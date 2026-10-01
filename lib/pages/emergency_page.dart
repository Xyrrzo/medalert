import 'package:flutter/material.dart';
import '../controllers/emergency_controller.dart';
import '../utils/constants.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final _controller = EmergencyController();

  
  static const String healthUnitHotline = '09171234567';
  static const String barangayEmergencyLine = '911';

  final Map<String, bool> _symptoms = {
    'Fever': false,
    'Difficulty breathing': false,
    'Chest pain': false,
    'Bleeding / injury': false,
    'Dizziness / fainting': false,
  };
  String _severity = 'mild';
  final _notesCtrl = TextEditingController();

  Future<void> _sos() async {
    final anyChecked = _symptoms.values.any((v) => v);
    if (anyChecked) {
      await _controller.submitSymptoms(_symptoms, _severity, _notesCtrl.text);
    }
    if (!mounted) return;
    await _controller.callEmergencyLine(healthUnitHotline);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_controller.confirmationMessage != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_controller.confirmationMessage!),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'In an emergency, tap the button below. You may fill in your symptoms first so responders can triage faster.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _controller.isSubmitting ? null : _sos,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: AppConstants.gradientBox(radius: 95).copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.redPrimary.withOpacity(0.5),
                        blurRadius: 32,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('SOS',
                        style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Quick symptom check (optional):', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._symptoms.keys.map(
              (k) => CheckboxListTile(
                dense: true,
                activeColor: AppConstants.redPrimary,
                title: Text(k),
                value: _symptoms[k],
                onChanged: (v) => setState(() => _symptoms[k] = v ?? false),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()),
              items: const ['mild', 'moderate', 'severe']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                  .toList(),
              onChanged: (v) => setState(() => _severity = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Additional notes', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.redPrimary,
                side: const BorderSide(color: AppConstants.redPrimary),
              ),
              onPressed: () => _controller.callEmergencyLine(barangayEmergencyLine),
              icon: const Icon(Icons.call),
              label: const Text('Call Barangay Emergency Line'),
            ),
          ],
        );
      },
    );
  }
}