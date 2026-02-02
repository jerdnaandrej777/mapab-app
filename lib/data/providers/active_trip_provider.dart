import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/active_trip_service.dart';
export '../services/active_trip_service.dart' show ActiveTripData;

part 'active_trip_provider.g.dart';

/// Provider für reaktiven Zugriff auf den aktiven Trip
/// keepAlive: true damit der State über Screen-Wechsel erhalten bleibt
@Riverpod(keepAlive: true)
class ActiveTripNotifier extends _$ActiveTripNotifier {
  @override
  Future<ActiveTripData?> build() async {
    final service = ref.read(activeTripServiceProvider);
    final data = await service.loadTrip();
    if (data != null) {
      debugPrint('[ActiveTrip] Aktiver Trip beim Start gefunden: ${data.trip.name}, '
          '${data.completedDays.length}/${data.trip.actualDays} Tage');
    }
    return data;
  }

  /// Aktualisiert den State nach Speichern/Löschen
  Future<void> refresh() async {
    final service = ref.read(activeTripServiceProvider);
    state = AsyncData(await service.loadTrip());
  }

  /// Löscht den aktiven Trip
  Future<void> clear() async {
    final service = ref.read(activeTripServiceProvider);
    await service.clearTrip();
    state = const AsyncData(null);
    debugPrint('[ActiveTrip] Aktiver Trip gelöscht');
  }
}
