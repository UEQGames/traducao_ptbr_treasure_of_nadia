@echo off
chcp 65001 >nul
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\ptbr-installer.ps1" -Action Verify
set "PTBR_EXIT=%ERRORLEVEL%"
echo.
pause
exit /b %PTBR_EXIT%
