#!/usr/bin/env bash
# =============================================================================
# Author: Rick Escher
# Project: SailingMedAdvisor
# Context: Google HAI-DEF Framework
# Models: Google MedGemmas
# Program: Kaggle Impact Challenge
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")"

if [[ ! -x ".venv/bin/python" ]]; then
  echo "[ERROR] Python virtual environment not found."
  echo "Run launch_macos_installer.command first."
  echo
  read -r -n 1 -s -p "Press any key to close..."
  echo
  exit 1
fi

if [[ -f ".env.macos" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env.macos"
  set +a
fi

echo "Starting SailingMedAdvisor..."
if command -v open >/dev/null 2>&1; then
  open "http://127.0.0.1:5000" || true
fi

".venv/bin/python" "./app.py"
exit_code=$?

echo
if [[ $exit_code -ne 0 ]]; then
  echo "App exited with code $exit_code."
else
  echo "App stopped."
fi
read -r -n 1 -s -p "Press any key to close..."
echo
exit $exit_code

