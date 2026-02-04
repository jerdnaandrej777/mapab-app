import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/route.dart';
import '../../../data/repositories/poi_repo.dart';

part 'corridor_browser_provider.g.dart';

// ── Isolate-Funktionen fuer UI-Freeze-freie Route-Berechnungen ──

/// Haversine-Distanz mit Rohdaten (ohne LatLng-Import, isolate-sicher)
double _havRaw(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  const deg2rad = math.pi / 180;
  final dLat = (lat2 - lat1) * deg2rad;
  final dLng = (lng2 - lng1) * deg2rad;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * deg2rad) *
          math.cos(lat2 * deg2rad) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Berechnet Route-Position (0..1) und Umweg (km) fuer alle POIs.
/// Laeuft in separatem Isolate via compute() → blockiert UI nicht.
///
/// Optimierungen gegenueber GeoUtils.calculateRoutePosition:
/// - Gesamt-Routenlaenge nur 1x berechnet (statt pro POI)
/// - Kumulative Segment-Distanzen vorberechnet
/// - Downsampling der Route vor Aufruf reduziert O(n) pro POI
List<List<double>> _computeRouteEnrichmentIsolate(
    Map<String, List<double>> input) {
  final poisLat = input['poisLat']!;
  final poisLng = input['poisLng']!;
  final routeLat = input['routeLat']!;
  final routeLng = input['routeLng']!;
  final n = routeLat.length;

  if (n < 2) {
    return List.generate(poisLat.length, (_) => [0.0, 0.0]);
  }

  // Kumulative Segment-Distanzen vorberechnen (nur 1x)
  final cumDist = List<double>.filled(n, 0.0);
  for (int i = 1; i < n; i++) {
    cumDist[i] = cumDist[i - 1] +
        _havRaw(routeLat[i - 1], routeLng[i - 1], routeLat[i], routeLng[i]);
  }
  final totalLen = cumDist[n - 1];

  final results = <List<double>>[];
  for (int p = 0; p < poisLat.length; p++) {
    final pLat = poisLat[p];
    final pLng = poisLng[p];

    // Naechsten Punkt auf Route finden
    double minDist = double.infinity;
    int closestSeg = 0;
    double closestT = 0;

    for (int i = 0; i < n - 1; i++) {
      final dx = routeLng[i + 1] - routeLng[i];
      final dy = routeLat[i + 1] - routeLat[i];
      double t = 0;
      if (dx != 0 || dy != 0) {
        t = ((pLng - routeLng[i]) * dx + (pLat - routeLat[i]) * dy) /
            (dx * dx + dy * dy);
        t = t.clamp(0.0, 1.0);
      }
      final cLat = routeLat[i] + t * dy;
      final cLng = routeLng[i] + t * dx;
      final dist = _havRaw(pLat, pLng, cLat, cLng);
      if (dist < minDist) {
        minDist = dist;
        closestSeg = i;
        closestT = t;
      }
    }

    // Route-Position (0..1) berechnen
    final cLat = routeLat[closestSeg] +
        closestT * (routeLat[closestSeg + 1] - routeLat[closestSeg]);
    final cLng = routeLng[closestSeg] +
        closestT * (routeLng[closestSeg + 1] - routeLng[closestSeg]);
    final distInSeg =
        _havRaw(routeLat[closestSeg], routeLng[closestSeg], cLat, cLng);
    final routePos =
        totalLen > 0 ? (cumDist[closestSeg] + distInSeg) / totalLen : 0.0;

    results.add([routePos, minDist * 2]); // [routePosition, detourKm]
  }

  return results;
}

/// State fuer den Korridor-Browser
class CorridorBrowserState {
  final List<POI> corridorPOIs;
  final bool isLoading;
  final String? error;
  final double bufferKm;
  final Set<POICategory> selectedCategories;
  final Set<String> addedPOIIds; // Bereits zum Trip hinzugefuegte POIs

  // Lazy Cache fuer gefilterte POIs - wird bei Filter-relevanten copyWith() zurueckgesetzt
  List<POI>? _filteredPOIsCache;
  int? _newPOICountCache;

  CorridorBrowserState({
    this.corridorPOIs = const [],
    this.isLoading = false,
    this.error,
    this.bufferKm = 30.0,
    this.selectedCategories = const {},
    this.addedPOIIds = const {},
  });

