import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/health_unit.dart';
import '../services/supabase_service.dart';

class AppointmentController extends ChangeNotifier {
  final _service = SupabaseService.instance;

  List<Appointment> appointments = [];
  List<HealthUnit> healthUnits = [];
  bool isLoading = false;
  String? error;

  Future<void> loadData() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final rawUnits = await _service.getHealthUnits();
      healthUnits = rawUnits.map(HealthUnit.fromJson).toList();
      final rawAppts = await _service.getAppointments();
      appointments = rawAppts.map(Appointment.fromJson).toList();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> book({
    required String patientName,
    required int healthUnitId,
    required String type,
    required DateTime date,
    required TimeOfDay time,
    String? notes,
  }) async {
   try {
  
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    await _service.bookAppointment(
      patientName: patientName,
      healthUnitId: healthUnitId,
      type: type,
      date: date,
      time: timeStr,
      notes: notes,
    
      );
      await loadData();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _service.cancelAppointment(id);
      await loadData();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}