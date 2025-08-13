import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/meca_services/service_card.dart';
import 'package:garagelink/providers/service_provider.dart';

class MecaServicesPage extends ConsumerStatefulWidget {
  const MecaServicesPage({super.key});

  @override
  ConsumerState<MecaServicesPage> createState() => _MecaServicesPageState();
}

class _MecaServicesPageState extends ConsumerState<MecaServicesPage> {
  String searchTerm = '';
  String selectedCategory = '';
  final categories = ['Entretien', 'Révision', 'Freinage', 'Électricité', 'Carrosserie'];

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(serviceProvider);
    final filtered = services.where((s) =>
      (s.nom.toLowerCase().contains(searchTerm.toLowerCase()) ||
       s.description.toLowerCase().contains(searchTerm.toLowerCase())) &&
      (selectedCategory.isEmpty || s.categorie == selectedCategory)
    ).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion Services')),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => searchTerm = v),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedCategory.isEmpty ? null : selectedCategory,
                  hint: const Text('Catégorie'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Toutes')),
                    ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() => selectedCategory = v ?? ''),
                ),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 1.3,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final service = filtered[index];
                return ServiceCard(
                  service: service,
                  onEdit: () {
                    // TODO: ouvrir le dialog d’édition
                  },
                  onDelete: () {
                    ref.read(serviceProvider.notifier).deleteService(service.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
