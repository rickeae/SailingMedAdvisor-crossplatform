# SailingMedAdvisor Crossplatform Install Guide (Windows + macOS)

## Project Banner

| Field | Details |
| --- | --- |
| Project | `SailingMedAdvisor` |
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

This guide contains install instructions for both Windows and macOS.

Windows instructions appear first.
macOS instructions appear right after Windows.
Manual crossplatform steps appear in Appendix A.

---

## =====================================================
## 1) WINDOWS
## =====================================================

```text
__        ___ _   _ ____   _____        _____
\ \      / (_) \ | |  _ \ / _ \ \      / / __|
 \ \ /\ / /| |  \| | | | | | | \ \ /\ / /\__ \
  \ V  V / | | |\  | |_| | |_| |\ V  V / |___/
   \_/\_/  |_|_| \_|____/ \___/  \_/\_/       
```

### 1.1 Windows Remove (Uninstall) First

Run this file from the project folder:

```bat
launch_windows_uninstall.cmd
```

Steps:
1. Open File Explorer.
2. Open your `SailingMedAdvisor-crossplatform` folder.
3. Double-click `launch_windows_uninstall.cmd`.
4. Answer `y` or `n` for each removal prompt.
5. Press any key to close the window at the end.

What it can remove:
- `.venv`
- `data\models_cache`
- `.env.windows`
- `data\runtime.log`
- `app.db` (optional)

If you also want to remove source files, delete the `SailingMedAdvisor-crossplatform` folder itself.

### 1.2 Windows Install (Automated, Recommended)

This is the easiest path for most users.

1. Install Python 3.11 (64-bit) from:
   - `https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe`
2. During install:
   - check **Add Python to PATH**
   - click **Install Now**
3. Download project ZIP:
   - `https://github.com/rickeae/SailingMedAdvisor-crossplatform`
   - click **Code -> Download ZIP**
4. Extract ZIP and open folder `SailingMedAdvisor-crossplatform`.
5. Double-click:
   - `launch_windows_bootstrap.cmd`
6. Follow prompts:
   - confirm MedGemma terms were accepted
   - paste Hugging Face token
   - choose 4B-only or 4B+27B model download
   - optional: install quantized 27B CPU backend
7. After bootstrap completes, double-click:
   - `launch_windows_app.cmd`
8. Open browser to:
   - `http://127.0.0.1:5000`
9. In app, validate:
   - `Settings -> Offline Readiness Check -> Check cache status`

---

## =====================================================
## 2) MACOS
## =====================================================

```text
 __  __    _    ____
|  \/  |  / \  / ___|
| |\/| | / _ \| |
| |  | |/ ___ \ |___
|_|  |_/_/   \_\____|
```

### 2.1 macOS Remove (Uninstall) First

Run this file from the project folder:

```bash
./launch_macos_uninstall.command
```

Steps:
1. Open Finder.
2. Open your `SailingMedAdvisor-crossplatform` folder.
3. Double-click `launch_macos_uninstall.command`.
4. If blocked, right-click -> Open -> Open.
5. Answer `y` or `n` for each removal prompt.

What it can remove:
- `.venv`
- `data/models_cache`
- `.env.macos`
- `data/runtime.log`
- `app.db` (optional)

If you also want to remove source files, move the `SailingMedAdvisor-crossplatform` folder to Trash.

### 2.2 macOS Install (Automated, Recommended)

1. Download project ZIP:
   - `https://github.com/rickeae/SailingMedAdvisor-crossplatform`
   - click **Code -> Download ZIP**
2. Extract ZIP and open folder `SailingMedAdvisor-crossplatform`.
3. Double-click:
   - `launch_macos_bootstrap.command`
4. If blocked by Gatekeeper:
   - right-click file -> **Open** -> **Open**
5. Follow prompts:
   - install missing dependencies if prompted
   - confirm MedGemma terms were accepted
   - paste Hugging Face token
   - choose 4B-only or 4B+27B model download
6. Start app:
   - double-click `launch_macos_app.command`
7. Open browser to:
   - `http://127.0.0.1:5000`
8. In app, validate:
   - `Settings -> Offline Readiness Check -> Check cache status`

---

## =====================================================
## 3) Hugging Face Terms Requirement (Both Platforms)
## =====================================================

Before model download, you must:

1. Create account:
   - `https://huggingface.co/join`
