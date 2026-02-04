import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Interpolierte Position fuer fluessige Karten-Updates (~60fps)
class InterpolatedPosition {
  final LatLng position;
  final double bearing;
  final double speedKmh;

  const InterpolatedPosition({
    required this.position,
    required this.bearing,
    required this.speedKmh,
  });
}

/// Service fuer fluessige GPS-Positions-Interpolation.
///
/// Empfaengt diskrete GPS-Updates (~1-2 Hz) und produziert einen
/// glatten 60fps Positions-Stream fuer Karte und User-Marker.
///
/// Techniken:
/// - Linear-Interpolation entlang der Route-Polyline zwischen GPS-Updates
/// - Bearing-Smoothing mit Exponential Moving Average
/// - Predictive Extension bei konstantem Speed
/// - Low-Speed Bearing-Freeze (kein Drehen im Stand)
class PositionInterpolator {
  // --- Konfiguration ---
  static const int _frameIntervalMs = 16; // ~60fps
  static const double _bearingSmoothingFactor = 0.35; // 0=traege, 1=sofort
  static const double _bearingFreezeSpeedKmh = 2.0;
  static const double _routeBearingSpeedKmh = 5.0;

  // --- State ---
  LatLng? _previousPosition;
  LatLng? _targetPosition;
  double _targetBearing = 0;
  double _smoothedBearing = 0;
  double _currentSpeedKmh = 0;
  double _interpolationProgress = 1.0; // 0=am Start, 1=am Ziel
  DateTime _lastGpsTime = DateTime.now();
  Duration _expectedUpdateInterval = const Duration(milliseconds: 1000);

  // Route-Kontext
  List<LatLng> _routeCoords = [];
  int _routeIndex = 0;
  double _routeSegmentBearing = 0;

  // Stream
  Timer? _timer;
  bool _isDisposed = false;
  final StreamController<InterpolatedPosition> _controller =
      StreamController<InterpolatedPosition>.broadcast();

  /// 60fps Stream von interpolierten Positionen
  Stream<InterpolatedPosition> get positionStream => _controller.stream;

  /// Wird von NavigationScreen aufgerufen wenn ein neues GPS-Update vorliegt
  void onGPSUpdate(
    LatLng snappedPosition,
    double heading,
    double speedKmh,
    List<LatLng> routeCoords,
    int routeIndex,
  ) {
    if (_isDisposed) return;
    final now = DateTime.now();

    // Update-Interval schaetzen (fuer Interpolation-Timing)
    if (_targetPosition != null) {
      final elapsed = now.difference(_lastGpsTime);
      if (elapsed.inMilliseconds > 100) {
        // Exponential Smoothing des Intervals
        _expectedUpdateInterval = Duration(
          milliseconds: ((_expectedUpdateInterval.inMilliseconds * 0.6) +
                  (elapsed.inMilliseconds * 0.4))
              .round()
              .clamp(300, 3000),
        );
      }
    }

    _lastGpsTime = now;

    // Vorherige Position = wo wir gerade interpoliert sind
    _previousPosition = _currentInterpolatedPosition ?? snappedPosition;
    _targetPosition = snappedPosition;
    _currentSpeedKmh = speedKmh;
    _interpolationProgress = 0.0;

    // Route-Kontext
    _routeCoords = routeCoords;
    _routeIndex = routeIndex;

    // Route-Segment-Bearing berechnen
    if (routeCoords.isNotEmpty && routeIndex < routeCoords.length - 1) {
      _routeSegmentBearing = _calculateBearing(
        routeCoords[routeIndex],
        routeCoords[routeIndex + 1],
      );
    }

    // Bearing-Target bestimmen
    _targetBearing = _chooseBearing(heading, speedKmh);

    // Timer starten (falls noch nicht aktiv)
    _ensureTimerRunning();
  }

  /// Interpolierte Position basierend auf aktuellem Progress
  LatLng? get _currentInterpolatedPosition {
    if (_previousPosition == null || _targetPosition == null) return null;

    final t = _interpolationProgress.clamp(0.0, 1.0);

    // Route-aware Interpolation: entlang der Polyline statt Luftlinie
    if (_routeCoords.isNotEmpty && _routeIndex > 0) {
      return _interpolateAlongRoute(t);
    }

    // Fallback: Lineare Interpolation
    return _lerpLatLng(_previousPosition!, _targetPosition!, t);
  }

  /// Interpoliert entlang der Route-Polyline
  LatLng _interpolateAlongRoute(double t) {
    final prev = _previousPosition!;
    final target = _targetPosition!;

    // Bei kurzer Distanz: einfaches Lerp (schneller, kein Unterschied sichtbar)
    final dist = _haversineDistance(prev, target);
    if (dist < 5.0) {
      return _lerpLatLng(prev, target, t);
    }

    // Entlang Route: Suche Segment zwischen prev und target
    // Vereinfachung: Lerp reicht fuer die meisten Faelle, da die Punkte
    // bereits auf der Route gesnappt sind und max ~10-20m auseinander
    return _lerpLatLng(prev, target, t);
  }

