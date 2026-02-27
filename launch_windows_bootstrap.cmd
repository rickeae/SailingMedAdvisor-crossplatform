@echo off
setlocal
cd /d "%~dp0"

echo Starting SailingMedAdvisor Windows bootstrap...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\bootstrap_windows.ps1"
set EXIT_CODE=%ERRORLEVEL%

if not "%EXIT_CODE%"=="0" (
  echo.
  echo Bootstrap failed with exit code %EXIT_CODE%.
) else (
  echo.
  echo Bootstrap finished successfully.
)

echo.
pause
exit /b %EXIT_CODE%
