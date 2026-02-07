/// Konstanten für Trip-Generierung und -Planung
class TripConstants {
  TripConstants._();

  /// Maximale Anzahl POIs pro Tag (Google Maps Waypoint Limit = 9)
  static const int maxPoisPerDay = 9;

  /// Kilometer pro Reisetag (Basis für Tagesberechnung)
  static const double kmPerDay = 600.0;

  /// Minimale Anzahl Reisetage
  static const int minDays = 1;

  /// Maximale Anzahl Reisetage
  static const int maxDays = 14;

  /// Minimale Anzahl POIs pro Tag
  static const int minPoisPerDay = 2;

  /// Berechnet die Anzahl der Tage basierend auf der Distanz
  static int calculateDaysFromDistance(double totalDistanceKm) {
    return (totalDistanceKm / kmPerDay).ceil().clamp(minDays, maxDays);
  }

  /// Berechnet den empfohlenen Radius basierend auf der Tagesanzahl
  static double calculateRadiusFromDays(int days) {
    return days * kmPerDay;
  }

  /// Quick-Select Werte für Euro Trip Tage
  static const List<int> euroTripQuickSelectDays = [2, 4, 7, 10];

  /// Minimale Anzahl Tage für Euro Trip
  static const int euroTripMinDays = 1;

  /// Maximale Anzahl Tage für Euro Trip
  static const int euroTripMaxDays = 14;

  /// Default-Tage für Euro Trip
  static const int euroTripDefaultDays = 3;

  /// Quick-Select Werte für Tagesausflug Radius (in km)
  static const List<double> dayTripQuickSelectRadii = [50, 100, 200, 300];

  /// Minimale Fahrdistanz pro Tag in km (Haversine)
  /// Entspricht ca. 200km echte Fahrtstrecke (Faktor ~1.3)
  static const double minKmPerDay = 150.0;

  /// Maximale Fahrdistanz pro Tag in km (Haversine)
  /// Entspricht ca. 650-700km echte Fahrtstrecke (Faktor ~1.3)
  static const double maxKmPerDay = 500.0;

  /// Ideale Fahrdistanz pro Tag in km (Haversine)
  /// Mitte des Zielbereichs
  static const double idealKmPerDay = 350.0;

  /// Faktor Haversine → geschaetzte reale Fahrstrecke
  static const double haversineToDisplayFactor = 1.35;

  /// Absolutes Maximum angezeigte Distanz pro Tag in km
  /// Anzeige-Distanz = Haversine × haversineToDisplayFactor
  /// 700km ist die absolute Obergrenze pro Reisetag
  static const double maxDisplayKmPerDay = 700.0;

  /// Maximale Haversine-Distanz pro Tag, die das Display-Limit einhält
  /// 700 / 1.35 ≈ 518.5km Haversine
  static double get maxHaversineKmForDisplay =>
      maxDisplayKmPerDay / haversineToDisplayFactor;

  /// Konvertiert Haversine-km in angezeigte Fahr-km.
  static double toDisplayKm(double haversineKm) {
    return haversineKm * haversineToDisplayFactor;
  }

  /// Konvertiert angezeigte Fahr-km zur Haversine-Naeherung.
  static double toHaversineKm(double displayKm) {
    return displayKm / haversineToDisplayFactor;
  }

  /// Prueft, ob eine Display-Distanz das Tageslimit ueberschreitet.
  static bool isDisplayOverDayLimit(double displayKm) {
    return displayKm > maxDisplayKmPerDay;
  }
}
