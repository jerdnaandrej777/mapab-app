import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../data/models/poi.dart';
import '../constants/categories.dart';
import '../utils/geo_utils.dart';

/// Algorithmus für gewichtete zufällige POI-Auswahl
/// Verwendet für Tagesausflüge und Euro Trips
class RandomPOISelector {
  final Random _random;

  RandomPOISelector({Random? random}) : _random = random ?? Random();

  /// Wählt zufällige POIs basierend auf Gewichtung
  ///
  /// [pois] - Verfügbare POIs
  /// [startLocation] - Startpunkt für Distanz-Berechnung
  /// [count] - Gewünschte Anzahl POIs
  /// [preferredCategories] - Bevorzugte Kategorien (70% Präferenz, 30% zufällig)
  /// [maxPerCategory] - Maximale POIs pro Kategorie (Diversität)
  List<POI> selectRandomPOIs({
    required List<POI> pois,
    required LatLng startLocation,
    required int count,
    List<POICategory> preferredCategories = const [],
    int maxPerCategory = 2,
    double? maxSegmentKm,
    LatLng? tripEndLocation,
    double? remainingTripBudgetKm,
    LatLng? currentAnchorLocation,
  }) {
    if (pois.isEmpty || count <= 0) return [];

    final useConstrainedMode = maxSegmentKm != null ||
        tripEndLocation != null ||
        remainingTripBudgetKm != null ||
        currentAnchorLocation != null;
    if (useConstrainedMode) {
      return _selectConstrainedRandomPOIs(
        pois: pois,
        startLocation: startLocation,
        count: count,
        preferredCategories: preferredCategories,
        maxPerCategory: maxPerCategory,
        maxSegmentKm: maxSegmentKm,
        tripEndLocation: tripEndLocation,
        remainingTripBudgetKm: remainingTripBudgetKm,
        currentAnchorLocation: currentAnchorLocation,
      );
    }

    // POIs mit Gewichtung versehen
    final weightedPOIs = pois.map((poi) {
      final weight = _calculateWeight(
        poi: poi,
        startLocation: startLocation,
        preferredCategories: preferredCategories,
      );
      return _WeightedPOI(poi: poi, weight: weight);
    }).toList();

    // Nach Gewicht sortieren (höchste zuerst)
    weightedPOIs.sort((a, b) => b.weight.compareTo(a.weight));

    // Auswahl mit Diversitäts-Regel
    final selected = <POI>[];
    final categoryCount = <String, int>{};

    // Gewichtete Zufallsauswahl
    final pool = List<_WeightedPOI>.from(weightedPOIs);

    while (selected.length < count && pool.isNotEmpty) {
      // Gewichtete Zufallsauswahl aus dem Pool
      final selectedPOI = _weightedRandomSelect(pool);

      if (selectedPOI == null) break;

      // Diversitäts-Check
      final catCount = categoryCount[selectedPOI.poi.categoryId] ?? 0;
      if (catCount < maxPerCategory) {
        selected.add(selectedPOI.poi);
        categoryCount[selectedPOI.poi.categoryId] = catCount + 1;
      }

      // Aus Pool entfernen (O(n) via indexOf statt O(n) removeWhere)
      final idx = pool.indexOf(selectedPOI);
      if (idx >= 0) pool.removeAt(idx);
    }

    return selected;
  }

  List<POI> _selectConstrainedRandomPOIs({
    required List<POI> pois,
    required LatLng startLocation,
    required int count,
    required List<POICategory> preferredCategories,
    required int maxPerCategory,
    double? maxSegmentKm,
    LatLng? tripEndLocation,
    double? remainingTripBudgetKm,
    LatLng? currentAnchorLocation,
  }) {
    final selected = <POI>[];
    final categoryCount = <String, int>{};
    final usedIds = <String>{};

    var anchor = currentAnchorLocation ?? startLocation;
    var remainingBudget = remainingTripBudgetKm ?? double.infinity;

    while (selected.length < count) {
      final remainingPicks = count - selected.length;
      final candidates = <POI>[];

      for (final poi in pois) {
        if (usedIds.contains(poi.id)) continue;

        final catCount = categoryCount[poi.categoryId] ?? 0;
        if (catCount >= maxPerCategory) continue;

        final segmentKm = GeoUtils.haversineDistance(anchor, poi.location);
        if (maxSegmentKm != null && segmentKm > maxSegmentKm) continue;
        if (segmentKm > remainingBudget) continue;

        if (tripEndLocation != null && maxSegmentKm != null) {
          final remainingSteps = max(1, remainingPicks);
          final distanceToEnd =
              GeoUtils.haversineDistance(poi.location, tripEndLocation);
          if (distanceToEnd > remainingSteps * maxSegmentKm) {
            continue;
          }
        }

        candidates.add(poi);
      }

      if (candidates.isEmpty) break;

      final weighted = candidates.map((poi) {
        final weight = _calculateWeight(
          poi: poi,
          startLocation: anchor,
          preferredCategories: preferredCategories,
        );
        return _WeightedPOI(poi: poi, weight: weight);
      }).toList();

      final selectedWeighted = _weightedRandomSelect(weighted);
      if (selectedWeighted == null) break;

      final picked = selectedWeighted.poi;
      selected.add(picked);
      usedIds.add(picked.id);
      categoryCount[picked.categoryId] =
          (categoryCount[picked.categoryId] ?? 0) + 1;

      final segmentKm = GeoUtils.haversineDistance(anchor, picked.location);
      remainingBudget -= segmentKm;
      anchor = picked.location;
    }

    return selected;
  }

