import 'package:flutter/material.dart';
import 'package:garagelink/MecanicienScreens/dashboard/constants/constants.dart';
import 'package:garagelink/MecanicienScreens/dashboard/constants/responsive.dart';
import 'package:garagelink/MecanicienScreens/dashboard/screens/components/analytic_cards.dart';
import 'package:garagelink/MecanicienScreens/dashboard/screens/components/frequent_repairs_card.dart';
import 'package:garagelink/MecanicienScreens/dashboard/screens/components/sales_line_chart.dart';
import 'package:garagelink/MecanicienScreens/dashboard/screens/components/vehicles_by_type.dart';
import 'package:garagelink/MecanicienScreens/dashboard/screens/components/workshop_load_card.dart';
import 'package:garagelink/MecanicienScreens/dashboard/screens/report_screen.dart';
import 'package:get/get.dart';
import 'discussions.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(appPadding),
        child: Column(
          children: [
           
            SizedBox(height: appPadding),
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          AnalyticCards(),
                          SizedBox(height: appPadding),
                          WorkshopLoadCard(mechanics: 5, hoursPerMechanic: 8),
                          if (Responsive.isMobile(context))
                            SizedBox(height: appPadding),
                          if (Responsive.isMobile(context)) Discussions(),
                        ],
                      ),
                    ),
                    if (!Responsive.isMobile(context))
                      SizedBox(width: appPadding),
                    if (!Responsive.isMobile(context))
                      Expanded(flex: 2, child: Discussions()),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          SizedBox(height: appPadding),
                          Row(
                            children: [
                              if (!Responsive.isMobile(context))
                                Expanded(child: FrequentRepairsCard(), flex: 2),
                              if (!Responsive.isMobile(context))
                                SizedBox(width: appPadding),
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    Get.to(() => const ReportsScreen());
                                  },
                                  child: Stack(
                                    children: [
                                      SalesLineChart(),
                                      Positioned(
                                        right: 12,
                                        top: 12,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.85,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            crossAxisAlignment: CrossAxisAlignment.start,
                          ),
                          SizedBox(height: appPadding),
                          if (Responsive.isMobile(context))
                            SizedBox(height: appPadding),
                          if (Responsive.isMobile(context))
                            FrequentRepairsCard(),
                          if (Responsive.isMobile(context))
                            SizedBox(height: appPadding),
                          if (Responsive.isMobile(context)) VehiclesByType(),
                        ],
                      ),
                    ),
                    if (!Responsive.isMobile(context))
                      SizedBox(width: appPadding),
                    if (!Responsive.isMobile(context))
                      Expanded(flex: 2, child: VehiclesByType()),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
