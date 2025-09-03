import 'dart:io';
import 'package:flutter/material.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/vehicules/car%20widgets/full_screen_image_view.dart';
import 'ui_constants.dart';
import 'package:get/get.dart';

class PhotoSection extends StatelessWidget {
  final Vehicule veh;
  const PhotoSection({required this.veh, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.camera_alt, color: primaryBlue, size: 24),
                SizedBox(width: 12),
                Text(
                  'Photo du compteur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkBlue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: veh.picKm != null && veh.picKm!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.to(() => FullScreenImageView(imagePath: veh.picKm!));
                            },
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              child: veh.picKm!.startsWith('http')
                                  ? Image.network(veh.picKm!, fit: BoxFit.cover)
                                  : Image.file(File(veh.picKm!), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Agrandir', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.no_photography, size: 48, color: Colors.grey.shade500),
                          const SizedBox(height: 12),
                          Text('Aucune photo disponible', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
