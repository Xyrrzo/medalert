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

  Future<List<Map<String, dynamic>>> getAllAppointments() async {
    final response = await _client.from('appointments').select('*, health_units(name, address, phone)').order('appointment_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateAppointmentStatus(int id, String status) async {
    await _client.from('appointments').update({'status': status}).eq('id', id);
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
    'status': 'pending',
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
      'symptoms': symptoms.entries.where((e) => e.value).map((e) => e.key).join(', '),
      'severity': severity,
      'notes': notes,
      'handled': false,
    });
  }

  Future<List<Map<String, dynamic>>> getSymptomReports() async {
    final response = await _client.from('symptom_reports').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, int>> getStaffOverview() async {
    final results = await Future.wait([
      _client.from('appointments').select('id, status, appointment_date'),
      _client.from('symptom_reports').select('id, severity, handled'),
      _client.from('health_units').select('id, is_open'),
      _client.from('announcements').select('id'),
    ]);
    final appointments = List<Map<String, dynamic>>.from(results[0]);
    final reports = List<Map<String, dynamic>>.from(results[1]);
    final units = List<Map<String, dynamic>>.from(results[2]);
    final announcements = List<Map<String, dynamic>>.from(results[3]);
    final unhandled = reports.where((row) => row['handled'] != true).toList();
    final today = DateTime.now().toIso8601String().split('T').first;
    return {
      'pendingAppointments': appointments.where((row) => row['status'] == 'pending').length,
      'appointmentsToday': appointments.where((row) => row['appointment_date']?.toString() == today).length,
      'confirmedAppointments': appointments.where((row) => row['status'] == 'confirmed').length,
      'unhandledReports': unhandled.length,
      'criticalReports': unhandled.where((row) => const {'critical', 'severe'}.contains(row['severity']?.toString().toLowerCase())).length,
      'openHealthUnits': units.where((row) => row['is_open'] == true).length,
      'announcements': announcements.length,
    };
  }

  Future<void> markSymptomReportHandled(int id, bool handled) async {
    await _client.from('symptom_reports').update({'handled': handled}).eq('id', id);
  }

  Future<void> createAnnouncement({required String title, required String body, required String category}) async {
    await _client.from('announcements').insert({'title': title, 'body': body, 'category': category});
  }

  Future<List<Map<String, dynamic>>> getProfiles() async {
    final response = await _client.from('profiles').select('id, full_name, role, created_at').order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateProfileRole(String id, String role) async {
    await _client.from('profiles').update({'role': role}).eq('id', id);
  }

  Future<void> saveHealthUnit({int? id, required String name, required String address, required String phone, required bool isOpen}) async {
    final values = {'name': name, 'address': address, 'phone': phone, 'is_open': isOpen};
    if (id == null) { await _client.from('health_units').insert(values); }
    else { await _client.from('health_units').update(values).eq('id', id); }
  }

  Future<void> setHealthUnitOpen(int id, bool isOpen) async {
    await _client.from('health_units').update({'is_open': isOpen}).eq('id', id);
  }
}
