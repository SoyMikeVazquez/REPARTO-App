import 'dart:math' as math;

class LocationService {
  /// Calcula la distancia entre dos puntos (lat1, lon1) y (lat2, lon2) usando la fórmula Haversine en Km.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Calcula el tiempo estimado en minutos asumiendo velocidad promedio de moto en ciudad (25 km/h)
  static int estimateTravelMinutes(double distanceKm) {
    final double hours = distanceKm / 25.0;
    final int minutes = (hours * 60).round();
    return minutes < 3 ? 3 : minutes;
  }

  /// Formateo amigable de distancia
  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}
