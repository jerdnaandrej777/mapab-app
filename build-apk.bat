@echo off
:: MapAB Flutter APK Build Script
:: Erstellt von Claude - Einfach per Doppelklick ausfuehren

echo.
echo ========================================
echo   MapAB Flutter APK Builder
echo ========================================
echo.

:: Wechsle ins Projektverzeichnis
cd /d "%~dp0"

echo [1/5] Pruefe Flutter Installation...
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [FEHLER] Flutter ist nicht im PATH!
    echo.
    echo Bitte oeffne eine neue Command Prompt und fuehre aus:
    echo   setx PATH "%%PATH%%;C:\flutter\bin"
    echo.
    echo Oder fuehre dieses Script in einer Command Prompt mit Flutter aus.
    echo.
    pause
    exit /b 1
)

echo [OK] Flutter gefunden!
echo.

echo [2/5] Hole Dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo [FEHLER] flutter pub get fehlgeschlagen!
    pause
    exit /b 1
)
echo.

echo [3/5] Generiere Code mit build_runner...
call flutter pub run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo [WARNUNG] build_runner hatte Probleme, fahre trotzdem fort...
)
echo.

echo [4/5] Baue Release APK (dies kann 5-10 Minuten dauern)...
call flutter build apk --release --split-per-abi
if %errorlevel% neq 0 (
    echo [FEHLER] APK Build fehlgeschlagen!
    pause
    exit /b 1
)
echo.

echo [5/5] APK erfolgreich erstellt!
echo.
echo ========================================
echo   Build erfolgreich abgeschlossen!
echo ========================================
echo.
echo APK-Dateien befinden sich hier:
echo   %CD%\build\app\outputs\flutter-apk\
echo.
echo Erstellt wurden:
dir /b "build\app\outputs\flutter-apk\app-*-release.apk" 2>nul
echo.
echo Hauptdatei zum Testen (moderne Geraete):
echo   app-arm64-v8a-release.apk
echo.

:: Oeffne Explorer mit APK-Ordner
echo Moechtest du den APK-Ordner im Explorer oeffnen? (J/N)
set /p choice="> "
if /i "%choice%"=="J" (
    start "" explorer "build\app\outputs\flutter-apk"
)

echo.
echo Druecke eine beliebige Taste zum Beenden...
pause >nul
