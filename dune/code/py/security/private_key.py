import sys
import os
import argparse
from pathlib import Path
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.hazmat.primitives import serialization


def seed_to_ed25519(seed: bytes):
    if len(seed) != 32:
        raise ValueError("Seed must be exactly 32 bytes.")
    private_key = ed25519.Ed25519PrivateKey.from_private_bytes(seed)
    return private_key, private_key.public_key()


def secure_write(path: Path, data: bytes, mode: int):
    path.write_bytes(data)
    os.chmod(path, mode)


def main():
    parser = argparse.ArgumentParser(
        prog="ed25519_git_key.py",
        description=(
            "Generate an Ed25519 SSH key from a 32-byte hex seed.\n\n"
            "The seed MUST be exactly 64 hex characters (32 bytes).\n"
            "This tool is intended for deterministic key generation in "
            "controlled environments."
        ),
        epilog=(
            "Examples:\n"
            "  python ed25519_git_key.py <seed>\n"
            "  python ed25519_git_key.py <seed> --pub\n"
            "  python ed25519_git_key.py <seed> --pub --install "
            "--comment \"gituser@host\"\n\n"
            "Security warning: predictable seeds produce weak keys."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "seed",
        help="64 hex characters representing the 32-byte seed"
    )
    parser.add_argument(
        "--pub",
        action="store_true",
        help="also write the OpenSSH public key"
    )
    parser.add_argument(
        "--install",
        action="store_true",
        help="install keys into ~/.ssh/ with hardened permissions"
    )
    parser.add_argument(
        "--comment",
        default="generated-key",
        help="comment appended to the public key (default: generated-key)"
    )

    args = parser.parse_args()

    # --- validate seed ---
    if len(args.seed) != 64:
        sys.exit("Error: Seed must be exactly 64 hex characters.")

    try:
        seed = bytes.fromhex(args.seed)
    except ValueError:
        sys.exit("Error: Invalid hex string.")

    private_key, public_key = seed_to_ed25519(seed)

    # --- determine paths ---
    if args.install:
        ssh_dir = Path.home() / ".ssh"
        ssh_dir.mkdir(mode=0o700, exist_ok=True)
        os.chmod(ssh_dir, 0o700)

        priv_path = ssh_dir / "id_ed25519"
        pub_path = ssh_dir / "id_ed25519.pub"
    else:
        priv_path = Path("id_ed25519")
        pub_path = Path("id_ed25519.pub")

    # --- serialize private key ---
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.OpenSSH,
        encryption_algorithm=serialization.NoEncryption()
    )

    secure_write(priv_path, private_pem, 0o600)

    # --- optional public key ---
    if args.pub:
        public_ssh = public_key.public_bytes(
            encoding=serialization.Encoding.OpenSSH,
            format=serialization.PublicFormat.OpenSSH
        )

        public_line = public_ssh + b" " + args.comment.encode() + b"\n"
        secure_write(pub_path, public_line, 0o644)

        print(f"✅ Private key: {priv_path}")
        print(f"✅ Public key:  {pub_path}")
    else:
        print(f"✅ Private key: {priv_path}")
        print("ℹ️  Public key not written")

    print("🔐 Permissions hardened")


if __name__ == "__main__":
    main()