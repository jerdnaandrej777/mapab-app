import 'package:freezed_annotation/freezed_annotation.dart';

part 'cost.freezed.dart';
part 'cost.g.dart';

/// Fahrzeugtyp für Spritkosten-Berechnung
enum VehicleType {
  petrolSmall('Benzin (Klein)', 6.5, 0),
  petrolMedium('Benzin (Mittel)', 7.5, 0),
  petrolLarge('Benzin (Groß)', 9.5, 0),
  dieselSmall('Diesel (Klein)', 5.5, 0),
  dieselMedium('Diesel (Mittel)', 6.5, 0),
  dieselLarge('Diesel (Groß)', 8.0, 0),
  electricSmall('Elektro (Klein)', 0, 15),
  electricMedium('Elektro (Mittel)', 0, 18),
  electricLarge('Elektro (Groß)', 0, 22),
  hybrid('Hybrid', 5.0, 5);

  final String label;
  final double fuelConsumptionL100km;
  final double electricConsumptionKwh100km;

  const VehicleType(this.label, this.fuelConsumptionL100km, this.electricConsumptionKwh100km);

  bool get isElectric => electricConsumptionKwh100km > 0 && fuelConsumptionL100km == 0;
  bool get isHybrid => electricConsumptionKwh100km > 0 && fuelConsumptionL100km > 0;
}

/// Kraftstofftyp
enum FuelType {
  e5('Super E5', 1.75),
  e10('Super E10', 1.70),
  diesel('Diesel', 1.65),
  electricity('Strom', 0.35);  // kWh

  final String label;
  final double defaultPricePerUnit;
  const FuelType(this.label, this.defaultPricePerUnit);
}

/// Kosten-Kategorie
enum CostCategory {
  fuel('Kraftstoff', '⛽'),
  toll('Maut', '🛣️'),
  parking('Parken', '🅿️'),
  admission('Eintritt', '🎫'),
  food('Essen', '🍽️'),
  accommodation('Übernachtung', '🏨'),
  other('Sonstiges', '📝');

  final String label;
  final String emoji;
  const CostCategory(this.label, this.emoji);
}

/// Einzelner Kosteneintrag
@freezed
class CostEntry with _$CostEntry {
  const factory CostEntry({
    required String id,
    required CostCategory category,
    required double amount,
    required String currency,
    String? description,
    String? poiId,
    DateTime? timestamp,
    @Default(false) bool isEstimate,
  }) = _CostEntry;

  factory CostEntry.fromJson(Map<String, dynamic> json) =>
      _$CostEntryFromJson(json);
}

/// Trip-Kosten-Übersicht
@freezed
class TripCosts with _$TripCosts {
  const factory TripCosts({
    required String tripId,
    @Default([]) List<CostEntry> entries,
    @Default(0) double estimatedFuelCost,
    @Default(0) double estimatedTollCost,
    @Default(0) double estimatedParkingCost,
    @Default(0) double estimatedAdmissionCost,
    @Default(0) double estimatedFoodCost,
    @Default(0) double estimatedAccommodationCost,
    VehicleType? vehicleType,
    double? customFuelPrice,
    DateTime? lastUpdated,
  }) = _TripCosts;

  const TripCosts._();

  /// Gesamte geschätzte Kosten
  double get totalEstimated =>
      estimatedFuelCost +
      estimatedTollCost +
      estimatedParkingCost +
      estimatedAdmissionCost +
      estimatedFoodCost +
      estimatedAccommodationCost;

  /// Tatsächliche Kosten (aus Einträgen)
  double get totalActual =>
      entries.fold(0.0, (sum, e) => sum + e.amount);

  /// Differenz zwischen Schätzung und Tatsächlich
  double get difference => totalActual - totalEstimated;

  /// Kosten pro Kategorie
  Map<CostCategory, double> get costsByCategory {
    final result = <CostCategory, double>{};
    for (final entry in entries) {
      result[entry.category] = (result[entry.category] ?? 0) + entry.amount;
    }
    return result;
  }

  /// Formatierte Gesamtkosten
  String get formattedTotal => '${totalEstimated.toStringAsFixed(2)} €';

  factory TripCosts.fromJson(Map<String, dynamic> json) =>
      _$TripCostsFromJson(json);
}

/// Kraftstoffpreis-Daten
@freezed
class FuelPrice with _$FuelPrice {
  const factory FuelPrice({
    required String stationId,
    required String stationName,
    required double latitude,
    required double longitude,
    required double e5Price,
    required double e10Price,
    required double dieselPrice,
    required bool isOpen,
    String? brand,
    String? address,
    DateTime? lastUpdated,
  }) = _FuelPrice;

  factory FuelPrice.fromJson(Map<String, dynamic> json) =>
      _$FuelPriceFromJson(json);
}
