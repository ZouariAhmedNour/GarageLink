import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/user.dart';
import 'package:garagelink/models/service.dart';
import 'package:garagelink/providers/reservation_provider.dart';
import 'package:garagelink/providers/service_provider.dart';
import 'package:get/get.dart';

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
  String? selectedHour; // stored as 'HH:mm'

  @override
  void initState() {
    super.initState();
    // Déclencher le chargement APRES que la première frame soit affichée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // appel asynchrone non awaited pour ne pas bloquer initState
      ref.read(serviceProvider.notifier).loadAll().catchError((e) {
        debugPrint('loadAll services error: $e');
      });
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr'),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final initial = selectedHour != null
        ? _parseTimeOfDay(selectedHour!)
        : TimeOfDay(hour: 9, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        selectedHour = _formatTimeOfDay(picked);
      });
    }
  }

  TimeOfDay _parseTimeOfDay(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
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

  try {
    // Appel création réservation
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

    // SnackBar vert de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Votre demande a été envoyée au garage'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(milliseconds: 350), () {
      Get.offAllNamed('/mecaHome');
    });
  } catch (e) {
    debugPrint('create reservation error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la création : $e')),
    );
  }
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
              const SizedBox(height: 12),

              // Date picker field
              GestureDetector(
                onTap: () => _pickDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Date souhaitée',
                      hintText: 'Choisir une date',
                    ),
                    controller: TextEditingController(
                        text: selectedDate != null ? _formatDate(selectedDate!) : ''),
                    validator: (_) => selectedDate == null ? 'Date requise' : null,
                    readOnly: true,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Time picker field
              GestureDetector(
                onTap: () => _pickTime(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Heure d'arrivée souhaitée",
                      hintText: 'Choisir une heure',
                    ),
                    controller: TextEditingController(text: selectedHour ?? ''),
                    validator: (_) => selectedHour == null ? 'Heure requise' : null,
                    readOnly: true,
                  ),
                ),
              ),

              const SizedBox(height: 12),
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
