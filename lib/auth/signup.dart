import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:garagelink/MecanicienScreens/edit_localisation.dart';
import 'package:garagelink/auth/login.dart';
import 'package:garagelink/components/custom_button.dart';
import 'package:garagelink/components/custom_text_form.dart';
import 'package:garagelink/providers/signup_providers.dart';
import 'package:garagelink/services/user_api.dart';
import 'package:garagelink/utils/input_formatters.dart';
import 'package:get/get.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage>
    with TickerProviderStateMixin {
  // Regex téléphone tunisien (ex: +21612345678)
  final RegExp tunisianPhoneRegExp = RegExp(r'^\+216\d{8}$');

  bool _usePhoneSignup = false;
  bool _codeSent = false;
  bool _isLoading = false;

  late AnimationController _toggleController;
  late AnimationController _slideController;
  late Animation<Offset> _emailSlideAnimation;
  late Animation<Offset> _phoneSlideAnimation;

  final TextEditingController otpController = TextEditingController();

  // verificationId retourné par Firebase lors du codeSent
  String? _verificationId;

  @override
  void initState() {
    super.initState();

    _toggleController =
        AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _slideController =
        AnimationController(duration: const Duration(milliseconds: 400), vsync: this);

    _emailSlideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0))
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
    _phoneSlideAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _toggleController.dispose();
    _slideController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void _toggleSignupMode() {
    setState(() {
      _usePhoneSignup = !_usePhoneSignup;
      _codeSent = false;
      otpController.clear();

      if (_usePhoneSignup) {
        _toggleController.forward();
        _slideController.forward();
        final phoneCtrl = ref.read(phoneControllerProvider);
        phoneCtrl.text = '+216';
        phoneCtrl.selection = TextSelection.fromPosition(TextPosition(offset: phoneCtrl.text.length));
      } else {
        _toggleController.reverse();
        _slideController.reverse();
      }
    });
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

  void _handleApiResult(Map<String, dynamic> res,
      {bool successIsError = false, VoidCallback? onSuccess}) {
    final msg = (res['message'] as String?) ?? 'Une erreur est survenue.';
    final isError = !(res['success'] == true) || successIsError;

    _showSnackBar(msg, isError: isError);
    if (res['success'] == true && onSuccess != null) onSuccess();

    if (kDebugMode) {
      debugPrint('[API DEBUG] message: $msg');
      if (res.containsKey('devMessage')) debugPrint('[API DEBUG] devMessage: ${res['devMessage']}');
      if (res.containsKey('statusCode')) debugPrint('[API DEBUG] statusCode: ${res['statusCode']}');
      if (res.containsKey('body')) debugPrint('[API DEBUG] body: ${res['body']}');
    }
  }

  Widget _buildToggleButton() {
    return Container(
      width: 320,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.grey[300],
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
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
                    boxShadow: [BoxShadow(color: const Color(0xFF4A90E2).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => !_usePhoneSignup ? null : _toggleSignupMode(),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined, color: !_usePhoneSignup ? Colors.white : Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text('Email', style: TextStyle(color: !_usePhoneSignup ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _usePhoneSignup ? null : _toggleSignupMode(),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android, color: _usePhoneSignup ? Colors.white : Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text('Téléphone', style: TextStyle(color: _usePhoneSignup ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 16)),
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

  Widget _buildEmailForm() {
    final usernameCtrl = ref.watch(usernameControllerProvider);
    final emailCtrl = ref.watch(emailControllerProvider);
    final phoneCtrl = ref.watch(phoneControllerProvider);
    final passwordCtrl = ref.watch(passwordControllerProvider);
    final confirmPasswordCtrl = ref.watch(confirmPasswordControllerProvider);

    return SlideTransition(
      position: _emailSlideAnimation,
      child: Column(
        children: [
          CustomTextForm(hinttext: 'Nom complet', mycontroller: usernameCtrl),
          const SizedBox(height: 20),
          CustomTextForm(hinttext: 'Adresse email', mycontroller: emailCtrl),
          const SizedBox(height: 20),
          CustomTextForm(hinttext: 'Numéro de téléphone', mycontroller: phoneCtrl),
          const SizedBox(height: 20),
          CustomTextForm(hinttext: 'Mot de passe', mycontroller: passwordCtrl),
          const SizedBox(height: 20),
          CustomTextForm(hinttext: 'Confirmer le mot de passe', mycontroller: confirmPasswordCtrl),
          const SizedBox(height: 30),
          CustomButton(
            text: _isLoading ? 'Création du compte...' : 'Créer un compte',
            backgroundColor: const Color(0xFF4A90E2),
            onPressed: _isLoading ? null : () => _handleEmailSignup(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm() {
    final phoneCtrl = ref.watch(phoneControllerProvider);

    return SlideTransition(
      position: _phoneSlideAnimation,
      child: Column(
        children: [
          CustomTextForm(
            hinttext: 'Numéro de téléphone',
            mycontroller: phoneCtrl,
            inputFormatters: [TunisiePhoneFormatter()],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez entrer un numéro';
              if (!tunisianPhoneRegExp.hasMatch(value)) return 'Numéro tunisien invalide. Format: +216********';
              return null;
            },
          ),
          if (_codeSent) ...[
            const SizedBox(height: 20),
            CustomTextForm(hinttext: 'Code de vérification (6 chiffres)', mycontroller: otpController),
          ],
          const SizedBox(height: 30),
          CustomButton(
            text: _isLoading ? (_codeSent ? 'Vérification...' : 'Envoi...') : (_codeSent ? 'Vérifier le code' : 'Envoyer le code'),
            backgroundColor: const Color(0xFF4A90E2),
            onPressed: _isLoading ? () {} : () => _handlePhoneSignup(),
          ),
        ],
      ),
    );
  }

  // Flow email -> ouvre EditLocalisation pour compléter la localisation avant d'appeler l'API
  Future<void> _handleEmailSignup() async {
    final usernameCtrl = ref.read(usernameControllerProvider);
    final emailCtrl = ref.read(emailControllerProvider);
    final phoneCtrl = ref.read(phoneControllerProvider);
    final passwordCtrl = ref.read(passwordControllerProvider);
    final confirmPasswordCtrl = ref.read(confirmPasswordControllerProvider);

    if (usernameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty || confirmPasswordCtrl.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    if (passwordCtrl.text != confirmPasswordCtrl.text) {
      _showSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final passedData = {
        "username": usernameCtrl.text.trim(),
        "garagenom": ref.read(garageNameProvider),
        "matriculefiscal": ref.read(matriculeFiscalProvider),
        "email": emailCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
      };

      // Navigation pour compléter adresse/localisation
      Get.to(() => EditLocalisation(), arguments: passedData);
    } catch (e) {
      _showSnackBar("Erreur: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Flow téléphone : envoi du code via Firebase et vérification
  Future<void> _handlePhoneSignup() async {
    final phoneCtrl = ref.read(phoneControllerProvider);
    final phone = phoneCtrl.text.trim();

    if (!_codeSent) {
      if (phone.isEmpty) {
        _showSnackBar('Veuillez entrer votre numéro de téléphone');
        return;
      }
      if (!tunisianPhoneRegExp.hasMatch(phone)) {
        _showSnackBar('Numéro tunisien invalide. Format: +216********');
        return;
      }

      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            // connexion automatique (rare sur émulateur)
            try {
              final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
              if (kDebugMode) debugPrint('Firebase auto login success: ${userCred.user?.uid}');
              // si la connexion réussit, enregistre l'utilisateur côté backend
              await _registerBackendAfterFirebase(phone);
            } catch (e) {
              if (kDebugMode) debugPrint('Auto sign-in error: $e');
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            if (kDebugMode) debugPrint('verifyPhone failed: ${e.toString()}');
            if (mounted) {
              setState(() => _isLoading = false);
              _showSnackBar('Erreur envoi SMS: ${e.message ?? e.code}');
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            if (!mounted) return;
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _isLoading = false;
            });
            _showSnackBar('Code envoyé', isError: false);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Timeout, on sauvegarde quand même l'id
            _verificationId = verificationId;
          },
        );
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        _showSnackBar('Erreur lors de l\'envoi du SMS: ${e.toString()}');
      }
    } else {
      // Vérification manuelle du code
      final smsCode = otpController.text.trim();
      if (smsCode.isEmpty) {
        _showSnackBar('Veuillez saisir le code reçu');
        return;
      }
      if (_verificationId == null) {
        _showSnackBar('ID de vérification manquant. Renvoyez le code.');
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        final credential = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: smsCode);
        final userCred = await FirebaseAuth.instance.signInWithCredential(credential);

        if (userCred.user != null) {
          // inscription côté backend après réussite Firebase
          await _registerBackendAfterFirebase(userCred.user!.phoneNumber ?? phone);
        } else {
          _showSnackBar('Échec de l\'authentification Firebase', isError: true);
        }
      } on FirebaseAuthException catch (e) {
        _showSnackBar('Erreur vérification OTP: ${e.message ?? e.code}');
      } catch (e) {
        _showSnackBar('Erreur: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Appelle ton backend pour créer l'utilisateur après succès Firebase
  Future<void> _registerBackendAfterFirebase(String phone) async {
    try {
      // utilise les values pré-remplies des providers
      final username = ref.read(usernameProvider);
      final email = ref.read(emailProvider);
      final garagenom = ref.read(garageNameProvider);
      final matricule = ref.read(matriculeFiscalProvider);
      final password = ref.read(passwordProvider); // placeholder

      // Appel API
      final createdUser = await UserApi.register(
        username: username.isEmpty ? 'Utilisateur $phone' : username,
        garagenom: garagenom,
        matriculefiscal: matricule,
        email: email,
        password: password,
        phone: phone,
      );

      // Succès -> informer l'utilisateur et rediriger vers login
      _handleApiResult({'success': true, 'message': 'Inscription réussie'});
      if (mounted) {
        // optionnel : tu peux stocker createdUser via authNotifierProvider si besoin
        Get.off(() => const LoginPage());
      }
    } catch (e) {
      // si backend échoue, préviens l'utilisateur (mais Firebase compte existe déjà)
      _handleApiResult({'success': false, 'message': 'Erreur backend: ${e.toString()}'}); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Row(
                children: [
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50))),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF4A90E2).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: const Icon(Icons.person_add, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 25),
              const Text('Créer un compte', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 10),
              Text('Rejoignez GarageLink aujourd\'hui', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w400)),
              const SizedBox(height: 40),
              _buildToggleButton(),
              const SizedBox(height: 35),
              SizedBox(
                height: _usePhoneSignup ? (_codeSent ? 250 : 180) : 450,
                child: Stack(
                  children: [
                    if (!_usePhoneSignup) _buildEmailForm(),
                    if (_usePhoneSignup) _buildPhoneForm(),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              TextButton(
                onPressed: () => Get.off(() => const LoginPage()),
                child: RichText(
                  text: const TextSpan(
                    text: 'Déjà un compte ? ',
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(text: 'Se connecter', style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.w600)),
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
