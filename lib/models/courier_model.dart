class CourierModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String vehicleType; // 'Moto', 'Bicicleta', 'Auto'
  final String vehiclePlate;
  final double rating;
  final int totalDeliveries;
  final bool isOnline;
  final double currentLat;
  final double currentLng;
  final double todayEarnings;
  final double todayTips;
  final int completedToday;

  CourierModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.rating,
    required this.totalDeliveries,
    required this.isOnline,
    required this.currentLat,
    required this.currentLng,
    required this.todayEarnings,
    required this.todayTips,
    required this.completedToday,
  });

  CourierModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? vehiclePlate,
    double? rating,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    double? todayEarnings,
    double? todayTips,
    int? completedToday,
    int? totalDeliveries,
  }) {
    return CourierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isOnline: isOnline ?? this.isOnline,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayTips: todayTips ?? this.todayTips,
      completedToday: completedToday ?? this.completedToday,
    );
  }

  factory CourierModel.fromSupabase(Map<String, dynamic> json) {
    return CourierModel(
      id: (json['id_repartidor'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['nombre'] ?? 'Repartidor').toString(),
      phone: (json['phone'] ?? json['telefono'] ?? '').toString(),
      email: (json['email'] ?? json['correo'] ?? '').toString(),
      vehicleType: (json['vehicleType'] ?? json['tipo_vehiculo'] ?? 'Moto').toString(),
      vehiclePlate: (json['vehiclePlate'] ?? json['placa'] ?? 'MX-REP-01').toString(),
      rating: ((json['rating'] ?? 4.9) as num).toDouble(),
      totalDeliveries: ((json['totalDeliveries'] ?? json['entregas_totales'] ?? 24) as num).toInt(),
      isOnline: json['isOnline'] == true,
      currentLat: ((json['lat'] ?? 19.4194) as num).toDouble(),
      currentLng: ((json['lng'] ?? -99.1601) as num).toDouble(),
      todayEarnings: ((json['todayEarnings'] ?? 640.0) as num).toDouble(),
      todayTips: ((json['todayTips'] ?? 85.0) as num).toDouble(),
      completedToday: ((json['completedToday'] ?? 6) as num).toInt(),
    );
  }

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    return CourierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      vehicleType: json['vehicleType'] as String,
      vehiclePlate: json['vehiclePlate'] as String,
      rating: (json['rating'] as num).toDouble(),
      totalDeliveries: (json['totalDeliveries'] as num).toInt(),
      isOnline: json['isOnline'] as bool? ?? false,
      currentLat: (json['currentLat'] as num).toDouble(),
      currentLng: (json['currentLng'] as num).toDouble(),
      todayEarnings: (json['todayEarnings'] as num).toDouble(),
      todayTips: (json['todayTips'] as num).toDouble(),
      completedToday: (json['completedToday'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'vehicleType': vehicleType,
        'vehiclePlate': vehiclePlate,
        'rating': rating,
        'totalDeliveries': totalDeliveries,
        'isOnline': isOnline,
        'currentLat': currentLat,
        'currentLng': currentLng,
        'todayEarnings': todayEarnings,
        'todayTips': todayTips,
        'completedToday': completedToday,
      };
}
