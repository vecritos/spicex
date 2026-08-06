import subprocess
import shutil

def download_spotify_playlist(playlist_url: str):
    """
    Downloads a complete Spotify playlist as MP3 files with metadata.
    
    :param playlist_url: The full share URL of the Spotify playlist
    """
    # Verify spotdl is installed and accessible
    if not shutil.which("spotdl"):
        raise EnvironmentError("spotdl CLI tool not found. Please run 'pip install spotdl' first.")
    
    print(f"Initializing download for: {playlist_url}")
    
    try:
        # Executes the spotDL download command via a system subprocess
        result = subprocess.run(
            ["spotdl", "download", playlist_url],
            check=True,
            text=True,
            capture_output=False  # Shows the real-time download progress bar in your console
        )
        print("\n✨ Playlist download successfully completed!")
        
    except subprocess.CalledProcessError as e:
        print(f"\n❌ An error occurred during download: {e}")

# Example Usage
if __name__ == "__main__":
    TARGET_PLAYLIST = input('enter target playlist url')
    
    download_spotify_playlist(TARGET_PLAYLIST)

