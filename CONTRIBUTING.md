# Beitragen zu MapAB

Vielen Dank für dein Interesse, zu MapAB beizutragen!

## Entwicklungsumgebung einrichten

### Voraussetzungen

- Flutter SDK 3.24.5 oder höher
- Dart SDK 3.0+
- Android Studio oder VS Code mit Flutter-Extension
- Git

### Setup

```bash
# Repository klonen
git clone https://github.com/jerdnaandrej777/mapab-app.git
cd mapab-app

# Dependencies installieren
flutter pub get

# Code-Generierung ausführen
flutter pub run build_runner build --delete-conflicting-outputs
```

### Umgebungsvariablen konfigurieren

Erstelle eine lokale `.env.local` Datei (wird nicht committed):

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
BACKEND_URL=https://your-backend.vercel.app
```

Starte die App mit:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=BACKEND_URL=...
```

Oder nutze die Build-Scripts (siehe [SECURITY.md](docs/SECURITY.md)).

## Code-Standards

### Dart/Flutter Konventionen

- **Dateinamen:** snake_case (`poi_detail_screen.dart`)
- **Klassen:** PascalCase (`POIDetailScreen`)
- **Variablen/Methoden:** camelCase (`loadPOIs()`)
- **Konstanten:** SCREAMING_SNAKE_CASE oder camelCase

### Architektur

```
lib/
├── core/           # Theme, Constants, Utils
├── data/
│   ├── models/     # Freezed Data Models
│   ├── providers/  # Riverpod Provider
│   ├── repositories/
│   └── services/
└── features/       # Feature-basierte Module
    └── feature_name/
        ├── providers/
        ├── widgets/
        └── feature_screen.dart
```

### State Management (Riverpod)

- Verwende `@riverpod` Annotation für Code-Generierung
- Nutze `keepAlive: true` für persistente Daten (Account, Favorites)
- Dokumentiere Provider mit `/// Kommentar`

```dart
/// Verwaltet den Account-Status des Benutzers.
@Riverpod(keepAlive: true)
class AccountNotifier extends _$AccountNotifier {
  // ...
}
```

### Datenmodelle (Freezed)

```dart
@freezed
class POI with _$POI {
  const factory POI({
    required String id,
    required String name,
    @Default(false) bool isEnriched,
  }) = _POI;

  factory POI.fromJson(Map<String, dynamic> json) => _$POIFromJson(json);
}
```

### Dark Mode

- Verwende `Theme.of(context).colorScheme.*` statt hardcodierte Farben
- Siehe [DARK-MODE.md](docs/guides/DARK-MODE.md) für Details

```dart
// Richtig
color: Theme.of(context).colorScheme.surface

// Falsch
color: Colors.white
```

## Pull Request Prozess

### 1. Branch erstellen

```bash
git checkout -b feature/dein-feature-name
# oder
git checkout -b fix/bug-beschreibung
```

### 2. Änderungen committen

Format: `type(scope): description`

Typen:
- `feat`: Neues Feature
- `fix`: Bug-Fix
- `docs`: Dokumentation
- `refactor`: Code-Refactoring
- `test`: Tests
- `chore`: Build, Dependencies

```bash
git commit -m "feat(poi): add UNESCO highlight badge"
git commit -m "fix(map): resolve dark mode contrast issue"
git commit -m "docs(readme): update installation instructions"
```

### 3. Code-Generierung

Vor dem Push immer ausführen:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Tests

```bash
flutter test
flutter analyze
```

### 5. Pull Request erstellen

1. Push zu GitHub
2. PR erstellen mit aussagekräftigem Titel
3. Beschreibung mit:
   - Was wurde geändert?
   - Warum?
   - Screenshots (bei UI-Änderungen)
   - Getestete Szenarien

## Debugging

### Log-Prefixes

| Prefix | Bereich |
|--------|---------|
| `[POI]` | POI-Repository |
| `[Enrichment]` | POI-Enrichment |
| `[RoutePlanner]` | Route-Berechnung |
| `[Account]` | Account-System |
| `[AI-Chat]` | AI-Service |

### Riverpod DevTools

```dart
// In main.dart aktivieren
void main() {
  runApp(ProviderScope(
    observers: [ProviderLogger()], // Debug-Logging
    child: const MyApp(),
  ));
}
```

## Hilfreiche Ressourcen

- [Flutter Dokumentation](https://docs.flutter.dev/)
- [Riverpod Dokumentation](https://riverpod.dev/)
- [Freezed Dokumentation](https://pub.dev/packages/freezed)
- [MapAB Architecture](docs/architecture/PROVIDER-GUIDE.md)
- [POI System](docs/architecture/POI-SYSTEM.md)

## Fragen?

- **Issues:** https://github.com/jerdnaandrej777/mapab-app/issues
- **Discussions:** https://github.com/jerdnaandrej777/mapab-app/discussions

---

Vielen Dank für deine Beiträge!
