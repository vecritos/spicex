import os
import sys
from PIL import Image
from pillow_heif import register_heif_opener

# Register the HEIF/HEIC opener with Pillow
register_heif_opener()

def convert_heic_to_jpg(heic_path, output_dir=None, quality=90):
    """
    Converts a HEIC image file to a JPG image file.
    """
    if not os.path.exists(heic_path):
        print(f"Error: File not found at '{heic_path}'")
        return None

    file_dir, file_name = os.path.split(heic_path)
    base_name, _ = os.path.splitext(file_name)
    jpg_name = f"{base_name}.jpg"

    save_dir = output_dir if output_dir else file_dir
    jpg_path = os.path.join(save_dir, jpg_name)

    try:
        with Image.open(heic_path) as image:
            rgb_image = image.convert("RGB")
            rgb_image.save(jpg_path, "JPEG", quality=quality)
            
        print(f"Successfully converted: {jpg_path}")
        return jpg_path

    except Exception as e:
        print(f"Failed to convert {heic_path}. Error: {e}")
        return None

if __name__ == "__main__":
    # Check if at least the input file path is provided
    # sys.argv[0] is always the script name itself
    if len(sys.argv) < 2:
        print("Usage: python script.py <input_heic_path> [output_directory]")
        sys.exit(1)

    input_file = sys.argv[1]
    
    # Check if an optional output directory was provided
    output_folder = sys.argv[2] if len(sys.argv) > 2 else None

    convert_heic_to_jpg(input_file, output_folder)

