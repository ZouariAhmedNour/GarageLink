import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:garagelink/vehicules/car%20widgets/ui_constants.dart';
import 'package:image_picker/image_picker.dart';

Future<void> openEditVehicleSheet(BuildContext context, WidgetRef ref, Vehicule veh) {
  final picker = ImagePicker();

  // Controllers et états locaux créés ici pour pouvoir les disposer après fermeture
  final _marqueCtrl = TextEditingController(text: veh.marque);
  final _modeleCtrl = TextEditingController(text: veh.modele);
  final _anneeCtrl = TextEditingController(text: veh.annee?.toString() ?? '');
  final _kmCtrl = TextEditingController(text: veh.kilometrage?.toString() ?? '');
  String? _localPicPath = veh.picKm;
  final List<String> _localImages = List.from(veh.images);
  FuelType _selectedFuelType = veh.typeCarburant;
  final _formKey = GlobalKey<FormState>();

  final future = showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(builder: (BuildContext innerContext, void Function(void Function()) setState) {
        String? _requiredValidator(String? v) =>
            v == null || v.trim().isEmpty ? 'Ce champ est obligatoire' : null;

        String? _yearValidator(String? v) {
          if (v == null || v.isEmpty) return null;
          final year = int.tryParse(v);
          if (year == null) return 'Année invalide';
          final currentYear = DateTime.now().year;
          if (year < 1900 || year > currentYear + 1) {
            return 'Année entre 1900 et ${currentYear + 1}';
          }
          return null;
        }

        String? _kmValidator(String? v) {
          if (v == null || v.isEmpty) return null;
          final km = int.tryParse(v);
          if (km == null) return 'Kilométrage invalide';
          if (km < 0 || km > 999999) return 'Kilométrage entre 0 et 999 999 km';
          return null;
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: const [
                      Icon(Icons.edit, color: primaryBlue),
                      SizedBox(width: 12),
                      Text(
                        'Modifier le véhicule',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildEditTextField(_marqueCtrl, 'Marque', Icons.business, validator: _requiredValidator),
                        _buildEditTextField(_modeleCtrl, 'Modèle', Icons.directions_car, validator: _requiredValidator),
                        _buildEditTextField(
                          _anneeCtrl,
                          'Année',
                          Icons.calendar_today,
                          keyboardType: TextInputType.number,
                          validator: _yearValidator,
                        ),
                        _buildEditTextField(
                          _kmCtrl,
                          'Kilométrage',
                          Icons.speed,
                          keyboardType: TextInputType.number,
                          validator: _kmValidator,
                        ),

                        // Carburant
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.local_gas_station, color: primaryBlue),
                                  SizedBox(width: 8),
                                  Text('Carburant', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: FuelType.values.map((fuelType) {
                                  final isSelected = _selectedFuelType == fuelType;
                                  return FilterChip(
                                    label: Text(fuelTypeLabel(fuelType)),
                                    selected: isSelected,
                                    onSelected: (selected) => setState(() => _selectedFuelType = fuelType),
                                    selectedColor: lightBlue,
                                    checkmarkColor: primaryBlue,
                                    backgroundColor: Colors.grey.shade100,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        // Photo principale
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Photo principale'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  try {
                                    final XFile? photo = await picker.pickImage(
                                      source: ImageSource.camera,
                                      maxWidth: 1600,
                                      imageQuality: 80,
                                    );
                                    if (photo != null) {
                                      setState(() => _localPicPath = photo.path);
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(innerContext).showSnackBar(
                                      SnackBar(content: Text('Erreur photo: $e')),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        // Photo principale preview
                        if (_localPicPath != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _localPicPath!.startsWith('http')
                                  ? Image.network(_localPicPath!, fit: BoxFit.cover)
                                  : Image.file(File(_localPicPath!), fit: BoxFit.cover),
                            ),
                          ),
                        ],

                        // Ajouter photos supplémentaires
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Ajouter photos'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  try {
                                    final List<XFile>? photos = await picker.pickMultiImage(
                                      maxWidth: 1600,
                                      imageQuality: 80,
                                    );
                                    if (photos != null && photos.isNotEmpty) {
                                      setState(() {
                                        _localImages.addAll(photos.map((p) => p.path));
                                      });
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(innerContext).showSnackBar(
                                      SnackBar(content: Text('Erreur photos: $e')),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        // Preview images supplémentaires
                        if (_localImages.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _localImages.length,
                              itemBuilder: (context, index) {
                                final imagePath = _localImages[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: imagePath.startsWith('http')
                                              ? Image.network(imagePath, fit: BoxFit.cover)
                                              : Image.file(File(imagePath), fit: BoxFit.cover),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => setState(() => _localImages.removeAt(index)),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Boutons Action
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(innerContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade600,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Annuler'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  if (!(_formKey.currentState?.validate() ?? false)) {
                                    ScaffoldMessenger.of(innerContext).showSnackBar(
                                      const SnackBar(content: Text('Veuillez corriger les erreurs'), backgroundColor: errorRed),
                                    );
                                    return;
                                  }
                                  if (veh.id == null || veh.id!.isEmpty) {
                                    ScaffoldMessenger.of(innerContext).showSnackBar(
                                      const SnackBar(content: Text('ID véhicule manquant'), backgroundColor: errorRed),
                                    );
                                    return;
                                  }

                                  try {
                                    await ref.read(vehiculesProvider.notifier).updateVehicule(
                                          id: veh.id!,
                                          marque: _marqueCtrl.text.trim(),
                                          modele: _modeleCtrl.text.trim(),
                                          typeCarburant: _selectedFuelType,
                                          annee: int.tryParse(_anneeCtrl.text.trim()),
                                          kilometrage: int.tryParse(_kmCtrl.text.trim()),
                                          picKm: _localPicPath,
                                          images: _localImages,
                                        );

                                    Navigator.of(innerContext).pop();
                                    ScaffoldMessenger.of(innerContext).showSnackBar(
                                      const SnackBar(
                                        content: Text('Véhicule modifié avec succès'),
                                        backgroundColor: successGreen,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(innerContext).showSnackBar(
                                      SnackBar(content: Text('Erreur: $e'), backgroundColor: errorRed),
                                    );
                                  }
                                },
                                child: const Text('Enregistrer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );

  // Disposer les controllers quand la sheet est fermée
  future.whenComplete(() {
    _marqueCtrl.dispose();
    _modeleCtrl.dispose();
    _anneeCtrl.dispose();
    _kmCtrl.dispose();
  });

  return future;
}

Widget _buildEditTextField(
  TextEditingController controller,
  String label,
  IconData icon, {
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorRed, width: 2)),
        filled: true,
        fillColor: surfaceColor,
      ),
    ),
  );
}
