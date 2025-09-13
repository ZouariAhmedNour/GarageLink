// lib/screens/stock_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/stock/stock%20widgets/kpi_section.dart';
import 'package:garagelink/MecanicienScreens/stock/stock%20widgets/main_grid.dart';
import 'package:garagelink/MecanicienScreens/stock/stock%20widgets/modern_drawer.dart';
import 'package:garagelink/MecanicienScreens/stock/stock%20widgets/stock_appbar.dart';
import 'package:garagelink/providers/mouvement_provider.dart';
import 'package:garagelink/providers/stockpiece_provider.dart';
import 'package:garagelink/providers/stock_provider.dart';

/// Palette de couleurs unifiée
class StockColors {
  static const Color primary = Color(0xFF357ABD);
  static const Color primaryLight = Color(0xFF5A9BD8);
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFED8936);
  static const Color error = Color(0xFFE53E3E);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color cardBg = Colors.white;
}

/// Provider calculé pour la valeur totale du stock
final totalValeurStockProvider = Provider<double>((ref) {
  final piecesAsync = ref.watch(stockPieceProvider);
  return piecesAsync.when(
    data: (pieces) => pieces.fold<double>(0, (sum, p) => sum + p.valeurStock),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

class StockDashboard extends ConsumerStatefulWidget {
  const StockDashboard({super.key});

  @override
  ConsumerState<StockDashboard> createState() => _StockDashboardState();
}

class _StockDashboardState extends ConsumerState<StockDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final piecesAsync = ref.watch(stockPieceProvider);
    final alertes = ref.watch(stockProvider);
    final mouvements = ref.watch(mouvementProvider);
    final totalValeur = ref.watch(totalValeurStockProvider);

    return Scaffold(
      backgroundColor: StockColors.surface,
      appBar: StockAppBar(onRefresh: _refreshData),
      drawer: const ModernDrawer(),
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _slideAnimation.value)),
            child: Opacity(opacity: _slideAnimation.value, child: child),
          );
        },
        child: piecesAsync.when(
          data: (pieces) {
            final isWide = MediaQuery.of(context).size.width > 900;
            return RefreshIndicator(
              onRefresh: _refreshData,
              color: StockColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KpiSection(
                      piecesCount: pieces.length,
                      alertesCount: alertes.length,
                      mouvements: mouvements,
                      totalValeur: totalValeur,
                    ),
                    const SizedBox(height: 24),
                    MainGrid(
                      isWide: isWide,
                      pieces: pieces,
                      alertes: alertes,
                      mouvements: mouvements,
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erreur: $err')),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: StockColors.success),
              const SizedBox(width: 8),
              const Text('Données actualisées'),
            ],
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
