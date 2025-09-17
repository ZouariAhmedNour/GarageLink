// mecanicien/meca_services/add_edit_service_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/service.dart';
import 'package:garagelink/providers/service_provider.dart';

class AddEditServiceScreen extends ConsumerStatefulWidget {
  final Service? service;
  const AddEditServiceScreen({super.key, this.service});

  @override
  ConsumerState<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends ConsumerState<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  bool actif = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      // Remplir avec les champs réels du modèle Service
      nomCtrl.text = widget.service!.name;
      descCtrl.text = widget.service!.description;
      actif = widget.service!.statut == ServiceStatut.actif;
    }
  }

  @override
  void dispose() {
    nomCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final name = nomCtrl.text.trim();
    final description = descCtrl.text.trim();
    final statut = actif ? ServiceStatut.actif : ServiceStatut.desactive;

    try {
      final notifier = ref.read(serviceProvider.notifier);

      if (widget.service == null) {
        // Création via provider -> createService (réseau)
        await notifier.createService(
          name: name,
          description: description,
          statut: statut,
        );
      } else {
        // Mise à jour : utiliser l'id MongoDB si présent sinon serviceId
        final idToUse = widget.service!.id ?? widget.service!.serviceId;
        await notifier.updateService(
          id: idToUse,
          name: name,
          description: description,
          statut: statut,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.service != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? 'Modifier service' : 'Nouveau service',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF357ABD),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: nomCtrl,
                    label: 'Nom du service',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: descCtrl,
                    label: 'Description',
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'La description est requise' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Statut: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(actif ? 'Actif' : 'Désactivé'),
                        backgroundColor:
                            actif ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                      ),
                      const Spacer(),
                      Switch(
                        value: actif,
                        onChanged: (v) => setState(() => actif = v),
                        activeColor: const Color(0xFF357ABD),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveService,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF357ABD)),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditing ? 'Sauvegarder' : 'Créer le service',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
