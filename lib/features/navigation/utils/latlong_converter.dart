import 'package:latlong2/latlong.dart' as ll2;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

/// Konvertiert zwischen latlong2.LatLng (Provider/Models)
/// und maplibre_gl.LatLng (Map-Widget).
class LatLngConverter {
  const LatLngConverter._();

  /// latlong2 -> maplibre_gl
  static ml.LatLng toMapLibre(ll2.LatLng pos) {
    return ml.LatLng(pos.latitude, pos.longitude);
  }

  /// maplibre_gl -> latlong2
  static ll2.LatLng toLatLong2(ml.LatLng pos) {
    return ll2.LatLng(pos.latitude, pos.longitude);
  }

  /// Erstellt ein GeoJSON FeatureCollection mit einer LineString-Geometry.
  /// GeoJSON nutzt [longitude, latitude] Reihenfolge (RFC 7946).
  static Map<String, dynamic> toGeoJsonLine(List<ll2.LatLng> coords) {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': coords
                .map((c) => [c.longitude, c.latitude])
                .toList(),
          },
          'properties': <String, dynamic>{},
        },
      ],
    };
  }

  /// Leere GeoJSON FeatureCollection (fuer Initialisierung).
  static Map<String, dynamic> get emptyGeoJson => {
        'type': 'FeatureCollection',
        'features': <Map<String, dynamic>>[],
      };

  /// Berechnet LatLngBounds aus einer Liste von latlong2-Koordinaten.
  static ml.LatLngBounds boundsFromCoords(List<ll2.LatLng> coords) {
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final c in coords) {
      if (c.latitude < minLat) minLat = c.latitude;
      if (c.latitude > maxLat) maxLat = c.latitude;
      if (c.longitude < minLng) minLng = c.longitude;
      if (c.longitude > maxLng) maxLng = c.longitude;
    }
    return ml.LatLngBounds(
      southwest: ml.LatLng(minLat, minLng),
      northeast: ml.LatLng(maxLat, maxLng),
    );
  }
}
