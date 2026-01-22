# MapAB v1.2.8 - Animiertes Onboarding

## Release Date: 22.01.2026

---

## Zusammenfassung

Diese Version fuegt ein anspruchsvolles **animiertes Onboarding** vor dem Login hinzu. Neue Nutzer werden durch 3 animierte Seiten gefuehrt, die die Kernfeatures von MapAB vorstellen: POI-Entdeckung, KI-Reiseplanung und Cloud-Synchronisation.

**Highlights:**
- 🎬 3 animierte Onboarding-Seiten mit nativen Flutter-Animationen
- ✨ CustomPainter fuer Route-Animation und Daten-Partikel
- 🎨 Dunkles Design mit pulsierenden Kreisen und Glow-Effekten
- 📍 Page-Indicator mit animierten Punkten
- 🔄 First-Time Detection via Hive

---

## Neue Features

### 1. Animiertes Onboarding

**3 Seiten mit unterschiedlichen Animationen:**

| Seite | Titel | Highlight-Wort | Animation | Farbe |
|-------|-------|----------------|-----------|-------|
| 1 | "Entdecke Sehenswuerdigkeiten" | "Sehenswuerdigkeiten" | Route + POI-Marker | Blue `#3B82F6` |
| 2 | "Dein KI-Reiseassistent" | "KI" | Pulsierende Kreise | Cyan `#06B6D4` |
| 3 | "Deine Reisen in der Cloud" | "Cloud" | Phone ↔ Cloud Sync | Green `#22C55E` |

### 2. Animation: AnimatedRoute (Seite 1)

```dart
// Staggered Animations mit CustomPainter
// - Route zeichnet sich selbst (Bezier-Kurve)
// - 3 POI-Marker erscheinen nacheinander mit Bounce
// - Pulsierende Ringe um aktive Marker

class _RoutePainter extends CustomPainter {
  void paint(Canvas canvas, Size size) {
    // Path partiell zeichnen
    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(0, length * pathProgress);
    canvas.drawPath(extractPath, linePaint);

    // Marker mit elasticOut Kurve
    _drawMarker(canvas, poi1, marker1Progress, Icons.castle);
  }
}
```

**Timing:**
- 0-60%: Route zeichnet sich
- 25-45%: Marker 1 erscheint (Schloss)
- 45-65%: Marker 2 erscheint (Museum)
- 65-85%: Marker 3 erscheint (See)

### 3. Animation: AnimatedAICircle (Seite 2)

```dart
// 5 AnimationControllers fuer verschiedene Effekte
// Inspiriert vom Referenzbild: Dunkler BG, pulsierende Kreise

_pulse1Controller = AnimationController(duration: 2500ms)..repeat();
_pulse2Controller = AnimationController(duration: 3000ms)..repeat();
_pulse3Controller = AnimationController(duration: 3500ms)..repeat();
_glowController = AnimationController(duration: 2000ms)..repeat(reverse: true);
_iconController = AnimationController(duration: 1500ms)..repeat(reverse: true);
```

**Elemente:**
- Hintergrund-Glow (RadialGradient)
- 3 pulsierende Ringe (unterschiedliche Geschwindigkeiten)
- Statischer innerer Ring
- Zentraler Kreis mit Glow
- _SmileyPainter fuer AI-Face

### 4. Animation: AnimatedSync (Seite 3)

```dart
// Daten-Partikel fliessen zwischen Phone und Cloud
class _DataParticlesPainter extends CustomPainter {
  void paint(Canvas canvas, Size size) {
    // 5 Partikel entlang der Verbindungslinie
    for (int i = 0; i < 5; i++) {
      final particleProgress = (progress + i * 0.2) % 1.0;
      // ... Partikel zeichnen
    }
  }
}
```

**Elemente:**
- Phone-Icon (links) mit Bounce
- Cloud-Icon (rechts) mit Bounce + Checkmark
- 5 animierte Daten-Partikel

### 5. Page Indicator

```dart
// Animierte Punkte: aktiv = breiter Balken
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  width: isActive ? 28 : 10,
  height: 10,
  decoration: BoxDecoration(
    color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.5),
    borderRadius: BorderRadius.circular(5),
  ),
)
```

### 6. Onboarding Provider (Hive)

```dart
@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  static const String _key = 'hasSeenOnboarding';

  @override
  bool build() {
    final box = Hive.box('settings');
    return box.get(_key, defaultValue: false);
  }

  Future<void> completeOnboarding() async {
    final box = Hive.box('settings');
    await box.put(_key, true);
    state = true;
  }
}
```

---

## Geaenderte Dateien

