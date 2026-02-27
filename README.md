---
title: SailingMedAdvisor
emoji: ⛵
colorFrom: blue
colorTo: indigo
sdk: docker
pinned: false
---

# SailingMedAdvisor

Offline-first emergency decision support for offshore crews, using Google MedGemma models with a structured triage workflow.

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

## What This Repository Contains

This repository contains the active application code and core runtime assets for:

- FastAPI backend (`app.py`)
- SQLite persistence layer (`app.db`, `db_store.py`)
- MedGemma inference adapters (`medgemma4.py`, `medgemma27b.py`, `medgemma_common.py`)
- Frontend UI (`templates/`, `static/`)
- Default seed data (`data/default/`)
- Startup script (`run_med_advisor.sh`)

Non-project scratch/export artifacts have been removed from version control.

## Core Capabilities

- Triage and inquiry consultation modes
- Clinical triage pathway dropdowns (Domain, Problem, Anatomy, Mechanism/Cause, Severity/Complication)
- Patient condition capture (Consciousness, Breathing, Circulation, Overall Stability)
- Prompt assembly with pathway fallback to general triage instructions when path coverage is incomplete
- Consultation logging with restore/demo-restore workflows
- Crew, vessel, inventory, and settings management from UI
- Model parameters in Settings (temperature, top-p, top-k, token limits, etc.)

## Models

- `google/medgemma-1.5-4b-it`
- `google/medgemma-27b-text-it` (runtime adapter file: `medgemma27b.py`)
- Optional slow/deep CPU path: `local/medgemma-27b-quantized-cpu` (GGUF + `llama-cpp-python`)

Both model paths are wired to use settings-defined sampling/token parameters.

For licensing safety, distribute code only and have each user download/convert models locally after accepting MedGemma terms.

## Quick Start (Single Install Path)

For end users, installation is intentionally simple:
- Download ZIP from this repository.
- Extract ZIP.
- Run one installer script for your platform.

Platform installer guide:
- `README-Crossplatform-Installer.md`

One installer script per platform:
- Windows: `launch_windows_bootstrap.cmd`
- macOS: `launch_macos_bootstrap.command`

## Demo Reproduction (27B scenario)

For the Kaggle demo scenario, use the 27B model path in the UI:

1. Open `http://127.0.0.1:5000`.
2. In MedGemma Consultation, choose `Triage Consultation`.
3. Set model to `google/medgemma-27b-text-it`.
4. Enter the fish-hook cheek scenario used in the demo.
5. Select the matching clinical triage pathway values.
6. Submit and compare output structure against the demo video.

## Authentication Behavior

- If crew credentials are configured, login is required.
- If no credentials are configured yet, login is auto-admitted.

Credentials are managed from the app UI (Vessel & Crew / Settings flows).

## Data Storage

- Primary runtime data is stored in `app.db`.
- Default dataset JSONs live in `data/default/` and are used for baseline content and seeding support.

To regenerate a clean population database for fresh installs (keep prompts/settings, clear consultation/inventory/crew/vessel/last-prompt):

```bash
python3 scripts/prepare_population_db.py app.db seed/app.db
```

## Repository Layout (Primary)

```text
SailingMedAdvisor/
├── app.py
├── app.db
├── db_store.py
├── medgemma4.py
├── medgemma27b.py
├── medgemma_common.py
├── run_med_advisor.sh
├── requirements.txt
├── templates/
├── static/
├── scripts/
└── data/default/
```

## Operational Notes

- The startup script performs CUDA preflight when `FORCE_CUDA=1` (default).
- CPU fallback on CUDA runtime errors is disabled by default (`ALLOW_CPU_FALLBACK_ON_CUDA_ERROR=0`).
- If GPU is already occupied, the app surfaces a GPU-busy style failure message instead of silently switching devices.

## Medical Safety Note

This software is a decision-support aid for constrained/offshore scenarios.  
It is not a replacement for licensed medical professionals or emergency services.
