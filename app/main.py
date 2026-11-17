import hashlib
import hmac
import os
import secrets
from contextlib import contextmanager
from datetime import date, time
from decimal import Decimal
from pathlib import Path

import pymysql
from fastapi import FastAPI, Form, HTTPException, Request
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from dotenv import load_dotenv
from starlette.middleware.sessions import SessionMiddleware


ROOT = Path(__file__).resolve().parent
load_dotenv(ROOT.parent / ".env")
app = FastAPI(title="UMT RideShare")
app.add_middleware(SessionMiddleware, secret_key=os.getenv("SESSION_SECRET", secrets.token_hex(32)), same_site="lax")
app.mount("/static", StaticFiles(directory=ROOT / "static"), name="static")
templates = Jinja2Templates(directory=ROOT / "templates")


@contextmanager
def db():
    name = os.getenv("MYSQL_DATABASE")
    if not name:
        raise HTTPException(503, "Database is not configured yet. Set MYSQL_DATABASE and MySQL credentials.")
    try:
        connection = pymysql.connect(host=os.getenv("MYSQL_HOST", "localhost"), port=int(os.getenv("MYSQL_PORT", "3306")), user=os.getenv("MYSQL_USER", "root"), password=os.getenv("MYSQL_PASSWORD", ""), database=name, cursorclass=pymysql.cursors.DictCursor, autocommit=False)
    except pymysql.MySQLError as exc:
        raise HTTPException(503, "Database connection is unavailable.") from exc
    try:
        yield connection
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def one(conn, sql, args=()):
    with conn.cursor() as cur:
        cur.execute(sql, args)
        return cur.fetchone()


def many(conn, sql, args=()):
    with conn.cursor() as cur:
        cur.execute(sql, args)
        return cur.fetchall()


def execute(conn, sql, args=()):
    with conn.cursor() as cur:
        cur.execute(sql, args)
        return cur.rowcount


def password_hash(password):
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 310000)
    return f"pbkdf2_sha256${salt.hex()}${digest.hex()}"


def password_ok(password, saved):
    try:
        method, salt, digest = saved.split("$")
        return method == "pbkdf2_sha256" and hmac.compare_digest(hashlib.pbkdf2_hmac("sha256", password.encode(), bytes.fromhex(salt), 310000), bytes.fromhex(digest))
    except (ValueError, AttributeError):
        # shortcut: legacy JSP passwords are plaintext; remove fallback after old accounts are migrated.
        return hmac.compare_digest(password, saved or "")


def page(request, name, **context):
    return templates.TemplateResponse(request, name, {"user_id": request.session.get("user_id"), "username": request.session.get("username"), **context})


def uid(request):
    user_id = request.session.get("user_id")
    if not user_id:
        raise HTTPException(401, "Sign in required.")
    return user_id


def redirect(path):
    return RedirectResponse(path, status_code=303)


@app.get("/")
def home(request: Request):
    return page(request, "home.html")


@app.get("/register")
def register_page(request: Request):
    return page(request, "register.html")


@app.post("/register")
def register(request: Request, name: str = Form(...), email: str = Form(...), phone: str = Form(...), username: str = Form(...), password: str = Form(...), confirm_password: str = Form(...)):
    if len(password) < 8 or password != confirm_password:
        return page(request, "register.html", error="Passwords must match and be at least 8 characters.")
    with db() as conn:
        if one(conn, "SELECT id FROM users WHERE username=%s OR email=%s", (username, email)):
            return page(request, "register.html", error="Username or email already exists.")
        execute(conn, "INSERT INTO users (name,email,phone,username,password) VALUES (%s,%s,%s,%s,%s)", (name, email, phone, username, password_hash(password)))
    return redirect("/?registered=1")


