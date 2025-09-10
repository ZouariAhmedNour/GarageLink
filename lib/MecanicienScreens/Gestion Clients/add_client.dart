import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/models/client.dart';
import 'package:garagelink/providers/client_provider.dart';
import 'package:garagelink/vehicules/car%20widgets/ui_constants.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _mailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adrCtrl = TextEditingController();
  
  late AnimationController _animationController;
 Animation<double>? _fadeAnimation;
  
  Categorie _cat = Categorie.particulier;
  bool _isLoading = false;

  // Palette de couleurs unifiée
  static const Color _primaryBlue = Color(0xFF357ABD);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _darkBlue = Color(0xFF1976D2);
  static const Color _errorRed = Color(0xFFD32F2F);
  static const Color _successGreen = Color(0xFF388E3C);
  static const Color _surfaceColor = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
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
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(v) ? null : 'Format email invalide (ex: nom@domaine.com)';
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.isEmpty) return 'Numéro de téléphone requis';
    final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{8,15}$');
    return phoneRegex.hasMatch(v) ? null : 'Format de téléphone invalide';
  }

  String? _requiredValidator(String? v) =>
      v == null || v.trim().isEmpty ? 'Ce champ est obligatoire' : null;

  String? _nameValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nom complet requis';
    if (v.trim().length < 2) return 'Le nom doit contenir au moins 2 caractères';
    return null;
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Client ajouté avec succès!'),
          ],
        ),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    HapticFeedback.mediumImpact();
    
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackBar('Veuillez corriger les erreurs dans le formulaire');
      return;
    }

    setState(() => _isLoading = true);

    try {
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
      
      HapticFeedback.heavyImpact();
      _showSuccessSnackBar();
      
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'ajout du client: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? helperText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon, color: _primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _errorRed, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _errorRed, width: 2),
          ),
          filled: true,
          fillColor: _surfaceColor,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.category, color: _primaryBlue),
                SizedBox(width: 12),
                Text(
                  'Catégorie de client',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryBlue.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Categorie>(
                  value: _cat,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: _primaryBlue),
                  style: const TextStyle(color: _darkBlue, fontSize: 16),
                  items: Categorie.values.map((categorie) {
                    return DropdownMenuItem(
                      value: categorie,
                      child: Row(
                        children: [
                          Icon(
                            categorie == Categorie.particulier 
                                ? Icons.person 
                                : Icons.business,
                            color: _primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            categorie == Categorie.particulier 
                                ? 'Particulier' 
                                : 'Professionnel',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _cat = value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Ajouter le client',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
  title: 'Nouveau client',
  backgroundColor: primaryBlue,

),
      body: FadeTransition(
        opacity: _fadeAnimation!,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.info_outline, color: _primaryBlue),
                              SizedBox(width: 8),
                              Text(
                                'Informations personnelles',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _darkBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildCustomTextField(
                            controller: _nomCtrl,
                            label: 'Nom complet',
                            icon: Icons.person,
                            validator: _nameValidator,
                            helperText: 'Prénom et nom du client',
                          ),
                          _buildCustomTextField(
                            controller: _mailCtrl,
                            label: 'Adresse email',
                            icon: Icons.email,
                            validator: _emailValidator,
                            keyboardType: TextInputType.emailAddress,
                            helperText: 'Email optionnel pour les notifications',
                          ),
                          _buildCustomTextField(
                            controller: _telCtrl,
                            label: 'Numéro de téléphone',
                            icon: Icons.phone,
                            validator: _phoneValidator,
                            keyboardType: TextInputType.phone,
                            helperText: 'Numéro principal de contact',
                          ),
                          _buildCustomTextField(
                            controller: _adrCtrl,
                            label: 'Adresse complète',
                            icon: Icons.location_on,
                            validator: _requiredValidator,
                            maxLines: 2,
                            helperText: 'Adresse de facturation et de correspondance',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCategorySelector(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}