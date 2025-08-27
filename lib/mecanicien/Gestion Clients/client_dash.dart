import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/mecanicien/Gestion%20Clients/add_client.dart';
import 'package:garagelink/mecanicien/Gestion%20Clients/add_veh.dart';
import 'package:garagelink/mecanicien/Gestion%20Clients/vehicule_info.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/models/client.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/client_provider.dart';
import 'package:garagelink/providers/orders_provider.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ClientDash extends ConsumerStatefulWidget {
  const ClientDash({Key? key}) : super(key: key);

  @override
  ConsumerState<ClientDash> createState() => _ClientDashState();
}
enum TypeFiltre { nom, immatriculation, periode }

class _ClientDashState extends ConsumerState<ClientDash> {
  final Color primary = const Color(0xFF357ABD);
   int selectedIndex = 0; // 0 = Nom, 1 = Immatriculation, 2 = Période
  String nomFilter = '';
  String immatFilter = '';
  DateTimeRange? dateRangeFilter;
  final vinCtrl = TextEditingController();
  final numLocalCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(clientsProvider);
    final vehState = ref.watch(vehiculesProvider);
    final ordersState = ref.watch(ordersProvider);

       // ✅ Filtrage
    final filtered = clientsState.clients.where((c) {
      bool matches = true;

      if (selectedIndex == 0) {
        matches = nomFilter.isEmpty ||
            c.nomComplet.toLowerCase().contains(nomFilter.toLowerCase());
      } else if (selectedIndex == 1) {
        matches = immatFilter.isEmpty ||
            c.vehiculeIds.any(
              (vid) => vid.toLowerCase().contains(immatFilter.toLowerCase()),
            );
      } else if (selectedIndex == 2) {
        final clientOrders =
            ordersState.where((o) => o.clientId == c.id).toList();
        matches = dateRangeFilter == null ||
            clientOrders.any(
              (o) =>
                  o.date.isAfter(
                      dateRangeFilter!.start.subtract(const Duration(days: 1))) &&
                  o.date.isBefore(
                      dateRangeFilter!.end.add(const Duration(days: 1))),
            );
      }

      return matches;
    }).toList();

     
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text('Clients',
         style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primary,
        elevation: 4,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () => Get.to(() => const AddClientScreen()),
        child: const Icon(Icons.add, color: Colors.white,),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔹 Filtre avec ToggleButtons
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    ToggleButtons(
                      isSelected: [
                        selectedIndex == 0,
                        selectedIndex == 1,
                        selectedIndex == 2,
                      ],
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: Colors.white,
                      fillColor: primary,
                      onPressed: (index) {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Nom"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Immatriculation"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Période"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 🔹 Zone de saisie dynamique selon le filtre choisi
                    if (selectedIndex == 0)
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Filtrer par nom',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (v) => setState(() => nomFilter = v),
                      ),

                    if (selectedIndex == 1)
                      NumeroSerieInput(
                        vinCtrl: vinCtrl,
                        numLocalCtrl: numLocalCtrl,
                        onChanged: (val) =>
                            setState(() => immatFilter = val),
                      ),

                    if (selectedIndex == 2)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                dateRangeFilter == null
                                    ? 'Filtrer par période'
                                    : '${DateFormat('dd/MM/yyyy').format(dateRangeFilter!.start)} - ${DateFormat('dd/MM/yyyy').format(dateRangeFilter!.end)}',
                              ),
                              onPressed: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  initialDateRange: dateRangeFilter,
                                );
                                if (picked != null) {
                                  setState(() => dateRangeFilter = picked);
                                }
                              },
                            ),
                          ),
                          if (dateRangeFilter != null)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: () =>
                                  setState(() => dateRangeFilter = null),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Liste des clients filtrés
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text("Aucun client trouvé"))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final c = filtered[idx];
                        final clientVeh = vehState.vehicules
                            .where((v) => v.clientId == c.id)
                            .toList();
                        return ClientCard(client: c, vehicules: clientVeh);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientCard extends ConsumerStatefulWidget {
  final Client client;
  final List<Vehicule> vehicules;
  const ClientCard({required this.client, required this.vehicules, Key? key})
    : super(key: key);

  @override
  ConsumerState<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends ConsumerState<ClientCard> {
  bool expanded = false;
  final Color primary = const Color(0xFF357ABD);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: primary.withOpacity(0.1),
                child: widget.client.categorie == Categorie.particulier
                    ? const Icon(Icons.person, color: Colors.blue)
                    : const Icon(Icons.business, color: Colors.green),
              ),
              title: Text(
                widget.client.nomComplet,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(widget.client.telephone),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Get.toNamed(
                        AppRoutes.editClientScreen,
                        arguments: widget.client,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Confirmer la suppression"),
                          content: const Text(
                            "Voulez-vous vraiment supprimer ce client ?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Annuler"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Supprimer"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          ref
                              .read(clientsProvider.notifier)
                              .removeClient(widget.client.id);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Client supprimé avec succès"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Erreur lors de la suppression"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                    onPressed: () => setState(() => expanded = !expanded),
                  ),
                ],
              ),
            ),

            if (expanded)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${widget.client.mail}'),
                    Text('Adresse: ${widget.client.adresse}'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Véhicules',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // navigator vers add veh avec client id
                            Get.to(
                              () => AddVehScreen(clientId: widget.client.id),
                            );
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: widget.vehicules
                          .map(
                            (v) => GestureDetector(
                              onTap: () => Get.to(
                                () => VehiculeInfoScreen(vehiculeId: v.id),
                              ),
                              child: Chip(
                                label: Text(
                                  '${v.marque} ${v.modele}\n${v.immatriculation}',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
