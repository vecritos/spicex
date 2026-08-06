from markdown import markdown
from weasyprint import HTML
import sys
from pathlib import Path

def markdown_to_pdf(md_path, pdf_path):
    md_text = Path(md_path).read_text(encoding="utf-8")

    html = markdown(
        md_text,
        extensions=[
            "fenced_code",
            "tables",
            "toc",
            "codehilite"
        ]
    )

    html_template = f"""
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body {{
                font-family: Arial, sans-serif;
                margin: 2cm;
            }}
            pre {{
                background: #f4f4f4;
                padding: 10px;
                overflow-x: auto;
            }}
            code {{
                font-family: monospace;
            }}
            h1, h2, h3 {{
                color: #333;
            }}
        </style>
    </head>
    <body>
        {html}
    </body>
    </html>
    """

    HTML(string=html_template).write_pdf(pdf_path)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python md_to_pdf.py input.md output.pdf")
        sys.exit(1)

    markdown_to_pdf(sys.argv[1], sys.argv[2])


