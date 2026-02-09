# MapAB Deployment Guide

## 🚀 Schnell-Deployment in 3 Schritten

### Vorbereitungen

Öffne eine **neue Command Prompt** oder **PowerShell** als Administrator.

---

## Teil 1: Flutter App Build erstellen

### Schritt 1: Code-Generierung ausführen

```bash
cd <PROJECT_ROOT>
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

> **Hinweis:** Ersetze `<PROJECT_ROOT>` mit deinem lokalen Projektpfad (z.B. `C:\Users\DeinName\Projects\MapAB`).

**Wichtig:** Dieser Schritt generiert die fehlenden Freezed-Dateien für das Account-System.

### Schritt 2: Android APK erstellen

```bash
# Debug APK (zum Testen)
flutter build apk --debug

# Release APK (für Veröffentlichung)
flutter build apk --release --split-per-abi
```

**Split-per-abi** erstellt 3 separate APKs für verschiedene Architekturen:
- `app-armeabi-v7a-release.apk` (32-bit ARM, ältere Geräte)
- `app-arm64-v8a-release.apk` (64-bit ARM, moderne Geräte) ⭐ **Meistens diese**
- `app-x86_64-release.apk` (Intel/AMD CPUs, Emulatoren)

**APK-Speicherort:**
```
<PROJECT_ROOT>/build/app/outputs/flutter-apk/
```

### Schritt 3: APK online hosten

**Option A: GitHub Release (Empfohlen)**

1. Erstelle ein GitHub Repository
2. Gehe zu "Releases" → "Create new release"
3. Lade die APK hoch
4. Veröffentlichen
5. **Download-Link:** `https://github.com/DEIN-USERNAME/mapab/releases/download/v1.0.0/app-arm64-v8a-release.apk`

**Option B: Google Drive**

1. Lade APK in Google Drive hoch
2. Rechtsklick → "Link abrufen"
3. Setze auf "Jeder mit dem Link kann ansehen"
4. Teile den Link

**Option C: Dropbox**

1. Lade APK zu Dropbox hoch
2. "Link teilen" → "Link erstellen"
3. Ändere `?dl=0` zu `?dl=1` für direkten Download

**Option D: Firebase App Distribution (Professionell)**

```bash
# Firebase CLI installieren
npm install -g firebase-tools

# Einloggen
firebase login

# App Distribution einrichten
firebase init appdistribution

# APK hochladen
firebase appdistribution:distribute "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" \
  --app YOUR_FIREBASE_APP_ID \
  --groups testers
```

---

## Teil 2: PWA auf Netlify deployen

### Methode 1: Netlify Drop (Einfachste Methode)

1. Gehe zu https://app.netlify.com/drop
2. Ziehe den **gesamten** `Mobi` Ordner in das Upload-Feld
3. Warte auf Deployment (30-60 Sekunden)
4. **Link:** `https://random-name-12345.netlify.app`

**Tipp:** Klicke auf "Domain Settings" um eine eigene Subdomain zu setzen:
- `mapab-travel.netlify.app`
- `mapab-reiseplaner.netlify.app`

### Methode 2: Netlify CLI (Fortgeschritten)

```bash
# Netlify CLI installieren
npm install -g netlify-cli

# In PWA-Ordner wechseln
cd <PROJECT_ROOT>/web

# Deployen
netlify deploy --dir=. --prod
```

**Beim ersten Mal:**
1. Login durchführen
2. "Create & configure a new site" wählen
3. Team auswählen
4. Site Name eingeben (z.B. `mapab-travel`)

**Link:** `https://mapab-travel.netlify.app`

### Methode 3: GitHub Pages (Kostenlos)

1. Erstelle ein GitHub Repository
2. Pushe den `Mobi` Ordner dorthin
3. Gehe zu Settings → Pages
4. Source: `main` branch, `/` (root)
5. Save

**Link:** `https://DEIN-USERNAME.github.io/mapab/`

---

## Teil 3: Veröffentlichung

### Android APK verteilen

**Für Beta-Tester:**
```
Hallo! 👋

Hier ist die MapAB App zum Download:

📱 Android APK:
https://github.com/DEIN-USERNAME/mapab/releases/download/v1.0.0/app-arm64-v8a-release.apk

Installationsanleitung:
1. Link öffnen
2. APK herunterladen
3. "Aus unbekannten Quellen installieren" erlauben
4. APK öffnen und installieren

Features:
✅ 14 Features: Dark Mode, AI-Chat, Account-System, etc.
✅ Offline-fähig mit GPS-Fallback
✅ 527 kuratierte POIs in Europa

Viel Spaß beim Testen!
```

**Für Play Store:**

