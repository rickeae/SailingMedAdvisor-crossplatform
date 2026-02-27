# =============================================================================
# Author: Rick Escher
# Project: SailingMedAdvisor
# Context: Google HAI-DEF Framework
# Models: Google MedGemmas
# Program: Kaggle Impact Challenge
# =============================================================================
param(
    [switch]$SkipModelDownload = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section([string]$text) {
    Write-Host ""
    Write-Host "==== $text ====" -ForegroundColor Cyan
}

function Write-Info([string]$text) {
    Write-Host "[INFO] $text" -ForegroundColor Gray
}

function Write-WarnLine([string]$text) {
    Write-Host "[WARN] $text" -ForegroundColor Yellow
}

function Refresh-ProcessPath() {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

function Install-ExecutableFromUrl {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$FileName,
        [Parameter(Mandatory = $true)][string]$DisplayName
    )
    $tempDir = Join-Path $env:TEMP "sma_installer"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    $installerPath = Join-Path $tempDir $FileName
    Write-Info "Downloading $DisplayName installer..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $installerPath -UseBasicParsing
    }
    catch {
        throw "Failed downloading $DisplayName installer from $Url"
    }
    Write-Info "Launching $DisplayName installer. Complete the installer, then return here."
    Start-Process -FilePath $installerPath -Wait
    Start-Sleep -Seconds 2
    Refresh-ProcessPath
}

function Install-WithWinget {
    param(
        [Parameter(Mandatory = $true)][string]$PackageId,
        [Parameter(Mandatory = $true)][string]$DisplayName
    )
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        $manualHint = @(
            "winget is not available in this environment.",
            "Install $DisplayName manually, then rerun launch_windows_installer.cmd.",
            "Manual install links:",
            "- Git: https://git-scm.com/download/win",
            "- Python 3.11 (64-bit): https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe",
            "If you are using Windows Sandbox, this is expected on some images."
        ) -join [Environment]::NewLine
        throw $manualHint
    }
    Write-WarnLine "$DisplayName not detected. Attempting auto-install via winget..."
    & winget install --id $PackageId -e --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "Failed installing $DisplayName via winget."
    }
    Start-Sleep -Seconds 2
    Refresh-ProcessPath
}

function Ensure-GitInstalled {
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        & git --version
        return $true
    }

    Write-WarnLine "Git for Windows not detected."
    Write-WarnLine "Git is optional if you installed this project from a ZIP file."
    if (-not (Test-Yes "Install Git now? (Recommended only if you want command-line updates from GitHub)" $false)) {
        Write-WarnLine "Continuing without Git. This is fine for ZIP-based installs."
        return $false
    }

    try {
        Install-WithWinget -PackageId "Git.Git" -DisplayName "Git for Windows"
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    }
    catch {
        Write-WarnLine $_.Exception.Message
    }

    if (-not $gitCmd) {
        if (Test-Yes "winget path failed. Download and run Git installer now?" $false) {
            Install-ExecutableFromUrl `
                -Url "https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe" `
                -FileName "Git-64-bit.exe" `
                -DisplayName "Git for Windows"
            $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        }
    }

    if (-not $gitCmd) {
        Write-WarnLine "Git is still not installed. Continuing without Git for ZIP-based setup."
        return $false
    }
    & git --version
    return $true
}

function Resolve-Python311Command {
    $pyCmd = Get-Command py -ErrorAction SilentlyContinue
    if ($pyCmd) {
        & py -3.11 --version *> $null
        if ($LASTEXITCODE -eq 0) {
            return @{ Launcher = "py"; PrefixArgs = @("-3.11") }
        }
    }

    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        try {
            $version = (& python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')").Trim()
        }
        catch {
            $version = ""
        }
        if ($version -eq "3.11") {
            return @{ Launcher = "python"; PrefixArgs = @() }
        }
    }

    $candidates = @()
    if ($env:LocalAppData) {
        $candidates += (Join-Path $env:LocalAppData "Programs\Python\Python311\python.exe")
    }
    if ($env:ProgramFiles) {
        $candidates += (Join-Path $env:ProgramFiles "Python311\python.exe")
    }
    $pf86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    if ($pf86) {
        $candidates += (Join-Path $pf86 "Python311-32\python.exe")
    }
    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        if (Test-Path $candidate) {
            return @{ Launcher = $candidate; PrefixArgs = @() }
        }
    }
    return $null
}

function Ensure-Python311Installed {
    $resolved = Resolve-Python311Command
    if (-not $resolved) {
        try {
            Install-WithWinget -PackageId "Python.Python.3.11" -DisplayName "Python 3.11"
        }
        catch {
            Write-WarnLine $_.Exception.Message
        }
        $resolved = Resolve-Python311Command
    }
    if (-not $resolved -and (Test-Yes "Download and run Python 3.11 installer now?" $true)) {
        Install-ExecutableFromUrl `
            -Url "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe" `
            -FileName "python-3.11.9-amd64.exe" `
            -DisplayName "Python 3.11"
        $resolved = Resolve-Python311Command
    }
    if (-not $resolved) {
        throw @(
            "Python 3.11 is still not detected.",
            "Install it manually and rerun launch_windows_installer.cmd:",
            "- https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe",
            "After install, close and reopen Command Prompt, then run installer again."
        ) -join [Environment]::NewLine
    }
    $probeArgs = @() + $resolved.PrefixArgs + @("--version")
    & $resolved.Launcher @probeArgs
    return $resolved
}

