import os
from PIL import Image
from pillow_heif import register_heif_opener

# Enable HEIF/HEIC support in Pillow
register_heif_opener()

def convert_all_heic_images(directory_path):
	if not os.path.exists(directory_path):
	    print(f"Error: The directory '{directory_path}' does not exist.")
	    exit()
	
	# Loop through all files in the directory
	for filename in os.listdir(directory_path):
	    # Check for both .heic and .heif extensions (case-insensitive)
	    if filename.lower().endswith((".heic", ".heif")):
	        
	        # Construct full input and output file paths
	        heic_path = os.path.join(directory_path, filename)
	        
	        base_name = os.path.splitext(filename)[0]
	        jpg_filename = f"{base_name}.jpg"
	        jpg_path = os.path.join(directory_path, jpg_filename)
	        
	        # Process the image conversion
	        try:
	            with Image.open(heic_path) as img:
	                # Convert to RGB color mode and save as JPEG
	                img.convert("RGB").save(jpg_path, "JPEG", quality=95)
	            print(f"Converted: {filename} -> {jpg_filename}")
	        except Exception as e:
	            print(f"Error converting {filename}: {e}")

print("Batch conversion completed!")

if __name__ == "__main__":
	directory_path = input('enter path to directory ')
	convert_all_heic_images(directory_path)


