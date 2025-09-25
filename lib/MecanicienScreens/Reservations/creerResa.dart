// lib/MecanicienScreens/Reservations/creer_resa_screen.dart
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
    // Déclencher le chargement APRES la première frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // appelle asynchrone non-awaited
      ref.read(serviceProvider.notifier).loadAll().catchError((e) {
        debugPrint('loadAll services error: $e');
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    super.dispose();
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
    final initial = selectedHour != null ? _parseTimeOfDay(selectedHour!) : const TimeOfDay(hour: 9, minute: 0);

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

      // Petite attente pour voir le SnackBar puis revenir
      Future.delayed(const Duration(milliseconds: 350), () {
        // Si tu veux revenir à l'accueil mécanicien :
        // Get.offAllNamed('/mecaHome');
        // ou revenir simplement à l'écran précédent :
        Get.back(result: true);
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
    final servicesState = ref.watch(serviceProvider);
    final services = servicesState.services;
    final isLoadingServices = servicesState.loading;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 700;

    // Remplacement : on utilise username ou email comme fallback
    final garageLabel = (widget.garage.username.isNotEmpty)
        ? widget.garage.username
        : (widget.garage.email.isNotEmpty)
            ? widget.garage.email
            : 'Garage';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Créer une réservation', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF357ABD),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 800 : double.infinity),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 6,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text(
                        garageLabel,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Remplissez les informations ci-dessous pour envoyer une demande de réservation',
                          style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 18),

                      // Name
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),

                      // Phone
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: 'Téléphone',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email (optionnel)',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      // Service dropdown (avec loader si nécessaire)
                      isLoadingServices
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                              child: const Row(
                                children: [
                                  SizedBox(width: 12),
                                  CircularProgressIndicator(strokeWidth: 2),
                                  SizedBox(width: 12),
                                  Text('Chargement des services...'),
                                ],
                              ),
                            )
                          : DropdownButtonFormField<Service>(
                              items: services.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                              value: selectedService,
                              onChanged: (v) => setState(() => selectedService = v),
                              decoration: InputDecoration(
                                  labelText: 'Service',
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                              validator: (_) => selectedService == null ? 'Veuillez sélectionner un service' : null,
                            ),
                      const SizedBox(height: 12),

                      // Date + Time row
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDate(context),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Date souhaitée',
                                    hintText: 'Choisir une date',
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  ),
                                  controller: TextEditingController(text: selectedDate != null ? _formatDate(selectedDate!) : ''),
                                  validator: (_) => selectedDate == null ? 'Date requise' : null,
                                  readOnly: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 140,
                            child: GestureDetector(
                              onTap: () => _pickTime(context),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: "Heure souhaitée",
                                    hintText: 'HH:mm',
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  ),
                                  controller: TextEditingController(text: selectedHour ?? ''),
                                  validator: (_) => selectedHour == null ? 'Heure requise' : null,
                                  readOnly: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description du dépannage (optionnel)',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 18),

                      // Buttons row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF357ABD),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Réserver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
