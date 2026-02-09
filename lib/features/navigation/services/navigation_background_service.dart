import 'package:flutter/foundation.dart';

import 'navigation_background_service_android.dart';
import 'navigation_background_service_ios.dart';
import 'navigation_background_service_noop.dart';

typedef NavigationBackgroundDataCallback = void Function(Object data);

NavigationBackgroundService? _debugServiceOverride;

abstract class NavigationBackgroundService {
  Future<void> initialize();

  Future<bool> start({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  });

  Future<void> stop();

  Future<void> update({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  });

  Future<bool> isRunning();

  void setDataCallback(NavigationBackgroundDataCallback callback);

  void removeDataCallback(NavigationBackgroundDataCallback callback);
}

NavigationBackgroundService createNavigationBackgroundService() {
  if (_debugServiceOverride != null) {
    return _debugServiceOverride!;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AndroidNavigationBackgroundService.instance;
    case TargetPlatform.iOS:
      return IOSNavigationBackgroundService.instance;
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return NoopNavigationBackgroundService.instance;
  }
}

@visibleForTesting
void setNavigationBackgroundServiceOverride(
  NavigationBackgroundService? service,
) {
  _debugServiceOverride = service;
}
