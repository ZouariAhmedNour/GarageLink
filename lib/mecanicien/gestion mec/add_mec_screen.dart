// screens/add_mec_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/gestion%20mec/mec_list_screen.dart';
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
  final permisCtrl = TextEditingController();
  
  DateTime? dateNaissance;
  DateTime? dateEmbauche;
  Poste? poste;
  TypeContrat? typeContrat;
  Statut? statut;
  final Set<String> selectedServices = {};
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  static const primaryColor = Color(0xFF357ABD);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const cardColor = Colors.white;
  static const errorColor = Color(0xFFE53E3E);
  static const successColor = Color(0xFF38A169);
  
  final allServices = [
    'Entretien', 'Diagnostic', 'Révision', 'Dépannage', 
    'Électricité', 'Carrosserie', 'Climatisation'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );
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
    _animationController.dispose();
    nomCtrl.dispose();
    telCtrl.dispose();
    emailCtrl.dispose();
    matriculeCtrl.dispose();
    salaireCtrl.dispose();
    experienceCtrl.dispose();
    permisCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial, {required bool isBirth}) async {
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
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: primaryColor),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixText: suffix,
        labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
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
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(itemLabel(item), style: const TextStyle(fontWeight: FontWeight.w500)),
      )).toList(),
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
        Row(
          children: [
            const Icon(Icons.build, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text('Services', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allServices.map((service) {
            final selected = selectedServices.contains(service);
            return FilterChip(
              label: Text(service, style: TextStyle(
                color: selected ? Colors.white : primaryColor,
                fontWeight: FontWeight.w500,
              )),
              selected: selected,
              selectedColor: primaryColor,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: selected ? primaryColor : Colors.grey[300]!),
              onSelected: (on) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (on) selectedServices.add(service);
                  else selectedServices.remove(service);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mecanicien != null;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Modifier mécanicien' : 'Ajouter mécanicien',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                      Row(
                        children: [
                          const Icon(Icons.person, color: primaryColor),
                          const SizedBox(width: 8),
                          Text('Informations personnelles', 
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600, color: Colors.black87,
                            )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: nomCtrl,
                        label: 'Nom complet',
                        icon: Icons.person_outline,
                        validator: (v) => (v?.isEmpty ?? true) ? 'Nom requis' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(
                            controller: telCtrl,
                            label: 'Téléphone',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v?.isEmpty ?? true) ? 'Téléphone requis' : null,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(
                            controller: emailCtrl,
                            label: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          )),
                        ],
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
                      Row(
                        children: [
                          const Icon(Icons.work, color: primaryColor),
                          const SizedBox(width: 8),
                          Text('Informations professionnelles',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600, color: Colors.black87,
                            )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(
                            controller: matriculeCtrl,
                            label: 'Matricule',
                            icon: Icons.badge,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(
                            controller: salaireCtrl,
                            label: 'Salaire',
                            icon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            suffix: 'DT',
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<Poste>(
                        label: 'Poste',
                        icon: Icons.assignment_ind,
                        value: poste,
                        items: Poste.values,
                        onChanged: (v) => setState(() => poste = v),
                        itemLabel: (p) => p.toString().split('.').last,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildDropdown<TypeContrat>(
                            label: 'Type contrat',
                            icon: Icons.description,
                            value: typeContrat,
                            items: TypeContrat.values,
                            onChanged: (v) => setState(() => typeContrat = v),
                            itemLabel: (t) => t.toString().split('.').last,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDropdown<Statut>(
                            label: 'Statut',
                            icon: Icons.check_circle,
                            value: statut,
                            items: Statut.values,
                            onChanged: (v) => setState(() => statut = v),
                            itemLabel: (s) => s.toString().split('.').last,
                          )),
                        ],
                      ),
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
                        label: 'Expérience',
                        icon: Icons.star,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: permisCtrl,
                        label: 'Permis de conduite',
                        icon: Icons.drive_eta,
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
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

void _save() {
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

  try {
    if (widget.mecanicien == null) {
      ref.read(mecaniciensProvider.notifier).addMec(mec);
    } else {
      ref.read(mecaniciensProvider.notifier).updateMec(id, mec);
    }

    // Affiche l'alerte de succès
    Get.snackbar(
      'Succès',
      'Vos modifications sont enregistrées',
      backgroundColor: successColor,
      colorText: Colors.white,
      icon: const Icon(Icons.check, color: Colors.white),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );

    // Navigation vers la liste des mécaniciens
    // Utilise Get.to si tu veux empiler, Get.off pour remplacer la page actuelle,
    // ou Get.offAll pour vider la pile. Ici j'utilise Get.to comme demandé :
    Get.to(() => const MecListScreen());
  } catch (e) {
    Get.snackbar(
      'Erreur',
      'Une erreur est survenue lors de l\'enregistrement',
      backgroundColor: errorColor,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }
}
}