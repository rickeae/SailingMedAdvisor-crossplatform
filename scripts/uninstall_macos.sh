#!/usr/bin/env bash
# =============================================================================
# Author: Rick Escher
# Project: SailingMedAdvisor
# Context: Google HAI-DEF Framework
# Models: Google MedGemmas
# Program: Kaggle Impact Challenge
# =============================================================================
set -euo pipefail

write_section() {
  echo
  echo "==== $1 ===="
}

test_yes() {
  local prompt="$1"
  local default="${2:-N}"
  local suffix="[y/N]"
  if [[ "${default^^}" == "Y" ]]; then
    suffix="[Y/n]"
  fi
  read -r -p "$prompt $suffix " raw
  if [[ -z "$raw" ]]; then
    [[ "${default^^}" == "Y" ]]
    return
  fi
  case "${raw,,}" in
    y|yes|1|true) return 0 ;;
    *) return 1 ;;
  esac
}

remove_path_safe() {
  local path="$1"
  if [[ -e "$path" ]]; then
    rm -rf "$path"
    echo "[REMOVED] $path"
  else
    echo "[SKIP] Not found: $path"
  fi
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

write_section "SailingMedAdvisor macOS Uninstall"
echo "This script removes local runtime artifacts created during install/use."
echo "Your git repository files remain unless you remove the folder manually."

venv_path="$repo_root/.venv"
cache_path="$repo_root/data/models_cache"
env_file="$repo_root/.env.macos"
runtime_log="$repo_root/data/runtime.log"
db_file="$repo_root/app.db"

write_section "Choose What To Remove"
if test_yes "Remove Python virtual environment (.venv)?" "Y"; then
  remove_path_safe "$venv_path"
fi
if test_yes "Remove downloaded model cache (data/models_cache)?" "N"; then
  remove_path_safe "$cache_path"
fi
if test_yes "Remove local macOS env file (.env.macos)?" "Y"; then
  remove_path_safe "$env_file"
fi
if test_yes "Remove runtime log (data/runtime.log)?" "Y"; then
  remove_path_safe "$runtime_log"
fi
if test_yes "Remove SQLite database (app.db)? This deletes saved app data." "N"; then
  remove_path_safe "$db_file"
fi

write_section "Uninstall Complete"
echo "If you also want to remove source code, delete this folder manually:"
echo "  $repo_root"

