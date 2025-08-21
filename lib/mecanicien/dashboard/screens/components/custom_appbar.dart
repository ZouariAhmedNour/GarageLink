
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/dashboard/constants/constants.dart';
import 'package:garagelink/mecanicien/dashboard/constants/responsive.dart';
import 'package:garagelink/mecanicien/dashboard/controllers/controller.dart';
import 'package:garagelink/mecanicien/dashboard/screens/components/profile_info.dart';
import 'package:garagelink/mecanicien/dashboard/screens/components/search_field.dart';


class CustomAppbar extends ConsumerWidget {
  const CustomAppbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        if (!Responsive.isDesktop(context))
          IconButton(
            onPressed: () => ref.read(controllerProvider).controlMenu(),
            icon: Icon(Icons.menu, color: textColor.withOpacity(0.5)),
          ),
        const Expanded(child: SearchField()),
        const ProfileInfo(),
      ],
    );
  }
}
