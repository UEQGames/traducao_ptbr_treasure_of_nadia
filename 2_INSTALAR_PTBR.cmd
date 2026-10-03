@echo off
chcp 65001 >nul
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\ptbr-installer.ps1" -Action Install
set "PTBR_EXIT=%ERRORLEVEL%"
echo.
if not "%PTBR_EXIT%"=="0" echo A instalacao nao foi concluida. Leia a mensagem acima.
pause
exit /b %PTBR_EXIT%