2. Accept model terms on:
   - `https://huggingface.co/google/medgemma-1.5-4b-it`
   - `https://huggingface.co/google/medgemma-27b-text-it`
3. Create token (Read scope):
   - `https://huggingface.co/settings/tokens`

If terms are not accepted, downloads fail with `403/unauthorized`.

---

## =====================================================
## 4) Quick Troubleshooting (Both Platforms)
## =====================================================

### Download failed with 403/Unauthorized
- Confirm terms accepted on both model pages.
- Confirm token is valid.
- Re-run bootstrap launcher.

### Hugging Face CLI command not found
- Re-run bootstrap launcher (it installs dependencies).
- Or run manual appendix steps for environment setup.

### Downloaded a `.msix` Python package and it does not open (Windows)
- Ignore/remove that file.
- Install Python 3.11 from:
  - `https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe`

### `.command` file blocked (macOS)
- Right-click launcher -> **Open** -> **Open**.

### Quantized 27B option not visible
- Install optional quantized backend in bootstrap/manual steps.
- Set GGUF path in:
  - `Settings -> MedGemma Model Parameters -> Quantized 27B CPU (Optional)`

---

## =====================================================
## Appendix A - Manual Install (Windows + macOS Intermixed)
## =====================================================

This appendix keeps a single mixed manual flow for both platforms.

### A1) Get the project files locally

Option 1 (ZIP, easiest):
1. Open `https://github.com/rickeae/SailingMedAdvisor-crossplatform`.
2. Click **Code -> Download ZIP**.
3. Extract ZIP to a folder you can access.

Option 2 (Git clone):

Windows Command Prompt:

```powershell
cd %USERPROFILE%
git clone https://github.com/rickeae/SailingMedAdvisor-crossplatform.git
cd SailingMedAdvisor-crossplatform
```

macOS Terminal:

```bash
cd ~
git clone https://github.com/rickeae/SailingMedAdvisor-crossplatform.git
cd SailingMedAdvisor-crossplatform
```

### A2) Install Python 3.11

Windows:
- Install from:
  - `https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe`
- Verify:

```powershell
py -3.11 --version
```

macOS (Homebrew path):

```bash
brew install python@3.11
python3.11 --version
```

### A3) Create and activate a virtual environment

Windows:

```powershell
py -3.11 -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip setuptools wheel
```

macOS:

```bash
python3.11 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
```

### A4) Install app dependencies

Windows and macOS:

```bash
pip install -r requirements.txt
```

CPU PyTorch:

Windows:

```powershell
pip install torch --index-url https://download.pytorch.org/whl/cpu
```

macOS:

```bash
pip install torch
```

Optional quantized backend:

```bash
pip install llama-cpp-python
```

### A5) Authenticate to Hugging Face

1. Accept MedGemma terms:
   - `https://huggingface.co/google/medgemma-1.5-4b-it`
   - `https://huggingface.co/google/medgemma-27b-text-it`
2. Create read token:
   - `https://huggingface.co/settings/tokens`
3. Login in terminal:

```bash
hf auth login
hf auth whoami
```

### A6) Download model files to local cache

Windows:

```powershell
$cache = Join-Path (Get-Location) "data\models_cache\hub"
New-Item -ItemType Directory -Force -Path $cache | Out-Null
hf download google/medgemma-1.5-4b-it --cache-dir $cache
hf download google/medgemma-27b-text-it --cache-dir $cache
```

macOS:

```bash
cache="$(pwd)/data/models_cache/hub"
mkdir -p "$cache"
hf download google/medgemma-1.5-4b-it --cache-dir "$cache"
hf download google/medgemma-27b-text-it --cache-dir "$cache"
```

### A7) Run the app in CPU mode

Windows:

```powershell
set FORCE_CUDA=0
set ALLOW_CPU_FALLBACK_ON_CUDA_ERROR=1
python app.py
```

macOS:

```bash
export FORCE_CUDA=0
export ALLOW_CPU_FALLBACK_ON_CUDA_ERROR=1
python app.py
```

Open:
- `http://127.0.0.1:5000`

### A8) Confirm offline readiness in app

1. Open `Settings -> Offline Readiness Check`.
2. Click `Check cache status`.
3. Confirm required models are detected.

---

## =====================================================
## Security Notes
## =====================================================

- Do not store Hugging Face tokens in source code.
- Do not commit `.env` files with secrets.
- Keep model downloads local to the user machine after terms acceptance.
