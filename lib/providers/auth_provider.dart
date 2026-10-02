import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/courier_model.dart';
import '../core/services/storage_service.dart';
import '../core/network/api_service.dart';
import '../core/network/mock_data.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isAuthenticated = false;
  String _userRole = 'cliente'; // 'cliente' | 'repartidor' | 'broker'
  String _businessSlug = '';
  CourierModel _courier = MockData.initialCourier;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String get userRole => _userRole;
  bool get isCourier => _userRole == 'repartidor';
  bool get isClient => _userRole == 'cliente';
  String get businessSlug => _businessSlug;
  CourierModel get courier => _courier;
  bool get isOnline => _courier.isOnline;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    _isAuthenticated = session != null;
    if (session != null) {
      await _fetchUserProfile(session.user.id);
    } else {
      _courierStatus = '';
    }

    // Escuchar cambios de sesión en Supabase
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      _isAuthenticated = session != null;
      if (session != null) {
        // Fetch user profile to get role
        await _fetchUserProfile(session.user.id);
      } else {
        _courierStatus = '';
        _userRole = 'cliente';
      }
      notifyListeners();
    });

    _userRole = StorageService.getUserRole();
    _businessSlug = StorageService.getBusinessSlug();
    final savedOnline = StorageService.getCourierOnline();
    _courier = _courier.copyWith(isOnline: savedOnline);
    notifyListeners();
  }

  String _courierStatus = ''; // 'Pendiente', 'Confirmado', etc.
  String get courierStatus => _courierStatus;

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role, broker_id')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _userRole = response['role'] ?? 'cliente';
        await StorageService.saveUserRole(_userRole);
      }

      // Also check if they exist in repartidores table
      final repResponse = await _supabase
          .from('repartidores')
          .select('status')
          .eq('id_repartidor', userId)
          .maybeSingle();
          
      if (repResponse != null) {
        _userRole = 'repartidor'; // Force role if they exist here
        _courierStatus = repResponse['status'] ?? 'Pendiente';
        await StorageService.saveUserRole(_userRole);
      } else {
        _courierStatus = '';
      }
      
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> signInWithPhone(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> verifyOTP(String phone, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

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

    // Sincroniza telemetría en background con Supabase o API
    _apiService.updateCourierLocation(
      isOnline: nextStatus,
      lat: _courier.currentLat,
      lng: _courier.currentLng,
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _isAuthenticated = false;
    _courierStatus = '';
    _userRole = 'cliente';
    await StorageService.clearAll();
    notifyListeners();
  }
}
