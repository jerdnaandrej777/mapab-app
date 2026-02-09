import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import 'navigation_background_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_NavigationTaskHandler());
}

class _NavigationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;
  int _updateCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[BackgroundService/Android] started at $timestamp');

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _updateCount++;
        FlutterForegroundTask.sendDataToMain({
          'type': 'position',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'heading': position.heading,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.millisecondsSinceEpoch,
        });

        if (_updateCount % 10 == 0) {
          FlutterForegroundTask.updateService(
            notificationTitle: 'Navigation aktiv',
            notificationText:
                'GPS-Updates: $_updateCount | Genauigkeit: ${position.accuracy.toStringAsFixed(0)}m',
          );
        }
      },
      onError: (error) {
        debugPrint('[BackgroundService/Android] gps error: $error');
        FlutterForegroundTask.sendDataToMain({
          'type': 'error',
          'message': error.toString(),
        });
      },
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[BackgroundService/Android] stopped at $timestamp');
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map<String, dynamic> && data['type'] == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    // Keine direkte Navigation ohne Payload, sonst kann /navigation crashen.
    FlutterForegroundTask.launchApp('/trip');
  }

  @override
  void onNotificationDismissed() {}
}

class AndroidNavigationBackgroundService
    implements NavigationBackgroundService {
  AndroidNavigationBackgroundService._();

  static final AndroidNavigationBackgroundService instance =
      AndroidNavigationBackgroundService._();

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'mapab_navigation',
        channelName: 'Navigation',
        channelDescription: 'GPS-Tracking waehrend der Navigation',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
    debugPrint('[BackgroundService/Android] initialized');
  }

  @override
  Future<bool> start({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      final result =
          await FlutterForegroundTask.requestNotificationPermission();
      if (result != NotificationPermission.granted) {
        debugPrint(
            '[BackgroundService/Android] notification permission denied');
        return false;
      }
    }

    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Navigation zu $destinationName',
      notificationText:
          '${distanceKm.toStringAsFixed(1)} km | ~$etaMinutes Min.',
      notificationIcon: null,
      notificationButtons: const [
        NotificationButton(id: 'stop', text: 'Beenden'),
      ],
      callback: startCallback,
    );

    debugPrint('[BackgroundService/Android] start result: $result');
    return result is ServiceRequestSuccess;
  }

  @override
  Future<void> stop() async {
    final result = await FlutterForegroundTask.stopService();
    debugPrint('[BackgroundService/Android] stop result: $result');
  }

  @override
  Future<void> update({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Navigation zu $destinationName',
      notificationText:
          '${distanceKm.toStringAsFixed(1)} km | ~$etaMinutes Min.',
    );
  }

  @override
  Future<bool> isRunning() async {
    return FlutterForegroundTask.isRunningService;
  }

  @override
  void setDataCallback(NavigationBackgroundDataCallback callback) {
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  @override
  void removeDataCallback(NavigationBackgroundDataCallback callback) {
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }
}
