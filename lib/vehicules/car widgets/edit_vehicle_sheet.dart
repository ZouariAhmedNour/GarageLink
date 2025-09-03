import 'dart:io';
import 'package:flutter/material.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui_constants.dart';

Future<void> openEditVehicleSheet(BuildContext context, WidgetRef ref, Vehicule veh) {
  final picker = ImagePicker();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final _marqueCtrl = TextEditingController(text: veh.marque);
      final _modeleCtrl = TextEditingController(text: veh.modele);
      final _anneeCtrl = TextEditingController(text: veh.annee?.toString() ?? '');
      final _kmCtrl = TextEditingController(text: veh.kilometrage?.toString() ?? '');
      DateTime? _pickedDate = veh.dateCirculation;
      String? _localPicPath = veh.picKm;
      Carburant _selectedCarb = veh.carburant;

      return StatefulBuilder(builder: (context, setState) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 20),
                Row(children: const [Icon(Icons.edit, color: primaryBlue), SizedBox(width: 12), Text('Modifier le véhicule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBlue))]),
                const SizedBox(height: 24),
                _buildEditTextField(_marqueCtrl, 'Marque', Icons.business),
                _buildEditTextField(_modeleCtrl, 'Modèle', Icons.directions_car),
                _buildEditTextField(_anneeCtrl, 'Année', Icons.calendar_today, TextInputType.number),
                _buildEditTextField(_kmCtrl, 'Kilométrage', Icons.speed, TextInputType.number),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: const [Icon(Icons.local_gas_station, color: primaryBlue), SizedBox(width: 8), Text('Carburant', style: TextStyle(fontWeight: FontWeight.w600))]),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Carburant.values.map((c) {
                        final isSelected = _selectedCarb == c;
                        return FilterChip(
                          label: Text(carburantLabel(c)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCarb = c),
                          selectedColor: lightBlue,
                          checkmarkColor: primaryBlue,
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                  ]),
                ),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Photo'),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        try {
                          final XFile? photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 80);
                          if (photo != null) setState(() => _localPicPath = photo.path);
                        } catch (e) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Erreur photo: $e')));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_pickedDate != null ? formatDate(_pickedDate) : 'Date'),
                      style: OutlinedButton.styleFrom(foregroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: primaryBlue)),
                      onPressed: () async {
                        final picked = await showDatePicker(context: ctx, initialDate: _pickedDate ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(DateTime.now().year + 5));
                        if (picked != null) setState(() => _pickedDate = picked);
                      },
                    ),
                  ),
                ]),
                if (_localPicPath != null) ...[
                  const SizedBox(height: 16),
                  Container(height: 120, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))]), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_localPicPath!), fit: BoxFit.cover))),
                ],
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade600, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Annuler'))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        final updated = veh.copyWith(
                          marque: _marqueCtrl.text.trim(),
                          modele: _modeleCtrl.text.trim(),
                          carburant: _selectedCarb,
                          annee: int.tryParse(_anneeCtrl.text.trim()),
                          kilometrage: int.tryParse(_kmCtrl.text.trim()),
                          picKm: _localPicPath,
                          dateCirculation: _pickedDate,
                        );
                        ref.read(vehiculesProvider.notifier).updateVehicule(veh.id, updated);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Véhicule modifié avec succès'), backgroundColor: successGreen));
                      },
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        );
      });
    },
  );
}

// helper used inside this file (private to the file)
Widget _buildEditTextField(TextEditingController controller, String label, IconData icon, [TextInputType? keyboardType]) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
        filled: true,
        fillColor: surfaceColor,
      ),
    ),
  );
}
