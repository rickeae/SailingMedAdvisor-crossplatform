# SailingMedAdvisor Windows Install Guide

This guide is for Windows users.
It is written for users who are smart but not highly technical.

## 1) Estimated System Requirements

1. 64-bit Windows 10 or 11
2. RAM:
- Minimum: 16 GB
- Recommended: 32 GB
3. Free disk:
- Minimum: 60 GB
- Recommended: 100 GB
4. Virtual memory (paging file):
- If RAM is 16 GB, set paging file to:
  - Initial size: `32768` MB
  - Maximum size: `65536` MB
5. Internet for first install

## 2) Set Windows Virtual Memory First (Important)

If this is not set, PyTorch may fail with `os error 1455`.

1. Press the Windows key.
2. Search for `View advanced system settings`.
3. Open it.
4. Click `Settings` under `Performance`.
5. Open the `Advanced` tab.
6. Under `Virtual memory`, click `Change`.
7. Uncheck `Automatically manage paging file size`.
8. Select drive `C:`.
9. Choose `Custom size`.
10. Set:
- Initial size: `32768`
- Maximum size: `65536`
11. Click `Set`, then `OK`.
12. Reboot Windows.

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
- Downloads both MedGemma models (4B and 27B)
- Writes local runtime config files

There are no model selection prompts during install.

## 5) Start App

1. In the same folder, double-click:
- `launch_windows_app.cmd`
2. Open browser:
- `http://127.0.0.1:5000`

## 6) If Something Fails

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

## 7) Uninstall

Run:
- `launch_windows_uninstall.cmd`
