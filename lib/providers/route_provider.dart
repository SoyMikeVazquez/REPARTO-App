import 'package:flutter/material.dart';
import '../models/route_stop_model.dart';
import '../core/network/api_service.dart';
import '../core/network/mock_data.dart';
import '../core/services/location_service.dart';

class RouteProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<RouteStopModel> _stops = [];
  bool _isLoading = false;
  int _activeStopIndex = 1; // 0 is pickup, 1 is next stop

  // Simulated GPS courier position
  double _courierLat = 19.4180;
  double _courierLng = -99.1605;

  List<RouteStopModel> get stops => _stops;
  bool get isLoading => _isLoading;
  int get activeStopIndex => _activeStopIndex;
  double get courierLat => _courierLat;
  double get courierLng => _courierLng;

  RouteStopModel? get currentStop {
    if (_stops.isEmpty) return null;
    final pending = _stops.where((s) => !s.isCompleted).toList();
    return pending.isNotEmpty ? pending.first : null;
  }

  double get remainingDistanceKm {
    return _stops
        .where((s) => !s.isCompleted)
        .fold(0.0, (acc, stop) => acc + stop.distanceKm);
  }

  int get remainingMinutes {
    return LocationService.estimateTravelMinutes(remainingDistanceKm);
  }

  RouteProvider() {
    fetchActiveRoute();
  }

  Future<void> fetchActiveRoute() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stops = await _apiService.getActiveRouteStops();
    } catch (_) {
      _stops = MockData.mockActiveRouteStops;
    }

    _isLoading = false;
    notifyListeners();
  }

  void completeStop(int sequenceIndex) {
    final index = _stops.indexWhere((s) => s.sequenceIndex == sequenceIndex);
    if (index != -1) {
      _stops[index] = _stops[index].copyWith(isCompleted: true);

      // Mueve la posición del repartidor hacia el waypoint completado
      _courierLat = _stops[index].lat;
      _courierLng = _stops[index].lng;

      if (_activeStopIndex < _stops.length - 1) {
        _activeStopIndex++;
      }
      notifyListeners();
    }
  }

  /// Simula el avance en el mapa de navegación
  void simulateGpsStep() {
    final current = currentStop;
    if (current == null) return;

    // Acercar 20% la posición actual a la parada destino
    _courierLat += (current.lat - _courierLat) * 0.25;
    _courierLng += (current.lng - _courierLng) * 0.25;
    notifyListeners();
  }
}
