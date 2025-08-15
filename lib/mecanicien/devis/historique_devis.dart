import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/providers/historique_devis_provider.dart';

enum TypeFiltre { date, numeroSerie, id, client }

class HistoriqueDevisPage extends ConsumerStatefulWidget {
  const HistoriqueDevisPage({super.key});

  @override
  ConsumerState<HistoriqueDevisPage> createState() => _HistoriqueDevisPageState();
}

class _HistoriqueDevisPageState extends ConsumerState<HistoriqueDevisPage> {
  TypeFiltre typeFiltre = TypeFiltre.client;

  DateTimeRange? dateRange;
  final vinCtrl = TextEditingController();
  final numLocalCtrl = TextEditingController();
  final rechercheCtrl = TextEditingController();

  // Valeur temporaire avant clic sur bouton filtrer
  String valeurFiltre = "";

  @override
  Widget build(BuildContext context) {
    final historique = ref.watch(devisFiltresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historique devis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Choix du type de filtre
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<TypeFiltre>(
              value: typeFiltre,
              decoration: const InputDecoration(
                labelText: "Filtrer par",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: TypeFiltre.date, child: Text("Date")),
                DropdownMenuItem(value: TypeFiltre.numeroSerie, child: Text("Numéro de série")),
                DropdownMenuItem(value: TypeFiltre.id, child: Text("ID Devis")),
                DropdownMenuItem(value: TypeFiltre.client, child: Text("Nom Client")),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    typeFiltre = val;
                    valeurFiltre = "";
                    dateRange = null;
                    vinCtrl.clear();
                    numLocalCtrl.clear();
                    rechercheCtrl.clear();
                  });
                }
              },
            ),
          ),

          // Zone de saisie selon le filtre choisi
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Builder(
              builder: (context) {
                if (typeFiltre == TypeFiltre.date) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      dateRange == null
                          ? "Choisir une période"
                          : "${dateRange!.start.toString().split(' ')[0]} → ${dateRange!.end.toString().split(' ')[0]}",
                    ),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          dateRange = picked;
                          valeurFiltre =
                              "${picked.start.toIso8601String()}|${picked.end.toIso8601String()}";
                        });
                      }
                    },
                  );
                } else if (typeFiltre == TypeFiltre.numeroSerie) {
                  return NumeroSerieInput(
                    vinCtrl: vinCtrl,
                    numLocalCtrl: numLocalCtrl,
                    onChanged: (value) {
                      valeurFiltre = value;
                    },
                  );
                } else {
                  return TextField(
                    controller: rechercheCtrl,
                    decoration: InputDecoration(
                      hintText: typeFiltre == TypeFiltre.id
                          ? "Entrer l'ID du devis"
                          : "Entrer le nom du client",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      valeurFiltre = value;
                    },
                  );
                }
              },
            ),
          ),

          // Bouton appliquer filtre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.filter_alt),
              label: const Text("Appliquer le filtre"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: () {
                ref.read(filtreProvider.notifier).state = valeurFiltre;
              },
            ),
          ),

          const SizedBox(height: 8),

          // Liste filtrée
          Expanded(
            child: historique.isEmpty
                ? const Center(child: Text('Aucun devis trouvé'))
                : ListView.builder(
                    itemCount: historique.length,
                    itemBuilder: (context, index) {
                      final devis = historique[index];
                      return Card(
                        child: ListTile(
                          title: Text(devis.client),
                          subtitle: Text(
                            'Date: ${devis.date.toLocal().toString().split(" ")[0]} - Total: ${devis.totalTtc.toStringAsFixed(2)}€',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // TODO: Naviguer vers l'édition du devis
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