  CorridorBrowserState copyWith({
    List<POI>? corridorPOIs,
    bool? isLoading,
    String? error,
    double? bufferKm,
    Set<POICategory>? selectedCategories,
    Set<String>? addedPOIIds,
  }) {
    final newState = CorridorBrowserState(
      corridorPOIs: corridorPOIs ?? this.corridorPOIs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bufferKm: bufferKm ?? this.bufferKm,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      addedPOIIds: addedPOIIds ?? this.addedPOIIds,
    );
    // Cache nur erhalten wenn Filter-relevante Felder sich NICHT aendern
    // (z.B. bei reinem bufferKm/isLoading/error Update)
    if (corridorPOIs == null && selectedCategories == null && addedPOIIds == null) {
      newState._filteredPOIsCache = _filteredPOIsCache;
      newState._newPOICountCache = _newPOICountCache;
    }
    return newState;
  }

  /// Gefilterte POIs (Kategorie-Filter) - Lazy-cached pro State-Instanz
  List<POI> get filteredPOIs {
    if (_filteredPOIsCache != null) return _filteredPOIsCache!;

    var result = corridorPOIs;

    // Kategorie-Filter
    if (selectedCategories.isNotEmpty) {
      result = result
          .where((poi) => selectedCategories.contains(poi.category))
          .toList();
    }

    _filteredPOIsCache = result;
    return result;
  }

  /// Anzahl neuer POIs (nicht im Trip) - lazy cached
  int get newPOICount {
    if (_newPOICountCache != null) return _newPOICountCache!;
    _newPOICountCache = filteredPOIs.where((p) => !addedPOIIds.contains(p.id)).length;
    return _newPOICountCache!;
  }
}

/// Provider fuer den Korridor-POI-Browser
@riverpod
class CorridorBrowserNotifier extends _$CorridorBrowserNotifier {
  /// Request-ID: Nur die neueste Anfrage darf State aktualisieren.
  /// Verhindert dass alte, langsame Requests stale Daten schreiben.
  int _loadRequestId = 0;

  @override
  CorridorBrowserState build() => CorridorBrowserState();

