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

write_info() {
  echo "[INFO] $1"
}

write_warn() {
  echo "[WARN] $1"
}

test_yes() {
  local prompt="$1"
  local default="${2:-Y}"
  local suffix="[Y/n]"
  if [[ "${default^^}" != "Y" ]]; then
    suffix="[y/N]"
  fi
  read -r -p "$prompt $suffix " raw
  if [[ -z "${raw}" ]]; then
    [[ "${default^^}" == "Y" ]]
    return
  fi
  case "${raw,,}" in
    y|yes|1|true) return 0 ;;
    *) return 1 ;;
  esac
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

resolve_python311() {
  if command -v python3.11 >/dev/null 2>&1; then
    command -v python3.11
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    if python3 - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if (sys.version_info.major, sys.version_info.minor) == (3, 11) else 1)
PY
    then
      command -v python3
      return 0
    fi
  fi
  return 1
}

ensure_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    return 0
  fi
  write_warn "Xcode Command Line Tools are not installed."
  write_info "They are needed to build Python packages."
  if test_yes "Install Xcode Command Line Tools now?" "Y"; then
    if xcode-select --install >/dev/null 2>&1; then
      write_info "Installer launched. Complete it, then rerun launch_macos_bootstrap.command."
    else
      write_warn "Install command returned non-zero. It may already be in progress."
      write_info "Complete Command Line Tools installation, then rerun launch_macos_bootstrap.command."
    fi
  fi
  exit 1
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  write_warn "Homebrew is not installed."
  write_info "Homebrew is the easiest way to install Python 3.11 on older/newer macOS versions."
  if ! test_yes "Install Homebrew now?" "Y"; then
    echo "Install Homebrew manually, then rerun:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
  fi
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew still not detected in this shell."
    echo "Open a new Terminal window and rerun launch_macos_bootstrap.command."
    exit 1
  fi
}

ensure_python311() {
  local py
  if py="$(resolve_python311)"; then
    echo "$py"
    return 0
  fi

  ensure_homebrew
  write_info "Installing Python 3.11 via Homebrew..."
  brew install python@3.11

  local brew_py=""
  brew_py="$(brew --prefix python@3.11)/bin/python3.11" || true
  if [[ -n "$brew_py" && -x "$brew_py" ]]; then
    echo "$brew_py"
    return 0
  fi
  if py="$(resolve_python311)"; then
    echo "$py"
    return 0
  fi
  echo "Python 3.11 is still not detected."
  echo "Install manually and rerun launch_macos_bootstrap.command."
  exit 1
}

invoke_hf() {
  local py_exec="$1"
  shift
  if command -v hf >/dev/null 2>&1; then
    hf "$@"
  else
    "$py_exec" -m huggingface_hub.commands.hf_cli "$@"
  fi
}

install_python_deps() {
  local py_exec="$1"
  write_info "Upgrading pip/setuptools/wheel..."
  "$py_exec" -m pip install --upgrade pip setuptools wheel

  write_info "Installing core Python packages..."
  "$py_exec" -m pip install \
    fastapi \
    uvicorn \
    jinja2 \
    python-multipart \
    aiofiles \
    pillow \
    itsdangerous \
    huggingface-hub \
    transformers \
    accelerate \
    safetensors

  write_info "Installing PyTorch..."
  "$py_exec" -m pip install torch
}

write_section "SailingMedAdvisor macOS Bootstrap"
write_info "Repository root: $repo_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[ERROR] This script is for macOS only."
  exit 1
fi

write_section "Preflight Checks"
ensure_clt
python_cmd="$(ensure_python311)"
write_info "Using Python: $python_cmd"
"$python_cmd" --version

venv_dir="$repo_root/.venv"
venv_python="$venv_dir/bin/python"

write_section "Create / Reuse Virtual Environment"
if [[ ! -x "$venv_python" ]]; then
  write_info "Creating .venv with Python 3.11..."
  "$python_cmd" -m venv "$venv_dir"
else
  write_info ".venv already exists. Reusing existing environment."
fi

install_python_deps "$venv_python"

write_section "Hugging Face Setup"
echo "Before continuing, you must accept MedGemma terms on:"
echo "  https://huggingface.co/google/medgemma-1.5-4b-it"
echo "  https://huggingface.co/google/medgemma-27b-text-it"
if ! test_yes "Have you accepted the terms on both model pages?" "N"; then
  echo "Terms not accepted yet. Complete terms acceptance, then rerun bootstrap."
  exit 1
fi

read -r -s -p "Paste your Hugging Face token (input hidden): " hf_token
echo
if [[ -z "${hf_token}" ]]; then
  echo "No token provided. Cannot continue."
  exit 1
fi

write_info "Logging in to Hugging Face CLI..."
invoke_hf "$venv_python" auth login --token "$hf_token"

if [[ "${1:-}" != "--skip-model-download" ]]; then
  write_section "Model Download"
  cache_dir="$repo_root/data/models_cache/hub"
  mkdir -p "$cache_dir"
  write_info "Model cache path: $cache_dir"
  echo
  echo "Choose model download mode:"
  echo "  1) 4B only (fastest setup)"
  echo "  2) 4B + 27B (larger download)"
  echo "  3) Skip model download for now"
  read -r -p "Enter choice [1/2/3]: " choice
  choice="${choice:-1}"

  case "$choice" in
    1)
      write_info "Downloading MedGemma 4B..."
      invoke_hf "$venv_python" download google/medgemma-1.5-4b-it --cache-dir "$cache_dir" --token "$hf_token"
      ;;
    2)
      write_info "Downloading MedGemma 4B..."
      invoke_hf "$venv_python" download google/medgemma-1.5-4b-it --cache-dir "$cache_dir" --token "$hf_token"
      write_info "Downloading MedGemma 27B..."
      invoke_hf "$venv_python" download google/medgemma-27b-text-it --cache-dir "$cache_dir" --token "$hf_token"
      ;;
    3)
      write_warn "Skipping model download by user choice."
      ;;
    *)
      write_warn "Unknown choice '$choice'. Defaulting to 4B only."
      invoke_hf "$venv_python" download google/medgemma-1.5-4b-it --cache-dir "$cache_dir" --token "$hf_token"
      ;;
  esac
else
  write_warn "Skipping model download due to --skip-model-download."
fi

write_section "Optional Quantized 27B CPU Setup"
if test_yes "Install llama-cpp-python for optional quantized 27B CPU mode?" "N"; then
  if ! "$venv_python" -m pip install llama-cpp-python; then
    write_warn "Could not install llama-cpp-python. You can retry later."
  fi
fi
write_info "GGUF path/config is managed inside SailingMedAdvisor Settings."

write_section "Write Local Runtime Config"
env_file="$repo_root/.env.macos"
cat >"$env_file" <<'EOF'
# Auto-generated by scripts/bootstrap_macos.sh
FORCE_CUDA=0
ALLOW_CPU_FALLBACK_ON_CUDA_ERROR=1
EOF
write_info "Wrote: $env_file"

write_section "Bootstrap Complete"
echo "Next steps:"
echo "  1) Start app: ./launch_macos_app.command"
echo "  2) Open: http://127.0.0.1:5000"
echo "  3) Verify in Settings -> Offline Readiness Check"

