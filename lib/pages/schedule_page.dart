import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/appointment_controller.dart';
import '../utils/constants.dart';
import '../widgets/appointment_card.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _controller = AppointmentController();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedType = AppConstants.appointmentTypes.first;
  String _statusFilter = 'all';
  int? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _controller.loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmCancel(int appointmentId) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Cancel appointment?'),
      content: const Text('The appointment will be marked as cancelled.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel appointment'))],
    ));
    if (confirmed != true || !mounted) return;
    final cancelled = await _controller.cancel(appointmentId);
    if (!mounted) return;
    if (!cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.error ?? 'The appointment could not be cancelled.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  Future<void> _book() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the patient name.')),
      );
      return;
    }
    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a health unit.')),
      );
      return;
    }

    final ok = await _controller.book(
      patientName: _nameCtrl.text.trim(),
      healthUnitId: _selectedUnitId!,
      type: _selectedType,
      date: _selectedDate,
      time: _selectedTime,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment request submitted. It is pending staff review.')),
      );
      _nameCtrl.clear();
      _notesCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${_controller.error ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Book a Checkup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Patient name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(labelText: 'Appointment type', border: OutlineInputBorder()),
                    items: AppConstants.appointmentTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedUnitId,
                    decoration: const InputDecoration(labelText: 'Health unit', border: OutlineInputBorder()),
                    items: _controller.healthUnits
                        .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnitId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule),
                          label: Text(_selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _controller.isLoading ? null : _book,
                      icon: const Icon(Icons.check),
                      label: const Text('Book Appointment'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final status in ['all', 'pending', 'confirmed', 'completed', 'rejected', 'cancelled']) Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(status == 'all' ? 'All' : status[0].toUpperCase() + status.substring(1)), selected: _statusFilter == status, onSelected: (_) => setState(() => _statusFilter = status)))]))),
            if (_controller.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Text('Error: ${_controller.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _controller.loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_controller.appointments.where((a) => _statusFilter == 'all' || a.status == _statusFilter).isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No appointments match this filter.')),
              )
            else
              ..._controller.appointments.where((a) => _statusFilter == 'all' || a.status == _statusFilter).map(
                (a) => AppointmentCard(
                  appointment: a,
                  onCancel: !{'pending', 'confirmed'}.contains(a.status)
                      ? null
                      : () => _confirmCancel(a.id),
                ),
              ),
          ],
        );
      },
    );
  }
}
