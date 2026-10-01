import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../services/supabase_service.dart';

class AnnouncementController extends ChangeNotifier {
  final _service = SupabaseService.instance;

  List<Announcement> announcements = [];
  bool isLoading = false;
  String? error;

  Future<void> loadAnnouncements() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final raw = await _service.getAnnouncements();
      announcements = raw.map(Announcement.fromJson).toList();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}