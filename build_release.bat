@echo off
echo Buildando APK release...
flutter build apk --release

if %ERRORLEVEL% NEQ 0 (
    echo Build falhou.
    exit /b 1
)

set OUTPUT=build\app\outputs\flutter-apk
set FROM=%OUTPUT%\app-release.apk
set TO=%OUTPUT%\nymbus-coletor.apk

if exist "%TO%" del "%TO%"
rename "%FROM%" "nymbus-coletor.apk"

echo.
echo APK gerado: %TO%
