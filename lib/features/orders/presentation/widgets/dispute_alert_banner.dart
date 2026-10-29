import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../domain/entities/order_dispute.dart';
import '../../domain/enums/dispute_enums.dart';

class DisputeAlertBanner extends StatelessWidget {
  final OrderDispute dispute;
  final VoidCallback onRespond;

  const DisputeAlertBanner({
    super.key,
    required this.dispute,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final status = dispute.status;
    final isPendingAction = status.requiresMerchantAction;
    final isAdminReview = status == DisputeStatus.adminReview;

    final bannerBgColor = isAdminReview
        ? const Color(0xFFF5F3FF)
        : isPendingAction
            ? const Color(0xFFFEF2F2)
            : status.backgroundColor;

    final bannerBorderColor = isAdminReview
        ? const Color(0xFFDDD6FE)
        : isPendingAction
            ? const Color(0xFFEF4444)
            : status.textColor.withValues(alpha: 0.3);

    final bannerTitle = isAdminReview
        ? 'Pedido en mediación con Soporte'
        : isPendingAction
            ? '¡RECLAMO PENDIENTE DE RESPUESTA!'
            : 'Reclamo del Cliente';

    final bannerTitleColor = isAdminReview
        ? const Color(0xFF5B21B6)
        : isPendingAction
            ? const Color(0xFF991B1B)
            : status.textColor;

    final iconBgColor = isAdminReview
        ? const Color(0xFFEDE9FE)
        : isPendingAction
            ? const Color(0xFFFEE2E2)
            : Colors.white;

    final iconColor = isAdminReview
        ? const Color(0xFF7C3AED)
        : isPendingAction
            ? const Color(0xFFDC2626)
            : status.textColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bannerBorderColor,
          width: (isPendingAction || isAdminReview) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAdminReview
                    ? Colors.purple
                    : isPendingAction
                        ? Colors.red
                        : Colors.blue)
                .withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: isAdminReview
                    ? const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      )
                    : HugeIcon(
                        icon: isPendingAction
                            ? HugeIcons.strokeRoundedAlert02
                            : HugeIcons.strokeRoundedClock01,
                        color: iconColor,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bannerTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: bannerTitleColor,
                      ),
                    ),
                    Text(
                      'Motivo: ${dispute.type.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAdminReview
                        ? const Color(0xFFDDD6FE)
                        : status.textColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  isAdminReview ? 'En Mediación' : status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAdminReview
                        ? const Color(0xFF7C3AED)
                        : status.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Reason summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              '"${dispute.reason}"',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Color(0xFF374151),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (isAdminReview) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF7C3AED),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este caso fue escalado a una disputa y está en proceso de revisión por el equipo de soporte. Es posible que el soporte se ponga en contacto contigo para resolver el caso.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF5B21B6),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/orders/${dispute.orderId}/support-chat');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.support_agent_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Hablar con Soporte',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],

          if (isPendingAction && !isAdminReview) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onRespond,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedComment01,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Responder al Reclamo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
