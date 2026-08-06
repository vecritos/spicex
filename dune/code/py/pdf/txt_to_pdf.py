import argparse
from pathlib import Path
from reportlab.lib.pagesizes import LETTER
from reportlab.pdfgen import canvas


def txt_to_pdf(input_dir, output_dir):
    input_dir = Path(input_dir)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for txt_file in input_dir.glob("*.txt"):
        pdf_path = output_dir / (txt_file.stem + ".pdf")

        c = canvas.Canvas(str(pdf_path), pagesize=LETTER)
        width, height = LETTER

        x_margin = 50
        y_margin = 50
        y = height - y_margin

        with open(txt_file, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if y < y_margin:
                    c.showPage()
                    y = height - y_margin

                c.drawString(x_margin, y, line.rstrip())
                y -= 14  # line spacing

        c.save()
        print(f"Converted: {txt_file.name} → {pdf_path.name}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert text files to PDFs")
    parser.add_argument("input_dir", help="Directory containing .txt files")
    parser.add_argument("output_dir", help="Directory to save PDFs")

    args = parser.parse_args()
    txt_to_pdf(args.input_dir, args.output_dir)

