import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/models/client.dart';
import 'package:garagelink/providers/client_provider.dart';
import 'package:get/get.dart';

class EditClientScreen extends ConsumerStatefulWidget {
  final Client client;
  const EditClientScreen({Key? key, required this.client}) : super(key: key);

  @override
  ConsumerState<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends ConsumerState<EditClientScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _mailCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _adrCtrl;
  late Categorie _cat;
late AnimationController _animationController;
Animation<double>? _fadeAnimation;
  bool _isLoading = false;

  // Palette de couleurs unifiée
  static const Color primaryColor = Color(0xFF357ABD);
  static const Color primaryLight = Color(0xFF5A9BD4);
  static const Color backgroundColor = Color(0xFFF8FAFB);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);

  @override
  void initState() {
    super.initState();
    _initControllers();
    _setupAnimation();
  }

  void _initControllers() {
    _nomCtrl = TextEditingController(text: widget.client.nomComplet);
    _mailCtrl = TextEditingController(text: widget.client.mail);
    _telCtrl = TextEditingController(text: widget.client.telephone);
    _adrCtrl = TextEditingController(text: widget.client.adresse);
    _cat = widget.client.categorie;
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nomCtrl.dispose();
    _mailCtrl.dispose();
    _telCtrl.dispose();
    _adrCtrl.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return null;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(v) ? null : 'Format d\'email invalide';
  }

  String? _requiredValidator(String? v) =>
      v == null || v.trim().isEmpty ? 'Ce champ est obligatoire' : null;

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ce champ est obligatoire';
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    return phoneRegex.hasMatch(v.trim()) ? null : 'Format de téléphone invalide';
  }

  Widget _buildAnimatedCard({required Widget child}) {
  // si _fadeAnimation est null (ex: après hot reload) on affiche directement l'enfant opaque
  final opacity = _fadeAnimation ?? AlwaysStoppedAnimation<double>(1.0);

  return FadeTransition(
    opacity: opacity,
    child: Card(
      color: cardColor,
      elevation: 4,
      shadowColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: child,
      ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor, size: 22),
          labelStyle: const TextStyle(
            color: Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.category_outlined, color: primaryColor, size: 22),
          const SizedBox(width: 12),
          const Text(
            'Catégorie :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Categorie>(
                value: _cat,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2D3748),
                ),
                items: Categorie.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e.toString().split('.').last.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _cat = v ?? Categorie.particulier);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading ? null : _handleSave,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Enregistrer les modifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final updated = widget.client.copyWith(
        nomComplet: _nomCtrl.text.trim(),
        mail: _mailCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
        adresse: _adrCtrl.text.trim(),
        categorie: _cat,
      );

      ref.read(clientsProvider.notifier).updateClient(widget.client.id, updated);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Client modifié avec succès',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Get.back();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Erreur lors de la modification',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
  title: 'Modifier le client',
  centerTitle: true,
  backgroundColor: primaryColor, // fallback si gradient null
  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primaryColor, primaryLight]),
),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                
                // Section informations personnelles
                _buildAnimatedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_outline, color: primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Informations personnelles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildTextField(
                        controller: _nomCtrl,
                        label: 'Nom complet',
                        icon: Icons.badge_outlined,
                        validator: _requiredValidator,
                      ),
                      
                      _buildTextField(
                        controller: _mailCtrl,
                        label: 'Adresse email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                      ),
                      
                      _buildTextField(
                        controller: _telCtrl,
                        label: 'Numéro de téléphone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: _phoneValidator,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Section adresse et catégorie
                _buildAnimatedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Adresse et catégorie',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildTextField(
                        controller: _adrCtrl,
                        label: 'Adresse complète',
                        icon: Icons.home_outlined,
                        validator: _requiredValidator,
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 8),
                      _buildCategorySelector(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}