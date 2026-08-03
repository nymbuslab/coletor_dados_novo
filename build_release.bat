@echo off
cd /d "%~dp0"
echo Buildando APK release...
call flutter build apk --release

if %ERRORLEVEL% NEQ 0 (
    echo Build falhou.
    exit /b 1
)

set OUTPUT=build\app\outputs\flutter-apk
set FROM=%OUTPUT%\app-release.apk
set TO=%OUTPUT%\gr7-coletor.apk

if exist "%TO%" del "%TO%"
rename "%FROM%" "gr7-coletor.apk"

echo.
echo APK gerado: %TO%
