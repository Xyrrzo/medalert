class HealthUnit {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String openTime;
  final String closeTime;
  final bool isOpen;

  HealthUnit({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
  });

  factory HealthUnit.fromJson(Map<String, dynamic> json) => HealthUnit(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        phone: json['phone'],
        openTime: json['open_time'] ?? '08:00',
        closeTime: json['close_time'] ?? '17:00',
        isOpen: json['is_open'] ?? false,
      );
}