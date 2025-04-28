#!/usr/bin/env python3
"""
Verbose Automated Installer for Ultimate Vocal Remover GUI on Linux
"""

import os
import sys
import platform
import subprocess
import urllib.request
import zipfile
import shutil
from pathlib import Path
import tempfile

# Color codes
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
RESET = "\033[0m"

def print_info(message):
    print(f"{YELLOW}[INFO]{RESET} {message}")

def print_success(message):
    print(f"{GREEN}[SUCCESS]{RESET} {message}")

def print_error(message):
    print(f"{RED}[ERROR]{RESET} {message}")

def run_command(command, shell=False, description=None):
    if description:
        print_info(description)
    try:
        subprocess.run(command, shell=shell, check=True)
        print_success(f"Finished: {description}")
    except subprocess.CalledProcessError as e:
        print_error(f"Failed: {description}")
        sys.exit(1)

def is_arch_based():
    if os.path.exists("/etc/arch-release"):
        return True
    if os.path.exists("/etc/os-release"):
        with open("/etc/os-release", "r") as f:
            content = f.read().lower()
            if "arch" in content or "manjaro" in content or "endeavouros" in content:
                return True
    return False

def install_dependencies():
    print_info("Checking and installing system dependencies...")
    if is_arch_based():
        run_command(["sudo", "pacman", "-Syu", "--noconfirm"], description="System update (Arch)")
        run_command(["sudo", "pacman", "-S", "--noconfirm", "ffmpeg", "python-pip", "tk"], description="Installing ffmpeg, python-pip, tk (Arch)")
    else:
        run_command(["sudo", "apt", "update"], description="System update (Debian)")
        run_command(["sudo", "apt", "install", "-y", "ffmpeg", "python3-pip", "python3-tk"], description="Installing ffmpeg, python3-pip, python3-tk (Debian)")

def download_and_extract():
    print_info("Downloading Ultimate Vocal Remover repository...")
    repo_url = "https://github.com/Anjok07/ultimatevocalremovergui/archive/refs/heads/master.zip"
    temp_dir = tempfile.gettempdir()
    zip_path = os.path.join(temp_dir, "uvr_master.zip")
    
    try:
        urllib.request.urlretrieve(repo_url, zip_path)
        print_success("Download complete")
    except Exception as e:
        print_error(f"Download failed: {e}")
        sys.exit(1)
    
    print_info("Extracting repository...")
    extract_dir = os.path.join(Path.home(), "UltimateVocalRemover")
    os.makedirs(extract_dir, exist_ok=True)
    
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)
    except zipfile.BadZipFile:
        print_error("Failed to extract ZIP file")
        sys.exit(1)

    extracted_dir = os.path.join(temp_dir, "ultimatevocalremovergui-master")
    
    for item in os.listdir(extracted_dir):
        source = os.path.join(extracted_dir, item)
        destination = os.path.join(extract_dir, item)
        if os.path.exists(destination):
            if os.path.isdir(destination):
                shutil.rmtree(destination)
            else:
                os.remove(destination)
        shutil.move(source, destination)
    
    os.remove(zip_path)
    shutil.rmtree(extracted_dir)

    print_success(f"Repository extracted to {extract_dir}")
    return extract_dir

def setup_venv(repo_dir):
    print_info("Creating virtual environment...")
    venv_dir = os.path.join(repo_dir, "venv")
    run_command([sys.executable, "-m", "venv", venv_dir], description="Virtual environment creation")
    
    pip_path = os.path.join(venv_dir, "bin", "pip")
    python_path = os.path.join(venv_dir, "bin", "python")
    
    print_info("Installing Python dependencies from requirements.txt...")
    run_command([pip_path, "install", "-r", os.path.join(repo_dir, "requirements.txt")], description="Installing requirements")
    
    print_info("Installing audioread module...")
    run_command([pip_path, "install", "audioread"], description="Installing audioread")
    
    return python_path

def run_uvr(repo_dir, python_path):
    print_info("Launching Ultimate Vocal Remover GUI...")
    app_script = os.path.join(repo_dir, "UVR.py")
    subprocess.Popen([python_path, app_script])
    print_success("Ultimate Vocal Remover GUI launched")

def main():
    print_info("Starting Ultimate Vocal Remover Installer for Linux...")
    
    if platform.system() != "Linux":
        print_error("This installer only supports Linux systems.")
        sys.exit(1)
    
    install_dependencies()
    repo_dir = download_and_extract()
    python_path = setup_venv(repo_dir)
    run_uvr(repo_dir, python_path)

    print_success("Installation process completed successfully!")

if __name__ == "__main__":
    main()
