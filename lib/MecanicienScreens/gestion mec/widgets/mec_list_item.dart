// mec_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/mecanicien.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../add_mec_screen.dart';

class MecItemColors {
  static const primary = Color(0xFF357ABD);
  static const primaryLight = Color(0xFF5A9BD8);
  static const success = Color(0xFF38A169);
  static const warning = Color(0xFFED8936);
  static const danger = Color(0xFFE53E3E);
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const surface = Color(0xFFF7FAFC);
}

class MecListItem extends ConsumerStatefulWidget {
  final Mecanicien mec;
  final Function(String) onDelete;
  final Set<String> expanded;
  final void Function(String id) onToggle;

  const MecListItem({
    super.key,
    required this.mec,
    required this.onDelete,
    required this.expanded,
    required this.onToggle,
  });

  @override
  ConsumerState<MecListItem> createState() => _MecListItemState();
}

class _MecListItemState extends ConsumerState<MecListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  String get _id => widget.mec.id ?? '';

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeIn),
    );

    // Synchroniser l'animation avec l'état initial
    if (widget.expanded.contains(_id) && _id.isNotEmpty) {
      _expandController.value = 1.0;
    } else {
      _expandController.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(MecListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isExpanded = widget.expanded.contains(_id);
    if (isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url, String errorMessage) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        HapticFeedback.lightImpact();
      } else {
        _showError(errorMessage);
      }
    } catch (e) {
      _showError(errorMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MecItemColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _confirmDelete() {
    HapticFeedback.mediumImpact();

    if (_id.isEmpty) {
      _showError('Impossible de supprimer : identifiant invalide.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
  children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: MecItemColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.warning_amber, color: MecItemColors.danger, size: 24),
    ),
    const SizedBox(width: 12),
    // Expanded / Flexible évite l'overflow dans les petits écrans/dialogs
    Flexible(
  child: Text(
    'Supprimer le mécanicien',
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    maxLines: 2, // autorise 2 lignes si nécessaire (évite l'overflow)
    overflow: TextOverflow.ellipsis,
    softWrap: true,
  ),
),
  ],
),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${widget.mec.nom} ?\nCette action est irréversible.',
          style: const TextStyle(color: MecItemColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MecItemColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              widget.onDelete(_id);
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  int _computeAnciennete() {
    final embauche = widget.mec.dateEmbauche;
    final now = DateTime.now();
    int years = now.year - embauche.year;
    if (now.month < embauche.month ||
        (now.month == embauche.month && now.day < embauche.day)) {
      years--;
    }
    return years;
  }

  Color _getStatutColor(String statutKey) {
    switch (statutKey) {
      case 'actif':
        return MecItemColors.success;
      case 'conge':
      case 'arretMaladie':
        return MecItemColors.warning;
      case 'suspendu':
      case 'demissionne':
        return MecItemColors.danger;
      default:
        return MecItemColors.textSecondary;
    }
  }

  String _formatPoste(String raw) {
    switch (raw) {
      case 'electricienAuto':
        return 'Électricien Auto';
      case 'carrossier':
        return 'Carrossier';
      case 'chefDEquipe':
        return 'Chef d\'équipe';
      case 'apprenti':
        return 'Apprenti';
      case 'mecanicien':
      default:
        return 'Mécanicien';
    }
  }

  String _formatStatut(String raw) {
    switch (raw) {
      case 'conge':
        return 'Congé';
      case 'arretMaladie':
        return 'Arrêt maladie';
      case 'suspendu':
        return 'Suspendu';
      case 'demissionne':
        return 'Démissionné';
      case 'actif':
      default:
        return 'Actif';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = widget.expanded.contains(_id);
    final statutRaw = widget.mec.statut.toString().split('.').last;
    final posteRaw = widget.mec.poste.toString().split('.').last;
    final statutStr = _formatStatut(statutRaw);
    final posteStr = _formatPoste(posteRaw);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            if (_id.isNotEmpty) {
              widget.onToggle(_id);
              HapticFeedback.selectionClick();
            } else {
              _showError('Identifiant du mécanicien manquant.');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(posteStr, statutStr, statutRaw),
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: FadeTransition(opacity: _fadeAnimation, child: _buildExpandedContent()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String poste, String statut, String statutRaw) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [MecItemColors.primary, MecItemColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              widget.mec.nom.isNotEmpty ? widget.mec.nom[0].toUpperCase() : 'M',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.mec.nom, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: MecItemColors.textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.badge_outlined, size: 14, color: MecItemColors.textSecondary),
              const SizedBox(width: 4),
              Text(widget.mec.matricule, style: const TextStyle(fontSize: 12, color: MecItemColors.textSecondary)),
              const SizedBox(width: 12),
              Icon(Icons.work_outline, size: 14, color: MecItemColors.textSecondary),
              const SizedBox(width: 4),
              Text(poste, style: const TextStyle(fontSize: 12, color: MecItemColors.textSecondary)),
            ]),
          ]),
        ),
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatutColor(statutRaw).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _getStatutColor(statutRaw).withOpacity(0.3)),
            ),
            child: Text(statut, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getStatutColor(statutRaw))),
          ),
          const SizedBox(height: 4),
          Icon(
            widget.expanded.contains(_id) ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: MecItemColors.textSecondary,
          ),
        ]),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: MecItemColors.surface, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildContactSection(),
        const SizedBox(height: 12),
        _buildInfoSection(),
        const SizedBox(height: 12),
        _buildServicesSection(),
        const SizedBox(height: 16),
        _buildActionButtons(),
      ]),
    );
  }

  Widget _buildContactSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.contact_phone, size: 16, color: MecItemColors.primary),
        const SizedBox(width: 8),
        const Text('Contact', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Row(children: [
            Icon(Icons.phone, size: 14, color: MecItemColors.textSecondary),
            const SizedBox(width: 6),
            Text(widget.mec.telephone, style: const TextStyle(fontSize: 13)),
          ]),
        ),
        _buildActionButton(
          icon: Icons.phone,
          color: MecItemColors.success,
          onPressed: () => _launchUrl('tel:${widget.mec.telephone}', 'Impossible de lancer l\'appel'),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.email,
          color: MecItemColors.primary,
          onPressed: () => _launchUrl(
            'mailto:${widget.mec.email}?subject=Message&body=Bonjour ${widget.mec.nom}',
            'Impossible d\'ouvrir le client mail',
          ),
        ),
      ]),
    ]);
  }

  Widget _buildInfoSection() {
    final anciennete = _computeAnciennete();
    return Column(children: [
      _buildInfoRow(Icons.work_history, 'Expérience', '${widget.mec.experience} ans'),
      const SizedBox(height: 6),
      _buildInfoRow(Icons.payments, 'Salaire', '${widget.mec.salaire.toStringAsFixed(2)} DT'),
      const SizedBox(height: 6),
      _buildInfoRow(Icons.schedule, 'Ancienneté', anciennete > 0 ? '$anciennete ans' : 'Nouveau'),
    ]);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: MecItemColors.textSecondary),
      const SizedBox(width: 6),
      Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      Expanded(
        child: Text(value, style: const TextStyle(fontSize: 13, color: MecItemColors.textSecondary), overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    ]);
  }

  Widget _buildServicesSection() {
    final services = widget.mec.services;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.build, size: 16, color: MecItemColors.primary),
        const SizedBox(width: 8),
        const Text('Services', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
      const SizedBox(height: 8),
      if (services.isEmpty)
        const Text('Aucun service', style: TextStyle(color: MecItemColors.textSecondary))
      else
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: services.map((service) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: MecItemColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MecItemColors.primary.withOpacity(0.2)),
              ),
              child: Text(
                service.name, // <-- corrige : name (model) au lieu de label
                style: const TextStyle(fontSize: 11, color: MecItemColors.primary, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
    ]);
  }

  Widget _buildActionButtons() {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      _buildActionButton(
        icon: Icons.edit,
        color: MecItemColors.primary,
        onPressed: () {
          HapticFeedback.mediumImpact();
          // navigation vers l'écran d'édition — on passe l'objet complet
          Get.to(() => AddMecScreen(mecanicien: widget.mec));
        },
        label: 'Modifier',
      ),
      const SizedBox(width: 12),
      _buildActionButton(
        icon: Icons.delete_outline,
        color: MecItemColors.danger,
        onPressed: _confirmDelete,
        label: 'Supprimer',
      ),
    ]);
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? label,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: label != null ? 12 : 8, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ],
        ]),
      ),
    );
  }
}
