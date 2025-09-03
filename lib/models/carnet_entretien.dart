import 'package:uuid/uuid.dart';

class CarnetEntretien {
  final String idOperation;
  final DateTime dateOperation;
  final String service; 
  final String tache;
  final double coutTotal;
  final String? notes;

  CarnetEntretien({
    String? idOperation,
    required this.dateOperation,
    this.service = 'entretien',
    required this.tache,
    required this.coutTotal,
    this.notes,
  }) : idOperation = idOperation ?? const Uuid().v4();

  CarnetEntretien copyWith({
    String? idOperation,
    DateTime? dateOperation,
    String? service,
    String? tache,
    double? coutTotal,
    String? notes,
  }) {
    return CarnetEntretien(
      idOperation: idOperation ?? this.idOperation,
      dateOperation: dateOperation ?? this.dateOperation,
      service: service ?? this.service,
      tache: tache ?? this.tache,
      coutTotal: coutTotal ?? this.coutTotal,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idOperation': idOperation,
      'dateOperation': dateOperation.toIso8601String(),
      'service': service,
      'tache': tache,
      'coutTotal': coutTotal,
      'notes': notes,
    };
  }

  factory CarnetEntretien.fromJson(Map<String, dynamic> m) {
    return CarnetEntretien(
      idOperation: m['idOperation'] as String?,
      dateOperation: DateTime.parse(m['dateOperation'] as String),
      service: (m['service'] as String?) ?? 'entretien',
      tache: (m['tache'] as String?) ?? '',
      coutTotal: (m['coutTotal'] is num) ? (m['coutTotal'] as num).toDouble() : double.parse((m['coutTotal'] ?? '0').toString()),
      notes: m['notes'] as String?,
    );
  }
}