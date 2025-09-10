import 'package:flutter/material.dart';
import 'package:garagelink/MecanicienScreens/devis/models/catalogItem.dart';

import 'package:garagelink/utils/format.dart';

class CatalogDropdown extends StatelessWidget {
  final CatalogItem? selectedItem;
  final ValueChanged<CatalogItem?> onChanged;

  const CatalogDropdown({
    super.key,
    required this.selectedItem,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CatalogItem>(
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
  items: kCatalog.map(
    (e) => DropdownMenuItem(
      value: e,
      child: Text(
        '${e.nom} — ${Fmt.money(e.prixUnitaire)}',
        overflow: TextOverflow.ellipsis, // ajoute une troncature si texte trop long
      ),
    ),
  ).toList(),
  onChanged: onChanged,
);
  }
}