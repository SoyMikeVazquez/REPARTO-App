import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../core/network/mock_data.dart';
import '../core/services/storage_service.dart';

class OrdersProvider extends ChangeNotifier {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  List<OrderModel> _orders = MockData.mockOrders;
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, in_route, ready, delivered
  String _searchQuery = '';
  
  // Ubicación del repartidor para cálculo de radar (CDMX Roma Norte por defecto)
  double _courierLat = 19.4194;
  double _courierLng = -99.1601;
  String? _currentCourierId;

  RealtimeChannel? _realtimeChannel;
  Timer? _pollingTimer;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  double get courierLat => _courierLat;
  double get courierLng => _courierLng;
  String? get currentCourierId => _currentCourierId;

  OrdersProvider() {
    fetchOrders();
    _setupRealtime();
    _startPeriodicPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _startPeriodicPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      fetchOrders(silent: true);
    });
  }

  void updateCourierLocation(double lat, double lng, {String? courierId}) {
    bool changed = false;
    if (_courierLat != lat || _courierLng != lng) {
      _courierLat = lat;
      _courierLng = lng;
      changed = true;
    }
    if (courierId != null && _currentCourierId != courierId) {
      _currentCourierId = courierId;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void _setupRealtime() {
    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = _supabase
          ?.channel('public:deliveries')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'deliveries',
            callback: (payload) {
              debugPrint('⚡ [Supabase Realtime] Cambio en deliveries (${payload.eventType})');
              fetchOrders(silent: true);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('⚠️ Error en realtime de deliveries: $e');
    }
  }

  /// Pedidos pendientes disponibles dentro del rango de 5 a 6 km de la sucursal/ubicación
  List<OrderModel> get nearbyPendingOrders {
    return _orders.where((order) {
      // 1. Debe ser un pedido no finalizado y disponible para ser tomado
      final isPending = order.status == 'pending' ||
          order.status == 'ready' ||
          order.courierId == null ||
          order.courierId == 'sin_asignar' ||
          order.courierId == 'unassigned' ||
          order.courierId == '' ||
          order.courierId == 'none';

      final isClaimedByMe = _currentCourierId != null &&
          order.courierId == _currentCourierId &&
          order.status == 'in_route';
      final isDelivered = order.status == 'delivered' || order.status == 'canceled';

      if (!isPending || isClaimedByMe || isDelivered) return false;

      // 2. Radio de 6 km desde la sucursal o el punto de origen
      final dist = order.distanceToBranch(_courierLat, _courierLng);
      return dist <= 6.0;
    }).toList();
  }

  /// Contador en tiempo real de pedidos pendientes dentro del radio de 6 km
  int get nearbyPendingCount => nearbyPendingOrders.length;

  /// Pedido activo que el repartidor está entregando actualmente
  OrderModel? get activeOrder {
    // 1. Buscar primero la orden que pertenezca al repartidor autenticado en tránsito
    if (_currentCourierId != null && _currentCourierId!.isNotEmpty) {
      final myOrders = _orders.where((o) =>
          o.courierId == _currentCourierId &&
          (o.status == 'in_route' || o.status == 'transit')).toList();
      if (myOrders.isNotEmpty) return myOrders.first;
    }

    // 2. Si no hay una específica del id actual, buscar cualquier orden en ruta localmente
    final inRoute = _orders.where((o) => o.status == 'in_route' || o.status == 'transit').toList();
    if (inRoute.isNotEmpty) return inRoute.first;

    return null;
  }

  List<OrderModel> get filteredOrders {
    return _orders.where((order) {
      final matchesFilter = switch (_selectedFilter) {
        'in_route' => order.status == 'in_route' || order.status == 'en_camino',
        'ready' => order.status == 'ready' || order.status == 'pending',
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
  int get countReady => nearbyPendingCount;
  int get countDelivered =>
      _orders.where((o) => o.status == 'delivered' || o.status == 'entregado').length;

  /// Carga los pedidos en tiempo real desde la tabla 'deliveries' de Supabase
  Future<void> fetchOrders({
    bool silent = false,
    double? courierLat,
    double? courierLng,
    String? courierId,
  }) async {
    if (courierLat != null) _courierLat = courierLat;
    if (courierLng != null) _courierLng = courierLng;
    if (courierId != null) _currentCourierId = courierId;

    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final client = _supabase;
      if (client == null) {
        if (_orders.isEmpty) _orders = MockData.mockOrders;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Consulta sucursales para enriquecer con coordenadas reales de recogida
      final Map<String, Map<String, dynamic>> sucursalesMap = {};
      try {
        final List<dynamic> sucursalesData = await client.from('Sucursales').select();
        for (final item in sucursalesData) {
          if (item is Map) {
            final sMap = Map<String, dynamic>.from(item);
            final idEmpresa = sMap['IDEmpresa']?.toString();
            final idSucursal = sMap['IDSucursal']?.toString();
            if (idEmpresa != null && idEmpresa.isNotEmpty) {
              sucursalesMap[idEmpresa] = sMap;
            }
            if (idSucursal != null && idSucursal.isNotEmpty) {
              sucursalesMap[idSucursal] = sMap;
            }
          }
        }
      } catch (e) {
        debugPrint('Consulta opcional de Sucursales: $e');
      }

      // Consulta en tiempo real a la tabla 'deliveries'
      final List<dynamic> deliveriesData = await client
          .from('deliveries')
          .select()
          .order('id', ascending: false);

      if (deliveriesData.isNotEmpty) {
        _orders = deliveriesData.map((data) {
          final map = Map<String, dynamic>.from(data as Map);
          final idEmpresa = map['idEmpresa']?.toString();
          final idSucursal = map['idSucursal']?.toString();
          final sucursal = sucursalesMap[idEmpresa] ?? sucursalesMap[idSucursal];
          if (sucursal != null) {
            map['NombreSucursal'] ??= sucursal['NombreSucursal'];
            map['DireccionSucursal'] ??= sucursal['DireccionSucursal'];
            map['branch_lat'] ??= sucursal['Latitud'];
            map['branch_lng'] ??= sucursal['Longitud'];
          }
          return OrderModel.fromJson(map);
        }).toList();
      } else {
        _orders = MockData.mockOrders;
      }
    } catch (e) {
      debugPrint('Error fetching deliveries from Supabase: $e');
      if (_orders.isEmpty) {
        _orders = MockData.mockOrders;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Permite al repartidor reclamar un pedido disponible dentro de su rango
  Future<bool> claimOrder({
    required String orderId,
    required String courierId,
  }) async {
    try {
      final client = _supabase;
      _currentCourierId = courierId;

      if (client != null) {
        await client.from('deliveries').update({
          'id_repartidor': courierId,
          'status': 'transit',
        }).eq('id', orderId);
      }

      // Actualización optimista local inmediata
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          courierId: courierId,
          status: 'in_route',
        );
        notifyListeners();
      }

      // Sincronizar con la BD
      await fetchOrders(silent: true, courierId: courierId);
      return true;
    } catch (e) {
      debugPrint('Error claiming delivery $orderId: $e');
      return false;
    }
  }

  /// Actualiza el estado de la entrega en Supabase
  Future<bool> updateStatus(String orderId, String newStatus) async {
    try {
      final client = _supabase;
      final userId = _currentCourierId ?? client?.auth.currentUser?.id;

      String dbStatus = newStatus;
      if (newStatus == 'in_route') dbStatus = 'transit';
      if (newStatus == 'delivered') dbStatus = 'delivered';

      await client?.from('deliveries').update({
        'status': dbStatus,
        if (dbStatus == 'transit' && userId != null) 'id_repartidor': userId,
      }).eq('id', orderId);

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: newStatus);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating delivery status: $e');
      return false;
    }
  }

  /// Registra la prueba de entrega (firma, persona que recibe) y marca entregada
  Future<bool> registerProofOfDelivery({
    required String orderId,
    required String signature,
    required String receivedBy,
    String? photoUrl,
  }) async {
    try {
      final client = _supabase;
      final now = DateTime.now();
      final deliveredTimeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      await client?.from('deliveries').update({
        'status': 'delivered',
        'delivered_time': deliveredTimeStr,
      }).eq('id', orderId);

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
      await fetchOrders(silent: true);
      return true;
    } catch (e) {
      debugPrint('Error registering proof of delivery: $e');
      return false;
    }
  }

  String _clientIdentifier = '';
  String get clientIdentifier => _clientIdentifier;

  /// Consulta en Supabase ('ordenes' y 'orders') si existen pedidos con el teléfono o correo indicado.
  Future<List<OrderModel>> checkOrdersByPhoneOrEmail(String input) async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = _supabase;
      if (client == null) {
        _isLoading = false;
        notifyListeners();
        return [];
      }

      final trimmed = input.trim();
      final isEmail = trimmed.contains('@');
      List<dynamic> results = [];

      if (!isEmail) {
        // Limpiar dígitos de teléfono
        final cleanDigits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
        final last10Digits = cleanDigits.length >= 10
            ? cleanDigits.substring(cleanDigits.length - 10)
            : cleanDigits;

        // 1. PRIORIDAD: Consultar tabla 'deliveries' (historial de entregas solicitado por el cliente)
        if (last10Digits.isNotEmpty) {
          try {
            final List<dynamic> data = await client
                .from('deliveries')
                .select('*')
                .or('phone.eq.$last10Digits,phone.eq.$cleanDigits')
                .order('id', ascending: false);
            if (data.isNotEmpty) {
              results = data;
            }
          } catch (e) {
            debugPrint('Consulta deliveries por phone: $e');
            try {
              final List<dynamic> data = await client
                  .from('deliveries')
                  .select('*')
                  .or('numero.eq.$last10Digits,telefono.eq.$last10Digits')
                  .order('id', ascending: false);
              if (data.isNotEmpty) {
                results = data;
              }
            } catch (_) {}
          }
        }

        // 2. Si no hubo en 'deliveries', intentar en la tabla 'ordenes'
        if (results.isEmpty) {
          try {
            final withPlus52 = '+52$last10Digits';
            final with52 = '52$last10Digits';
            final queryFilter =
                'telefono.eq.$trimmed,telefono.eq.$cleanDigits,telefono.eq.$last10Digits,telefono.eq.$withPlus52,telefono.eq.$with52';
            final List<dynamic> data = await client
                .from('ordenes')
                .select('*')
                .or(queryFilter)
                .order('created_at', ascending: false);
            if (data.isNotEmpty) {
              results = data;
            }
          } catch (e) {
            debugPrint('Error consultando tabla ordenes por telefono: $e');
          }
        }

        // 3. Si no hubo en 'ordenes', intentar en 'orders'
        if (results.isEmpty) {
          try {
            final withPlus52 = '+52$last10Digits';
            final List<dynamic> data = await client
                .from('orders')
                .select('*')
                .or('phone.eq.$trimmed,phone.eq.$cleanDigits,phone.eq.$last10Digits,phone.eq.$withPlus52,customer_phone.eq.$last10Digits')
                .order('created_at', ascending: false);
            if (data.isNotEmpty) {
              results = data;
            }
          } catch (_) {}
        }
      } else {
        final emailLower = trimmed.toLowerCase();
        // 1. PRIORIDAD: Consultar tabla 'deliveries' por mail / correo
        try {
          final List<dynamic> data = await client
              .from('deliveries')
              .select('*')
              .or('mail.eq.$emailLower,email.eq.$emailLower,correo.eq.$emailLower')
              .order('id', ascending: false);
          if (data.isNotEmpty) {
            results = data;
          }
        } catch (e) {
          debugPrint('Consulta deliveries por mail: $e');
        }

        // 2. Si no hubo en 'deliveries', intentar en la tabla 'ordenes' por correo
        if (results.isEmpty) {
          try {
            final List<dynamic> data = await client
                .from('ordenes')
                .select('*')
                .or('email.eq.$emailLower,correo.eq.$emailLower,cliente_email.eq.$emailLower')
                .order('created_at', ascending: false);
            if (data.isNotEmpty) {
              results = data;
            }
          } catch (_) {}
        }

        // 3. Intentar en la tabla 'orders' por email
        if (results.isEmpty) {
          try {
            final List<dynamic> data = await client
                .from('orders')
                .select('*')
                .or('email.eq.$emailLower,customer_email.eq.$emailLower')
                .order('created_at', ascending: false);
            if (data.isNotEmpty) {
              results = data;
            }
          } catch (_) {}
        }
      }

      if (results.isNotEmpty) {
        _clientIdentifier = trimmed;
        await StorageService.saveClientIdentifier(trimmed);
        _orders = results
            .map((data) => OrderModel.fromJson(Map<String, dynamic>.from(data as Map)))
            .toList();
        _isLoading = false;
        notifyListeners();
        return _orders;
      }
    } catch (e) {
      debugPrint('Error en checkOrdersByPhoneOrEmail: $e');
    }

    _isLoading = false;
    notifyListeners();
    return [];
  }

  Future<void> fetchClientOrders([String? identifier]) async {
    _isLoading = true;
    notifyListeners();

    final target = identifier ??
        (_clientIdentifier.isNotEmpty
            ? _clientIdentifier
            : StorageService.getClientIdentifier());

    if (target != null && target.isNotEmpty) {
      final clientOrders = await checkOrdersByPhoneOrEmail(target);
      if (clientOrders.isNotEmpty) {
        return;
      }
    }

    try {
      final client = _supabase;
      if (client != null) {
        try {
          final List<dynamic> delData = await client
              .from('deliveries')
              .select('*')
              .order('id', ascending: false)
              .limit(10);
          if (delData.isNotEmpty) {
            _orders = delData
                .map((d) => OrderModel.fromJson(Map<String, dynamic>.from(d as Map)))
                .toList();
            _isLoading = false;
            notifyListeners();
            return;
          }
        } catch (_) {}

        final List<dynamic> data = await client
            .from('ordenes')
            .select('*')
            .order('created_at', ascending: false)
            .limit(10);
        if (data.isNotEmpty) {
          _orders = data
              .map((d) => OrderModel.fromJson(Map<String, dynamic>.from(d as Map)))
              .toList();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (_) {}

    _orders = MockData.mockOrders;
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
}
