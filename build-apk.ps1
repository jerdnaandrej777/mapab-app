# MapAB Flutter APK Build Script (PowerShell)
# Erstellt von Claude - Rechtsklick -> "Mit PowerShell ausfuehren"

Write-Host ""
Write-Host "========================================"  -ForegroundColor Cyan
Write-Host "  MapAB Flutter APK Builder" -ForegroundColor Cyan
Write-Host "========================================"  -ForegroundColor Cyan
Write-Host ""

# Wechsle ins Projektverzeichnis
Set-Location $PSScriptRoot

# Pruefe Flutter Installation
Write-Host "[1/5] Pruefe Flutter Installation..." -ForegroundColor Yellow
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue

if (-not $flutterCmd) {
    Write-Host ""
    Write-Host "[FEHLER] Flutter ist nicht im PATH!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Loesungen:" -ForegroundColor Yellow
    Write-Host "  1. Oeffne eine neue PowerShell mit Flutter im PATH"
    Write-Host "  2. Oder installiere Flutter von: https://flutter.dev"
    Write-Host ""
    Read-Host "Druecke Enter zum Beenden"
    exit 1
}

Write-Host "[OK] Flutter gefunden: $($flutterCmd.Source)" -ForegroundColor Green
Write-Host ""

# Dependencies holen
Write-Host "[2/5] Hole Dependencies..." -ForegroundColor Yellow
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FEHLER] flutter pub get fehlgeschlagen!" -ForegroundColor Red
    Read-Host "Druecke Enter zum Beenden"
    exit 1
}
Write-Host ""

# Code-Generierung
Write-Host "[3/5] Generiere Code mit build_runner..." -ForegroundColor Yellow
& flutter pub run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNUNG] build_runner hatte Probleme, fahre trotzdem fort..." -ForegroundColor Yellow
}
Write-Host ""

# APK bauen
Write-Host "[4/5] Baue Release APK (dies kann 5-10 Minuten dauern)..." -ForegroundColor Yellow
Write-Host "      Bitte warten..." -ForegroundColor Gray
& flutter build apk --release --split-per-abi

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FEHLER] APK Build fehlgeschlagen!" -ForegroundColor Red
    Read-Host "Druecke Enter zum Beenden"
    exit 1
}
Write-Host ""

# Erfolg
Write-Host "[5/5] APK erfolgreich erstellt!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build erfolgreich abgeschlossen!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$apkPath = "$PSScriptRoot\build\app\outputs\flutter-apk"
Write-Host "APK-Dateien befinden sich hier:" -ForegroundColor Yellow
Write-Host "  $apkPath" -ForegroundColor White
Write-Host ""

if (Test-Path $apkPath) {
    Write-Host "Erstellt wurden:" -ForegroundColor Yellow
    Get-ChildItem "$apkPath\app-*-release.apk" | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  - $($_.Name) ($size MB)" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Hauptdatei zum Testen (moderne Geraete):" -ForegroundColor Yellow
    Write-Host "  app-arm64-v8a-release.apk" -ForegroundColor Green
    Write-Host ""

    # Explorer oeffnen
    $choice = Read-Host "Moechtest du den APK-Ordner im Explorer oeffnen? (J/N)"
    if ($choice -eq "J" -or $choice -eq "j") {
        Start-Process explorer $apkPath
    }
} else {
    Write-Host "[WARNUNG] APK-Ordner nicht gefunden!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Naechste Schritte:" -ForegroundColor Cyan
Write-Host "  1. APK auf GitHub Releases hochladen" -ForegroundColor White
Write-Host "  2. Oder per Google Drive/Dropbox teilen" -ForegroundColor White
Write-Host "  3. Siehe DEPLOYMENT-GUIDE.md fuer Details" -ForegroundColor White
Write-Host ""

Read-Host "Druecke Enter zum Beenden"
