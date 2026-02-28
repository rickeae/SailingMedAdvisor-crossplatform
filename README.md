# SailingMedAdvisor

Offline emergency medical guidance for offshore crews, powered by Google MedGemma.

This repository now has one install guide per platform:

1. Windows: `README-Windows.md`
2. macOS: `README-macOS.md`
3. Linux: `README-Linux.md`

Each platform uses one installer launcher:

1. Windows: `launch_windows_installer.cmd`
2. macOS: `launch_macos_installer.command`
3. Linux: `launch_linux_installer.sh`

## Estimated System Requirements

These are practical estimates for CPU-first installs:

| Platform | RAM (minimum) | RAM (recommended) | Free disk | Virtual memory guidance |
| --- | --- | --- | --- | --- |
| Windows | 16 GB | 32 GB | 60+ GB | Set paging file to 32768 MB min, 65536 MB max when RAM is 16 GB |
| macOS | 16 GB | 24+ GB | 80+ GB | macOS manages swap automatically; keep lots of free disk space |
| Linux | 16 GB | 32 GB | 60+ GB | If RAM <=16 GB, configure 32-64 GB swap |

Important:
1. 4B is the normal model for these systems.
2. 27B on CPU is a slow/deep option and not recommended for low-memory machines.
3. Platform installers run a full fixed setup and download both 4B and 27B by default.

## Before Install

1. Create a Hugging Face account: `https://huggingface.co/join`
2. Accept MedGemma terms:
- `https://huggingface.co/google/medgemma-1.5-4b-it`
- `https://huggingface.co/google/medgemma-27b-text-it`
3. Create a Read token:
- `https://huggingface.co/settings/tokens`

## Project Notes

1. Backend: FastAPI + SQLite
2. Frontend: HTML/CSS/JavaScript
3. Main app: `app.py`
4. License: `LICENSE` (CC BY 4.0)

## Help

If you run into trouble, start with your platform readme first (`README-Windows.md`, `README-macOS.md`, or `README-Linux.md`).
