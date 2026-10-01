import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';

class ReminderController extends ChangeNotifier {
  final _client = Supabase.instance.client;
  
  List<Reminder> reminders = [];
  bool isLoading = false;
  String? error;

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      reminders = [];
      notifyListeners();
      return;
    }
    
    isLoading = true;
    notifyListeners();
    
    try {
      final response = await _client
          .from('reminders')
          .select()
          .eq('user_id', uid)
          .order('remind_at');
      
      reminders = (response as List)
          .map((json) => Reminder.fromJson(json))
          .toList();
      
      
      for (final r in reminders.where((r) => !r.isDone)) {
        await NotificationService.instance.scheduleDaily(
          r.id,
          title: '💊 MedAlert — ${r.title}',
          body: 'Time for your ${r.title}',
          hour: r.hour,
          minute: r.minute,
        );
      }
    } catch (e) {
      error = e.toString();
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<bool> add({
    required String title,
    required String type,
    required TimeOfDay time,
  }) async {
    final uid = _userId;
    if (uid == null) {
      error = 'You must be logged in';
      notifyListeners();
      return false;
    }
    
    try {
      
      final now = DateTime.now();
      final remindAt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      
      final response = await _client.from('reminders').insert({
        'user_id': uid,
        'title': title,
        'reminder_type': type,
        'remind_at': remindAt.toIso8601String(),
        'is_done': false,
      }).select();
      
      if (response.isNotEmpty) {
        final reminder = Reminder.fromJson(response[0]);
        reminders.add(reminder);
        
        await NotificationService.instance.scheduleDaily(
          reminder.id,
          title: '💊 MedAlert — ${reminder.title}',
          body: 'Time for your ${reminder.title}',
          hour: reminder.hour,
          minute: reminder.minute,
        );
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleDone(Reminder reminder) async {
    try {
      await _client
          .from('reminders')
          .update({'is_done': !reminder.isDone})
          .eq('id', reminder.id);
      
      final index = reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        reminders[index] = Reminder(
          id: reminder.id,
          title: reminder.title,
          type: reminder.type,
          hour: reminder.hour,
          minute: reminder.minute,
          isDone: !reminder.isDone,
        );
        
        if (reminders[index].isDone) {
          await NotificationService.instance.cancel(reminder.id);
        } else {
          await NotificationService.instance.scheduleDaily(
            reminder.id,
            title: '💊 MedAlert — ${reminder.title}',
            body: 'Time for your ${reminder.title}',
            hour: reminder.hour,
            minute: reminder.minute,
          );
        }
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> remove(Reminder reminder) async {
    try {
      await _client.from('reminders').delete().eq('id', reminder.id);
      await NotificationService.instance.cancel(reminder.id);
      reminders.removeWhere((r) => r.id == reminder.id);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}