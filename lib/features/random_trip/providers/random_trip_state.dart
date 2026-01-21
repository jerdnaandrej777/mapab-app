import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/trip.dart';
import '../../../data/repositories/trip_generator_repo.dart';
import '../../../data/services/hotel_service.dart';

part 'random_trip_state.freezed.dart';

/// State für den Random Trip Screen
@freezed
class RandomTripState with _$RandomTripState {
  const RandomTripState._();

  const factory RandomTripState({
    /// Aktueller Schritt im Flow
    @Default(RandomTripStep.config) RandomTripStep step,

    /// Typ des Trips (Tagesausflug oder Euro Trip)
    @Default(RandomTripMode.daytrip) RandomTripMode mode,

    /// Startpunkt (GPS oder manuell)
    LatLng? startLocation,

    /// Start-Adresse (für Anzeige)
    String? startAddress,

    /// Verwendet GPS-Position
    @Default(false) bool useGPS,

    /// Ausgewählte Kategorien
    @Default([]) List<POICategory> selectedCategories,

    /// Such-Radius in km
    @Default(100) double radiusKm,

    /// Anzahl der Tage (für Euro Trip)
    @Default(1) int days,

    /// Hotels vorschlagen (für Euro Trip)
    @Default(true) bool includeHotels,

    /// Generierter Trip
    GeneratedTrip? generatedTrip,

    /// Hotel-Vorschläge pro Tag
    @Default([]) List<List<HotelSuggestion>> hotelSuggestions,

    /// Ausgewählte Hotels pro Tag
    @Default({}) Map<int, HotelSuggestion> selectedHotels,

    /// Lädt gerade
    @Default(false) bool isLoading,

    /// Fehler-Nachricht
    String? error,
  }) = _RandomTripState;

  /// Hat gültigen Startpunkt
  bool get hasValidStart => startLocation != null && startAddress != null;

  /// Kann generieren
  bool get canGenerate => hasValidStart && !isLoading;

  /// Hat generierten Trip
  bool get hasTrip => generatedTrip != null;

  /// Ist Mehrtages-Trip
  bool get isMultiDay => mode == RandomTripMode.eurotrip && days > 1;

  /// Anzahl ausgewählter Kategorien
  int get selectedCategoryCount => selectedCategories.length;

  /// Formatierter Radius
  String get formattedRadius => '${radiusKm.round()} km';

  /// Trip-Statistiken
  String? get tripStats {
    final trip = generatedTrip?.trip;
    if (trip == null) return null;

    final stops = trip.stopCount;
    final distance = trip.route.formattedDistance;
    final duration = trip.formattedTotalDuration;

    return '$stops Stops • $distance • $duration';
  }
}

/// Schritte im Random Trip Flow
enum RandomTripStep {
  /// Konfiguration (Start, Radius, Kategorien)
  config,

  /// Trip wird generiert
  generating,

  /// Vorschau des generierten Trips
  preview,

  /// Trip bestätigt/gespeichert
  confirmed,
}

/// Trip-Modus
enum RandomTripMode {
  /// Tagesausflug (1 Tag)
  daytrip('Tagesausflug', '🚗'),

  /// Euro Trip (mehrere Tage)
  eurotrip('Euro Trip', '✈️');

  final String label;
  final String icon;

  const RandomTripMode(this.label, this.icon);
}

/// Konfiguration für Trip-Generierung
class TripConfig {
  final LatLng startLocation;
  final String startAddress;
  final double radiusKm;
  final List<POICategory> categories;
  final int days;
  final bool includeHotels;

  TripConfig({
    required this.startLocation,
    required this.startAddress,
    required this.radiusKm,
    this.categories = const [],
    this.days = 1,
    this.includeHotels = true,
  });

  /// Ist Tagesausflug
  bool get isDayTrip => days == 1;

  /// Ist Euro Trip
  bool get isEuroTrip => days > 1;

  /// Empfohlene POI-Anzahl basierend auf Radius und Tagen
  int get recommendedPOICount {
    if (isDayTrip) {
      return (radiusKm / 20).clamp(3, 8).round();
    }
    return (days * 4).clamp(4, 20);
  }
}