function Test-Yes([string]$prompt, [bool]$defaultYes = $true) {
    $suffix = if ($defaultYes) { " [Y/n]" } else { " [y/N]" }
    $raw = Read-Host "$prompt$suffix"
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $defaultYes
    }
    $v = $raw.Trim().ToLowerInvariant()
    return @("y", "yes", "1", "true").Contains($v)
}

function Read-SecretToken([string]$prompt) {
    $secure = Read-Host $prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Invoke-HfCommand {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$PythonExe
    )
    $hfCmd = Get-Command hf -ErrorAction SilentlyContinue
    if ($hfCmd) {
        & hf @Arguments
    }
    else {
        & $PythonExe -m huggingface_hub.commands.hf_cli @Arguments
    }
    if ($LASTEXITCODE -ne 0) {
        throw "HF command failed: $($Arguments -join ' ')"
    }
}

function Install-PythonDeps {
    param(
        [Parameter(Mandatory = $true)][string]$PythonExe
    )
    Write-Info "Upgrading pip/setuptools/wheel..."
    & $PythonExe -m pip install --upgrade pip setuptools wheel
    if ($LASTEXITCODE -ne 0) { throw "Failed to upgrade pip tools." }

    $corePackages = @(
        "fastapi",
        "uvicorn",
        "jinja2",
        "python-multipart",
        "aiofiles",
        "pillow",
        "itsdangerous",
        "huggingface-hub",
        "transformers",
        "accelerate",
        "safetensors"
    )
    Write-Info "Installing core Python packages..."
    & $PythonExe -m pip install @corePackages
    if ($LASTEXITCODE -ne 0) { throw "Failed installing core packages." }

    Write-Info "Installing CPU PyTorch..."
    & $PythonExe -m pip install torch --index-url https://download.pytorch.org/whl/cpu
    if ($LASTEXITCODE -ne 0) { throw "Failed installing CPU PyTorch." }
}

