# =============================================================================
# Author: Rick Escher
# Project: SailingMedAdvisor
# Context: Google HAI-DEF Framework
# Models: Google MedGemmas
# Program: Kaggle Impact Challenge
# =============================================================================
param(
    [switch]$SkipModelDownload = $false,
    [switch]$SelfTest = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$script:TranscriptStarted = $false
$script:InstallerLogPath = $null

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
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [string[]]$InstallerArgs = @()
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
    $proc = Start-Process -FilePath $installerPath -ArgumentList $InstallerArgs -Wait -PassThru
    if ($proc -and $null -ne $proc.ExitCode) {
        $exitCode = [int]$proc.ExitCode
        if ($exitCode -ne 0 -and $exitCode -ne 3010 -and $exitCode -ne 1638) {
            throw "$DisplayName installer exited with code $exitCode"
        }
    }
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

function Test-VcRedistInstalled {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
    )
    foreach ($path in $paths) {
        try {
            $entry = Get-ItemProperty -Path $path -ErrorAction Stop
            if ($null -ne $entry.Installed -and [int]$entry.Installed -eq 1) {
                return $true
            }
        }
        catch {
            # ignore missing key
        }
    }
    return $false
}

function Install-VcRedist {
    param(
        [bool]$ForceInstall = $false
    )
    if ((-not $ForceInstall) -and (Test-VcRedistInstalled)) {
        Write-Info "Microsoft Visual C++ Redistributable (x64) detected."
        return
    }
    if (-not $ForceInstall) {
        Write-WarnLine "Microsoft Visual C++ Redistributable (x64) is missing."
        Write-WarnLine "PyTorch requires it on Windows."
        if (-not (Test-Yes "Install Microsoft Visual C++ Redistributable (x64) now?" $true)) {
            throw @(
                "Microsoft Visual C++ Redistributable (x64) is required.",
                "Install it from:",
                "- https://aka.ms/vs/17/release/vc_redist.x64.exe",
                "Then rerun launch_windows_installer.cmd."
            ) -join [Environment]::NewLine
        }
    } else {
        Write-WarnLine "Attempting forced Microsoft Visual C++ Redistributable (x64) install due to torch runtime failure..."
    }
    Install-ExecutableFromUrl `
        -Url "https://aka.ms/vs/17/release/vc_redist.x64.exe" `
        -FileName "vc_redist.x64.exe" `
        -DisplayName "Microsoft Visual C++ Redistributable (x64)" `
        -InstallerArgs @("/install", "/passive", "/norestart")
}

function Ensure-VcRedistInstalled {
    Install-VcRedist -ForceInstall $false
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
    & $resolved.Launcher @probeArgs | Out-Null
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

function Normalize-HfToken([string]$raw) {
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return ""
    }
    $token = $raw.Trim().Trim('"').Trim("'")
    # Remove non-printable characters often introduced by copy/paste.
    $token = [regex]::Replace($token, "[^\x20-\x7E]", "")
    # Try to extract token from pasted surrounding text like:
    # "token: hf_xxx..." or "hf_xxx copied"
    $m = [regex]::Match($token, '(hf_\S+)')
    if ($m.Success) {
        return $m.Groups[1].Value.Trim()
    }
    # Fallback: if there is whitespace, keep first chunk.
    if ($token -match "\s") {
        $parts = $token -split "\s+"
        if ($parts.Count -gt 0) { return $parts[0] }
    }
    return $token.Trim()
}

function Read-HfTokenWithValidation {
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        $raw = Read-SecretToken "Paste your Hugging Face token only (starts with hf_)"
        $token = Normalize-HfToken $raw
        if ([string]::IsNullOrWhiteSpace($token)) {
            Write-WarnLine "No token detected. Paste only the token string."
            continue
        }
        if (-not ($token -match '^hf_[^\s]{8,}$')) {
            Write-WarnLine "Token format looks invalid. It should start with hf_ and contain no spaces."
            Write-WarnLine "If you pasted extra text, paste only the token itself."
            continue
        }
        return $token
    }
    throw "Token entry failed after multiple attempts."
}

