import 'package:flutter/material.dart';

class AppDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final String? error;
  final ValueChanged<String> onChanged;

  const AppDropdownField({
    super.key,
    required this.label,
    this.value,
    required this.hint,
    required this.items,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // Dropdown
        DropdownButtonFormField<String>(
          value: (value?.isEmpty ?? true) ? null : value,
          hint: Text(hint),
          items: items,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Error
        if (error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}
