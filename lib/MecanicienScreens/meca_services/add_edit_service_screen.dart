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
  ConsumerState<AddEditServiceScreen> createState() =>
      _AddEditServiceScreenState();
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

  Future<bool> _confirmUpdate(BuildContext ctx, String currentName) async {
    final res = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirmer la modification'),
        content: Text('Voulez-vous vraiment modifier le service "$currentName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF357ABD)),
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    final name = nomCtrl.text.trim();
    final description = descCtrl.text.trim();
    final statut = actif ? ServiceStatut.actif : ServiceStatut.desactive;

    if (widget.service != null) {
      final confirmed = await _confirmUpdate(context, widget.service!.name);
      if (!confirmed) return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final notifier = ref.read(serviceProvider.notifier);
      if (widget.service == null) {
        await notifier.createService(
          name: name,
          description: description,
          statut: statut,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service créé avec succès'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final idToUse = widget.service!.id;
        if (idToUse == null || idToUse.isEmpty) {
          throw Exception(
              'ID du service manquant — impossible de mettre à jour.');
        }
        await notifier.updateService(
          id: idToUse,
          name: name,
          description: description,
          statut: statut,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service mis à jour avec succès'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde : $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.service != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true, // Important: permet le redimensionnement
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? 'Modifier service' : 'Nouveau service',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF357ABD),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: nomCtrl,
                          label: 'Nom du service',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Le nom est requis'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: descCtrl,
                          label: 'Description',
                          maxLines: 4,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'La description est requise'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Statut: ',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(actif ? 'Actif' : 'Désactivé'),
                              backgroundColor: actif
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.red.withOpacity(0.12),
                            ),
                            const Spacer(),
                            Switch(
                              value: actif,
                              onChanged: (v) => setState(() => actif = v),
                              activeColor: const Color(0xFF357ABD),
                            ),
                          ],
                        ),
                        // Espacement supplémentaire pour éviter que le contenu soit caché par le clavier
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bouton fixe en bas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF357ABD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEditing ? 'Sauvegarder' : 'Créer le service',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}