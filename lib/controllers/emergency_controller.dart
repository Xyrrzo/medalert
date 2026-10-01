import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';

class EmergencyController extends ChangeNotifier {
  final _service = SupabaseService.instance;

  bool isSubmitting = false;
  String? confirmationMessage;

 
  Future<void> callEmergencyLine(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }


  Future<void> submitSymptoms(Map<String, bool> symptoms, String severity, String? notes) async {
    isSubmitting = true;
    confirmationMessage = null;
    notifyListeners();
    try {
      await _service.submitSymptomReport(symptoms, severity, notes);
      confirmationMessage = 'Symptom report sent to the health unit. Help is on the way.';
    } catch (e) {
      confirmationMessage = 'Could not send report, but you can still call directly.';
    }
    isSubmitting = false;
    notifyListeners();
  }
}