@echo off
setlocal EnableExtensions EnableDelayedExpansion

if /i not "%~1"=="--inner" (
  start "SailingMedAdvisor App" cmd /k ""%~f0" --inner"
  exit /b 0
)
shift

cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
  echo [WARN] Python virtual environment not found.
  echo [INFO] Launching Windows installer automatically...
  echo.
  call ".\launch_windows_installer.cmd"
  if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] Setup did not create the Python virtual environment.
    echo [ERROR] Fix installer errors, then run launch_windows_app.cmd again.
    echo.
    pause
    exit /b 1
  )
)

if exist ".env.windows" (
  for /f "usebackq tokens=1* delims==" %%A in (".env.windows") do (
    set "KEY=%%A"
    if not "!KEY!"=="" (
      if not "!KEY:~0,1!"=="#" (
        set "%%A=%%B"
      )
    )
  )
)

echo Starting SailingMedAdvisor...
echo [INFO] Browser will open automatically in about 5 seconds.
echo [INFO] If you briefly see a 404 or connection error, wait 5-10 seconds and refresh.
set "TORCH_PROBE_LOG=%TEMP%\sma_torch_probe.log"
call :torch_probe
if not "%ERRORLEVEL%"=="0" (
  findstr /I /C:"1455" /C:"paging file is too small" "%TORCH_PROBE_LOG%" >nul
  if "%ERRORLEVEL%"=="0" (
    call :handle_1455
    exit /b 1
  )
  echo [WARN] PyTorch failed to load on first check. Attempting runtime repair...
  ".venv\Scripts\python.exe" -m pip install --upgrade msvc-runtime
  call :torch_probe
)
if not "%ERRORLEVEL%"=="0" (
  findstr /I /C:"1455" /C:"paging file is too small" "%TORCH_PROBE_LOG%" >nul
  if "%ERRORLEVEL%"=="0" (
    call :handle_1455
    exit /b 1
  )
  echo [WARN] PyTorch still failing. Attempting Microsoft Visual C++ Redistributable install...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$u='https://aka.ms/vs/17/release/vc_redist.x64.exe'; $p=Join-Path $env:TEMP 'vc_redist.x64.exe'; Invoke-WebRequest -Uri $u -OutFile $p -UseBasicParsing; $proc=Start-Process -FilePath $p -ArgumentList '/install','/passive','/norestart' -Wait -PassThru; exit $proc.ExitCode"
  call :torch_probe
)
if not "%ERRORLEVEL%"=="0" (
  findstr /I /C:"1455" /C:"paging file is too small" "%TORCH_PROBE_LOG%" >nul
  if "%ERRORLEVEL%"=="0" (
    call :handle_1455
    exit /b 1
  )
  echo.
  echo [ERROR] PyTorch failed to load.
  echo [ERROR] Install Microsoft Visual C++ Redistributable x64 and restart terminal:
  echo [ERROR] https://aka.ms/vs/17/release/vc_redist.x64.exe
  echo [ERROR] Then rerun launch_windows_installer.cmd and start again.
  echo.
  pause
  exit /b 1
)
start "" powershell -NoProfile -Command "Start-Sleep -Seconds 5; Start-Process 'http://127.0.0.1:5000'"
".venv\Scripts\python.exe" ".\app.py"
set EXIT_CODE=%ERRORLEVEL%

echo.
if not "%EXIT_CODE%"=="0" (
  echo App exited with code %EXIT_CODE%.
) else (
  echo App stopped.
)
pause
exit /b %EXIT_CODE%

:torch_probe
".venv\Scripts\python.exe" -c "import torch" > "%TORCH_PROBE_LOG%" 2>&1
exit /b %ERRORLEVEL%

:handle_1455
echo.
echo [ERROR] Windows virtual memory paging file is too small for PyTorch.
echo [ERROR] Set paging file to minimum 65536 MB, recommended 131072 MB, then reboot.
echo [ERROR] Open: System Properties ^> Advanced ^> Performance Settings ^> Advanced ^> Virtual memory.
if /I "%USERNAME%"=="WDAGUtilityAccount" (
  echo [ERROR] Windows Sandbox detected ^(WDAGUtilityAccount^).
  echo [ERROR] Sandbox memory/commit limits often prevent MedGemma 4B/27B from running.
  echo [ERROR] Run SailingMedAdvisor on the host Windows machine ^(not inside Sandbox^).
)
echo.
pause
exit /b 0
