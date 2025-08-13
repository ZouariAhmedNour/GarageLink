import 'package:intl/intl.dart';

class Fmt {
  static String money(num v, {String locale = 'fr_FR'}) => NumberFormat.currency(locale: locale, symbol: 'TND').format(v);
  static String date(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (m == 0) return '$h h';
    return '${h}h ${m.toString().padLeft(2, '0')}';
  }
}