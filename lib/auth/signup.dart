import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/auth/login.dart';
import 'package:garagelink/components/custom_button.dart';
import 'package:garagelink/components/custom_text_form.dart';
import 'package:garagelink/providers/signup_providers.dart';
import 'package:garagelink/services/user_api.dart';
import 'package:get/get.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  bool _isLoading = false;

  // états de validation du mot de passe
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;

  // référence locale au controller (nullable pour éviter LateError)
  TextEditingController? _pwCtrl;

  // helper: met à jour les bools depuis le texte
  void _validatePassword() {
    // si non initialisé, on ignore (sécurité)
    final controller = _pwCtrl;
    if (controller == null) return;

    final pw = controller.text;

    final newHasMinLength = pw.length >= 8;
    final newHasUppercase = RegExp(r'[A-Z]').hasMatch(pw);
    final newHasLowercase = RegExp(r'[a-z]').hasMatch(pw);
    final newHasDigit = RegExp(r'\d').hasMatch(pw);

    // ne rebuild que si quelque chose change
    if (newHasMinLength != _hasMinLength ||
        newHasUppercase != _hasUppercase ||
        newHasLowercase != _hasLowercase ||
        newHasDigit != _hasDigit) {
      setState(() {
        _hasMinLength = newHasMinLength;
        _hasUppercase = newHasUppercase;
        _hasLowercase = newHasLowercase;
        _hasDigit = newHasDigit;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Réinitialiser tous les champs (ok d'utiliser ref ici)
    ref.read(firstNameControllerProvider).clear();
    ref.read(lastNameControllerProvider).clear();
    ref.read(garageNameControllerProvider).clear();
    ref.read(matriculeFiscalControllerProvider).clear();
    ref.read(emailControllerProvider).clear();
    ref.read(phoneControllerProvider).clear();

    // lire ET garder le controller dans un champ (on n'utilisera plus ref en dispose)
    _pwCtrl = ref.read(passwordControllerProvider);
    _pwCtrl?.clear();
    _pwCtrl?.addListener(_validatePassword);

    // clear confirm password aussi si tu veux
    ref.read(confirmPasswordControllerProvider).clear();
  }

  @override
  void dispose() {
    // retirer le listener via la référence locale si existante
    _pwCtrl?.removeListener(_validatePassword);

    // Ne pas appeler ref.read(...) ici, car ref peut être déjà disposé
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildConstraintLine(bool valid, String text) {
    // petite animation visuelle (change d'icône + couleur)
    final color = valid ? Colors.green : Colors.grey[500];
    final icon = valid ? Icons.check_circle : Icons.radio_button_unchecked;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: color),
        ),
      ],
    );
  }

  Widget _buildPasswordConstraints() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConstraintLine(_hasMinLength, 'Au moins 8 caractères'),
        const SizedBox(height: 6),
        _buildConstraintLine(_hasUppercase, 'Au moins 1 lettre majuscule (A-Z)'),
        const SizedBox(height: 6),
        _buildConstraintLine(_hasLowercase, 'Au moins 1 lettre minuscule (a-z)'),
        const SizedBox(height: 6),
        _buildConstraintLine(_hasDigit, 'Au moins 1 chiffre (0-9)'),
      ],
    );
  }

  Widget _buildEmailForm() {
    final firstNameCtrl = ref.watch(firstNameControllerProvider);
    final lastNameCtrl = ref.watch(lastNameControllerProvider);
    final garageNameCtrl = ref.watch(garageNameControllerProvider);
    final matriculeFiscalCtrl = ref.watch(matriculeFiscalControllerProvider);
    final emailCtrl = ref.watch(emailControllerProvider);
    final phoneCtrl = ref.watch(phoneControllerProvider);
    final passwordCtrl = ref.watch(passwordControllerProvider);
    final confirmPasswordCtrl = ref.watch(confirmPasswordControllerProvider);

    return Column(
      children: [
        CustomTextForm(
          hinttext: 'Prénom',
          mycontroller: firstNameCtrl,
          validator: (value) =>
              value == null || value.isEmpty ? 'Veuillez entrer votre prénom' : null,
        ),
        const SizedBox(height: 20),
        CustomTextForm(
          hinttext: 'Nom',
          mycontroller: lastNameCtrl,
          validator: (value) =>
              value == null || value.isEmpty ? 'Veuillez entrer votre nom' : null,
        ),
        const SizedBox(height: 20),
        CustomTextForm(
          hinttext: 'Nom du garage',
          mycontroller: garageNameCtrl,
          validator: (value) =>
              value == null || value.isEmpty ? 'Veuillez entrer le nom du garage' : null,
        ),
        const SizedBox(height: 20),
        CustomTextForm(
          hinttext: 'Téléphone',
          mycontroller: phoneCtrl,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre numéro de téléphone';
            }

            final phone = value.trim();

            if (!RegExp(r'^\d{8}$').hasMatch(phone)) {
              return 'Le numéro doit contenir exactement 8 chiffres';
            }

            final prefix = int.tryParse(phone.substring(0, 2));
            if (prefix == null ||
                !((prefix >= 90 && prefix <= 99) ||
                    (prefix >= 50 && prefix <= 59) ||
                    (prefix >= 20 && prefix <= 29) ||
                    (prefix >= 40 && prefix <= 49))) {
              return 'Préfixe invalide (valide: 20-29, 40-49, 50-59, 90-99)';
            }

            return null;
          },
        ),
        const SizedBox(height: 20),
        CustomTextForm(
          hinttext: 'Matricule fiscal',
          mycontroller: matriculeFiscalCtrl,
          validator: (value) => value == null || value.isEmpty
              ? 'Veuillez entrer le matricule fiscal'
              : null,
        ),
        const SizedBox(height: 20),
        CustomTextForm(
          hinttext: 'Email',
          mycontroller: emailCtrl,
          validator: (value) =>
              value == null || value.isEmpty ? 'Veuillez entrer votre email' : null,
        ),
        const SizedBox(height: 20),
        // === MOT DE PASSE avec validation live ===
        CustomTextForm(
          hinttext: 'Mot de passe',
          mycontroller: passwordCtrl,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un mot de passe';
            }
            if (value.length < 8) {
              return 'Le mot de passe doit contenir au moins 8 caractères';
            }
            if (!RegExp(r'[A-Z]').hasMatch(value)) {
              return 'Ajoutez au moins une majuscule';
            }
            if (!RegExp(r'[a-z]').hasMatch(value)) {
              return 'Ajoutez au moins une minuscule';
            }
            if (!RegExp(r'\d').hasMatch(value)) {
              return 'Ajoutez au moins un chiffre';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        // affichage des contraintes sous le champ
        AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 200),
          child: _buildPasswordConstraints(),
        ),
        const SizedBox(height: 20),
        CustomTextForm(
          hinttext: 'Confirmer le mot de passe',
          mycontroller: confirmPasswordCtrl,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez confirmer le mot de passe';
            }
            if (value != passwordCtrl.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          },
        ),
        const SizedBox(height: 30),
        CustomButton(
          text: _isLoading ? 'Création...' : 'Créer mon compte',
          backgroundColor: const Color(0xFF4A90E2),
          onPressed: _isLoading ? () {} : () => _handleEmailSignup(),
        ),
      ],
    );
  }

  Future<void> _handleEmailSignup() async {
    final firstNameCtrl = ref.read(firstNameControllerProvider);
    final lastNameCtrl = ref.read(lastNameControllerProvider);
    final garageNameCtrl = ref.read(garageNameControllerProvider);
    final matriculeFiscalCtrl = ref.read(matriculeFiscalControllerProvider);
    final emailCtrl = ref.read(emailControllerProvider);
    final phoneCtrl = ref.read(phoneControllerProvider);
    final passwordCtrl = ref.read(passwordControllerProvider);
    final confirmPasswordCtrl = ref.read(confirmPasswordControllerProvider);

    if (firstNameCtrl.text.trim().isEmpty ||
        lastNameCtrl.text.trim().isEmpty ||
        garageNameCtrl.text.trim().isEmpty ||
        matriculeFiscalCtrl.text.trim().isEmpty ||
        phoneCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passwordCtrl.text.trim().isEmpty ||
        confirmPasswordCtrl.text.trim().isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    // Vérifier règles de mot de passe côté front (déjà signalé en live)
    final pw = passwordCtrl.text.trim();
    if (!(pw.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(pw) &&
        RegExp(r'[a-z]').hasMatch(pw) &&
        RegExp(r'\d').hasMatch(pw))) {
      _showSnackBar(
          'Le mot de passe doit contenir au moins 8 caractères, une majuscule, une minuscule et un chiffre.');
      return;
    }

    if (passwordCtrl.text.trim() != confirmPasswordCtrl.text.trim()) {
      _showSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    final username = "${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}";

    setState(() => _isLoading = true);

    try {
      await UserApi.register(
        username: username,
        garagenom: garageNameCtrl.text.trim(),
        matriculefiscal: matriculeFiscalCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Succès"),
          content: const Text("Votre compte a été créé avec succès."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext, rootNavigator: true).pop();
                Get.offAll(() => const LoginPage());
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}');
      if (kDebugMode) debugPrint('Signup error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: const Icon(Icons.person_add, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 25),
              const Text(
                'Créer un compte',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 10),
              Text(
                'Rejoignez GarageLink aujourd\'hui',
                style: TextStyle(
                    fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 40),
              _buildEmailForm(),
              const SizedBox(height: 25),
              TextButton(
                onPressed: () => Get.off(() => const LoginPage()),
                child: RichText(
                  text: const TextSpan(
                    text: 'Déjà un compte ? ',
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'Se connecter',
                        style: TextStyle(
                            color: Color(0xFF4A90E2), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
