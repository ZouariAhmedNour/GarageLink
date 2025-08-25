import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/mecanicien.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../add_mec_screen.dart';

class MecListItem extends ConsumerStatefulWidget {
  final Mecanicien mec;
  final Function(String) onDelete;
  final Set<String> expanded;

  const MecListItem({
    super.key,
    required this.mec,
    required this.onDelete,
    required this.expanded,
  });

  @override
  ConsumerState<MecListItem> createState() => _MecListItemState();
}

class _MecListItemState extends ConsumerState<MecListItem> {
  Future<void> _launchTel(String tel) async {
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('Erreur', 'Impossible de lancer l\'appel', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _launchEmail(String email, String subject, String body) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('Erreur', 'Impossible d\'ouvrir le client mail', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer mécanicien'),
        content: Text('Voulez-vous vraiment supprimer ${widget.mec.nom} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.onDelete(widget.mec.id);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.expanded.contains(widget.mec.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() {
          if (isOpen) widget.expanded.remove(widget.mec.id);
          else widget.expanded.add(widget.mec.id);
        }),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('${widget.mec.nom} • ${widget.mec.matricule}', style: const TextStyle(fontWeight: FontWeight.w700))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(widget.mec.poste.toString().split('.').last, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Chip(label: Text(widget.mec.statut.toString().split('.').last)),
                    ],
                  ),
                ],
              ),
              if (isOpen) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Téléphone: ${widget.mec.telephone}')),
                    IconButton(icon: const Icon(Icons.phone), onPressed: () => _launchTel(widget.mec.telephone)),
                    IconButton(icon: const Icon(Icons.email), onPressed: () => _launchEmail(widget.mec.email, 'Message', 'Bonjour ${widget.mec.nom}')),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Services: ${widget.mec.services.join(', ')}'),
                const SizedBox(height: 6),
                Text('Expérience: ${widget.mec.experience}'),
                const SizedBox(height: 6),
                Text('Salaire: ${widget.mec.salaire.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                Text('Ancienneté: ${widget.mec.dateEmbauche != null ? '${DateTime.now().year - widget.mec.dateEmbauche!.year} ans' : 'N/A'}'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => Get.to(() => AddMecScreen(mecanicien: widget.mec)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _confirmDelete,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}