function Validate-HfToken {
    param(
        [Parameter(Mandatory = $true)][string]$PythonExe,
        [Parameter(Mandatory = $true)][string]$Token
    )
    # Keep this as a single-line script string. Multi-line -c text can be mangled
    # by some Windows shells and cause confusing Python syntax errors.
    $code = "from huggingface_hub import HfApi; import sys; token=sys.argv[1].strip(); HfApi(token=token).whoami(); print('HF token OK')"
    & $PythonExe -c $code $Token
    if ($LASTEXITCODE -ne 0) {
        throw "Hugging Face token validation failed. Confirm token, terms acceptance, and internet connectivity."
    }
}

function Invoke-HfDownload {
    param(
        [Parameter(Mandatory = $true)][string]$PythonExe,
        [Parameter(Mandatory = $true)][string]$RepoId,
        [Parameter(Mandatory = $true)][string]$CacheDir,
        [Parameter(Mandatory = $true)][string]$Token
    )
    $code = "from huggingface_hub import snapshot_download; import sys; snapshot_download(repo_id=sys.argv[1], cache_dir=sys.argv[2], token=sys.argv[3]); print('HF download OK')"
    & $PythonExe -c $code $RepoId $CacheDir $Token
    if ($LASTEXITCODE -ne 0) {
        throw "Model download failed for repository '$RepoId'. Confirm token, terms acceptance, internet connectivity, and available disk space."
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

function Test-TorchImport {
    param(
        [Parameter(Mandatory = $true)][string]$PythonExe
    )
    & $PythonExe -c "import torch; print('TORCH_IMPORT_OK')"
    if ($LASTEXITCODE -ne 0) {
        throw @(
            "PyTorch import failed after install.",
            "On Windows this usually means Microsoft Visual C++ Redistributable (x64) is missing.",
            "Install from:",
            "- https://aka.ms/vs/17/release/vc_redist.x64.exe",
            "Then rerun launch_windows_installer.cmd."
        ) -join [Environment]::NewLine
    }
}

function Install-MsvcRuntimePythonPackage {
    param(
        [Parameter(Mandatory = $true)][string]$PythonExe
    )
    Write-Info "Installing Python msvc-runtime fallback package..."
    & $PythonExe -m pip install --upgrade msvc-runtime
    if ($LASTEXITCODE -ne 0) {
        Write-WarnLine "Could not install msvc-runtime package automatically."
    }
}

function Ensure-TorchRuntimeReady {
    param(
        [Parameter(Mandatory = $true)][string]$PythonExe
    )
    try {
        Test-TorchImport -PythonExe $PythonExe
        return
    }
    catch {
        Write-WarnLine "PyTorch runtime check failed. Attempting VC++ runtime repair..."
    }

    try {
        Install-VcRedist -ForceInstall $true
        Test-TorchImport -PythonExe $PythonExe
        return
    }
    catch {
        Write-WarnLine "VC++ runtime repair path did not resolve torch import."
    }

    Install-MsvcRuntimePythonPackage -PythonExe $PythonExe
    Test-TorchImport -PythonExe $PythonExe
}

function Invoke-InstallerSelfTest {
    Write-Section "Windows Installer Self-Test"
    Write-Info "Running token parser and validation checks..."

    $cases = @(
        @{ Input = "hf_abcdefghijklmnop123456"; Expected = "hf_abcdefghijklmnop123456" },
        @{ Input = "  hf_abcdefghijklmnop123456  "; Expected = "hf_abcdefghijklmnop123456" },
        @{ Input = "'hf_abcdefghijklmnop123456'"; Expected = "hf_abcdefghijklmnop123456" },
        @{ Input = '"hf_abcdefghijklmnop123456"'; Expected = "hf_abcdefghijklmnop123456" },
        @{ Input = "token: hf_abcdefghijklmnop123456"; Expected = "hf_abcdefghijklmnop123456" },
        @{ Input = "hf_abcdefghijklmnop123456 copied"; Expected = "hf_abcdefghijklmnop123456" },
        @{ Input = ""; Expected = "" }
    )

    foreach ($case in $cases) {
        $actual = Normalize-HfToken $case.Input
        if ($actual -ne $case.Expected) {
            throw "Self-test failed: Normalize-HfToken input '$($case.Input)' expected '$($case.Expected)' but got '$actual'."
        }
    }

    if (-not ("hf_abcdefgh" -match '^hf_[^\s]{8,}$')) {
        throw "Self-test failed: expected valid token pattern did not match."
    }
    if ("hf_bad token" -match '^hf_[^\s]{8,}$') {
        throw "Self-test failed: invalid token pattern was accepted."
    }

    Write-Host "[INFO] Self-test passed." -ForegroundColor Green
}

if ($SelfTest) {
    try {
        Invoke-InstallerSelfTest
        exit 0
    }
    catch {
        Write-Host "[ERROR] Self-test failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

try {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    Set-Location $repoRoot
    $script:InstallerLogPath = Join-Path $repoRoot "windows_installer.log"
    try {
        Start-Transcript -Path $script:InstallerLogPath -Force | Out-Null
        $script:TranscriptStarted = $true
    }
    catch {
        Write-WarnLine "Could not start transcript logging. Continuing without transcript."
    }

    Write-Section "SailingMedAdvisor Windows Installer"
    Write-Info "Repository root: $repoRoot"
    Write-Info "This script installs dependencies, validates Hugging Face token access, and downloads MedGemma models."

    Write-Section "Preflight Checks"
    Write-Info "Git is not required for this installer (ZIP-based workflow)."
    Ensure-VcRedistInstalled
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
    Ensure-TorchRuntimeReady -PythonExe $venvPython

    Write-Section "Hugging Face Setup"
    Write-Host "Before continuing, you must accept MedGemma terms on:" -ForegroundColor White
    Write-Host "  https://huggingface.co/google/medgemma-1.5-4b-it" -ForegroundColor White
    Write-Host "  https://huggingface.co/google/medgemma-27b-text-it" -ForegroundColor White
    if (-not (Test-Yes "Have you accepted the terms on both model pages?" $false)) {
        throw "Terms not accepted yet. Complete terms acceptance, then rerun installer."
    }

    $hfToken = Read-HfTokenWithValidation
    Write-Info "Validating Hugging Face token..."
    Validate-HfToken -PythonExe $venvPython -Token $hfToken

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
                Invoke-HfDownload -PythonExe $venvPython -RepoId "google/medgemma-1.5-4b-it" -CacheDir $cacheDir -Token $hfToken
            }
            "2" {
                Write-Info "Downloading MedGemma 4B..."
                Invoke-HfDownload -PythonExe $venvPython -RepoId "google/medgemma-1.5-4b-it" -CacheDir $cacheDir -Token $hfToken
                Write-Info "Downloading MedGemma 27B..."
                Invoke-HfDownload -PythonExe $venvPython -RepoId "google/medgemma-27b-text-it" -CacheDir $cacheDir -Token $hfToken
            }
            "3" {
                Write-WarnLine "Skipping model download by user choice."
            }
            default {
                Write-WarnLine "Unknown choice '$choice'. Defaulting to 4B only."
                Invoke-HfDownload -PythonExe $venvPython -RepoId "google/medgemma-1.5-4b-it" -CacheDir $cacheDir -Token $hfToken
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
    if ($_.InvocationInfo -and $_.InvocationInfo.PositionMessage) {
        Write-Host "[ERROR] Location: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Red
    }
    if ($_.ScriptStackTrace) {
        Write-Host "[ERROR] Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
    }
    Write-Host "Installer stopped. Fix the issue above and rerun launch_windows_installer.cmd." -ForegroundColor Red
    if ($script:TranscriptStarted) {
        try { Stop-Transcript | Out-Null } catch {}
    }
    exit 1
}
finally {
    if ($script:TranscriptStarted) {
        try { Stop-Transcript | Out-Null } catch {}
    }
}
