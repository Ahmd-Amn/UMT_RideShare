from app.main import password_hash, password_ok
from app import main
from app.maps import route_match
from starlette.requests import Request
import ssl
from datetime import date, timedelta
from fastapi import HTTPException
import pytest
import stripe
import asyncio
import hashlib
import hmac
import json
import time


def test_password_hash_and_legacy_login():
    saved = password_hash("correct horse")
    assert password_ok("correct horse", saved)
    assert not password_ok("wrong", saved)
    assert password_ok("old password", "old password")


def test_registration_keeps_values_and_marks_errors(monkeypatch):
    request = Request({"type": "http", "method": "POST", "path": "/register", "headers": [], "query_string": b"", "scheme": "http", "server": ("test", 80), "session": {}})
    response = main.register(request, "A name", "person@example.com", "123", "driver", "password123", "different")
    assert response.status_code == 400
    assert response.context["values"]["name"] == "A name"
    assert response.context["values"]["password"] == "password123"
    assert response.context["errors"]["confirm_password"] == "Passwords do not match."

    class FakeDB:
        def __enter__(self):
            return object()

        def __exit__(self, *args):
            pass

    monkeypatch.setattr(main, "db", FakeDB)
    monkeypatch.setattr(main, "many", lambda *args: [{"username": "driver", "email": "other@example.com"}])
    response = main.register(request, "A name", "person@example.com", "123", "driver", "password123", "password123")
    assert response.status_code == 400
    assert response.context["errors"]["username"] == "This username is already taken."


def test_hosted_mysql_uses_verified_tls(monkeypatch):
    class Connection:
        def commit(self):
            pass

        def close(self):
            pass

    options = {}
    monkeypatch.setenv("MYSQL_DATABASE", "UMTRideShare")
    monkeypatch.setenv("MYSQL_SSL", "1")
    monkeypatch.setattr(main.pymysql, "connect", lambda **kwargs: options.update(kwargs) or Connection())
    with main.db():
        pass
    assert isinstance(options["ssl"], ssl.SSLContext)
    assert options["ssl"].verify_mode == ssl.CERT_REQUIRED
    assert options["ssl"].check_hostname


def test_passenger_points_follow_driver_route():
    geometry = {"type": "MultiLineString", "coordinates": [[[103.08, 5.40], [103.09, 5.40], [103.10, 5.40]]]}
    assert route_match(geometry, (5.4005, 103.083), (5.4005, 103.097))
    assert not route_match(geometry, (5.4005, 103.097), (5.4005, 103.083))
    assert not route_match(geometry, (5.42, 103.083), (5.4005, 103.097))


def test_booking_rejects_points_outside_route(monkeypatch):
    request = Request({"type": "http", "method": "POST", "path": "/book/1", "headers": [], "query_string": b"", "scheme": "http", "server": ("test", 80), "session": {"user_id": 2, "username": "passenger"}})
    class FakeDB:
        def __enter__(self):
            return object()

        def __exit__(self, *args):
            pass

    ride = {"status": 1, "available_seats": 2, "date": date.today() + timedelta(days=1), "pickup_time": "12:00:00", "driver_name": "driver", "route_geometry": {"type": "LineString", "coordinates": [[103.08, 5.40], [103.10, 5.40]]}}
    monkeypatch.setattr(main, "db", FakeDB)
    monkeypatch.setattr(main, "one", lambda *args: ride)
    monkeypatch.setattr(main, "execute", lambda *args: pytest.fail("Booking should not be saved"))
    with pytest.raises(HTTPException) as error:
        main.reserve(request, 1, "Away", "Destination", 5.42, 103.08, 5.4, 103.10)
    assert error.value.status_code == 400


@pytest.mark.parametrize("event_type,payment_status,expected", [
    ("checkout.session.completed", "paid", "paid"),
    ("checkout.session.completed", "unpaid", None),
    ("checkout.session.expired", "unpaid", "expired"),
    ("checkout.session.async_payment_failed", "unpaid", "failed"),
])
def test_checkout_updates_booking_only_for_final_payment(monkeypatch, event_type, payment_status, expected):
    class FakeDB:
        def __enter__(self):
            return object()

        def __exit__(self, *args):
            pass

    changes = []
    booking = {"id": 7, "ride_id": 3, "status": 2, "payment_status": "pending", "payment_id": "cs_test_7", "price": main.Decimal("5.00"), "date": date.today() + timedelta(days=1), "pickup_time": "12:00:00"}
    monkeypatch.setattr(main, "db", FakeDB)
    monkeypatch.setattr(main, "one", lambda *args: booking)
    monkeypatch.setattr(main, "execute", lambda conn, sql, args: changes.append((sql, args)))
    session = stripe.StripeObject.construct_from({"id": "cs_test_7", "client_reference_id": "7", "currency": "myr", "amount_total": 500, "payment_status": payment_status}, "test")
    main.confirm_checkout(session, event_type)
    if expected is None:
        assert not changes
    else:
        assert expected in changes[0][0] or expected in changes[0][1]
        assert len(changes) == (2 if expected in ("expired", "failed") else 1)
    changes.clear()
    with pytest.raises(HTTPException) as error:
        main.confirm_checkout({"id": "cs_test_7", "client_reference_id": "7", "currency": "myr", "amount_total": 100, "payment_status": payment_status}, event_type)
    assert error.value.status_code == 409
    assert not changes


