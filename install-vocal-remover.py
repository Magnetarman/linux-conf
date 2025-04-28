#!/usr/bin/env python3
"""
Automated Installation Script for Ultimate Vocal Remover GUI
This script automates the process of downloading, installing, and running
the Ultimate Vocal Remover GUI application.
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

def print_step(step_number, message):
    """Print a formatted step message."""
    print(f"\n{'=' * 80}")
    print(f"Step {step_number}: {message}")
    print(f"{'=' * 80}")

def run_command(command, shell=False):
    """Run a shell command and display its output."""
    print(f"Running: {command if isinstance(command, str) else ' '.join(command)}")
    try:
        process = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            shell=shell,
            check=True
        )
        print(process.stdout)
        return process
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        print(f"Error output: {e.stderr}")
        return None

def is_arch_based():
    """Check if the system is Arch-based."""
    if os.path.exists("/etc/arch-release"):
        return True
    
    # Check for Arch-based distros like EndeavourOS, Manjaro, etc.
    if os.path.exists("/etc/os-release"):
        with open("/etc/os-release", "r") as f:
            content = f.read().lower()
            if "arch" in content or "endeavouros" in content or "manjaro" in content:
                return True
    return False

def install_system_dependencies():
    """Install required system dependencies."""
    print_step(1, "Installing system dependencies")
    
    if platform.system() == "Linux":
        if is_arch_based():
            print("Detected Arch-based system. Installing dependencies with pacman...")
            run_command(["sudo", "pacman", "-Syu", "--noconfirm"])
            run_command(["sudo", "pacman", "-S", "--noconfirm", "ffmpeg", "python-pip", "tk"])
        else:
            print("Assuming Debian-based system. Installing dependencies with apt...")
            run_command(["sudo", "apt", "update"])
            run_command(["sudo", "apt", "install", "-y", "ffmpeg", "python3-pip", "python3-tk"])
    elif platform.system() == "Darwin":  # macOS
        print("Detected macOS. Installing dependencies with Homebrew...")
        # Check if Homebrew is installed
        if subprocess.run(["which", "brew"], stdout=subprocess.PIPE).returncode != 0:
            print("Homebrew not found. Installing Homebrew...")
            homebrew_install_cmd = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            run_command(homebrew_install_cmd, shell=True)
        
        run_command(["brew", "update"])
        run_command(["brew", "install", "ffmpeg", "python", "tk"])
    elif platform.system() == "Windows":
        print("Detected Windows. Please make sure you have FFmpeg installed.")
        print("You can download FFmpeg from: https://ffmpeg.org/download.html")
        print("Make sure it's added to your PATH.")
        # Install pip packages
        run_command(["pip", "install", "tkinter"])
    else:
        print(f"Unsupported operating system: {platform.system()}")
        sys.exit(1)

def download_repository():
    """Download the UVR repository from GitHub."""
    print_step(2, "Downloading the repository")
    
    repo_url = "https://github.com/Anjok07/ultimatevocalremovergui/archive/refs/heads/master.zip"
    temp_dir = tempfile.gettempdir()
    zip_path = os.path.join(temp_dir, "uvr_master.zip")
    
    print(f"Downloading from {repo_url} to {zip_path}...")
    urllib.request.urlretrieve(repo_url, zip_path)
    
    # Ask user where to extract
    home_dir = Path.home()
    default_extract_dir = os.path.join(home_dir, "UltimateVocalRemover")
    
    print(f"\nWhere would you like to extract the repository?")
    print(f"Default: {default_extract_dir}")
    extract_dir = input(f"Press Enter to use default or specify a different path: ")
    
    if not extract_dir:
        extract_dir = default_extract_dir
    
    # Create directory if it doesn't exist
    os.makedirs(extract_dir, exist_ok=True)
    
    # Extract the zip file
    print(f"Extracting to {extract_dir}...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(temp_dir)
    
    # Move contents from the extracted directory to the target directory
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
    
    # Clean up
    os.remove(zip_path)
    if os.path.exists(extracted_dir):
        shutil.rmtree(extracted_dir)
    
    return extract_dir

def setup_virtual_environment(repo_dir):
    """Set up a virtual environment and install dependencies."""
    print_step(3, "Setting up a virtual environment")
    
    venv_dir = os.path.join(repo_dir, "venv")
    
    # Create virtual environment
    run_command([sys.executable, "-m", "venv", venv_dir])
    
    # Activate virtual environment and install dependencies
    if platform.system() == "Windows":
        activate_script = os.path.join(venv_dir, "Scripts", "activate")
        pip_path = os.path.join(venv_dir, "Scripts", "pip")
        python_path = os.path.join(venv_dir, "Scripts", "python")
    else:
        activate_script = os.path.join(venv_dir, "bin", "activate")
        pip_path = os.path.join(venv_dir, "bin", "pip")
        python_path = os.path.join(venv_dir, "bin", "python")
    
    print("Installing dependencies in the virtual environment...")
    requirements_file = os.path.join(repo_dir, "requirements.txt")
    
    # Install requirements
    if platform.system() == "Windows":
        run_command(f'"{pip_path}" install -r "{requirements_file}"', shell=True)
    else:
        run_command([pip_path, "install", "-r", requirements_file])
    
    return venv_dir, python_path

def run_application(repo_dir, python_path):
    """Run the UVR application."""
    print_step(4, "Running the application")
    
    app_script = os.path.join(repo_dir, "UVR.py")
    
    print("\nReady to run the Ultimate Vocal Remover GUI application!")
    run_now = input("Would you like to run it now? (y/n): ").strip().lower()
    
    if run_now == 'y' or run_now == 'yes':
        print("Starting Ultimate Vocal Remover GUI...")
        
        if platform.system() == "Windows":
            subprocess.Popen(f'"{python_path}" "{app_script}"', shell=True)
        else:
            subprocess.Popen([python_path, app_script])
        
        print("\nApplication started!")
    
    # Create a launch script
    create_launch_script = input("Would you like to create a launch script? (y/n): ").strip().lower()
    
    if create_launch_script == 'y' or create_launch_script == 'yes':
        if platform.system() == "Windows":
            launch_script_path = os.path.join(repo_dir, "launch_uvr.bat")
            with open(launch_script_path, "w") as f:
                f.write(f'@echo off\n')
                f.write(f'echo Starting Ultimate Vocal Remover GUI...\n')
                f.write(f'"{python_path}" "{app_script}"\n')
        else:
            launch_script_path = os.path.join(repo_dir, "launch_uvr.sh")
            with open(launch_script_path, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("echo Starting Ultimate Vocal Remover GUI...\n")
                f.write(f'"{python_path}" "{app_script}"\n')
            os.chmod(launch_script_path, 0o755)
        
        print(f"Launch script created at: {launch_script_path}")

def create_instructions(repo_dir, venv_dir):
    """Create a README with instructions for future use."""
    readme_path = os.path.join(repo_dir, "SETUP_README.txt")
    
    with open(readme_path, "w") as f:
        f.write("Ultimate Vocal Remover GUI - Setup Instructions\n")
        f.write("=============================================\n\n")
        f.write("This application has been set up with a virtual environment.\n\n")
        
        if platform.system() == "Windows":
            activate_cmd = os.path.join(venv_dir, "Scripts", "activate")
            f.write(f"To activate the virtual environment:\n{activate_cmd}\n\n")
        else:
            f.write(f"To activate the virtual environment:\nsource {os.path.join(venv_dir, 'bin', 'activate')}\n\n")
        
        f.write(f"To run the application:\npython {os.path.join(repo_dir, 'UVR.py')}\n\n")
        
        if os.path.exists(os.path.join(repo_dir, "launch_uvr.sh")) or os.path.exists(os.path.join(repo_dir, "launch_uvr.bat")):
            f.write("You can also use the launch script that was created during installation.\n")
    
    print(f"\nSetup instructions saved to: {readme_path}")

def main():
    """Main function to run the installation process."""
    print("=" * 80)
    print("Ultimate Vocal Remover GUI - Automated Installation Script")
    print("=" * 80)
    
    # Step 1: Install system dependencies
    install_system_dependencies()
    
    # Step 2: Download repository
    repo_dir = download_repository()
    
    # Step 3: Set up virtual environment
    venv_dir, python_path = setup_virtual_environment(repo_dir)
    
    # Step 4: Run the application
    run_application(repo_dir, python_path)
    
    # Create instructions file
    create_instructions(repo_dir, venv_dir)
    
    print("\nInstallation complete!")
    print(f"Ultimate Vocal Remover GUI is installed at: {repo_dir}")

if __name__ == "__main__":
    main()