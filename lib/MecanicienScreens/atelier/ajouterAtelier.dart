// lib/MecanicienScreens/atelier/ajouterAtelierScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/atelier_provider.dart';
import 'package:get/get.dart';

class AjouterAtelierScreen extends ConsumerStatefulWidget {
  const AjouterAtelierScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AjouterAtelierScreen> createState() => _AjouterAtelierScreenState();
}

class _AjouterAtelierScreenState extends ConsumerState<AjouterAtelierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _localisationCtrl = TextEditingController();

  static const Color primaryBlue = Color(0xFF357ABD);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _localisationCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // on utilise l'indicateur de chargement du provider
    final notifier = ref.read(ateliersProvider.notifier);

    try {
      final atelier = await notifier.create(
        name: _nameCtrl.text.trim(),
        localisation: _localisationCtrl.text.trim(),
      );

      if (atelier != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atelier créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        // Retourne true pour indiquer au caller de rafraîchir la liste
        Get.back(result: true);
        return;
      } else {
        // provider a géré l'erreur et rempli state.error probablement
        final state = ref.read(ateliersProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Échec création atelier'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(ateliersProvider);
    final isLoading = providerState.loading;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryBlue,
        elevation: 0,
        title:
         const Text('Ajouter un atelier',
         style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          ),
          ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 36 : 16, vertical: 20),
          child: Column(
            children: [
              // Header card avec gradient & icône stylisée
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, Color(0xFF4A90E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    // cercle bleu avec icône blanche
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.business, color: primaryBlue),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Nouvel atelier', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text('Ajouter un atelier au garage', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Formulaire
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nom
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Nom de l\'atelier',
                          prefixIcon: const Icon(Icons.business_center, color: primaryBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                      ),
                      const SizedBox(height: 16),

                      // Localisation
                      TextFormField(
                        controller: _localisationCtrl,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Localisation',
                          prefixIcon: const Icon(Icons.location_on, color: primaryBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Localisation obligatoire' : null,
                      ),
                      const SizedBox(height: 20),

                      // Boutons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: primaryBlue.withOpacity(0.12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Annuler', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              child: isLoading
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Info / Aide
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Color(0xFF374151)),
                        SizedBox(width: 10),
                        Expanded(child: Text('Les ateliers seront affichés dans votre tableau de bord et pourront être sélectionnés lors de la création d\'ordres.')),
                      ],
                    ),
                    if (providerState.error != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(providerState.error!, style: const TextStyle(color: Colors.red))),
                        ],
                      )
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
