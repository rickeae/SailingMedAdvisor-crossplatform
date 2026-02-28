@echo off
setlocal
cd /d "%~dp0"
set "INSTALLER_VERSION=WIN-INSTALLER-2026-02-28.9"

echo Starting SailingMedAdvisor Windows installer...
echo Installer version: %INSTALLER_VERSION%
set "INSTALLER_LOG=%~dp0windows_installer_log.txt"
echo Writing installer log to: %INSTALLER_LOG%
echo Running installer self-test...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows_installer.ps1" -SelfTest
if not "%ERRORLEVEL%"=="0" (
  echo.
  echo Installer self-test failed. See error output above.
  echo.
  pause
  exit /b 1
)
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
  echo.
  set "START_APP="
  set /p START_APP=Start SailingMedAdvisor now? [Y/N]: 
  if /I "%START_APP%"=="Y" (
    call ".\launch_windows_app.cmd"
    exit /b 0
  )
  if /I "%START_APP%"=="YES" (
    call ".\launch_windows_app.cmd"
    exit /b 0
  )
)

echo.
pause
exit /b %EXIT_CODE%
