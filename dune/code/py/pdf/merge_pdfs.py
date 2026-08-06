import argparse
from pypdf import PdfReader, PdfWriter
from pathlib import Path


def merge_pdfs(pdf_files, output_pdf):
    writer = PdfWriter()

    for pdf in pdf_files:
        pdf_path = Path(pdf)
        if not pdf_path.exists():
            print(f"Skipping missing file: {pdf}")
            continue

        reader = PdfReader(pdf_path)
        for page in reader.pages:
            writer.add_page(page)

        print(f"Added: {pdf_path.name}")

    if len(writer.pages) == 0:
        raise ValueError("No pages were added. Check input files.")

    with open(output_pdf, "wb") as f:
        writer.write(f)

    print(f"\nMerged PDF created: {output_pdf}")


def main():
    parser = argparse.ArgumentParser(
        description="Combine multiple PDF files into a single PDF."
    )
    parser.add_argument(
        "pdfs",
        nargs="+",
        help="Input PDF files (in desired order)"
    )
    parser.add_argument(
        "-o",
        "--output",
        required=True,
        help="Output merged PDF file"
    )

    args = parser.parse_args()
    merge_pdfs(args.pdfs, args.output)


if __name__ == "__main__":
    main()

