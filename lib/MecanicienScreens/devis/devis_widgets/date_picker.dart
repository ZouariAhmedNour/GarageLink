import 'package:flutter/material.dart';
import 'package:garagelink/utils/format.dart';

class DatePicker extends StatelessWidget {
  final DateTime date;
  final bool isTablet;
  final ValueChanged<DateTime> onDateChanged;

  const DatePicker({
    super.key,
    required this.date,
    required this.isTablet,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: const Color(0xFF4A90E2)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Date: ${Fmt.date(date)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: date,
                locale: const Locale('fr'),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF4A90E2),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (d != null) {
                onDateChanged(d);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.edit_calendar, size: 16),
            label: const Text('Modifier'),
          ),
        ],
      ),
    );
  }
}