class BranchModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  final int activeOrdersCount;
  final bool isOpen;

  BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.activeOrdersCount,
    required this.isOpen,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      activeOrdersCount: (json['activeOrdersCount'] as num).toInt(),
      isOpen: json['isOpen'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'lat': lat,
        'lng': lng,
        'activeOrdersCount': activeOrdersCount,
        'isOpen': isOpen,
      };
}