  /// Berechnet das Gewicht für einen POI
  double _calculateWeight({
    required POI poi,
    required LatLng startLocation,
    required List<POICategory> preferredCategories,
  }) {
    double weight = poi.effectiveScore ?? poi.score.toDouble();

    // Kategorie-Bonus (1.5x wenn in Präferenzen)
    final preferredIds = preferredCategories.map((c) => c.id).toSet();
    if (preferredIds.contains(poi.categoryId)) {
      weight *= 1.5;
    }

    // Distanz-Bonus (näher = besser, aber nicht zu nah)
    final distance = GeoUtils.haversineDistance(startLocation, poi.location);

    // Optimale Distanz zwischen 20-100km für interessante Ausflüge
    if (distance < 10) {
      weight *= 0.7; // Zu nah
    } else if (distance < 20) {
      weight *= 0.9;
    } else if (distance <= 100) {
      weight *= 1.2; // Sweet Spot
    } else if (distance <= 150) {
      weight *= 1.0;
    } else {
      // Weiter entfernt - leicht reduzieren
      weight *= 0.8;
    }

    // Kuratiert-Bonus
    if (poi.isCurated) {
      weight *= 1.3;
    }

    // Must-See-Bonus
    if (poi.isMustSee) {
      weight *= 1.4;
    }

    // Wikipedia-Bonus
    if (poi.hasWikipedia) {
      weight *= 1.1;
    }

    // UNESCO-Bonus
    if (poi.isUnesco) {
      weight *= 1.5;
    }

    return weight;
  }

  /// Gewichtete Zufallsauswahl aus Pool
  _WeightedPOI? _weightedRandomSelect(List<_WeightedPOI> pool) {
    if (pool.isEmpty) return null;

    // Gesamtgewicht berechnen
    final totalWeight = pool.fold(0.0, (sum, wp) => sum + wp.weight);

    if (totalWeight <= 0) {
      // Fallback: zufällige Auswahl
      return pool[_random.nextInt(pool.length)];
    }

    // Zufälliger Wert zwischen 0 und Gesamtgewicht
    final randomValue = _random.nextDouble() * totalWeight;

    // POI auswählen
    double cumulative = 0;
    for (final wp in pool) {
      cumulative += wp.weight;
      if (randomValue <= cumulative) {
        return wp;
      }
    }

    // Fallback: letztes Element
    return pool.last;
  }

  /// Würfelt einen einzelnen POI neu (für Reroll-Funktion)
  ///
  /// [previousLocation] - Position des vorherigen POIs/Starts in der Route
  /// [nextLocation] - Position des naechsten POIs/Ziels in der Route
  /// [maxSegmentKm] - Maximale Haversine-Distanz zum Nachbarn (optional)
  POI? rerollSinglePOI({
    required List<POI> availablePOIs,
    required List<POI> currentSelection,
    required POI poiToReplace,
    required LatLng startLocation,
    List<POICategory> preferredCategories = const [],
    LatLng? previousLocation,
    LatLng? nextLocation,
    double? maxSegmentKm,
  }) {
    // Bereits ausgewählte IDs
    final selectedIds = currentSelection
        .where((p) => p.id != poiToReplace.id)
        .map((p) => p.id)
        .toSet();

    // Verfügbare POIs filtern (nicht bereits ausgewählt)
    var available = availablePOIs
        .where((p) => !selectedIds.contains(p.id) && p.id != poiToReplace.id)
        .toList();

    if (available.isEmpty) return null;

    // Distanz-Filter: nur POIs in akzeptabler Entfernung zu Nachbarn
    if (maxSegmentKm != null &&
        (previousLocation != null || nextLocation != null)) {
      final distanceFiltered = available.where((p) {
        if (previousLocation != null) {
          final dist = GeoUtils.haversineDistance(previousLocation, p.location);
          if (dist > maxSegmentKm) return false;
        }
        if (nextLocation != null) {
          final dist = GeoUtils.haversineDistance(p.location, nextLocation);
          if (dist > maxSegmentKm) return false;
        }
        return true;
      }).toList();

      // Nur verwenden wenn Kandidaten gefunden
      if (distanceFiltered.isNotEmpty) {
        available = distanceFiltered;
      }
      // Sonst: Fallback auf alle verfuegbaren POIs (ohne Distanz-Constraint)
    }

    // Gleiche Kategorie bevorzugen (50% Chance)
    final sameCategory = available
        .where((p) => p.categoryId == poiToReplace.categoryId)
        .toList();

    if (sameCategory.isNotEmpty && _random.nextDouble() < 0.5) {
      return _selectFromPool(sameCategory, startLocation, preferredCategories);
    }

    return _selectFromPool(available, startLocation, preferredCategories);
  }

  POI? _selectFromPool(
    List<POI> pool,
    LatLng startLocation,
    List<POICategory> preferredCategories,
  ) {
    final weighted = pool.map((poi) {
      final weight = _calculateWeight(
        poi: poi,
        startLocation: startLocation,
        preferredCategories: preferredCategories,
      );
      return _WeightedPOI(poi: poi, weight: weight);
    }).toList();

    return _weightedRandomSelect(weighted)?.poi;
  }
}

/// Hilfsklasse für gewichtete POIs
class _WeightedPOI {
  final POI poi;
  final double weight;

  _WeightedPOI({required this.poi, required this.weight});
}
