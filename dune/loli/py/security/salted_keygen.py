import os
import argparse
import getpass
from pathlib import Path
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF


# ----------------------------
# Key derivation
# ----------------------------
def derive_seed(master_secret: bytes, salt: bytes) -> bytes:
    hkdf = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        info=b"ssh:git:ed25519:v1",
    )
    return hkdf.derive(master_secret)


def seed_to_ed25519(seed: bytes):
    if len(seed) != 32:
        raise ValueError("Seed must be exactly 32 bytes.")
    private_key = ed25519.Ed25519PrivateKey.from_private_bytes(seed)
    return private_key, private_key.public_key()


def secure_write(path: Path, data: bytes, mode: int):
    path.write_bytes(data)
    os.chmod(path, mode)


def zero_bytes(b: bytearray):
    for i in range(len(b)):
        b[i] = 0


# ----------------------------
# Main
# ----------------------------
def main():
    parser = argparse.ArgumentParser(
        prog="ed25519_git_key.py",
        description=(
            "Derive an Ed25519 SSH key using HKDF from a master secret.\n"
            "Master secret is prompted securely; salt can be prompted or read from a file."
        ),
        epilog=(
            "Security note: Python performs best-effort memory cleanup only.\n"
            "Protect your master secret and salt appropriately."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument("--pub", action="store_true",
                        help="also write the OpenSSH public key")
    parser.add_argument("--install", action="store_true",
                        help="install keys into ~/.ssh/")
    parser.add_argument("--comment", default="generated-key",
                        help="comment appended to the public key")
    parser.add_argument("--salt", type=str,
                        help="path to a file containing raw salt bytes")

    args = parser.parse_args()

    # ----------------------------
    # Prompt or load master secret
    # ----------------------------
    master_input = getpass.getpass("Master secret (hidden): ")
    if not master_input:
        raise SystemExit("Error: master secret required.")
    master_secret = bytearray(master_input.encode())
    master_input = None  # drop plaintext

    # ----------------------------
    # Prompt salt or read from file
    # ----------------------------
    if args.salt:
        salt_path = Path(args.salt)
        if not salt_path.exists():
            raise SystemExit(f"Error: salt file {salt_path} does not exist.")
        salt_bytes = bytearray(salt_path.read_bytes())
    else:
        salt_input = getpass.getpass("Salt / machine id (hidden): ")
        if not salt_input:
            raise SystemExit("Error: salt required.")
        salt_bytes = bytearray(salt_input.encode())

    try:
        # ----------------------------
        # Derive seed via HKDF
        # ----------------------------
        seed = derive_seed(bytes(master_secret), bytes(salt_bytes))

        private_key, public_key = seed_to_ed25519(seed)

        # ----------------------------
        # Determine paths
        # ----------------------------
        if args.install:
            ssh_dir = Path.home() / ".ssh"
            ssh_dir.mkdir(mode=0o700, exist_ok=True)
            os.chmod(ssh_dir, 0o700)

            priv_path = ssh_dir / "id_ed25519"
            pub_path = ssh_dir / "id_ed25519.pub"
        else:
            priv_path = Path("id_ed25519")
            pub_path = Path("id_ed25519.pub")

        # ----------------------------
        # Write private key
        # ----------------------------
        private_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.OpenSSH,
            encryption_algorithm=serialization.NoEncryption(),
        )
        secure_write(priv_path, private_pem, 0o600)

        # ----------------------------
        # Optional public key
        # ----------------------------
        if args.pub:
            public_ssh = public_key.public_bytes(
                encoding=serialization.Encoding.OpenSSH,
                format=serialization.PublicFormat.OpenSSH,
            )
            public_line = public_ssh + b" " + args.comment.encode() + b"\n"
            secure_write(pub_path, public_line, 0o644)
            print(f"✅ Private key: {priv_path}")
            print(f"✅ Public key:  {pub_path}")
        else:
            print(f"✅ Private key: {priv_path}")
            print("ℹ️  Public key not written")

        print("🔐 HKDF derivation complete")

    finally:
        # ----------------------------
        # Best-effort memory scrubbing
        # ----------------------------
        zero_bytes(master_secret)
        zero_bytes(salt_bytes)
        if 'seed' in locals():
            seed = b"\x00" * len(seed)


if __name__ == "__main__":
    main()