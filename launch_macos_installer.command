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
echo "Starting SailingMedAdvisor macOS installer..."
./scripts/macos_installer.sh
exit_code=$?

echo
if [[ $exit_code -ne 0 ]]; then
  echo "Installer failed with exit code $exit_code."
else
  echo "Installer finished successfully."
  read -r -p "Start SailingMedAdvisor now? [y/N]: " start_now
  case "${start_now:-}" in
    y|Y|yes|YES)
      ./launch_macos_app.command
      exit $?
      ;;
  esac
fi
echo
read -r -n 1 -s -p "Press any key to close..."
echo
exit $exit_code
