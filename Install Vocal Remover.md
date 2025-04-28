# Install Vocal Remover

#### **Step 1: Download the Repository**

- Download and save this repository from [GitHub](https://github.com/Anjok07/ultimatevocalremovergui/archive/refs/heads/master.zip).
- Extract the downloaded file to a directory of your choice.

---

#### **Step 2: Install Dependencies**

Use the following commands based on your system type:

**For Arch-based systems (EndeavourOS):**

```bash
sudo pacman -Syu
sudo pacman -S ffmpeg python-pip tk
```

---

#### **Step 3: Set Up a Virtual Environment (Recommended)**

Setting up a virtual environment (venv) ensures that the program's dependencies do not interfere with system-wide Python packages.

1. **Navigate to the extracted repository directory:**

   ```bash
   cd /path/to/ultimatevocalremovergui
   ```

2. **Create a virtual environment:**

   ```bash
   python3 -m venv venv
   ```

3. **Activate the virtual environment:**

   - For **Debian-based and Arch-based systems:**
     ```bash
     source venv/bin/activate
     ```

4. **Install dependencies in the virtual environment:**
   ```bash
   pip install -r requirements.txt
   ```

---

#### **Step 4: Run the Application**

While the virtual environment is activated, start the application:

```bash
python UVR.py
```

---
