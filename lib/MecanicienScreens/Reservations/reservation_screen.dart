// lib/MecanicienScreens/Reservations/reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/reservation_provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:garagelink/models/reservation.dart';

// NOTIF: import du provider global de notifications
import 'package:garagelink/providers/notification_provider.dart';

class ReservationScreen extends ConsumerStatefulWidget {
  const ReservationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> with TickerProviderStateMixin {
  // Affichage agréable : dd/MM/yyyy et HH:mm
  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFmt = DateFormat.Hm();

  // NOTIF: dernier nombre connu de réservations (pour détecter nouvelles résas)
  int _lastReservationsCount = 0;

  // UI state
  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // charge la liste et initialise le compteur/notifications
      await ref.read(reservationsProvider.notifier).loadAll();

      // initialise et reset notifications globales car l'utilisateur a ouvert la page
      final currentCount = ref.read(reservationsProvider).reservations.length;
      _lastReservationsCount = currentCount;

      // reset global notification counter
      ref.read(newNotificationProvider.notifier).state = 0;

      if (mounted) setState(() {}); // force rebuild si nécessaire
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _statusLabel(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.enAttente:
        return 'En attente';
      case ReservationStatus.accepte:
        return 'Acceptée';
      case ReservationStatus.refuse:
        return 'Refusée';
      case ReservationStatus.contrePropose:
        return 'Contre-proposée';
      case ReservationStatus.annule:
        return 'Annulée';
    }
  }

