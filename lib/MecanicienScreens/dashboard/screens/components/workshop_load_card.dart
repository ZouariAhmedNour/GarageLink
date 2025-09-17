import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/dashboard/constants/constants.dart';
import 'package:garagelink/MecanicienScreens/dashboard/screens/components/radial_painter.dart';


class WorkshopLoadCard extends ConsumerWidget {
  final int mechanics;
  final double hoursPerMechanic;

  const WorkshopLoadCard({
    Key? key,
    this.mechanics = 5,
    this.hoursPerMechanic = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    

    // total heures planifiées pour aujourd'hui
    double plannedMinutes = 0.0;
    final today = DateTime.now();

 

    final plannedHours = plannedMinutes / 60.0;
    final capacity = mechanics * hoursPerMechanic;
    final percent =
        capacity <= 0 ? 0.0 : (plannedHours / capacity).clamp(0.0, 1.0);

    return Container(
      height: 400,
      padding: EdgeInsets.all(appPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Charge d'atelier (aujourd'hui)",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: textColor,
            ),
          ),
          SizedBox(height: appPadding),
          Expanded(
            child: Row(
              children: [
                // Indicateur radial
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: RadialPainter(
                      bgColor: Colors.grey.shade200,
                      lineColor: percent >= 0.85
                          ? red
                          : (percent >= 0.6 ? orange : primaryColor),
                      percent: percent,
                      width: 12,
                    ),
                    child: Center(
                      child: Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: appPadding),
                // détails et explication
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Heures planifiées: ${plannedHours.toStringAsFixed(1)} h',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Capacité: ${capacity.toStringAsFixed(0)} h '
                        '(${mechanics} mécaniciens × ${hoursPerMechanic.toStringAsFixed(0)} h)',
                        style: TextStyle(color: textColor.withOpacity(0.6)),
                      ),
                      SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                      ),
                      SizedBox(height: 12),
                      Text(
                        _suggestion(percent),
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: appPadding / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/reports');
                },
                icon: Icon(Icons.open_in_new, size: 18),
                label: Text("Voir détails"),
              )
            ],
          )
        ],
      ),
    );
  }

  String _suggestion(double percent) {
    if (percent >= 0.9) {
      return "Atelier surchargé — re-planifier ou ajouter ressources.";
    }
    if (percent >= 0.75) {
      return "Charge élevée — surveiller les délais.";
    }
    if (percent >= 0.5) {
      return "Charge modérée — bon niveau d'utilisation.";
    }
    return "Charge faible — capacité disponible.";
  }
}
