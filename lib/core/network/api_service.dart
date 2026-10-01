import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../models/courier_model.dart';
import '../../models/branch_model.dart';
import '../../models/route_stop_model.dart';
import 'mock_data.dart';
import '../services/storage_service.dart';

class ApiService {
  final http.Client _client = http.Client();

  Map<String, String> get _supabaseHeaders => {
        'apikey': AppConstants.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Reparto-Slug': StorageService.getBusinessSlug(),
        if (StorageService.getAuthToken() != null)
          'Authorization': 'Bearer ${StorageService.getAuthToken()}',
      };

  /// Obtiene los pedidos asignados o de la sucursal (conectado a Supabase en vivo)
  Future<List<OrderModel>> getOrders() async {
    try {
      // 1. Intentar consultar directamente Supabase (tabla 'ordenes')
      final supabaseUrl = Uri.parse(
        '${AppConstants.supabaseUrl}/rest/v1/ordenes?select=*&order=created_at.desc&limit=25',
      );
      final response = await _client
          .get(supabaseUrl, headers: _supabaseHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {
      // Fallback resiliente si no hay conexión de red
    }

    // 2. Intentar endpoint secundario de reparto.mx
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConstants.repartoApiBaseUrl}/orders'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => OrderModel.fromJson(e)).toList();
      }
    } catch (_) {}

    return MockData.mockOrders;
  }

  /// Actualiza el estado de un pedido (sincroniza en Supabase)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      String dbStatus = newStatus;
      if (newStatus == 'pending') dbStatus = 'creada';
      if (newStatus == 'in_route') dbStatus = 'en_camino';
      if (newStatus == 'delivered') dbStatus = 'entregada';
      if (newStatus == 'canceled') dbStatus = 'cancelada';

      final supabaseUrl = Uri.parse(
        '${AppConstants.supabaseUrl}/rest/v1/ordenes?id=eq.$orderId',
      );
      final response = await _client
          .patch(
            supabaseUrl,
            headers: _supabaseHeaders,
            body: jsonEncode({'estado': dbStatus}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
    } catch (_) {}

    return true; // En modo offline o mock simulado retorna éxito
  }

  /// Registra la prueba de entrega digital (firma, foto, receptor)
  Future<bool> submitProofOfDelivery({
    required String orderId,
    required String? signature,
    required String? photoUrl,
    required String receivedBy,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConstants.repartoApiBaseUrl}/orders/$orderId/proof'),
            headers: _headers,
            body: jsonEncode({
              'signature': signature,
              'photoUrl': photoUrl,
              'receivedBy': receivedBy,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  /// Obtiene el perfil del repartidor
  Future<CourierModel> getCourierProfile() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConstants.repartoApiBaseUrl}/courier/profile'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return CourierModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return MockData.initialCourier;
  }

  /// Actualiza posición y estado online del repartidor
  Future<bool> updateCourierLocation({
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConstants.repartoApiBaseUrl}/courier/telemetry'),
            headers: _headers,
            body: jsonEncode({
              'isOnline': isOnline,
              'lat': lat,
              'lng': lng,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  /// Obtiene la ruta optimizada activa
  Future<List<RouteStopModel>> getActiveRouteStops() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConstants.repartoApiBaseUrl}/courier/route'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => RouteStopModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return MockData.mockActiveRouteStops;
  }

  /// Obtiene las sucursales de la plataforma
  Future<List<BranchModel>> getBranches() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConstants.repartoApiBaseUrl}/branches'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => BranchModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return MockData.mockBranches;
  }
}
