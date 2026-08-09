import os
import moviepy as mp

def batch_convert_mpeg_to_mp4(folder_path):
    # Ensure the folder path exists
    if not os.path.exists(folder_path):
        print(f"Error: The folder '{folder_path}' does not exist.")
        return

    # Scan the directory for target files
    # Lowercase conversion ensures it catches both .mpeg and .MPEG
    files = [f for f in os.listdir(folder_path) if f.lower().endswith(('.webm'))]
    
    if not files:
        print("No files found in the specified folder.")
        return
        
    print(f"Found {len(files)} files to convert. Starting batch process...\n")

    for filename in files:
        # Construct full file paths
        input_file = os.path.join(folder_path, filename)
        
        # Strip the old extension and replace it with .mp4
        base_name = os.path.splitext(filename)[0]
        output_file = os.path.join(folder_path, f"{base_name}.mp4")
        
        print(f"Processing: {filename} -> {base_name}.mp4")
        
        try:
            # Load and convert the file
            clip = mp.VideoFileClip(input_file)
            clip.write_videofile(output_file, codec="libx264", audio_codec="aac")
            clip.close()
            print(f"Successfully converted: {filename}\n")
            
        except Exception as e:
            print(f"Failed to convert {filename}. Error: {e}\n")

# Example usage: Replace with your actual directory path
# Use "." to target the same folder where your Python script is located
target_folder = "./my_videos"
batch_convert_mpeg_to_mp4(target_folder)

