
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:garagelink/mecanicien/dashboard/constants/constants.dart';

class GarageStatsChart extends StatelessWidget {
  const GarageStatsChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                switch (value.toInt()) {
                  case 1: return Text('Lun');
                  case 2: return Text('Mar');
                  case 3: return Text('Mer');
                  case 4: return Text('Jeu');
                  case 5: return Text('Ven');
                  case 6: return Text('Sam');
                  case 7: return Text('Dim');
                  default: return const Text('');
                }
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData( // Chiffre d’affaires
            spots: [
              FlSpot(1, 2000),
              FlSpot(2, 3200),
              FlSpot(3, 2800),
              FlSpot(4, 3500),
              FlSpot(5, 4000),
              FlSpot(6, 3700),
              FlSpot(7, 4200),
            ],
            isCurved: true,
            color: primaryColor,
          ),
          LineChartBarData( // Pièces vendues
            spots: [
              FlSpot(1, 40),
              FlSpot(2, 55),
              FlSpot(3, 48),
              FlSpot(4, 60),
              FlSpot(5, 65),
              FlSpot(6, 70),
              FlSpot(7, 75),
            ],
            isCurved: true,
            color: orange,
          ),
        ],
      ),
    );
  }
}
