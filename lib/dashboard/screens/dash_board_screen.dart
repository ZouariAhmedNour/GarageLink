
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/dashboard/constants/constants.dart';
import 'package:garagelink/dashboard/constants/responsive.dart';
import 'package:garagelink/dashboard/controllers/controller.dart';
import 'package:garagelink/dashboard/screens/components/dashboard_content.dart';

import 'components/drawer_menu.dart';

class DashBoardScreen extends ConsumerWidget {
  const DashBoardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(controllerProvider);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: const DrawerMenu(),
      key: controller.scaffoldKey,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              const Expanded(child: DrawerMenu()),
            const Expanded(
              flex: 5,
              child: DashboardContent(),
            )
          ],
        ),
      ),
    );
  }
}
