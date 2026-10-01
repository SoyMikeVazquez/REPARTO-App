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
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    double? todayEarnings,
    double? todayTips,
    int? completedToday,
    int? totalDeliveries,
  }) {
    return CourierModel(
      id: id,
      name: name,
      phone: phone,
      email: email,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      rating: rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isOnline: isOnline ?? this.isOnline,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayTips: todayTips ?? this.todayTips,
      completedToday: completedToday ?? this.completedToday,
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
