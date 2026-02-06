import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/supabase/supabase_client.dart' show isAuthenticated;
import '../models/poi.dart';
import '../models/trip.dart';
import '../services/sync_service.dart';
import 'gamification_provider.dart';

part 'favorites_provider.g.dart';

/// Provider für Favoriten-Management (POIs und Routen)
/// keepAlive: true damit der State nicht verloren geht wenn keine Widgets watchen
@Riverpod(keepAlive: true)
class FavoritesNotifier extends _$FavoritesNotifier {
  late Box _favoritesBox;

  @override
  Future<FavoritesState> build() async {
    _favoritesBox = await Hive.openBox('favorites');
    return await _loadFavorites();
  }

  /// Lädt Favoriten aus Hive
  Future<FavoritesState> _loadFavorites() async {
    try {
      // Gespeicherte Routen
      final routesData = _favoritesBox.get('saved_routes', defaultValue: <dynamic>[]);
      final routes = (routesData as List)
          .map((json) => Trip.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      // Favorisierte POIs
      final poisData = _favoritesBox.get('favorite_pois', defaultValue: <dynamic>[]);
      final pois = (poisData as List)
          .map((json) => POI.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      debugPrint('[Favorites] Geladen: ${routes.length} Routen, ${pois.length} POIs');

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
    debugPrint('[Favorites] State geladen: ${currentState.routeCount} Routen, ${currentState.poiCount} POIs');
    return currentState;
  }

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

    // Cloud-Sync (wenn authentifiziert)
    if (isAuthenticated) {
      final syncService = ref.read(syncServiceProvider);
      await syncService.saveTrip(
        name: trip.name,
        route: trip.route,
        stops: trip.stops,
        isFavorite: true,
      );
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

    // Cloud-Sync (wenn authentifiziert)
    if (isAuthenticated) {
      final syncService = ref.read(syncServiceProvider);
      await syncService.saveFavoritePOI(poi);
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

    // Cloud-Sync (wenn authentifiziert)
    if (isAuthenticated) {
      final syncService = ref.read(syncServiceProvider);
      await syncService.removeFavoritePOI(poiId);
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

  const FavoritesState({
    this.savedRoutes = const [],
    this.favoritePOIs = const [],
  });

  FavoritesState copyWith({
    List<Trip>? savedRoutes,
    List<POI>? favoritePOIs,
  }) {
    return FavoritesState(
      savedRoutes: savedRoutes ?? this.savedRoutes,
      favoritePOIs: favoritePOIs ?? this.favoritePOIs,
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
  return ref.watch(favoritesNotifierProvider.notifier).isPOIFavorite(poiId);
}

/// Helper Provider: Prüft ob Route gespeichert ist
@riverpod
bool isRouteSaved(IsRouteSavedRef ref, String tripId) {
  return ref.watch(favoritesNotifierProvider.notifier).isRouteSaved(tripId);
}
