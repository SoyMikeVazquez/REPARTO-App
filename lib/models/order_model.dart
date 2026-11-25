import 'dart:math';

class OrderItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final String? notes;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.notes,
  });

  double get totalPrice => quantity * unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: (json['name'] ?? json['nombre'] ?? json['item'] ?? 'Producto').toString(),
      quantity: ((json['quantity'] ?? json['cantidad'] ?? 1) as num).toInt(),
      unitPrice: ((json['unitPrice'] ?? json['price'] ?? json['precio'] ?? 0) as num).toDouble(),
      notes: (json['notes'] ?? json['notas']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'notes': notes,
      };
}

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String? deliveryNotes;
  final String branchName;
  final String branchAddress;
  final String status; // pending, preparing, ready, in_route, delivered, canceled
  final String paymentMethod; // cash, card, online
  final bool isPaid;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String estimatedDeliveryTime;
  final String deliveryPin;
  final double lat;
  final double lng;
  final double branchLat;
  final double branchLng;
  final DateTime createdAt;
  final String? courierId;
  final String? proofSignature;
  final String? proofPhotoUrl;
  final String? proofReceivedBy;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.deliveryNotes,
    required this.branchName,
    required this.branchAddress,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.estimatedDeliveryTime,
    required this.deliveryPin,
    required this.lat,
    required this.lng,
    required this.branchLat,
    required this.branchLng,
    required this.createdAt,
    this.courierId,
    this.proofSignature,
    this.proofPhotoUrl,
    this.proofReceivedBy,
  });

  /// Distancia en kilómetros desde la sucursal/origen hasta las coordenadas del repartidor
  double distanceToBranch(double courierLat, double courierLng) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((branchLat - courierLat) * p) / 2 +
        cos(courierLat * p) * cos(branchLat * p) * (1 - cos((branchLng - courierLng) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Distancia en kilómetros desde el destino del cliente hasta las coordenadas del repartidor
  double distanceToCustomer(double courierLat, double courierLng) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat - courierLat) * p) / 2 +
        cos(courierLat * p) * cos(lat * p) * (1 - cos((lng - courierLng) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  OrderModel copyWith({
    String? status,
    String? courierId,
    String? proofSignature,
    String? proofPhotoUrl,
    String? proofReceivedBy,
  }) {
    return OrderModel(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      deliveryNotes: deliveryNotes,
      branchName: branchName,
      branchAddress: branchAddress,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      isPaid: isPaid,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      estimatedDeliveryTime: estimatedDeliveryTime,
      deliveryPin: deliveryPin,
      lat: lat,
      lng: lng,
      branchLat: branchLat,
      branchLng: branchLng,
      createdAt: createdAt,
      courierId: courierId ?? this.courierId,
      proofSignature: proofSignature ?? this.proofSignature,
      proofPhotoUrl: proofPhotoUrl ?? this.proofPhotoUrl,
      proofReceivedBy: proofReceivedBy ?? this.proofReceivedBy,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Normalizar estado
    String rawStatus = (json['status'] ?? json['estado'] ?? 'pending').toString().toLowerCase();
    String normalizedStatus = 'pending';
    if (rawStatus == 'creada' || rawStatus == 'pending' || rawStatus == 'pendiente') {
      normalizedStatus = 'pending';
    } else if (rawStatus == 'preparando' || rawStatus == 'preparing') {
      normalizedStatus = 'preparing';
    } else if (rawStatus == 'listo' || rawStatus == 'ready' || rawStatus == 'listo_para_entregar') {
      normalizedStatus = 'ready';
    } else if (rawStatus == 'en_camino' || rawStatus == 'en_ruta' || rawStatus == 'in_route' || rawStatus == 'transit') {
      normalizedStatus = 'in_route';
    } else if (rawStatus == 'entregada' || rawStatus == 'delivered' || rawStatus == 'entregado') {
      normalizedStatus = 'delivered';
    } else if (rawStatus == 'cancelada' || rawStatus == 'canceled') {
      normalizedStatus = 'canceled';
    }

    // Normalizar items/productos
    final rawItems = json['items'] ?? json['productos'] ?? json['order_carrito'];
    List<OrderItem> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .map((e) => OrderItem.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (rawItems is String && rawItems.isNotEmpty) {
      itemsList = [
        OrderItem(
          name: rawItems,
          quantity: 1,
          unitPrice: ((json['monto_envio'] ?? json['total'] ?? 180) as num).toDouble(),
        ),
      ];
    } else {
      itemsList = [
        OrderItem(
          name: 'Pedido de Entrega',
          quantity: 1,
          unitPrice: ((json['monto_envio'] ?? json['total'] ?? 180) as num).toDouble(),
        ),
      ];
    }

    final totalVal = ((json['total'] ?? json['monto_envio'] ?? 240.0) as num).toDouble();
    final subtotalVal = ((json['subtotal'] ?? totalVal) as num).toDouble();
    final deliveryFeeVal = ((json['deliveryFee'] ?? json['costo_envio'] ?? json['comision'] ?? 35.0) as num).toDouble();

    DateTime parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    final double destLat = ((json['lat'] ?? 19.4185) as num).toDouble();
    final double destLng = ((json['lng'] ?? -99.1620) as num).toDouble();

    // Coordenadas de la sucursal / origen (soporta Sucursales y deliveries de Supabase)
    final double bLat = ((json['branch_lat'] ??
            json['sucursal_lat'] ??
            json['latitud_sucursal'] ??
            json['lat_sucursal'] ??
            json['pickup_lat'] ??
            json['origen_lat'] ??
            json['Latitud'] ??
            (destLat + 0.0035)) as num)
        .toDouble();
    final double bLng = ((json['branch_lng'] ??
            json['sucursal_lng'] ??
            json['longitud_sucursal'] ??
            json['lng_sucursal'] ??
            json['pickup_lng'] ??
            json['origen_lng'] ??
            json['Longitud'] ??
            (destLng - 0.0025)) as num)
        .toDouble();

    final courierIdVal = (json['id_repartidor'] ?? json['driver_id'] ?? json['courierId'])?.toString();

    final branchNameVal = (json['NombreSucursal'] ??
            json['branchName'] ??
            json['sucursal_nombre'] ??
            json['sucursal'] ??
            (json['idEmpresa'] != null ? 'Sucursal ${json['idEmpresa']}' : 'Pizzería Roma Artesanal'))
        .toString();

    final branchAddressVal = (json['DireccionSucursal'] ??
            json['branchAddress'] ??
            json['sucursal_direccion'] ??
            'Calle Colima 180, Cuauhtémoc')
        .toString();

    return OrderModel(
      id: (json['id'] ?? '').toString(),
      customerName: (json['name'] ?? json['nombre'] ?? json['customer'] ?? json['customerName'] ?? json['cliente_nombre'] ?? 'Cliente').toString(),
      customerPhone: (json['phone'] ?? json['numero'] ?? json['customerPhone'] ?? json['telefono'] ?? '+52 55 5584 9201').toString(),
      deliveryAddress: (json['address'] ?? json['deliveryAddress'] ?? json['direccion'] ?? 'Dirección en CDMX').toString(),
      deliveryNotes: (json['deliveryNotes'] ?? json['notas'] ?? json['instrucciones']) as String?,
      branchName: branchNameVal,
      branchAddress: branchAddressVal,
      status: normalizedStatus,
      paymentMethod: (json['paymentMethod'] ?? json['metodo_pago'] ?? 'online').toString(),
      isPaid: json['isPaid'] ?? (json['pagado'] == true || json['estado_pago'] == 'pagado' || true),
      items: itemsList,
      subtotal: subtotalVal,
      deliveryFee: deliveryFeeVal,
      total: totalVal,
      estimatedDeliveryTime: (json['created_time'] ?? json['estimatedDeliveryTime'] ?? json['tiempo_estimado'] ?? '25-35 min').toString(),
      deliveryPin: (json['deliveryPin'] ?? json['pin_entrega'] ?? '4821').toString(),
      lat: destLat,
      lng: destLng,
      branchLat: bLat,
      branchLng: bLng,
      createdAt: parsedCreatedAt,
      courierId: courierIdVal,
      proofSignature: (json['proofSignature'] ?? json['firma_entrega']) as String?,
      proofPhotoUrl: (json['proofPhotoUrl'] ?? json['foto_entrega']) as String?,
      proofReceivedBy: (json['proofReceivedBy'] ?? json['recibido_por']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'deliveryNotes': deliveryNotes,
        'branchName': branchName,
        'branchAddress': branchAddress,
        'status': status,
        'paymentMethod': paymentMethod,
        'isPaid': isPaid,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'estimatedDeliveryTime': estimatedDeliveryTime,
        'deliveryPin': deliveryPin,
        'lat': lat,
        'lng': lng,
        'branchLat': branchLat,
        'branchLng': branchLng,
        'createdAt': createdAt.toIso8601String(),
        'id_repartidor': courierId,
        'proofSignature': proofSignature,
        'proofPhotoUrl': proofPhotoUrl,
        'proofReceivedBy': proofReceivedBy,
      };
}

