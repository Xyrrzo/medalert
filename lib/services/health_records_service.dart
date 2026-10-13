import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_tool_entry.dart';
import '../models/health_tool_profile.dart';

/// Reads and writes personal Health Tools data scoped to the signed-in user.
class HealthRecordsService {
  HealthRecordsService._();
  static final instance = HealthRecordsService._();

  final _client = Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in to access your health records.');
    return id;
  }

  Future<HealthRecordsSnapshot> load() async {
    final uid = _userId;
    final row = await _client.from('profiles').select('health_data').eq('id', uid).maybeSingle()
        .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Loading health records timed out'));
    if (row == null) throw StateError('No profile exists for the signed-in user.');
    final rawData = row['health_data'];
    final data = rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};
    final profiles = <String, String>{};
    final entries = <String, List<HealthToolEntry>>{};
    for (final item in data.entries) {
      if (item.value is List) {
        final rows = (item.value as List)
            .whereType<Map>()
            .map((row) => HealthToolEntry.fromJson(
                  Map<String, dynamic>.from(row),
                  userId: uid,
                  toolKey: item.key,
                ))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        entries[item.key] = rows;
      } else {
        final profile = HealthToolProfile.fromJson(item.key, item.value);
        profiles[profile.toolKey] = profile.value;
      }
    }
    return HealthRecordsSnapshot(profiles: profiles, entries: entries);
  }

  Future<void> saveProfile(String key, String value) async {
    await _updateHealthData((data) {
      if (value.isEmpty) {
        data.remove(key);
      } else {
        data[key] = value;
      }
    });
  }

  Future<HealthToolEntry> addEntry(String key, String value) async {
    final uid = _userId;
    final createdAt = DateTime.now().toUtc();
    await _updateHealthData((data) {
      final current = data[key];
      final entries = current is List ? List<dynamic>.from(current) : <dynamic>[];
      entries.add({'value': value, 'created_at': createdAt.toIso8601String()});
      data[key] = entries;
    });
    return HealthToolEntry(id: null, userId: uid, toolKey: key, value: value, createdAt: createdAt);
  }

  Future<void> _updateHealthData(void Function(Map<String, dynamic>) change) async {
    final uid = _userId;
    final row = await _client.from('profiles').select('health_data').eq('id', uid).single()
        .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Loading health records timed out'));
    final raw = row['health_data'];
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    change(data);
    await _client.from('profiles').update({'health_data': data}).eq('id', uid)
        .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Saving health records timed out'));
  }
}

class HealthRecordsSnapshot {
  const HealthRecordsSnapshot({required this.profiles, required this.entries});
  final Map<String, String> profiles;
  final Map<String, List<HealthToolEntry>> entries;
}
