import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:garagelink/auth/login.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';


class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final double? fontSize;
  const DefaultAppBar({Key? key,
   this.title,
   this.fontSize,});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
     title: title != null
          ? Text(
              title!,
              style: TextStyle(fontSize: fontSize ?? 20.0), // Taille par défaut de 20.0 si non spécifiée
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            final GoogleSignIn googleSignIn = GoogleSignIn();
            try {
              await googleSignIn.signOut(); // Utilisez signOut au lieu de disconnect
              await FirebaseAuth.instance.signOut();
              Get.offAll(() =>  LoginPage()); // Ajustez le widget de login
            } catch (e) {
              print('Logout error: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error during logout: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}