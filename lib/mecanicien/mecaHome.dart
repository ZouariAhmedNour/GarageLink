import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:get/get.dart';
import 'package:garagelink/configurations/app_routes.dart';


class MecaHomePage extends ConsumerWidget {
  const MecaHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return const SizedBox();
    }
    return Scaffold(
            appBar: DefaultAppBar(
             title: 'Welcome, ${user.displayName ?? user.email?.split('@')[0] ?? 'User'}',
            ),
      body: Center(
        child: Text('Welcome, ${user.email}!'),
      ),
    );
  }
}