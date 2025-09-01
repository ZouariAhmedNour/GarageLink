import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/dashboard/constants/constants.dart';
import 'package:garagelink/mecanicien/dashboard/constants/responsive.dart';
import 'package:garagelink/mecanicien/dashboard/controllers/controller.dart';
import 'package:garagelink/mecanicien/dashboard/screens/components/dashboard_content.dart';
import 'package:garagelink/mecanicien/mecaHome.dart';

class DashBoardScreen extends ConsumerWidget {
  const DashBoardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(controllerProvider);

    return Scaffold(
      backgroundColor: bgColor,

      key: controller.scaffoldKey,
     appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MecaHomePage()),
      );
    },
    tooltip: 'Retour à MecaHome',
  ),
  title: const Text(
    'Tableau de bord',
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
  ),
  backgroundColor: const Color(0xFF357ABD),
  elevation: 0,
  iconTheme: const IconThemeData(color: Colors.white), // Ensures all icons are white
  titleTextStyle: const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
  ), // Ensures title text is white
),
     body: SafeArea(
  child: Responsive.isDesktop(context)
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              flex: 5,
              child: DashboardContent(),
            ),
          ],
        )
      : const DashboardContent(), 
),
    );
  }
}