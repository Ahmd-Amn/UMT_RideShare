from app.main import password_hash, password_ok
from app import main
from starlette.requests import Request
import ssl


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
