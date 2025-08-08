import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Tu peux laisser cette importation si tu comptes réactiver Firestore plus tard
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' as auth;

import 'configurations/app_routes.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  @override
  _CompleteProfilePageState createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  DateTime? birthDate;

  void _submit() async {
    // 🔒 Partie backend désactivée pour l’instant
    /*
    final auth.User? user = auth.FirebaseAuth.instance.currentUser;

    if (user != null) {
      final uid = user.uid;

      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': nameController.text,
          'surname': surnameController.text,
          'email': emailController.text,
          'address': addressController.text,
          'birthDate': birthDate?.toIso8601String(),
          'isProfileComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        Get.offAllNamed(AppRoutes.mecaHome);
      } catch (e) {
        print('Error saving profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete profile')),
        );
      }
    }
    */

    // ✅ Front-end seulement : redirection directe
    Get.offAllNamed(AppRoutes.mecaHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: surnameController, decoration: const InputDecoration(labelText: 'Surname')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (selected != null) {
                  setState(() {
                    birthDate = selected;
                  });
                }
              },
              child: Text(
                birthDate == null
                    ? 'Select Birth Date'
                    : DateFormat('dd-MM-yyyy').format(birthDate!),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text("Submit"),
            )
          ],
        ),
      ),
    );
  }
}
