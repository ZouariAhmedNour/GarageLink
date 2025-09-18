import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/date_picker.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/generate_button.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_card.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_text_field.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/MecanicienScreens/ordreTravail/work_order_page.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/models/ordre.dart';
import 'package:garagelink/providers/ordres_provider.dart';
import 'package:get/get.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  // on garde le Devis passé (obligatoire)
  final Devis devis;
  const CreateOrderScreen({super.key, required this.devis});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final clientCtrl = TextEditingController();
  final vinCtrl = TextEditingController();
  final numLocalCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();

  String? mechanic;
  String? workshop;
  DateTime date = DateTime.now();
  String? service;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Pré-remplir certains champs depuis le devis passé
    clientCtrl.text = widget.devis.clientName.isNotEmpty ? widget.devis.clientName : '';
    // Si ton modèle Devis a vin/numLocal, décommente:
    // vinCtrl.text = widget.devis.vin ?? '';
    // numLocalCtrl.text = widget.devis.numLocal ?? '';

    final idToShow = widget.devis.devisId.isNotEmpty ? widget.devis.devisId : (widget.devis.id ?? '');
    descriptionCtrl.text = 'Travail lié au devis $idToShow';
  }

  @override
  void dispose() {
    _animationController.dispose();
    clientCtrl.dispose();
    vinCtrl.dispose();
    numLocalCtrl.dispose();
    descriptionCtrl.dispose();
    super.dispose();
  }

  void _onCreatePressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final tache = Tache(
      description: descriptionCtrl.text.trim().isEmpty
          ? (service ?? 'Service')
          : descriptionCtrl.text.trim(),
      serviceId: '',
      serviceNom: service ?? '',
      mecanicienId: '',
      mecanicienNom: mechanic ?? '',
      estimationHeures: 1.0,
    );

    try {
      // Utiliser l'ID du devis réel (devisId si présent sinon id)
      final String linkedDevisId = widget.devis.devisId.isNotEmpty
          ? widget.devis.devisId
          : (widget.devis.id ?? '');

      await ref.read(ordresProvider.notifier).createOrdre(
            devisId: linkedDevisId,
            dateCommence: date,
            atelierId: workshop ?? '',
            priorite: 'normale',
            description: descriptionCtrl.text.trim(),
            taches: [tache],
          );

      if (mounted) {
        // Retourner à la liste des ordres
        Get.off(() => const WorkOrderPage());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur création ordre : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Créer un ordre',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF4A90E2),
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 16,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ModernCard(
                        title: 'Informations Client',
                        icon: Icons.person,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          children: [
                            ModernTextField(
                              controller: clientCtrl,
                              label: 'Client',
                              icon: Icons.person,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Obligatoire' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ModernCard(
                        title: 'Véhicule',
                        icon: Icons.directions_car,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          children: [
                            NumeroSerieInput(
                              vinCtrl: vinCtrl,
                              numLocalCtrl: numLocalCtrl,
                              onChanged: (v) {},
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ModernCard(
                        title: 'Détails de l\'ordre',
                        icon: Icons.settings,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Service',
                                border: OutlineInputBorder(),
                              ),
                              value: service,
                              items: ['Dépannage', 'Entretien', 'Diagnostic']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => service = v),
                              validator: (v) => v == null ? "Sélectionner un service" : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Mécanicien',
                                border: OutlineInputBorder(),
                              ),
                              value: mechanic,
                              items: ['Jean Dupont', 'Marie']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => mechanic = v),
                              validator: (v) => v == null ? "Sélectionner un mécanicien" : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Atelier',
                                border: OutlineInputBorder(),
                              ),
                              value: workshop,
                              items: ['Atelier 1', 'Atelier 2']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => workshop = v),
                              validator: (v) => v == null ? "Sélectionner un atelier" : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: descriptionCtrl,
                              decoration: const InputDecoration(
                                labelText: "Description",
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? "Description obligatoire"
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            DatePicker(
                              date: date,
                              isTablet: isTablet,
                              onDateChanged: (d) => setState(() => date = d),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: GenerateButton(
                          onPressed: _submitting ? null : _onCreatePressed,
                          text: _submitting ? 'Création...' : 'Créer et retourner',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
