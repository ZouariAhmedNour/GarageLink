import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:garagelink/configurations/app_routes.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  String? _verificationId;

  // ----------- Email / Password -----------
  Future<void> signInWithEmailAndPassword(String email, String password, BuildContext context) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      final user = _firebaseAuth.currentUser;

      if (user != null && !user.emailVerified) {
        if (context.mounted) {
          _showVerificationDialog(context, user);
        }
        await _firebaseAuth.signOut();
        return;
      }

      if (context.mounted) {
        Get.offAllNamed(AppRoutes.mecaHome);
      }
    } catch (e) {
      if (context.mounted) {
        String message = 'Une erreur est survenue';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              message = 'Aucun utilisateur trouvé pour cet email.';
              break;
            case 'wrong-password':
            case 'invalid-credential':
              message = 'Mot de passe incorrect.';
              break;
            default:
              message = 'Erreur inconnue: ${e.message}';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> sendPasswordReset(String email, BuildContext context) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien de réinitialisation envoyé.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _showVerificationDialog(BuildContext context, User user) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'Email non vérifié',
      desc: 'Votre compte n\'est pas encore vérifié. Voulez-vous renvoyer un email de vérification ?',
      btnCancelText: 'Annuler',
      btnOkText: 'Envoyer',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          await user.sendEmailVerification();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email de vérification envoyé.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${e.toString()}')),
            );
          }
        }
      },
    ).show();
  }

  // ----------- Google Sign-In -----------
  Future<void> signInWithGoogle(BuildContext context) async {
  try {
    await _googleSignIn.signOut(); // 👈 Forcer à rechoisir un compte

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion Google annulée.')),
        );
      }
      return;
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);

    final user = _firebaseAuth.currentUser;
    if (user != null && context.mounted) {
      Get.offAllNamed(AppRoutes.mecaHome);
    }

  } catch (e) {
    print('Erreur Google Sign-In: $e');
    if (context.mounted) {
      final message = (e is PlatformException && e.code == '10')
          ? 'Erreur de configuration Google Sign-In.'
          : 'Erreur lors de la connexion Google: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

  // ----------- Phone Sign-In / Sign-Up -----------
  Future<void> signInWithPhone(
    String phoneNumber,
    BuildContext context,
    void Function() onCodeSent,
    void Function(String error) onError,
  ) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        _handlePostPhoneLogin(userCredential, context);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? "Échec de la vérification.");
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifySmsCode(String smsCode, BuildContext context, {required bool isSignup}) async {
  if (_verificationId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID de vérification non trouvé.')),
    );
    return;
  }

  final credential = PhoneAuthProvider.credential(
    verificationId: _verificationId!,
    smsCode: smsCode,
  );

  try {
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    if (isSignup) {
      _handlePostPhoneSignup(userCredential, context);
    } else {
      _handlePostPhoneLogin(userCredential, context);
    }
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? 'Code invalide')),
    );
  }
}

  Future<void> signUpWithPhone(
    String phoneNumber,
    BuildContext context,
    void Function() onCodeSent,
    void Function(String error) onError,
  ) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Éviter la redirection automatique vers login
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        _handlePostPhoneSignup(userCredential, context);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? "Échec de la vérification.");
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _handlePostPhoneLogin(UserCredential userCredential, BuildContext context) {
    final user = userCredential.user;
    if (user != null && context.mounted) {
      Get.offAllNamed(AppRoutes.mecaHome);
    }
  }

  void _handlePostPhoneSignup(UserCredential userCredential, BuildContext context) {
    final user = userCredential.user;
    if (user != null && context.mounted) {
      // Rediriger vers complete_profile pour les nouveaux utilisateurs
      Get.offAllNamed(AppRoutes.completeProfile);
    }
  }
}