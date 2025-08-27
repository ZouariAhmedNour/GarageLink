import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/client.dart';
import 'package:garagelink/providers/client_provider.dart';
import 'package:get/get.dart';

class EditClientScreen extends ConsumerStatefulWidget {
  final Client client;
  const EditClientScreen({Key? key, required this.client}) : super(key: key);

  @override
  ConsumerState<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends ConsumerState<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _mailCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _adrCtrl;
  late Categorie _cat;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.client.nomComplet);
    _mailCtrl = TextEditingController(text: widget.client.mail);
    _telCtrl = TextEditingController(text: widget.client.telephone);
    _adrCtrl = TextEditingController(text: widget.client.adresse);
    _cat = widget.client.categorie;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _mailCtrl.dispose();
    _telCtrl.dispose();
    _adrCtrl.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return null;
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
        title: const Text('Modifier client'),
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
                    try {
                      final updated = widget.client.copyWith(
                        nomComplet: _nomCtrl.text.trim(),
                        mail: _mailCtrl.text.trim(),
                        telephone: _telCtrl.text.trim(),
                        adresse: _adrCtrl.text.trim(),
                        categorie: _cat,
                      );
                      ref.read(clientsProvider.notifier).updateClient(widget.client.id, updated);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Client modifié avec succès"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Get.back();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Erreur lors de la modification"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
