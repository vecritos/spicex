import argparse
from pypdf import PdfReader, PdfWriter


def rotate_pdf_90(input_pdf, output_pdf):
    reader = PdfReader(input_pdf)
    writer = PdfWriter()

    for page in reader.pages:
        # Rotate +90 degrees clockwise
        rotated = page.rotate(90)
        writer.add_page(rotated)

    with open(output_pdf, "wb") as f:
        writer.write(f)

    print(f"Rotated PDF saved to: {output_pdf}")


def main():
    parser = argparse.ArgumentParser(
        description="Rotate every page in a PDF +90 degrees clockwise."
    )
    parser.add_argument("input_pdf", help="Path to input PDF")
    parser.add_argument("output_pdf", help="Path to output rotated PDF")

    args = parser.parse_args()
    rotate_pdf_90(args.input_pdf, args.output_pdf)


if __name__ == "__main__":
    main()

