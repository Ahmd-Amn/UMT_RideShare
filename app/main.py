import hashlib
import hmac
import json
import logging
import os
import re
import secrets
import ssl
from contextlib import contextmanager
from datetime import date, datetime, time, timedelta
from decimal import Decimal
from pathlib import Path
from zoneinfo import ZoneInfo

import pymysql
import stripe
from fastapi import FastAPI, Form, HTTPException, Request
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from dotenv import load_dotenv
from starlette.middleware.sessions import SessionMiddleware
from app.maps import driving_route, geoapify, route_match, valid_point


ROOT = Path(__file__).resolve().parent
logger = logging.getLogger(__name__)
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
        connection = pymysql.connect(host=os.getenv("MYSQL_HOST", "localhost"), port=int(os.getenv("MYSQL_PORT", "3306")), user=os.getenv("MYSQL_USER", "root"), password=os.getenv("MYSQL_PASSWORD", ""), database=name, cursorclass=pymysql.cursors.DictCursor, autocommit=False, connect_timeout=5, ssl=ssl.create_default_context() if os.getenv("MYSQL_SSL") == "1" else None)
    except pymysql.MySQLError as exc:
        logger.error("MySQL connection failed: %s", exc)
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


def page(request, name, *, status_code=200, **context):
    return templates.TemplateResponse(request, name, {"user_id": request.session.get("user_id"), "username": request.session.get("username"), **context}, status_code=status_code)


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
def register(request: Request, name: str = Form(""), email: str = Form(""), phone: str = Form(""), username: str = Form(""), password: str = Form(""), confirm_password: str = Form("")):
    values = {"name": name.strip(), "email": email.strip(), "phone": phone.strip(), "username": username.strip(), "password": password, "confirm_password": confirm_password}
    errors = {}
    for field, label, limit in (("name", "Full name", 150), ("email", "Email", 255), ("phone", "Phone", 40), ("username", "Username", 100)):
        if not values[field]:
            errors[field] = f"{label} is required."
        elif len(values[field]) > limit:
            errors[field] = f"{label} must be {limit} characters or fewer."
    if values["email"] and not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", values["email"]):
        errors["email"] = "Enter a valid email address."
    if len(password) < 8:
        errors["password"] = "Use at least 8 characters."
    if password != confirm_password:
        errors["confirm_password"] = "Passwords do not match."
    if errors:
        return page(request, "register.html", values=values, errors=errors, status_code=400)
    try:
        with db() as conn:
            existing = many(conn, "SELECT username,email FROM users WHERE username=%s OR email=%s", (values["username"], values["email"]))
            if any(row["username"] == values["username"] for row in existing):
                errors["username"] = "This username is already taken."
            if any(row["email"] == values["email"] for row in existing):
                errors["email"] = "This email is already registered."
            if errors:
                return page(request, "register.html", values=values, errors=errors, status_code=400)
            execute(conn, "INSERT INTO users (name,email,phone,username,password) VALUES (%s,%s,%s,%s,%s)", (values["name"], values["email"], values["phone"], values["username"], password_hash(password)))
    except pymysql.err.IntegrityError:
        return page(request, "register.html", values=values, errors={"form": "Username or email is already registered. Please check both fields."}, status_code=400)
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
KL_TIMEZONE = ZoneInfo("Asia/Kuala_Lumpur")


def ride_departed(ride_date, pickup_time):
    departure = datetime.combine(ride_date, time.min)
    departure = departure + pickup_time if isinstance(pickup_time, timedelta) else datetime.combine(ride_date, pickup_time if isinstance(pickup_time, time) else time.fromisoformat(pickup_time))
    departure = departure.replace(tzinfo=KL_TIMEZONE)
    return departure <= datetime.now(KL_TIMEZONE)


def stripe_ready():
    return bool(os.getenv("STRIPE_SECRET_KEY") and os.getenv("STRIPE_WEBHOOK_SECRET"))


