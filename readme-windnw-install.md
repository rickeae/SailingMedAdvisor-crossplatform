# SailingMedAdvisor Windows + macOS Install / Uninstall Guide

## Project Banner

| Field | Details |
| --- | --- |
| Project | `SailingMedAdvisor` (MedSailingAdvisor) |
| Maintainer | Rick Escher |
| Blog | [www.aphrodite.cat](https://www.aphrodite.cat) |
| Email | [rick@escher.ca](mailto:rick@escher.ca) |
| WhatsApp | +1-613-729-7579 (Canada) |
| Framework | Google HAI-DEF |
| Models | Google MedGemma (`4B` and `27B`) |
| Challenge Context | Kaggle MedGemma Impact Challenge |
| Primary Stack | FastAPI, SQLite, HTML/CSS/JavaScript |
| Deployment Modes | Local edge runtime, Hugging Face demo mode |
| License | CC BY 4.0 (`LICENSE`) |

This guide is for a brand-new Windows or macOS machine with none of the required software installed.

Scope:
- Windows 10/11 (64-bit)
- macOS (Intel and Apple Silicon)
- CPU-first setup
- Local model download from Hugging Face after user accepts MedGemma terms

Important note:
- Full **Manual Install Instructions** are preserved in **Appendix A**.
- Recommended path is the automated launcher scripts.

---

## =====================================================
## 1) Uninstall / Remove Everything (Read This First)
## =====================================================
This section explains how to remove what the installer creates.  
Why this is necessary: many first-time users are concerned about being unable to roll back.

Use this uninstall launcher:

```bat
launch_windows_uninstall.cmd
```

### Step-by-step uninstall instructions
1. Open **File Explorer**.
2. Open your `SailingMedAdvisor-crossplatform` folder.
3. Double-click `launch_windows_uninstall.cmd`.
4. A black terminal window opens and asks simple Yes/No questions.
5. For each item you want to remove, type `y` and press **Enter**.
6. For each item you want to keep, type `n` and press **Enter**.
7. When finished, press any key to close the window.

What this means in plain English:
- The script only removes local files on your own computer.
- It does not make permanent system-wide policy changes.
- You are asked before each major delete action.

What the uninstall script can remove:
- `.venv` (Python virtual environment)
- `data\models_cache` (downloaded model cache)
- `.env.windows` (local runtime config file)
- `data\runtime.log`
- `app.db` (optional, deletes saved app data)

If you also want to remove the source code, delete the folder named `SailingMedAdvisor-crossplatform`.  
You will usually find it in your Windows user home folder, for example:
- `C:\Users\<your-username>\SailingMedAdvisor-crossplatform`

---

## =====================================================
## 2) Install Everything (Automated, Recommended)
## =====================================================
This option does almost all of the setup work for you.  
When you run the installer launcher, it opens a guided terminal window and asks simple questions.

In plain language, it will:
- create a local Python environment for this app
- detect/install required software packages for the app
- ask for your Hugging Face token
- download MedGemma model files to the correct folder
- prepare default local settings so the app starts in CPU-safe mode

Why this is necessary: it avoids long command lines and reduces setup errors for first-time users.

Compatibility note:
- This flow is designed to work on older Windows installs.
- Git is optional if you installed this project from a ZIP file.
- If a dependency is missing, use the direct installer links in this guide.

### 2.0 What is Command Prompt and how to open it
**Command Prompt** is a Windows text window where you type commands (instead of clicking buttons).
For this automated install, you mainly use double-click launchers.  
You will still do a small amount of command-line work for quick checks and, if needed, fallback troubleshooting steps.

How to open Command Prompt:
1. Click the **Start** button (Windows logo).
2. Type `cmd`.
3. Click **Command Prompt**.

Alternative way:
1. Press `Windows key + R`.
2. Type `cmd`.
3. Press **Enter**.

You should see a black or dark window with a blinking cursor, ready for typing.

### 2.1 Step-by-step install instructions
1. Install Python 3.11 (64-bit):
   - Download the Python runtime installer (`.exe`):
     - `https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe`
   - Run the installer.
   - Leave "Use admin privleges when installing py.exe" checked.
   - Check **Add Python to PATH**.
   - Click Install Now.
   - If you downloaded `python-manager-*.msix` by mistake, ignore it and use the `.exe` link above.
   - Optional quick check in Command Prompt:
     - `py -3.11 --version`
2. Download the project as a ZIP file:
   - Open `https://github.com/rickeae/SailingMedAdvisor-crossplatform`
   - Click **Code** -> **Download ZIP**
   - Save the ZIP file
3. Extract the ZIP file:
   - Right-click ZIP -> **Extract All...**
   - Open the extracted folder
   - If needed, rename the folder to `SailingMedAdvisor-crossplatform`
4. Open the extracted project folder named `SailingMedAdvisor-crossplatform`  
   (example: `C:\Users\<your-username>\Downloads\SailingMedAdvisor-crossplatform`).
5. Inside `SailingMedAdvisor-crossplatform`, double-click:
   - `launch_windows_bootstrap.cmd`
6. Follow the on-screen prompts in the black terminal window:
   - confirm MedGemma terms were accepted
   - paste Hugging Face token
   - choose 4B-only or 4B+27B download
   - optionally install quantized 27B CPU backend (`llama-cpp-python`)
7. When bootstrap is finished, still inside `SailingMedAdvisor-crossplatform`, double-click:
   - `launch_windows_app.cmd`
8. Open the app in your browser:
   - `http://127.0.0.1:5000`
9. Validate readiness inside the app:
   - Go to **Settings** -> **Offline Readiness Check**
   - Click **Check cache status**
   - Confirm required models are cached

What the bootstrap script does automatically:
- creates/reuses `.venv`
- checks required tools and guides manual fallback if needed
- installs Python dependencies
- logs into Hugging Face CLI using your token
- downloads MedGemma models to `data\models_cache\hub`
- optionally installs `llama-cpp-python` for quantized 27B CPU mode
- writes `.env.windows` with CPU-safe defaults

If you prefer command-line install, use Appendix A.

---

## =====================================================
## 3) Hugging Face Terms Requirement
## =====================================================
The bootstrap will ask, but you must do this before model download can succeed.  
Why this is necessary: MedGemma access is permission-gated.

1. Create account: `https://huggingface.co/join`
2. Accept model terms on:
   - `https://huggingface.co/google/medgemma-1.5-4b-it`
   - `https://huggingface.co/google/medgemma-27b-text-it`
3. Create a Read token: `https://huggingface.co/settings/tokens`

If terms are not accepted, download commands return 403/unauthorized.

---

## =====================================================
## 4) Quick Troubleshooting
## =====================================================

### `hf` command not found
Meaning: Hugging Face CLI not available in the active environment.  
Fix: rerun bootstrap; it installs `huggingface-hub` and uses a Python fallback CLI path if needed.

### 403/Unauthorized downloading models
Meaning: terms or auth are incomplete.  
Fix:
- confirm terms accepted on both model pages
- confirm token is valid
- rerun `launch_windows_bootstrap.cmd`

### `winget` not found during bootstrap
Meaning: Windows package manager is unavailable on this machine.  
Fix:
- install Git manually from `https://git-scm.com/download/win`
- install Python 3.11 manually using:
  - `https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe`
- rerun bootstrap, or use Appendix A manual path
- this is common in some Windows Sandbox images
- if the project was installed from ZIP, you can continue without Git

### Downloaded `python-manager-*.msix` and Windows cannot open it
Meaning: you downloaded the Python Manager package, not the Python runtime installer used by this project.  
Fix:
- ignore/remove the `.msix` file
- install Python 3.11 using one of these:
  - `winget install --id Python.Python.3.11 -e`
  - `https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe`
- verify with:
  - `py -3.11 --version`

### Quantized 27B option missing in model dropdown
Meaning: GGUF path or llama-cpp backend is not configured.  
Fix:
- install `llama-cpp-python`
- in the app, open **Settings -> MedGemma Model Parameters -> Quantized 27B CPU (Optional)** and set the GGUF file path

---

## =====================================================
## 5) macOS Install Everything (Automated, Recommended)
## =====================================================
This section is the macOS equivalent of Section 2.
It uses double-click launchers and guided prompts, with fallback instructions for older Macs.

### 5.0 What is Terminal and how to open it
**Terminal** is the macOS command window where you type commands.
For this automated flow, you mostly use double-click launchers, but Terminal may open automatically and ask for simple input.

How to open Terminal:
1. Press `Command + Space`.
2. Type `Terminal`.
3. Press **Enter**.

### 5.1 Step-by-step macOS install
1. Download the project ZIP:
   - `https://github.com/rickeae/SailingMedAdvisor-crossplatform`
   - Click **Code** -> **Download ZIP**
2. Extract the ZIP and open the extracted folder.
3. Run the macOS bootstrap launcher:
   - Double-click `launch_macos_bootstrap.command`
4. If macOS blocks it:
   - Right-click `launch_macos_bootstrap.command` -> **Open** -> **Open**
5. Follow on-screen prompts:
   - install missing dependencies if prompted (Xcode Command Line Tools / Homebrew / Python 3.11)
   - accept MedGemma terms confirmation
   - enter Hugging Face token
   - choose 4B-only or 4B+27B download
6. Start the app:
   - Double-click `launch_macos_app.command`
7. Open in browser:
   - `http://127.0.0.1:5000`
8. Validate readiness:
   - Settings -> Offline Readiness Check -> Check cache status

What the macOS bootstrap does automatically:
- checks for Xcode Command Line Tools
- installs or finds Python 3.11
- creates/reuses `.venv`
- installs Python dependencies
- logs into Hugging Face CLI using your token
- downloads MedGemma models to `data/models_cache/hub`
- optionally installs `llama-cpp-python` for quantized 27B CPU mode
- writes `.env.macos` with CPU-safe defaults

### 5.2 macOS uninstall
1. Open project folder.
2. Double-click `launch_macos_uninstall.command`.
3. Answer the Yes/No prompts.

---

## =====================================================
## 6) macOS Quick Troubleshooting
## =====================================================

### macOS says file cannot be opened
Meaning: Gatekeeper blocked an unsigned script.
Fix:
- Right-click the `.command` file -> **Open** -> **Open**

### `xcode-select` prompt appears
Meaning: Command Line Tools are missing.
Fix:
- Complete the Apple installer prompt
- Rerun `launch_macos_bootstrap.command`

### Homebrew missing
Meaning: older or fresh macOS install.
Fix:
- let bootstrap install Homebrew when prompted
- or install manually:
  - `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

### Python 3.11 not detected
Fix:
- let bootstrap install via Homebrew
- reopen Terminal and rerun `launch_macos_bootstrap.command`

### `.command` launcher closes too quickly
Fix:
- open Terminal manually
- run launcher from repo root:
  - `./launch_macos_bootstrap.command`
  - `./launch_macos_app.command`
  - `./launch_macos_uninstall.command`

---

## =====================================================
## Appendix A - Manual Install Instructions (Windows)
## =====================================================

These are the full Windows manual steps (kept intentionally for users who want full control).

### A0) Open Command Prompt
Command Prompt is the Windows command window used for manual commands in this appendix.

1. Click **Start**.
2. Type `cmd`.
3. Click **Command Prompt**.

Alternative:
1. Press `Windows key + R`.
2. Type `cmd`.
3. Press **Enter**.

### A1) Install Required Software
This section installs baseline tools needed to run Python projects from GitHub.  
Why this is necessary: without these tools, manual setup cannot proceed.

#### A1.1 Install Git for Windows
This installs Git, which downloads and updates the project code from GitHub.  
Why this is necessary: SailingMedAdvisor source code is versioned in Git.
If you already downloaded a ZIP of the project, Git is optional for first-time run.

1. Go to: `https://git-scm.com/download/win`
2. Install with default options.
3. Verify:

```powershell
git --version
```

#### A1.2 Install Python 3.11 (64-bit)
This installs the Python runtime used by the backend and setup scripts.  
Why this is necessary: the app is built in Python and requires a compatible interpreter.

1. Preferred install command:

```powershell
winget install --id Python.Python.3.11 -e
```

2. Alternative direct installer (`.exe`, avoid `.msix` manager package):
   - `https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe`
3. During install, check **Add Python to PATH**.
4. Verify:

```powershell
py -3.11 --version
python --version
```

#### A1.3 (Recommended) Install Microsoft C++ Build Tools
This installs native compilers used by some Python packages.  
Why this is necessary: optional quantized 27B support may need local compilation.

1. Go to: `https://visualstudio.microsoft.com/visual-cpp-build-tools/`
2. Install **Desktop development with C++** workload.

### A2) Clone the Crossplatform Repository
This downloads your local copy of the code.  
Why this is necessary: you cannot run the app until files exist locally.

```powershell
cd $HOME
git clone https://github.com/rickeae/SailingMedAdvisor-crossplatform.git
cd .\SailingMedAdvisor-crossplatform
```

### A3) Create Virtual Environment
This creates an isolated Python workspace for this project only.  
Why this is necessary: it prevents dependency conflicts with other Python projects.

```powershell
py -3.11 -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip setuptools wheel
```

If PowerShell blocks activation:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.venv\Scripts\Activate.ps1
```

### A4) Install Python Dependencies (Windows CPU)
This installs required runtime packages.  
Why this is necessary: missing packages cause startup/import failures.

Install core app packages:

```powershell
pip install fastapi uvicorn jinja2 python-multipart aiofiles pillow itsdangerous huggingface-hub transformers accelerate safetensors
```

Install CPU PyTorch:

```powershell
pip install torch --index-url https://download.pytorch.org/whl/cpu
```

Install optional quantized 27B backend:

```powershell
pip install llama-cpp-python
```

### A5) Hugging Face Account + MedGemma Terms + Token
This enables authenticated model download access.  
Why this is necessary: MedGemma downloads require accepted terms and auth token.

#### A5.1 Create Hugging Face account
This creates your identity on Hugging Face.  
Why this is necessary: permissions and tokens are account-bound.

- `https://huggingface.co/join`

#### A5.2 Accept MedGemma terms
This records your acceptance of MedGemma terms.  
Why this is necessary: without this, downloads are rejected.

Open and accept terms on:
- `https://huggingface.co/google/medgemma-1.5-4b-it`
- `https://huggingface.co/google/medgemma-27b-text-it`

#### A5.3 Create a Hugging Face access token
This creates a secure CLI credential.  
Why this is necessary: browser login alone does not authorize CLI downloads.

1. Open: `https://huggingface.co/settings/tokens`
2. Create token with **Read** scope.
3. Copy token securely.

#### A5.4 Login from terminal
This stores token auth locally for CLI usage.  
Why this is necessary: `hf download` depends on authenticated state.

```powershell
hf auth login
hf auth whoami
```

### A6) Download MedGemma Models Locally
This downloads model files for local inference.  
Why this is necessary: the app expects local models, not cloud inference.

SailingMedAdvisor expects model cache under `data\models_cache\hub`.

```powershell
$cache = Join-Path (Get-Location) "data\models_cache\hub"
New-Item -ItemType Directory -Force -Path $cache | Out-Null

hf download google/medgemma-1.5-4b-it --cache-dir $cache
hf download google/medgemma-27b-text-it --cache-dir $cache
```

### A7) (Optional) Configure Quantized 27B in App Settings
This points app runtime to a local `.gguf` file using the UI.  
Why this is necessary: quantized option appears only when a valid GGUF path is configured.

1. Start the app (`python .\app.py`).
2. Open `http://127.0.0.1:5000`.
3. Go to **Settings -> MedGemma Model Parameters -> Quantized 27B CPU (Optional)**.
4. Enter your GGUF file path.
5. (Optional) Set Context Window and CPU Threads.

Advanced fallback (optional): you can still use environment variables:

```powershell
$env:MEDGEMMA_27B_GGUF_PATH = "C:\path\to\medgemma-27b-q4_k_m.gguf"
```

### A8) Run the App (CPU Mode)
This starts local server in CPU-safe configuration.  
Why this is necessary: manual path assumes CPU-first Windows runtime.

```powershell
$env:FORCE_CUDA = "0"
$env:ALLOW_CPU_FALLBACK_ON_CUDA_ERROR = "1"
python .\app.py
```

Open:
- `http://127.0.0.1:5000`

### A9) Verify App Readiness
This confirms model visibility and configuration correctness.  
Why this is necessary: catches setup errors early.

1. In app: **Settings** -> **Offline Readiness Check**
2. Click **Check cache status**
3. Confirm required models are cached

### A10) Manual Path Common Issues

#### `hf` command not found
- Close/reopen terminal
- Ensure the active venv has `huggingface-hub` installed
- Try:

```powershell
hf --help
```

#### 403/Unauthorized when downloading MedGemma
- Confirm terms accepted on both model pages
- Confirm `hf auth whoami` matches expected account

#### App says model cache missing
- Confirm downloads used `--cache-dir .\data\models_cache\hub`
- Re-run Offline Readiness Check

#### `llama-cpp-python` install fails
- Install C++ Build Tools
- Retry install

#### 27B is too slow on CPU
- Use 4B for faster response
- Reserve 27B for slow/deep reasoning use cases

---

## =====================================================
## Security Notes
## =====================================================

- Do not store Hugging Face tokens in source code.
- Do not commit tokens, `.env` files with secrets, or cached credentials to git.
- Users should download/convert models locally after accepting license terms.