  /// Laedt POIs entlang des Korridors einer Route
  Future<void> loadCorridorPOIs({
    required AppRoute route,
    double? bufferKm,
    Set<String>? existingStopIds,
  }) async {
    final requestId = ++_loadRequestId;
    final effectiveBuffer = bufferKm ?? state.bufferKm;
    state = state.copyWith(
      isLoading: true,
      error: null,
      bufferKm: effectiveBuffer,
      addedPOIIds: existingStopIds ?? state.addedPOIIds,
    );

    try {
      final poiRepo = ref.read(poiRepositoryProvider);

      // Korridor-Bounds berechnen (Route + Puffer)
      final bounds = GeoUtils.calculateBoundsWithBuffer(
        route.coordinates,
        effectiveBuffer,
      );

      debugPrint('[CorridorBrowser] Lade POIs im Korridor: '
          '${effectiveBuffer.toStringAsFixed(0)}km Puffer, '
          '${route.coordinates.length} Route-Punkte');

      // Kategorie-Filter (leere Liste = alle)
      final categoryFilter = state.selectedCategories.isNotEmpty
          ? state.selectedCategories.map((c) => c.name).toList()
          : null;

      // POIs im Korridor laden (3-Layer: Kuratiert + Wikipedia + Overpass)
      final pois = await poiRepo.loadPOIsInBounds(
        bounds: bounds,
        categoryFilter: categoryFilter,
        maxResults: 150,
      );

      // Cancellation-Check: Wurde inzwischen ein neuer Request gestartet?
      if (requestId != _loadRequestId) {
        debugPrint('[CorridorBrowser] Request $requestId abgebrochen (neuer aktiv)');
        return;
      }

      // POI-Limit vor Compute: Verhindert O(n*m) Explosion im Isolate
      var poisForCompute = pois;
      if (pois.length > 150) {
        poisForCompute = List<POI>.from(pois)
          ..sort((a, b) => b.score.compareTo(a.score));
        poisForCompute = poisForCompute.take(150).toList();
        debugPrint('[Corridor] POIs limitiert: ${pois.length} → 150 fuer Compute');
      }

      // Route-Koordinaten vorbereiten + Downsampling bei langen Routen
      final coords = route.coordinates;
      List<double> rLat;
      List<double> rLng;
      if (coords.length > 500) {
        final step = coords.length / 500;
        rLat = <double>[coords.first.latitude];
        rLng = <double>[coords.first.longitude];
        for (int i = 1; i < 499; i++) {
          final idx = (i * step).round();
          rLat.add(coords[idx].latitude);
          rLng.add(coords[idx].longitude);
        }
        rLat.add(coords.last.latitude);
        rLng.add(coords.last.longitude);
        debugPrint(
            '[Corridor] Route downsampled: ${coords.length} → ${rLat.length} Punkte');
      } else {
        rLat = coords.map((c) => c.latitude).toList();
        rLng = coords.map((c) => c.longitude).toList();
      }

      // Routen-Position und Umweg in separatem Isolate berechnen
      // Verhindert UI-Freeze bei vielen POIs / langen Routen
      final enrichmentResult = await compute(
        _computeRouteEnrichmentIsolate,
        <String, List<double>>{
          'poisLat': poisForCompute.map((p) => p.latitude).toList(),
          'poisLng': poisForCompute.map((p) => p.longitude).toList(),
          'routeLat': rLat,
          'routeLng': rLng,
        },
      );

      // Cancellation-Check nach Isolate-Berechnung
      if (requestId != _loadRequestId) {
        debugPrint('[CorridorBrowser] Request $requestId abgebrochen (neuer aktiv)');
        return;
      }

      final enrichedPOIs = List<POI>.generate(
        poisForCompute.length,
        (i) => poisForCompute[i].copyWith(
          routePosition: enrichmentResult[i][0],
          detourKm: enrichmentResult[i][1],
        ),
      );

      // Nach Position auf Route sortieren (Start → Ziel)
      enrichedPOIs.sort(
          (a, b) => (a.routePosition ?? 0).compareTo(b.routePosition ?? 0));

      debugPrint('[CorridorBrowser] ${enrichedPOIs.length} POIs im Korridor gefunden');

      if (requestId == _loadRequestId) {
        state = state.copyWith(
          corridorPOIs: enrichedPOIs,
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('[CorridorBrowser] Fehler: $e');
      if (requestId == _loadRequestId) {
        state = state.copyWith(
          isLoading: false,
          error: 'POIs konnten nicht geladen werden',
        );
      }
    }
  }

  /// Korridor-Breite aendern und neu laden
  Future<void> setBufferKm(double km, {required AppRoute route}) async {
    state = state.copyWith(bufferKm: km);
    await loadCorridorPOIs(route: route, bufferKm: km);
  }

  /// Korridor-Breite nur visuell aktualisieren (fuer Slider-Drag, kein API-Call)
  void setBufferKmLocal(double km) {
    state = state.copyWith(bufferKm: km);
  }

  /// Kategorien in einem einzigen State-Write setzen (kein Reload, client-side Filter)
  void setCategoriesBatch(Set<POICategory> categories) {
    state = state.copyWith(selectedCategories: categories);
  }

  /// Kategorie-Filter setzen und neu laden
  Future<void> setCategories(
    Set<POICategory> categories, {
    required AppRoute route,
  }) async {
    state = state.copyWith(selectedCategories: categories);
    await loadCorridorPOIs(route: route);
  }

  /// Einzelne Kategorie toggeln
  void toggleCategory(POICategory category) {
    final updated = Set<POICategory>.from(state.selectedCategories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    state = state.copyWith(selectedCategories: updated);
  }

  /// POI als hinzugefuegt markieren
  void markAsAdded(String poiId) {
    state = state.copyWith(
      addedPOIIds: {...state.addedPOIIds, poiId},
    );
  }

  /// POI als entfernt markieren (aus dem Trip geloescht)
  void markAsRemoved(String poiId) {
    state = state.copyWith(
      addedPOIIds: Set<String>.from(state.addedPOIIds)..remove(poiId),
    );
  }

  /// Zuruecksetzen + laufende Requests abbrechen
  void reset() {
    _loadRequestId++;
    state = CorridorBrowserState();
  }
}