def use_stripe():
    if not stripe_ready():
        raise HTTPException(503, "Online payments are not configured yet.")
    stripe.api_key = os.environ["STRIPE_SECRET_KEY"]


def confirm_checkout(session, event_type):
    if hasattr(session, "to_dict"):
        session = session.to_dict()
    booking_id = session.get("client_reference_id")
    if not booking_id or not str(booking_id).isdigit():
        return
    with db() as conn:
        booking = one(conn, "SELECT b.id,b.ride_id,b.status,b.payment_status,b.payment_id,r.price,r.date,r.pickup_time FROM bookings b JOIN rides r ON b.ride_id=r.id WHERE b.id=%s FOR UPDATE", (int(booking_id),))
        if not booking or booking["payment_id"] != session.get("id"):
            return
        if session.get("currency") != "myr" or session.get("amount_total") != int(booking["price"] * 100):
            logger.error("Stripe checkout amount or currency mismatch for booking %s", booking["id"])
            raise HTTPException(409, "Payment amount does not match the booking.")
        if event_type in ("checkout.session.completed", "checkout.session.async_payment_succeeded") and session.get("payment_status") == "paid":
            if booking["status"] == 2:
                if ride_departed(booking["date"], booking["pickup_time"]):
                    refund = stripe.Refund.create(payment_intent=session["payment_intent"], metadata={"booking_id": str(booking["id"])}, idempotency_key=f"booking-{booking['id']}-refund")
                    execute(conn, "UPDATE bookings SET status=0,payment_status=%s,refund_id=%s WHERE id=%s", ("refunded" if refund.status == "succeeded" else "refund_failed" if refund.status == "failed" else "refund_pending", refund.id, booking["id"]))
                    execute(conn, "UPDATE rides SET available_seats=available_seats+1 WHERE id=%s", (booking["ride_id"],))
                else:
                    execute(conn, "UPDATE bookings SET status=1,payment_status='paid' WHERE id=%s", (booking["id"],))
            elif booking["status"] == 0 and booking["payment_status"] not in ("refunded", "refund_pending", "refund_failed"):
                refund = stripe.Refund.create(payment_intent=session["payment_intent"], metadata={"booking_id": str(booking["id"])}, idempotency_key=f"booking-{booking['id']}-refund")
                execute(conn, "UPDATE bookings SET payment_status=%s,refund_id=%s WHERE id=%s", ("refunded" if refund.status == "succeeded" else "refund_failed" if refund.status == "failed" else "refund_pending", refund.id, booking["id"]))
        elif event_type in ("checkout.session.expired", "checkout.session.async_payment_failed") and booking["status"] == 2:
            execute(conn, "UPDATE bookings SET status=0,payment_status=%s WHERE id=%s", ("expired" if event_type.endswith("expired") else "failed", booking["id"]))
            execute(conn, "UPDATE rides SET available_seats=available_seats+1 WHERE id=%s", (booking["ride_id"],))


def confirm_refund(refund):
    if hasattr(refund, "to_dict"):
        refund = refund.to_dict()
    booking_id = (refund.get("metadata") or {}).get("booking_id")
    if not booking_id or not str(booking_id).isdigit():
        return
    with db() as conn:
        booking = one(conn, "SELECT id,refund_id,status FROM bookings WHERE id=%s FOR UPDATE", (int(booking_id),))
        if booking and booking["status"] == 0 and booking["refund_id"] == refund.get("id"):
            status = "refunded" if refund.get("status") == "succeeded" else "refund_failed" if refund.get("status") == "failed" else "refund_pending"
            execute(conn, "UPDATE bookings SET payment_status=%s WHERE id=%s", (status, booking["id"]))


@app.get("/api/places")
def places(request: Request, q: str = ""):
    uid(request)
    q = q.strip()
    if len(q) < 3 or len(q) > 100:
        raise HTTPException(400, "Enter at least 3 characters to search for a place.")
    data = geoapify("geocode/autocomplete", text=q, format="json", filter="countrycode:my", bias="proximity:103.09,5.41", limit=5)
    return [{"label": item["formatted"], "lat": item["lat"], "lon": item["lon"]} for item in data.get("results", []) if all(key in item for key in ("formatted", "lat", "lon"))]


