// lib/auth/login_page.dart
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/auth/signup.dart';
import 'package:garagelink/components/custom_button.dart';
import 'package:garagelink/components/custom_text_form.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/providers/login_providers.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/services/user_api.dart';
import 'package:garagelink/utils/input_formatters.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  final RegExp tunisianPhoneRegExp = RegExp(r'^\+216\d{8}$');

  bool _usePhoneLogin = false;
  bool _codeSent = false;
  bool _isLoading = false;

  late AnimationController _toggleController;
  late AnimationController _slideController;
  late Animation<Offset> _emailSlideAnimation;
  late Animation<Offset> _phoneSlideAnimation;

  // controllers
  late final TextEditingController phoneController;
  late final TextEditingController otpController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  // verification id for phone auth
  String? _verificationId;

  @override
  void initState() {
    super.initState();

    _toggleController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);

    _emailSlideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0))
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
    _phoneSlideAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));

    // controllers from providers for email/password (these providers create & dispose controllers)
    emailController = ref.read(loginEmailControllerProvider);
    passwordController = ref.read(loginPasswordControllerProvider);

    // local controllers for phone / otp
    phoneController = TextEditingController();
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
    // remove listeners from provider-managed controllers (we don't dispose them here)
    emailController.removeListener(_updateEmail);
    passwordController.removeListener(_updatePassword);

    // dispose local controllers
    otpController.dispose();
    phoneController.dispose();
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
        phoneController.selection = TextSelection.fromPosition(TextPosition(offset: phoneController.text.length));
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

  void _handleApiResult(
    Map<String, dynamic> res, {
    bool successIsError = false,
    VoidCallback? onSuccess,
  }) {
    final msg = (res['message'] as String?) ?? 'Une erreur est survenue.';
    final isError = !(res['success'] == true) || successIsError;

    // afficher message
    _showSnackBar(msg, isError: isError);

    if (res['success'] == true && onSuccess != null) {
      onSuccess();
    }

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
                left: _usePhoneLogin ? 160 : 0,
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
                  onTap: () => !_usePhoneLogin ? null : _toggleLoginMode(),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined, color: !_usePhoneLogin ? Colors.white : Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text('Email', style: TextStyle(color: !_usePhoneLogin ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 16)),
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
                        Icon(Icons.phone_android, color: _usePhoneLogin ? Colors.white : Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text('Téléphone', style: TextStyle(color: _usePhoneLogin ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 16)),
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
            onPressed: _handleGoogleSignIn,
            icon: Icons.g_mobiledata,
            backgroundColor: const Color(0xFFDB4437),
          ),
          const SizedBox(height: 30),
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.grey)),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
              Expanded(child: Divider(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 30),
          CustomTextForm(hinttext: 'Adresse email', mycontroller: emailController),
          const SizedBox(height: 20),
          CustomTextForm(hinttext: 'Mot de passe', mycontroller: passwordController),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.toNamed('/resetPassword'),
              child: const Text("Mot de passe oublié ?", style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 25),
          CustomButton(
            text: _isLoading ? 'Connexion...' : 'Se connecter',
            onPressed: _isLoading ? () {} : _handleEmailLogin,
            icon: Icons.login,
            backgroundColor: const Color(0xFF4A90E2),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialogWithCheck(BuildContext context, fb.User user) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'Email non vérifié',
      desc: 'Votre compte n\'est pas encore vérifié. Voulez-vous renvoyer un email de vérification ?',
      btnCancelText: 'Annuler',
      btnOkText: 'Renvoyer',
      btnCancelOnPress: () async {
        try {
          await fb.FirebaseAuth.instance.signOut();
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleApiResult({'success': true, 'message': 'Déconnecté.', 'devMessage': 'User signed out after cancelling verification dialog'});
            });
          }
        } catch (e) {
          if (kDebugMode) debugPrint('[LOGIN DEBUG] signOut error: $e');
        }
      },
      btnOkOnPress: () async {
        try {
          await user.sendEmailVerification();
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleApiResult({'success': true, 'message': 'Email de vérification renvoyé.', 'devMessage': 'Email verification sent via Firebase'});
            });
          }
        } catch (e) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleApiResult({'success': false, 'message': 'Erreur lors de l\'envoi de l\'email: ${e.toString()}', 'devMessage': e.toString()});
            });
          }
        }
      },
    ).show();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Après avoir cliqué sur le lien, appuyez sur "Vérifier".'),
          action: SnackBarAction(
            label: 'Vérifier',
            onPressed: () async {
              try {
                await fb.FirebaseAuth.instance.currentUser?.reload();
                final reloaded = fb.FirebaseAuth.instance.currentUser;
                if (kDebugMode) debugPrint('[LOGIN DEBUG] after manual reload: emailVerified=${reloaded?.emailVerified}');
                if (reloaded != null && reloaded.emailVerified) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) Get.offAllNamed(AppRoutes.mecaHome);
                  });
                } else {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _handleApiResult({'success': false, 'message': 'Email toujours non vérifié. Vérifiez le lien dans votre boite mail.', 'devMessage': 'emailVerified still false after reload'});
                    });
                  }
                }
              } catch (e) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _handleApiResult({'success': false, 'message': 'Erreur lors de la vérification: ${e.toString()}', 'devMessage': e.toString()});
                  });
                }
              }
            },
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    });
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
            onPressed: _isLoading ? () {} : _handlePhoneAuth,
            icon: Icons.phone_android,
            backgroundColor: const Color(0xFF4A90E2),
          ),
        ],
      ),
    );
  }

  // ---------------------- _handleEmailLogin (utilise UserApi + AuthNotifier) ----------------------
  Future<void> _handleEmailLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleApiResult({'success': false, 'message': 'Veuillez remplir tous les champs', 'devMessage': 'Missing email or password in login form'});
      });
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      // login via backend
      final token = await UserApi.login(email: email, password: password);

      // fetch profile
      final profile = await UserApi.getProfile(token);

      // persist in auth provider
      await ref.read(authNotifierProvider.notifier).setToken(token, userToSave: profile);

      // navigate to home
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(AppRoutes.mecaHome, arguments: {'justLoggedIn': true, 'message': 'Connecté avec succès.'});
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LOGIN DEBUG] error: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleApiResult({'success': false, 'message': e.toString()});
      });
    } finally {
      if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isLoading = false));
    }
  }
  // ---------------------- FIN _handleEmailLogin ----------------------

  // Google Sign-In using google_sign_in + FirebaseAuth
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        // cancelled
        return;
      }
      final gAuth = await gUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);

      final fb.User? fbUser = userCredential.user;
      if (fbUser != null) {
        // TODO: si ton backend nécessite d'échanger Firebase token contre un backend token,
        // fais l'appel ici (par ex. POST /auth/google avec idToken) et stocke le token via authNotifier.
        // Pour l'instant, on navigue vers home.
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(AppRoutes.mecaHome, arguments: {'justLoggedIn': true, 'message': 'Connecté via Google.'});
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LOGIN DEBUG] Google sign-in error: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleApiResult({'success': false, 'message': 'Erreur Google Sign-In: ${e.toString()}'}); 
      });
    } finally {
      if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isLoading = false));
    }
  }

  // Phone auth flow using FirebaseAuth.verifyPhoneNumber
  void _handlePhoneAuth() {
    if (!_codeSent) {
      final phone = phoneController.text.trim();
      if (phone.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleApiResult({'success': false, 'message': 'Veuillez entrer votre numéro de téléphone', 'devMessage': 'Phone input empty in phone auth'});
        });
        return;
      }

      setState(() => _isLoading = true);

      FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          // automatic verification (rare)
          try {
            final result = await FirebaseAuth.instance.signInWithCredential(credential);
            if (result.user != null) {
              if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => Get.offAllNamed(AppRoutes.mecaHome));
            }
          } catch (e) {
            if (kDebugMode) debugPrint('[PHONE AUTH] verificationCompleted error: $e');
          } finally {
            if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isLoading = false));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) debugPrint('[PHONE AUTH] verificationFailed: $e');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleApiResult({'success': false, 'message': 'Échec de l\'envoi du code: ${e.message}', 'devMessage': e.toString()});
            if (mounted) setState(() => _isLoading = false);
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {
              _codeSent = true;
              _isLoading = false;
            });
            _handleApiResult({'success': true, 'message': 'Code envoyé.'});
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } else {
      // Verify the code
      final code = otpController.text.trim();
      if (code.isEmpty || _verificationId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleApiResult({'success': false, 'message': 'Entrez le code reçu par SMS.'});
        });
        return;
      }

      setState(() => _isLoading = true);

      final credential = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: code);
      FirebaseAuth.instance.signInWithCredential(credential).then((userCred) {
        if (userCred.user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(AppRoutes.mecaHome);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleApiResult({'success': false, 'message': 'Échec de l\'authentification par SMS.'});
          });
        }
      }).catchError((err) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleApiResult({'success': false, 'message': 'Code invalide ou expiré.'});
        });
      }).whenComplete(() {
        if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isLoading = false));
      });
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF4A90E2).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: const Icon(Icons.build_circle, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 30),
              const Text('GarageLink', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 10),
              Text('Gestion intelligente de votre garage', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w400)),
              const SizedBox(height: 50),
              _buildToggleButton(),
              const SizedBox(height: 40),
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
              TextButton(onPressed: () => Get.to(() => const SignUpPage()), child: RichText(text: const TextSpan(text: 'Nouveau utilisateur ? ', style: TextStyle(color: Colors.grey), children: [TextSpan(text: 'Créer un compte', style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.w600))]))),
            ],
          ),
        ),
      ),
    );
  }
}
