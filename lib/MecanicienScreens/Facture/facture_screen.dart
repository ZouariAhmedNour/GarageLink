// screens/facture_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/Facture/facture_detail_page.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/providers/factures_provider.dart';
import 'package:intl/intl.dart';

class FactureScreen extends ConsumerStatefulWidget {
  const FactureScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FactureScreen> createState() => _FacturesScreenState();
}

class _FacturesScreenState extends ConsumerState<FactureScreen>
    with SingleTickerProviderStateMixin {
  DateTimeRange? _range;
  final _searchCtrl = TextEditingController();

  late AnimationController _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  static const primaryColor = Color(0xFF357ABD);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const cardColor = Colors.white;
  static const successColor = Color(0xFF38A169);
  static const warningColor = Color(0xFFF56500);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();

    // charge initial des factures
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(facturesProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : primaryColor),
        label: Text(label, style: TextStyle(
          color: selected ? Colors.white : primaryColor,
          fontWeight: FontWeight.w600,
        )),
        selected: selected,
        selectedColor: primaryColor,
        backgroundColor: cardColor,
        side: BorderSide(color: selected ? primaryColor : Colors.grey[300]!),
        onSelected: (_) {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }

  Widget _buildSearchCard(Widget child) {
    return Card(
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {
    TextInputType? keyboardType,
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor, width: 2)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (_) {
        HapticFeedback.selectionClick();
        onChanged?.call();
      },
    );
  }

  Widget _buildFactureCard(dynamic facture, int index) {
    final clientName = (facture.clientInfo?.nom ?? 'Client').toString();
    final invoiceDate = facture.invoiceDate ?? facture.createdAt ?? DateTime.now();
    final montant = (facture.totalTTC as double?) ?? (facture.totalTTC ?? 0.0);
    final displayId = (facture.numeroFacture?.isNotEmpty ?? false) ? facture.numeroFacture : (facture.id ?? '');

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 30)),
      child: Card(
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => FactureDetailPage(facture: facture),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.12), primaryColor.withOpacity(0.18)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt_long, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(DateFormat.yMd().format(invoiceDate), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 12),
                      if ((facture.devisId?.toString().isNotEmpty ?? false)) ...[
                        Icon(Icons.description, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('Devis: ${facture.devisId}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                      const SizedBox(width: 8),
                      if ((facture.vehicleInfo?.toString().isNotEmpty ?? false)) ...[
                        Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(child: Text(facture.vehicleInfo.toString(), style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ]),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('${(montant).toStringAsFixed(2)} DT', style: const TextStyle(fontWeight: FontWeight.w700, color: successColor, fontSize: 14)),
                  ),
                  const SizedBox(height: 8),
                  Text(displayId, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 6),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(facturesProvider); // FactureFilterState
    final notifier = ref.read(facturesProvider.notifier);
    final list = state.factures;

    final fadeAnim = _fadeAnimation ?? AlwaysStoppedAnimation<double>(1.0);
    final slideAnim = _slideAnimation ?? AlwaysStoppedAnimation<Offset>(Offset.zero);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: 'Factures',
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSearchCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.filter_list, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Filtres', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                ]),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _buildFilterChip('Client', Icons.person, state.searchField == SearchField.client, () => _changeSearchField(SearchField.client, notifier)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Statut paiement', Icons.payment, state.searchField == SearchField.paymentStatus, () => _changeSearchField(SearchField.paymentStatus, notifier)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Période', Icons.date_range, state.searchField == SearchField.periode, () => _changeSearchField(SearchField.periode, notifier)),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSearchInterface(state.searchField, notifier),
              ])),
              const SizedBox(height: 16),
              if (state.loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator()))
              else if (state.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text(state.error!, style: const TextStyle(color: Colors.red))),
                )
              else
                Expanded(
                  child: list.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Aucune facture trouvée', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        ]))
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) => _buildFactureCard(list[i], i),
                        ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  void _changeSearchField(SearchField field, FactureNotifier notifier) {
    _searchCtrl.clear();
    notifier.setQuery('');
    notifier.setPaymentStatusFilter('');
    notifier.setSearchField(field);
    if (field == SearchField.periode) _pickDateRange(context, notifier);
    setState(() {});
  }

  Widget _buildSearchInterface(SearchField field, FactureNotifier notifier) {
    switch (field) {
      case SearchField.paymentStatus:
        return DropdownButtonFormField<String>(
          value: notifier.state.paymentStatus.isEmpty ? 'Tous' : notifier.state.paymentStatus,
          items: <String>['Tous', 'en_attente', 'partiellement_paye', 'paye', 'en_retard', 'annule']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            notifier.setPaymentStatusFilter((v == null || v == 'Tous') ? '' : v);
          },
          decoration: const InputDecoration(labelText: 'Filtrer par statut paiement'),
        );
      case SearchField.periode:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          icon: const Icon(Icons.date_range),
          label: Text(_range == null ? 'Sélectionner période' : '${DateFormat.yMd().format(_range!.start)} → ${DateFormat.yMd().format(_range!.end)}'),
          onPressed: () => _pickDateRange(context, notifier),
        );
      case SearchField.client:
      default:
        return _buildTextField(_searchCtrl, 'Rechercher par client (nom ou id)', Icons.search, onChanged: () {
          notifier.setQuery(_searchCtrl.text.trim());
        });
    }
  }

  Future<void> _pickDateRange(BuildContext context, FactureNotifier notifier) async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _range = picked);
      notifier.setDateRange(picked.start, picked.end);
      notifier.setQuery('');
    }
  }
}
