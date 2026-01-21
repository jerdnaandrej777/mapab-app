@echo off
:: MapAB Flutter APK Build Script (mit automatischer Flutter-Erkennung)
:: Erstellt von Claude

echo.
echo ========================================
echo   MapAB Flutter APK Builder
echo ========================================
echo.

:: Wechsle ins Projektverzeichnis
cd /d "%~dp0"

:: Setze Flutter-Pfad (gefunden unter C:\Users\Gejer\flutter)
set "FLUTTER_BIN=C:\Users\Gejer\flutter\bin"
set "PATH=%FLUTTER_BIN%;%PATH%"

echo [1/5] Pruefe Flutter Installation...
echo Flutter-Pfad: %FLUTTER_BIN%

if not exist "%FLUTTER_BIN%\flutter.bat" (
    echo.
    echo [FEHLER] Flutter nicht gefunden unter: %FLUTTER_BIN%
    echo.
    echo Bitte installiere Flutter von: https://flutter.dev
    echo.
    pause
    exit /b 1
)

echo [OK] Flutter gefunden!
flutter --version
echo.

echo [2/5] Hole Dependencies...
call "%FLUTTER_BIN%\flutter.bat" pub get
if %errorlevel% neq 0 (
    echo [FEHLER] flutter pub get fehlgeschlagen!
    pause
    exit /b 1
)
echo.

echo [3/5] Generiere Code mit build_runner...
echo (Dies kann einige Minuten dauern...)
call "%FLUTTER_BIN%\flutter.bat" pub run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo [WARNUNG] build_runner hatte Probleme, fahre trotzdem fort...
)
echo.

echo [4/5] Baue Release APK...
echo (Dies kann 5-10 Minuten dauern - bitte warten...)
echo.
call "%FLUTTER_BIN%\flutter.bat" build apk --release --split-per-abi

if %errorlevel% neq 0 (
    echo.
    echo [FEHLER] APK Build fehlgeschlagen!
    echo.
    echo Moegliche Ursachen:
    echo  - Java JDK nicht installiert
    echo  - Android SDK nicht konfiguriert
    echo  - Netzwerkprobleme beim Download von Dependencies
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Build erfolgreich abgeschlossen!
echo ========================================
echo.
echo APK-Dateien befinden sich hier:
echo   %CD%\build\app\outputs\flutter-apk\
echo.

if exist "build\app\outputs\flutter-apk" (
    echo Erstellt wurden:
    dir /b "build\app\outputs\flutter-apk\app-*-release.apk" 2>nul
    echo.

    :: Zeige Dateigroessen
    for %%f in ("build\app\outputs\flutter-apk\app-*-release.apk") do (
        set size=%%~zf
        set /a sizeMB=!size! / 1048576
        echo   - %%~nxf (!sizeMB! MB)
    )

    echo.
    echo Hauptdatei zum Testen (moderne Geraete):
    echo   app-arm64-v8a-release.apk
    echo.

    :: Oeffne Explorer
    echo Explorer wird geoeffnet...
    timeout /t 2 /nobreak >nul
    start "" explorer "build\app\outputs\flutter-apk"
) else (
    echo [WARNUNG] APK-Ordner nicht gefunden!
)

echo.
echo Naechste Schritte:
echo   1. APK auf GitHub Releases hochladen
echo   2. Oder per Google Drive/Dropbox teilen
echo   3. Siehe DEPLOYMENT-GUIDE.md fuer Details
echo.
echo Druecke eine beliebige Taste zum Beenden...
pause >nul
