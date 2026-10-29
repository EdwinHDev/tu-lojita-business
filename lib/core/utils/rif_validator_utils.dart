/// Utilidades para validación y cálculo del Registro de Información Fiscal (RIF) venezolano.
/// Implementa el algoritmo oficial Módulo 11 del SENIAT.
class RifValidatorUtils {
  static const Map<String, int> letterBases = {
    'V': 4,
    'E': 8,
    'J': 12,
    'C': 12,
    'P': 16,
    'G': 20,
  };

  static const List<int> weights = [3, 2, 7, 6, 5, 4, 3, 2];

  /// Calcula el dígito verificador oficial del SENIAT (Módulo 11).
  /// [prefix] Debe ser una letra válida: V, E, J, C, P, G.
  /// [numberStr] Número de cédula o identificación (hasta 8 dígitos).
  /// Si tiene menos de 8 dígitos se rellena automáticamente con ceros a la izquierda.
  static int? calculateCheckDigit(String prefix, String numberStr) {
    final cleanPrefix = prefix.toUpperCase().trim();
    final base = letterBases[cleanPrefix];
    if (base == null) return null;

    final cleanDigits = numberStr.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) return null;

    // Rellenar con ceros a la izquierda hasta 8 dígitos
    final paddedNumber = cleanDigits.padLeft(8, '0');
    if (paddedNumber.length > 8) return null;

    int sum = base;
    for (int i = 0; i < 8; i++) {
      sum += int.parse(paddedNumber[i]) * weights[i];
    }

    final remainder = sum % 11;
    int expectedDigit = 11 - remainder;
    if (expectedDigit >= 10) expectedDigit = 0;

    return expectedDigit;
  }

  /// Retorna el RIF completamente formateado: `X-XXXXXXXX-X`
  static String? formatRif(String prefix, String numberStr) {
    final digit = calculateCheckDigit(prefix, numberStr);
    if (digit == null) return null;
    final cleanDigits = numberStr.replaceAll(RegExp(r'[^0-9]'), '').padLeft(8, '0');
    return '${prefix.toUpperCase().trim()}-$cleanDigits-$digit';
  }

  /// Valida si un string de RIF completo cumple con el formato y el Módulo 11.
  static bool isValidRif(String? rif) {
    if (rif == null || rif.isEmpty) return false;
    final regExp = RegExp(r'^[VEJCPGvejcpg]-\d{8}-\d$');
    if (!regExp.hasMatch(rif)) return false;

    final parts = rif.split('-');
    if (parts.length != 3) return false;

    final calculated = calculateCheckDigit(parts[0], parts[1]);
    return calculated != null && calculated.toString() == parts[2];
  }
}