@app.get("/api/places/reverse")
def reverse_place(request: Request, lat: float, lon: float):
    uid(request)
    if not valid_point(lat, lon):
        raise HTTPException(400, "Invalid map location.")
    data = geoapify("geocode/reverse", lat=lat, lon=lon, format="json", limit=1)
    results = data.get("results", [])
    return {"label": results[0]["formatted"] if results else f"{lat:.5f}, {lon:.5f}"}


@app.get("/api/route-preview")
def route_preview(request: Request, pickup_lat: float, pickup_lon: float, dropoff_lat: float, dropoff_lon: float):
    uid(request)
    return {"geometry": driving_route(pickup_lat, pickup_lon, dropoff_lat, dropoff_lon)}


@app.get("/rides")
def rides(request: Request):
    with db() as conn:
        user_id = uid(request)
        cars = many(conn, "SELECT * FROM cars WHERE user_id=%s", (user_id,))
        offered = many(conn, RIDE_SELECT + " WHERE c.user_id=%s ORDER BY r.date DESC,r.pickup_time DESC", (user_id,))
        passengers = many(conn, "SELECT b.ride_id,b.pickup_address,b.dropoff_address,b.payment_method,u.username FROM bookings b JOIN users u ON b.user_id=u.id JOIN rides r ON b.ride_id=r.id JOIN cars c ON r.car_id=c.id WHERE c.user_id=%s AND b.status=1 ORDER BY b.created_at", (user_id,))
    return page(request, "rides.html", cars=cars, rides=offered, passengers=passengers, map_key=os.getenv("GEOAPIFY_BROWSER_KEY", ""))


@app.post("/rides")
def add_ride(request: Request, car_id: int = Form(...), date_: date = Form(..., alias="date"), pickup_time: time = Form(...), pickup_address: str = Form(...), dropoff_address: str = Form(...), pickup_latitude: float = Form(...), pickup_longitude: float = Form(...), dropoff_latitude: float = Form(...), dropoff_longitude: float = Form(...), available_seats: int = Form(...), price: Decimal = Form(...)):
    if date_ < date.today() or available_seats < 1 or price < 0 or not pickup_address.strip() or not dropoff_address.strip() or len(pickup_address) > 255 or len(dropoff_address) > 255:
        raise HTTPException(400, "Invalid ride date, seats or price")
    with db() as conn:
        if not one(conn, "SELECT id FROM cars WHERE id=%s AND user_id=%s", (car_id, uid(request))):
            raise HTTPException(403, "Car does not belong to you")
    geometry = driving_route(pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude)
    with db() as conn:
        execute(conn, "INSERT INTO rides (car_id,date,pickup_time,pickup_latitude,pickup_longitude,dropoff_latitude,dropoff_longitude,pickup_address,dropoff_address,available_seats,price,status,route_geometry) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,1,%s)", (car_id, date_, pickup_time, pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude, pickup_address, dropoff_address, available_seats, price, json.dumps(geometry)))
    return redirect("/rides")


@app.post("/rides/{ride_id}/cancel")
def cancel_ride(request: Request, ride_id: int):
    with db() as conn:
        ride = one(conn, "SELECT r.id FROM rides r JOIN cars c ON r.car_id=c.id WHERE r.id=%s AND c.user_id=%s AND r.status=1 FOR UPDATE", (ride_id, uid(request)))
        if not ride:
            raise HTTPException(404, "Active ride not found")
        if one(conn, "SELECT id FROM bookings WHERE ride_id=%s AND status IN (1,2) LIMIT 1", (ride_id,)):
            raise HTTPException(409, "Cancel or settle existing bookings before cancelling this ride.")
        execute(conn, "UPDATE rides SET status=0 WHERE id=%s", (ride_id,))
    return redirect("/rides")


