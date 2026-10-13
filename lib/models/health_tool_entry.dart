class HealthToolEntry {
  const HealthToolEntry({
    required this.id,
    required this.userId,
    required this.toolKey,
    required this.value,
    required this.createdAt,
  });

  final int? id;
  final String userId;
  final String toolKey;
  final String value;
  final DateTime createdAt;

  factory HealthToolEntry.fromJson(
    Map<String, dynamic> json, {
    required String userId,
    required String toolKey,
  }) => HealthToolEntry(
        id: (json['id'] as num?)?.toInt(),
        userId: userId,
        toolKey: toolKey,
        value: json['value'] as String,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now().toUtc(),
      );

}
