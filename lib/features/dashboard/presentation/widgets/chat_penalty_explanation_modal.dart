import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatPenaltyExplanationModal extends StatelessWidget {
  final String title;
  final String body;

  const ChatPenaltyExplanationModal({
    super.key,
    required this.title,
    required this.body,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChatPenaltyExplanationModal(
        title: title,
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowerTitle = title.toLowerCase();
    final bool isWarning = lowerTitle.contains('advertencia');
    final bool isPermBan = lowerTitle.contains('definitiva') ||
        lowerTitle.contains('permanente') ||
        title.contains('🚫');
    final bool is72h = lowerTitle.contains('72');
    final bool is15d = lowerTitle.contains('15');
    final bool is30d = lowerTitle.contains('30');
    final bool isTempSuspension = is72h || is15d || is30d || lowerTitle.contains('temporal');

    final Color primaryColor;
    final Color bgColor;
    final Color borderColor;
    final dynamic iconData;
    final String badgeText;

    if (isWarning) {
      primaryColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      iconData = HugeIcons.strokeRoundedAlertSquare;
      badgeText = 'Advertencia de Moderación';
    } else if (isPermBan) {
      primaryColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      iconData = HugeIcons.strokeRoundedUserBlock01;
      badgeText = 'Suspensión Definitiva de Chat';
    } else if (isTempSuspension) {
      primaryColor = const Color(0xFFEA580C);
      bgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFED7AA);
      iconData = is72h
          ? HugeIcons.strokeRoundedClock01
          : HugeIcons.strokeRoundedCalendar03;
      badgeText = is72h
          ? 'Suspensión Temporal (72 Horas)'
          : is15d
              ? 'Suspensión Temporal (15 Días)'
              : is30d
                  ? 'Suspensión Temporal (30 Días)'
                  : 'Suspensión Temporal de Chat';
    } else {
      primaryColor = const Color(0xFF4F46E5);
      bgColor = const Color(0xFFEEF2FF);
      borderColor = const Color(0xFFC7D2FE);
      iconData = HugeIcons.strokeRoundedAlertCircle;
      badgeText = 'Resolución de Moderación';
    }

    // Parsear el motivo y evidencias si vienen estructurados en body
    String mainDescription = body;
    String? reason;
    List<String> evidenceList = [];

    if (body.contains('Mensajes citados como evidencia:')) {
      final parts = body.split('Mensajes citados como evidencia:');
      final topSection = parts[0].trim();
      final evidenceSection = parts.length > 1 ? parts[1].trim() : '';

      if (topSection.contains('Motivo:')) {
        final reasonParts = topSection.split('Motivo:');
        mainDescription = reasonParts[0].trim();
        reason = reasonParts.length > 1 ? reasonParts[1].trim() : null;
      } else {
        mainDescription = topSection;
      }

      if (evidenceSection.isNotEmpty) {
        evidenceList = evidenceSection
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .map((e) => e.startsWith('• ') ? e.substring(2).trim() : e)
            .toList();
      }
    } else if (body.contains('Motivo:')) {
      final reasonParts = body.split('Motivo:');
      mainDescription = reasonParts[0].trim();
      reason = reasonParts.length > 1 ? reasonParts[1].trim() : null;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Content
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              children: [
                // Icon Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: HugeIcon(
                      icon: iconData,
                      color: primaryColor,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Description
                if (mainDescription.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      mainDescription,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF334155),
                        height: 1.45,
                      ),
                    ),
                  ),

                // Reason Card
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedInformationCircle,
                              color: primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Motivo de la moderación',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Evidence Section
                if (evidenceList.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedComment01,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Mensajes citados como evidencia',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...evidenceList.map((item) {
                    final cleanItem = item.replaceAll('^"|"\$', '');
                    final isGap = cleanItem.contains('Se omitieron mensajes intermedios');

                    if (isGap) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedMoreHorizontalCircle01,
                              color: Color(0xFF64748B),
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Se omitieron mensajes intermedios',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        cleanItem,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E293B),
                          height: 1.35,
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
