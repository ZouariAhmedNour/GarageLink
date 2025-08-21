
import 'package:flutter/material.dart';
import 'package:garagelink/mecanicien/dashboard/constants/constants.dart';
import 'package:garagelink/mecanicien/dashboard/screens/components/drawer_list_tile.dart';
import 'package:garagelink/mecanicien/dashboard/screens/report_screen.dart';
import 'package:get/get.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(appPadding),
            child: Image.asset("assets/images/garageLink.jpeg"),
          ),
         DrawerListTile(
  title: 'Tableau de bord',
  svgSrc: 'assets/icons/Dashboard.svg',
  tap: () {},
),
DrawerListTile(
  title: 'Clients',
  svgSrc: 'assets/icons/client.svg',
  tap: () {},
),
DrawerListTile(
  title: 'Véhicules',
  svgSrc: 'assets/icons/car.svg',
  tap: () {},
),
DrawerListTile(
  title: 'Réparations',
  svgSrc: 'assets/icons/repair.svg',
  tap: () {},
),
DrawerListTile(
  title: 'Stock pièces',
  svgSrc: 'assets/icons/parts.svg',
  tap: () {},
),
DrawerListTile(
  title: 'Factures',
  svgSrc: 'assets/icons/invoice.svg',
  tap: () {},
),
DrawerListTile(
  title: 'Rapports',
  svgSrc: 'assets/icons/report.svg', // mets une icône svg que tu as, sinon change
  tap: () {
    Get.to(() => const ReportsScreen());
  },
),
        ],
      ),
    );
  }
}
