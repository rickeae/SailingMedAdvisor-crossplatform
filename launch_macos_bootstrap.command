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
echo "Starting SailingMedAdvisor macOS bootstrap..."
./scripts/bootstrap_macos.sh
exit_code=$?

echo
if [[ $exit_code -ne 0 ]]; then
  echo "Bootstrap failed with exit code $exit_code."
else
  echo "Bootstrap finished successfully."
fi
echo
read -r -n 1 -s -p "Press any key to close..."
echo
exit $exit_code

