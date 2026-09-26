import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../domain/entities/order_dispute.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPendingAction ? const Color(0xFFFEF2F2) : status.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPendingAction ? const Color(0xFFEF4444) : status.textColor.withValues(alpha: 0.3),
          width: isPendingAction ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPendingAction ? Colors.red : Colors.blue).withValues(alpha: 0.06),
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
                  color: isPendingAction ? const Color(0xFFFEE2E2) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: isPendingAction
                      ? HugeIcons.strokeRoundedAlert02
                      : HugeIcons.strokeRoundedClock01,
                  color: isPendingAction ? const Color(0xFFDC2626) : status.textColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPendingAction
                          ? '¡RECLAMO PENDIENTE DE RESPUESTA!'
                          : 'Reclamo del Cliente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isPendingAction ? const Color(0xFF991B1B) : status.textColor,
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
                  border: Border.all(color: status.textColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: status.textColor,
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

          if (isPendingAction) ...[
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
