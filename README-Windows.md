# SailingMedAdvisor Windows Install Guide

This guide is for Windows users.
The steps are written in plain language and explain what each action does.

## 1) Estimated System Requirements

These numbers are estimates, not guarantees. They are based on typical Windows laptops running local MedGemma models. Actual needs can vary based on background apps, available disk speed, and other software already running on your machine.

1. 64-bit Windows 10 or 11
2. RAM (working memory used while the app runs):
- Minimum: 16 GB
- Recommended: 32 GB
3. Free disk space (storage used by Python packages and model files):
- Minimum: 60 GB
- Recommended: 100 GB
4. Virtual memory (Windows paging file used when RAM is full):
- If RAM is 16 GB, set paging file to (steps are provided below):
  - Initial size: `32768` MB
  - Maximum size: `65536` MB
5. Internet for first install

## 2) Set Windows Virtual Memory First (Important)

If this is not set, PyTorch may fail with `os error 1455`.

1. Press the Windows key.
2. Search for `View advanced system settings`.
3. In the `System Properties` window, click the `Advanced` tab.
4. Under `Performance`, click `Settings`.
5. In the `Performance Options` window, click the `Advanced` tab.
6. Under `Virtual memory`, click `Change`.
7. Uncheck `Automatically manage paging file size for all drives`.
8. Select drive `C:`.
9. Choose `Custom size`.
10. Enter:
- Initial size: `32768`
- Maximum size: `65536`
11. Click `Set`.
12. Click `OK` on all open windows to apply the change.
13. Reboot Windows.

## 3) Create Hugging Face Token

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

## 4) Install (One Script)

1. Download ZIP:
- `https://github.com/rickeae/SailingMedAdvisor-crossplatform`
2. Extract ZIP.
3. Open folder `SailingMedAdvisor-crossplatform`.
4. Double-click:
- `launch_windows_installer.cmd`
5. Paste your Hugging Face token when asked.
6. Wait for setup to finish.

The installer now runs a fixed full setup automatically:
- Creates/reuses `.venv`
- Installs required Python packages
- Installs CPU PyTorch
- Asks which models to download:
  - `4B only` (recommended for most systems)
  - `4B + 27B` (larger download and heavier runtime)
- Writes local runtime config files

### Token Paste Tip (Windows)

When the installer asks for your Hugging Face token, the input is hidden for safety.
This means you may not see characters appear while typing or pasting. That is normal.

1. Click inside the terminal window once.
2. Paste token:
- `Ctrl+V` (Windows Terminal / newer cmd)
- or right-click and choose `Paste`
3. Press `Enter`.

## 5) Start App

1. In the same folder, double-click:
- `launch_windows_app.cmd`
2. Open browser:
- `http://127.0.0.1:5000`

## 6) First Startup Dialogs (Normal)

On first start, Windows may show one or more security dialogs. These are expected.

1. If you see `Windows protected your PC`:
- Click `More info`
- Click `Run anyway`

2. If you see `Windows Security Alert` for Python:
- This appears because SailingMedAdvisor runs a local web server on your own machine.
- Check `Private networks` only
- Click `Allow access`

3. If a terminal window says token input is hidden:
- This is normal for secure token entry.
- Paste token, then press `Enter`.

## 7) If Something Fails

1. If you see `os error 1455` or `paging file is too small`:
- Recheck virtual memory settings in Section 2
- Reboot
- Run installer again
2. If model download fails with `403`:
- Recheck model terms acceptance
- Create a new Read token
- Run installer again
3. If SmartScreen blocks scripts:
- Click `More info` then `Run anyway`

## 8) Uninstall

Run:
- `launch_windows_uninstall.cmd`
