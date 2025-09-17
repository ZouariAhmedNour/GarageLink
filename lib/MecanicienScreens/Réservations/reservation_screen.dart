// lib/screens/reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/reservation_provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/models/reservation.dart';

class ReservationScreen extends ConsumerStatefulWidget {
  const ReservationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> {
  final DateFormat _dateFmt = DateFormat.yMd();
  final DateFormat _timeFmt = DateFormat.Hm();

  @override
  void initState() {
    super.initState();
    // charge la liste après build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reservationsProvider.notifier).loadAll();
    });
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

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await ref.read(reservationsProvider.notifier).loadAll();
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
        : TimeOfDay(hour: 9, minute: 0);

    final date = await showDatePicker(
      context: context,
      initialDate: pickedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: pickedTime ?? TimeOfDay(hour: 9, minute: 0),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservationsProvider);
    final notifier = ref.read(reservationsProvider.notifier);
    final reservations = state.reservations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        backgroundColor: const Color(0xFF357ABD),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF357ABD),
        child: Builder(builder: (context) {
          if (state.loading) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.error != null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(child: Text('Erreur: ${state.error}')),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    onPressed: _refresh,
                  ),
                ),
              ],
            );
          }
          if (reservations.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Aucune réservation', style: TextStyle(fontSize: 16))),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reservations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final r = reservations[idx];
              final dateStr = r.creneauDemande.date != null ? _dateFmt.format(r.creneauDemande.date!.toLocal()) : 'Date non définie';
              final timeStr = r.creneauDemande.heureDebut ?? (r.creneauPropose?.heureDebut ?? 'Heure non définie');
              final serviceLabel = (r.serviceName != null && r.serviceName!.isNotEmpty) ? r.serviceName! : r.serviceId;
              final client = r.clientName.isNotEmpty ? r.clientName : r.clientPhone;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header row
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.event_available, color: Color(0xFF357ABD)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(client, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('$serviceLabel • $dateStr • $timeStr', style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(r.status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_statusLabel(r.status), style: TextStyle(color: _statusColor(r.status), fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 6),
                              Text(r.id ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (r.descriptionDepannage.isNotEmpty)
                        Text(r.descriptionDepannage, style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 12),
                      // actions
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.request_quote),
                            label: const Text('Devis'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF357ABD)),
                            onPressed: () {
                              // transformer en devis : navigation vers créationDevis avec l'objet réservation
                              Get.toNamed(AppRoutes.creationDevis, arguments: r);
                            },
                          ),
                          const SizedBox(width: 8),
                          if (r.status == ReservationStatus.enAttente || r.status == ReservationStatus.contrePropose) ...[
                            OutlinedButton(
                              onPressed: () async {
                                final confirm = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Accepter la réservation'),
                                    content: const Text('Confirmer l\'acceptation ?'),
                                    actions: [
                                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Non')),
                                      ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Oui')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _performAction(reservation: r, action: 'accepte');
                                }
                              },
                              child: const Text('Accepter'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () async {
                                final confirm = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Refuser la réservation'),
                                    content: const Text('Voulez-vous refuser cette réservation ?'),
                                    actions: [
                                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Non')),
                                      ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Oui')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _performAction(reservation: r, action: 'refuse');
                                }
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Refuser'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _showProposeDialog(r),
                              child: const Text('Contre-proposer'),
                            ),
                          ],
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final confirm = await Get.dialog<bool>(
                                AlertDialog(
                                  title: const Text('Annuler la réservation'),
                                  content: const Text('Confirmer l\'annulation ?'),
                                  actions: [
                                    TextButton(onPressed: () => Get.back(result: false), child: const Text('Non')),
                                    ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Oui')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _performAction(reservation: r, action: 'annule');
                              }
                            },
                            child: const Text('Annuler', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
