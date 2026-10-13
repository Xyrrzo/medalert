import 'package:supabase_flutter/supabase_flutter.dart';

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
    final result = await Future.wait([
      _client.from('user_health_profiles').select('tool_key, value').eq('user_id', uid),
      _client.from('user_health_entries').select('tool_key, value, created_at').eq('user_id', uid).order('created_at', ascending: false),
    ]);
    final profiles = <String, String>{};
    for (final row in List<Map<String, dynamic>>.from(result[0])) {
      profiles[row['tool_key'] as String] = row['value'] as String;
    }
    final entries = <String, List<Map<String, dynamic>>>{};
    for (final row in List<Map<String, dynamic>>.from(result[1])) {
      (entries[row['tool_key'] as String] ??= []).add(row);
    }
    return HealthRecordsSnapshot(profiles: profiles, entries: entries);
  }

  Future<void> saveProfile(String key, String value) async {
    final uid = _userId;
    if (value.isEmpty) {
      await _client.from('user_health_profiles').delete().eq('user_id', uid).eq('tool_key', key);
      return;
    }
    await _client.from('user_health_profiles').upsert({
      'user_id': uid,
      'tool_key': key,
      'value': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,tool_key');
  }

  Future<void> addEntry(String key, String value) async {
    await _client.from('user_health_entries').insert({
      'user_id': _userId,
      'tool_key': key,
      'value': value,
    });
  }
}

class HealthRecordsSnapshot {
  const HealthRecordsSnapshot({required this.profiles, required this.entries});
  final Map<String, String> profiles;
  final Map<String, List<Map<String, dynamic>>> entries;
}
