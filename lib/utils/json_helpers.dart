String? _extractId(dynamic raw) {
  try {
    if (raw == null) return null;
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is Map) {
      if (raw.containsKey(r'$oid')) return raw[r'$oid']?.toString();
      // parfois le document complet est fourni sous la clé _id
      final cand = raw['_id'] ?? raw['id'] ?? raw['ID'];
      if (cand != null) {
        if (cand is String) return cand;
        if (cand is Map && cand.containsKey(r'$oid')) return cand[r'$oid']?.toString();
        return cand.toString();
      }
    }
    return raw.toString();
  } catch (_) {
    return null;
  }
}

DateTime? _parseDate(dynamic raw) {
  try {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    if (raw is Map) {
      if (raw.containsKey(r'$date')) {
        final val = raw[r'$date'];
        if (val is String) return DateTime.tryParse(val);
        if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}