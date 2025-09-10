import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/auth/signup.dart';
import 'package:garagelink/components/custom_button.dart';
import 'package:garagelink/components/custom_text_form.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/providers/login_providers.dart';
import 'package:garagelink/services/auth_service.dart';
import 'package:garagelink/utils/input_formatters.dart';
import 'package:get/get.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class LoginPage extends ConsumerStatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final RegExp tunisianPhoneRegExp = RegExp(r'^\+216\d{8}$');

  bool _usePhoneLogin = false;
  bool _codeSent = false;
  bool _isLoading = false;

  late AnimationController _toggleController;
  late AnimationController _slideController;
  late Animation<Offset> _emailSlideAnimation;
  late Animation<Offset> _phoneSlideAnimation;

  late final TextEditingController phoneController;
  late final TextEditingController otpController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();

    _toggleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _emailSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0)).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _phoneSlideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    emailController = ref.read(loginEmailControllerProvider);
    passwordController = ref.read(loginPasswordControllerProvider);
    phoneController = ref.read(numberControllerProvider);
    otpController = TextEditingController();

    emailController.addListener(_updateEmail);
    passwordController.addListener(_updatePassword);
  }

  void _updateEmail() {
    if (mounted) {
      ref.read(loginEmailProvider.notifier).state = emailController.text;
    }
  }

  void _updatePassword() {
    if (mounted) {
      ref.read(loginPasswordProvider.notifier).state = passwordController.text;
    }
  }

  @override
  void dispose() {
    _toggleController.dispose();
    _slideController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void _toggleLoginMode() {
    setState(() {
      _usePhoneLogin = !_usePhoneLogin;
      _codeSent = false;
      phoneController.clear();
      otpController.clear();

      if (_usePhoneLogin) {
        _toggleController.forward();
        _slideController.forward();
        phoneController.text = '+216';
        phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: phoneController.text.length),
        );
      } else {
        _toggleController.reverse();
        _slideController.reverse();
      }
    });
  }

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
  void _handleApiResult(
    Map<String, dynamic> res, {
    bool successIsError = false,
    VoidCallback? onSuccess,
  }) {
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
      if (res.containsKey('devMessage'))
        print('[API DEBUG] devMessage: ${res['devMessage']}');
      if (res.containsKey('statusCode'))
        print('[API DEBUG] statusCode: ${res['statusCode']}');
      if (res.containsKey('body')) print('[API DEBUG] body: ${res['body']}');
    }
  }

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
          AnimatedBuilder(
            animation: _toggleController,
            builder: (context, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _usePhoneLogin ? 160 : 0,
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => !_usePhoneLogin ? null : _toggleLoginMode(),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: !_usePhoneLogin
                              ? Colors.white
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Email',
                          style: TextStyle(
                            color: !_usePhoneLogin
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
              Expanded(
                child: GestureDetector(
                  onTap: () => _usePhoneLogin ? null : _toggleLoginMode(),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_android,
                          color: _usePhoneLogin
                              ? Colors.white
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Téléphone',
                          style: TextStyle(
                            color: _usePhoneLogin
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

  Widget _buildEmailForm() {
    return SlideTransition(
      position: _emailSlideAnimation,
      child: Column(
        children: [
          CustomButton(
            text: 'Connexion avec Google',
            onPressed: () =>
                ref.read(authServiceProvider).signInWithGoogle(context),
            icon: Icons.g_mobiledata,
            backgroundColor: const Color(0xFFDB4437),
          ),
          const SizedBox(height: 30),
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.grey)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OU',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 30),
          CustomTextForm(
            hinttext: 'Adresse email',
            mycontroller: emailController,
          ),
          const SizedBox(height: 20),
          CustomTextForm(
            hinttext: 'Mot de passe',
            mycontroller: passwordController,
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.toNamed('/resetPassword'),
              child: const Text(
                "Mot de passe oublié ?",
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          CustomButton(
            text: _isLoading ? 'Connexion...' : 'Se connecter',
            onPressed: _isLoading ? () {} : () => _handleEmailLogin(),
            icon: Icons.login,
            backgroundColor: const Color(0xFF4A90E2),
          ),
        ],
      ),
    );
  }
  void _showVerificationDialogWithCheck(BuildContext context, User user) {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.warning,
    title: 'Email non vérifié',
    desc: 'Votre compte n\'est pas encore vérifié. Voulez-vous renvoyer un email de vérification ?',
    btnCancelText: 'Annuler',
    btnOkText: 'Renvoyer',
    btnCancelOnPress: () async {
      // Optionnel : déconnecter l'utilisateur si il annule explicitement
      try {
        await FirebaseAuth.instance.signOut();
        _handleApiResult({
          'success': true,
          'message': 'Déconnecté.',
          'devMessage': 'User signed out after cancelling verification dialog',
        });
      } catch (e) {
        if (kDebugMode) print('[LOGIN DEBUG] signOut error: $e');
      }
    },
    btnOkOnPress: () async {
      try {
        await user.sendEmailVerification();
        if (context.mounted) {
          _handleApiResult({
            'success': true,
            'message': 'Email de vérification renvoyé.',
            'devMessage': 'Email verification sent via Firebase',
          }, onSuccess: null);
        }
      } catch (e) {
        if (context.mounted) {
          _handleApiResult({
            'success': false,
            'message': 'Erreur lors de l\'envoi de l\'email: ${e.toString()}',
            'devMessage': e.toString(),
          });
        }
      }
    },
  ).show();

  // SnackBar avec action "J'ai vérifié" — permet de relire l'état et rediriger
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Après avoir cliqué sur le lien, appuyez sur "Vérifier".'),
      action: SnackBarAction(
        label: 'Vérifier',
        onPressed: () async {
          try {
            // reload du user courant et vérification
            await FirebaseAuth.instance.currentUser?.reload();
            final reloaded = FirebaseAuth.instance.currentUser;
            if (kDebugMode) {
              print('[LOGIN DEBUG] after manual reload: emailVerified=${reloaded?.emailVerified}');
            }
            if (reloaded != null && reloaded.emailVerified) {
              // Rediriger vers home
              Get.offAllNamed(AppRoutes.mecaHome);
            } else {
              _handleApiResult({
                'success': false,
                'message': 'Email toujours non vérifié. Vérifiez le lien dans votre boite mail.',
                'devMessage': 'emailVerified still false after reload',
              });
            }
          } catch (e) {
            _handleApiResult({
              'success': false,
              'message': 'Erreur lors de la vérification: ${e.toString()}',
              'devMessage': e.toString(),
            });
          }
        },
      ),
      duration: const Duration(seconds: 10),
    ),
  );
}

  Widget _buildPhoneForm() {
    return SlideTransition(
      position: _phoneSlideAnimation,
      child: Column(
        children: [
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
          if (_codeSent) ...[
            const SizedBox(height: 20),
            CustomTextForm(
              hinttext: 'Code de vérification (6 chiffres)',
              mycontroller: otpController,
            ),
          ],
          const SizedBox(height: 30),
          CustomButton(
            text: _isLoading
                ? (_codeSent ? 'Vérification...' : 'Envoi...')
                : (_codeSent ? 'Vérifier le code' : 'Envoyer le code'),
            onPressed: _isLoading ? () {} : _handlePhoneAuth,
            icon: Icons.phone_android,
            backgroundColor: const Color(0xFF4A90E2),
          ),
        ],
      ),
    );
  }
Future<void> _handleEmailLogin() async {
  if (emailController.text.isEmpty || passwordController.text.isEmpty) {
    _handleApiResult({
      'success': false,
      'message': 'Veuillez remplir tous les champs',
      'devMessage': 'Missing email or password in login form',
    });
    return;
  }

  setState(() => _isLoading = true);

  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    // Récupérer le user et forcer un reload pour obtenir un emailVerified à jour
    User? user = credential.user ?? FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
    }

    if (kDebugMode) {
      print('[LOGIN DEBUG] user after signIn: uid=${user?.uid} emailVerified=${user?.emailVerified}');
    }

    if (user != null && !user.emailVerified) {
      // Afficher dialog de vérification sans déconnecter immédiatement
      if (mounted) _showVerificationDialogWithCheck(context, user);
      return;
    }

    // Si tout est ok -> navigation vers la page principale
    Get.offAllNamed(AppRoutes.mecaHome);


  } on FirebaseAuthException catch (e) {
    String message = 'Erreur inconnue';
    if (e.code == 'user-not-found') {
      message = 'Aucun utilisateur trouvé pour cet email.';
    } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
      message = 'Mot de passe incorrect.';
    } else {
      message = 'Erreur: ${e.message}';
    }
    _handleApiResult({
      'success': false,
      'message': message,
      'devMessage': e.toString(),
    });
  } catch (e) {
    _handleApiResult({
      'success': false,
      'message': 'Une erreur inattendue s\'est produite',
      'devMessage': e.toString(),
    });
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _handlePhoneAuth() {
    if (!_codeSent) {
      if (phoneController.text.isEmpty) {
        _handleApiResult({
          'success': false,
          'message': 'Veuillez entrer votre numéro de téléphone',
          'devMessage': 'Phone input empty in phone auth',
        });
        return;
      }
      setState(() => _isLoading = true);
      ref
          .read(authServiceProvider)
          .signInWithPhone(
            phoneController.text,
            context,
            () {
              setState(() {
                _codeSent = true;
                _isLoading = false;
              });
            },
            (error) {
              setState(() => _isLoading = false);
              _handleApiResult({
                'success': false,
                'message': error,
                'devMessage': error,
              });
            },
          );
    } else {
      setState(() => _isLoading = true);
      ref
          .read(authServiceProvider)
          .verifySmsCode(
            otpController.text.trim(),
            context,
            isSignup: false,
            onSuccess: (User? firebaseUser) async {
              if (firebaseUser != null) {
                // Utilisateur Firebase connecté avec succès -> navigation vers l'app
                Get.offAllNamed(AppRoutes.mecaHome);
              } else {
                _handleApiResult({
                  'success': false,
                  'message': 'Échec de l\'authentification.',
                  'devMessage': 'verifySmsCode returned null user',
                });
              }
            },
          );
      setState(() => _isLoading = false);
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
              const SizedBox(height: 40),
              // Logo ou titre de l'app
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
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.build_circle,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'GarageLink',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Gestion intelligente de votre garage',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 50),

              // Toggle Button
              _buildToggleButton(),
              const SizedBox(height: 40),

              // Forms
              SizedBox(
                height: 400,
                child: Stack(
                  children: [
                    if (!_usePhoneLogin) _buildEmailForm(),
                    if (_usePhoneLogin) _buildPhoneForm(),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.to(() => SignUpPage()),
                child: RichText(
                  text: const TextSpan(
                    text: 'Nouveau utilisateur ? ',
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'Créer un compte',
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
