# =============================================================================
# Author: Rick Escher
# Project: SailingMedAdvisor
# Context: Google HAI-DEF Framework
# Models: Google MedGemmas
# Program: Kaggle Impact Challenge
# =============================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section([string]$text) {
    Write-Host ""
    Write-Host "==== $text ====" -ForegroundColor Cyan
}

function Test-Yes([string]$prompt, [bool]$defaultYes = $false) {
    $suffix = if ($defaultYes) { " [Y/n]" } else { " [y/N]" }
    $raw = Read-Host "$prompt$suffix"
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $defaultYes
    }
    $v = $raw.Trim().ToLowerInvariant()
    return @("y", "yes", "1", "true").Contains($v)
}

function Remove-PathSafe([string]$targetPath) {
    if (Test-Path $targetPath) {
        Remove-Item -Recurse -Force $targetPath
        Write-Host "[REMOVED] $targetPath" -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Not found: $targetPath" -ForegroundColor Gray
    }
}

try {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    Set-Location $repoRoot

    Write-Section "SailingMedAdvisor Windows Uninstall"
    Write-Host "This script removes local runtime artifacts created during install/use." -ForegroundColor White
    Write-Host "Your git repository files remain unless you remove the folder manually." -ForegroundColor White

    $venvPath = Join-Path $repoRoot ".venv"
    $cachePath = Join-Path $repoRoot "data\models_cache"
    $envPath = Join-Path $repoRoot ".env.windows"
    $runtimeLogPath = Join-Path $repoRoot "data\runtime.log"

    Write-Section "Choose What To Remove"
    if (Test-Yes "Remove Python virtual environment (.venv)?" $true) {
        Remove-PathSafe $venvPath
    }
    if (Test-Yes "Remove downloaded model cache (data\\models_cache)?" $false) {
        Remove-PathSafe $cachePath
    }
    if (Test-Yes "Remove local Windows env file (.env.windows)?" $true) {
        Remove-PathSafe $envPath
    }
    if (Test-Yes "Remove runtime log (data\\runtime.log)?" $true) {
        Remove-PathSafe $runtimeLogPath
    }
    if (Test-Yes "Remove SQLite database (app.db)? This deletes saved app data." $false) {
        Remove-PathSafe (Join-Path $repoRoot "app.db")
    }

    Write-Section "Uninstall Complete"
    Write-Host "If you also want to remove source code, delete this folder manually:" -ForegroundColor Green
    Write-Host "  $repoRoot" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
