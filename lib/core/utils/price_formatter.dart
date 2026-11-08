import 'package:intl/intl.dart';

class PriceFormatter {
  static String formatNumeric(double amount) {
    final formatter = NumberFormat('#,##0.00', 'es_ES');
    return '\$ ${formatter.format(amount)}';
  }

  static String formatBsNumeric(double amountInBs) {
    final formatter = NumberFormat('#,##0.00', 'es_ES');
    return 'Bs. ${formatter.format(amountInBs)}';
  }
}

