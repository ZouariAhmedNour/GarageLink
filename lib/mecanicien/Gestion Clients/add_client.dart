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
  void dispose() {
    _nomCtrl.dispose();
    _mailCtrl.dispose();
    _telCtrl.dispose();
    _adrCtrl.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return null; // email optionnel
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(v) ? null : 'Email invalide';
  }

  String? _requiredValidator(String? v) =>
      v == null || v.isEmpty ? 'Obligatoire' : null;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF357ABD);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Ajouter client', style: TextStyle(color: Colors.white)),
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
                validator: _requiredValidator,
              ),
              TextFormField(
                controller: _mailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              TextFormField(
                controller: _telCtrl,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
                validator: _requiredValidator,
              ),
              TextFormField(
                controller: _adrCtrl,
                decoration: const InputDecoration(labelText: 'Adresse'),
                validator: _requiredValidator,
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
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final id = const Uuid().v4();
                    final client = Client(
                      id: id,
                      nomComplet: _nomCtrl.text.trim(),
                      mail: _mailCtrl.text.trim(),
                      telephone: _telCtrl.text.trim(),
                      adresse: _adrCtrl.text.trim(),
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