def test_online_booking_holds_seat_and_redirects_to_checkout(monkeypatch):
    request = Request({"type": "http", "method": "POST", "path": "/book/1", "headers": [(b"host", b"test.example")], "query_string": b"", "scheme": "https", "server": ("test.example", 443), "session": {"user_id": 2, "username": "passenger"}, "app": main.app})

    class FakeDB:
        def __enter__(self):
            return object()

        def __exit__(self, *args):
            pass

    ride = {"status": 1, "available_seats": 2, "date": date.today() + timedelta(days=1), "pickup_time": "12:00:00", "driver_name": "driver", "price": main.Decimal("5.00"), "route_geometry": {"type": "LineString", "coordinates": [[103.08, 5.40], [103.10, 5.40]]}}
    changes = []
    checkout = {}
    monkeypatch.setenv("STRIPE_SECRET_KEY", "sk_test_fake")
    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec_fake")
    monkeypatch.setattr(main, "db", FakeDB)
    monkeypatch.setattr(main, "one", lambda conn, sql, args=(): ride if "FROM rides r" in sql else {"id": 7} if "LAST_INSERT_ID" in sql else None)
    monkeypatch.setattr(main, "execute", lambda conn, sql, args: changes.append((sql, args)))
    monkeypatch.setattr(main.stripe.checkout.Session, "create", lambda **kwargs: checkout.update(kwargs) or type("Session", (), {"id": "cs_test_7", "url": "https://checkout.stripe.com/test"})())
    response = main.reserve(request, 1, "Pickup", "Destination", 5.4, 103.083, 5.4, 103.097, "online")
    assert response.status_code == 303
    assert response.headers["location"] == "https://checkout.stripe.com/test"
    assert "payment_method_types" not in checkout
    assert checkout["line_items"][0]["price_data"]["unit_amount"] == 500
    assert any("payment_status" in sql and args[-1] == "pending" for sql, args in changes)
    assert any("SET payment_id" in sql and args == ("cs_test_7", 7) for sql, args in changes)


def test_ride_departure_accepts_mysql_time_values():
    future = date.today() + timedelta(days=2)
    assert not main.ride_departed(future, timedelta(hours=9))
    assert not main.ride_departed(future, "09:00:00")


def test_payment_webhook_requires_valid_stripe_signature(monkeypatch):
    payload = json.dumps({"id": "evt_test_1", "object": "event", "type": "checkout.session.completed", "data": {"object": {"id": "cs_test_1"}}}).encode()
    timestamp = str(int(time.time()))
    signature = hmac.new(b"whsec_test", timestamp.encode() + b"." + payload, hashlib.sha256).hexdigest()
    received = []
    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec_test")
    monkeypatch.setattr(main, "use_stripe", lambda: None)
    monkeypatch.setattr(main, "confirm_checkout", lambda session, event_type: received.append((session["id"], event_type)))

    def request(header):
        async def body():
            return {"type": "http.request", "body": payload, "more_body": False}
        return Request({"type": "http", "method": "POST", "path": "/payments/webhook", "headers": [(b"stripe-signature", header.encode())]}, body)

    with pytest.raises(HTTPException) as error:
        asyncio.run(main.stripe_webhook(request("invalid")))
    assert error.value.status_code == 400
    assert not received
    assert asyncio.run(main.stripe_webhook(request(f"t={timestamp},v1={signature}"))) == {"received": True}
    assert received == [("cs_test_1", "checkout.session.completed")]


def test_cancel_paid_booking_starts_refund_before_releasing_seat(monkeypatch):
    request = Request({"type": "http", "method": "POST", "path": "/bookings/7/cancel", "headers": [], "query_string": b"", "scheme": "http", "server": ("test", 80), "session": {"user_id": 2}})

    class FakeDB:
        def __enter__(self):
            return object()

        def __exit__(self, *args):
            pass

    booking = {"id": 7, "ride_id": 3, "status": 1, "payment_id": "cs_test_7", "payment_method": "card", "payment_status": "paid", "date": date.today() + timedelta(days=2), "pickup_time": timedelta(hours=9)}
    actions = []
    monkeypatch.setenv("STRIPE_SECRET_KEY", "sk_test_fake")
    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec_fake")
    monkeypatch.setattr(main, "db", FakeDB)
    monkeypatch.setattr(main, "one", lambda *args: booking)
    monkeypatch.setattr(main, "execute", lambda conn, sql, args: actions.append((sql, args)))
    monkeypatch.setattr(main.stripe.checkout.Session, "retrieve", lambda session_id: type("Session", (), {"payment_intent": "pi_test_7"})())
    monkeypatch.setattr(main.stripe.Refund, "create", lambda **kwargs: actions.append(("refund", kwargs)) or type("Refund", (), {"id": "re_test_7", "status": "succeeded"})())
    response = main.cancel_booking(request, 7)
    assert response.status_code == 303
    assert actions[0] == ("refund", {"payment_intent": "pi_test_7", "metadata": {"booking_id": "7"}, "idempotency_key": "booking-7-refund"})
    assert actions[1][1] == ("refunded", "re_test_7", 7)
    assert actions[2][1] == (3,)


def test_refund_webhook_updates_only_matching_refund(monkeypatch):
    class FakeDB:
        def __enter__(self):
            return object()

        def __exit__(self, *args):
            pass

    changes = []
    monkeypatch.setattr(main, "db", FakeDB)
    monkeypatch.setattr(main, "one", lambda *args: {"id": 7, "refund_id": "re_test_7", "status": 0})
    monkeypatch.setattr(main, "execute", lambda conn, sql, args: changes.append(args))
    main.confirm_refund({"id": "re_other", "metadata": {"booking_id": "7"}, "status": "failed"})
    assert not changes
    main.confirm_refund({"id": "re_test_7", "metadata": {"booking_id": "7"}, "status": "failed"})
    assert changes == [("refund_failed", 7)]
