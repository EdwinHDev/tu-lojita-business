import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../domain/entities/crm_entities.dart';

String? resolveCrmImageUrl(String? rawUrl) {
  final trimmed = rawUrl?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  String baseUrl = '';
  try {
    baseUrl = Envs.apiBaseUrlImages;
  } catch (_) {}
  final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
  final cleanPath = trimmed.replaceAll(RegExp(r'^/+'), '');
  if (cleanBase.isEmpty) return '/$cleanPath';
  return '$cleanBase/$cleanPath';
}

class SegmentBadgeMeta {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const SegmentBadgeMeta({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}

SegmentBadgeMeta crmSegmentMeta(String segment) {
  switch (segment.toUpperCase()) {
    case 'VIP':
      return const SegmentBadgeMeta(
        label: 'VIP',
        color: TuLojitaBrandColors.amber800,
        bgColor: TuLojitaBrandColors.amber100,
        icon: Icons.workspace_premium_rounded,
      );
    case 'FREQUENT':
      return const SegmentBadgeMeta(
        label: 'Frecuente',
        color: TuLojitaBrandColors.indigo700,
        bgColor: TuLojitaBrandColors.indigo100,
        icon: Icons.repeat_rounded,
      );
    case 'AT_RISK':
      return const SegmentBadgeMeta(
        label: 'En Riesgo',
        color: Color(0xFFB45309),
        bgColor: Color(0xFFFFEDD5),
        icon: Icons.warning_amber_rounded,
      );
    case 'WITH_DEBT':
      return const SegmentBadgeMeta(
        label: 'Con Deuda',
        color: TuLojitaBrandColors.danger,
        bgColor: TuLojitaBrandColors.dangerBg,
        icon: Icons.account_balance_wallet_outlined,
      );
    case 'BLOCKED':
      return const SegmentBadgeMeta(
        label: 'Bloqueado',
        color: Color(0xFF991B1B),
        bgColor: Color(0xFFFEE2E2),
        icon: Icons.block_rounded,
      );
    case 'WISHLIST':
      return const SegmentBadgeMeta(
        label: 'Favoritos',
        color: Color(0xFF9D174D),
        bgColor: Color(0xFFFCE7F3),
        icon: Icons.favorite_rounded,
      );
    case 'NEW':
    default:
      return const SegmentBadgeMeta(
        label: 'Nuevo',
        color: TuLojitaBrandColors.positive,
        bgColor: TuLojitaBrandColors.positiveBg,
        icon: Icons.fiber_new_rounded,
      );
  }
}

String _sanitizePhoneDigits(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0') && digits.length == 11) {
    digits = '58${digits.substring(1)}';
  }
  return digits;
}

Future<void> launchDirectWhatsApp(
  BuildContext context,
  String phone, {
  String message = '',
}) async {
  final digits = _sanitizePhoneDigits(phone);
  if (digits.isEmpty) {
    if (context.mounted) {
      NotificationService.showWarning(
        context,
        'El cliente no tiene un número telefónico válido.',
      );
    }
    return;
  }
  final encoded = Uri.encodeComponent(message);
  final uri = Uri.parse(
    'https://wa.me/$digits${encoded.isNotEmpty ? '?text=$encoded' : ''}',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    NotificationService.showError(
      context,
      'No se pudo abrir WhatsApp.',
    );
  }
}

Future<void> openWhatsAppTemplateSheet(
  BuildContext context,
  CrmCustomer customer, {
  Future<void> Function()? onMarkContacted,
}) async {
  final storeName = customer.primaryStore?.name ?? 'nuestra tienda';
  final firstFav = customer.topFavoriteItems.isNotEmpty
      ? customer.topFavoriteItems.first.title
      : null;

  final templates = <({String title, String subtitle, String text})>[
    (
      title: 'Saludo VIP / Atención Personalizada',
      subtitle: 'Mantén cercanía comercial con el cliente',
      text:
          '¡Hola ${customer.firstName}! Te saluda el equipo de $storeName en Tu Lojita. Queríamos saber cómo te ha ido con tus compras recientes y si necesitas ayuda con algún producto.',
    ),
    if (customer.pendingDebtUsd > 0)
      (
        title: 'Recordatorio Amigable de Cuotas',
        subtitle:
            'Saldo pendiente: \$${customer.pendingDebtUsd.toStringAsFixed(2)}',
        text:
            '¡Hola ${customer.firstName}! Te recordamos con cariño que en $storeName tienes un saldo de cuotas pendiente por \$${customer.pendingDebtUsd.toStringAsFixed(2)} USD. Puedes reportar tu pago desde Tu Lojita cuando gustes.',
      ),
    if (firstFav != null)
      (
        title: 'Seguimiento de Favorito',
        subtitle: 'Mencionar "$firstFav"',
        text:
            '¡Hola ${customer.firstName}! Notamos tu interés en "$firstFav" en $storeName. Avísanos si deseas consultar disponibilidad o recibir atención inmediata por acá.',
      ),
    (
      title: 'Abrir Chat en Blanco',
      subtitle: 'Redacta tu propio mensaje directo en WhatsApp',
      text: '',
    ),
  ];

  final chosen = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escribir por WhatsApp a ${customer.firstName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...templates.map(
                (t) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const CircleAvatar(
                    backgroundColor: TuLojitaBrandColors.positiveBg,
                    child: Icon(
                      Icons.chat_rounded,
                      color: TuLojitaBrandColors.positive,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    t.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    t.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => Navigator.of(ctx).pop(t.text),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (chosen == null || !context.mounted) return;
  if (onMarkContacted != null) {
    await onMarkContacted();
  }
  if (context.mounted) {
    await launchDirectWhatsApp(context, customer.phone, message: chosen);
  }
}

Future<void> callCustomerPhone(BuildContext context, String phone) async {
  final cleaned = phone.trim();
  if (cleaned.isEmpty) return;
  final ok = await launchUrl(Uri.parse('tel:$cleaned'));
  if (!ok && context.mounted) {
    NotificationService.showError(
      context,
      'No se pudo iniciar la llamada.',
    );
  }
}

Future<void> openCustomerLocationMap(
  BuildContext context,
  CrmAddress address,
) async {
  final query = address.hasCoordinates
      ? '${address.latitude},${address.longitude}'
      : Uri.encodeComponent(address.fullAddress);
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    NotificationService.showError(
      context,
      'No se pudo abrir Google Maps.',
    );
  }
}
