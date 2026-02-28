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
echo "Starting SailingMedAdvisor Linux installer..."
chmod +x ./scripts/linux_installer.sh
./scripts/linux_installer.sh
exit_code=$?

echo
if [[ $exit_code -ne 0 ]]; then
  echo "Installer failed with exit code $exit_code."
else
  echo "Installer finished successfully."
fi
echo
exit $exit_code
