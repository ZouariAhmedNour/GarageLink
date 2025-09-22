// lib/MecanicienScreens/ateliers/modifier_atelier_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:garagelink/models/atelier.dart';
import 'package:garagelink/providers/atelier_provider.dart';

class ModifierAtelierScreen extends ConsumerStatefulWidget {
  final Atelier atelier;
  const ModifierAtelierScreen({Key? key, required this.atelier}) : super(key: key);

  @override
  ConsumerState<ModifierAtelierScreen> createState() => _ModifierAtelierScreenState();
}

class _ModifierAtelierScreenState extends ConsumerState<ModifierAtelierScreen> with TickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF357ABD);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _localisationCtrl;
  bool _localSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.atelier.name);
    _localisationCtrl = TextEditingController(text: widget.atelier.localisation);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _localisationCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Use local submitting flag to control the button immediately
    setState(() => _localSubmitting = true);

    final notifier = ref.read(ateliersProvider.notifier);

    try {
      final updated = await notifier.update(
        id: widget.atelier.id ?? '',
        name: _nameCtrl.text.trim(),
        localisation: _localisationCtrl.text.trim(),
      );

      if (updated != null) {
        // Optionally reload list in background (not strictly necessary if notifier already updated cache)
        await ref.read(ateliersProvider.notifier).loadAll();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atelier modifié avec succès'), backgroundColor: Colors.green),
        );
        // Return true so calling screen can refresh if needed
        Get.back(result: true);
      } else {
        final err = ref.read(ateliersProvider).error;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la modification : ${err ?? "inconnue"}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification : ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _localSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ateliersProvider);
    final isLoading = state.loading || _localSubmitting;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FB),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Modifier Atelier', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 36 : 16, vertical: 20),
        child: Column(
          children: [
            // Header card with stylized icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFF7FBFF)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
                border: Border.all(color: const Color(0xFFE6EEF8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [primaryBlue, primaryBlue]),
                      boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Center(child: Icon(Icons.storefront, color: Colors.white, size: 30)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.atelier.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF102035))),
                        const SizedBox(height: 6),
                        Text(widget.atelier.localisation, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Form card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nom de l\'atelier',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                    ),
                    const SizedBox(height: 12),

                    // Localisation
                    TextFormField(
                      controller: _localisationCtrl,
                      decoration: InputDecoration(
                        labelText: 'Localisation',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Localisation obligatoire' : null,
                    ),
                    const SizedBox(height: 16),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Optional: show provider error
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(state.error!, style: const TextStyle(color: Colors.redAccent)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
