import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../core/supabase/supabase_client.dart'
    show isAuthenticated, isSupabaseAvailable;
import '../models/poi.dart';
import '../models/trip.dart';
import '../repositories/favorites_cloud_repo.dart';
import 'gamification_provider.dart';

part 'favorites_provider.g.dart';

/// Provider für Favoriten-Management (POIs und Routen)
/// keepAlive: true damit der State nicht verloren geht wenn keine Widgets watchen
@Riverpod(keepAlive: true)
class FavoritesNotifier extends _$FavoritesNotifier {
  late Box _favoritesBox;
  FavoritesCloudRepo? _cloudRepo;

  @override
  Future<FavoritesState> build() async {
    _favoritesBox = await Hive.openBox('favorites');

    // Cloud-Repo initialisieren wenn authentifiziert
    if (isAuthenticated && isSupabaseAvailable) {
      _cloudRepo = FavoritesCloudRepo(Supabase.instance.client);
    }

    final localState = await _loadFavorites();

    // Automatischer Cloud-Sync im Hintergrund (fire-and-forget)
    if (_cloudRepo != null) {
      _syncFromCloudInBackground(localState);
    }

    return localState;
  }

  /// Lädt Favoriten aus Hive
  Future<FavoritesState> _loadFavorites() async {
    try {
      // Gespeicherte Routen
      final routesData =
          _favoritesBox.get('saved_routes', defaultValue: <dynamic>[]);
      final routes = <Trip>[];
      for (final json in (routesData as List)) {
        try {
          routes.add(Trip.fromJson(Map<String, dynamic>.from(json as Map)));
        } catch (e) {
          debugPrint('[Favorites] Route parse error: $e');
        }
      }

      // Favorisierte POIs
      final poisData =
          _favoritesBox.get('favorite_pois', defaultValue: <dynamic>[]);
      final pois = <POI>[];
      for (final json in (poisData as List)) {
        try {
          pois.add(POI.fromJson(Map<String, dynamic>.from(json as Map)));
        } catch (e) {
          debugPrint('[Favorites] POI parse error: $e');
        }
      }

      debugPrint(
          '[Favorites] Geladen: ${routes.length} Routen, ${pois.length} POIs');

      return FavoritesState(
        savedRoutes: routes,
        favoritePOIs: pois,
      );
    } catch (e) {
      debugPrint('[Favorites] Fehler beim Laden: $e');
      return const FavoritesState();
    }
  }

  /// Wartet bis der State geladen ist und gibt ihn zurück
  Future<FavoritesState> _ensureLoaded() async {
    // Wenn bereits geladen, direkt zurückgeben
    if (state.hasValue && state.value != null) {
      return state.value!;
    }

    // Warte auf das Laden
    debugPrint('[Favorites] Warte auf State-Laden...');
    final currentState = await future;
    debugPrint(
        '[Favorites] State geladen: ${currentState.routeCount} Routen, ${currentState.poiCount} POIs');
    return currentState;
  }

  // ============================================
  // CLOUD SYNC
  // ============================================

  /// Hintergrund-Sync: Cloud-Daten laden und mit lokalen mergen
  void _syncFromCloudInBackground(FavoritesState localState) {
    Future(() async {
      try {
        await _syncFromCloud(localState);
      } catch (e) {
        debugPrint('[Favorites] Background sync failed: $e');
      }
    });
  }

  /// Bidirektionaler Sync mit Cloud
  Future<void> _syncFromCloud(FavoritesState localState) async {
    if (_cloudRepo == null) return;

    debugPrint('[Favorites] Cloud-Sync gestartet...');
    state = AsyncValue.data(localState.copyWith(isSyncing: true));

    try {
      // 1. Cloud-Daten laden
      final cloudTrips = await _cloudRepo!.fetchAllTrips();
      final cloudPOIs = await _cloudRepo!.fetchAllPOIs();

      debugPrint(
          '[Favorites] Cloud: ${cloudTrips.length} Trips, ${cloudPOIs.length} POIs');

      // 2. Merge: Trips
      final mergedRoutes = _mergeTrips(localState.savedRoutes, cloudTrips);

      // 3. Merge: POIs
      final mergedPOIs = _mergePOIs(localState.favoritePOIs, cloudPOIs);

      // 4. Lokal speichern
      await _favoritesBox.put(
        'saved_routes',
        mergedRoutes.map((r) => r.toJson()).toList(),
      );
      await _favoritesBox.put(
        'favorite_pois',
        mergedPOIs.map((p) => p.toJson()).toList(),
      );

      // 5. State aktualisieren
      state = AsyncValue.data(FavoritesState(
        savedRoutes: mergedRoutes,
        favoritePOIs: mergedPOIs,
        isSyncing: false,
      ));

      // 6. Lokale Daten hochladen die in Cloud fehlen
      final cloudTripIds = cloudTrips.map((t) => t.id).toSet();
      final localOnlyTrips =
          localState.savedRoutes.where((t) => !cloudTripIds.contains(t.id));
      for (final trip in localOnlyTrips) {
        await _cloudRepo!.uploadTrip(trip);
      }

      final cloudPOIIds = cloudPOIs.map((p) => p.id).toSet();
      final localOnlyPOIs =
          localState.favoritePOIs.where((p) => !cloudPOIIds.contains(p.id));
      for (final poi in localOnlyPOIs) {
        await _cloudRepo!.uploadPOI(poi);
      }

      debugPrint(
          '[Favorites] Sync abgeschlossen: ${mergedRoutes.length} Routen, ${mergedPOIs.length} POIs');
    } catch (e) {
      debugPrint('[Favorites] Cloud-Sync Fehler: $e');
      // State ohne Sync-Flag zuruecksetzen
      state = AsyncValue.data(localState.copyWith(isSyncing: false));
    }
  }

