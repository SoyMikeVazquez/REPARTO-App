import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../core/network/api_service.dart';
import '../core/network/mock_data.dart';

class OrdersProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

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
  }

  List<OrderModel> get filteredOrders {
    return _orders.where((order) {
      final matchesFilter = switch (_selectedFilter) {
        'in_route' => order.status == 'in_route',
        'ready' => order.status == 'ready' || order.status == 'preparing',
        'delivered' => order.status == 'delivered',
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
      _orders.where((o) => o.status == 'in_route').length;
  int get countReady =>
      _orders.where((o) => o.status == 'ready' || o.status == 'preparing').length;
  int get countDelivered =>
      _orders.where((o) => o.status == 'delivered').length;

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _apiService.getOrders();
    } catch (_) {
      _orders = MockData.mockOrders;
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
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
      notifyListeners();
      return await _apiService.updateOrderStatus(orderId, newStatus);
    }
    return false;
  }

  Future<bool> registerProofOfDelivery({
    required String orderId,
    required String signature,
    required String receivedBy,
    String? photoUrl,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: 'delivered',
        proofSignature: signature,
        proofReceivedBy: receivedBy,
        proofPhotoUrl: photoUrl,
      );
      notifyListeners();

      return await _apiService.submitProofOfDelivery(
        orderId: orderId,
        signature: signature,
        photoUrl: photoUrl,
        receivedBy: receivedBy,
      );
    }
    return false;
  }
}
