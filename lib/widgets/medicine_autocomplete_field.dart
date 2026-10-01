import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api/medicine_api_service.dart';


class MedicineAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  const MedicineAutocompleteField({super.key, required this.controller});

  @override
  State<MedicineAutocompleteField> createState() => _MedicineAutocompleteFieldState();
}

class _MedicineAutocompleteFieldState extends State<MedicineAutocompleteField> {
  final _api = MedicineApiService.instance;
  List<String> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loading = true);
      final results = await _api.suggest(value);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: 'Medicine / vaccine name',
            prefixIcon: const Icon(Icons.medication),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _suggestions
                  .take(5)
                  .map(
                    (s) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.medication_liquid, size: 18, color: Colors.grey),
                      title: Text(s, style: const TextStyle(fontSize: 14)),
                      onTap: () {
                        widget.controller.text = s;
                        setState(() => _suggestions = []);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