@app.post("/login")
def login(request: Request, username: str = Form(...), password: str = Form(...)):
    with db() as conn:
        user = one(conn, "SELECT id,username,password FROM users WHERE username=%s", (username,))
    if not user or not password_ok(password, user["password"]):
        return page(request, "home.html", error="Incorrect username or password.")
    request.session.clear()
    request.session.update(user_id=user["id"], username=user["username"])
    return redirect("/dashboard")


@app.post("/logout")
def logout(request: Request):
    request.session.clear()
    return redirect("/")


@app.get("/dashboard")
def dashboard(request: Request):
    uid(request)
    return page(request, "dashboard.html")


@app.get("/profile")
def profile(request: Request):
    with db() as conn:
        user = one(conn, "SELECT id,name,email,phone,username FROM users WHERE id=%s", (uid(request),))
    if not user:
        raise HTTPException(404, "User not found")
    return page(request, "profile.html", user=user)


@app.post("/profile")
def update_profile(request: Request, name: str = Form(...), email: str = Form(...), phone: str = Form(...)):
    with db() as conn:
        execute(conn, "UPDATE users SET name=%s,email=%s,phone=%s WHERE id=%s", (name, email, phone, uid(request)))
    return redirect("/profile")


@app.get("/garage")
def garage(request: Request):
    with db() as conn:
        cars = many(conn, "SELECT * FROM cars WHERE user_id=%s ORDER BY id DESC", (uid(request),))
    return page(request, "garage.html", cars=cars)


@app.post("/garage")
def add_car(request: Request, plate_number: str = Form(...), color: str = Form(...), car_type: str = Form(...)):
    with db() as conn:
        if one(conn, "SELECT id FROM cars WHERE plate_number=%s", (plate_number,)):
            cars = many(conn, "SELECT * FROM cars WHERE user_id=%s", (uid(request),))
            return page(request, "garage.html", cars=cars, error="Plate number already exists.")
        execute(conn, "INSERT INTO cars (plate_number,color,car_type,user_id) VALUES (%s,%s,%s,%s)", (plate_number, color, car_type, uid(request)))
    return redirect("/garage")


@app.post("/garage/{car_id}/delete")
def delete_car(request: Request, car_id: int):
    with db() as conn:
        user_id = uid(request)
        if one(conn, "SELECT r.id FROM rides r JOIN cars c ON r.car_id=c.id WHERE r.car_id=%s AND c.user_id=%s LIMIT 1", (car_id, user_id)):
            cars = many(conn, "SELECT * FROM cars WHERE user_id=%s ORDER BY id DESC", (user_id,))
            return page(request, "garage.html", cars=cars, error="This car has rides attached and cannot be deleted.")
        execute(conn, "DELETE FROM cars WHERE id=%s AND user_id=%s", (car_id, user_id))
    return redirect("/garage")


RIDE_JOIN = "FROM rides r JOIN cars c ON r.car_id=c.id JOIN users u ON c.user_id=u.id"
RIDE_SELECT = "SELECT r.*,c.plate_number,c.car_type,c.color,u.username AS driver_name " + RIDE_JOIN


@app.get("/rides")
def rides(request: Request):
    with db() as conn:
        user_id = uid(request)
        cars = many(conn, "SELECT * FROM cars WHERE user_id=%s", (user_id,))
        offered = many(conn, RIDE_SELECT + " WHERE c.user_id=%s ORDER BY r.date DESC,r.pickup_time DESC", (user_id,))
    return page(request, "rides.html", cars=cars, rides=offered)


@app.post("/rides")
def add_ride(request: Request, car_id: int = Form(...), date_: date = Form(..., alias="date"), pickup_time: time = Form(...), pickup_address: str = Form(...), dropoff_address: str = Form(...), available_seats: int = Form(...), price: Decimal = Form(...)):
    if date_ < date.today() or available_seats < 1 or price < 0:
        raise HTTPException(400, "Invalid ride date, seats or price")
    with db() as conn:
        if not one(conn, "SELECT id FROM cars WHERE id=%s AND user_id=%s", (car_id, uid(request))):
            raise HTTPException(403, "Car does not belong to you")
        execute(conn, "INSERT INTO rides (car_id,date,pickup_time,pickup_latitude,pickup_longitude,dropoff_latitude,dropoff_longitude,pickup_address,dropoff_address,available_seats,price,status) VALUES (%s,%s,%s,0,0,0,0,%s,%s,%s,%s,1)", (car_id, date_, pickup_time, pickup_address, dropoff_address, available_seats, price))
    return redirect("/rides")


