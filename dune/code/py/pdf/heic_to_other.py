import os
import sys
from pprint import pprint
import time
from PIL import Image
from wand.image import Image

def convert_heic_to_jpg(heic_file, jpg_file):
    with Image(filename=heic_file) as img:
        img.format = 'jpeg'
        img.save(filename=jpg_file)
# credit panofish
# def is_locked(filepath):
#     locked = None
#     file_object = None
#     if os.path.exists(filepath):
#         try:
#             buffer_size = 8
#             # Opening file in append mode and read the first 8 characters.
#             file_object = open(filepath, 'a', buffer_size)
#             if file_object:
#                 locked = False
#         except IOError as message:
#             locked = True
#         finally:
#             if file_object:
#                 file_object.close()
#     return locked

# credit panofish
# def wait_for_file(filepath):
#     wait_time = 1
#     while is_locked(filepath):
#         time.sleep(wait_time)

def create_save_name(filename):
    return f'{filename.split('.')[0]}.jpg'

def get_files(directory):
    # Get list of HEIF and HEIC files in directory
    files = [f for f in os.listdir(directory) if f.endswith('.heic') or f.endswith('.heif')]
    return files

def convert_image(directory):
    path_prefix = os.path.join(os.getcwd(), directory)
    files = [os.path.join(path_prefix, f) for f in get_files(directory)]
    
    pprint(files)
    
    # Convert each file to JPEG
    for filename in files:
        save_filename = os.path.join(directory, os.path.splitext(filename)[0] + '.jpg')
        convert_heic_to_jpg(filename, save_filename)

if __name__ == '__main__':
    directory = sys.argv[1]
    convert_image(directory)
