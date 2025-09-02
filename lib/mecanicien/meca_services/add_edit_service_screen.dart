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
      nomCtrl.text = widget.service!.nomService;
      descCtrl.text = widget.service!.description;
      actif = widget.service!.status == ServiceStatus.actif;
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

    try {
      final newService = Service(
        id: widget.service?.id ?? 'SVC-${DateTime.now().millisecondsSinceEpoch}',
        nomService: nomCtrl.text.trim(),
        description: descCtrl.text.trim(),
        status: actif ? ServiceStatus.actif : ServiceStatus.inactif,
      );

      if (widget.service == null) {
        ref.read(serviceProvider.notifier).addService(newService);
      } else {
        ref.read(serviceProvider.notifier).updateService(newService);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde')),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.service == null ? 'Nouveau service' : 'Modifier service', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                        label: Text(actif ? 'Actif' : 'Inactif'),
                        backgroundColor: actif ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
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
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.service == null ? 'Créer le service' : 'Sauvegarder', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
