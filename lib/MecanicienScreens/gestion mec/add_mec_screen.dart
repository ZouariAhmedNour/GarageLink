// screens/add_mec_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/gestion%20mec/mec_list_screen.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/models/mecanicien.dart';
import 'package:garagelink/providers/mecaniciens_provider.dart';
import 'package:get/get.dart';

class AddMecScreen extends ConsumerStatefulWidget {
  final Mecanicien? mecanicien;
  const AddMecScreen({super.key, this.mecanicien});

  @override
  ConsumerState<AddMecScreen> createState() => _AddMecScreenState();
}

class _AddMecScreenState extends ConsumerState<AddMecScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nomCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final matriculeCtrl = TextEditingController();
  final salaireCtrl = TextEditingController();
  final experienceCtrl = TextEditingController();

  DateTime? dateNaissance;
  DateTime? dateEmbauche;
  Poste? poste;
  TypeContrat? typeContrat;
  Statut? statut;
  PermisConduire? permis; // maintenant enum

  final Set<String> selectedServices = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const primaryColor = Color(0xFF357ABD);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const cardColor = Colors.white;
  static const errorColor = Color(0xFFE53E3E);
  static const successColor = Color(0xFF38A169);

  // Liste simple de services (strings) — adapte si tu veux des ids différents
  final List<String> allServices = [
    'Moteur',
    'Transmission',
    'Freinage',
    'Suspension',
    'Électricité',
    'Diagnostic',
    'Carrosserie',
    'Climatisation'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();

    _initializeData();
  }

  void _initializeData() {
    if (widget.mecanicien != null) {
      final m = widget.mecanicien!;
      nomCtrl.text = m.nom;
      telCtrl.text = m.telephone;
      emailCtrl.text = m.email;
      matriculeCtrl.text = m.matricule;
      salaireCtrl.text = m.salaire.toString();
      experienceCtrl.text = m.experience;
      dateNaissance = m.dateNaissance;
      dateEmbauche = m.dateEmbauche;
      poste = m.poste;
      typeContrat = m.typeContrat;
      statut = m.statut;
      permis = m.permisConduire;
      // remplir selectedServices à partir de m.services (utilise name)
      selectedServices.addAll(m.services.map((s) => s.name));
    } else {
      poste = Poste.mecanicien;
      typeContrat = TypeContrat.cdi;
      statut = Statut.actif;
      permis = PermisConduire.b;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    nomCtrl.dispose();
    telCtrl.dispose();
    emailCtrl.dispose();
    matriculeCtrl.dispose();
    salaireCtrl.dispose();
    experienceCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial,
      {required bool isBirth}) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? (isBirth ? DateTime(now.year - 25) : now),
      firstDate: DateTime(1950),
      lastDate: isBirth ? now : DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).colorScheme.copyWith(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    return picked;
  }

  Widget _buildCard({required Widget child, EdgeInsets? padding}) {
    return Card(
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? suffix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixText: suffix,
        labelStyle:
            TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onTap: () => HapticFeedback.selectionClick(),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(itemLabel(item),
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ))
          .toList(),
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
    );
  }

  Widget _buildDateField(String label, IconData icon, DateTime? date, bool isBirth) {
    return InkWell(
      onTap: () async {
        final d = await _pickDate(context, date, isBirth: isBirth);
        if (d != null) setState(() => isBirth ? dateNaissance = d : dateEmbauche = d);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    date?.toLocal().toString().split(' ')[0] ?? 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: date != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.build, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Text('Services',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  )),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allServices.map((service) {
            final selected = selectedServices.contains(service);
            return FilterChip(
              label: Text(
                service,
                style: TextStyle(
                  color: selected ? Colors.white : primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: selected,
              selectedColor: primaryColor,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: selected ? primaryColor : Colors.grey[300]!),
              onSelected: (on) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (on)
                    selectedServices.add(service);
                  else
                    selectedServices.remove(service);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _labelPoste(Poste p) {
    switch (p) {
      case Poste.electricienAuto:
        return 'Électricien Auto';
      case Poste.carrossier:
        return 'Carrossier';
      case Poste.chefDEquipe:
        return 'Chef d\'équipe';
      case Poste.apprenti:
        return 'Apprenti';
      case Poste.mecanicien:
      return 'Mécanicien';
    }
  }

  String _labelTypeContrat(TypeContrat t) {
    switch (t) {
      case TypeContrat.cdd:
        return 'CDD';
      case TypeContrat.stage:
        return 'Stage';
      case TypeContrat.apprentissage:
        return 'Apprentissage';
      case TypeContrat.cdi:
      return 'CDI';
    }
  }

  String _labelStatut(Statut s) {
    switch (s) {
      case Statut.conge:
        return 'Congé';
      case Statut.arretMaladie:
        return 'Arrêt maladie';
      case Statut.suspendu:
        return 'Suspendu';
      case Statut.demissionne:
        return 'Démissionné';
      case Statut.actif:
      return 'Actif';
    }
  }

  String _labelPermis(PermisConduire p) {
    return p.toString().split('.').last.toUpperCase();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();

    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Erreur de validation',
        'Veuillez corriger les erreurs dans le formulaire',
        backgroundColor: errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // fallback raisonnables si dates manquantes
    final now = DateTime.now();
    final dn = dateNaissance ?? DateTime(now.year - 25);
    final de = dateEmbauche ?? now;

    final salaire = double.tryParse(salaireCtrl.text.replaceAll(',', '.')) ?? 0.0;

    // convertir selectedServices en List<ServiceMecanicien>
    final services = selectedServices
        .map((s) => ServiceMecanicien(
              serviceId: s.toLowerCase().replaceAll(' ', '_'),
              name: s,
            ))
        .toList();

    final mecanicienId = widget.mecanicien?.id; // null si création

    try {
      if (mecanicienId == null) {
        // création via le provider (méthode asynchrone)
        await ref.read(mecaniciensProvider.notifier).addMecanicien(
              nom: nomCtrl.text.trim(),
              dateNaissance: dn,
              telephone: telCtrl.text.trim(),
              email: emailCtrl.text.trim(),
              poste: poste ?? Poste.mecanicien,
              dateEmbauche: de,
              typeContrat: typeContrat ?? TypeContrat.cdi,
              statut: statut ?? Statut.actif,
              salaire: salaire,
              services: services,
              experience: experienceCtrl.text.trim(),
              permisConduire: permis ?? PermisConduire.b,
            );
      } else {
        // mise à jour : on envoie les champs modifiables
        await ref.read(mecaniciensProvider.notifier).updateMecanicien(
              id: mecanicienId,
              nom: nomCtrl.text.trim(),
              dateNaissance: dn,
              telephone: telCtrl.text.trim(),
              email: emailCtrl.text.trim(),
              poste: poste,
              dateEmbauche: de,
              typeContrat: typeContrat,
              statut: statut,
              salaire: salaire,
              services: services,
              experience: experienceCtrl.text.trim(),
              permisConduire: permis,
            );
      }

      Get.snackbar(
        'Succès',
        mecanicienId == null ? 'Mécanicien ajouté' : 'Modifications enregistrées',
        backgroundColor: successColor,
        colorText: Colors.white,
        icon: const Icon(Icons.check, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      // retourner à la liste (remplace la page actuelle)
      Get.off(() => const MecListScreen());
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de l\'enregistrement : ${e.toString()}',
        backgroundColor: errorColor,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mecanicien != null;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: isEdit ? 'Modifier mécanicien' : 'Ajouter mécanicien',
        backgroundColor: primaryColor,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.person, color: primaryColor),
                        const SizedBox(width: 8),
                        Text('Informations personnelles',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                )),
                      ]),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: nomCtrl,
                        label: 'Nom complet',
                        icon: Icons.person_outline,
                        validator: (v) => (v?.isEmpty ?? true) ? 'Nom requis' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: telCtrl,
                        label: 'Téléphone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Téléphone requis';
                          final regex = RegExp(r'^\d{8}$');
                          if (!regex.hasMatch(v)) return 'Format valide: XXXXXXXX';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: emailCtrl,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null; // facultatif
                          final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                          if (!regex.hasMatch(v)) return 'Email invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDateField('Date de naissance', Icons.cake, dateNaissance, true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.work, color: primaryColor),
                        const SizedBox(width: 8),
                        Text('Informations professionnelles',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                )),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: _buildTextField(
                            controller: matriculeCtrl,
                            label: 'Matricule',
                            icon: Icons.badge,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: salaireCtrl,
                            label: 'Salaire',
                            icon: Icons.attach_money,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              if (double.tryParse(v.replaceAll(',', '.')) == null)
                                return 'Salaire doit être un nombre';
                              return null;
                            },
                            suffix: 'DT',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildDropdown<Poste>(
                        label: 'Poste',
                        icon: Icons.assignment_ind,
                        value: poste,
                        items: Poste.values,
                        onChanged: (v) => setState(() => poste = v),
                        itemLabel: (p) => _labelPoste(p),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: _buildDropdown<TypeContrat>(
                            label: 'Type contrat',
                            icon: Icons.description,
                            value: typeContrat,
                            items: TypeContrat.values,
                            onChanged: (v) => setState(() => typeContrat = v),
                            itemLabel: (t) => _labelTypeContrat(t),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown<Statut>(
                            label: 'Statut',
                            icon: Icons.check_circle,
                            value: statut,
                            items: Statut.values,
                            onChanged: (v) => setState(() => statut = v),
                            itemLabel: (s) => _labelStatut(s),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildDateField('Date d\'embauche', Icons.today, dateEmbauche, false),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(child: _buildServicesSection()),
                const SizedBox(height: 16),
                _buildCard(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: experienceCtrl,
                        label: 'Expérience (description / années)',
                        icon: Icons.star,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<PermisConduire>(
                        label: 'Permis de conduite',
                        icon: Icons.drive_eta,
                        value: permis,
                        items: PermisConduire.values,
                        onChanged: (v) => setState(() => permis = v),
                        itemLabel: (p) => _labelPermis(p),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  icon: Icon(isEdit ? Icons.save : Icons.add),
                  label: Text(
                    isEdit ? 'Enregistrer les modifications' : 'Ajouter le mécanicien',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async => await _save(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
