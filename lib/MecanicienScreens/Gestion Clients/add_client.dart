// lib/MecanicienScreens/Gestion Clients/add_client.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/models/ficheClient.dart';
import 'package:garagelink/providers/ficheClient_provider.dart';
import 'package:get/get.dart';

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

  ClientType _type = ClientType.particulier;
  bool _isLoading = false;

  // Palette locale (utilisée dans le widget)
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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

  // Validators
  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null; // email optionnel
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(v.trim()) ? null : 'Format email invalide (ex: nom@domaine.com)';
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Numéro de téléphone requis';
    final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{6,20}$');
    return phoneRegex.hasMatch(v.trim()) ? null : 'Format de téléphone invalide';
  }

  String? _requiredValidator(String? v) =>
      v == null || v.trim().isEmpty ? 'Ce champ est obligatoire' : null;

  String? _nameValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nom complet requis';
    if (v.trim().length < 2) return 'Le nom doit contenir au moins 2 caractères';
    return null;
  }

  // Snackbars
  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Client ajouté avec succès !'),
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

  // Envoi du formulaire
  Future<void> _handleSubmit() async {
    // retirer le focus clavier
    FocusScope.of(context).unfocus();

    final token = ref.read(authTokenFromAuthProvider);
    if (token == null || token.isEmpty) {
      _showErrorSnackBar('Token manquant. Veuillez vous reconnecter.');
      return;
    }

    HapticFeedback.mediumImpact();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackBar('Veuillez corriger les erreurs dans le formulaire');
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    final nom = _nomCtrl.text.trim();
    final email = _mailCtrl.text.trim();
    final telephone = _telCtrl.text.trim();
    final adresse = _adrCtrl.text.trim();

    try {
      // Appel du provider
      await ref.read(ficheClientsProvider.notifier).addFicheClient(
            nom: nom,
            type: _type,
            adresse: adresse,
            telephone: telephone,
            email: email,
          );

      // Vérifier si le provider a signalé une erreur
      final err = ref.read(ficheClientsProvider).error;
      if (err != null && err.isNotEmpty) {
        _showErrorSnackBar('Erreur: $err');
      } else {
        HapticFeedback.heavyImpact();
        _showSuccessSnackBar();
        // Réinitialiser le formulaire
        _formKey.currentState?.reset();
        _nomCtrl.clear();
        _mailCtrl.clear();
        _telCtrl.clear();
        _adrCtrl.clear();
        if (mounted) setState(() => _type = ClientType.particulier);

        // Retour à l'écran précédent (on signale true si on veut)
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          Get.back(result: true);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'ajout du client: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Widgets réutilisables
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

  Widget _buildTypeSelector() {
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
              children: [
                Icon(Icons.category, color: _primaryBlue),
                const SizedBox(width: 12),
                Text(
                  'Type de client',
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
                child: DropdownButton<ClientType>(
                  value: _type,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: _primaryBlue),
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  items: ClientType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(
                            t == ClientType.particulier ? Icons.person : Icons.business,
                            color: _primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t == ClientType.particulier ? 'Particulier' : 'Professionnel',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _type = value);
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
        backgroundColor: _primaryBlue,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation ?? kAlwaysCompleteAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    color: Colors.white,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: _primaryBlue),
                              const SizedBox(width: 8),
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
                  _buildTypeSelector(),
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
