class HealthToolProfile {
  const HealthToolProfile({required this.toolKey, required this.value});

  final String toolKey;
  final String value;

  factory HealthToolProfile.fromJson(String toolKey, Object? json) =>
      HealthToolProfile(toolKey: toolKey, value: json?.toString() ?? '');
}
