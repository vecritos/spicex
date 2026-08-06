import sys

def strip_newlines(input_file, output_file="output.py"):
    """
    Reads a Python program from the input file, removes unnecessary newline whitespace,
    and writes the cleaned code to the output file.
    """
    try:
        with open(input_file, 'r') as infile:
            lines = infile.readlines()
        
        # Strip whitespace and preserve only meaningful blank lines
        stripped_lines = []
        for line in lines:
            if line.strip():  # Preserve non-empty lines
                stripped_lines.append(line.rstrip())  # Remove trailing whitespace
            elif stripped_lines and stripped_lines[-1]:  # Preserve a single blank line
                stripped_lines.append("")
        
        with open(output_file, 'w') as outfile:
            outfile.write("\n".join(stripped_lines))
        
        print(f"Whitespace-stripped code saved to {output_file}.")
    except FileNotFoundError:
        print(f"Error: File {input_file} not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <input_file>")
    else:
        input_file = sys.argv[1]
        strip_newlines(input_file)
