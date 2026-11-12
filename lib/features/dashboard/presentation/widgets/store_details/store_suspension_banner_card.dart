import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_dashboard.dart';

/// Prominent Bento suspension & reactivation card shown beneath store identity
/// whenever a branch is in `SUSPENDED` status.
class StoreSuspensionBannerCard extends StatelessWidget {
  final Store store;
  final StoreStats? stats;
  final bool canViewFinancials;
  final VoidCallback onTapPayAndReactivate;
  final VoidCallback onOpenHealthSheet;

  const StoreSuspensionBannerCard({
    super.key,
    required this.store,
    this.stats,
    this.canViewFinancials = true,
    required this.onTapPayAndReactivate,
    required this.onOpenHealthSheet,
  });

  @override
  Widget build(BuildContext context) {
    if (store.status.toUpperCase() != 'SUSPENDED') {
      return const SizedBox.shrink();
    }

    final debt = stats?.commissionDebt ?? store.commissionDebt;
    final pendingReports =
        stats?.pendingCommissionReportsCount ?? store.pendingCommissionReportsCount;
    final activeStrikes = stats?.activeStrikesCount ?? 0;
    final hasPendingReview = pendingReports > 0;
    final isDebtSuspension = debt > 0 || hasPendingReview;

    // Restricted collaborator without financial permissions
    if (!canViewFinancials) {
      return _BentoSuspensionContainer(
        backgroundColor: TuLojitaBrandColors.dangerBg,
        borderColor: const Color(0xFFFCA5A5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SuspensionHeader(
              title: 'Tienda suspendida · Regularización pendiente',
              subtitle:
                  'Esta sucursal está oculta temporalmente para los compradores.',
              accentColor: TuLojitaBrandColors.danger,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                'Tu rol actual es de solo lectura financiera. Solicita al dueño o administrador financiero completar el pago en Deudas con la Plataforma para reactivar la tienda.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: TuLojitaBrandColors.inkSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Debt suspension with a submitted receipt awaiting review
    if (isDebtSuspension && hasPendingReview) {
      return _BentoSuspensionContainer(
        backgroundColor: TuLojitaBrandColors.indigo50,
        borderColor: TuLojitaBrandColors.indigo600.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SuspensionHeader(
              title: 'Pago en revisión · Tienda aún suspendida',
              subtitle:
                  'Ya recibimos tu comprobante de pago por comisiones vencidas.',
              accentColor: TuLojitaBrandColors.indigo700,
              icon: HugeIcons.strokeRoundedClock01,
            ),
            if (debt > 0) ...[
              const SizedBox(height: 12),
              _DebtAmountBox(
                debt: debt,
                label: 'Saldo en regularización',
                borderColor: TuLojitaBrandColors.indigo100,
                amountColor: TuLojitaBrandColors.indigo700,
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'El equipo administrativo está validando tu reporte. Si cubre el total adeudado, tu tienda y catálogo se reactivarán automáticamente al aprobarse.',
              style: TextStyle(
                fontSize: 12.5,
                color: TuLojitaBrandColors.inkSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTapPayAndReactivate,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedInvoice01,
                  color: TuLojitaBrandColors.indigo700,
                  size: 16,
                ),
                label: const Text(
                  'Ver estado del pago',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TuLojitaBrandColors.indigo700,
                  side: const BorderSide(color: TuLojitaBrandColors.indigo600),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Strike / moderation suspension (when no commission debt is present)
    if (!isDebtSuspension && activeStrikes > 0) {
      return _BentoSuspensionContainer(
        backgroundColor: TuLojitaBrandColors.dangerBg,
        borderColor: const Color(0xFFFCA5A5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SuspensionHeader(
              title: 'Tienda suspendida por moderación',
              subtitle:
                  'Se registran $activeStrikes ${activeStrikes == 1 ? 'strike activo' : 'strikes activos'}. Ni la tienda ni sus productos son visibles al público.',
              accentColor: TuLojitaBrandColors.danger,
              icon: HugeIcons.strokeRoundedShield01,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenHealthSheet,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedShield01,
                  color: Colors.white,
                  size: 17,
                ),
                label: const Text(
                  'Revisar salud y sanciones',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TuLojitaBrandColors.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Commission debt suspension (or general suspended branch where financial action resolves it)
    return _BentoSuspensionContainer(
      backgroundColor: TuLojitaBrandColors.dangerBg,
      borderColor: const Color(0xFFFCA5A5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SuspensionHeader(
            title: 'Tienda suspendida por mora en comisiones',
            subtitle:
                'Tu catálogo y productos están ocultos para los compradores hasta regularizar el saldo vencido.',
            accentColor: TuLojitaBrandColors.danger,
          ),
          if (debt > 0) ...[
            const SizedBox(height: 12),
            _DebtAmountBox(
              debt: debt,
              label: 'Deuda total a regularizar',
              borderColor: const Color(0xFFFECACA),
              amountColor: TuLojitaBrandColors.danger,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cómo reactivar tu tienda:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                ),
                SizedBox(height: 6),
                _StepLine(
                  step: '1',
                  text: 'Revisa las cuentas oficiales y copia los datos de pago.',
                ),
                SizedBox(height: 4),
                _StepLine(
                  step: '2',
                  text: 'Transfiere el monto en USD o Bs. y reporta tu comprobante.',
                ),
                SizedBox(height: 4),
                _StepLine(
                  step: '3',
                  text:
                      'Al verificarse el pago completo, tu tienda se reactiva automáticamente.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTapPayAndReactivate,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedInvoice01,
                color: Colors.white,
                size: 17,
              ),
              label: const Text(
                'Pagar y reactivar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TuLojitaBrandColors.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoSuspensionContainer extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  const _BentoSuspensionContainer({
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: child,
    );
  }
}

class _SuspensionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final dynamic icon;

  const _SuspensionHeader({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.icon = HugeIcons.strokeRoundedAlertCircle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TuLojitaBrandColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          child: HugeIcon(icon: icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: TuLojitaBrandColors.inkSecondary,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DebtAmountBox extends StatelessWidget {
  final double debt;
  final String label;
  final Color borderColor;
  final Color amountColor;

  const _DebtAmountBox({
    required this.debt,
    required this.label,
    required this.borderColor,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: TuLojitaBrandColors.inkSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: DualPriceText(
              amountInUsd: debt,
              isInline: true,
              crossAxisAlignment: CrossAxisAlignment.end,
              usdStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: amountColor,
              ),
              bsStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: TuLojitaBrandColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final String step;
  final String text;

  const _StepLine({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TuLojitaBrandColors.dangerBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: TuLojitaBrandColors.danger,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: TuLojitaBrandColors.inkPrimary,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
