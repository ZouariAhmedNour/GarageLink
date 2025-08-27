import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';


class AddVehScreen extends ConsumerStatefulWidget {
  final String clientId;
  const AddVehScreen({required this.clientId, Key? key}) : super(key: key);

  @override
  ConsumerState<AddVehScreen> createState() => _AddVehScreenState();
}

class _AddVehScreenState extends ConsumerState<AddVehScreen> {
  final _formKey = GlobalKey<FormState>();
  // Remplacé _immat par deux controllers pour le widget NumeroSerieInput
  final _vinCtrl = TextEditingController(); // pour N° de série étranger
  final _numLocalCtrl = TextEditingController(); // pour format local (ex: 250TUN1999)

  final _marque = TextEditingController();
  final _modele = TextEditingController();
  final _annee = TextEditingController();
  final _km = TextEditingController();
  final _dateCtrl = TextEditingController();

  DateTime? _dateCirculation;
  String? _picKmPath; // stocke le path local ou URL après upload
  final ImagePicker _picker = ImagePicker();

  // carburant (obligatoire dans le model)
  Carburant _selectedCarburant = Carburant.essence;

  @override
  void dispose() {
    _vinCtrl.dispose();
    _numLocalCtrl.dispose();
    _marque.dispose();
    _modele.dispose();
    _annee.dispose();
    _km.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = _dateCirculation ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5),
      helpText: 'Sélectionner la date de circulation',
    );
    if (picked != null) {
      setState(() {
        _dateCirculation = picked;
        _dateCtrl.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String? _required(String? v) => v == null || v.trim().isEmpty ? 'Obligatoire' : null;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() {
          _picKmPath = photo.path;
        });
      }
    } catch (e) {
      // erreur (permissions, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la prise de photo : $e')),
        );
      }
    }
  }

  bool _validateImmatriculation() {
    final vin = _vinCtrl.text.trim();
    final local = _numLocalCtrl.text.trim();
    return vin.isNotEmpty || local.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF357ABD);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Ajouter véhicule', style: TextStyle(color: Colors.white)),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // === Remplacement : widget de numéro de série à la place du champ immatriculation ===
              NumeroSerieInput(
                vinCtrl: _vinCtrl,
                numLocalCtrl: _numLocalCtrl,
                onChanged: (v) {
                  // onChanged peut être utilisé si tu veux réagir à la saisie
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _marque,
                decoration: const InputDecoration(labelText: 'Marque'),
                validator: _required,
              ),
              TextFormField(
                controller: _modele,
                decoration: const InputDecoration(labelText: 'Modèle'),
                validator: _required,
              ),
              const SizedBox(height: 8),
              // Carburant (radio buttons ou dropdown)
              Text('Carburant', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: Carburant.values.map((c) {
                  final label = c.toString().split('.').last; // essence, diesel...
                  return ChoiceChip(
                    label: Text(label),
                    selected: _selectedCarburant == c,
                    onSelected: (_) => setState(() => _selectedCarburant = c),
                    selectedColor: primary.withOpacity(0.15),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _annee,
                decoration: const InputDecoration(labelText: 'Année'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _km,
                decoration: const InputDecoration(labelText: 'Kilométrage'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              // Photo du compteur
              Text('Photo du compteur (optionnel)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Prendre photo'),
                    style: ElevatedButton.styleFrom(backgroundColor: primary),
                    onPressed: _takePhoto,
                  ),
                  const SizedBox(width: 12),
                  if (_picKmPath != null)
                    GestureDetector(
                      onTap: () {
                        // possibilité d'ouvrir un preview fullscreen
                        Get.to(() => ImagePreviewScreen(imagePath: _picKmPath!));
                      },
                      child: SizedBox(
                        width: 90,
                        height: 60,
                        child: Image.file(File(_picKmPath!), fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Date de circulation (readonly + date picker)
              GestureDetector(
                onTap: () => _pickDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Date de circulation',
                      hintText: 'JJ/MM/AAAA',
                    ),
                    validator: (v) {
                      return null; // facultative ; change si tu veux obligatoire
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                onPressed: () {
                  // validation custom pour immatriculation (local ou vin)
                  if (!(_formKey.currentState?.validate() ?? false)) return;

                  if (!_validateImmatriculation()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez saisir le N° local ou le N° de série (VIN).')),
                    );
                    return;
                  }

                  final immat = _numLocalCtrl.text.trim().isNotEmpty
                      ? _numLocalCtrl.text.trim()
                      : _vinCtrl.text.trim();

                  final v = Vehicule(
                    id: const Uuid().v4(),
                    immatriculation: immat,
                    marque: _marque.text.trim(),
                    modele: _modele.text.trim(),
                    carburant: _selectedCarburant,
                    annee: int.tryParse(_annee.text.trim()),
                    kilometrage: int.tryParse(_km.text.trim()),
                    picKm: _picKmPath,
                    dateCirculation: _dateCirculation,
                    clientId: widget.clientId,
                  );
                  ref.read(vehiculesProvider.notifier).addVehicule(v);
                  Get.back();
                },
                child: const Text('Ajouter véhicule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple preview screen (optionnel)
class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;
  const ImagePreviewScreen({required this.imagePath, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF357ABD)),
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}
