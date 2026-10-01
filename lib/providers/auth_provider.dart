import 'package:flutter/material.dart';
import '../models/courier_model.dart';
import '../core/services/storage_service.dart';
import '../core/network/api_service.dart';
import '../core/network/mock_data.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = true; // Por defecto autenticado en sesión demo
  String _userRole = 'courier'; // 'courier' | 'dispatcher'
  String _businessSlug = 'reparto-cdmx';
  CourierModel _courier = MockData.initialCourier;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String get userRole => _userRole;
  bool get isCourier => _userRole == 'courier';
  bool get isDispatcher => _userRole == 'dispatcher';
  String get businessSlug => _businessSlug;
  CourierModel get courier => _courier;
  bool get isOnline => _courier.isOnline;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _userRole = StorageService.getUserRole();
    _businessSlug = StorageService.getBusinessSlug();
    final savedOnline = StorageService.getCourierOnline();
    _courier = _courier.copyWith(isOnline: savedOnline);
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
    required String role,
    required String slug,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600)); // Simula handshake API

    _isAuthenticated = true;
    _userRole = role;
    _businessSlug = slug;

    await StorageService.saveUserRole(role);
    await StorageService.saveBusinessSlug(slug);
    await StorageService.saveAuthToken('token_reparto_${DateTime.now().millisecondsSinceEpoch}');

    _isLoading = false;
    notifyListeners();
  }

  void switchRole(String newRole) {
    _userRole = newRole;
    StorageService.saveUserRole(newRole);
    notifyListeners();
  }

  void setBusinessSlug(String newSlug) {
    _businessSlug = newSlug;
    StorageService.saveBusinessSlug(newSlug);
    notifyListeners();
  }

  Future<void> toggleOnlineStatus() async {
    final nextStatus = !_courier.isOnline;
    _courier = _courier.copyWith(isOnline: nextStatus);
    await StorageService.saveCourierOnline(nextStatus);
    notifyListeners();

    // Sincroniza telemetría en background con reparto.mx
    _apiService.updateCourierLocation(
      isOnline: nextStatus,
      lat: _courier.currentLat,
      lng: _courier.currentLng,
    );
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    await StorageService.clearAll();
    notifyListeners();
  }
}
