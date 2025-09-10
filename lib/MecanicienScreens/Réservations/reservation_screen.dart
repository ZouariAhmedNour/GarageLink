// lib/screens/reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:get/get.dart';
import 'package:garagelink/models/reservation.dart';

class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Exemples statiques
    final upcomingReservations = [
      Reservation(
        id: "1",
        clientId: "Client A",
        vehiculeId: "Peugeot 208",
        dateResa: DateTime.now().add(const Duration(days: 1)),
        heureResa: "09:30",
        descriptionPanne: "Problème de démarrage",
        status: ReservationStatus.enAttente,
        mecanicienId: '',
      ),
      Reservation(
        id: "2",
        clientId: "Client B",
        vehiculeId: "Renault Clio",
        dateResa: DateTime.now().add(const Duration(days: 2)),
        heureResa: "14:00",
        descriptionPanne: "Changement plaquettes de frein",
        status: ReservationStatus.accepte,
        mecanicienId: '',
      ),
      Reservation(
        id: "3",
        clientId: "Client C",
        vehiculeId: "Ford Focus",
        dateResa: DateTime.now().add(const Duration(days: 3)),
        heureResa: "11:00",
        descriptionPanne: "Vidange + contrôle général",
        status: ReservationStatus.clientConfirmed,
        mecanicienId: '',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Réservations"),
        backgroundColor: const Color(0xFF357ABD),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: upcomingReservations.isEmpty
            ? const Center(
                child: Text(
                  "Aucune réservation à venir",
                  style: TextStyle(fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: upcomingReservations.length,
                itemBuilder: (context, index) {
                  final reservation = upcomingReservations[index];
                  return GestureDetector(
                    onTap: () {
                      Get.defaultDialog(
                        title: "Passer un Devis",
                        middleText:
                            "Voulez-vous transformer cette réservation en un devis ?",
                        textCancel: "Annuler",
                        textConfirm: "Oui",
                        confirmTextColor: Colors.white,
                        buttonColor: const Color(0xFF357ABD),
                        onConfirm: () {
                          Get.back();
                          Get.toNamed(
                            AppRoutes.creationDevis,
                            arguments: reservation,
                          );
                        },
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF357ABD), Color(0xFF4A90E2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icône stylisée
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Color(0xFF357ABD),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Infos réservation
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Véhicule : ${reservation.vehiculeId}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Date : ${reservation.dateResa.toLocal().toString().split(' ')[0]}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "Heure : ${reservation.heureResa}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "Client : ${reservation.clientId}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Panne : ${reservation.descriptionPanne}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Statut : ${reservation.status.name}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
