"""Restore private Android signing material from Actions secrets, without logging it."""
import base64
import os
from pathlib import Path


def required(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        raise SystemExit(f"Missing repository secret: {name}; refusing temporary signing")
    return value


key = base64.b64decode(required("QUANT_KEYSTORE_BASE64"), validate=True)
store_password = required("QUANT_KEYSTORE_PASSWORD")
key_password = required("QUANT_KEY_PASSWORD")
for value in (store_password, key_password):
    if any(c in value for c in "\r\n\\"):
        raise SystemExit("Invalid signing password format")

os.umask(0o077)
Path("android/app/quant-release-key.jks").write_bytes(key)
Path("android/key.properties").write_text(
    "storeFile=app/quant-release-key.jks\n"
    f"storePassword={store_password}\n"
    f"keyPassword={key_password}\n"
    "keyAlias=quant_key\n", encoding="utf-8"
)
print("Persistent Android signing key restored")
