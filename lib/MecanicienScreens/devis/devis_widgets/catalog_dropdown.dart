import 'package:flutter/material.dart';
import 'package:garagelink/models/pieces.dart';
import 'package:garagelink/utils/format.dart';

class CatalogDropdown extends StatelessWidget {
  final Piece? selectedItem;
  final ValueChanged<Piece?> onChanged;
  final List<Piece> items;

  const CatalogDropdown({
    super.key,
    required this.selectedItem,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Piece>(
      value: selectedItem,
      isExpanded: true,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: 'Depuis le catalogue',
        prefixIcon: const Icon(Icons.inventory, color: Color(0xFF4A90E2)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      items: items.map((e) {
        final label = '${e.name} — ${Fmt.money(e.prix)}';
        return DropdownMenuItem(
          value: e,
          child: Text(label, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
