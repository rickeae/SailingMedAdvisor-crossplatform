@echo off
setlocal
cd /d "%~dp0"

echo Starting SailingMedAdvisor Windows uninstall...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\uninstall_windows.ps1"
set EXIT_CODE=%ERRORLEVEL%

if not "%EXIT_CODE%"=="0" (
  echo.
  echo Uninstall failed with exit code %EXIT_CODE%.
) else (
  echo.
  echo Uninstall finished.
)

echo.
pause
exit /b %EXIT_CODE%
