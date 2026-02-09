import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/elevation.dart';
import '../../../data/repositories/elevation_repo.dart';

part 'elevation_provider.g.dart';

/// State fuer Hoehenprofil-Daten
class ElevationState {
  final ElevationProfile? profile;
  final bool isLoading;
  final String? error;

  /// Koordinaten-Hash der zuletzt geladenen Route (Cache-Key)
  final int? _routeHash;

  const ElevationState({
    this.profile,
    this.isLoading = false,
    this.error,
    int? routeHash,
  }) : _routeHash = routeHash;

  ElevationState copyWith({
    ElevationProfile? profile,
    bool? isLoading,
    String? error,
    int? routeHash,
  }) {
    return ElevationState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      routeHash: routeHash ?? _routeHash,
    );
  }

  bool get hasProfile => profile != null && profile!.points.isNotEmpty;

  /// Prueft ob das Profil fuer die gegebene Route noch gueltig ist
  bool isCacheValidFor(List<LatLng> coords) {
    if (_routeHash == null || profile == null) return false;
    return _routeHash == _computeRouteHash(coords);
  }

  static int _computeRouteHash(List<LatLng> coords) {
    if (coords.isEmpty) return 0;
    // Schneller Hash aus Start, Mitte, Ende + Laenge
    final mid = coords.length ~/ 2;
    return Object.hash(
      coords.length,
      coords.first.latitude.toStringAsFixed(3),
      coords.first.longitude.toStringAsFixed(3),
      coords[mid].latitude.toStringAsFixed(3),
      coords[mid].longitude.toStringAsFixed(3),
      coords.last.latitude.toStringAsFixed(3),
      coords.last.longitude.toStringAsFixed(3),
    );
  }
}

/// Provider fuer Hoehenprofil-Daten.
///
/// Laedt asynchron Hoehendaten von Open-Meteo,
/// cached das Ergebnis pro Route (Route aendert sich selten).
@Riverpod(keepAlive: true)
class ElevationNotifier extends _$ElevationNotifier {
  /// Request-ID fuer Cancellation
  int _loadRequestId = 0;

  @override
  ElevationState build() => const ElevationState();

  /// Laedt das Hoehenprofil fuer eine Route.
  /// Ueberspringt den API-Call wenn das Profil bereits fuer diese Route geladen wurde.
  Future<void> loadElevation(List<LatLng> routeCoordinates) async {
    if (routeCoordinates.length < 2) return;

    final routeHash = ElevationState._computeRouteHash(routeCoordinates);

    // Verhindert Request-Storms durch wiederholte build()-Aufrufe, solange
    // dieselbe Route bereits geladen wird.
    if (state.isLoading && state._routeHash == routeHash) {
      return;
    }

    // Cache-Check: Profil fuer diese Route bereits geladen?
    if (state.isCacheValidFor(routeCoordinates)) {
      debugPrint('[Elevation] Cache gueltig, ueberspringe');
      return;
    }

    final requestId = ++_loadRequestId;

    state = state.copyWith(
      isLoading: true,
      error: null,
      routeHash: routeHash,
    );

    try {
      final repo = ref.read(elevationRepositoryProvider);
      final profile = await repo.getElevationProfile(routeCoordinates);

      // Cancellation-Check
      if (requestId != _loadRequestId) {
        debugPrint('[Elevation] Request $requestId abgebrochen');
        return;
      }

      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );

      debugPrint('[Elevation] Profil geladen: '
          '${profile.formattedAscent} Anstieg, '
          '${profile.formattedDescent} Abstieg, '
          'Max ${profile.formattedMaxElevation}');
    } catch (e) {
      debugPrint('[Elevation] Fehler: $e');
      if (requestId == _loadRequestId) {
        state = state.copyWith(
          isLoading: false,
          error: 'Hoehenprofil konnte nicht geladen werden',
        );
      }
    }
  }

  /// Zuruecksetzen (z.B. bei Route-Loeschung)
  void reset() {
    _loadRequestId++;
    state = const ElevationState();
  }
}
