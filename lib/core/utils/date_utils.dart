class AppTimezone {
  static String selectedTimezone = 'America/Caracas';

  static Duration get offset {
    if (selectedTimezone == 'America/Caracas') {
      return const Duration(hours: -4);
    }
    return const Duration(hours: -4); // Default/Venezuela
  }
}

extension DateTimeFormatting on DateTime {
  /// Retorna la fecha ajustada a la zona horaria elegida (UTC-4 por ahora).
  DateTime get local => toUtc().add(AppTimezone.offset);

  /// Retorna un formato amigable largo: "21 de mayo de 2026"
  String toFriendlyDate() {
    final localDate = local;
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${localDate.day} de ${months[localDate.month - 1]} de ${localDate.year}';
  }

  /// Retorna un formato amigable corto: "21 may, 2026"
  String toShortDateString() {
    final localDate = local;
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${localDate.day} ${months[localDate.month - 1]}, ${localDate.year}';
  }

  /// Retorna formato con barras: "21/05/2026"
  String toSlashDateString() {
    final localDate = local;
    final dayStr = localDate.day.toString().padLeft(2, '0');
    final monthStr = localDate.month.toString().padLeft(2, '0');
    return '$dayStr/$monthStr/${localDate.year}';
  }

  /// Retorna fecha y hora corta: "21/05 18:30"
  String toDateTimeString() {
    final localDate = local;
    final dayStr = localDate.day.toString().padLeft(2, '0');
    final monthStr = localDate.month.toString().padLeft(2, '0');
    final hourStr = localDate.hour.toString().padLeft(2, '0');
    final minuteStr = localDate.minute.toString().padLeft(2, '0');
    return '$dayStr/$monthStr $hourStr:$minuteStr';
  }

  /// Retorna la hora formateada: "06:30 PM" o "18:30"
  String toTimeString({bool use24Hour = false}) {
    final localDate = local;
    if (use24Hour) {
      final hourStr = localDate.hour.toString().padLeft(2, '0');
      final minuteStr = localDate.minute.toString().padLeft(2, '0');
      return '$hourStr:$minuteStr';
    } else {
      final hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;
      final minuteStr = localDate.minute.toString().padLeft(2, '0');
      final period = localDate.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:$minuteStr $period';
    }
  }
}