@app.post("/rides/{ride_id}/cancel")
def cancel_ride(request: Request, ride_id: int):
    with db() as conn:
        execute(conn, "UPDATE rides r JOIN cars c ON r.car_id=c.id SET r.status=0 WHERE r.id=%s AND c.user_id=%s AND r.status=1", (ride_id, uid(request)))
    return redirect("/rides")


@app.get("/book")
def book(request: Request, pickup: str = "", dropoff: str = "", travel_date: date | None = None):
    sql = RIDE_SELECT + " WHERE r.status=1 AND r.available_seats>0 AND r.date>=CURDATE() AND c.user_id!=%s"
    args = [uid(request)]
    if pickup:
        sql += " AND r.pickup_address LIKE %s"
        args.append(f"%{pickup}%")
    if dropoff:
        sql += " AND r.dropoff_address LIKE %s"
        args.append(f"%{dropoff}%")
    if travel_date:
        sql += " AND r.date=%s"
        args.append(travel_date)
    with db() as conn:
        available = many(conn, sql + " ORDER BY r.date,r.pickup_time", args)
    return page(request, "book.html", rides=available, pickup=pickup, dropoff=dropoff, travel_date=travel_date)


@app.post("/book/{ride_id}")
def reserve(request: Request, ride_id: int):
    with db() as conn:
        user_id = uid(request)
        ride = one(conn, RIDE_SELECT + " WHERE r.id=%s FOR UPDATE", (ride_id,))
        if not ride or ride["status"] != 1 or ride["available_seats"] < 1 or ride["date"] < date.today() or ride["driver_name"] == request.session.get("username"):
            raise HTTPException(409, "Ride is no longer available")
        if one(conn, "SELECT id FROM bookings WHERE user_id=%s AND ride_id=%s AND status=1", (user_id, ride_id)):
            raise HTTPException(409, "You already booked this ride")
        execute(conn, "UPDATE rides SET available_seats=available_seats-1 WHERE id=%s", (ride_id,))
        execute(conn, "INSERT INTO bookings (user_id,ride_id,payment_id,status,created_at) VALUES (%s,%s,%s,1,NOW())", (user_id, ride_id, "pending"))
    return redirect("/bookings")


@app.get("/bookings")
def bookings(request: Request):
    with db() as conn:
        rows = many(conn, "SELECT b.id,b.status,b.created_at,r.date,r.pickup_time,r.pickup_address,r.dropoff_address,r.price,u.username AS driver_name FROM bookings b JOIN rides r ON b.ride_id=r.id JOIN cars c ON r.car_id=c.id JOIN users u ON c.user_id=u.id WHERE b.user_id=%s ORDER BY b.created_at DESC", (uid(request),))
    return page(request, "bookings.html", bookings=rows)


@app.post("/bookings/{booking_id}/cancel")
def cancel_booking(request: Request, booking_id: int):
    with db() as conn:
        booking = one(conn, "SELECT id,ride_id FROM bookings WHERE id=%s AND user_id=%s AND status=1 FOR UPDATE", (booking_id, uid(request)))
        if not booking:
            raise HTTPException(404, "Active booking not found")
        execute(conn, "UPDATE bookings SET status=0 WHERE id=%s", (booking_id,))
        execute(conn, "UPDATE rides SET available_seats=available_seats+1 WHERE id=%s", (booking["ride_id"],))
    return redirect("/bookings")
