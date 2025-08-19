import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/meca_services/meca_services.dart';
import 'package:garagelink/providers/service_provider.dart';

class AddEditServiceScreen extends ConsumerStatefulWidget {
  final Service? service;

  const AddEditServiceScreen({super.key, this.service});

  @override
  ConsumerState<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends ConsumerState<AddEditServiceScreen> 
    with TickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF357ABD);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkGrey = Color(0xFF2C3E50);
  static const Color lightGrey = Color(0xFFF8F9FA);
  // ignore: unused_field
  static const Color successGreen = Color(0xFF27AE60);
  static const Color warningRed = Color(0xFFE74C3C);

  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final nomCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final prixCtrl = TextEditingController();
  final dureeCtrl = TextEditingController();
  
  String? categorie;
  bool actif = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> categories = [
    {'value': 'Entretien', 'icon': Icons.build_outlined, 'color': Colors.orange},
    {'value': 'Révision', 'icon': Icons.checklist_outlined, 'color': Colors.blue},
    {'value': 'Freinage', 'icon': Icons.speed_outlined, 'color': Colors.red},
    {'value': 'Électricité', 'icon': Icons.electrical_services_outlined, 'color': Colors.amber},
    {'value': 'Carrosserie', 'icon': Icons.directions_car_outlined, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _prefillFields();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), 
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  void _prefillFields() {
    if (widget.service != null) {
      nomCtrl.text = widget.service!.nom;
      descCtrl.text = widget.service!.description;
      prixCtrl.text = widget.service!.prix.toString();
      dureeCtrl.text = widget.service!.duree.toString();
      categorie = widget.service!.categorie;
      actif = widget.service!.actif;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    nomCtrl.dispose();
    descCtrl.dispose();
    prixCtrl.dispose();
    dureeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      final newService = Service(
        id: widget.service?.id ?? DateTime.now().millisecondsSinceEpoch,
        nom: nomCtrl.text.trim(),
        description: descCtrl.text.trim(),
        prix: double.parse(prixCtrl.text),
        duree: int.parse(dureeCtrl.text),
        categorie: categorie!,
        actif: actif,
      );

      if (widget.service == null) {
        ref.read(serviceProvider.notifier).addService(newService);
      } else {
        ref.read(serviceProvider.notifier).updateService(newService);
      }

      // Success feedback
      HapticFeedback.lightImpact();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MecaServicesPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorSnackBar('Erreur lors de la sauvegarde');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: warningRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x20357ABD),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service == null ? 'Nouveau Service' : 'Modifier Service',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.service == null 
                        ? 'Ajoutez un nouveau service à votre offre'
                        : 'Modifiez les détails du service',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.service == null ? Icons.add_business : Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? suffix,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: darkGrey.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          suffix: suffix != null ? Text(
            suffix,
            style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: warningRed, width: 2),
          ),
          filled: true,
          fillColor: lightGrey,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkGrey,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: categorie,
        decoration: InputDecoration(
          labelText: 'Catégorie de service',
          labelStyle: TextStyle(
            color: darkGrey.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.category_outlined, color: primaryBlue, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: lightGrey,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: categories.map((cat) => DropdownMenuItem<String>(
          value: cat['value'],
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (cat['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  cat['icon'],
                  color: cat['color'],
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                cat['value'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkGrey,
                ),
              ),
            ],
          ),
        )).toList(),
        onChanged: (v) {
          HapticFeedback.selectionClick();
          setState(() => categorie = v);
        },
        validator: (v) => v == null ? 'Veuillez sélectionner une catégorie' : null,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkGrey,
        ),
      ),
    );
  }

  Widget _buildActiveSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: actif ? lightBlue : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: actif ? primaryBlue.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actif ? primaryBlue : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              actif ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut du service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  actif ? 'Service visible aux clients' : 'Service masqué aux clients',
                  style: TextStyle(
                    fontSize: 14,
                    color: darkGrey.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.2,
            child: Switch(
              value: actif,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => actif = v);
              },
              activeColor: primaryBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, Color(0xFF4A90E2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _saveService,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    widget.service == null ? Icons.add : Icons.save,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isLoading 
                    ? 'Sauvegarde...' 
                    : (widget.service == null ? 'Créer le service' : 'Sauvegarder'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // ignore: unused_local_variable
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: lightGrey,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 16),
                      
                      // Informations générales
                      _buildFormCard(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: lightBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Informations générales',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildCustomTextField(
                              controller: nomCtrl,
                              label: 'Nom du service',
                              icon: Icons.build_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty) 
                                ? 'Le nom du service est obligatoire' : null,
                            ),
                            _buildCustomTextField(
                              controller: descCtrl,
                              label: 'Description détaillée',
                              icon: Icons.description_outlined,
                              maxLines: 3,
                              validator: (v) => (v == null || v.trim().isEmpty) 
                                ? 'La description est obligatoire' : null,
                            ),
                            _buildCategoryDropdown(),
                          ],
                        ),
                      ),
                      
                      // Tarification et durée
                      _buildFormCard(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: lightBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.payments_outlined,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Tarification & Durée',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCustomTextField(
                                    controller: prixCtrl,
                                    label: 'Prix',
                                    icon: Icons.attach_money,
                                    keyboardType: TextInputType.number,
                                    suffix: 'DT',
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Le prix est obligatoire';
                                      final price = double.tryParse(v);
                                      if (price == null) return 'Prix invalide';
                                      if (price <= 0) return 'Le prix doit être positif';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildCustomTextField(
                                    controller: dureeCtrl,
                                    label: 'Durée',
                                    icon: Icons.access_time,
                                    keyboardType: TextInputType.number,
                                    suffix: 'min',
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'La durée est obligatoire';
                                      final duration = int.tryParse(v);
                                      if (duration == null) return 'Durée invalide';
                                      if (duration <= 0) return 'La durée doit être positive';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Statut du service
                      _buildFormCard(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: lightBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.settings_outlined,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Configuration',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildActiveSwitch(),
                          ],
                        ),
                      ),
                      
                      // Bouton de sauvegarde
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: _buildSaveButton(),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}