import sys
import os
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
from cryptography.fernet import Fernet
from base64 import urlsafe_b64encode

def derive_key(password: str, salt: bytes) -> bytes:
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=200_000,
    )
    return urlsafe_b64encode(kdf.derive(password.encode()))

def encrypt_layer(data: bytes, password: str) -> bytes:
    salt = os.urandom(16)
    key = derive_key(password, salt)
    f = Fernet(key)
    return salt + f.encrypt(data)

def main():
    if len(sys.argv) != 4:
        print("usage: python encrypt_layers.py <input_file> <passwords.txt> <output_file>")
        sys.exit(1)

    infile, pwfile, outfile = sys.argv[1:4]

    with open(infile, "rb") as f:
        data = f.read()

    with open(pwfile, "r", encoding="utf-8") as f:
        passwords = [line.rstrip("\n") for line in f if line.strip()]

    for pw in passwords:
        data = encrypt_layer(data, pw)

    with open(outfile, "wb") as f:
        f.write(data)

if __name__ == "__main__":
    main()