@app.get("/book")
def book(request: Request, pickup: str = "", dropoff: str = "", pickup_lat: float | None = None, pickup_lon: float | None = None, dropoff_lat: float | None = None, dropoff_lon: float | None = None, travel_date: date | None = None):
    sql = RIDE_SELECT + " WHERE r.status=1 AND r.available_seats>0 AND r.date>=CURDATE() AND r.route_geometry IS NOT NULL AND c.user_id!=%s"
    args = [uid(request)]
    if travel_date:
        sql += " AND r.date=%s"
        args.append(travel_date)
    with db() as conn:
        available = many(conn, sql + " ORDER BY r.date,r.pickup_time", args)
    points = (pickup_lat, pickup_lon, dropoff_lat, dropoff_lon)
    searching = bool(pickup or dropoff or any(point is not None for point in points))
    error = None
    if searching and (not pickup or not dropoff or any(point is None for point in points) or not valid_point(pickup_lat, pickup_lon) or not valid_point(dropoff_lat, dropoff_lon)):
        error = "Select a pickup and destination from the suggestions or map."
        available = []
    ride_maps = []
    for ride in available:
        if ride_departed(ride["date"], ride["pickup_time"]):
            continue
        geometry = ride["route_geometry"] if isinstance(ride["route_geometry"], dict) else json.loads(ride["route_geometry"])
        if searching and not route_match(geometry, (pickup_lat, pickup_lon), (dropoff_lat, dropoff_lon)):
            continue
        ride_maps.append({"id": ride["id"], "geometry": geometry})
    matched_ids = {item["id"] for item in ride_maps}
    available = [ride for ride in available if ride["id"] in matched_ids]
    return page(request, "book.html", rides=available, ride_maps=ride_maps, pickup=pickup, dropoff=dropoff, pickup_lat=pickup_lat, pickup_lon=pickup_lon, dropoff_lat=dropoff_lat, dropoff_lon=dropoff_lon, travel_date=travel_date, error=error, map_key=os.getenv("GEOAPIFY_BROWSER_KEY", ""), stripe_enabled=stripe_ready())


