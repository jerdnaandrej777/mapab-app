import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_planner/features/navigation/providers/navigation_provider.dart';
import 'package:travel_planner/features/navigation/services/navigation_background_service.dart';

class _FakeBackgroundService implements NavigationBackgroundService {
  int stopCalls = 0;
  int removeCallbackCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isRunning() async => false;

  @override
  void removeDataCallback(NavigationBackgroundDataCallback callback) {
    removeCallbackCalls++;
  }

  @override
  void setDataCallback(NavigationBackgroundDataCallback callback) {}

  @override
  Future<bool> start({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    return false;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> update({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {}
}

void main() {
  test('stopNavigation stops background service even in idle state', () async {
    final fakeService = _FakeBackgroundService();
    setNavigationBackgroundServiceOverride(fakeService);

    final container = ProviderContainer();
    addTearDown(() {
      container.dispose();
      setNavigationBackgroundServiceOverride(null);
    });

    final notifier = container.read(navigationNotifierProvider.notifier);
    await notifier.stopNavigation();

    expect(fakeService.removeCallbackCalls, 1);
    expect(fakeService.stopCalls, 1);
  });
}
