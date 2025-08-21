import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesLineChart extends StatelessWidget {
  final List<FlSpot> revenue = [
    FlSpot(0, 1000),
    FlSpot(1, 1500),
    FlSpot(2, 1200),
    FlSpot(3, 1800),
    FlSpot(4, 1600),
  ];

  final List<FlSpot> partsSold = [
    FlSpot(0, 50),
    FlSpot(1, 70),
    FlSpot(2, 65),
    FlSpot(3, 80),
    FlSpot(4, 75),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6), // Limit to 60% of screen height
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Chiffre d’affaires & Pièces vendues",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenue,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                        LineChartBarData(
                          spots: partsSold,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      titlesData: FlTitlesData(show: true),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              return LineTooltipItem(
                                "${spot.y}",
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}