  /// Merge lokale und Cloud-Trips (Union, lokal hat Vorrang bei Duplikaten)
  List<Trip> _mergeTrips(List<Trip> local, List<Trip> cloud) {
    final localIds = local.map((t) => t.id).toSet();
    final merged = List<Trip>.from(local);

    for (final cloudTrip in cloud) {
      if (!localIds.contains(cloudTrip.id)) {
        merged.add(cloudTrip);
      }
    }

    return merged;
  }

  /// Merge lokale und Cloud-POIs (Union, lokal hat Vorrang bei Duplikaten)
  List<POI> _mergePOIs(List<POI> local, List<POI> cloud) {
    final localIds = local.map((p) => p.id).toSet();
    final merged = List<POI>.from(local);

    for (final cloudPOI in cloud) {
      if (!localIds.contains(cloudPOI.id)) {
        merged.add(cloudPOI);
      }
    }

    return merged;
  }

  /// Manueller Cloud-Sync (fuer UI-Button)
  Future<void> syncFromCloud() async {
    final current = await _ensureLoaded();
    if (_cloudRepo == null) {
      // Versuche Repo neu zu initialisieren (falls User sich gerade eingeloggt hat)
      if (isAuthenticated && isSupabaseAvailable) {
        _cloudRepo = FavoritesCloudRepo(Supabase.instance.client);
      } else {
        debugPrint('[Favorites] Cloud-Sync nicht moeglich: nicht authentifiziert');
        return;
      }
    }
    await _syncFromCloud(current);
  }

  // ============================================
  // TRIP OPERATIONS
  // ============================================

  /// Speichert Route zu Favoriten
  Future<void> saveRoute(Trip trip) async {
    final current = await _ensureLoaded();

    // Prüfe ob Route bereits existiert
    final exists = current.savedRoutes.any((r) => r.id == trip.id);
    if (exists) {
      debugPrint('[Favorites] Route bereits gespeichert: ${trip.name}');
      return;
    }

    final updated = [trip, ...current.savedRoutes];
    await _favoritesBox.put(
      'saved_routes',
      updated.map((r) => r.toJson()).toList(),
    );

    state = AsyncValue.data(current.copyWith(savedRoutes: updated));
    debugPrint('[Favorites] Route gespeichert: ${trip.name}');

    // XP fuer Trip-Erstellung vergeben
    await ref.read(gamificationNotifierProvider.notifier).onTripCreated();

    // Cloud-Sync (fire-and-forget)
    if (_cloudRepo != null) {
      _cloudRepo!.uploadTrip(trip).catchError((e) {
        debugPrint('[Favorites] Cloud upload trip failed: $e');
        return false;
      });
    }
  }

  /// Entfernt Route aus Favoriten
  Future<void> removeRoute(String tripId) async {
    final current = await _ensureLoaded();

    final updated = current.savedRoutes.where((r) => r.id != tripId).toList();
    await _favoritesBox.put(
      'saved_routes',
      updated.map((r) => r.toJson()).toList(),
    );

    state = AsyncValue.data(current.copyWith(savedRoutes: updated));
    debugPrint('[Favorites] Route entfernt: $tripId');

    // Cloud-Sync: auch aus Cloud loeschen
    if (_cloudRepo != null) {
      _cloudRepo!.deleteTrip(tripId).catchError((e) {
        debugPrint('[Favorites] Cloud delete trip failed: $e');
        return false;
      });
    }
  }

  /// Löscht alle gespeicherten Routen (für Migration nach Bugfix v1.7.13)
  Future<void> clearAllRoutes() async {
    final current = await _ensureLoaded();

    await _favoritesBox.put('saved_routes', []);
    state = AsyncValue.data(current.copyWith(savedRoutes: []));
    debugPrint('[Favorites] Alle Routen gelöscht (Migration)');
  }

