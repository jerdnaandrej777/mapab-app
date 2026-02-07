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

    /// Optionaler Zielpunkt (wenn leer → Rundreise/Random)
    LatLng? destinationLocation,

    /// Optionale Zieladresse (für Anzeige)
    String? destinationAddress,

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

    /// POI-ID die gerade geladen wird (für individuelle Loading-Anzeigen)
    String? loadingPOIId,

    /// v1.10.23: Aktuelle Generierungs-Phase (für Fortschrittsanzeige)
    @Default(GenerationPhase.idle) GenerationPhase generationPhase,

    /// v1.10.23: Generierungs-Fortschritt (0.0 - 1.0)
    @Default(0.0) double generationProgress,

    /// Fehler-Nachricht
    String? error,

    /// Aktuell ausgewählter Tag (1-basiert) für tagesweisen Export
    @Default(1) int selectedDay,

    /// Bereits exportierte/abgeschlossene Tage
    @Default({}) Set<int> completedDays,

    /// Wetter-Kategorien wurden angewendet (v1.7.8)
    @Default(false) bool weatherCategoriesApplied,
  }) = _RandomTripState;

  /// Hat gültigen Startpunkt
  bool get hasValidStart => startLocation != null && startAddress != null;

  /// Hat ein Ziel gesetzt (kein Rundreise-Modus)
  bool get hasDestination => destinationLocation != null;

  /// Ist Rundreise (kein Ziel gesetzt)
  bool get isRoundTrip => !hasDestination;

  /// Kann generieren (Startpunkt ist optional - wird automatisch per GPS ermittelt)
  bool get canGenerate => !isLoading;

  /// Hat generierten Trip
  bool get hasTrip => generatedTrip != null;

  /// Ist Mehrtages-Trip
  bool get isMultiDay => mode == RandomTripMode.eurotrip && days > 1;

  /// Anzahl ausgewählter Kategorien
  int get selectedCategoryCount => selectedCategories.length;

  /// Formatierter Radius
  String get formattedRadius => '${radiusKm.round()} km';

  /// Kann POIs entfernen (mindestens 3 POIs vorhanden)
  bool get canRemovePOI =>
      generatedTrip != null && generatedTrip!.selectedPOIs.length > 2;

  /// Prüft ob ein bestimmter POI gerade geladen wird
  bool isPOILoading(String poiId) => loadingPOIId == poiId;

  /// Anzahl der Tage im generierten Trip
  int get tripDays => generatedTrip?.trip.actualDays ?? 1;

  /// Prüft ob ein Tag abgeschlossen/exportiert wurde
  bool isDayCompleted(int dayNumber) => completedDays.contains(dayNumber);

  /// Stops für den ausgewählten Tag
  List<TripStop> get stopsForSelectedDay =>
      generatedTrip?.trip.getStopsForDay(selectedDay) ?? [];

  /// Anzahl Stops für den ausgewählten Tag
  int get stopsCountForSelectedDay => stopsForSelectedDay.length;

  /// Prüft ob der ausgewählte Tag das Google Maps Limit überschreitet
  bool get selectedDayOverLimit => stopsCountForSelectedDay > 9;

  /// Anzahl Tage (für Euro Trip direkt aus State, für Tagestrip immer 1)
  int get calculatedDays => mode == RandomTripMode.eurotrip ? days : 1;

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
  /// AI Tagesausflug (1 Tag)
  daytrip('AI Tagesausflug', '\u{1F916}'),

  /// AI Euro Trip (mehrere Tage)
  eurotrip('AI Euro Trip', '\u{2708}\u{FE0F}');

  final String label;
  final String icon;

  const RandomTripMode(this.label, this.icon);
}

/// v1.10.23: Generierungs-Phasen für Fortschrittsanzeige
enum GenerationPhase {
  /// Nicht aktiv
  idle('\u{23F8}\u{FE0F}', 0.0),

  /// Route wird berechnet (OSRM)
  calculatingRoute('\u{1F5FA}\u{FE0F}', 0.15),

  /// POIs werden gesucht (Supabase/Wikipedia/Overpass)
  searchingPOIs('\u{1F50D}', 0.40),

  /// POIs werden mit AI bewertet
  rankingWithAI('\u{1F916}', 0.70),

  /// Bilder werden geladen (Wikimedia)
  enrichingImages('\u{1F5BC}\u{FE0F}', 0.90),

  /// Abgeschlossen
  complete('\u{2705}', 1.0);

  final String emoji;
  final double baseProgress;

  const GenerationPhase(this.emoji, this.baseProgress);

  /// Lokalisierte Beschreibung
  String getLocalizedMessage(String languageCode) {
    switch (this) {
      case GenerationPhase.idle:
        return '';
      case GenerationPhase.calculatingRoute:
        switch (languageCode) {
          case 'en':
            return 'Calculating route...';
          case 'fr':
            return 'Calcul de l\'itinéraire...';
          case 'it':
            return 'Calcolo del percorso...';
          case 'es':
            return 'Calculando ruta...';
          default:
            return 'Berechne Route...';
        }
      case GenerationPhase.searchingPOIs:
        switch (languageCode) {
          case 'en':
            return 'Searching points of interest...';
          case 'fr':
            return 'Recherche de points d\'intérêt...';
          case 'it':
            return 'Ricerca punti di interesse...';
          case 'es':
            return 'Buscando puntos de interés...';
          default:
            return 'Suche Sehenswürdigkeiten...';
        }
      case GenerationPhase.rankingWithAI:
        switch (languageCode) {
          case 'en':
            return 'AI is optimizing your trip...';
          case 'fr':
            return 'L\'IA optimise votre voyage...';
          case 'it':
            return 'L\'IA sta ottimizzando il viaggio...';
          case 'es':
            return 'La IA optimiza tu viaje...';
          default:
            return 'AI optimiert deinen Trip...';
        }
      case GenerationPhase.enrichingImages:
        switch (languageCode) {
          case 'en':
            return 'Loading images...';
          case 'fr':
            return 'Chargement des images...';
          case 'it':
            return 'Caricamento immagini...';
          case 'es':
            return 'Cargando imágenes...';
          default:
            return 'Lade Bilder...';
        }
      case GenerationPhase.complete:
        switch (languageCode) {
          case 'en':
            return 'Done!';
          case 'fr':
            return 'Terminé!';
          case 'it':
            return 'Completato!';
          case 'es':
            return 'Listo!';
          default:
            return 'Fertig!';
        }
    }
  }
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
