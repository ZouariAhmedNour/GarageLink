import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/clients_liste/add_client.dart';
import 'package:garagelink/mecanicien/clients_liste/add_veh.dart';
import 'package:garagelink/mecanicien/clients_liste/vehicule_info.dart';
import 'package:garagelink/models/client.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/client_provider.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:get/get.dart';


class ClientDash extends ConsumerStatefulWidget {
  const ClientDash({Key? key}) : super(key: key);

  @override
  ConsumerState<ClientDash> createState() => _ClientDashState();
}

class _ClientDashState extends ConsumerState<ClientDash> {
  final Color primary = const Color(0xFF357ABD);
  String nomFilter = '';
  String immatFilter = '';

  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(clientsProvider);
    final vehState = ref.watch(vehiculesProvider);

    final filtered = clientsState.clients.where((c) {
      final matchesNom =
          nomFilter.isEmpty ||
          c.nomComplet.toLowerCase().contains(nomFilter.toLowerCase());
      final matchesImmat =
          immatFilter.isEmpty ||
          c.vehiculeIds.any(
            (vid) => vid.toLowerCase().contains(immatFilter.toLowerCase()),
          );
      return matchesNom && matchesImmat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        backgroundColor: primary,
        elevation: 4,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () => Get.to(() => const AddClientScreen()),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // filtres
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Filtrer par nom'),
                    onChanged: (v) => setState(() => nomFilter = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Filtrer par immatriculation',
                    ),
                    onChanged: (v) => setState(() => immatFilter = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
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

class ClientCard extends StatefulWidget {
  final Client client;
  final List<Vehicule> vehicules;
  const ClientCard({required this.client, required this.vehicules, Key? key})
    : super(key: key);

  @override
  State<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard> {
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
                child: Text(
                  widget.client.nomComplet.isNotEmpty
                      ? widget.client.nomComplet[0]
                      : '?',
                ),
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
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: ouvrir screen modification
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
