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
}
