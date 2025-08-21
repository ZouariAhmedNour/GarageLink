import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/dashboard/screens/components/sales_line_chart.dart';
import 'package:garagelink/providers/factures_provider.dart';
import 'package:garagelink/providers/interventions_provider.dart';
import 'package:garagelink/services/reports_service.dart';
import 'package:garagelink/utils/export_utils.dart';

// Palette de couleurs unifiée pour les rapports
class ReportsColors {
  static const Color primary = Color(0xFF357ABD);
  static const Color primaryLight = Color(0xFF5A9BD8);
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFED8936);
  static const Color info = Color(0xFF3182CE);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color cardBg = Colors.white;
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with TickerProviderStateMixin {
  final GlobalKey chartKey = GlobalKey();
  final ReportsService service = ReportsService();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isExporting = false;
  String? _exportMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _export(String type, List factures, List interventions, double ca, int nbItv) async {
    setState(() {
      _isExporting = true;
      _exportMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final rowsFactures = factures.map((f) => {
        'Date': f.date.toIso8601String(),
        'Client': f.clientName,
        'Montant': f.montant.toString(),
      }).toList();

      final rowsInterventions = interventions.map((i) => {
        'Date': i.date.toIso8601String(),
        'Client': i.clientName,
        'Type': i.type,
        'Durée (min)': i.dureeMinutes.toString(),
      }).toList();

      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');

      switch (type) {
        case "csv":
          await exportCsv(rowsFactures, 'factures_$timestamp');
          _showSuccessMessage('Rapport CSV exporté avec succès');
          break;
        case "excel":
          await exportExcel(rowsFactures, 'factures_$timestamp');
          _showSuccessMessage('Rapport Excel exporté avec succès');
          break;
        case "pdf":
          final chartBytes = await captureWidgetAsPng(chartKey);
          final summary = {
            'ca': ca.toStringAsFixed(0),
            'interventions': nbItv,
            'marge': ((ca * 0.25).toStringAsFixed(0)) // Estimation marge 25%
          };
          await exportPdfWithChart(
            chartBytes,
            summary,
            rowsInterventions,
            'rapport_$timestamp.pdf',
          );
          _showSuccessMessage('Rapport PDF généré avec succès');
          break;
      }
    } catch (e) {
      setState(() => _exportMessage = 'Erreur lors de l\'export: ${e.toString()}');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: ReportsColors.success),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          textColor: ReportsColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final factures = ref.watch(facturesProvider);
    final interventions = ref.watch(interventionsProvider);

    final ca = service.chiffreAffaires(factures);
    final nbItv = service.nombreInterventions(interventions);
    final tempsMoyen = service.tempsMoyenAtelier(interventions);
    final margeEstimee = ca * 0.25; // Estimation marge brute 25%

    return Scaffold(
      backgroundColor: ReportsColors.surface,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: ReportsColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_exportMessage != null) _buildErrorMessage(),
                _buildHeader(),
                const SizedBox(height: 20),
                _buildKpiSection(ca, nbItv, tempsMoyen, margeEstimee),
                const SizedBox(height: 24),
                _buildChartSection(),
                const SizedBox(height: 24),
                _buildInsightsSection(ca, nbItv, tempsMoyen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
  return AppBar(
    elevation: 0,
    backgroundColor: ReportsColors.primary,
    foregroundColor: Colors.white,
    title: SizedBox(
      width: 150, // Adjusted to fit content, can be tuned based on screen size
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6), // Reduced from 8 to 6
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.analytics, size: 18, color: Colors.white,), // Reduced from 20 to 18
          ),
          const SizedBox(width: 8), // Reduced from 12 to 8
          const Text(
            'Rapports', // Shortened from 'Rapports & Analytics'
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
        onPressed: _refreshData,
        tooltip: 'Actualiser',
      ),
      _buildExportMenu(),
    ],
  );
}

  Widget _buildExportMenu() {
    return PopupMenuButton<String>(
      icon: _isExporting 
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : const Icon(Icons.download, color: Colors.white),
      enabled: !_isExporting,
      tooltip: 'Exporter les données',
      onSelected: (val) => _export(val, ref.read(facturesProvider), ref.read(interventionsProvider), 
                                  service.chiffreAffaires(ref.read(facturesProvider)),
                                  service.nombreInterventions(ref.read(interventionsProvider))),
      itemBuilder: (context) => [
        _buildExportMenuItem(Icons.table_chart, "Exporter CSV", "csv"),
        _buildExportMenuItem(Icons.grid_on, "Exporter Excel", "excel"),
        _buildExportMenuItem(Icons.picture_as_pdf, "Générer PDF", "pdf"),
      ],
    );
  }

  PopupMenuItem<String> _buildExportMenuItem(IconData icon, String text, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: ReportsColors.primary),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ReportsColors.primary, ReportsColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ReportsColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tableau de bord analytique',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Période: ${DateTime.now().month}/${DateTime.now().year}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(_exportMessage!, style: const TextStyle(color: Colors.red))),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _exportMessage = null),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(double ca, int nbItv, Duration tempsMoyen, double marge) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
        
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ModernKpiCard(
              title: 'Chiffre d\'affaires',
              value: '${ca.toStringAsFixed(0)} TND',
              icon: Icons.paid,
              color: ReportsColors.success,
              trend: '+12%',
              width: cardWidth,
            ),
            _ModernKpiCard(
              title: 'Interventions',
              value: '$nbItv',
              icon: Icons.build,
              color: ReportsColors.info,
              trend: '+8%',
              width: cardWidth,
            ),
            _ModernKpiCard(
              title: 'Temps moyen',
              value: '${tempsMoyen.inMinutes} min',
              icon: Icons.timer,
              color: ReportsColors.warning,
              width: cardWidth,
            ),
            _ModernKpiCard(
              title: 'Marge estimée',
              value: '${marge.toStringAsFixed(0)} TND',
              icon: Icons.trending_up,
              color: ReportsColors.primary,
              trend: '+5%',
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartSection() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: ReportsColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity, // Constrain to container width
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, color: ReportsColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Évolution du chiffre d\'affaires',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                decoration: BoxDecoration(
                  color: ReportsColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'En croissance',
                  style: TextStyle(
                    color: ReportsColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle overflow
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RepaintBoundary(
          key: chartKey,
          child: SizedBox(
            height: 240,
            child: SalesLineChart(),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildInsightsSection(double ca, int nbItv, Duration tempsMoyen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ReportsColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: ReportsColors.warning, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Insights & Recommandations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            Icons.trending_up,
            'Performance excellente',
            'Votre CA progresse de 12% ce mois',
            ReportsColors.success,
          ),
          _buildInsightItem(
            Icons.speed,
            'Efficacité optimale',
            'Temps moyen d\'intervention: ${tempsMoyen.inMinutes}min',
            ReportsColors.info,
          ),
          _buildInsightItem(
            Icons.adjust,
            'Objectif en vue',
            'Plus que 15% pour atteindre l\'objectif mensuel',
            ReportsColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _showSuccessMessage('Données actualisées');
    }
  }
}

class _ModernKpiCard extends StatelessWidget {
  final String title, value, trend;
  final IconData icon;
  final Color color;
  final double width;

  const _ModernKpiCard({
    required this.title, required this.value, required this.icon,
    required this.color, required this.width, this.trend = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              if (trend.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}