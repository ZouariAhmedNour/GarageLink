// // lib/screens/client_home_screen.dart
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:garagelink/Clients%20Screens/clientMapScreen.dart';
// import 'package:garagelink/Clients%20Screens/client_vehicles_screen.dart';
// import 'package:get/get.dart';
// import 'package:garagelink/models/client.dart';
// import 'package:garagelink/providers/client_provider.dart';
// import 'package:garagelink/providers/vehicule_provider.dart';
// import 'package:garagelink/configurations/app_routes.dart';

// class ClientHomeScreen extends ConsumerWidget {
//   const ClientHomeScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Auth user (si tu veux rediriger si non connecté)
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       Get.offAllNamed(AppRoutes.login);
//       return const SizedBox();
//     }

//     // Récupération clientId (on accepte Get.arguments ou fallback sur email match)
//     final arg = Get.arguments;
//     String? clientId = arg is String ? arg : null;

//     final clientsState = ref.watch(clientsProvider);
//     Client? client;
//     if (clientId != null) {
//       client = clientsState.clients.firstWhere((c) => c.id == clientId, orElse: () => Client(
//         id: clientId!,
//         nomComplet: 'Client inconnu',
//         mail: '',
//         telephone: '',
//         adresse: '',
//       ));
//     } else {
//       // fallback : chercher par email
//       final email = user.email;
//       if (email != null && email.isNotEmpty) {
//         final idx = clientsState.clients.indexWhere((c) => c.mail.toLowerCase() == email.toLowerCase());
//         if (idx != -1) {
//           client = clientsState.clients[idx];
//           clientId = client.id;
//         }
//       }
//     }

//     // Si toujours null, on crée un placeholder minimal (évite crash UI)
//     client ??= Client(id: clientId ?? 'unknown', nomComplet: user.displayName ?? user.email?.split('@')[0] ?? 'Utilisateur', mail: user.email ?? '', telephone: '', adresse: '');

//     // Vehicules du client
//     final vehiculesState = ref.watch(vehiculesProvider);
//     final clientVehicules = vehiculesState.vehicules.where((v) => v.clientId == client!.id).toList();
//     final vehicleCount = clientVehicules.length;

//     // helper widgets (copié / adapté depuis ton MecaHomePage)
//     Widget buildMenuCard({
//       required IconData icon,
//       required String title,
//       required String description,
//       required Color color,
//       required VoidCallback onTap,
//     }) {
//       return AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         margin: const EdgeInsets.only(bottom: 20),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: onTap,
//             borderRadius: BorderRadius.circular(20),
//             child: Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: color.withOpacity(0.15),
//                     blurRadius: 15,
//                     offset: const Offset(0, 8),
//                   ),
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//                 border: Border.all(color: color.withOpacity(0.1), width: 1),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 60,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       color: color.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: Icon(icon, color: color, size: 30),
//                   ),
//                   const SizedBox(width: 20),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
//                         const SizedBox(height: 4),
//                         Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//                       ],
//                     ),
//                   ),
//                   Icon(Icons.arrow_forward_ios, color: color, size: 20),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     Widget buildQuickStat(String label, String value, IconData icon) {
//       return Expanded(
//         child: Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.12),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             children: [
//               Icon(icon, color: Colors.white, size: 20),
//               const SizedBox(height: 4),
//               Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
//               Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         title: Text('Bienvenue, ${client.nomComplet}'),
//         backgroundColor: const Color(0xFF357ABD),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           const SizedBox(height: 10),

//           // header welcome
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [BoxShadow(color: const Color(0xFF4A90E2).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
//             ),
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Row(children: [
//                 Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.person, color: Colors.white, size: 30)),
//                 const Spacer(),
//                 IconButton(
//                   onPressed: () async {
//                     await FirebaseAuth.instance.signOut();
//                     Get.offAllNamed(AppRoutes.login);
//                   },
//                   icon: const Icon(Icons.logout, color: Colors.white),
//                 )
//               ]),
//               const SizedBox(height: 12),
//               Text('Bonjour, ${client.nomComplet}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 6),
//               Text('Gérez vos véhicules et informations de profil', style: TextStyle(color: Colors.white.withOpacity(0.95))),
//               const SizedBox(height: 14),
//               Row(children: [
//                 buildQuickStat('Véhicules', vehicleCount.toString(), Icons.directions_car),
//                 const SizedBox(width: 12),
//                 buildQuickStat('Contacts', client.telephone.isNotEmpty ? client.telephone : '-', Icons.phone),
//                 const SizedBox(width: 12),
//                 buildQuickStat('Email', client.mail.isNotEmpty ? client.mail : '-', Icons.mail),
//               ])
//             ]),
//           ),

//           const SizedBox(height: 30),
//           const Text('Fonctions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
//           const SizedBox(height: 16),

//           buildMenuCard(
//             icon: Icons.directions_car,
//             title: 'Véhicules',
//             description: 'Voir et gérer vos véhicules',
//             color: const Color(0xFF4A90E2),
//             onTap: () {
//               Get.to(() => const ClientVehiclesScreen(), arguments: client!.id);
//             },
//           ),
//           buildMenuCard(
//             icon: Icons.directions_car,
//             title: 'Map Position',
//             description: 'Potisionnez votre véhicule',
//             color: const Color(0xFF4A90E2),
//             onTap: () {
//               Get.to(() => ClientMapScreen());
//             },
//           ),


//         ]),
//       ),
//     );
//   }
// }
