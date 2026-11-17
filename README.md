# UMT RideShare

UMT RideShare is a campus carpooling app for people who want to share a drive or reserve a seat. The current version uses FastAPI for the backend, Jinja2 templates with HTML, CSS, Bootstrap and JavaScript for the interface, and MySQL for data.

## What the app does

- Create an account, sign in, and update a profile.
- Add cars to a garage and publish rides with a date, route, seat count, and price.
- Search available rides by pickup, drop-off, and date.
- Reserve a seat and view or cancel bookings. Seat counts update with each reservation or cancellation.

Reservations do **not** collect payment. Payment processing and receipts from the older Java/JSP app have not yet been migrated.

## Project layout

| Path | Purpose |
| --- | --- |
| `app/main.py` | FastAPI routes, sessions, and MySQL queries |
| `app/templates/` | HTML pages |
| `app/static/` | CSS, JavaScript, and images |
| `schema.sql` | Schema for a fresh `UMTRideShare` database |
| `tests/` | Small backend checks |
| `src/`, `web/` | Original Java/JSP app, retained for reference |

## Run locally

Use Python 3.10 or newer and a running MySQL server. The app reads `SESSION_SECRET` and `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, and `MYSQL_DATABASE` from the ignored `.env` file. The database in this project is named `UMTRideShare`. Run `schema.sql` only if you are creating a fresh database; it is not a migration for existing data.

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Open <http://127.0.0.1:8000>. Run checks with `python -m pytest` after installing `pytest`.

New accounts use hashed passwords. The app still accepts plaintext passwords from the original JSP app so existing accounts can sign in; that compatibility should be removed after those accounts are migrated.

## Deploying on Vercel

Set each `.env` key separately in Vercel's project Environment Variables for the deployment environment. `MYSQL_HOST` must be a hostname or address that Vercel can reach; `localhost` only works when MySQL runs on the same machine as the app. A MySQL server on your laptop will need to be moved to an accessible database host before the deployed app can use it. Redeploy after changing Vercel environment variables. If the app returns a database connection error, check the deployment's runtime logs for the MySQL error code; the response shown to visitors intentionally omits connection details.
