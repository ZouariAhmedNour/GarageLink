import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/user.dart';
import 'package:garagelink/models/service.dart';
import 'package:garagelink/providers/reservation_provider.dart';
import 'package:garagelink/providers/service_provider.dart';

class CreerResaScreen extends ConsumerStatefulWidget {
  final User garage;

  const CreerResaScreen({super.key, required this.garage});

  @override
  ConsumerState<CreerResaScreen> createState() => _CreerResaScreenState();
}

class _CreerResaScreenState extends ConsumerState<CreerResaScreen> {
  final _formKey = GlobalKey<FormState>();
  Service? selectedService;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDate;
  String? selectedHour;

  @override
  void initState() {
    super.initState();
    ref.read(serviceProvider.notifier).loadAll();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un service')),
      );
      return;
    }
    if (selectedDate == null || selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une date et heure')),
      );
      return;
    }

    await ref.read(reservationsProvider.notifier).createReservation(
          garageId: widget.garage.id!,
          clientName: nameController.text,
          clientPhone: phoneController.text,
          clientEmail: emailController.text,
          serviceId: selectedService!.id!,
          creneauDemandeDate: selectedDate!,
          creneauDemandeHeureDebut: selectedHour!,
          descriptionDepannage: descriptionController.text,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réservation créée avec succès !')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(serviceProvider).services;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer une réservation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              DropdownButtonFormField<Service>(
                items: services
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                value: selectedService,
                onChanged: (v) => setState(() => selectedService = v),
                decoration: const InputDecoration(labelText: 'Service'),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description du dépannage'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Réserver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
