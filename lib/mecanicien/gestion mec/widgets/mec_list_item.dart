import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/mecanicien.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../add_mec_screen.dart';

// Couleurs cohérentes avec MecListScreen
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

  // ✅ Synchroniser immédiatement avec l'état courant
  if (widget.expanded.contains(widget.mec.id)) {
    _expandController.value = 1.0; // déjà ouvert
  } else {
    _expandController.value = 0.0; // fermé
  }
}

  @override
  void didUpdateWidget(MecListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isExpanded = widget.expanded.contains(widget.mec.id);
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
            Text(message),
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
            const Text('Supprimer mécanicien'),
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
              widget.onDelete(widget.mec.id);
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
    if (widget.mec.dateEmbauche == null) return 0;
    final now = DateTime.now();
    int years = now.year - widget.mec.dateEmbauche!.year;
    if (now.month < widget.mec.dateEmbauche!.month ||
        (now.month == widget.mec.dateEmbauche!.month && now.day < widget.mec.dateEmbauche!.day)) {
      years--;
    }
    return years;
  }

  Color _getStatutColor(String statut) {
    return switch (statut.toLowerCase()) {
      'actif' => MecItemColors.success,
      'inactif' => MecItemColors.danger,
      'conge' => MecItemColors.warning,
      _ => MecItemColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = widget.expanded.contains(widget.mec.id);
    final statutStr = widget.mec.statut.toString().split('.').last;
    final posteStr = widget.mec.poste.toString().split('.').last;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            widget.onToggle(widget.mec.id);
            HapticFeedback.selectionClick();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(posteStr, statutStr),
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildExpandedContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String poste, String statut) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [MecItemColors.primary, MecItemColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              widget.mec.nom.isNotEmpty ? widget.mec.nom[0].toUpperCase() : 'M',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mec.nom,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: MecItemColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.badge_outlined, size: 14, color: MecItemColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    widget.mec.matricule,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MecItemColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.work_outline, size: 14, color: MecItemColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    poste,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MecItemColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatutColor(statut).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _getStatutColor(statut).withOpacity(0.3)),
              ),
              child: Text(
                statut,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getStatutColor(statut),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              widget.expanded.contains(widget.mec.id) 
                ? Icons.keyboard_arrow_up 
                : Icons.keyboard_arrow_down,
              color: MecItemColors.textSecondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MecItemColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactSection(),
          const SizedBox(height: 12),
          _buildInfoSection(),
          const SizedBox(height: 12),
          _buildServicesSection(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.contact_phone, size: 16, color: MecItemColors.primary),
            const SizedBox(width: 8),
            const Text('Contact', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.phone, size: 14, color: MecItemColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(widget.mec.telephone, style: const TextStyle(fontSize: 13)),
                ],
              ),
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
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final anciennete = _computeAnciennete();
    return Column(
      children: [
        _buildInfoRow(Icons.work_history, 'Expérience', '${widget.mec.experience} ans'),
        const SizedBox(height: 6),
        _buildInfoRow(Icons.payments, 'Salaire', '${widget.mec.salaire.toStringAsFixed(2)} DT'),
        const SizedBox(height: 6),
        _buildInfoRow(Icons.schedule, 'Ancienneté', anciennete > 0 ? '$anciennete ans' : 'Nouveau'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
  children: [
    Icon(icon, size: 14, color: MecItemColors.textSecondary),
    const SizedBox(width: 6),
    Text(
      '$label: ',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    Expanded( // ⬅️ empêche l’overflow
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          color: MecItemColors.textSecondary,
        ),
        overflow: TextOverflow.ellipsis, // coupe proprement si trop long
        maxLines: 1, // reste sur une ligne
      ),
    ),
  ],
);
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.build, size: 16, color: MecItemColors.primary),
            const SizedBox(width: 8),
            const Text('Compétences', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: widget.mec.services.map((service) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: MecItemColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MecItemColors.primary.withOpacity(0.2)),
            ),
            child: Text(
              service,
              style: const TextStyle(
                fontSize: 11,
                color: MecItemColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionButton(
          icon: Icons.edit,
          color: MecItemColors.primary,
          onPressed: () {
            HapticFeedback.mediumImpact();
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
      ],
    );
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
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}