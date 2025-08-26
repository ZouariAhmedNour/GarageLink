import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';


class AddVehScreen extends ConsumerStatefulWidget {
  final String clientId;
  const AddVehScreen({required this.clientId, Key? key}) : super(key: key);

  @override
  ConsumerState<AddVehScreen> createState() => _AddVehScreenState();
}

class _AddVehScreenState extends ConsumerState<AddVehScreen> {
  final _formKey = GlobalKey<FormState>();
  final _immat = TextEditingController();
  final _marque = TextEditingController();
  final _modele = TextEditingController();
  final _annee = TextEditingController();
  final _km = TextEditingController();

  List<String> makes = []; // fetched marques
  List<String> models = [];

  @override
  void initState() {
    super.initState();
    fetchMakes();
  }

  Future<void> fetchMakes() async {
    // Exemple: utiliser l'API NHTSA vPIC qui est gratuite et ne nécessite pas de clé
    final url = Uri.parse(
      'https://vpic.nhtsa.dot.gov/api/vehicles/GetAllMakes?format=json',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final results = data['Results'] as List;
      setState(
        () => makes = results.map((e) => e['Make_Name'] as String).toList(),
      );
    }
  }

  Future<void> fetchModelsForMake(String make) async {
    final url = Uri.parse(
      'https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMake/$make?format=json',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final results = data['Results'] as List;
      setState(
        () => models = results
            .map((e) => e['Model_Name'] as String)
            .toSet()
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF357ABD);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter véhicule'),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // logos grid (placeholder) - tu peux remplacer par des assets logos
            SizedBox(
              height: 90,
              child: makes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: makes.length,
                      itemBuilder: (context, i) {
                        final m = makes[i];
                        return GestureDetector(
                          onTap: () async {
                            _marque.text = m;
                            await fetchModelsForMake(m);
                            // show model selector
                            showModalBottomSheet(
                              context: context,
                              builder: (_) {
                                return ListView(
                                  children: models
                                      .map(
                                        (mo) => ListTile(
                                          title: Text(mo),
                                          onTap: () {
                                            _modele.text = mo;
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car, size: 30),
                                const SizedBox(height: 6),
                                Flexible(
                                  child: Text(
                                    m,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _immat,
                      decoration: const InputDecoration(
                        labelText: 'Immatriculation',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Obligatoire' : null,
                    ),
                    TextFormField(
                      controller: _marque,
                      decoration: const InputDecoration(labelText: 'Marque'),
                    ),
                    TextFormField(
                      controller: _modele,
                      decoration: const InputDecoration(labelText: 'Modèle'),
                    ),
                    TextFormField(
                      controller: _annee,
                      decoration: const InputDecoration(labelText: 'Année'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _km,
                      decoration: const InputDecoration(
                        labelText: 'Kilométrage',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final v = Vehicule(
                            id: const Uuid().v4(),
                            immatriculation: _immat.text,
                            marque: _marque.text,
                            modele: _modele.text,
                            annee: int.tryParse(_annee.text),
                            kilometrage: int.tryParse(_km.text),
                            clientId: widget.clientId,
                          );
                          ref.read(vehiculesProvider.notifier).addVehicule(v);
                          Get.back();
                        }
                      },
                      child: const Text('Ajouter véhicule'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
