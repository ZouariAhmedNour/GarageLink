// screens/add_mec_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/mecanicien.dart';
import 'package:garagelink/providers/mecaniciens_provider.dart';
import 'package:get/get.dart';


class AddMecScreen extends ConsumerStatefulWidget {
  final Mecanicien? mecanicien;
  const AddMecScreen({super.key, this.mecanicien});

  @override
  ConsumerState<AddMecScreen> createState() => _AddMecScreenState();
}

class _AddMecScreenState extends ConsumerState<AddMecScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final matriculeCtrl = TextEditingController();
  final salaireCtrl = TextEditingController();
  final experienceCtrl = TextEditingController();
  final permisCtrl = TextEditingController();
  DateTime? dateNaissance;
  DateTime? dateEmbauche;
  Poste? poste;
  TypeContrat? typeContrat;
  Statut? statut;
  final Set<String> selectedServices = {};

  final allServices = ['Entretien', 'Diagnostic', 'Révision', 'Dépannage', 'élécrticité', 'carrosserie', 'climatisation'];

  @override
  void initState() {
    super.initState();
    if (widget.mecanicien != null) {
      final m = widget.mecanicien!;
      nomCtrl.text = m.nom;
      telCtrl.text = m.telephone;
      emailCtrl.text = m.email;
      matriculeCtrl.text = m.matricule;
      salaireCtrl.text = m.salaire.toString();
      experienceCtrl.text = m.experience;
      permisCtrl.text = m.permisConduite;
      dateNaissance = m.dateNaissance;
      dateEmbauche = m.dateEmbauche;
      poste = m.poste;
      typeContrat = m.typeContrat;
      statut = m.statut;
      selectedServices.addAll(m.services);
    } else {
      poste = Poste.mecanicien;
      typeContrat = TypeContrat.cdi;
      statut = Statut.actif;
    }
  }

  @override
  void dispose() {
    nomCtrl.dispose();
    telCtrl.dispose();
    emailCtrl.dispose();
    matriculeCtrl.dispose();
    salaireCtrl.dispose();
    experienceCtrl.dispose();
    permisCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(now.year - 25),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 1),
    );
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mecanicien != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier mécanicien' : 'Ajouter mécanicien'),
        backgroundColor: const Color(0xFF357ABD),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telCtrl,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: matriculeCtrl,
                      decoration: const InputDecoration(labelText: 'Matricule'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: salaireCtrl,
                      decoration: const InputDecoration(labelText: 'Salaire'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Poste>(
                decoration: const InputDecoration(labelText: 'Poste'),
                value: poste,
                items: Poste.values.map((p) => DropdownMenuItem(value: p, child: Text(p.toString().split('.').last))).toList(),
                onChanged: (v) => setState(() => poste = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TypeContrat>(
                decoration: const InputDecoration(labelText: 'Type contrat'),
                value: typeContrat,
                items: TypeContrat.values.map((t) => DropdownMenuItem(value: t, child: Text(t.toString().split('.').last))).toList(),
                onChanged: (v) => setState(() => typeContrat = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Statut>(
                decoration: const InputDecoration(labelText: 'Statut'),
                value: statut,
                items: Statut.values.map((s) => DropdownMenuItem(value: s, child: Text(s.toString().split('.').last))).toList(),
                onChanged: (v) => setState(() => statut = v),
              ),
              const SizedBox(height: 12),
              // Competences multi-select (chips)
              Align(alignment: Alignment.centerLeft, child: const Text('Compétences')),
              Wrap(
                spacing: 8,
                children: allServices.map((c) {
                  final selected = selectedServices.contains(c);
                  return FilterChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (on) {
                      setState(() {
                        if (on) selectedServices.add(c);
                        else selectedServices.remove(c);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: experienceCtrl,
                decoration: const InputDecoration(labelText: 'Expérience (texte)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: permisCtrl,
                decoration: const InputDecoration(labelText: 'Permis de conduite'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dateNaissance == null ? 'Date de naissance' : dateNaissance!.toLocal().toString().split(' ')[0]),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final d = await _pickDate(context, dateNaissance);
                          if (d != null) setState(() => dateNaissance = d);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dateEmbauche == null ? 'Date d\'embauche' : dateEmbauche!.toLocal().toString().split(' ')[0]),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final d = await _pickDate(context, dateEmbauche);
                          if (d != null) setState(() => dateEmbauche = d);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF357ABD)),
                onPressed: _save,
                child: Text(widget.mecanicien == null ? 'Ajouter' : 'Enregistrer'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar('Erreur', 'Veuillez remplir les champs obligatoires', backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final id = widget.mecanicien?.id ?? 'MEC-${DateTime.now().millisecondsSinceEpoch}';
    final salaire = double.tryParse(salaireCtrl.text.replaceAll(',', '.')) ?? 0.0;

    final mec = Mecanicien(
      id: id,
      nom: nomCtrl.text.trim(),
      dateNaissance: dateNaissance,
      telephone: telCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      matricule: matriculeCtrl.text.trim(),
      poste: poste ?? Poste.mecanicien,
      dateEmbauche: dateEmbauche,
      typeContrat: typeContrat ?? TypeContrat.cdi,
      statut: statut ?? Statut.actif,
      salaire: salaire,
      services: selectedServices.toList(),
      experience: experienceCtrl.text.trim(),
      permisConduite: permisCtrl.text.trim(),
    );

    if (widget.mecanicien == null) {
      ref.read(mecaniciensProvider.notifier).addMec(mec);
      Get.back();
    } else {
      ref.read(mecaniciensProvider.notifier).updateMec(id, mec);
      Get.back();
    }
  }
}
