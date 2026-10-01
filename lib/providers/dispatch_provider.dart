import 'package:flutter/material.dart';
import '../models/branch_model.dart';
import '../models/courier_model.dart';
import '../core/network/api_service.dart';
import '../core/network/mock_data.dart';

class DispatchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<BranchModel> _branches = [];
  List<CourierModel> _fleet = [];
  bool _isLoading = false;
  String _selectedBranchId = 'SUC-01';

  List<BranchModel> get branches => _branches;
  List<CourierModel> get fleet => _fleet;
  bool get isLoading => _isLoading;
  String get selectedBranchId => _selectedBranchId;

  BranchModel? get selectedBranch {
    if (_branches.isEmpty) return null;
    return _branches.firstWhere(
      (b) => b.id == _selectedBranchId,
      orElse: () => _branches.first,
    );
  }

  int get couriersOnlineCount => _fleet.where((c) => c.isOnline).length;

  DispatchProvider() {
    fetchDispatchData();
  }

  Future<void> fetchDispatchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _branches = await _apiService.getBranches();
    } catch (_) {
      _branches = MockData.mockBranches;
    }

    _fleet = [
      MockData.initialCourier,
      CourierModel(
        id: 'REP-773',
        name: 'Ana Sofía Rangel',
        phone: '+52 55 2233 4455',
        email: 'ana.rangel@reparto.mx',
        vehicleType: 'Bicicleta Eléctrica',
        vehiclePlate: 'BICI-90',
        rating: 4.88,
        totalDeliveries: 310,
        isOnline: true,
        currentLat: 19.4140,
        currentLng: -99.1630,
        todayEarnings: 620.0,
        todayTips: 140.0,
        completedToday: 5,
      ),
      CourierModel(
        id: 'REP-774',
        name: 'Javier Morales',
        phone: '+52 55 9988 7766',
        email: 'javier.morales@reparto.mx',
        vehicleType: 'Motocicleta (Italika 150)',
        vehiclePlate: '9X1-CDX',
        rating: 4.97,
        totalDeliveries: 890,
        isOnline: false,
        currentLat: 19.4230,
        currentLng: -99.1570,
        todayEarnings: 450.0,
        todayTips: 90.0,
        completedToday: 4,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void selectBranch(String branchId) {
    _selectedBranchId = branchId;
    notifyListeners();
  }

  void assignCourierToOrder(String orderId, String courierId) {
    // Simula asignación de repartidor a pedido
    notifyListeners();
  }
}
