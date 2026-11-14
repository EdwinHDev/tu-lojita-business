import 'package:flutter/material.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';

/// Grupo de opciones personalizadas formateado para impresión/PDF.
class FormattedCustomizationGroup {
  final String groupName;
  final List<String> optionLabels;

  const FormattedCustomizationGroup({
    required this.groupName,
    required this.optionLabels,
  });

  String get displayLine => '$groupName: ${optionLabels.join(', ')}';
}

/// Utilidades puras para colores de variantes, personalizaciones y elegibilidad de exportación PDF.
class OrderPdfHelpers {
  /// Determina si una orden está completada / pagada en su totalidad y lista para hoja de control.
  static bool isOrderCompleted(Order order) {
    return order.status.toUpperCase() == 'FULLY_PAID' || order.isFullyPaid;
  }

  /// Retorna el código corto estándar de 8 caracteres para folios y nombres de archivo.
  static String shortOrderCode(String orderId) {
    final trimmed = orderId.trim();
    if (trimmed.isEmpty) return 'ORDEN';
    return trimmed.length > 8
        ? trimmed.substring(0, 8).toUpperCase()
        : trimmed.toUpperCase();
  }
}

/// Parser de colores para etiquetas de variantes (hexadecimal o nombre en español/inglés).
class VariantColorParser {
  static Color? parseColor(String text) {
    if (text.isEmpty) return null;

    final hexRegex = RegExp(r'#([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6})\b');
    final hexMatch = hexRegex.firstMatch(text);
    if (hexMatch != null) {
      final hex = hexMatch.group(1)!;
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }

    final lower = text.toLowerCase();
    const Map<String, Color> namedColors = {
      'rojo': Color(0xFFE11D48),
      'roja': Color(0xFFE11D48),
      'red': Color(0xFFE11D48),
      'azul': Color(0xFF2563EB),
      'blue': Color(0xFF2563EB),
      'negro': Color(0xFF0F172A),
      'negra': Color(0xFF0F172A),
      'black': Color(0xFF0F172A),
      'blanco': Color(0xFFFFFFFF),
      'blanca': Color(0xFFFFFFFF),
      'white': Color(0xFFFFFFFF),
      'verde': Color(0xFF16A34A),
      'green': Color(0xFF16A34A),
      'amarillo': Color(0xFFEAB308),
      'amarilla': Color(0xFFEAB308),
      'yellow': Color(0xFFEAB308),
      'naranja': Color(0xFFEA580C),
      'orange': Color(0xFFEA580C),
      'morado': Color(0xFF9333EA),
      'morada': Color(0xFF9333EA),
      'purple': Color(0xFF9333EA),
      'violeta': Color(0xFF7C3AED),
      'rosa': Color(0xFFEC4899),
      'rosado': Color(0xFFEC4899),
      'rosada': Color(0xFFEC4899),
      'pink': Color(0xFFEC4899),
      'gris': Color(0xFF64748B),
      'grey': Color(0xFF64748B),
      'gray': Color(0xFF64748B),
      'marron': Color(0xFF78350F),
      'marrón': Color(0xFF78350F),
      'brown': Color(0xFF78350F),
      'beige': Color(0xFFF5F5DC),
      'dorado': Color(0xFFD97706),
      'gold': Color(0xFFD97706),
      'plateado': Color(0xFF94A3B8),
      'silver': Color(0xFF94A3B8),
      'cyan': Color(0xFF06B6D4),
      'turquesa': Color(0xFF14B8A6),
    };

    for (final entry in namedColors.entries) {
      if (RegExp('\\b${entry.key}\\b', caseSensitive: false).hasMatch(lower)) {
        return entry.value;
      }
    }

    return null;
  }
}

/// Resuelve `selectedOptions` contra la definición de `CustomizationGroup` del artículo.
class OrderPdfCustomizationHelper {
  static List<FormattedCustomizationGroup> formatGroups({
    required Map<String, List<String>> selectedOptions,
    required List<CustomizationGroup> availableGroups,
  }) {
    if (selectedOptions.isEmpty) return const [];

    final result = <FormattedCustomizationGroup>[];

    for (final entry in selectedOptions.entries) {
      final groupId = entry.key;
      final optionIds = entry.value;
      if (optionIds.isEmpty) continue;

      final groupDef =
          availableGroups.where((g) => g.id == groupId).firstOrNull;
      final groupName = (groupDef != null && groupDef.name.trim().isNotEmpty)
          ? groupDef.name.trim()
          : (availableGroups.isEmpty ? groupId : 'Personalización');

      final counts = <String, int>{};
      for (final optId in optionIds) {
        counts[optId] = (counts[optId] ?? 0) + 1;
      }

      final labels = <String>[];
      for (final optEntry in counts.entries) {
        final optId = optEntry.key;
        final count = optEntry.value;

        var optName = optId;
        if (groupDef != null && groupDef.options.isNotEmpty) {
          final optDef =
              groupDef.options.where((o) => o.id == optId).firstOrNull;
          if (optDef != null && optDef.name.trim().isNotEmpty) {
            optName = optDef.name.trim();
          }
        }

        labels.add(count > 1 ? '$optName x$count' : optName);
      }

      if (labels.isNotEmpty) {
        result.add(
          FormattedCustomizationGroup(
            groupName: groupName,
            optionLabels: labels,
          ),
        );
      }
    }

    return result;
  }

  static String formatSingleLine({
    required Map<String, List<String>> selectedOptions,
    required List<CustomizationGroup> availableGroups,
  }) {
    final groups = formatGroups(
      selectedOptions: selectedOptions,
      availableGroups: availableGroups,
    );
    if (groups.isEmpty) return '';
    return groups.map((g) => g.displayLine).join(' | ');
  }
}
