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
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadData() async {
    if (_disposed) return;
    isLoading = true;
    error = null;
    _notify();
    try {
      final rawUnits = await _service.getHealthUnits();
      if (_disposed) return;
      healthUnits = rawUnits.map(HealthUnit.fromJson).toList();
      final rawAppts = await _service.getAppointments();
      if (_disposed) return;
      appointments = rawAppts.map(Appointment.fromJson).toList();
    } catch (_) {
      if (_disposed) return;
      error = 'Your request could not be completed. Check your access and try again.';
    }
    isLoading = false;
    _notify();
  }

  Future<bool> book({
    required String patientName,
    required int healthUnitId,
    required String type,
    required DateTime date,
    required TimeOfDay time,
    String? notes,
  }) async {
   if (_disposed) return false;
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
      if (_disposed) return true;
      await loadData();
      return true;
    } catch (e) {
      if (_disposed) return false;
      error = 'Appointment could not be booked: $e';
      _notify();
      return false;
    }
  }

  Future<bool> cancel(int id) async {
    if (_disposed) return false;
    try {
      await _service.cancelAppointment(id);
      if (_disposed) return true;
      await loadData();
      return error == null;
    } catch (e) {
      if (_disposed) return false;
      error = e.toString();
      _notify();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
