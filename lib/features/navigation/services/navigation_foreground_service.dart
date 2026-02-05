import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

/// Callback-Handler fuer den Foreground-Service.
/// Wird im Hintergrund aufgerufen wenn die App minimiert ist.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(NavigationTaskHandler());
}

/// Task-Handler fuer die Hintergrund-Navigation.
/// Verarbeitet GPS-Updates und sendet sie an die Flutter-UI.
class NavigationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;
  int _updateCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[ForegroundService] Service gestartet um $timestamp');

    // GPS-Stream starten
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Nur bei 5m Bewegung updaten
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _updateCount++;
        // Position an die Flutter-UI senden
        FlutterForegroundTask.sendDataToMain({
          'type': 'position',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'heading': position.heading,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.millisecondsSinceEpoch,
        });

        // Benachrichtigung aktualisieren (alle 10 Updates)
        if (_updateCount % 10 == 0) {
          FlutterForegroundTask.updateService(
            notificationTitle: 'Navigation aktiv',
            notificationText:
                'GPS-Updates: $_updateCount | Genauigkeit: ${position.accuracy.toStringAsFixed(0)}m',
          );
        }
      },
      onError: (error) {
        debugPrint('[ForegroundService] GPS-Fehler: $error');
        FlutterForegroundTask.sendDataToMain({
          'type': 'error',
          'message': error.toString(),
        });
      },
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Periodische Aufgabe (optional)
    // Kann genutzt werden um Heartbeat zu senden
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[ForegroundService] Service gestoppt um $timestamp');
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void onReceiveData(Object data) {
    // Daten von der Flutter-UI empfangen (z.B. Konfigurationsaenderungen)
    if (data is Map<String, dynamic>) {
      final type = data['type'] as String?;
      if (type == 'stop') {
        debugPrint('[ForegroundService] Stop-Befehl empfangen');
        FlutterForegroundTask.stopService();
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    // Benachrichtigungs-Button gedrückt
    if (id == 'stop') {
      debugPrint('[ForegroundService] Stop-Button gedrückt');
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    // Benachrichtigung angetippt - App in den Vordergrund bringen
    FlutterForegroundTask.launchApp('/navigation');
  }

  @override
  void onNotificationDismissed() {
    // Benachrichtigung wegewischt (nur Android 14+)
  }
}

/// Service-Manager fuer die Hintergrund-Navigation.
/// Verwaltet den Start/Stop des Foreground Services.
class NavigationForegroundService {
  NavigationForegroundService._();

  static bool _isInitialized = false;

  /// Initialisiert den Foreground-Task (einmalig aufrufen)
  static Future<void> initialize() async {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'mapab_navigation',
        channelName: 'Navigation',
        channelDescription: 'GPS-Tracking während der Navigation',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // Alle 5 Sekunden
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
    debugPrint('[ForegroundService] Initialisiert');
  }

  /// Startet den Foreground-Service fuer die Navigation
  static Future<bool> startService({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Berechtigungen pruefen
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      final result =
          await FlutterForegroundTask.requestNotificationPermission();
      if (result != NotificationPermission.granted) {
        debugPrint('[ForegroundService] Benachrichtigungs-Berechtigung verweigert');
        return false;
      }
    }

    // Service starten
    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Navigation zu $destinationName',
      notificationText: '${distanceKm.toStringAsFixed(1)} km • ~$etaMinutes Min.',
      notificationIcon: null, // Verwendet Standard-Icon
      notificationButtons: [
        const NotificationButton(id: 'stop', text: 'Beenden'),
      ],
      callback: startCallback,
    );

    debugPrint('[ForegroundService] Service Start: $result');
    // v8.13.0 API: Sealed class pattern
    return result is ServiceRequestSuccess;
  }

  /// Stoppt den Foreground-Service
  static Future<void> stopService() async {
    final result = await FlutterForegroundTask.stopService();
    debugPrint('[ForegroundService] Service Stop: $result');
  }

  /// Aktualisiert die Benachrichtigung waehrend der Navigation
  static Future<void> updateNotification({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Navigation zu $destinationName',
      notificationText: '${distanceKm.toStringAsFixed(1)} km • ~$etaMinutes Min.',
    );
  }

  /// Prüft ob der Service laeuft
  static Future<bool> get isRunning async {
    return await FlutterForegroundTask.isRunningService;
  }

  /// Registriert einen Callback fuer Daten vom Service
  static void setDataCallback(void Function(Object data) callback) {
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  /// Entfernt den Daten-Callback
  static void removeDataCallback(void Function(Object data) callback) {
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }

  /// Sendet Daten an den Service
  static void sendDataToService(Object data) {
    FlutterForegroundTask.sendDataToTask(data);
  }
}
