import 'package:flutter/material.dart';

class ModernDureePicker extends StatelessWidget {
  final Duration value;
  final ValueChanged<Duration> onChanged;

  const ModernDureePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hours = value.inHours;
    final minutes = value.inMinutes % 60;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Durée estimée',
          prefixIcon: const Icon(Icons.timer, color: Color(0xFFFF8C00)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                isExpanded: true,
                value: hours,
                items: List.generate(
                  24,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text('$i h', style: const TextStyle(fontSize: 14)),
                  ),
                ),
                onChanged: (h) => onChanged(Duration(hours: h ?? 0, minutes: minutes)),
                underline: const SizedBox.shrink(),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<int>(
                isExpanded: true,
                value: minutes,
                items: const [0, 15, 30, 45]
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text('$m min', style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (m) => onChanged(Duration(hours: hours, minutes: m ?? 0)),
                underline: const SizedBox.shrink(),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}