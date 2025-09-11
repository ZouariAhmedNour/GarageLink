import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:garagelink/MecanicienScreens/edit_localisation.dart';
import 'package:garagelink/auth/login.dart';
import 'package:garagelink/components/custom_button.dart';
import 'package:garagelink/components/custom_text_form.dart';
import 'package:garagelink/providers/signup_providers.dart';
import 'package:garagelink/services/user_service_api.dart';
import 'package:garagelink/utils/input_formatters.dart';
import 'package:get/get.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage>
    with TickerProviderStateMixin {
  // 🔧 CONFIGURATION ET VALIDATION
  // ===============================
  final RegExp tunisianPhoneRegExp = RegExp(r'^\+216\d{8}\$');

  // 📊 ÉTATS DE L'INTERFACE
  // =======================
  bool _usePhoneSignup = false; // Mode téléphone vs email
  bool _codeSent = false; // État d'envoi du code SMS
  bool _isLoading = false; // État de chargement

  // 🎬 CONTRÔLEURS D'ANIMATION
  // ==========================
  late AnimationController _toggleController; // Animation du toggle
  late AnimationController _slideController; // Animation des slides
  late Animation<Offset> _emailSlideAnimation; // Slide formulaire email
  late Animation<Offset> _phoneSlideAnimation; // Slide formulaire téléphone

  // 📝 CONTRÔLEUR DE SAISIE
  // ========================
  final TextEditingController otpController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 🎯 INITIALISATION DES ANIMATIONS
    // =================================
    _toggleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // 📐 CONFIGURATION DES TRANSITIONS
    // ================================
    _emailSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0)).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _phoneSlideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // 🧹 NETTOYAGE DES RESSOURCES
    // ============================
    _toggleController.dispose();
    _slideController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // 🔄 GESTION DU TOGGLE ENTRE MODES
  // =================================
  void _toggleSignupMode() {
    setState(() {
      _usePhoneSignup = !_usePhoneSignup;
      _codeSent = false;
      otpController.clear();

      if (_usePhoneSignup) {
        // 📱 Passage au mode téléphone
        _toggleController.forward();
        _slideController.forward();
        final phoneController = ref.read(numberControllerProvider);
        phoneController.text = '+216';
        phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: phoneController.text.length),
        );
      } else {
        // 📧 Passage au mode email
        _toggleController.reverse();
        _slideController.reverse();
      }
    });
  }

  // 📢 SYSTÈME DE NOTIFICATIONS
  // ============================
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Handle response maps from UserService and show SnackBar + debug print
  void _handleApiResult(Map<String, dynamic> res,
      {bool successIsError = false, VoidCallback? onSuccess}) {
    // Affiche un message utilisateur via SnackBar (champ 'message' retourné par UserService)
    final msg = (res['message'] as String?) ?? 'Une erreur est survenue.';
    final isError = !(res['success'] == true) || successIsError;

    _showSnackBar(msg, isError: isError);

    // Si succès et callback fourni -> appelle le callback
    if (res['success'] == true && onSuccess != null) {
      onSuccess();
    }

    // Log détaillé pour dev/admin (seulement en debug)
    if (kDebugMode) {
      print('[API DEBUG] message: $msg');
      if (res.containsKey('devMessage')) print('[API DEBUG] devMessage: ${res['devMessage']}');
      if (res.containsKey('statusCode')) print('[API DEBUG] statusCode: ${res['statusCode']}');
      if (res.containsKey('body')) print('[API DEBUG] body: ${res['body']}');
    }
  }

  // 🎚️ WIDGET TOGGLE ANIMÉ
  // =======================
  Widget _buildToggleButton() {
    return Container(
      width: 320,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.grey[300],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 🎯 INDICATEUR ANIMÉ
          AnimatedBuilder(
            animation: _toggleController,
            builder: (context, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _usePhoneSignup ? 160 : 0,
                child: Container(
                  width: 160,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: const Color(0xFF4A90E2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A90E2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // 📱📧 BOUTONS DE SÉLECTION
          Row(
            children: [
              // 📧 MODE EMAIL
              Expanded(
                child: GestureDetector(
                  onTap: () => !_usePhoneSignup ? null : _toggleSignupMode(),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: !_usePhoneSignup
                              ? Colors.white
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Email',
                          style: TextStyle(
                            color: !_usePhoneSignup
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 📱 MODE TÉLÉPHONE
              Expanded(
                child: GestureDetector(
                  onTap: () => _usePhoneSignup ? null : _toggleSignupMode(),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_android,
                          color: _usePhoneSignup
                              ? Colors.white
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Téléphone',
                          style: TextStyle(
                            color: _usePhoneSignup
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📧 FORMULAIRE D'INSCRIPTION EMAIL
  // ==================================
  Widget _buildEmailForm() {
    final fullNameController = ref.watch(fullNameControllerProvider);
    final emailController = ref.watch(emailControllerProvider);
    final phoneController = ref.watch(numberControllerProvider);
    final passwordController = ref.watch(passwordControllerProvider);
    final confirmPasswordController = ref.watch(
      confirmPasswordControllerProvider,
    );

    return SlideTransition(
      position: _emailSlideAnimation,
      child: Column(
        children: [
          // 👤 NOM COMPLET
          CustomTextForm(
            hinttext: 'Nom complet',
            mycontroller: fullNameController,
          ),
          const SizedBox(height: 20),
          // 📧 EMAIL
          CustomTextForm(
            hinttext: 'Adresse email',
            mycontroller: emailController,
          ),
          const SizedBox(height: 20),
          // 📱 TÉLÉPHONE
          CustomTextForm(
            hinttext: 'Numéro de téléphone',
            mycontroller: phoneController,
          ),
          const SizedBox(height: 20),
          // 🔐 MOT DE PASSE
          CustomTextForm(
            hinttext: 'Mot de passe',
            mycontroller: passwordController,
          ),
          const SizedBox(height: 20),
          // 🔐 CONFIRMATION MOT DE PASSE
          CustomTextForm(
            hinttext: 'Confirmer le mot de passe',
            mycontroller: confirmPasswordController,
          ),
          const SizedBox(height: 30),
          // ✅ BOUTON D'INSCRIPTION
          CustomButton(
            text: _isLoading ? 'Création du compte...' : 'Créer un compte',
            backgroundColor: const Color(0xFF4A90E2),
            onPressed: _isLoading ? null : () => _handleEmailSignup(),
          ),
        ],
      ),
    );
  }

  // 📱 FORMULAIRE D'INSCRIPTION TÉLÉPHONE
  // =====================================
  Widget _buildPhoneForm() {
    final phoneController = ref.watch(numberControllerProvider);

    return SlideTransition(
      position: _phoneSlideAnimation,
      child: Column(
        children: [
          // 📱 NUMÉRO DE TÉLÉPHONE
          CustomTextForm(
            hinttext: 'Numéro de téléphone',
            mycontroller: phoneController,
            inputFormatters: [TunisiePhoneFormatter()],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un numéro';
              }
              if (!tunisianPhoneRegExp.hasMatch(value)) {
                return 'Numéro tunisien invalide. Format: +216********';
              }
              return null;
            },
          ),
          // 🔢 CODE OTP (si envoyé)
          if (_codeSent) ...[
            const SizedBox(height: 20),
            CustomTextForm(
              hinttext: 'Code de vérification (6 chiffres)',
              mycontroller: otpController,
            ),
          ],
          const SizedBox(height: 30),
          // 📤 BOUTON D'ACTION
          CustomButton(
            text: _isLoading
                ? (_codeSent ? 'Vérification...' : 'Envoi...')
                : (_codeSent ? 'Vérifier le code' : 'Envoyer le code'),
            backgroundColor: const Color(0xFF4A90E2),
            onPressed: _isLoading ? () {} : () => _handlePhoneSignup(),
          ),
        ],
      ),
    );
  }

  // 📧 GESTION INSCRIPTION EMAIL
  // =============================
Future<void> _handleEmailSignup() async {
  final fullNameController = ref.read(fullNameControllerProvider);
  final emailController = ref.read(emailControllerProvider);
  final phoneController = ref.read(numberControllerProvider);
  final passwordController = ref.read(passwordControllerProvider);
  final confirmPasswordController = ref.read(confirmPasswordControllerProvider);

  if (fullNameController.text.isEmpty ||
      emailController.text.isEmpty ||
      passwordController.text.isEmpty ||
      confirmPasswordController.text.isEmpty) {
    _showSnackBar('Veuillez remplir tous les champs');
    return;
  }

  if (passwordController.text != confirmPasswordController.text) {
    _showSnackBar('Les mots de passe ne correspondent pas');
    return;
  }

  setState(() => _isLoading = true);

 try {
  // validation OK -> ne pas appeler userService.register ici
  final passedData = {
    "username": fullNameController.text.trim(),
    "garagenom": "Mon Garage",
    "matriculefiscal": "123456",
    "email": emailController.text.trim(),
    "password": passwordController.text.trim(),
    "phone": phoneController.text.trim(),
    // NE PAS inclure userId ici (on n'a pas encore créé l'utilisateur)
  };

  // Navigation vers EditLocalisation pour compléter adresse/localisation
  Get.to(() => EditLocalisation(), arguments: passedData);
} on Exception catch (e) {
  _showSnackBar("Erreur: $e");
} finally {
  if (mounted) setState(() => _isLoading = false);
}
}
  // 📱 GESTION INSCRIPTION TÉLÉPHONE
  // =================================
  Future<void> _handlePhoneSignup() async {
    final phoneController = ref.read(numberControllerProvider);
    final authService = ref.read(authServiceProvider);

    if (!_codeSent) {
      // 📤 ENVOI DU CODE SMS
      if (phoneController.text.isEmpty) {
        _showSnackBar('Veuillez entrer votre numéro de téléphone');
        return;
      }

      setState(() => _isLoading = true);

      authService.signUpWithPhone(
        phoneController.text,
        context,
        () {
          // ✅ SUCCÈS ENVOI
          if (mounted) {
            setState(() {
              _codeSent = true;
              _isLoading = false;
            });
          }
        },
        (error) {
          // ❌ ERREUR ENVOI
          if (mounted) {
            setState(() => _isLoading = false);
            _showSnackBar(error);
          }
        },
      );
    } else {
      // 🔢 VÉRIFICATION DU CODE
      setState(() => _isLoading = true);
      authService.verifySmsCode(
        otpController.text.trim(),
        context,
        isSignup: true,
        onSuccess: (User? firebaseUser) async {
          if (firebaseUser != null) {
            final phoneController = ref.read(numberControllerProvider);
            final userService = UserService();
            final res = await userService.register(
              username: "Utilisateur ${phoneController.text}",
              garagenom: "Mon Garage",
              matriculefiscal: "123456",
              email: "${phoneController.text}@dummy.com", // fake email si obligatoire
              password: "firebase", // mot de passe placeholder
              phone: phoneController.text,
            );

            _handleApiResult(res, onSuccess: () {
              // navigation only
              Get.off(() => LoginPage());
            });
          } else {
            _showSnackBar('Échec de l\'authentification.', isError: true);
          }
        },
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 🎨 Background moderne
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // 🔙 HEADER AVEC NAVIGATION
              // =========================
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 20),

              // 🏢 LOGO DE L'APPLICATION
              // ========================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2), // Aligné avec LoginPage
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),

              // 📝 TITRE ET SOUS-TITRE
              // =======================
              const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Rejoignez GarageLink aujourd\'hui',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),

              // 🎚️ TOGGLE ENTRE MODES
              // ======================
              _buildToggleButton(),
              const SizedBox(height: 35),

              // 📋 FORMULAIRES DYNAMIQUES
              // ==========================
              SizedBox(
                height: _usePhoneSignup
                    ? (_codeSent ? 250 : 180)
                    : 450, // Hauteur adaptative
                child: Stack(
                  children: [
                    if (!_usePhoneSignup) _buildEmailForm(),
                    if (_usePhoneSignup) _buildPhoneForm(),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 🔗 LIEN VERS CONNEXION
              // =======================
              TextButton(
                onPressed: () => Get.off(() => LoginPage()),
                child: RichText(
                  text: const TextSpan(
                    text: 'Déjà un compte ? ',
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'Se connecter',
                        style: TextStyle(
                          color: Color(0xFF4A90E2),
                          fontWeight: FontWeight.w600,
                        ),
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
