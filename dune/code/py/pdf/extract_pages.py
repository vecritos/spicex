import sys
import pypdf

def extract_first_page(pdf_path, pages, output_path):
    with open(pdf_path, "rb") as pdf_file:
        reader = pypdf.PdfReader(pdf_file)
        writer = pypdf.PdfWriter()

        for n in pages:
            page = reader.pages[int(n)]
            writer.add_page(page)

        # Write the first page to a new PDF
        with open(output_path, "wb") as output_file:
            writer.write(output_file)

if __name__ == "__main__":
    pdf_path = sys.argv[1]
    pages = sys.argv[2].split()
    output_path = sys.argv[3]
    extract_first_page(pdf_path, pages, output_path)
