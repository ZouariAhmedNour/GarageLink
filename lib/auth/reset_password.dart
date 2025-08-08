import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:garagelink/components/custom_button.dart';
import 'package:garagelink/components/custom_text_form.dart';

// 📧 PAGE DE RÉINITIALISATION DE MOT DE PASSE - GARAGELINK ERP
// ===========================================================
// Page moderne avec design cohérent avec Login et SignUp

class ResetPasswordPage extends StatefulWidget {
  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final emailController = TextEditingController();

  void _sendResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text("Veuillez entrer un email."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text("Email de réinitialisation envoyé."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text("Échec de l'envoi de l'email."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 🎨 Background cohérent
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              
              // 🔙 HEADER AVEC NAVIGATION
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2), // Bleu cohérent avec Login/SignUp
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
                  Icons.lock_reset,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              
              // 📝 TITRE ET SOUS-TITRE
              const Text(
                'Réinitialiser le mot de passe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Entrez votre email pour recevoir un lien de réinitialisation',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),
              
              // 📧 FORMULAIRE
              CustomTextForm(
                hinttext: 'Adresse email',
                mycontroller: emailController,
              ),
              const SizedBox(height: 30),
              
              // ✅ BOUTON D'ACTION
              CustomButton(
                text: 'Envoyer l\'email de réinitialisation',
                backgroundColor: const Color(0xFF4A90E2),
                onPressed: _sendResetEmail,
              ),
              
              const SizedBox(height: 25),
              
              // 🔗 LIEN VERS CONNEXION
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    text: 'Retour à la connexion ',
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