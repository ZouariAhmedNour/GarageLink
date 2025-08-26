import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/client.dart';
import 'package:garagelink/providers/client_provider.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';


class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _mailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adrCtrl = TextEditingController();
  Categorie _cat = Categorie.particulier;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF357ABD);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter client'),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (v) => v == null || v.isEmpty ? 'Obligatoire' : null,
              ),
              TextFormField(
                controller: _mailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _telCtrl,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _adrCtrl,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Catégorie :'),
                  const SizedBox(width: 12),
                  DropdownButton<Categorie>(
                    value: _cat,
                    items: Categorie.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString().split('.').last),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _cat = v ?? Categorie.particulier),
                  ),
                ],
              ),
              if (_cat == Categorie.professionnel) ...[
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nom entreprise',
                  ),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Téléphone entreprise',
                  ),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email entreprise',
                  ),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Adresse entreprise',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final id = const Uuid().v4();
                    final client = Client(
                      id: id,
                      nomComplet: _nomCtrl.text,
                      mail: _mailCtrl.text,
                      telephone: _telCtrl.text,
                      adresse: _adrCtrl.text,
                      categorie: _cat,
                    );
                    ref.read(clientsProvider.notifier).addClient(client);
                    Get.back();
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
