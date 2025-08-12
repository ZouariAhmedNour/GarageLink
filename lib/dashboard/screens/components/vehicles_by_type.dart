
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:garagelink/dashboard/constants/constants.dart';


class VehiclesByType extends StatelessWidget {
  const VehiclesByType({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(appPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition des véhicules',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 60,
                    color: primaryColor,
                    title: 'Voitures (60%)',
                  ),
                  PieChartSectionData(
                    value: 25,
                    color: orange,
                    title: 'Utilitaires (25%)',
                  ),
                  PieChartSectionData(
                    value: 15,
                    color: green,
                    title: 'Motos (15%)',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