  Color _statusColor(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.enAttente:
        return Colors.orange;
      case ReservationStatus.accepte:
        return Colors.green;
      case ReservationStatus.refuse:
      case ReservationStatus.annule:
        return Colors.red;
      case ReservationStatus.contrePropose:
        return Colors.blueGrey;
    }
  }

  // NOTIF: compare la longueur et incrémente le provider global si besoin
  void _maybeNotifyNewReservations() {
    final newCount = ref.read(reservationsProvider).reservations.length;
    if (newCount > _lastReservationsCount) {
      final diff = newCount - _lastReservationsCount;
      ref.read(newNotificationProvider.notifier).state += diff;
    }
    _lastReservationsCount = newCount;
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await ref.read(reservationsProvider.notifier).loadAll();
    // NOTIF: après refresh manuel, vérifier si de nouvelles résas sont arrivées
    _maybeNotifyNewReservations();
  }

  Future<void> _performAction({
    required Reservation reservation,
    required String action,
    DateTime? newDate,
    String? newHeureDebut,
    String? message,
  }) async {
    final notifier = ref.read(reservationsProvider.notifier);
    try {
      HapticFeedback.lightImpact();
      await notifier.updateReservation(
        id: reservation.id ?? '',
        action: action,
        newDate: newDate,
        newHeureDebut: newHeureDebut,
        message: message,
      );

      // --- recharger pour synchroniser toutes les vues ---
      await notifier.loadAll();

      // NOTIF: détecte si backend a ajouté de nouvelles réservations
      _maybeNotifyNewReservations();

      // NOTIF: si cette action inclut un message, alerter le dashboard (incrémente d'1)
      if (message != null && message.trim().isNotEmpty) {
        ref.read(newNotificationProvider.notifier).state += 1;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action effectuée : $action')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _showProposeDialog(Reservation r) async {
    DateTime? pickedDate = r.creneauDemande.date ?? DateTime.now();
    TimeOfDay? pickedTime = r.creneauDemande.heureDebut != null
        ? _parseTimeOfDay(r.creneauDemande.heureDebut!)
        : const TimeOfDay(hour: 9, minute: 0);

    final date = await showDatePicker(
      context: context,
      initialDate: pickedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: pickedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;

    final heureStr = time.format(context);
    final dateIso = DateTime(date.year, date.month, date.day);

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer contre-proposition'),
        content: Text('Proposer le ${_dateFmt.format(dateIso)} à $heureStr ?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirm == true) {
      await _performAction(
        reservation: r,
        action: 'contre_propose',
        newDate: dateIso,
        newHeureDebut: heureStr,
      );
    }
  }

  TimeOfDay? _parseTimeOfDay(String s) {
    try {
      final parts = s.split(':');
      final h = int.parse(parts[0]);
      final m = parts.length > 1 ? int.parse(parts[1]) : 0;
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  // Filtrage + recherche
  List<Reservation> _filterReservations(List<Reservation> all) {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = all.where((r) {
      final matchesFilter = _selectedFilter == 'Tous' || _statusLabel(r.status) == _selectedFilter;
      final clientOrPhone = (r.clientName.isNotEmpty ? r.clientName : r.clientPhone).toLowerCase();
      final service = (r.serviceName ?? r.serviceId).toLowerCase();
      final matchesSearch = q.isEmpty || clientOrPhone.contains(q) || service.contains(q) || (r.id ?? '').toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();

    // Safety: createdAt can be null -> fallback to epoch
    filtered.sort((a, b) {
      final da = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });

    return filtered;
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: const FlexibleSpaceBar(
        title: Text('Réservations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF357ABD), Color(0xFF357ABD)]),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF357ABD),
      elevation: 0,
      actions: [
        IconButton(
          tooltip: 'Rafraîchir',
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refresh,
        ),
      ],
    );
  }

  Widget _buildStatsCards(List<Reservation> reservations) {
    final enAttente = reservations.where((r) => r.status == ReservationStatus.enAttente).length;
    final accepte = reservations.where((r) => r.status == ReservationStatus.accepte).length;
    final refuse = reservations.where((r) => r.status == ReservationStatus.refuse).length;

    final stats = {
      'En attente': enAttente,
      'Acceptées': accepte,
      'Refusées': refuse,
    };

    return Row(
      children: stats.entries
          .map((entry) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Text('${entry.value}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      const SizedBox(height: 6),
                      Text(entry.key, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSearchFilter() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Rechercher (client, service, id)...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }))
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              items: ['Tous', 'En attente', 'Acceptée', 'Refusée', 'Contre-proposée', 'Annulée']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFilter = v ?? 'Tous'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationCard(Reservation r) {
    final requestedDate = r.creneauDemande.date;
    final requestedDateStr = requestedDate != null ? _dateFmt.format(requestedDate.toLocal()) : 'Date non définie';
    final requestedTimeStr = r.creneauDemande.heureDebut ?? 'Heure non définie';
    final serviceLabel = (r.serviceName != null && r.serviceName!.isNotEmpty) ? r.serviceName! : r.serviceId;
    final client = r.clientName.isNotEmpty ? r.clientName : r.clientPhone;

    final proposed = r.creneauPropose;
    final proposedDateStr = proposed?.date != null ? _dateFmt.format(proposed!.date!.toLocal()) : null;
    final proposedTimeStr = proposed?.heureDebut;

    // Card background forcé blanc et boutons retirés.
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon box (gris clair pour contraste)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.event_available, color: Color(0xFF357ABD)),
              ),
              const SizedBox(width: 12),
              // Main info: service label on first line, date/time below using Wrap to avoid overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client line
                    Text(client, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    // Service label
                    Text(serviceLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    // date/time using Wrap so it can wrap on small screens
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.black45),
                          const SizedBox(width: 6),
                          Text(requestedDateStr, style: const TextStyle(color: Colors.black54, fontSize: 13), overflow: TextOverflow.ellipsis),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.black45),
                          const SizedBox(width: 6),
                          Text(requestedTimeStr, style: const TextStyle(color: Colors.black54, fontSize: 13), overflow: TextOverflow.ellipsis),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status chip with constrained width to avoid forcing overflow
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _statusColor(r.status).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      _statusLabel(r.status),
                      style: TextStyle(color: _statusColor(r.status), fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ]),
            ],
          ),
          if (proposed != null && (proposedDateStr != null || proposedTimeStr != null))
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.swap_horiz, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Flexible(child: Text('Proposé: ${proposedDateStr ?? ''} ${proposedTimeStr ?? ''}', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ]),
            ),
          if (r.descriptionDepannage.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Description :', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
            const SizedBox(height: 6),
            Text(r.descriptionDepannage, style: const TextStyle(color: Colors.black87)),
          ],
          const SizedBox(height: 12),
          // Buttons removed as requested
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservationsProvider);
    final reservations = state.reservations;
    final filtered = _filterReservations(reservations);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildStatsCards(reservations),
                  const SizedBox(height: 16),
                  _buildSearchFilter(),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ),

          // content
          state.loading
              ? SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              : state.error != null
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(children: [
                          Center(child: Text('Erreur: ${state.error}')),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Réessayer'), onPressed: _refresh),
                        ]),
                      ),
                    )
                  : filtered.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: Center(child: Text('Aucune réservation', style: TextStyle(color: Colors.grey[600], fontSize: 16))),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) {
                              final r = filtered[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildReservationCard(r),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
        ],
      ),
    );
  }
}
