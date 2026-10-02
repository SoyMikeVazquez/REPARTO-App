import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../core/network/mock_data.dart';

class OrdersProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, in_route, ready, delivered
  String _searchQuery = '';

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  OrdersProvider() {
    fetchOrders();
    _setupRealtime();
  }

  void _setupRealtime() {
    _supabase
        .channel('public:orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            fetchOrders();
          },
        )
        .subscribe();
  }

  List<OrderModel> get filteredOrders {
    return _orders.where((order) {
      final matchesFilter = switch (_selectedFilter) {
        'in_route' => order.status == 'in_route' || order.status == 'en_camino',
        'ready' => order.status == 'ready' || order.status == 'listo_para_entregar',
        'delivered' => order.status == 'delivered' || order.status == 'entregado',
        _ => true,
      };

      final matchesSearch = _searchQuery.isEmpty ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.deliveryAddress.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  int get countInRoute =>
      _orders.where((o) => o.status == 'in_route' || o.status == 'en_camino').length;
  int get countReady =>
      _orders.where((o) => o.status == 'ready' || o.status == 'listo_para_entregar').length;
  int get countDelivered =>
      _orders.where((o) => o.status == 'delivered' || o.status == 'entregado').length;

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Obtener coordenadas del repartidor (Asumiremos un default o leeremos de LocationService)
      final double currentLat = 25.6866; 
      final double currentLng = -100.3161;

      // 1. Obtener órdenes listas cercanas (RPC)
      final List<dynamic> nearbyOrdersData = await _supabase.rpc(
        'nearby_ready_orders',
        params: {
          'driver_lat': currentLat,
          'driver_lng': currentLng,
          'radius_km': 6.0,
        },
      );

      // 2. Obtener órdenes propias (en camino o entregadas)
      final List<dynamic> ownOrdersData = await _supabase
          .from('orders')
          .select()
          .eq('driver_id', userId);

      // Fusionar y mapear
      final Map<String, dynamic> merged = {};
      for (var order in nearbyOrdersData) {
        merged[order['id']] = order;
      }
      for (var order in ownOrdersData) {
        merged[order['id']] = order;
      }

      if (merged.isEmpty) {
        // Fallback a mock data si la base de datos está vacía para fines de diseño
        _orders = MockData.mockOrders;
      } else {
        _orders = merged.values
            .map((data) => OrderModel.fromJson(Map<String, dynamic>.from(data)))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      _orders = MockData.mockOrders; // Fallback visual
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchClientOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Obtener órdenes donde client_id sea el usuario actual
      final List<dynamic> clientOrdersData = await _supabase
          .from('orders')
          .select()
          .eq('client_id', userId)
          .order('created_at', ascending: false);

      if (clientOrdersData.isEmpty) {
        _orders = [];
      } else {
        _orders = clientOrdersData
            .map((data) => OrderModel.fromJson(Map<String, dynamic>.from(data)))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching client orders: $e');
      _orders = MockData.mockOrders; // Fallback
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> updateStatus(String orderId, String newStatus) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      // Mapear status a los de la BD ('in_route' -> 'en_camino')
      String dbStatus = newStatus;
      if (newStatus == 'in_route') dbStatus = 'en_camino';
      if (newStatus == 'delivered') dbStatus = 'entregado';

      await _supabase.from('orders').update({
        'status': dbStatus,
        if (dbStatus == 'en_camino') 'driver_id': userId, // Tomar la orden
      }).eq('id', orderId);
      
      // Actualización optimista local
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: newStatus);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating order: $e');
      return false;
    }
  }

  Future<bool> registerProofOfDelivery({
    required String orderId,
    required String signature,
    required String receivedBy,
    String? photoUrl,
  }) async {
    try {
      await _supabase.from('orders').update({
        'status': 'entregado',
        // 'proof_signature': signature, // En una app real, actualizarías las columnas de prueba
        // 'proof_received_by': receivedBy,
      }).eq('id', orderId);

      // Optimistic update
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: 'delivered',
          proofSignature: signature,
          proofReceivedBy: receivedBy,
          proofPhotoUrl: photoUrl,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error registering proof: $e');
      return false;
    }
  }
}