1. Google Play Console Account erstellen ($25 einmalig)
2. AAB erstellen:
   ```bash
   flutter build appbundle --release
   ```
3. AAB hochladen: `build/app/outputs/bundle/release/app-release.aab`
4. Screenshots, Beschreibung, etc. hinzufügen
5. Review einreichen (1-7 Tage)

### iOS über TestFlight verteilen

Voraussetzungen:
1. Mac + Xcode
2. Apple Developer Account
3. App Store Connect App mit Bundle ID `com.mapab.app`
4. Signing-Assets (Zertifikat + Provisioning Profile)

Lokaler Build:
```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release --export-method app-store
```

CI Build + Upload (empfohlen):
1. GitHub Secrets laut `docs/guides/IOS-SETUP.md` setzen
2. Workflow `.github/workflows/ios-testflight.yml` ausführen
3. Build in App Store Connect unter TestFlight prüfen
4. Interne Tester-Gruppe zuweisen

### PWA teilen

```
MapAB Reiseplaner ist jetzt live! 🚀

🌐 Web-App:
https://mapab-travel.netlify.app

Features:
✅ Route planen mit Fast/Scenic Toggle
✅ 527 POIs in Europa
✅ Wetter-Integration
✅ Hotel-Suche mit Booking.com
✅ Kein Download nötig - läuft im Browser

Teste es aus!
```

---

## Troubleshooting

### Problem: APK lässt sich nicht installieren

**Lösung:**
1. Gehe zu Android-Einstellungen → Sicherheit
2. Aktiviere "Unbekannte Quellen" oder "Apps aus unbekannten Quellen installieren"
3. Versuche Installation erneut

### Problem: "App wurde nicht installiert"

**Mögliche Ursachen:**
- Falsche Architektur (probiere `app-armeabi-v7a-release.apk` statt `app-arm64-v8a-release.apk`)
- Nicht genug Speicherplatz
- Alte Version bereits installiert (deinstallieren und neu installieren)

### Problem: PWA funktioniert nicht

**Lösung:**
1. Prüfe Browser Console (F12) auf Fehler
2. Stelle sicher dass alle Dateien hochgeladen wurden:
   - `index.html`
   - `js/` Ordner
   - `css/` Ordner
   - `manifest.json`
   - `service-worker.js`

### Problem: Karten laden nicht in PWA

**Lösung:**
- HTTPS erforderlich (Netlify/GitHub Pages bieten automatisch HTTPS)
- MapLibre GL JS benötigt HTTPS für Tile-Loading

---

## Nächste Schritte

### Jetzt:
1. ✅ APK Build erstellen
2. ✅ APK auf GitHub Releases hochladen
3. ✅ PWA auf Netlify deployen
4. ✅ Links mit Freunden teilen

### Später:
- 📱 Google Play Store Veröffentlichung
- 🍎 Öffentliche iOS App Store Veröffentlichung (nach interner TestFlight-Phase)
- 🌍 Eigene Domain kaufen (mapab.de)
- 📊 Analytics hinzufügen (Google Analytics, Plausible)
- 🚀 Performance optimieren

---

## Wichtige Links

### Downloads & Tools:
- Flutter SDK: https://flutter.dev/docs/get-started/install
- Android Studio: https://developer.android.com/studio
- Netlify: https://app.netlify.com
- GitHub: https://github.com

### Hosting-Optionen:
| Anbieter | Typ | Kosten | Setup |
|----------|-----|--------|-------|
| GitHub Releases | APK | Kostenlos | Einfach |
| Netlify | PWA | Kostenlos (100GB/Monat) | Sehr einfach |
| Google Play | Android | $25 einmalig | Komplex |
| Vercel | PWA | Kostenlos | Einfach |
| Firebase Hosting | PWA/APK | Kostenlos (10GB) | Mittel |

---

## Automatisierung (Optional)

### GitHub Actions für Auto-Deployment

Erstelle `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.5'

      - name: Get dependencies
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release --split-per-abi

      - name: Create Release
        uses: ncipollo/release-action@v1
        with:
          artifacts: "build/app/outputs/flutter-apk/*.apk"
          tag: v${{ github.run_number }}
          token: ${{ secrets.GITHUB_TOKEN }}

  deploy-pwa:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Netlify
        uses: netlify/actions/cli@master
        with:
          args: deploy --dir=Mobi --prod
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

Bei jedem `git push` wird automatisch:
1. APK gebaut
2. GitHub Release erstellt
3. PWA auf Netlify deployed

Für iOS/TestFlight gibt es einen separaten Workflow:
- `.github/workflows/ios-testflight.yml`

---

**Viel Erfolg mit dem Deployment! 🚀**
