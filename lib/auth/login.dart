// lib/auth/login_page.dart
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
import 'package:get/get.dart';
import 'dart:async';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  bool _isLoading = false;

  // controllers (providers create & dispose controllers)
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  // toggle visibilité mot de passe
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // controllers from providers (these providers create & dispose controllers elsewhere)
    emailController = ref.read(loginEmailControllerProvider);
    passwordController = ref.read(loginPasswordControllerProvider);
    // IMPORTANT: we do NOT add listeners that call `ref` here to avoid "ref in callbacks" issues;
    // we'll read controllers' values at submit time.
  }

  @override
  void dispose() {
    // don't dispose provider-managed controllers here
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

  void _handleApiResult(
    Map<String, dynamic> res, {
    bool successIsError = false,
    VoidCallback? onSuccess,
  }) {
    final msg = (res['message'] as String?) ?? 'Une erreur est survenue.';
    final isError = !(res['success'] == true) || successIsError;

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

  Future<void> _handleEmailLogin() async {
  final email = emailController.text.trim();
  final password = passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleApiResult({
        'success': false,
        'message': 'Veuillez remplir tous les champs',
        'devMessage': 'Missing email or password in login form'
      });
    });
    return;
  }

  if (mounted) setState(() => _isLoading = true);

  try {
    // login via backend
    final token = await UserApi.login(email: email, password: password);

    // si l'API renvoie null/empty -> considérer comme credentials invalides
    if (((token).trim().isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleApiResult({'success': false, 'message': 'Email ou mot de passe incorrects.'});
      });
      return;
    }

    // fetch profile
    final profile = await UserApi.getProfile(token);

    // persist in auth provider (stocke token + profil)
    await ref.read(authNotifierProvider.notifier).setToken(token, userToSave: profile);

    // Si profil incomplet -> rediriger vers EditLocalisation pour compléter
    final bool needsLocation = (profile.location == null) ||
        (profile.governorateId == null || profile.governorateId!.isEmpty) ||
        (profile.cityId == null || profile.cityId!.isEmpty) ||
        (profile.streetAddress.trim().isEmpty);

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (needsLocation) {
          Get.offAllNamed(
            AppRoutes.editLocalisation,
            arguments: {'token': token, 'user': profile},
          );
        } else {
          Get.offAllNamed(AppRoutes.mecaHome,
              arguments: {'justLoggedIn': true, 'message': 'Connecté avec succès.'});
        }
      });
    }
  } on Exception catch (e) {
    final msg = _loginErrorMessageFromException(e);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleApiResult({'success': false, 'message': msg});
      });
    }
  } catch (e) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleApiResult({'success': false, 'message': 'Une erreur est survenue : ${e.toString()}'
        });
      });
    }
  } finally {
    if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isLoading = false));
  }
}

// petit helper pour détecter un échec d'authentification à partir de l'exception
String _loginErrorMessageFromException(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('401') ||
      s.contains('unauthor') ||
      s.contains('invalid') ||
      s.contains('credentials') ||
      s.contains('mot de passe') ||
      s.contains('email') ||
      s.contains('identifiant')) {
    return 'Email ou mot de passe incorrects.';
  }
  // sinon renvoyer message complet (ou tu peux renvoyer un message plus générique)
  return 'Une erreur est survenue : ${e.toString()}';
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
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              // Email form
              SizedBox(
                height: 400,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    CustomTextForm(hinttext: 'Adresse email', mycontroller: emailController),
                    const SizedBox(height: 20),

                    // === Champ mot de passe avec icône "oeil" ===
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Mot de passe',
                        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                        ),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleEmailLogin(),
                    ),

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
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.to(() => const SignUpPage()),
                child: RichText(
                  text: const TextSpan(
                    text: 'Nouveau utilisateur ? ',
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(text: 'Créer un compte', style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.w600)),
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
