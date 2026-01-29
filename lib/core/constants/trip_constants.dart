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

  /// Quick-Select Werte für Euro Trip Radius (in km)
  /// Jeder Wert entspricht 1, 2, 4 bzw. 7 Tagen
  static const List<double> euroTripQuickSelectRadii = [600, 1200, 2400, 4200];

  /// Quick-Select Werte für Tagesausflug Radius (in km)
  static const List<double> dayTripQuickSelectRadii = [50, 100, 200, 300];
}
