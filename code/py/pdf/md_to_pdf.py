#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path
from markdown_pdf import MarkdownPdf, Section

def convert_md_to_pdf(input_path: str, output_path: str):
    """Reads a Markdown file and converts it into a styled PDF."""
    in_file = Path(input_path)
    out_file = Path(output_path)
    
    # Safety Check: Ensure the input file exists
    if not in_file.is_file():
        print(f"Error: Input file '{input_path}' does not exist.", file=sys.stderr)
        sys.exit(1)
        
    try:
        # Read the markdown content
        with open(in_file, "r", encoding="utf-8") as f:
            md_content = f.read()
            
        # Initialize PDF builder (generates internal bookmarks for H1 and H2 headers)
        pdf = MarkdownPdf(toc_level=2)
        
        # Add the content as a document section
        pdf.add_section(Section(md_content))
        
        # Save the generated PDF
        pdf.save(out_file)
        print(f"Success! Converted '{in_file.name}' to '{out_file.name}'.")
        
    except Exception as e:
        print(f"An error occurred during conversion: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    # Set up command-line arguments
    parser = argparse.ArgumentParser(
        description="Convert a Markdown (.md) file into a PDF document."
    )
    parser.add_argument(
        "-i", "--input", 
        required=True, 
        help="Path to the input Markdown file (e.g., readme.md)"
    )
    parser.add_argument(
        "-o", "--output", 
        required=True, 
        help="Path where the output PDF should be saved (e.g., output.pdf)"
    )
    
    # Parse the arguments provided by the user
    args = parser.parse_args()
    
    # Run the conversion
    convert_md_to_pdf(args.input, args.output)

if __name__ == "__main__":
    main()
