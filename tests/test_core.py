from app.main import password_hash, password_ok


def test_password_hash_and_legacy_login():
    saved = password_hash("correct horse")
    assert password_ok("correct horse", saved)
    assert not password_ok("wrong", saved)
    assert password_ok("old password", "old password")