@app.post("/book/{ride_id}")
def reserve(request: Request, ride_id: int, pickup_address: str = Form(...), dropoff_address: str = Form(...), pickup_latitude: float = Form(...), pickup_longitude: float = Form(...), dropoff_latitude: float = Form(...), dropoff_longitude: float = Form(...), payment_method: str = Form("cash")):
    if payment_method not in ("cash", "online", "card", "fpx"):
        raise HTTPException(400, "Choose cash or online payment.")
    if payment_method != "cash":
        use_stripe()
    if not pickup_address.strip() or not dropoff_address.strip() or len(pickup_address) > 255 or len(dropoff_address) > 255 or not valid_point(pickup_latitude, pickup_longitude) or not valid_point(dropoff_latitude, dropoff_longitude):
        raise HTTPException(400, "Select valid pickup and destination points.")
    try:
        with db() as conn:
            user_id = uid(request)
            ride = one(conn, RIDE_SELECT + " WHERE r.id=%s FOR UPDATE", (ride_id,))
            if not ride or ride["status"] != 1 or ride["available_seats"] < 1 or ride_departed(ride["date"], ride["pickup_time"]) or ride["driver_name"] == request.session.get("username"):
                raise HTTPException(409, "Ride is no longer available")
            geometry = ride["route_geometry"] if isinstance(ride["route_geometry"], dict) else json.loads(ride["route_geometry"]) if ride["route_geometry"] else None
            if not route_match(geometry, (pickup_latitude, pickup_longitude), (dropoff_latitude, dropoff_longitude)):
                raise HTTPException(400, "Your pickup and destination are not along this route.")
            if one(conn, "SELECT id FROM bookings WHERE user_id=%s AND ride_id=%s AND status IN (1,2)", (user_id, ride_id)):
                raise HTTPException(409, "You already have a booking or payment in progress for this ride")
            amount = int(ride["price"] * 100)
            if payment_method != "cash" and amount < 200:
                raise HTTPException(400, "Online payment requires a fare of at least RM 2.00. Choose cash.")
            execute(conn, "UPDATE rides SET available_seats=available_seats-1 WHERE id=%s", (ride_id,))
            execute(conn, "INSERT INTO bookings (user_id,ride_id,payment_id,status,created_at,pickup_address,pickup_latitude,pickup_longitude,dropoff_address,dropoff_latitude,dropoff_longitude,payment_method,payment_status) VALUES (%s,%s,%s,%s,NOW(),%s,%s,%s,%s,%s,%s,%s,%s)", (user_id, ride_id, "cash" if payment_method == "cash" else "pending", 1 if payment_method == "cash" else 2, pickup_address, pickup_latitude, pickup_longitude, dropoff_address, dropoff_latitude, dropoff_longitude, payment_method, "unpaid" if payment_method == "cash" else "pending"))
            if payment_method != "cash":
                # shortcut: payments settle to this Stripe account; add Stripe Connect when drivers need automatic payouts.
                booking_id = one(conn, "SELECT LAST_INSERT_ID() AS id")["id"]
                session = stripe.checkout.Session.create(
                    ui_mode="hosted_page",
                    mode="payment",
                    billing_address_collection="auto",
                    phone_number_collection={"enabled": False},
                    automatic_tax={"enabled": False},
                    allow_promotion_codes=False,
                    submit_type="auto",
                    integration_identifier="hosted_web_0001",
                    origin_context="web",
                    line_items=[{"price_data": {"currency": "myr", "unit_amount": amount, "product_data": {"name": f"UMT RideShare seat · {ride['date']}"}}, "quantity": 1}],
                    client_reference_id=str(booking_id),
                    success_url=str(request.url_for("payment_return")) + "?session_id={CHECKOUT_SESSION_ID}",
                    cancel_url=str(request.url_for("bookings")) + "?payment=cancelled",
                    idempotency_key=f"booking-{booking_id}-checkout",
                )
                execute(conn, "UPDATE bookings SET payment_id=%s WHERE id=%s", (session.id, booking_id))
    except stripe.StripeError as exc:
        logger.warning("Stripe checkout failed: %s", type(exc).__name__)
        raise HTTPException(502, "Online checkout is temporarily unavailable. Please try again.") from exc
    return RedirectResponse(session.url, status_code=303) if payment_method != "cash" else redirect("/bookings")


@app.get("/bookings")
def bookings(request: Request):
    with db() as conn:
        rows = many(conn, "SELECT b.id,b.status,b.created_at,b.payment_method,b.payment_status,r.date,r.pickup_time,COALESCE(b.pickup_address,r.pickup_address) AS pickup_address,COALESCE(b.dropoff_address,r.dropoff_address) AS dropoff_address,r.price,u.username AS driver_name FROM bookings b JOIN rides r ON b.ride_id=r.id JOIN cars c ON r.car_id=c.id JOIN users u ON c.user_id=u.id WHERE b.user_id=%s ORDER BY b.created_at DESC", (uid(request),))
    for booking in rows:
        booking["can_cancel"] = booking["status"] in (1, 2) and not ride_departed(booking["date"], booking["pickup_time"])
    return page(request, "bookings.html", bookings=rows, payment_notice=request.query_params.get("payment"))


@app.get("/payments/return")
def payment_return(request: Request, session_id: str):
    user_id = uid(request)
    use_stripe()
    with db() as conn:
        booking = one(conn, "SELECT id FROM bookings WHERE payment_id=%s AND user_id=%s", (session_id, user_id))
    if not booking:
        raise HTTPException(404, "Payment booking not found")
    try:
        session = stripe.checkout.Session.retrieve(session_id)
        confirm_checkout(session, "checkout.session.completed")
    except stripe.StripeError as exc:
        logger.warning("Stripe payment check failed: %s", type(exc).__name__)
        raise HTTPException(502, "Payment confirmation is temporarily unavailable.") from exc
    return redirect("/bookings?payment=returned")