  /// Prüft ob Route gespeichert ist
  bool isRouteSaved(String tripId) {
    final current = state.value;
    if (current == null) return false;
    return current.savedRoutes.any((r) => r.id == tripId);
  }

  // ============================================
  // POI OPERATIONS
  // ============================================

  /// Speichert POI zu Favoriten
  Future<void> addPOI(POI poi) async {
    final current = await _ensureLoaded();

    // Prüfe ob POI bereits existiert
    final exists = current.favoritePOIs.any((p) => p.id == poi.id);
    if (exists) {
      debugPrint('[Favorites] POI bereits favorisiert: ${poi.name}');
      return;
    }

    final updated = [poi, ...current.favoritePOIs];
    await _favoritesBox.put(
      'favorite_pois',
      updated.map((p) => p.toJson()).toList(),
    );

    state = AsyncValue.data(current.copyWith(favoritePOIs: updated));
    debugPrint('[Favorites] POI favorisiert: ${poi.name}');

    // Cloud-Sync (fire-and-forget)
    if (_cloudRepo != null) {
      _cloudRepo!.uploadPOI(poi).catchError((e) {
        debugPrint('[Favorites] Cloud upload POI failed: $e');
        return false;
      });
    }
  }

  /// Entfernt POI aus Favoriten
  Future<void> removePOI(String poiId) async {
    final current = await _ensureLoaded();

    final updated = current.favoritePOIs.where((p) => p.id != poiId).toList();
    await _favoritesBox.put(
      'favorite_pois',
      updated.map((p) => p.toJson()).toList(),
    );

    state = AsyncValue.data(current.copyWith(favoritePOIs: updated));
    debugPrint('[Favorites] POI entfernt: $poiId');

    // Cloud-Sync: auch aus Cloud loeschen
    if (_cloudRepo != null) {
      _cloudRepo!.deletePOI(poiId).catchError((e) {
        debugPrint('[Favorites] Cloud delete POI failed: $e');
        return false;
      });
    }
  }

  /// Toggle POI-Favorit
  Future<void> togglePOI(POI poi) async {
    if (isPOIFavorite(poi.id)) {
      await removePOI(poi.id);
    } else {
      await addPOI(poi);
    }
  }

  /// Prüft ob POI favorisiert ist
  bool isPOIFavorite(String poiId) {
    final current = state.value;
    if (current == null) return false;
    return current.favoritePOIs.any((p) => p.id == poiId);
  }

  /// Löscht alle Favoriten
  Future<void> clearAll() async {
    await _favoritesBox.clear();
    state = const AsyncValue.data(FavoritesState());
    debugPrint('[Favorites] Alle Favoriten gelöscht');
  }
}

/// Favoriten-State
class FavoritesState {
  final List<Trip> savedRoutes;
  final List<POI> favoritePOIs;
  final bool isSyncing;

  const FavoritesState({
    this.savedRoutes = const [],
    this.favoritePOIs = const [],
    this.isSyncing = false,
  });

  FavoritesState copyWith({
    List<Trip>? savedRoutes,
    List<POI>? favoritePOIs,
    bool? isSyncing,
  }) {
    return FavoritesState(
      savedRoutes: savedRoutes ?? this.savedRoutes,
      favoritePOIs: favoritePOIs ?? this.favoritePOIs,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  /// Anzahl gespeicherter Routen
  int get routeCount => savedRoutes.length;

  /// Anzahl favorisierter POIs
  int get poiCount => favoritePOIs.length;

  /// Hat Favoriten?
  bool get hasFavorites => savedRoutes.isNotEmpty || favoritePOIs.isNotEmpty;
}

/// Helper Provider: Gibt gespeicherte Routen zurück
@riverpod
List<Trip> savedRoutes(SavedRoutesRef ref) {
  final favorites = ref.watch(favoritesNotifierProvider);
  return favorites.value?.savedRoutes ?? [];
}

/// Helper Provider: Gibt favorisierte POIs zurück
@riverpod
List<POI> favoritePOIs(FavoritePOIsRef ref) {
  final favorites = ref.watch(favoritesNotifierProvider);
  return favorites.value?.favoritePOIs ?? [];
}

/// Helper Provider: Prüft ob POI favorisiert ist
@riverpod
bool isPOIFavorite(IsPOIFavoriteRef ref, String poiId) {
  final favorites = ref.watch(favoritesNotifierProvider);
  return favorites.value?.favoritePOIs.any((p) => p.id == poiId) ?? false;
}

/// Helper Provider: Prüft ob Route gespeichert ist
@riverpod
bool isRouteSaved(IsRouteSavedRef ref, String tripId) {
  final favorites = ref.watch(favoritesNotifierProvider);
  return favorites.value?.savedRoutes.any((r) => r.id == tripId) ?? false;
}
