import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/client_provider.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:garagelink/models/client.dart';
import 'package:garagelink/configurations/app_routes.dart';

class ClientVehiclesScreen extends ConsumerWidget {
  const ClientVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = Get.arguments;
    final clientId = arg is String ? arg : null;

    if (clientId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Véhicules du client')),
        body: const Center(child: Text('Aucun client sélectionné')),
      );
    }

    // Récupère l'état courant
    final vehiculesState = ref.watch(vehiculesProvider);
    // Liste filtrée
    final vehicules = vehiculesState.vehicules.where((v) => v.clientId == clientId).toList();

    final clientsState = ref.watch(clientsProvider);
    final client = clientsState.clients.firstWhere(
      (c) => c.id == clientId,
      orElse: () => Client(
        id: clientId,
        nomComplet: 'Client inconnu',
        mail: '',
        telephone: '',
        adresse: '',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Véhicules — ${client.nomComplet}'),
        backgroundColor: const Color(0xFF357ABD),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: vehicules.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.directions_car, size: 56, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Aucun véhicule associé à ce client.'),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: vehicules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final v = vehicules[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // mini-aperçu image ou icone
                          if (v.picKm != null && v.picKm!.isNotEmpty)
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: v.picKm!.startsWith('http')
                                      ? NetworkImage(v.picKm!) as ImageProvider
                                      : FileImage(File(v.picKm!)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.directions_car, size: 34, color: Color(0xFF357ABD)),
                            ),
                          const SizedBox(width: 12),
                          // infos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${v.marque} ${v.modele}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text('Immatriculation: ${v.immatriculation}', style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (v.annee != null) Text('Année: ${v.annee}  ', style: const TextStyle(fontSize: 13)),
                                    if (v.kilometrage != null) Text('Km: ${v.kilometrage}', style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(label: Text(v.carburant.name.toUpperCase())),
                                    if (v.dateCirculation != null)
                                      Chip(label: Text(DateFormat('yyyy-MM-dd').format(v.dateCirculation!))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // actions
                          Column(
                            children: [
                              IconButton(
                                tooltip: 'Éditer',
                                icon: const Icon(Icons.edit, color: Color(0xFF357ABD)),
                                onPressed: () {
                                  // si tu as un écran d'édition, tu peux naviguer en passant l'id du véhicule
                                  // ex: Get.toNamed(AppRoutes.addVehiculeScreen, arguments: {'clientId': clientId, 'vehiculeId': v.id});
                                },
                              ),
                              IconButton(
                                tooltip: 'Supprimer',
                                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: 'Confirmer',
                                    middleText: 'Supprimer ${v.marque} ${v.modele} ?',
                                    textCancel: 'Annuler',
                                    textConfirm: 'Supprimer',
                                    onConfirm: () {
                                      // suppression du véhicule
                                      ref.read(vehiculesProvider.notifier).removeVehicule(v.id);

                                      // --- CORRECTION ICI: use indexWhere to check existence ---
                                      final clients = ref.read(clientsProvider).clients;
                                      final idx = clients.indexWhere((c) => c.id == clientId);
                                      if (idx != -1) {
                                        final maybeClient = clients[idx];
                                        final updated = maybeClient.copyWith(
                                          vehiculeIds: maybeClient.vehiculeIds.where((id) => id != v.id).toList(),
                                        );
                                        ref.read(clientsProvider.notifier).updateClient(maybeClient.id, updated);
                                      }
                                      // -------------------------------------------------------

                                      Get.back(); // ferme le dialog
                                      // Optionnel : snackbar
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${v.marque} ${v.modele} supprimé')),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF357ABD),
        onPressed: () {
          // navigation vers ton AddVehScreen (GenerateRoutes attend un String clientId)
          Get.toNamed(AppRoutes.addVehiculeScreen, arguments: clientId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