### Neue Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/features/onboarding/onboarding_screen.dart` | PageView-Container mit Header, Buttons |
| `lib/features/onboarding/models/onboarding_page_data.dart` | Page-Konfiguration (Titel, Animation, Farbe) |
| `lib/features/onboarding/providers/onboarding_provider.dart` | Hive First-Time-Flag |
| `lib/features/onboarding/providers/onboarding_provider.g.dart` | Generiert von Riverpod |
| `lib/features/onboarding/widgets/onboarding_page.dart` | Einzelne Seite Layout |
| `lib/features/onboarding/widgets/page_indicator.dart` | Animierte 3-Punkte-Anzeige |
| `lib/features/onboarding/widgets/animated_route.dart` | Route-Animation (CustomPainter) |
| `lib/features/onboarding/widgets/animated_ai_circle.dart` | AI-Pulse (5 Controllers) |
| `lib/features/onboarding/widgets/animated_sync.dart` | Cloud-Sync Animation |

### Modifizierte Dateien

| Datei | Aenderung |
|-------|----------|
| `lib/app.dart` | `/onboarding` Route hinzugefuegt |
| `lib/features/account/splash_screen.dart` | Onboarding-Check vor Auth-Check |

---

## App-Flow mit Onboarding

```
┌─────────────────────────────────────────────────────┐
│                    App Start                         │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│              SplashScreen (2s)                       │
│   ref.read(onboardingNotifierProvider)              │
└──────────────────┬──────────────────────────────────┘
                   │
         ┌────────┴────────┐
         │                 │
    hasSeenOnboarding   !hasSeenOnboarding
         │                 │
         v                 v
┌─────────────┐   ┌─────────────────────────────────┐
│ Auth-Check  │   │        OnboardingScreen          │
│ → /login    │   │   PageView (3 animierte Seiten) │
│ → /         │   │                                  │
└─────────────┘   │   Seite 1: AnimatedRoute         │
                  │   Seite 2: AnimatedAICircle      │
                  │   Seite 3: AnimatedSync          │
                  │                                  │
                  │   Header: "Ueberspringen"        │
                  │   Footer: "Weiter" / "Los geht's"│
                  └──────────────┬──────────────────┘
                                 │
                                 v
                  ┌─────────────────────────────────┐
                  │    completeOnboarding()          │
                  │    Hive: hasSeenOnboarding=true  │
                  │    context.go('/login')          │
                  └─────────────────────────────────┘
```

---

## Design-Spezifikationen

### Farben

| Element | Wert | Verwendung |
|---------|------|------------|
| Hintergrund | `#0F172A` | Immer dunkel (unabhaengig vom System-Theme) |
| Primary | `#3B82F6` | Route-Animation, aktiver Dot, Buttons |
| Secondary | `#06B6D4` | AI-Circle, Pulse-Ringe |
| Tertiary | `#22C55E` | Cloud-Sync Animation |
| Text Primary | `#FFFFFF` | Titel |
| Text Secondary | `#FFFFFF70` | Untertitel, "Ueberspringen" |
| Inaktiver Dot | `#47556980` | Page Indicator |

### Typography

```dart
// Titel
TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Colors.white,
)

// Untertitel
TextStyle(
  fontSize: 16,
  color: Colors.white.withValues(alpha: 0.7),
  height: 1.5,
)
```

### Buttons

```dart
// Primary Button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: EdgeInsets.symmetric(vertical: 16),
  ),
)

// Secondary Button (letzte Seite)
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
  ),
)
```

---

## Verifikation (Checkliste)

### Erstmaliger Start
- [ ] App-Daten loeschen oder frische Installation
- [ ] App starten
- [ ] Onboarding erscheint mit Animationen
- [ ] Alle 3 Seiten haben unterschiedliche Animationen

### Navigation
- [ ] Links wischen → vorherige Seite
- [ ] Rechts wischen → naechste Seite
- [ ] "Weiter" Button → naechste Seite
- [ ] Page Indicator aktualisiert sich

### Abschluss
- [ ] Seite 3: "Los geht's" klicken
- [ ] Weiterleitung zu /login erfolgt
- [ ] "Ich habe bereits ein Konto" → auch zu /login

### Ueberspringen
- [ ] "Ueberspringen" im Header klicken
- [ ] Direkt zu /login weitergeleitet

### Wiederholter Start
- [ ] App schliessen und neu starten
- [ ] Kein Onboarding mehr
- [ ] Direkt zu Splash → Auth-Check → /login oder /

### Animationen
- [ ] Route zeichnet sich progressiv
- [ ] POI-Marker erscheinen mit Bounce
- [ ] AI-Kreise pulsieren kontinuierlich
- [ ] Smiley "atmet" (leichtes Skalieren)
- [ ] Daten-Partikel fliessen zwischen Icons

---

## Migration Guide

### Von v1.2.7 zu v1.2.8

Keine Breaking Changes. Nach Update:

1. **build_runner ausfuehren:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Onboarding wird automatisch angezeigt** bei erstem Start (wenn nicht vorher gesehen)

3. **Zum Testen:** Onboarding zuruecksetzen via:
   ```dart
   ref.read(onboardingNotifierProvider.notifier).resetOnboarding();
   ```

---

## Build Info

- **Version:** 1.2.8
- **Flutter:** 3.38.7
- **Dart:** 3.10.7
- **Min Android SDK:** 21 (Android 5.0)
- **Target Android SDK:** 34 (Android 14)
- **Neue Dependencies:** Keine (nur native Flutter-Animationen)
