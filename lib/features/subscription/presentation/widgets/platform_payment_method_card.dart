import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../domain/entities/platform_payment_method.dart';
import 'platform_qr_dialog.dart';

/// Shared Bento card for displaying official platform payment accounts,
/// copyable details, instructions, QR dialog preview, and optional prefill trigger.
class PlatformPaymentMethodCard extends StatelessWidget {
  final PlatformPaymentMethod method;
  final VoidCallback? onSelectMethod;
  final String selectionLabel;
  final bool? isDarkOverride;

  const PlatformPaymentMethodCard({
    super.key,
    required this.method,
    this.onSelectMethod,
    this.selectionLabel = 'Reportar con esta cuenta',
    this.isDarkOverride,
  });

  static String formatTypeLabel(String rawType) {
    switch (rawType.toUpperCase()) {
      case 'PAGO_MOVIL':
        return 'Pago Móvil';
      case 'BANK_TRANSFER':
        return 'Transferencia';
      case 'BINANCE_PAY':
        return 'Binance Pay';
      case 'CASH_USD':
        return 'Efectivo USD';
      case 'CASH_BS':
        return 'Efectivo Bs.';
      default:
        return rawType.replaceAll('_', ' ');
    }
  }

  static List<MapEntry<String, String>> extractDetailEntries(
    Map<String, dynamic> d,
  ) {
    final entries = <MapEntry<String, String>>[];
    void addIfPresent(String key, String label) {
      final raw = d[key];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        entries.add(MapEntry(label, raw.toString().trim()));
      }
    }

    addIfPresent('bankName', 'Banco');
    addIfPresent('accountHolder', 'Titular');
    addIfPresent('accountType', 'Tipo');
    addIfPresent('phoneNumber', 'Teléfono');
    addIfPresent('idNumber', 'C.I. / RIF');
    addIfPresent('accountNumber', 'Nº Cuenta');
    addIfPresent('binancePayId', 'Binance Pay ID');
    addIfPresent('email', 'Correo');
    return entries;
  }

  void _copyField(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    NotificationService.showSuccess(context, '$label copiado al portapapeles');
  }

  void _copyAllDetails(
    BuildContext context,
    List<MapEntry<String, String>> entries,
  ) {
    final buffer = StringBuffer()..writeln(method.title);
    for (final entry in entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    NotificationService.showSuccess(
      context,
      'Datos de ${method.title} copiados al portapapeles',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        isDarkOverride ?? (Theme.of(context).brightness == Brightness.dark);
    final entries = extractDetailEntries(method.accountDetails);
    final instructions = method.instructions?.trim();
    final hasQr =
        method.qrImageUrl != null && method.qrImageUrl!.trim().isNotEmpty;

    final cardBg =
        isDark ? const Color(0xFF1E293B) : TuLojitaBrandColors.surface;
    final borderColor =
        isDark ? const Color(0xFF334155) : TuLojitaBrandColors.borderSubtle;
    final labelColor =
        isDark ? Colors.grey[400]! : TuLojitaBrandColors.inkSecondary;
    final valueColor =
        isDark ? Colors.white : TuLojitaBrandColors.inkPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  method.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: TuLojitaBrandColors.indigo50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TuLojitaBrandColors.indigo100),
                ),
                child: Text(
                  formatTypeLabel(method.type),
                  style: const TextStyle(
                    color: TuLojitaBrandColors.indigo700,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: valueColor,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _copyField(context, entry.value, entry.key),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCopy01,
                          color: TuLojitaBrandColors.indigo600,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (instructions != null && instructions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : TuLojitaBrandColors.canvas,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      color: TuLojitaBrandColors.indigo600,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      instructions,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InkWell(
                onTap: () => _copyAllDetails(context, entries),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.indigo50,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: TuLojitaBrandColors.indigo100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCopy01,
                        color: TuLojitaBrandColors.indigo700,
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Copiar todo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: TuLojitaBrandColors.indigo700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasQr)
                InkWell(
                  onTap: () => PlatformQrDialog.show(
                    context,
                    qrImageUrl: method.qrImageUrl!,
                    title: method.title,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: TuLojitaBrandColors.indigo50,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: TuLojitaBrandColors.indigo100),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedQrCode,
                          color: TuLojitaBrandColors.indigo700,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Ver QR',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: TuLojitaBrandColors.indigo700,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (onSelectMethod != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSelectMethod,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: Colors.white,
                  size: 15,
                ),
                label: Text(
                  selectionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TuLojitaBrandColors.indigo600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
