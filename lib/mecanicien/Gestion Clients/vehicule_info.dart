import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class VehiculeInfoScreen extends ConsumerWidget {
  final String vehiculeId;
  const VehiculeInfoScreen({required this.vehiculeId, Key? key})
      : super(key: key);

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 140,
              child:
                  Text('$label', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value.isNotEmpty ? value : '-')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehState = ref.watch(vehiculesProvider);
    final maybeVeh = vehState.vehicules.where((v) => v.id == vehiculeId);
    if (maybeVeh.isEmpty) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF357ABD)),
        body: const Center(child: Text('Véhicule non trouvé')),
      );
    }
    final veh = maybeVeh.first;
    final Color primary = const Color(0xFF357ABD);

    // Mock visites — remplace par ta source réelle si besoin
    final visites = [
      {'date': '12/01/2024', 'desc': 'Vidange', 'atelier': 'Atelier A'},
      {'date': '23/05/2024', 'desc': 'Révision', 'atelier': 'Atelier B'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${veh.marque} ${veh.modele}'),
        backgroundColor: primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openEditSheet(context, ref, veh),
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref, veh),
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- Card : Détails & Photo ----------------
              Card(
                elevation: 3,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Résumé en haut (image + titre)
                      Row(
                        children: [
                          Container(
                            width: 110,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade100,
                            ),
                            child: veh.picKm != null && veh.picKm!.isNotEmpty
                                ? (veh.picKm!.startsWith('http')
                                    ? Image.network(veh.picKm!, fit: BoxFit.cover)
                                    : Image.file(File(veh.picKm!), fit: BoxFit.cover))
                                : const Center(
                                    child: Icon(Icons.directions_car,
                                        size: 36, color: Colors.grey)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${veh.marque} ${veh.modele}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('Immat: ${veh.immatriculation}',
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Carburant: ${veh.carburant.toString().split('.').last}',
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      // Détails listés
                      _buildInfoRow('Immatriculation', veh.immatriculation),
                      _buildInfoRow('Marque', veh.marque),
                      _buildInfoRow('Modèle', veh.modele),
                      _buildInfoRow('Carburant', veh.carburant.toString().split('.').last),
                      _buildInfoRow('Année', veh.annee?.toString() ?? '-'),
                      _buildInfoRow('Kilométrage', veh.kilometrage?.toString() ?? '-'),
                      _buildInfoRow('Date circulation', _formatDate(veh.dateCirculation)),
                      _buildInfoRow('Client ID', veh.clientId ?? '-'),

                      const SizedBox(height: 12),

                      // Photo du compteur dans la même card (si présente)
                      const Text('Photo du compteur', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (veh.picKm != null && veh.picKm!.isNotEmpty)
                        SizedBox(
                          height: 160,
                          width: double.infinity,
                          child: veh.picKm!.startsWith('http')
                              ? Image.network(veh.picKm!, fit: BoxFit.contain)
                              : Image.file(File(veh.picKm!), fit: BoxFit.contain),
                        )
                      else
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Text('Aucune photo du compteur')),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ---------------- Card : Visites / Historique ----------------
              Card(
                elevation: 2,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Visites / Historique',
                          style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
                      const SizedBox(height: 8),
                      // Liste non-scrollable intégrée dans la card
                      ListView.builder(
                        itemCount: visites.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (ctx, i) {
                          final it = visites[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.history),
                            title: Text('${it['date']} - ${it['desc']}'),
                            subtitle: Text('${it['atelier']}'),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // bouton ajouter visite (placeholder)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter visite'),
                          onPressed: () {
                            // TODO: ouvrir un formulaire d'ajout de visite
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fonction "Ajouter visite" non implémentée')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Vehicule veh) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Supprimer le véhicule ${veh.marque} ${veh.modele} (${veh.immatriculation}) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF357ABD)),
            onPressed: () {
              ref.read(vehiculesProvider.notifier).removeVehicule(veh.id);
              Navigator.of(ctx).pop(); // fermer le dialog
              Get.back(); // revenir à la liste
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context, WidgetRef ref, Vehicule veh) {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        // controllers créés ici et utilisés dans le sheet
        final _marqueCtrl = TextEditingController(text: veh.marque);
        final _modeleCtrl = TextEditingController(text: veh.modele);
        final _anneeCtrl = TextEditingController(text: veh.annee?.toString() ?? '');
        final _kmCtrl = TextEditingController(text: veh.kilometrage?.toString() ?? '');
        DateTime? _pickedDate = veh.dateCirculation;
        String? _localPicPath = veh.picKm;
        Carburant _selectedCarb = veh.carburant;

        String formatDate(DateTime? d) {
          if (d == null) return '';
          final dd = d.day.toString().padLeft(2, '0');
          final mm = d.month.toString().padLeft(2, '0');
          final yyyy = d.year.toString();
          return '$dd/$mm/$yyyy';
        }

        Future<void> _pickDateInner() async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: ctx,
            initialDate: _pickedDate ?? now,
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) {
            _pickedDate = picked;
          }
        }

        Future<void> _takePhotoInner() async {
          try {
            final XFile? photo =
                await picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 80);
            if (photo != null) {
              _localPicPath = photo.path;
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Erreur photo: $e')));
            }
          }
        }

        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration:
                          BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(height: 12),
                    Text('Modifier véhicule',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF357ABD))),
                    const SizedBox(height: 12),
                    TextFormField(controller: _marqueCtrl, decoration: const InputDecoration(labelText: 'Marque')),
                    TextFormField(controller: _modeleCtrl, decoration: const InputDecoration(labelText: 'Modèle')),
                    const SizedBox(height: 8),
                    // carburant chips
                    Wrap(
                      spacing: 8,
                      children: Carburant.values.map((c) {
                        final label = c.toString().split('.').last;
                        return ChoiceChip(
                          label: Text(label),
                          selected: _selectedCarb == c,
                          onSelected: (_) => setState(() => _selectedCarb = c),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(controller: _anneeCtrl, decoration: const InputDecoration(labelText: 'Année'), keyboardType: TextInputType.number),
                    TextFormField(controller: _kmCtrl, decoration: const InputDecoration(labelText: 'Kilométrage'), keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Prendre / remplacer photo'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF357ABD)),
                          onPressed: () async {
                            await _takePhotoInner();
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        if (_localPicPath != null)
                          SizedBox(width: 80, height: 60, child: Image.file(File(_localPicPath!), fit: BoxFit.cover)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_pickedDate != null ? formatDate(_pickedDate) : 'Date circulation'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black),
                          onPressed: () async {
                            await _pickDateInner();
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            _pickedDate = null;
                            setState(() {});
                          },
                          child: const Text('Supprimer date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF357ABD)),
                            onPressed: () {
                              // build updated vehicle
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
                              Navigator.of(context).pop(); // close sheet
                            },
                            child: const Text('Enregistrer'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}
