
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:garagelink/dashboard/constants/constants.dart';

class BarChartRepairs extends StatelessWidget {
  const BarChartRepairs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(border: Border.all(width: 0)),
        groupsSpace: 15,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: appPadding,
              getTitlesWidget: (value, meta) {
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
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()} réparations',
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: primaryColor)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 8, color: primaryColor)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 6, color: primaryColor)]),
          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 10, color: primaryColor)]),
          BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 12, color: primaryColor)]),
          BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 7, color: primaryColor)]),
          BarChartGroupData(x: 7, barRods: [BarChartRodData(toY: 4, color: primaryColor)]),
        ],
      ),
    );
  }
}