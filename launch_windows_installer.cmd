@echo off
setlocal
cd /d "%~dp0"

echo Starting SailingMedAdvisor Windows installer...
set "INSTALLER_LOG=%~dp0windows_installer.log"
echo Writing installer log to: %INSTALLER_LOG%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows_installer.ps1"
set EXIT_CODE=%ERRORLEVEL%

if not "%EXIT_CODE%"=="0" (
  echo.
  echo Installer failed with exit code %EXIT_CODE%.
  if exist "%INSTALLER_LOG%" (
    echo Showing last 40 log lines:
    powershell -NoProfile -Command "Get-Content -Path '%INSTALLER_LOG%' -Tail 40"
  )
) else (
  echo.
  echo Installer finished successfully.
)

echo.
pause
exit /b %EXIT_CODE%
