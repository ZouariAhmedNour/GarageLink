import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/Facture/facture_detail_page.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/num_serie_input.dart';
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
  final _vinCtrl = TextEditingController();
  final _numLocalCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  
  late AnimationController _animationController;
  Animation<double>? _fadeAnimation;            // nullable now
  Animation<Offset>? _slideAnimation;           // nullable now

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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchCtrl.dispose();
    _vinCtrl.dispose();
    _numLocalCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    if (s.trim().isEmpty) return null;
    final cleaned = s.replaceAll(',', '.').replaceAll(' ', '');
    return double.tryParse(cleaned);
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {TextInputType? keyboardType, VoidCallback? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
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
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
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
                      colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt_long, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facture.clientName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.yMd().format(facture.date),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      if (facture.devisId?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.description, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Devis: ${facture.devisId}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (facture.immatriculation?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              facture.immatriculation!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${facture.montant.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: successColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(facturesProvider);
    final notifier = ref.read(facturesProvider.notifier);
    final list = notifier.filtered();

    // fallback animations if not yet initialized (prevents LateInitializationError)
    final fadeAnim = _fadeAnimation ?? AlwaysStoppedAnimation<double>(1.0);
    final slideAnim = _slideAnimation ?? AlwaysStoppedAnimation<Offset>(Offset.zero);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Factures', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          
        ],
      ),
      body: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.filter_list, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text('Filtres', style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Client', Icons.person, state.searchField == SearchField.client, 
                              () => _changeSearchField(SearchField.client, notifier)),
                            const SizedBox(width: 8),
                            _buildFilterChip('Immat.', Icons.directions_car, state.searchField == SearchField.immatriculation, 
                              () => _changeSearchField(SearchField.immatriculation, notifier)),
                            const SizedBox(width: 8),
                            _buildFilterChip('ID Facture', Icons.tag, state.searchField == SearchField.id, 
                              () => _changeSearchField(SearchField.id, notifier)),
                            const SizedBox(width: 8),
                            _buildFilterChip('Montant', Icons.euro, state.searchField == SearchField.montant, 
                              () => _changeSearchField(SearchField.montant, notifier)),
                            const SizedBox(width: 8),
                            _buildFilterChip('Période', Icons.date_range, state.searchField == SearchField.periode, 
                              () => _changeSearchField(SearchField.periode, notifier)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSearchInterface(state.searchField, notifier),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_range != null) 
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Text('${DateFormat.yMd().format(_range!.start)} → ${DateFormat.yMd().format(_range!.end)}',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: primaryColor, size: 18),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => _range = null);
                            notifier.setDateRange(null, null);
                          },
                        ),
                      ],
                    ),
                  ),
                if (_range != null) const SizedBox(height: 16),
                Expanded(
                  child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Aucune facture trouvée', 
                              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _buildFactureCard(list[i], i),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeSearchField(SearchField field, dynamic notifier) {
    _searchCtrl.clear();
    _vinCtrl.clear();
    _numLocalCtrl.clear();
    _minCtrl.clear();
    _maxCtrl.clear();
    notifier.setQuery('');
    notifier.clearMontantRange();
    notifier.setSearchField(field);
    if (field == SearchField.periode) _pickDateRange(context, notifier);
    setState(() {});
  }

  Widget _buildSearchInterface(SearchField field, dynamic notifier) {
    switch (field) {
      case SearchField.immatriculation:
        return NumeroSerieInput(
          vinCtrl: _vinCtrl,
          numLocalCtrl: _numLocalCtrl,
          onChanged: (v) => notifier.setQuery(v),
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
          label: Text(_range == null ? 'Sélectionner période' : 
            '${DateFormat.yMd().format(_range!.start)} → ${DateFormat.yMd().format(_range!.end)}'),
          onPressed: () => _pickDateRange(context, notifier),
        );
      case SearchField.montant:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField(_minCtrl, 'Montant min', Icons.arrow_downward,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: () {
                    final min = _parseDouble(_minCtrl.text);
                    final max = _parseDouble(_maxCtrl.text);
                    notifier.setMontantRange(min, max);
                  })),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_maxCtrl, 'Montant max', Icons.arrow_upward,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: () {
                    final min = _parseDouble(_minCtrl.text);
                    final max = _parseDouble(_maxCtrl.text);
                    notifier.setMontantRange(min, max);
                  })),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Appliquer'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final min = _parseDouble(_minCtrl.text);
                    final max = _parseDouble(_maxCtrl.text);
                    notifier.setMontantRange(min, max);
                  },
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _minCtrl.clear();
                    _maxCtrl.clear();
                    notifier.clearMontantRange();
                  },
                  child: const Text('Effacer', style: TextStyle(color: primaryColor)),
                ),
              ],
            ),
          ],
        );
      default:
        return _buildTextField(_searchCtrl, _getHintText(field), _getIcon(field),
          onChanged: () => notifier.setQuery(_searchCtrl.text));
    }
  }

  String _getHintText(SearchField field) {
    switch (field) {
      case SearchField.client: return 'Rechercher par nom du client';
      case SearchField.id: return 'Rechercher par ID facture';
      default: return 'Rechercher...';
    }
  }

  IconData _getIcon(SearchField field) {
    switch (field) {
      case SearchField.client: return Icons.person_search;
      case SearchField.id: return Icons.tag;
      default: return Icons.search;
    }
  }

  Future<void> _pickDateRange(BuildContext context, dynamic notifier) async {
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
