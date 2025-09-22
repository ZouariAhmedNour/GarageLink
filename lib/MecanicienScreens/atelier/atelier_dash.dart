// lib/MecanicienScreens/ateliers/atelier_dash.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/atelier/ajouterAtelier.dart';
import 'package:garagelink/MecanicienScreens/atelier/modifierAtelier.dart';
import 'package:get/get.dart';
import 'package:garagelink/models/atelier.dart';
import 'package:garagelink/providers/atelier_provider.dart';

class AtelierDashScreen extends ConsumerStatefulWidget {
  const AtelierDashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AtelierDashScreen> createState() => _AtelierDashScreenState();
}

class _AtelierDashScreenState extends ConsumerState<AtelierDashScreen>
    with TickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF357ABD);

  @override
  void initState() {
    super.initState();

    // Charger la liste au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ateliersProvider.notifier).loadAll();
    });

    // Écoute des erreurs pour afficher un snackbar automatiquement
    ref.listen<AteliersState>(ateliersProvider, (previous, next) {
      final prevErr = previous?.error;
      final nextErr = next.error;
      if (nextErr != null && nextErr != prevErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(nextErr),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _refresh() async {
    await ref.read(ateliersProvider.notifier).loadAll();
  }

  Future<void> _onDeleteTap(BuildContext context, Atelier atelier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${atelier.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(ateliersProvider.notifier);
      // afficher un petit indicateur modal pendant la suppression
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final success = await notifier.delete(atelier.id ?? '');
      if (mounted) Navigator.pop(context); // fermer l'indicateur
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Atelier "${atelier.name}" supprimé'), backgroundColor: Colors.green),
          );
        }
      } else {
        final state = ref.read(ateliersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur suppression : ${state.error ?? 'inconnu'}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _onEditTap(Atelier atelier) {
    // Attendre le résultat du screen d'édition ; si true => reload
    Get.to(() => ModifierAtelierScreen(atelier: atelier))?.then((result) {
      if (result == true) {
        ref.read(ateliersProvider.notifier).loadAll();
      }
    });
  }

  void _onAddTap() {
    Get.to(() => const AjouterAtelierScreen())?.then((result) {
      if (result == true) {
        ref.read(ateliersProvider.notifier).loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ateliersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        title: const Text('Mes Ateliers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: primaryBlue,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : state.ateliers.isEmpty
                  ? ListView(
                      // ListView to enable pull-to-refresh even when empty
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFEAF4FF), Color(0xFFDFF6FF)]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.storefront_outlined, size: 54, color: primaryBlue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Center(child: Text('Aucun atelier trouvé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                        if (state.error != null) ...[
                          const SizedBox(height: 8),
                          Center(child: Text(state.error!, style: const TextStyle(color: Colors.red))),
                        ],
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.ateliers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final atelier = state.ateliers[index];
                        return _atelierCard(context, atelier);
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.loading ? null : _onAddTap,
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _atelierCard(BuildContext context, Atelier atelier) {
    // si ton modèle Atelier contient d'autres champs, remplace les placeholders
    final servicesText = '—';
    final prixText = '—';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFFFF), Color(0xFFF7FBFF)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
        border: Border.all(color: const Color(0xFFE6EEF8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [primaryBlue, primaryBlue]),
                boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: const Center(child: Icon(Icons.work, color: Colors.white, size: 28)),
            ),
            const SizedBox(width: 12),
            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    atelier.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF102035)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          atelier.localisation,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // badges row
                  Row(
                    children: [
                      _badge(label: 'Services', value: servicesText),
                      const SizedBox(width: 8),
                      _badge(label: 'Prix moyen', value: prixText),
                    ],
                  ),
                ],
              ),
            ),
            // actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black54),
                  onPressed: () => _onEditTap(atelier),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _onDeleteTap(context, atelier),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCEFFA)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4B6D8A), fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
