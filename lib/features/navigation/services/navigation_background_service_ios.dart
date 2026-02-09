import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'navigation_background_service.dart';

class IOSNavigationPermissionBridge {
  IOSNavigationPermissionBridge._();

  static const MethodChannel _channel =
      MethodChannel('mapab/navigation_background');

  static Future<bool> requestAlwaysPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestAlwaysPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('[BackgroundService/iOS] requestAlwaysPermission error: $e');
      return false;
    }
  }
}

class IOSNavigationBackgroundService implements NavigationBackgroundService {
  IOSNavigationBackgroundService._();

  static final IOSNavigationBackgroundService instance =
      IOSNavigationBackgroundService._();

  static const MethodChannel _methodChannel =
      MethodChannel('mapab/navigation_background');
  static const EventChannel _eventChannel =
      EventChannel('mapab/navigation_background/events');

  final Set<NavigationBackgroundDataCallback> _callbacks = {};
  StreamSubscription<dynamic>? _eventSub;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _methodChannel.invokeMethod<void>('initialize');
      _initialized = true;
      _ensureEventSubscription();
      debugPrint('[BackgroundService/iOS] initialized');
    } catch (e) {
      debugPrint('[BackgroundService/iOS] initialize error: $e');
    }
  }

  @override
  Future<bool> start({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    await initialize();
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'start',
        <String, dynamic>{
          'destinationName': destinationName,
          'distanceKm': distanceKm,
          'etaMinutes': etaMinutes,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('[BackgroundService/iOS] start error: $e');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod<void>('stop');
    } catch (e) {
      debugPrint('[BackgroundService/iOS] stop error: $e');
    }
  }

  @override
  Future<void> update({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    try {
      await _methodChannel.invokeMethod<void>(
        'update',
        <String, dynamic>{
          'destinationName': destinationName,
          'distanceKm': distanceKm,
          'etaMinutes': etaMinutes,
        },
      );
    } catch (e) {
      debugPrint('[BackgroundService/iOS] update error: $e');
    }
  }

  @override
  Future<bool> isRunning() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isRunning');
      return result ?? false;
    } catch (e) {
      debugPrint('[BackgroundService/iOS] isRunning error: $e');
      return false;
    }
  }

  @override
  void setDataCallback(NavigationBackgroundDataCallback callback) {
    _callbacks.add(callback);
    _ensureEventSubscription();
  }

  @override
  void removeDataCallback(NavigationBackgroundDataCallback callback) {
    _callbacks.remove(callback);
    if (_callbacks.isEmpty) {
      _eventSub?.cancel();
      _eventSub = null;
    }
  }

  void _ensureEventSubscription() {
    if (_eventSub != null || _callbacks.isEmpty) return;

    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        for (final callback in _callbacks) {
          callback(event as Object);
        }
      },
      onError: (Object error) {
        final payload = <String, dynamic>{
          'type': 'error',
          'message': error.toString(),
        };
        for (final callback in _callbacks) {
          callback(payload);
        }
      },
    );
  }
}
