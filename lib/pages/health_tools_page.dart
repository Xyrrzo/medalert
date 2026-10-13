import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/health_tool_entry.dart';
import '../services/health_records_service.dart';

/// A collection of lightweight, account-synced tools for everyday health tracking.
class HealthToolsPage extends StatefulWidget {
  const HealthToolsPage({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<HealthToolsPage> createState() => _HealthToolsPageState();
}

class _HealthToolsPageState extends State<HealthToolsPage> {
  final _records = HealthRecordsService.instance;
  Map<String, String> _profiles = {};
  Map<String, List<HealthToolEntry>> _entries = {};
  bool _loadingRecords = true;
  String? _recordsError;
  int _water = 0;

  static const _tools = <_HealthTool>[
    _HealthTool('bmi', 'BMI calculator', Icons.monitor_weight_outlined, 'Estimate body mass index from height and weight.'),
    _HealthTool('water', 'Water tracker', Icons.water_drop_outlined, 'Track glasses of water today.'),
    _HealthTool('weight', 'Weight log', Icons.scale_outlined, 'Keep a dated record of your weight.'),
    _HealthTool('blood_pressure', 'Blood pressure log', Icons.favorite_outline, 'Record a blood pressure reading.'),
    _HealthTool('glucose', 'Blood sugar log', Icons.bloodtype_outlined, 'Record a glucose reading and context.'),
    _HealthTool('temperature', 'Temperature log', Icons.thermostat_outlined, 'Keep track of temperature readings.'),
    _HealthTool('pulse', 'Pulse log', Icons.monitor_heart_outlined, 'Record your pulse in beats per minute.'),
    _HealthTool('allergies', 'Allergy profile', Icons.warning_amber_outlined, 'Keep important allergy information handy.'),
    _HealthTool('conditions', 'Conditions list', Icons.medical_information_outlined, 'Save conditions to discuss with your care team.'),
    _HealthTool('blood_type', 'Blood type', Icons.bloodtype, 'Store your blood type for quick reference.'),
    _HealthTool('emergency_contact', 'Emergency contact', Icons.contact_phone_outlined, 'Save a person responders can contact.'),
    _HealthTool('symptoms', 'Symptom diary', Icons.edit_note, 'Note symptoms, when they started, and changes.'),
    _HealthTool('first_aid', 'First aid guide', Icons.health_and_safety_outlined, 'Review basic steps while seeking professional help.'),
    _HealthTool('pregnancy', 'Due date estimator', Icons.child_friendly_outlined, 'Estimate a due date from the last period date.'),
    _HealthTool('vaccines', 'Vaccine record', Icons.vaccines_outlined, 'Keep a personal note of vaccinations and dates.'),
    _HealthTool('health_notes', 'Health notes', Icons.note_alt_outlined, 'Keep general notes for your next visit.'),
    _HealthTool('visit_checklist', 'Visit checklist', Icons.checklist_outlined, 'Prepare questions and items for an appointment.'),
    _HealthTool('medicine_stock', 'Medicine stock', Icons.medication_outlined, 'Note medicine quantities and refill needs.'),
    _HealthTool('health_goals', 'Health goals', Icons.flag_outlined, 'Write down a goal to review over time.'),
    _HealthTool('health_summary', 'Copy health summary', Icons.content_copy_outlined, 'Copy your saved health notes to the clipboard.'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadRecords();
    });
  }

  String _waterKey(DateTime date) => 'water_${date.year}_${date.month}_${date.day}';

  Future<void> _loadRecords() async {
    setState(() {
      _loadingRecords = true;
      _recordsError = null;
    });
    try {
      final snapshot = await _records.load();
      if (!mounted) return;
      final todayWater = int.tryParse(snapshot.profiles[_waterKey(DateTime.now())] ?? '') ?? 0;
      setState(() {
        _profiles = snapshot.profiles;
        _entries = snapshot.entries;
        _water = todayWater;
        _loadingRecords = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _recordsError = _friendlyError(error);
        _loadingRecords = false;
      });
    }
  }

  Future<bool> _saveProfile(String key, String value) async {
    try {
      await _records.saveProfile(key, value);
      return true;
    } catch (error) {
      _showSaveError(error);
      return false;
    }
  }

  Future<bool> _addRecord(String key, String value) async {
    try {
      await _records.addEntry(key, value);
      return true;
    } catch (error) {
      _showSaveError(error);
      return false;
    }
  }

  void _applyProfile(String key, String value) {
    if (!mounted) return;
    setState(() {
      if (value.isEmpty) {
        _profiles.remove(key);
      } else {
        _profiles[key] = value;
      }
    });
  }

  void _applyEntry(String key, String value) {
    if (!mounted) return;
    setState(() {
      final entry = HealthToolEntry(
        id: null,
        userId: '',
        toolKey: key,
        value: value,
        createdAt: DateTime.now().toUtc(),
      );
      _entries = {..._entries, key: [entry, ...?_entries[key]]};
    });
  }

  void _showSaveError(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save record. ${_friendlyError(error)}')),
      );
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('user_health_profiles') ||
        message.contains('user_health_entries') ||
        message.contains('health_data') ||
        message.contains('schema cache') ||
        message.contains('does not exist')) {
      return 'Add a JSONB health_data column to the profiles table in Supabase Table Editor, then retry.';
    }
    if (message.contains('timed out')) return 'Supabase did not respond in time. Check your connection and retry.';
    if (message.contains('sign in')) return 'Sign in again to load your health records.';
    return 'Please check your connection and try again.';
  }

  List<String> _recentEntries(String key) => (_entries[key] ?? const <HealthToolEntry>[])
      .take(5)
      .map((row) {
        final date = row.createdAt.toLocal();
        final dateLabel = ' • ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return '${row.value}$dateLabel';
      })
      .toList();

  String? _latestEntry(String key) {
    final rows = _entries[key];
    if (rows == null || rows.isEmpty) return null;
    return rows.first.value;
  }

  Future<void> _openTool(_HealthTool tool) async {
    if (tool.id == 'weight') {
      await _editWeightLog();
      return;
    }
    if (tool.id == 'water') {
      await _showWaterTracker();
      return;
    }
    if (tool.id == 'first_aid') {
      await _showFirstAid();
      return;
    }
    if (tool.id == 'health_summary') {
      await _copySummary();
      return;
    }
    if (tool.id == 'bmi') {
      await _showBmi();
      return;
    }
    if (tool.id == 'pregnancy') {
      await _showDueDate();
      return;
    }
    await _editNote(tool);
  }

  Future<void> _showWaterTracker() async {
    final now = DateTime.now();
    final key = _waterKey(now);
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Water tracker'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.water_drop, size: 44, color: Colors.blue),
            const SizedBox(height: 8),
            Text('$_water glasses today', style: Theme.of(dialogContext).textTheme.titleLarge),
            if (saving) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            const SizedBox(height: 16),
            Wrap(spacing: 8, children: [
              OutlinedButton.icon(
                onPressed: _water == 0 || saving ? null : () async {
                  setDialogState(() => saving = true);
                  final count = _water > 0 ? _water - 1 : 0;
                  final saved = await _saveProfile(key, count.toString());
                  if (!dialogContext.mounted) return;
                  setDialogState(() => saving = false);
                  if (!saved) return;
                  _applyProfile(key, count.toString());
                  if (mounted) setState(() => _water = count);
                },
                icon: const Icon(Icons.remove), label: const Text('Undo glass'),
              ),
              FilledButton.icon(
                onPressed: saving ? null : () async {
                  setDialogState(() => saving = true);
                  final count = _water + 1;
                  final saved = await _saveProfile(key, count.toString());
                  if (!dialogContext.mounted) return;
                  setDialogState(() => saving = false);
                  if (!saved) return;
                  _applyProfile(key, count.toString());
                  if (mounted) setState(() => _water = count);
                },
                icon: const Icon(Icons.add), label: const Text('Add glass'),
              ),
            ]),
          ]),
          actions: [FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Done'))],
        ),
      ),
    );
  }

  Future<void> _editWeightLog() async {
    final controller = TextEditingController();
    final entries = _recentEntries('weight');
    String? savedValue;
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Weight log'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'e.g. 68.5',
                border: OutlineInputBorder(),
              ),
            ),
            if (saving) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Recent entries', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(entry),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: saving ? null : () async {
              final weight = double.tryParse(controller.text.trim().replaceAll(',', '.'));
              if (weight == null || weight <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Enter a valid weight in kilograms.')),
                );
                return;
              }
              setDialogState(() => saving = true);
              final value = '${weight.toString()} kg';
              final success = await _addRecord('weight', value);
              if (!dialogContext.mounted) return;
              setDialogState(() => saving = false);
              if (success) {
                savedValue = value;
                Navigator.of(dialogContext).pop(true);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add entry'),
          ),
        ],
        ),
      ),
    );
    controller.dispose();
    if (saved == true && mounted) {
      _applyEntry('weight', savedValue!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight entry saved.')),
      );
    }
  }

  Future<void> _editNote(_HealthTool tool) async {
    final isLog = const {'blood_pressure', 'glucose', 'temperature', 'pulse', 'symptoms', 'vaccines'}.contains(tool.id);
    final entries = _recentEntries(tool.id);
    final controller = TextEditingController(text: isLog ? '' : (_profiles[tool.id] ?? ''));
    String? savedValue;
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(tool.title),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              enabled: !saving,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(hintText: _hintFor(tool.id), border: const OutlineInputBorder()),
            ),
            if (saving) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            if (isLog && entries.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Recent entries', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              for (final entry in entries)
                Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(entry)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Close')),
          FilledButton(
            onPressed: saving ? null : () async {
              final value = controller.text.trim();
              if (isLog && value.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Enter a value before adding the entry.')));
                return;
              }
              setDialogState(() => saving = true);
              final success = isLog
                  ? await _addRecord(tool.id, value)
                  : await _saveProfile(tool.id, value);
              if (!dialogContext.mounted) return;
              setDialogState(() => saving = false);
              if (success) {
                savedValue = value;
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: Text(isLog ? 'Add entry' : 'Save'),
          ),
        ],
        ),
      ),
    );
    controller.dispose();
    if (saved == true && mounted) {
      if (isLog) {
        _applyEntry(tool.id, savedValue!);
      } else {
        _applyProfile(tool.id, savedValue!);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isLog ? 'Entry saved.' : 'Saved ${tool.title.toLowerCase()}.')));
    }
  }

  String _hintFor(String id) => switch (id) {
        'weight' => 'e.g. 68 kg — ${DateTime.now().toLocal().toString().split(' ').first}',
        'blood_pressure' => 'e.g. 120/80 mmHg, date and time',
        'glucose' => 'e.g. 5.5 mmol/L, fasting or after a meal',
        'temperature' => 'e.g. 36.8 °C, date and time',
        'pulse' => 'e.g. 72 bpm, at rest',
        'allergies' => 'Allergen and reaction, if known',
        'conditions' => 'Condition and any details you want to remember',
        'blood_type' => 'e.g. O+',
        'emergency_contact' => 'Name and phone number',
        'symptoms' => 'What you feel, when it started, and how it changes',
        'vaccines' => 'Vaccine and date received',
        'health_notes' => 'Notes to remember',
        'visit_checklist' => 'Questions, documents, or items to bring',
        'medicine_stock' => 'Medicine, remaining quantity, refill date',
        'health_goals' => 'A goal and target date',
        _ => 'Add a note',
      };

  Future<void> _showBmi() async {
    final height = TextEditingController();
    final weight = TextEditingController();
    String? result;
    String? savedValue;
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('BMI calculator'),
        scrollable: true,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(enabled: !saving, controller: height, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Height (cm)')),
          TextField(enabled: !saving, controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Weight (kg)')),
          if (result != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(result!, style: const TextStyle(fontWeight: FontWeight.bold))),
          if (saving) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          const Padding(padding: EdgeInsets.only(top: 12), child: Text('BMI is a rough screening measure, not a diagnosis.', style: TextStyle(fontSize: 12))),
        ]),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')), FilledButton(onPressed: saving ? null : () async {
          final h = double.tryParse(height.text.replaceAll(',', '.'));
          final w = double.tryParse(weight.text.replaceAll(',', '.'));
          if (h == null || w == null || h <= 0 || w <= 0) {
            setDialogState(() => result = 'Enter a valid height and weight.');
            return;
          }
          final bmi = w / ((h / 100) * (h / 100));
          final value = 'BMI ${bmi.toStringAsFixed(1)} • ${h.toString()} cm • ${w.toString()} kg';
          setDialogState(() => saving = true);
          final saved = await _addRecord('bmi', value);
          if (!dialogContext.mounted) return;
          setDialogState(() {
            saving = false;
            result = saved ? 'BMI: ${bmi.toStringAsFixed(1)} (saved to your records)' : 'Could not save this result.';
          });
          if (saved) savedValue = value;
        }, child: const Text('Calculate'))],
      )),
    );
    height.dispose();
    weight.dispose();
    if (savedValue != null) _applyEntry('bmi', savedValue);
  }

  Future<void> _showDueDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
    if (picked == null || !mounted) return;
    final due = picked.add(const Duration(days: 280));
    final periodDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    final dueDate = '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}';
    final value = 'Last period: $periodDate • Estimated due date: $dueDate';
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Estimated due date'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${due.day}/${due.month}/${due.year}\n\nThis estimate uses 280 days from the first day of the last menstrual period. A health professional can provide a more accurate estimate.'),
              if (saving) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Close')),
              FilledButton(onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                final success = await _addRecord('pregnancy', value);
                if (!dialogContext.mounted) return;
                setDialogState(() => saving = false);
                if (success) Navigator.of(dialogContext).pop(true);
              }, child: const Text('Save date')),
            ],
        ),
      ),
    );
    if (saved == true && mounted) {
      _applyEntry('pregnancy', value);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Due date saved.')));
    }
  }

  Future<void> _showFirstAid() => showDialog<void>(context: context, builder: (context) => AlertDialog(
    title: const Text('Basic first aid'),
    content: const SingleChildScrollView(child: Text('Call your local emergency number for severe or life-threatening symptoms.\n\nUnresponsive and not breathing normally: call emergency services, start CPR if trained, and follow the dispatcher’s instructions.\n\nSevere bleeding: apply firm, continuous pressure with clean cloth or gauze and seek urgent care.\n\nBurn: cool under clean, cool running water for 20 minutes; do not apply ice or creams.\n\nChoking, chest pain, difficulty breathing, or stroke signs need immediate emergency help. This guide is not a substitute for professional care.')),
    actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
  ));

  Future<void> _copySummary() async {
    final lines = <String>['MedAlert personal health notes'];
    for (final tool in _tools.where((t) => !{'water', 'first_aid', 'health_summary'}.contains(t.id))) {
      final value = _profiles[tool.id] ?? _latestEntry(tool.id);
      if (value != null && value.isNotEmpty) lines.add('${tool.title}: $value');
    }
    final water = _profiles[_waterKey(DateTime.now())];
    if (water != null) lines.add('Water today: $water glasses');
    for (final tool in _tools.where((t) => const {'weight', 'blood_pressure', 'glucose', 'temperature', 'pulse', 'symptoms', 'vaccines'}.contains(t.id))) {
      final history = _recentEntries(tool.id);
      if (history.isNotEmpty) lines.add('${tool.title} history:\n${history.join('\n')}');
    }
    try {
      await Clipboard.setData(ClipboardData(text: lines.join('\n')));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved health notes copied to clipboard.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not copy the summary on this device.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.showAppBar ? AppBar(title: const Text('Health Tools')) : null,
        body: _loadingRecords
            ? const Center(child: CircularProgressIndicator())
            : _recordsError != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Your health records could not be loaded.'),
                      const SizedBox(height: 8),
                      Text(_recordsError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 12),
                      FilledButton.icon(onPressed: _loadRecords, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ]),
                  ))
                : ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)), child: const Text('Track everyday details and keep notes for your care team. Your records are saved to your signed-in account.', style: TextStyle(fontSize: 14))),
              const SizedBox(height: 12),
              for (final tool in _tools)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(tool.icon)),
                    title: Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(tool.id == 'water' ? '$_water glasses today • Tap to update' : (tool.id == 'health_summary' || tool.id == 'first_aid') ? tool.description : (_profiles[tool.id] ?? _latestEntry(tool.id) ?? tool.description), maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openTool(tool),
                  ),
                ),
            ],
          ),
      );
}

class _HealthTool {
  const _HealthTool(this.id, this.title, this.icon, this.description);
  final String id;
  final String title;
  final IconData icon;
  final String description;
}
