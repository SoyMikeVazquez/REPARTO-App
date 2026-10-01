class RouteStopModel {
  final int sequenceIndex;
  final String orderId;
  final String type; // 'pickup' | 'delivery'
  final String title;
  final String recipientOrSender;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  final String estimatedArrival;
  final double distanceKm;
  final bool isCompleted;
  final String? notes;

  RouteStopModel({
    required this.sequenceIndex,
    required this.orderId,
    required this.type,
    required this.title,
    required this.recipientOrSender,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.estimatedArrival,
    required this.distanceKm,
    this.isCompleted = false,
    this.notes,
  });

  RouteStopModel copyWith({
    bool? isCompleted,
  }) {
    return RouteStopModel(
      sequenceIndex: sequenceIndex,
      orderId: orderId,
      type: type,
      title: title,
      recipientOrSender: recipientOrSender,
      address: address,
      phone: phone,
      lat: lat,
      lng: lng,
      estimatedArrival: estimatedArrival,
      distanceKm: distanceKm,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes,
    );
  }

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      sequenceIndex: (json['sequenceIndex'] as num).toInt(),
      orderId: json['orderId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      recipientOrSender: json['recipientOrSender'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      estimatedArrival: json['estimatedArrival'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'sequenceIndex': sequenceIndex,
        'orderId': orderId,
        'type': type,
        'title': title,
        'recipientOrSender': recipientOrSender,
        'address': address,
        'phone': phone,
        'lat': lat,
        'lng': lng,
        'estimatedArrival': estimatedArrival,
        'distanceKm': distanceKm,
        'isCompleted': isCompleted,
        'notes': notes,
      };
}