try {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    Set-Location $repoRoot

    Write-Section "SailingMedAdvisor Windows Installer"
    Write-Info "Repository root: $repoRoot"
    Write-Info "This script installs dependencies, configures Hugging Face login, and downloads MedGemma models."

    Write-Section "Preflight Checks"
    $hasGitMetadata = Test-Path (Join-Path $repoRoot ".git")
    if ($hasGitMetadata) {
        $hasGit = Ensure-GitInstalled
        if (-not $hasGit) {
            Write-WarnLine "Proceeding without Git."
        }
    }
    else {
        Write-Info "ZIP install detected (.git not present). Skipping Git preflight."
    }
    $pythonSpec = Ensure-Python311Installed
    Write-Info "Using Python launcher: $($pythonSpec.Launcher) $($pythonSpec.PrefixArgs -join ' ')"

    $venvDir = Join-Path $repoRoot ".venv"
    $venvPython = Join-Path $venvDir "Scripts\python.exe"

    Write-Section "Create / Reuse Virtual Environment"
    if (-not (Test-Path $venvPython)) {
        Write-Info "Creating .venv with Python 3.11..."
        $venvArgs = @() + $pythonSpec.PrefixArgs + @("-m", "venv", $venvDir)
        & $pythonSpec.Launcher @venvArgs
        if ($LASTEXITCODE -ne 0) { throw "Failed creating virtual environment." }
    }
    else {
        Write-Info ".venv already exists. Reusing existing environment."
    }

    Install-PythonDeps -PythonExe $venvPython

    Write-Section "Hugging Face Setup"
    Write-Host "Before continuing, you must accept MedGemma terms on:" -ForegroundColor White
    Write-Host "  https://huggingface.co/google/medgemma-1.5-4b-it" -ForegroundColor White
    Write-Host "  https://huggingface.co/google/medgemma-27b-text-it" -ForegroundColor White
    if (-not (Test-Yes "Have you accepted the terms on both model pages?" $false)) {
        throw "Terms not accepted yet. Complete terms acceptance, then rerun installer."
    }

    $hfToken = Read-SecretToken "Paste your Hugging Face token (input hidden)"
    if ([string]::IsNullOrWhiteSpace($hfToken)) {
        throw "No token provided. Cannot continue."
    }

    Write-Info "Logging in to Hugging Face CLI..."
    Invoke-HfCommand -PythonExe $venvPython -Arguments @("auth", "login", "--token", $hfToken)

    if (-not $SkipModelDownload) {
        Write-Section "Model Download"
        $cacheDir = Join-Path $repoRoot "data\models_cache\hub"
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
        Write-Info "Model cache path: $cacheDir"

        Write-Host ""
        Write-Host "Choose model download mode:" -ForegroundColor White
        Write-Host "  1) 4B only (fastest setup)" -ForegroundColor White
        Write-Host "  2) 4B + 27B (larger download)" -ForegroundColor White
        Write-Host "  3) Skip model download for now" -ForegroundColor White
        $choice = (Read-Host "Enter choice [1/2/3]").Trim()
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

        switch ($choice) {
            "1" {
                Write-Info "Downloading MedGemma 4B..."
                Invoke-HfCommand -PythonExe $venvPython -Arguments @("download", "google/medgemma-1.5-4b-it", "--cache-dir", $cacheDir, "--token", $hfToken)
            }
            "2" {
                Write-Info "Downloading MedGemma 4B..."
                Invoke-HfCommand -PythonExe $venvPython -Arguments @("download", "google/medgemma-1.5-4b-it", "--cache-dir", $cacheDir, "--token", $hfToken)
                Write-Info "Downloading MedGemma 27B..."
                Invoke-HfCommand -PythonExe $venvPython -Arguments @("download", "google/medgemma-27b-text-it", "--cache-dir", $cacheDir, "--token", $hfToken)
            }
            "3" {
                Write-WarnLine "Skipping model download by user choice."
            }
            default {
                Write-WarnLine "Unknown choice '$choice'. Defaulting to 4B only."
                Invoke-HfCommand -PythonExe $venvPython -Arguments @("download", "google/medgemma-1.5-4b-it", "--cache-dir", $cacheDir, "--token", $hfToken)
            }
        }
    }
    else {
        Write-WarnLine "Skipping model download due to -SkipModelDownload."
    }

    Write-Section "Optional Quantized 27B CPU Setup"
    $installLlamaCpp = Test-Yes "Install llama-cpp-python for optional quantized 27B CPU mode?" $false
    if ($installLlamaCpp) {
        & $venvPython -m pip install llama-cpp-python
        if ($LASTEXITCODE -ne 0) {
            Write-WarnLine "Could not install llama-cpp-python. You can retry later after installing Visual C++ Build Tools."
        }
    }
    Write-Info "GGUF path/config is managed inside SailingMedAdvisor Settings (no manual env entry required)."

    Write-Section "Write Local Runtime Config"
    $envFile = Join-Path $repoRoot ".env.windows"
    $lines = @(
        "# Auto-generated by scripts/windows_installer.ps1",
        "FORCE_CUDA=0",
        "ALLOW_CPU_FALLBACK_ON_CUDA_ERROR=1"
    )
    Set-Content -Path $envFile -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
    Write-Info "Wrote: $envFile"

    Write-Section "Installer Complete"
    Write-Host "Next steps:" -ForegroundColor Green
    Write-Host "  1) Start app: .venv\Scripts\python.exe .\app.py" -ForegroundColor Green
    Write-Host "  2) Open: http://127.0.0.1:5000" -ForegroundColor Green
    Write-Host "  3) Verify in Settings -> Offline Readiness Check" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Installer stopped. Fix the issue above and rerun launch_windows_installer.cmd." -ForegroundColor Red
    exit 1
}
