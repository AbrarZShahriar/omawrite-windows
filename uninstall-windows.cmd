@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows\uninstall.ps1"
if errorlevel 1 (
  echo.
  echo OmaWrite removal failed. Review the message above.
  pause
  exit /b 1
)
endlocal
