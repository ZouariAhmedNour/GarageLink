import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/vehicule_provider.dart';

class VehiculeInfoScreen extends ConsumerWidget {
  final String vehiculeId;
  const VehiculeInfoScreen({required this.vehiculeId, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehState = ref.watch(vehiculesProvider);
    final veh = vehState.vehicules.firstWhere((v) => v.id == vehiculeId);
    final Color primary = const Color(0xFF357ABD);

    return Scaffold(
      appBar: AppBar(
        title: Text('${veh.marque} ${veh.modele}'),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: Text('${veh.marque} ${veh.modele}'),
                subtitle: Text(
                  'Immat: ${veh.immatriculation}\nAnnée: ${veh.annee ?? '-'}\nKm: ${veh.kilometrage ?? '-'}',
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              'Visites / Historique',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Pour l'instant mock list - tu pourras connecter à une source de visites
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    title: Text('12/01/2024 - Vidange'),
                    subtitle: Text('Atelier A'),
                  ),
                  ListTile(
                    title: Text('23/05/2024 - Révision'),
                    subtitle: Text('Atelier B'),
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
