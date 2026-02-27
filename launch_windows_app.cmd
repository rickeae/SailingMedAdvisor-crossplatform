@echo off
setlocal EnableExtensions EnableDelayedExpansion

if /i not "%~1"=="--inner" (
  start "SailingMedAdvisor App" cmd /k "\"%~f0\" --inner"
  exit /b 0
)
shift

cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
  echo [ERROR] Python virtual environment not found.
  echo Run launch_windows_installer.cmd first.
  echo.
  pause
  exit /b 1
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
".venv\Scripts\python.exe" -c "import torch" >nul 2>&1
if not "%ERRORLEVEL%"=="0" (
  echo.
  echo [ERROR] PyTorch failed to load.
  echo [ERROR] Install Microsoft Visual C++ Redistributable (x64):
  echo [ERROR] https://aka.ms/vs/17/release/vc_redist.x64.exe
  echo [ERROR] Then rerun launch_windows_installer.cmd and start again.
  echo.
  pause
  exit /b 1
)
start "" http://127.0.0.1:5000
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
