import 'navigation_background_service.dart';

class NoopNavigationBackgroundService implements NavigationBackgroundService {
  NoopNavigationBackgroundService._();

  static final NoopNavigationBackgroundService instance =
      NoopNavigationBackgroundService._();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> start({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    return false;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> update({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {}

  @override
  Future<bool> isRunning() async => false;

  @override
  void setDataCallback(NavigationBackgroundDataCallback callback) {}

  @override
  void removeDataCallback(NavigationBackgroundDataCallback callback) {}
}
