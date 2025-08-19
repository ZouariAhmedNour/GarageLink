import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/date_picker.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/generate_button.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/modern_card.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/modern_text_field.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/models/order.dart';
import 'package:garagelink/providers/orders_provider.dart';
import 'package:garagelink/mecanicien/work order/work_order_page.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final clientCtrl = TextEditingController();
  final vinCtrl = TextEditingController();
  final numLocalCtrl = TextEditingController();
  String? mechanic;
  String? workshop;
  DateTime date = DateTime.now();
  String? service;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    clientCtrl.dispose();
    vinCtrl.dispose();
    numLocalCtrl.dispose();
    super.dispose();
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
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
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16, vertical: 16),
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
                              validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null,
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
                            DropdownButton<String>(
                              hint: const Text('Sélectionner un service'),
                              value: service,
                              items: ['Dépannage', 'Entretien', 'Diagnostic']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => service = v),
                            ),
                            const SizedBox(height: 16),
                            DropdownButton<String>(
                              hint: const Text('Sélectionner un mécanicien'),
                              value: mechanic,
                              items: ['Jean Dupont', 'Marie'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (v) => setState(() => mechanic = v),
                            ),
                            const SizedBox(height: 16),
                            DropdownButton<String>(
                              hint: const Text('Sélectionner un atelier'),
                              value: workshop,
                              items: ['Atelier 1', 'Atelier 2'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (v) => setState(() => workshop = v),
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
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ref.read(ordersProvider.notifier).addOrder(
                                    WorkOrder(
                                      id: "WO-${DateTime.now().millisecondsSinceEpoch}",
                                      client: clientCtrl.text,
                                      phone: "0000000000",
                                      email: "azouari00@gmail.com",
                                      mechanic: mechanic ?? 'N/A',
                                      workshop: workshop ?? 'N/A',
                                      date: date,
                                      status: "En attente",
                                      vin: vinCtrl.text.isNotEmpty ? vinCtrl.text : numLocalCtrl.text,
                                      service: service ?? 'N/A',
                                    ),
                                  );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const WorkOrderPage()),
                              );
                            }
                          },
                          text: 'Créer et retourner',
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