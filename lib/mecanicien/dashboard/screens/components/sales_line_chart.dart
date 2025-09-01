// lib/mecanicien/dashboard/screens/components/sales_line_chart.dart
import 'dart:math';
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxAvailable = constraints.maxHeight.isFinite ? constraints.maxHeight : double.infinity;
            final defaultChartHeight = 200.0;
            double chartHeight;

            if (maxAvailable.isFinite) {
              chartHeight = max(100.0, min(defaultChartHeight, maxAvailable - 80.0));
            } else {
              chartHeight = defaultChartHeight;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Chiffre d’affaires & Pièces vendues",
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Chart : hauteur adaptative (évite overflow)
                SizedBox(
                  height: chartHeight,
                  width: double.infinity,
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
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
