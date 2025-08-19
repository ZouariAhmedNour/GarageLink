import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:garagelink/auth/login.dart';
import 'package:garagelink/mecanicien/work%20order/notif_screen.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final double? fontSize;
  final Color? backgroundColor;
  final Widget? leading;
  final bool showLogout;
  final VoidCallback? onLogout;

  const DefaultAppBar({
    Key? key,
    this.title,
    this.fontSize,
    this.backgroundColor,
    this.leading,
    this.showLogout = true,
    this.onLogout,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading ?? (Navigator.canPop(context) ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ) : null),
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                fontSize: fontSize ?? 20.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            )
          : null,
      backgroundColor: backgroundColor ?? AppColors.primary,
      elevation: 0,
      actions: [
        if (showLogout)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Déconnexion',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                );

                final GoogleSignIn googleSignIn = GoogleSignIn();
                await googleSignIn.signOut();
                await FirebaseAuth.instance.signOut();

                // Navigate to login page
                Get.offAll(() => LoginPage());

                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur de déconnexion : ${e.toString().split(':').first}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              }
            },
          ),
      ],
      iconTheme: const IconThemeData(color: Colors.white), // Ensure all icons are white
    );
  }
}