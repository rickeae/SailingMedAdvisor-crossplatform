@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
  echo [ERROR] Python virtual environment not found.
  echo Run launch_windows_bootstrap.cmd first.
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
