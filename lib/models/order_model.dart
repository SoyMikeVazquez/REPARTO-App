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
      name: (json['name'] ?? json['nombre'] ?? 'Producto').toString(),
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
    this.proofSignature,
    this.proofPhotoUrl,
    this.proofReceivedBy,
  });

  OrderModel copyWith({
    String? status,
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
      proofSignature: proofSignature ?? this.proofSignature,
      proofPhotoUrl: proofPhotoUrl ?? this.proofPhotoUrl,
      proofReceivedBy: proofReceivedBy ?? this.proofReceivedBy,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Normalizar estado
    String rawStatus = (json['status'] ?? json['estado'] ?? 'pending').toString().toLowerCase();
    String normalizedStatus = 'pending';
    if (rawStatus == 'creada' || rawStatus == 'pending') {
      normalizedStatus = 'pending';
    } else if (rawStatus == 'preparando' || rawStatus == 'preparing') {
      normalizedStatus = 'preparing';
    } else if (rawStatus == 'listo' || rawStatus == 'ready') {
      normalizedStatus = 'ready';
    } else if (rawStatus == 'en_camino' || rawStatus == 'en_ruta' || rawStatus == 'in_route') {
      normalizedStatus = 'in_route';
    } else if (rawStatus == 'entregada' || rawStatus == 'delivered') {
      normalizedStatus = 'delivered';
    } else if (rawStatus == 'cancelada' || rawStatus == 'canceled') {
      normalizedStatus = 'canceled';
    }

    // Normalizar items/productos
    final rawItems = json['items'] ?? json['productos'];
    List<OrderItem> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .map((e) => OrderItem.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final totalVal = ((json['total'] ?? 0) as num).toDouble();
    final subtotalVal = ((json['subtotal'] ?? totalVal) as num).toDouble();
    final deliveryFeeVal = ((json['deliveryFee'] ?? json['costo_envio'] ?? 35.0) as num).toDouble();

    DateTime parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return OrderModel(
      id: (json['id'] ?? '').toString(),
      customerName: (json['customerName'] ?? json['cliente_nombre'] ?? 'Cliente').toString(),
      customerPhone: (json['customerPhone'] ?? json['telefono'] ?? '').toString(),
      deliveryAddress: (json['deliveryAddress'] ?? json['direccion'] ?? 'Dirección no especificada').toString(),
      deliveryNotes: (json['deliveryNotes'] ?? json['notas'] ?? json['instrucciones']) as String?,
      branchName: (json['branchName'] ?? json['sucursal_nombre'] ?? 'Tosti Pizza Centro').toString(),
      branchAddress: (json['branchAddress'] ?? json['sucursal_direccion'] ?? 'Av. Constitución 1234').toString(),
      status: normalizedStatus,
      paymentMethod: (json['paymentMethod'] ?? json['metodo_pago'] ?? 'cash').toString(),
      isPaid: json['isPaid'] ?? (json['pagado'] == true || json['estado_pago'] == 'pagado'),
      items: itemsList,
      subtotal: subtotalVal,
      deliveryFee: deliveryFeeVal,
      total: totalVal,
      estimatedDeliveryTime: (json['estimatedDeliveryTime'] ?? json['tiempo_estimado'] ?? '25-35 min').toString(),
      deliveryPin: (json['deliveryPin'] ?? json['pin_entrega'] ?? '4821').toString(),
      lat: ((json['lat'] ?? 25.686614) as num).toDouble(),
      lng: ((json['lng'] ?? -100.316112) as num).toDouble(),
      branchLat: ((json['branchLat'] ?? 25.6800) as num).toDouble(),
      branchLng: ((json['branchLng'] ?? -100.3100) as num).toDouble(),
      createdAt: parsedCreatedAt,
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
        'proofSignature': proofSignature,
        'proofPhotoUrl': proofPhotoUrl,
        'proofReceivedBy': proofReceivedBy,
      };
}
