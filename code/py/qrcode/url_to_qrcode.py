import qrcode
import sys
from pathlib import Path


def url_to_qrcode(url: str, output_file: str = "qrcode.png"):
    if not url.startswith(("http://", "https://")):
        raise ValueError("URL must start with http:// or https://")

    qr = qrcode.QRCode(
        version=None,  # automatic size
        error_correction=qrcode.constants.ERROR_CORRECT_Q,
        box_size=10,
        border=4,
    )

    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")

    output_path = Path(output_file)
    img.save(output_path)

    print(f"QR code saved to: {output_path.resolve()}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python url_to_qr.py <url> [output.png]")
        sys.exit(1)

    url = sys.argv[1]
    output = sys.argv[2] if len(sys.argv) > 2 else "qrcode.png"

    try:
        url_to_qrcode(url, output)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
