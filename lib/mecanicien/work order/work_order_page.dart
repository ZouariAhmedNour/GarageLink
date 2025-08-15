import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/date_picker.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/generate_button.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/modern_card.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/modern_text_field.dart';

class WorkOrderPage extends ConsumerStatefulWidget {
  const WorkOrderPage({super.key});

  @override
  ConsumerState<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends ConsumerState<WorkOrderPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedWorkshop = 'Atelier 1';
  String? _selectedMechanic = 'Jean Dupont';
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _workOrders = [
    {'id': 'WO-001', 'client': 'Jean Dupont', 'mechanic': 'Marie', 'workshop': 'Atelier 2', 'date': DateTime(2025, 8, 16, 9, 0), 'status': 'En cours'},
    {'id': 'WO-002', 'client': 'Pierre Martin', 'mechanic': 'Jean', 'workshop': 'Atelier 1', 'date': DateTime(2025, 8, 17, 10, 0), 'status': 'En attente'},
  ];

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
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Ordres de travail',
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModernCard(
                    title: 'Filtres',
                    icon: Icons.filter_list,
                    borderColor: const Color(0xFF4A90E2),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedWorkshop,
                            items: ['Atelier 1', 'Atelier 2'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedWorkshop = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedMechanic,
                            items: ['Jean Dupont', 'Marie'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedMechanic = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DatePicker(
                            date: _selectedDate,
                            isTablet: isTablet,
                            onDateChanged: (d) => setState(() => _selectedDate = d),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ModernCard(
                    title: 'Liste des ordres',
                    icon: Icons.list_alt,
                    borderColor: const Color(0xFF4A90E2),
                    child: Column(
                      children: [
                        ..._workOrders.map((wo) => ListTile(
                              title: Text('${wo['id']} - ${wo['client']}'),
                              subtitle: Text(
                                'Mécanicien: ${wo['mechanic']}  •  Atelier: ${wo['workshop']}  •  ${wo['date'].toString().substring(0, 16)}',
                              ),
                              trailing: Chip(
                                label: Text(wo['status']),
                                backgroundColor: wo['status'] == 'En attente'
                                    ? Colors.blue[100]
                                    : wo['status'] == 'En cours'
                                        ? Colors.yellow[100]
                                        : Colors.green[100],
                              ),
                              onTap: () {
                                // Navigate to edit/details screen
                              },
                            )),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GenerateButton(
                            onPressed: () {
                              // Open new work order form
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Nouvel ordre de travail'),
                                  content: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ModernTextField(
                                          controller: TextEditingController(),
                                          label: 'Client',
                                          icon: Icons.person,
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButton<String>(
                                          items: ['Jean Dupont', 'Marie'].map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {},
                                          hint: const Text('Sélectionner un mécanicien'),
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButton<String>(
                                          items: ['Atelier 1', 'Atelier 2'].map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {},
                                          hint: const Text('Sélectionner un atelier'),
                                        ),
                                        const SizedBox(height: 16),
                                        DatePicker(
                                          date: DateTime.now(),
                                          isTablet: isTablet,
                                          onDateChanged: (d) {},
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    GenerateButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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