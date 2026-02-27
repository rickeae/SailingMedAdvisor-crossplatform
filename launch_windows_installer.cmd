@echo off
setlocal
cd /d "%~dp0"

echo Starting SailingMedAdvisor Windows installer...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows_installer.ps1"
set EXIT_CODE=%ERRORLEVEL%

if not "%EXIT_CODE%"=="0" (
  echo.
  echo Installer failed with exit code %EXIT_CODE%.
) else (
  echo.
  echo Installer finished successfully.
)

echo.
pause
exit /b %EXIT_CODE%
