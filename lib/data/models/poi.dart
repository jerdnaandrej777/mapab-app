import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/categories.dart' show POICategory, POIHighlight;
import '../../core/utils/scoring_utils.dart';

part 'poi.freezed.dart';
part 'poi.g.dart';

/// POI (Point of Interest) Datenmodell
/// Übernommen von MapAB POI-Datenstruktur
@freezed
class POI with _$POI {
  const POI._();

  const factory POI({
    /// Eindeutige ID (z.B. 'de-c1')
    required String id,

    /// Name des POI
    required String name,

    /// Breitengrad
    required double latitude,

    /// Längengrad
    required double longitude,

    /// Kategorie-ID (z.B. 'castle', 'nature')
    required String categoryId,

    /// Basis-Score (0-100)
    @Default(50) int score,

    /// Bild-URL (optional)
    String? imageUrl,

    /// Beschreibung (optional)
    String? description,

    /// Ist aus kuratierter Liste
    @Default(false) bool isCurated,

    /// Hat Wikipedia-Artikel
    @Default(false) bool hasWikipedia,

    /// Wikipedia-Artikel-Titel
    String? wikipediaTitle,

    /// Tags (z.B. ['unesco', 'indoor'])
    @Default([]) List<String> tags,

    // === Wikidata-Felder (echte Daten) ===

    /// Wikidata-ID
    String? wikidataId,

    /// Telefonnummer
    String? phone,

    /// E-Mail
    String? email,

    /// Website-URL
    String? website,

    /// Öffnungszeiten (OSM-Format)
    String? openingHours,

    /// Deutsche Beschreibung aus Wikidata
    String? wikidataDescription,

    /// Hat echte Wikidata-Daten
    @Default(false) bool hasWikidataData,

    // === Enrichment-Felder (v1.2.5) ===

    /// Gründungsjahr (aus Wikidata)
    int? foundedYear,

    /// Architekturstil (aus Wikidata)
    String? architectureStyle,

    /// Ist bereits angereichert
    @Default(false) bool isEnriched,

    /// Thumbnail-URL (kleinere Version für Listen)
    String? thumbnailUrl,

    // === Berechnete Routen-Felder ===

    /// Position auf der Route (0 = Start, 1 = Ende)
    double? routePosition,

    /// Umweg in Kilometern
    double? detourKm,

    /// Umweg in Minuten
    int? detourMinutes,

    /// Effektiver Score (nach Umweg-Berechnung)
    double? effectiveScore,
  }) = _POI;

  /// Erstellt POI aus JSON
  factory POI.fromJson(Map<String, dynamic> json) => _$POIFromJson(json);

  /// Koordinaten als LatLng
  LatLng get location => LatLng(latitude, longitude);

  /// Kategorie als Enum
  POICategory? get category => POICategory.fromId(categoryId);

  /// Kategorie-Icon
  String get categoryIcon => category?.icon ?? '📍';

  /// Kategorie-Label
  String get categoryLabel => category?.label ?? categoryId;

  /// Ist UNESCO-Welterbe
  bool get isUnesco => tags.contains('unesco');

  /// Ist Indoor-POI
  bool get isIndoor => category?.isIndoor ?? false;

  /// Ist historischer Ort (älter als 100 Jahre)
  bool get isHistoric {
    if (foundedYear != null && foundedYear! < 1925) return true;
    return tags.contains('historic');
  }

  /// Ist Geheimtipp (niedriger Score aber gute Bewertung)
  bool get isSecret {
    if (tags.contains('secret')) return true;
    return score >= 40 && score <= 60 && !isCurated && !hasWikipedia;
  }

  /// Alle Highlights dieses POIs
  List<POIHighlight> get highlights {
    final result = <POIHighlight>[];
    if (isUnesco) result.add(POIHighlight.unesco);
    if (isMustSee) result.add(POIHighlight.mustSee);
    if (isHistoric) result.add(POIHighlight.historic);
    if (isSecret) result.add(POIHighlight.secret);
    return result;
  }

  /// Hat mindestens ein Highlight
  bool get hasHighlights => highlights.isNotEmpty;

  /// Sterne-Bewertung (1.0 - 5.0)
  double get starRating => ScoringUtils.getStarRating(score);

  /// Simulierte Bewertungsanzahl
  int get reviewCount => ScoringUtils.getReviewCount(
        score: score,
        isCurated: isCurated,
        hasWikipedia: hasWikipedia,
      );

  /// Ist ein Must-See/Highlight
  bool get isMustSee => ScoringUtils.isMustSee(
        score: score,
        reviewCount: reviewCount,
        isCurated: isCurated,
        hasWikipedia: hasWikipedia,
        isUnesco: isUnesco,
      );

  /// Hat verifizierte Kontaktdaten
  bool get hasVerifiedContact =>
      hasWikidataData && (phone != null || email != null || website != null);

  /// Kurze Beschreibung (max 100 Zeichen)
  String get shortDescription {
    final desc = wikidataDescription ?? description ?? '';
    if (desc.length <= 100) return desc;
    return '${desc.substring(0, 97)}...';
  }
}

/// Erweiterung für Listen-Operationen
extension POIListExtensions on List<POI> {
  /// Filtert POIs nach Kategorie
  List<POI> filterByCategory(POICategory category) {
    return where((poi) => poi.categoryId == category.id).toList();
  }

  /// Filtert POIs nach maximalem Umweg
  List<POI> filterByMaxDetour(double maxDetourKm) {
    return where((poi) =>
        poi.detourKm == null || poi.detourKm! <= maxDetourKm).toList();
  }

  /// Filtert nur Must-See POIs
  List<POI> get mustSeeOnly {
    return where((poi) => poi.isMustSee).toList();
  }

  /// Filtert nur Indoor-POIs
  List<POI> get indoorOnly {
    return where((poi) => poi.isIndoor).toList();
  }

  /// Sortiert nach effektivem Score (absteigend)
  List<POI> sortByEffectiveScore() {
    final sorted = List<POI>.from(this);
    sorted.sort((a, b) =>
        (b.effectiveScore ?? b.score.toDouble())
            .compareTo(a.effectiveScore ?? a.score.toDouble()));
    return sorted;
  }

  /// Sortiert nach Umweg (aufsteigend)
  List<POI> sortByDetour() {
    final sorted = List<POI>.from(this);
    sorted.sort((a, b) =>
        (a.detourKm ?? double.infinity)
            .compareTo(b.detourKm ?? double.infinity));
    return sorted;
  }

  /// Sortiert nach Routen-Position
  List<POI> sortByRoutePosition() {
    final sorted = List<POI>.from(this);
    sorted.sort((a, b) =>
        (a.routePosition ?? 0).compareTo(b.routePosition ?? 0));
    return sorted;
  }
}
