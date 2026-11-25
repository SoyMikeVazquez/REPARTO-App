import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/courier_model.dart';
import '../core/services/storage_service.dart';
import '../core/network/api_service.dart';
import '../core/network/mock_data.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

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
  User? get user => _supabase?.auth.currentUser;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final client = _supabase;
    if (client != null) {
      final session = client.auth.currentSession;
      _isAuthenticated = session != null;
      if (session != null) {
        await _fetchUserProfile(session.user.id);
      } else {
        _courierStatus = '';
      }

      // Escuchar cambios de sesión en Supabase
      client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        _isAuthenticated = session != null;
        if (session != null) {
          await _fetchUserProfile(session.user.id);
        } else {
          _courierStatus = '';
          _userRole = 'cliente';
        }
        notifyListeners();
      });
    }

    _userRole = StorageService.getUserRole();
    _businessSlug = StorageService.getBusinessSlug();
    final savedOnline = StorageService.getCourierOnline();
    _courier = _courier.copyWith(isOnline: savedOnline);

    final savedClient = StorageService.getClientIdentifier();
    if (savedClient != null && savedClient.isNotEmpty) {
      _userRole = 'cliente';
      _isAuthenticated = true;
    }

    notifyListeners();
  }

  String _courierStatus = ''; // 'Pendiente', 'Confirmado', etc.
  String get courierStatus => _courierStatus;

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final client = _supabase;
      if (client == null) return;

      final session = client.auth.currentSession;
      final userEmail = session?.user.email ?? client.auth.currentUser?.email;

      final response = await client
          .from('profiles')
          .select('role, broker_id')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _userRole = response['role'] ?? 'cliente';
        await StorageService.saveUserRole(_userRole);
      }

      // Consulta en la tabla 'repartidores' por id o correo
      final filter = userEmail != null && userEmail.isNotEmpty
          ? 'id_repartidor.eq.$userId,email.eq.$userEmail'
          : 'id_repartidor.eq.$userId';

      final repResponse = await client
          .from('repartidores')
          .select('*')
          .or(filter)
          .maybeSingle();

      if (repResponse != null) {
        _userRole = 'repartidor';
        _courierStatus = (repResponse['status'] ?? 'Pendiente').toString();
        _courier = CourierModel.fromSupabase(repResponse);
        await StorageService.saveUserRole(_userRole);
        if (_courier.id.isNotEmpty) {
          await StorageService.saveCourierId(_courier.id);
        }
      } else {
        _courierStatus = '';
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  /// Consulta directamente en la tabla 'repartidores' de Supabase
  Future<Map<String, dynamic>?> checkCourierByPhone(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final last10Digits = cleanDigits.length >= 10
          ? cleanDigits.substring(cleanDigits.length - 10)
          : cleanDigits;

      final client = _supabase;
      if (client != null) {
        final response = await client
            .from('repartidores')
            .select('*')
            .or('phone.eq.$last10Digits,phone.eq.+$cleanDigits,phone.eq.$cleanDigits')
            .maybeSingle();

        _isLoading = false;
        notifyListeners();
        return response;
      }
    } catch (e) {
      debugPrint('Error consultando tabla repartidores en Supabase: $e');
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Inicia sesión con correo y contraseña para repartidores en Supabase Auth
  /// y valida su registro y estatus en la tabla 'repartidores'.
  Future<Map<String, dynamic>> signInCourierWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = _supabase;
      if (client == null) {
        throw Exception('El servicio de Supabase no está configurado.');
      }

      final cleanEmail = email.trim();

      // 1. Iniciar sesión en Supabase Auth con credenciales
      final authResponse = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('No fue posible autenticar el usuario en Supabase.');
      }

      // 2. Consultar la tabla de 'repartidores'
      final normalizedEmail = (user.email ?? cleanEmail).toLowerCase();
      final courierData = await client
          .from('repartidores')
          .select('*')
          .or('id_repartidor.eq.${user.id},email.eq.$normalizedEmail')
          .maybeSingle();

      if (courierData == null) {
        // La cuenta existe en Supabase Auth pero NO está dada de alta en 'repartidores'
        await client.auth.signOut();
        throw Exception(
          'Esta cuenta no está registrada en la tabla de "Repartidores". '
          'Verifica tus credenciales o solicita tu registro como repartidor.',
        );
      }

      // 3. Configurar sesión de repartidor
      final status = (courierData['status'] ?? 'Confirmado').toString();
      _userRole = 'repartidor';
      _isAuthenticated = true;
      _courierStatus = status;
      _courier = CourierModel.fromSupabase(courierData);

      await StorageService.saveUserRole('repartidor');
      if (_courier.id.isNotEmpty) {
        await StorageService.saveCourierId(_courier.id);
      }

      return courierData;
    } on AuthException catch (ae) {
      final msg = ae.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        throw Exception('Correo o contraseña incorrectos. Verifica tus credenciales.');
      } else if (msg.contains('email not confirmed')) {
        throw Exception('Tu correo electrónico no ha sido verificado en Supabase.');
      } else {
        throw Exception(ae.message);
      }
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('socketconnection failed') ||
          str.contains('socketexception') ||
          str.contains('operation not permitted')) {
        throw Exception(
          'Error de red: Conexión denegada por el sistema. '
          'Reinicia la app para aplicar los permisos de red en macOS.',
        );
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envía correo de recuperación de contraseña para repartidores
  Future<void> sendPasswordReset(String email) async {
    final client = _supabase;
    if (client == null) throw Exception('Supabase no disponible');
    await client.auth.resetPasswordForEmail(email.trim());
  }

  /// Inicia sesión con la referencia de la tabla 'repartidores'
  Future<void> loginAsCourier(Map<String, dynamic> courierData) async {
    _isLoading = true;
    notifyListeners();

    _userRole = 'repartidor';
    _isAuthenticated = true;
    _courierStatus = (courierData['status'] ?? 'Confirmado').toString();
    _courier = CourierModel.fromSupabase(courierData);

    await StorageService.saveUserRole('repartidor');
    if (_courier.id.isNotEmpty) {
      await StorageService.saveCourierId(_courier.id);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Inicia sesión como cliente con su teléfono o correo verificado en la tabla de órdenes
  Future<void> loginAsClient(String phoneOrEmail) async {
    _isLoading = true;
    notifyListeners();

    _userRole = 'cliente';
    _isAuthenticated = true;
    _courierStatus = '';

    await StorageService.saveUserRole('cliente');
    await StorageService.saveClientIdentifier(phoneOrEmail.trim());

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithPhone(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = _supabase;
      if (client != null) {
        await client.auth.signInWithOtp(
          phone: phone,
        );
      }
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
      final client = _supabase;
      if (client != null) {
        await client.auth.verifyOTP(
          phone: phone,
          token: token,
          type: OtpType.sms,
        );
      }
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
    try {
      await _supabase?.auth.signOut();
    } catch (_) {}
    _isAuthenticated = false;
    _courierStatus = '';
    _userRole = 'cliente';
    await StorageService.clearAll();
    notifyListeners();
  }
}
