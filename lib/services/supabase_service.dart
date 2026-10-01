import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  final _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> getHealthUnits() async {
    final response = await _client.from('health_units').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final uid = _userId;
    if (uid == null) return [];

    final response = await _client
        .from('appointments')
        .select('*, health_units(name, address, phone)')
        .eq('user_id', uid)
        .order('appointment_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

 Future<void> bookAppointment({
  required String patientName,  
  required int healthUnitId,
  required String type,
  required DateTime date,
  required String time,
  String? notes,
}) async {
  final uid = _userId;
  if (uid == null) throw Exception('User not authenticated');

  await _client.from('appointments').insert({
    'user_id': uid,
    'patient_name': patientName, 
    'health_unit_id': healthUnitId,
    'appointment_type': type,
    'appointment_date': date.toIso8601String().split('T')[0],
    'appointment_time': time,
    'status': 'confirmed',
    'notes': notes ?? '$patientName - $type',
  });
}

  Future<void> cancelAppointment(int id) async {
    await _client.from('appointments').update({'status': 'cancelled'}).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final response = await _client.from('announcements').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> submitSymptomReport(
    Map<String, bool> symptoms,
    String severity,
    String? notes,
  ) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');

    await _client.from('symptom_reports').insert({
      'user_id': uid,
      'symptoms': symptoms.entries.where((e) => e.value).map((e) => e.key).toList(),
      'severity': severity,
      'notes': notes,
      'handled': false,
    });
  }
}