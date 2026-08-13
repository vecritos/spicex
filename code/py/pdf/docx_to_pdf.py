import subprocess
from pathlib import Path

INPUT_DIR = Path("input_docs")
OUTPUT_DIR = Path("pdfs")

OUTPUT_DIR.mkdir(exist_ok=True)

for docx_file in INPUT_DIR.glob("*.md.docx"):
    subprocess.run([
        "libreoffice",
        "--headless",
        "--convert-to", "pdf",
        "--outdir", str(OUTPUT_DIR),
        str(docx_file)
    ], check=True)

print("✅ Conversion complete")
