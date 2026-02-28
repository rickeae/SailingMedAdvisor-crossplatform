#!/usr/bin/env bash
# =============================================================================
# Author: Rick Escher
# Project: SailingMedAdvisor
# Context: Google HAI-DEF Framework
# Models: Google MedGemmas
# Program: Kaggle Impact Challenge
# =============================================================================
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "== SailingMedAdvisor Crossplatform QA =="
echo "Repo: $repo_root"

failures=0
warnings=0

ok()   { echo "[OK] $1"; }
warn() { echo "[WARN] $1"; warnings=$((warnings + 1)); }
fail() { echo "[FAIL] $1"; failures=$((failures + 1)); }

require_file() {
  local p="$1"
  if [[ -f "$p" ]]; then
    ok "Found file: $p"
  else
    fail "Missing file: $p"
  fi
}

echo
echo "1) Required file checks"
require_file "README.md"
require_file "README-Windows.md"
require_file "README-macOS.md"
require_file "README-Linux.md"
require_file "README-Crossplatform-Installer.md"
require_file "launch_windows_installer.cmd"
require_file "launch_macos_installer.command"
require_file "launch_linux_installer.sh"
require_file "scripts/windows_installer.ps1"
require_file "scripts/macos_installer.sh"
require_file "scripts/linux_installer.sh"

echo
echo "2) Shell syntax checks (bash-launch and bash scripts)"
if bash -n scripts/macos_installer.sh; then ok "bash -n scripts/macos_installer.sh"; else fail "bash -n scripts/macos_installer.sh"; fi
if bash -n scripts/linux_installer.sh; then ok "bash -n scripts/linux_installer.sh"; else fail "bash -n scripts/linux_installer.sh"; fi
if bash -n launch_macos_installer.command; then ok "bash -n launch_macos_installer.command"; else fail "bash -n launch_macos_installer.command"; fi
if bash -n launch_linux_installer.sh; then ok "bash -n launch_linux_installer.sh"; else fail "bash -n launch_linux_installer.sh"; fi

echo
echo "3) Installer behavior regression checks"
if rg -n "Install llama-cpp|test_yes|\\[Y/n\\]|\\[y/N\\]" \
  scripts/windows_installer.ps1 scripts/macos_installer.sh scripts/linux_installer.sh >/dev/null; then
  fail "Installer scripts contain disallowed yes/no or optional-extra prompt logic."
else
  ok "Installer prompts match expected scope."
fi

if rg -n "Choose model download mode|Enter choice \\[1/2\\]" scripts/windows_installer.ps1 scripts/macos_installer.sh scripts/linux_installer.sh >/dev/null; then
  ok "Model-selection prompt is present in installers."
else
  fail "Model-selection prompt is missing in one or more installers."
fi

if rg -n 'Start-Process -FilePath \$installerPath -ArgumentList \$InstallerArgs' scripts/windows_installer.ps1 >/dev/null; then
  fail "Windows installer still has legacy Start-Process ArgumentList path."
else
  ok "Windows installer uses safe Start-Process parameter handling."
fi

if rg -n "Start-Process @startParams" scripts/windows_installer.ps1 >/dev/null; then
  ok "Windows installer contains hardened Start-Process path."
else
  warn "Could not confirm hardened Start-Process path in windows_installer.ps1."
fi

echo
echo "4) Launcher wiring checks"
if rg -n "scripts\\\\windows_installer.ps1" launch_windows_installer.cmd >/dev/null; then ok "Windows launcher points to windows installer script."; else fail "Windows launcher wiring missing."; fi
if rg -n "scripts/macos_installer.sh" launch_macos_installer.command >/dev/null; then ok "macOS launcher points to macOS installer script."; else fail "macOS launcher wiring missing."; fi
if rg -n "scripts/linux_installer.sh" launch_linux_installer.sh >/dev/null; then ok "Linux launcher points to Linux installer script."; else fail "Linux launcher wiring missing."; fi
if rg -n "Launching Windows installer automatically" launch_windows_app.cmd >/dev/null; then
  ok "Windows app launcher auto-recovers by launching installer when .venv is missing."
else
  fail "Windows app launcher is missing .venv auto-recovery behavior."
fi
if rg -n "Run launch_windows_installer.cmd first" launch_windows_app.cmd >/dev/null; then
  fail "Windows app launcher still contains stale manual-only .venv error text."
else
  ok "Windows app launcher no longer uses stale manual-only .venv text."
fi

echo
echo "5) URL health checks"
urls_file="$(mktemp)"
rg --no-filename -o "https?://[^)\\]>'\\\"[:space:]]+" \
  README*.md scripts/windows_installer.ps1 scripts/macos_installer.sh scripts/linux_installer.sh launch_windows_app.cmd \
  | tr -d '`' \
  | tr -d '"' \
  | tr -d "'" \
  | sort -u > "$urls_file"

while IFS= read -r url; do
  [[ -z "$url" ]] && continue
  if [[ "$url" == "http://127.0.0.1:5000" ]]; then
    warn "Skipping localhost URL check: $url"
    continue
  fi
  code="$(curl -L -s -o /dev/null -w "%{http_code}" --max-time 30 "$url" || echo "000")"
  if [[ "$code" =~ ^(2|3) ]]; then
    ok "URL $code: $url"
  else
    fail "URL $code: $url"
  fi
done < "$urls_file"
rm -f "$urls_file"

echo
echo "6) README cross-link checks"
if rg -n "README-Windows.md|README-macOS.md|README-Linux.md" README.md README-Crossplatform-Installer.md >/dev/null; then
  ok "Main README docs link to platform READMEs."
else
  fail "Missing platform README links from index docs."
fi

echo
echo "== QA Summary =="
echo "Warnings: $warnings"
echo "Failures: $failures"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
exit 0
