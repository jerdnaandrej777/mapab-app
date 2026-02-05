# CHANGELOG v1.10.7 - Filter-Modal Fix

**Datum:** 2026-02-06
**Build:** 188

## Zusammenfassung

Bugfix für das Filter-Modal in der Trip-Galerie. Buttons werden jetzt sofort als ausgewählt markiert, anstatt erst nach Schließen und Wiederöffnen des Modals.

## Bugfixes

### Filter-Modal Buttons reagieren nicht sofort

**Problem:**
Im Filter-Modal der Trip-Galerie wurden die Filter-Buttons (Trip-Typ, Tags, Sortierung) beim Auswählen nicht sofort als ausgewählt markiert. Der Benutzer sah erst nach dem Schließen und Wiederöffnen des Modals, dass die Filter aktiv waren.

**Ursache:**
Das `_FilterSheet` Widget erhielt den `GalleryState` als Konstruktor-Parameter statt ihn direkt aus dem Provider zu holen. Dadurch wurde das Widget nicht neu gebaut, wenn sich der State änderte:

```dart
// VORHER - State als Parameter (nicht reaktiv)
class _FilterSheet extends ConsumerWidget {
  final GalleryState state;  // Einmal beim Öffnen übergeben, nie aktualisiert
  final ScrollController scrollController;

  const _FilterSheet({
    required this.state,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    // state.tripTypeFilter ändert sich nie, da state ein alter Snapshot ist
```

**Lösung:**
Der State wird jetzt direkt mit `ref.watch()` aus dem Provider geholt, wodurch das Widget automatisch neu gebaut wird bei Änderungen:

```dart
// NACHHER - State direkt aus Provider (reaktiv)
class _FilterSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _FilterSheet({
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // State direkt aus dem Provider holen fuer sofortige Updates
    final state = ref.watch(galleryNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    // state.tripTypeFilter wird bei jeder Änderung aktualisiert
```

**Datei:** `lib/features/social/gallery_screen.dart` (Zeile 354-365)

---

## Technische Details

### Betroffene Dateien

| Datei | Änderungen |
|-------|------------|
| `lib/features/social/gallery_screen.dart` | `_FilterSheet` holt State via `ref.watch()` statt Parameter |
| `pubspec.yaml` | Version 1.10.7+188 |

### Riverpod Pattern für Modals

**Best Practice:** Bei `ConsumerWidget`-Modals sollte der State immer direkt mit `ref.watch()` geholt werden, nicht als Parameter übergeben. Dies stellt sicher, dass das Modal reaktiv auf State-Änderungen reagiert.

```dart
// RICHTIG - Modal mit ref.watch()
class _MyModal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);  // Reaktiv
    return ...;
  }
}

// FALSCH - Modal mit State-Parameter
class _MyModal extends ConsumerWidget {
  final MyState state;  // Nicht reaktiv!
  const _MyModal({required this.state});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ...;  // state ändert sich nie
  }
}
```

### Verifikation

1. App starten
2. Zur Trip-Galerie navigieren
3. Filter-Button (oben rechts) antippen
4. Einen Trip-Typ-Chip auswählen → Chip wird sofort visuell markiert
5. Einen Tag-Chip auswählen → Chip wird sofort visuell markiert
6. Sortierung ändern → Radio-Button wird sofort aktiv

---

## Upgrade-Hinweise

Keine manuellen Schritte erforderlich. Einfach die neue Version installieren.
