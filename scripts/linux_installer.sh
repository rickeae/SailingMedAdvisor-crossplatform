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

ensure_python311() {
  local py
  if py="$(resolve_python311)"; then
    echo "$py"
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    write_warn "Python 3.11 not found."
    if test_yes "Install Python 3.11 now with apt-get?" "Y"; then
      if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        apt-get update
        apt-get install -y python3.11 python3.11-venv python3-pip ca-certificates curl
      else
        sudo apt-get update
        sudo apt-get install -y python3.11 python3.11-venv python3-pip ca-certificates curl
      fi
      py="$(resolve_python311 || true)"
      if [[ -n "${py}" ]]; then
        echo "$py"
        return 0
      fi
    fi
  fi

  echo "Python 3.11 is required."
  echo "Install Python 3.11, then rerun ./launch_linux_installer.sh"
  exit 1
}

validate_hf_token() {
  local py_exec="$1"
  local token="$2"
  "$py_exec" -c "from huggingface_hub import HfApi; import sys; HfApi(token=sys.argv[1].strip()).whoami(); print('HF token OK')" "$token"
}

hf_download_repo() {
  local py_exec="$1"
  local repo_id="$2"
  local cache_dir="$3"
  local token="$4"
  "$py_exec" -c "from huggingface_hub import snapshot_download; import sys; snapshot_download(repo_id=sys.argv[1], cache_dir=sys.argv[2], token=sys.argv[3]); print('HF download OK')" "$repo_id" "$cache_dir" "$token"
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

  write_info "Installing CPU PyTorch..."
  "$py_exec" -m pip install torch --index-url https://download.pytorch.org/whl/cpu
}

check_memory_swap() {
  local mem_kb swap_kb
  mem_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
  swap_kb="$(awk '/SwapTotal/ {print $2}' /proc/meminfo)"
  local mem_gb swap_gb
  mem_gb="$((mem_kb / 1024 / 1024))"
  swap_gb="$((swap_kb / 1024 / 1024))"
  write_info "Detected RAM: ${mem_gb} GB"
  write_info "Detected swap: ${swap_gb} GB"
  if (( mem_gb <= 16 && swap_gb < 32 )); then
    write_warn "Recommended swap for ${mem_gb} GB RAM is at least 32 GB."
    write_warn "Consider increasing swap before running larger models."
  elif (( mem_gb <= 24 && swap_gb < 32 )); then
    write_warn "Recommended swap for <=24 GB RAM is at least 32 GB."
  fi
}

write_section "SailingMedAdvisor Linux Installer"
write_info "Repository root: $repo_root"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "[ERROR] This script is for Linux only."
  exit 1
fi

write_section "Preflight Checks"
check_memory_swap
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
  echo "Terms not accepted yet. Complete terms acceptance, then rerun installer."
  exit 1
fi

read -r -s -p "Paste your Hugging Face token (input hidden): " hf_token
echo
if [[ -z "${hf_token}" ]]; then
  echo "No token provided. Cannot continue."
  exit 1
fi

write_info "Validating Hugging Face token..."
if ! validate_hf_token "$venv_python" "$hf_token"; then
  echo "[ERROR] Hugging Face token validation failed. Confirm token, terms acceptance, and internet connectivity."
  exit 1
fi

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
    hf_download_repo "$venv_python" "google/medgemma-1.5-4b-it" "$cache_dir" "$hf_token"
    ;;
  2)
    write_info "Downloading MedGemma 4B..."
    hf_download_repo "$venv_python" "google/medgemma-1.5-4b-it" "$cache_dir" "$hf_token"
    write_info "Downloading MedGemma 27B..."
    hf_download_repo "$venv_python" "google/medgemma-27b-text-it" "$cache_dir" "$hf_token"
    ;;
  3)
    write_warn "Skipping model download by user choice."
    ;;
  *)
    write_warn "Unknown choice '$choice'. Defaulting to 4B only."
    hf_download_repo "$venv_python" "google/medgemma-1.5-4b-it" "$cache_dir" "$hf_token"
    ;;
esac

write_section "Optional Quantized 27B CPU Setup"
if test_yes "Install llama-cpp-python for optional quantized 27B CPU mode?" "N"; then
  if ! "$venv_python" -m pip install llama-cpp-python; then
    write_warn "Could not install llama-cpp-python automatically. You can retry later."
  fi
fi

write_section "Write Local Runtime Config"
env_file="$repo_root/.env.linux"
cat >"$env_file" <<'EOF'
# Auto-generated by scripts/linux_installer.sh
FORCE_CUDA=0
ALLOW_CPU_FALLBACK_ON_CUDA_ERROR=1
EOF
write_info "Wrote: $env_file"

write_section "Installer Complete"
echo "Next steps:"
echo "  1) Start app: ./run_med_advisor.sh"
echo "  2) Open: http://127.0.0.1:5000"
echo "  3) Verify in Settings -> Offline Readiness Check"
