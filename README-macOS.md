# SailingMedAdvisor macOS Install Guide

This guide is for macOS users.
It keeps the steps simple and direct.

## 1) Estimated System Requirements

1. macOS (Intel or Apple Silicon)
2. RAM:
- Minimum: 16 GB
- Recommended: 24 GB or more
3. Free disk:
- Minimum: 80 GB
- Recommended: 120 GB
4. Virtual memory note:
- macOS manages virtual memory automatically.
- You cannot set a page file manually like Windows.
- Keep plenty of free disk space so macOS can create swap files.
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
3. Open folder `SailingMedAdvisor-crossplatform`.
4. Double-click:
- `launch_macos_installer.command`
5. If blocked:
- Right-click file, then click `Open`, then click `Open` again.
6. Follow prompts.

## 4) Start App

1. In the same folder, double-click:
- `launch_macos_app.command`
2. Open browser:
- `http://127.0.0.1:5000`

## 5) If Something Fails

1. If model download fails with `403`:
- Recheck model terms acceptance
- Create a new Read token
- Run installer again
2. If launcher is blocked:
- Right-click `.command` file and use `Open`
3. If the machine feels memory-limited:
- Close other apps
- Free disk space
- Reboot and try again

## 6) Uninstall

Run:
- `launch_macos_uninstall.command`
