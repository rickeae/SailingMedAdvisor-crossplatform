# SailingMedAdvisor Linux Install Guide

This guide is for Linux users.
Current installer path is targeted at Ubuntu/Debian style systems.

## 1) Estimated System Requirements

These numbers are estimates, not guarantees. They are based on common Linux systems running local inference. Actual needs can vary by distro, desktop environment, background services, and how much swap space is already configured.

1. Linux x86_64
2. RAM (working memory used while the app runs):
- Minimum: 16 GB
- Recommended: 32 GB
3. Free disk space (storage used by Python packages and model files):
- Minimum: 60 GB
- Recommended: 100 GB
4. Swap (virtual memory Linux uses when RAM is full):
- If RAM is 16 GB or less, set swap to 32-64 GB
- If RAM is 24 GB or less, set swap to at least 32 GB
5. Internet for first install

## 2) Create Hugging Face Token

1. Create account: `https://huggingface.co/join`
2. Accept model terms:
- `https://huggingface.co/google/medgemma-1.5-4b-it`
- `https://huggingface.co/google/medgemma-27b-text-it`
3. Open token page: `https://huggingface.co/settings/tokens`
4. Click `Create new token`
5. Token name: for example `medgemma`
6. Scope: `Read`
7. Click `Create token`
8. Copy token now and save it in a local text file.
- Hugging Face will not show the full token again.

## 3) Install (One Script)

1. Download ZIP:
- `https://github.com/rickeae/SailingMedAdvisor-crossplatform`
2. Extract ZIP.
3. Open terminal in folder `SailingMedAdvisor-crossplatform`.
4. Run:

```bash
chmod +x launch_linux_installer.sh
./launch_linux_installer.sh
```

5. Enter your Linux password if `sudo` asks for it.
6. Paste your Hugging Face token when asked.
7. Wait for setup to finish.

The installer now runs a fixed full setup automatically:
- Creates/reuses `.venv`
- Installs required Python packages
- Installs CPU PyTorch
- Asks which models to download:
  - `4B only` (recommended for most systems)
  - `4B + 27B` (larger download and heavier runtime)
- Writes local runtime config files

### Token Paste Tip (Linux)

When the installer asks for your Hugging Face token, the input is hidden for safety.
In many Linux terminals, nothing is shown while you type or paste. That is normal.

1. Click inside the terminal window once.
2. Paste token:
- `Ctrl+Shift+V` (common Linux terminal shortcut)
- or right-click and choose `Paste`
3. Press `Enter`.

## 4) Start App

From the same folder, run:

```bash
./run_med_advisor.sh
```

Open browser:
- `http://127.0.0.1:5000`

## 5) If Something Fails

1. If model download fails with `403`:
- Recheck model terms acceptance
- Create a new Read token
- Run installer again
2. If Python 3.11 is missing:
- Let installer install it (Ubuntu/Debian)
- Or install manually, then rerun installer
3. If memory is too low:
- Increase swap
- Close other apps
- Reboot and try again

## 6) Uninstall

No dedicated Linux uninstall launcher yet.
To remove this install, delete the folder and optional virtual environment:

```bash
rm -rf SailingMedAdvisor-crossplatform
```
