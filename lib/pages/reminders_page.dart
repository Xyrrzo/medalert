import 'package:flutter/material.dart';
import '../controllers/reminder_controller.dart';
import '../utils/constants.dart';
import '../widgets/medicine_autocomplete_field.dart';


class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _controller = ReminderController();
  final _titleCtrl = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  String _type = 'medication';

  static const _types = ['medication', 'vaccine', 'followup'];

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _add() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medicine name.')),
      );
      return;
    }
    final ok = await _controller.add(
      title: _titleCtrl.text.trim(),
      type: _type,
      time: _time,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Reminder set — you will be notified daily at ${_time.format(context)}.' : 'Failed to save reminder.')),
    );
    if (ok) _titleCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppConstants.gradientBox(),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medicine Schedule',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Type a medicine name for suggestions, pick a time, get daily reminders.',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MedicineAutocompleteField(controller: _titleCtrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: _types
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.replaceAll('_', ' ').toUpperCase())))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.redPrimary,
                      side: const BorderSide(color: AppConstants.redPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _controller.isLoading ? null : _add,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Set Daily Reminder'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('My Reminders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_controller.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.reminders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No reminders yet. Add your first medicine above.')),
              )
            else
              ..._controller.reminders.map((r) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: CheckboxListTile(
                      activeColor: AppConstants.redPrimary,
                      value: r.isDone,
                      onChanged: (_) => _controller.toggleDone(r),
                      title: Text(
                        r.title,
                        style: TextStyle(
                          decoration: r.isDone ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('${r.type.replaceAll('_', ' ').toUpperCase()} • Daily at ${r.timeLabel}'),
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () => _controller.remove(r),
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }
}
