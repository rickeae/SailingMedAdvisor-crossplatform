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
$script:InstallerVersion = "WIN-INSTALLER-2026-02-28.7"

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

function Get-FreeDiskSpaceGB {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )
    try {
        $root = [System.IO.Path]::GetPathRoot((Resolve-Path $Path).Path)
        if ([string]::IsNullOrWhiteSpace($root)) {
            return -1
        }
        $driveName = $root.TrimEnd('\').TrimEnd(':')
        $drive = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
        if (-not $drive) {
            return -1
        }
        return [math]::Round(($drive.Free / 1GB), 2)
    }
    catch {
        return -1
    }
}

function Remove-PartialModelCache {
    param(
        [Parameter(Mandatory = $true)][string]$CacheDir,
        [Parameter(Mandatory = $true)][string]$ModelRepoFolder
    )
    $partialPath = Join-Path $CacheDir $ModelRepoFolder
    if (Test-Path $partialPath) {
        Write-WarnLine "Removing partial model cache: $partialPath"
        try {
            Remove-Item -Path $partialPath -Recurse -Force -ErrorAction Stop
            Write-Info "Removed partial model cache."
        }
        catch {
            Write-WarnLine "Could not remove partial cache automatically."
            Write-WarnLine "You can remove it manually: $partialPath"
        }
    }
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
    Write-Info "Launching $DisplayName installer."
    $proc = $null
    $startParams = @{
        FilePath = $installerPath
        Wait     = $true
        PassThru = $true
    }
    $cleanArgs = @()
    if ($InstallerArgs) {
        $cleanArgs = @($InstallerArgs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    if ($cleanArgs.Count -gt 0) {
        $startParams["ArgumentList"] = $cleanArgs
    }
    $proc = Start-Process @startParams
    if ($proc -and $null -ne $proc.ExitCode) {
        $exitCode = [int]$proc.ExitCode
        if ($exitCode -ne 0 -and $exitCode -ne 3010 -and $exitCode -ne 1638) {
            throw "$DisplayName installer exited with code $exitCode"
        }
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
        if (Test-Path $path) {
            try {
                $entry = Get-ItemProperty -Path $path -ErrorAction Stop
                if ($null -ne $entry.Installed -and [int]$entry.Installed -eq 1) {
                    return $true
                }
            }
            catch {
                # ignore read failure for this key
            }
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
        Write-WarnLine "Microsoft Visual C++ Redistributable (x64) is missing. Installing automatically."
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
        Write-Info "Python 3.11 not found. Downloading and installing Python 3.11 directly."
        Install-ExecutableFromUrl `
            -Url "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe" `
            -FileName "python-3.11.9-amd64.exe" `
            -DisplayName "Python 3.11" `
            -InstallerArgs @(
                "/quiet",
                "InstallAllUsers=0",
                "PrependPath=1",
                "Include_launcher=1",
                "Include_pip=1",
                "Include_test=0",
                "SimpleInstall=1",
                "Shortcuts=0"
            )
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
    $probeLog = Join-Path $env:TEMP "sma_torch_probe.log"
    if (Test-Path $probeLog) {
        Remove-Item $probeLog -Force -ErrorAction SilentlyContinue
    }
    & $PythonExe -c "import torch; print('TORCH_IMPORT_OK')" *> $probeLog
    if ($LASTEXITCODE -ne 0) {
        $details = ""
        try {
            $details = (Get-Content -Path $probeLog -Raw -ErrorAction SilentlyContinue)
        }
        catch {
            $details = ""
        }
        $detailsLower = ""
        if (-not [string]::IsNullOrWhiteSpace($details)) {
            $detailsLower = $details.ToLowerInvariant()
        }
        if ($detailsLower -like "*1455*" -or $detailsLower -like "*paging file is too small*") {
            throw @(
                "PyTorch import failed because Windows virtual memory (paging file) is too small (WinError 1455).",
                "Set paging file to at least 32768 MB (recommended 65536 MB), then reboot.",
                "Path: System Properties > Advanced > Performance Settings > Advanced > Virtual memory > Change.",
                "After reboot, rerun launch_windows_installer.cmd."
            ) -join [Environment]::NewLine
        }
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
        $msg = $_.Exception.Message
        if ($msg -and (($msg.ToLowerInvariant() -like "*1455*") -or ($msg.ToLowerInvariant() -like "*paging file*"))) {
            throw $msg
        }
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
    $script:InstallerLogPath = Join-Path $repoRoot "windows_installer_log.txt"
    try {
        Start-Transcript -Path $script:InstallerLogPath -Force | Out-Null
        $script:TranscriptStarted = $true
    }
    catch {
        Write-WarnLine "Could not start transcript logging. Continuing without transcript."
    }

    Write-Section "SailingMedAdvisor Windows Installer"
    Write-Info "Installer version: $script:InstallerVersion"
    Write-Info "Repository root: $repoRoot"
    Write-Info "This script installs dependencies, validates Hugging Face token access, and downloads MedGemma models."

    Write-Section "Preflight Checks"
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
    Write-Host "Before token validation and model download, accept MedGemma terms on:" -ForegroundColor White
    Write-Host "  https://huggingface.co/google/medgemma-1.5-4b-it" -ForegroundColor White
    Write-Host "  https://huggingface.co/google/medgemma-27b-text-it" -ForegroundColor White

    $hfToken = Read-HfTokenWithValidation
    Write-Info "Validating Hugging Face token..."
    Validate-HfToken -PythonExe $venvPython -Token $hfToken

    if (-not $SkipModelDownload) {
        Write-Section "Model Download"
        $cacheDir = Join-Path $repoRoot "data\models_cache\hub"
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
        Write-Info "Model cache path: $cacheDir"
        $installed4B = $false
        $installed27B = $false
        $skipped27B = $false
        Write-Host "Choose model download mode:" -ForegroundColor White
        Write-Host "  1) 4B only (recommended for most systems)" -ForegroundColor White
        Write-Host "  2) 4B + 27B (larger download and heavier runtime)" -ForegroundColor White
        $downloadChoice = (Read-Host "Enter choice [1/2]").Trim()
        if ([string]::IsNullOrWhiteSpace($downloadChoice)) { $downloadChoice = "1" }
        if ($downloadChoice -eq "2") {
            Write-Info "Downloading MedGemma 4B..."
            Invoke-HfDownload -PythonExe $venvPython -RepoId "google/medgemma-1.5-4b-it" -CacheDir $cacheDir -Token $hfToken
            $installed4B = $true
            $freeBefore27B = Get-FreeDiskSpaceGB -Path $cacheDir
            if ($freeBefore27B -ge 0 -and $freeBefore27B -lt 60) {
                Write-WarnLine "Not enough free disk for 27B download (free: ${freeBefore27B} GB, recommended >= 60 GB)."
                Write-WarnLine "Continuing with 4B only. You can add 27B later by rerunning installer and choosing option 2."
                $skipped27B = $true
            }
            else {
                Write-Info "Downloading MedGemma 27B..."
                try {
                    Invoke-HfDownload -PythonExe $venvPython -RepoId "google/medgemma-27b-text-it" -CacheDir $cacheDir -Token $hfToken
                    $installed27B = $true
                }
                catch {
                    Write-WarnLine "27B download failed. Continuing with 4B only."
                    Write-WarnLine "Most common cause is low free disk space. Free at least 60 GB, then rerun installer and choose option 2."
                    Remove-PartialModelCache -CacheDir $cacheDir -ModelRepoFolder "models--google--medgemma-27b-text-it"
                    $skipped27B = $true
                }
            }
        }
        else {
            Write-Info "Downloading MedGemma 4B..."
            Invoke-HfDownload -PythonExe $venvPython -RepoId "google/medgemma-1.5-4b-it" -CacheDir $cacheDir -Token $hfToken
            $installed4B = $true
            $skipped27B = $true
        }
        if ($installed4B -and $installed27B) {
            Write-Info "Model install summary: 4B and 27B are installed."
        }
        elseif ($installed4B -and $skipped27B) {
            Write-Info "Model install summary: 4B is installed. 27B is not installed."
        }
    }
    else {
        Write-WarnLine "Skipping model download due to -SkipModelDownload."
    }

    Write-Info "Optional quantized 27B tooling is not installed by default."

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
