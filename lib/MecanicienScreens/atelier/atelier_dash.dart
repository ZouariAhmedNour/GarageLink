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
  }

  Future<void> _refresh() async {
    await ref.read(ateliersProvider.notifier).loadAll();
  }

  Future<void> _onDeleteTap(BuildContext context, Atelier atelier) async {
    // Confirmation dialog with explicit white background
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Voulez-vous vraiment supprimer "${atelier.name}" ?', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: primaryBlue.withOpacity(0.12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Annuler', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(ateliersProvider.notifier);

      // afficher un indicateur modal avec fond blanc pendant la suppression
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 16),
                Text('Suppression en cours...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
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

  Widget _statsHeader(AteliersState state) {
    final total = state.ateliers.length;
    final lastAddedName = state.ateliers.isNotEmpty ? state.ateliers.last.name : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statistiques', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('$total atelier(s)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF102035))),
                const SizedBox(height: 4),
                Text('Dernier : $lastAddedName', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Icon(Icons.insights, color: primaryBlue, size: 34),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ref.listen ici est OK (dans build)
    ref.listen<AteliersState>(ateliersProvider, (previous, next) {
      final prevErr = previous?.error;
      final nextErr = next.error;
      if (nextErr != null && nextErr != prevErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(nextErr), backgroundColor: Colors.red),
          );
        }
      }
    });

    final state = ref.watch(ateliersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FB),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        backgroundColor: primaryBlue,
        title: const Text(
          'Mes Ateliers',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: primaryBlue,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: state.loading
              ? ListView(
                  // allow pull-to-refresh
                  children: [
                    _statsHeader(state),
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                )
              : state.ateliers.isEmpty
                  ? ListView(
                      // ListView to enable pull-to-refresh even when empty
                      children: [
                        _statsHeader(state),
                        const SizedBox(height: 20),
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
                      itemCount: state.ateliers.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) return _statsHeader(state);
                        final atelier = state.ateliers[index - 1];
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
}