@app.post("/payments/webhook")
async def stripe_webhook(request: Request):
    secret = os.getenv("STRIPE_WEBHOOK_SECRET")
    if not secret:
        raise HTTPException(503, "Payment webhook is not configured.")
    try:
        event = stripe.Webhook.construct_event(await request.body(), request.headers.get("stripe-signature", ""), secret)
    except (ValueError, stripe.SignatureVerificationError) as exc:
        raise HTTPException(400, "Invalid payment notification.") from exc
    if event["type"] in ("checkout.session.completed", "checkout.session.async_payment_succeeded", "checkout.session.async_payment_failed", "checkout.session.expired"):
        use_stripe()
        confirm_checkout(event["data"]["object"], event["type"])
    elif event["type"] in ("refund.updated", "refund.failed"):
        confirm_refund(event["data"]["object"])
    return {"received": True}


@app.get("/bookings/{booking_id}/pay")
def resume_payment(request: Request, booking_id: int):
    use_stripe()
    with db() as conn:
        booking = one(conn, "SELECT b.payment_id,r.date,r.pickup_time FROM bookings b JOIN rides r ON b.ride_id=r.id WHERE b.id=%s AND b.user_id=%s AND b.status=2", (booking_id, uid(request)))
    if not booking:
        raise HTTPException(404, "Pending payment not found")
    if ride_departed(booking["date"], booking["pickup_time"]):
        raise HTTPException(409, "This ride has already departed.")
    try:
        session = stripe.checkout.Session.retrieve(booking["payment_id"])
    except stripe.StripeError as exc:
        raise HTTPException(502, "Payment page is temporarily unavailable.") from exc
    return RedirectResponse(session.url, status_code=303) if session.status == "open" else redirect("/bookings?payment=returned")


@app.post("/bookings/{booking_id}/cancel")
def cancel_booking(request: Request, booking_id: int):
    try:
        with db() as conn:
            booking = one(conn, "SELECT b.id,b.ride_id,b.status,b.payment_id,b.payment_method,b.payment_status,r.date,r.pickup_time FROM bookings b JOIN rides r ON b.ride_id=r.id WHERE b.id=%s AND b.user_id=%s AND b.status IN (1,2) FOR UPDATE", (booking_id, uid(request)))
            if not booking:
                raise HTTPException(404, "Active booking not found")
            if ride_departed(booking["date"], booking["pickup_time"]):
                raise HTTPException(409, "This ride has already departed.")
            payment_status = booking["payment_status"]
            refund_id = None
            if booking["payment_method"] != "cash":
                use_stripe()
                session = stripe.checkout.Session.retrieve(booking["payment_id"])
                if booking["status"] == 2:
                    if session.status != "open":
                        raise HTTPException(409, "Payment is being confirmed. Try again shortly.")
                    stripe.checkout.Session.expire(session.id)
                    payment_status = "expired"
                else:
                    refund = stripe.Refund.create(payment_intent=session.payment_intent, metadata={"booking_id": str(booking_id)}, idempotency_key=f"booking-{booking_id}-refund")
                    if refund.status == "failed":
                        raise HTTPException(502, "Refund could not be started. Booking remains active.")
                    payment_status = "refunded" if refund.status == "succeeded" else "refund_pending"
                    refund_id = refund.id
            execute(conn, "UPDATE bookings SET status=0,payment_status=%s,refund_id=%s WHERE id=%s", (payment_status, refund_id, booking_id))
            execute(conn, "UPDATE rides SET available_seats=available_seats+1 WHERE id=%s", (booking["ride_id"],))
    except stripe.StripeError as exc:
        logger.warning("Stripe cancellation failed: %s", type(exc).__name__)
        raise HTTPException(502, "Cancellation could not be completed. Please try again.") from exc
    return redirect("/bookings")