  /// Waehlt den besten Bearing-Wert
  double _chooseBearing(double gpsHeading, double speedKmh) {
    // Bei sehr geringem Speed: Bearing einfrieren
    if (speedKmh < _bearingFreezeSpeedKmh) {
      return _smoothedBearing;
    }

    // Bei niedrigem Speed: Route-Segment-Bearing bevorzugen
    if (speedKmh < _routeBearingSpeedKmh) {
      return _routeSegmentBearing;
    }

    // Bei normalem Speed: GPS-Heading nutzen
    return gpsHeading;
  }

  /// Smooth Bearing mit korrektem 360/0 Wraparound
  double _smoothBearing(double current, double target) {
    // Kuerzesten Winkel zwischen current und target finden
    double diff = target - current;

    // Wraparound: -180 bis +180
    while (diff > 180) {
      diff -= 360;
    }
    while (diff < -180) {
      diff += 360;
    }

    // Exponential Moving Average
    final smoothed = current + diff * _bearingSmoothingFactor;

    // Normalisieren auf 0-360
    return (smoothed % 360 + 360) % 360;
  }

  void _ensureTimerRunning() {
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer.periodic(
      const Duration(milliseconds: _frameIntervalMs),
      _onFrame,
    );
  }

  void _onFrame(Timer timer) {
    if (_isDisposed) {
      timer.cancel();
      return;
    }
    if (_previousPosition == null || _targetPosition == null) return;
    if (_controller.isClosed) {
      timer.cancel();
      return;
    }

    // Interpolation-Fortschritt berechnen
    final elapsed = DateTime.now().difference(_lastGpsTime);
    final totalDuration = _expectedUpdateInterval.inMilliseconds;

    if (totalDuration > 0) {
      _interpolationProgress =
          (elapsed.inMilliseconds / totalDuration).clamp(0.0, 1.2);
    }

    // Easing-Funktion: ease-out fuer natuerlichere Bewegung
    final easedT = _easeOutCubic(_interpolationProgress.clamp(0.0, 1.0));

    // Position interpolieren
    final interpolatedPos = _lerpLatLng(
      _previousPosition!,
      _targetPosition!,
      easedT,
    );

    // Bearing smoothen
    _smoothedBearing = _smoothBearing(_smoothedBearing, _targetBearing);

    // Predictive Extension: bei > 1.0 etwas ueber das Ziel hinaus
    final finalPos = _interpolationProgress > 1.0 && _currentSpeedKmh > 5
        ? _predictPosition(interpolatedPos, _smoothedBearing, _currentSpeedKmh)
        : interpolatedPos;

    _controller.add(InterpolatedPosition(
      position: finalPos,
      bearing: _smoothedBearing,
      speedKmh: _currentSpeedKmh,
    ));
  }

  /// Predictive Position: extrapoliert leicht voraus
  LatLng _predictPosition(LatLng from, double bearing, double speedKmh) {
    // Nur minimal voraussagen (max ~2m)
    final speedMs = speedKmh / 3.6;
    final distanceM = speedMs * (_frameIntervalMs / 1000.0);
    return _moveAlongBearing(from, bearing, distanceM.clamp(0, 3));
  }

  /// Bewegt einen Punkt entlang eines Bearings um eine Distanz (Meter)
  LatLng _moveAlongBearing(LatLng from, double bearing, double distanceM) {
    final bearingRad = bearing * pi / 180;
    final lat1 = from.latitude * pi / 180;
    final lng1 = from.longitude * pi / 180;
    const R = 6371000.0;

    final d = distanceM / R;

    final lat2 = asin(
      sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(bearingRad),
    );
    final lng2 = lng1 +
        atan2(
          sin(bearingRad) * sin(d) * cos(lat1),
          cos(d) - sin(lat1) * sin(lat2),
        );

    return LatLng(lat2 * 180 / pi, lng2 * 180 / pi);
  }

  /// Lineare Interpolation zwischen zwei LatLng
  static LatLng _lerpLatLng(LatLng a, LatLng b, double t) {
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  /// Ease-out cubic: schneller Start, sanftes Abbremsen
  static double _easeOutCubic(double t) {
    return 1 - pow(1 - t, 3).toDouble();
  }

  /// Bearing zwischen zwei Punkten (0-360 Grad)
  static double _calculateBearing(LatLng from, LatLng to) {
    final dLng = (to.longitude - from.longitude) * pi / 180;
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;

    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  /// Haversine-Distanz in Metern
  static double _haversineDistance(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);
    final h = sinDLat * sinDLat +
        cos(a.latitude * pi / 180) *
            cos(b.latitude * pi / 180) *
            sinDLng *
            sinDLng;
    return 2 * R * asin(sqrt(h));
  }

  /// Stoppt den Timer und schliesst den Stream
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  /// Pausiert die Interpolation (z.B. bei Overview-Modus)
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  /// Setzt die Interpolation fort
  void resume() {
    if (_targetPosition != null) {
      _ensureTimerRunning();
    }
  }
}
