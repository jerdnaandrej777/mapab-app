import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service.g.dart';

/// Notification Channels
class NotificationChannels {
  static const String weatherAlerts = 'weather_alerts';
  static const String tripReminders = 'trip_reminders';
  static const String poiNearby = 'poi_nearby';
  static const String general = 'general';
}

/// Notification Service für lokale Benachrichtigungen
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  NotificationService() : _notifications = FlutterLocalNotificationsPlugin();

  /// Initialisiert den Notification Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Timezone initialisieren
    tz.initializeTimeZones();

    // Android-Einstellungen
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS-Einstellungen
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialisieren
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android Notification Channels erstellen
    await _createNotificationChannels();

    _isInitialized = true;
  }

  /// Erstellt Notification Channels für Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Wetter-Warnungen Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.weatherAlerts,
        'Wetter-Warnungen',
        description: 'Benachrichtigungen über Wetteränderungen auf deiner Route',
        importance: Importance.high,
      ),
    );

    // Trip-Erinnerungen Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.tripReminders,
        'Trip-Erinnerungen',
        description: 'Erinnerungen für geplante Ausflüge',
        importance: Importance.defaultImportance,
      ),
    );

    // POI in der Nähe Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.poiNearby,
        'POIs in der Nähe',
        description: 'Hinweise auf interessante Orte in deiner Nähe',
        importance: Importance.low,
      ),
    );

    // Allgemeiner Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.general,
        'Allgemein',
        description: 'Allgemeine Benachrichtigungen',
        importance: Importance.defaultImportance,
      ),
    );
  }

  /// Handler für Notification-Taps
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[Notification] Tapped: ${response.payload}');
    // TODO: Navigation basierend auf Payload
  }

  /// Fragt Berechtigungen an (iOS/Android 13+)
  Future<bool> requestPermissions() async {
    // Android
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Zeigt sofortige Benachrichtigung
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channel = NotificationChannels.general,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channel,
      _getChannelName(channel),
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Plant Benachrichtigung für bestimmten Zeitpunkt
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String channel = NotificationChannels.tripReminders,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channel,
      _getChannelName(channel),
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Wetter-Warnung senden
  Future<void> sendWeatherAlert({
    required String condition,
    required String message,
  }) async {
    await showNotification(
      id: 1000,
      title: '⛈️ Wetterwarnung',
      body: message,
      channel: NotificationChannels.weatherAlerts,
      payload: 'weather:$condition',
    );
  }

  /// Trip-Erinnerung planen
  Future<void> scheduleTripReminder({
    required String tripId,
    required String tripName,
    required DateTime tripStart,
    Duration reminderBefore = const Duration(hours: 1),
  }) async {
    final reminderTime = tripStart.subtract(reminderBefore);

    if (reminderTime.isBefore(DateTime.now())) return;

    await scheduleNotification(
      id: tripId.hashCode,
      title: '🚗 Trip startet bald!',
      body: '$tripName beginnt in ${_formatDuration(reminderBefore)}',
      scheduledDate: reminderTime,
      channel: NotificationChannels.tripReminders,
      payload: 'trip:$tripId',
    );
  }

  /// POI in der Nähe benachrichtigen
  Future<void> notifyNearbyPOI({
    required String poiId,
    required String poiName,
    required String category,
    required double distanceKm,
  }) async {
    await showNotification(
      id: poiId.hashCode,
      title: '📍 $poiName in der Nähe',
      body: 'Nur ${distanceKm.toStringAsFixed(1)} km entfernt - $category',
      channel: NotificationChannels.poiNearby,
      payload: 'poi:$poiId',
    );
  }

  /// Löscht eine geplante Benachrichtigung
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Löscht alle Benachrichtigungen
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Holt alle ausstehenden Benachrichtigungen
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case NotificationChannels.weatherAlerts:
        return 'Wetter-Warnungen';
      case NotificationChannels.tripReminders:
        return 'Trip-Erinnerungen';
      case NotificationChannels.poiNearby:
        return 'POIs in der Nähe';
      default:
        return 'Allgemein';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours >= 1) {
      return '${duration.inHours} Stunde${duration.inHours > 1 ? 'n' : ''}';
    }
    return '${duration.inMinutes} Minuten';
  }
}

/// Notification Service Provider
@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  final service = NotificationService();
  service.initialize();
  return service;
}
