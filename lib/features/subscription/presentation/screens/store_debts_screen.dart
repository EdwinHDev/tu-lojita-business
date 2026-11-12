import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_image_resolver.dart';
import '../../domain/entities/platform_payment_method.dart';
import '../providers/subscription_provider.dart';
import '../widgets/platform_payment_method_card.dart';
import '../widgets/platform_qr_dialog.dart';

class StoreDebtsScreen extends ConsumerStatefulWidget {
  final String storeId;
  final Future<File?> Function(ImageSource source)? receiptPickerOverride;

  const StoreDebtsScreen({
    super.key,
    required this.storeId,
    this.receiptPickerOverride,
  });

  @override
  ConsumerState<StoreDebtsScreen> createState() => _StoreDebtsScreenState();
}

class _StoreDebtsScreenState extends ConsumerState<StoreDebtsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _debtData;

  @override
  void initState() {
    super.initState();
    _loadDebtData();
    Future.microtask(
      () => ref.read(subscriptionProvider.notifier).loadSubscriptionAndMethods(),
    );
  }

  Future<void> _loadDebtData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final res =
          await dio.get('/commissions/stores/${widget.storeId}/debt-hub');
      if (!mounted) return;
      setState(() {
        _debtData = (res.data as Map).cast<String, dynamic>();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No pudimos consultar el estado de comisiones.';
        _isLoading = false;
      });
    }
  }

  List<PlatformPaymentMethod> _resolveMethods() {
    final apiRaw = _debtData?['platformPaymentMethods'] as List?;
    if (apiRaw != null && apiRaw.isNotEmpty) {
      return apiRaw
          .whereType<Map>()
          .map(
            (m) => PlatformPaymentMethod.fromJson(
              Map<String, dynamic>.from(m),
            ),
          )
          .where((m) => m.isActive)
          .toList();
    }
    return ref.read(subscriptionProvider).paymentMethods;
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  void _showReportPaymentModal({PlatformPaymentMethod? preselectedMethod}) {
    final methods = _resolveMethods();
    final billing = _debtData?['currentBilling'] as Map<String, dynamic>?;
    final billingId = billing?['id']?.toString() ?? '';
    final store = _debtData?['store'] as Map<String, dynamic>?;
    final currentDebt = _toDouble(store?['accumulatedCommissionDebt']);

    if (billingId.isEmpty && currentDebt <= 0) {
      NotificationService.showInfo(
        context,
        'Tu tienda no tiene cortes ni deudas pendientes de comisiones.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReportCommissionPaymentModal(
        storeId: widget.storeId,
        billingId: billingId,
        debtAmount: currentDebt,
        methods: methods,
        initialMethod: preselectedMethod,
        receiptPickerOverride: widget.receiptPickerOverride,
        onSuccess: () {
          Navigator.of(ctx).pop();
          _loadDebtData();
          NotificationService.showSuccess(
            context,
            'Comprobante enviado. Nuestro equipo lo verificará pronto.',
          );
        },
      ),
    );
  }

  int? _daysRemaining(DateTime? deadline) {
    if (deadline == null) return null;
    final localDeadline = deadline.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay =
        DateTime(localDeadline.year, localDeadline.month, localDeadline.day);
    final diff = endDay.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  double _computeFinePreview(
    double baseAmount,
    Map<String, dynamic>? settings,
  ) {
    if (baseAmount <= 0 || settings == null) return 0;
    final fineType = (settings['fineType'] ?? 'PERCENTAGE').toString();
    final fineValue = _toDouble(settings['fineValue']);
    if (fineType == 'PERCENTAGE') {
      return ((baseAmount * fineValue) / 100 * 100).round() / 100;
    }
    return (fineValue * 100).round() / 100;
  }

  @override
  Widget build(BuildContext context) {
    // Watch subscription provider as fallback when API payload omits methods
    ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: TuLojitaBrandColors.canvas,
      appBar: AppBar(
        backgroundColor: TuLojitaBrandColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Deudas con la Plataforma',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: TuLojitaBrandColors.indigo600,
              size: 20,
            ),
            onPressed: _loadDebtData,
          ),
        ],
      ),
      body: _isLoading
          ? const _StoreDebtsShimmerSkeleton()
          : (_errorMessage != null || _debtData == null)
              ? _ErrorStateCard(
                  message: _errorMessage ?? 'Error desconocido',
                  onRetry: _loadDebtData,
                )
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final store = Map<String, dynamic>.from(_debtData!['store'] as Map);
    final billing = _debtData!['currentBilling'] != null
        ? Map<String, dynamic>.from(_debtData!['currentBilling'] as Map)
        : null;
    final settings = _debtData!['settings'] != null
        ? Map<String, dynamic>.from(_debtData!['settings'] as Map)
        : null;
    final suspensionInfo = _debtData!['suspensionInfo'] != null
        ? Map<String, dynamic>.from(_debtData!['suspensionInfo'] as Map)
        : null;

    final recentOrders = (_debtData!['recentOrders'] as List?) ?? [];
    final paymentReports = (_debtData!['paymentReports'] as List?) ?? [];
    final methods = _resolveMethods();

    final debt = _toDouble(store['accumulatedCommissionDebt']);
    final isSuspended = store['status'] == 'SUSPENDED';

    final billingCommission =
        billing != null ? _toDouble(billing['commissionAmount']) : debt;
    final billingFine = billing != null ? _toDouble(billing['fineAmount']) : 0.0;
    final billingPaid = billing != null ? _toDouble(billing['paidAmount']) : 0.0;

    final hasPendingReport = (suspensionInfo?['hasPendingReport'] == true) ||
        billing?['status'] == 'PAYMENT_REPORTED' ||
        paymentReports.any(
          (r) => r is Map && r['status'] == 'PENDING_REVIEW',
        );

    Map<String, dynamic>? rejectedReport;
    if (suspensionInfo?['latestRejectedReport'] is Map) {
      rejectedReport = Map<String, dynamic>.from(
        suspensionInfo!['latestRejectedReport'] as Map,
      );
    } else {
      final firstRejected = paymentReports.whereType<Map>().where(
            (r) => r['status'] == 'REJECTED',
          );
      if (firstRejected.isNotEmpty) {
        rejectedReport = Map<String, dynamic>.from(firstRejected.first);
      }
    }
    final showRejectedAlert =
        rejectedReport != null && !hasPendingReport && debt > 0;

    final deadlineRaw =
        billing?['gracePeriodEndDate'] ?? billing?['dueDate'];
    final deadline = deadlineRaw != null
        ? DateTime.tryParse(deadlineRaw.toString())
        : null;
    final daysRemaining = _daysRemaining(deadline);
    final gracePeriodDays = (settings?['gracePeriodDays'] as num?)?.toInt() ?? 3;
    final finePreview =
        (!isSuspended && billingFine == 0 && debt > 0)
            ? _computeFinePreview(debt, settings)
            : 0.0;

    return RefreshIndicator(
      onRefresh: _loadDebtData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ContextualStatusBanner(
              isSuspended: isSuspended,
              debt: debt,
              hasPendingReport: hasPendingReport,
              deadline: deadline,
              daysRemaining: daysRemaining,
              gracePeriodDays: gracePeriodDays,
              finePreview: finePreview,
            ),
            if (showRejectedAlert) ...[
              const SizedBox(height: 12),
              _RejectedReportBanner(
                rejectionReason:
                    rejectedReport['rejectionReason']?.toString() ??
                        'No se pudo validar tu comprobante.',
                amount: _toDouble(rejectedReport['amount']),
                onRetryReport: () => _showReportPaymentModal(),
              ),
            ],
            const SizedBox(height: 14),
            _DebtHeroAndBreakdownCard(
              debt: debt,
              isSuspended: isSuspended,
              hasPendingReport: hasPendingReport,
              commissionAmount:
                  billing != null ? billingCommission : debt,
              fineAmount: billingFine,
              paidAmount: billingPaid,
              hasOpenBilling: billing != null,
              onReportPayment: (debt > 0 && !hasPendingReport)
                  ? () => _showReportPaymentModal()
                  : null,
            ),
            const SizedBox(height: 20),
            const _SectionHeader(
              title: '¿Cómo y dónde pagar?',
              subtitle:
                  'Copia los datos de una cuenta oficial, paga el monto en Bolívares según la tasa del día y adjunta tu comprobante.',
            ),
            const SizedBox(height: 10),
            if (methods.isEmpty)
              _EmptyBentoBox(
                text:
                    'No hay cuentas receptoras configuradas en este momento. Intenta actualizar.',
              )
            else
              ...methods.map(
                (m) => PlatformPaymentMethodCard(
                  method: m,
                  isDarkOverride: false,
                  selectionLabel: 'Reportar con esta cuenta',
                  onSelectMethod: (debt > 0 && !hasPendingReport)
                      ? () => _showReportPaymentModal(preselectedMethod: m)
                      : null,
                ),
              ),
            const SizedBox(height: 20),
            const _SectionHeader(
              title: 'Historial de reportes de pago',
              subtitle: 'Seguimiento de verificación de tus comprobantes.',
            ),
            const SizedBox(height: 10),
            if (paymentReports.isEmpty)
              const _EmptyBentoBox(
                text: 'Aún no has enviado comprobantes de pago de comisiones.',
              )
            else
              ...paymentReports.whereType<Map>().map(
                    (rep) => _PaymentReportHistoryCard(
                      report: Map<String, dynamic>.from(rep),
                    ),
                  ),
            const SizedBox(height: 20),
            const _SectionHeader(
              title: 'Ventas recientes & comisión',
              subtitle: 'Órdenes pagadas o abonadas que generan comisión.',
            ),
            const SizedBox(height: 10),
            if (recentOrders.isEmpty)
              const _EmptyBentoBox(
                text: 'No hay ventas con comisiones registradas aún.',
              )
            else
              ...recentOrders.whereType<Map>().map(
                    (ord) => _CommissionOrderCard(
                      order: Map<String, dynamic>.from(ord),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: TuLojitaBrandColors.inkPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: TuLojitaBrandColors.inkSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmptyBentoBox extends StatelessWidget {
  final String text;

  const _EmptyBentoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TuLojitaBrandColors.borderSubtle),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            color: TuLojitaBrandColors.inkSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ContextualStatusBanner extends StatelessWidget {
  final bool isSuspended;
  final double debt;
  final bool hasPendingReport;
  final DateTime? deadline;
  final int? daysRemaining;
  final int gracePeriodDays;
  final double finePreview;

  const _ContextualStatusBanner({
    required this.isSuspended,
    required this.debt,
    required this.hasPendingReport,
    required this.deadline,
    required this.daysRemaining,
    required this.gracePeriodDays,
    required this.finePreview,
  });

  @override
  Widget build(BuildContext context) {
    if (isSuspended && hasPendingReport) {
      return _BannerCard(
        bgColor: TuLojitaBrandColors.indigo50,
        borderColor: TuLojitaBrandColors.indigo600.withValues(alpha: 0.35),
        icon: HugeIcons.strokeRoundedClock01,
        accentColor: TuLojitaBrandColors.indigo700,
        title: 'Pago en revisión · Tienda suspendida temporalmente',
        body:
            'Recibimos tu comprobante y lo estamos validando. Si cubre el total adeudado, tu tienda y productos se reactivarán automáticamente al aprobarse.',
      );
    }

    if (isSuspended) {
      return _BannerCard(
        bgColor: TuLojitaBrandColors.dangerBg,
        borderColor: const Color(0xFFFCA5A5),
        icon: HugeIcons.strokeRoundedAlert02,
        accentColor: TuLojitaBrandColors.danger,
        title: 'TIENDA SUSPENDIDA POR MORA',
        body:
            'Tu catálogo y productos están ocultos del público por facturas vencidas.\n1. Elige una cuenta oficial abajo y paga el monto en Bolívares según la tasa del día.\n2. Adjunta tu comprobante con el botón de pago.\n3. Al aprobarse el monto total, tu tienda se reactiva automáticamente.',
      );
    }

    if (hasPendingReport) {
      return _BannerCard(
        bgColor: TuLojitaBrandColors.indigo50,
        borderColor: TuLojitaBrandColors.indigo600.withValues(alpha: 0.35),
        icon: HugeIcons.strokeRoundedClock01,
        accentColor: TuLojitaBrandColors.indigo700,
        title: 'Comprobante de pago en revisión',
        body:
            'Ya recibimos tu reporte de pago y nuestro equipo lo está verificando. Tus recordatorios diarios están pausados mientras concluye la auditoría.',
      );
    }

    if (debt > 0) {
      final dateStr = deadline != null
          ? DateFormat('dd/MM/yyyy').format(deadline!.toLocal())
          : null;
      final String title;
      if (daysRemaining == null) {
        title = 'Período de gracia activo ($gracePeriodDays días)';
      } else if (daysRemaining == 0) {
        title = 'Último día para pagar comisiones';
      } else if (daysRemaining == 1) {
        title = 'Queda 1 día antes del vencimiento';
      } else {
        title = 'Quedan $daysRemaining días del período de gracia';
      }

      return _BannerCard(
        bgColor: TuLojitaBrandColors.amber50,
        borderColor: TuLojitaBrandColors.amber400,
        icon: HugeIcons.strokeRoundedClock01,
        accentColor: TuLojitaBrandColors.amber800,
        title: title,
        body:
            '${dateStr != null ? 'Fecha límite: $dateStr (11:59 PM). ' : ''}Reporta tu pago antes del vencimiento para evitar la suspensión de tu catálogo.',
        extra: finePreview > 0
            ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Multa por mora al vencer:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: TuLojitaBrandColors.amber800,
                      ),
                    ),
                    DualPriceText(
                      amountInUsd: finePreview,
                      isInline: true,
                      usdStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.amber800,
                      ),
                      bsStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TuLojitaBrandColors.amber700,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      );
    }

    return _BannerCard(
      bgColor: TuLojitaBrandColors.positiveBg,
      borderColor: const Color(0xFFA7F3D0),
      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
      accentColor: TuLojitaBrandColors.positive,
      title: 'Tu tienda está al día',
      body: 'No tienes saldos pendientes ni cortes vencidos con la plataforma.',
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Color bgColor;
  final Color borderColor;
  final dynamic icon;
  final Color accentColor;
  final String title;
  final String body;
  final Widget? extra;

  const _BannerCard({
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.body,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(icon: icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TuLojitaBrandColors.inkSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ?extra,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectedReportBanner extends StatelessWidget {
  final String rejectionReason;
  final double amount;
  final VoidCallback onRetryReport;

  const _RejectedReportBanner({
    required this.rejectionReason,
    required this.amount,
    required this.onRetryReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCancelCircle,
                color: TuLojitaBrandColors.danger,
                size: 18,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Último comprobante rechazado',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: TuLojitaBrandColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Motivo: $rejectionReason',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: TuLojitaBrandColors.inkPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: onRetryReport,
              style: OutlinedButton.styleFrom(
                foregroundColor: TuLojitaBrandColors.danger,
                side: const BorderSide(color: TuLojitaBrandColors.danger),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Enviar comprobante corregido',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtHeroAndBreakdownCard extends StatelessWidget {
  final double debt;
  final bool isSuspended;
  final bool hasPendingReport;
  final double commissionAmount;
  final double fineAmount;
  final double paidAmount;
  final bool hasOpenBilling;
  final VoidCallback? onReportPayment;

  const _DebtHeroAndBreakdownCard({
    required this.debt,
    required this.isSuspended,
    required this.hasPendingReport,
    required this.commissionAmount,
    required this.fineAmount,
    required this.paidAmount,
    required this.hasOpenBilling,
    required this.onReportPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: TuLojitaBrandColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total en comisiones por liquidar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: TuLojitaBrandColors.inkSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          DualPriceText(
            amountInUsd: debt,
            crossAxisAlignment: CrossAxisAlignment.center,
            usdStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: debt > 0
                  ? TuLojitaBrandColors.danger
                  : TuLojitaBrandColors.positive,
              letterSpacing: -1,
            ),
            bsStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: TuLojitaBrandColors.inkSecondary,
            ),
          ),
          if (hasOpenBilling || fineAmount > 0 || paidAmount > 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.canvas,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TuLojitaBrandColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _BreakdownRow(
                    label: 'Comisión acumulada',
                    amountUsd: commissionAmount,
                  ),
                  const SizedBox(height: 6),
                  _BreakdownRow(
                    label: 'Multa / mora',
                    amountUsd: fineAmount,
                    valueColor: fineAmount > 0
                        ? TuLojitaBrandColors.danger
                        : TuLojitaBrandColors.inkSecondary,
                  ),
                  if (paidAmount > 0) ...[
                    const SizedBox(height: 6),
                    _BreakdownRow(
                      label: 'Abonos aprobados',
                      amountUsd: paidAmount,
                      prefix: '- ',
                      valueColor: TuLojitaBrandColors.positive,
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      height: 1,
                      color: TuLojitaBrandColors.borderMuted,
                    ),
                  ),
                  _BreakdownRow(
                    label: 'Total a pagar',
                    amountUsd: debt,
                    isBold: true,
                    valueColor: debt > 0
                        ? TuLojitaBrandColors.inkPrimary
                        : TuLojitaBrandColors.positive,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onReportPayment,
              icon: HugeIcon(
                icon: hasPendingReport
                    ? HugeIcons.strokeRoundedClock01
                    : HugeIcons.strokeRoundedCheckmarkCircle02,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                hasPendingReport
                    ? 'Pago en revisión administrativa'
                    : isSuspended && debt > 0
                        ? 'Pagar y Reactivar Tienda'
                        : 'Reportar Pago de Comisiones',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuspended && !hasPendingReport && debt > 0
                    ? TuLojitaBrandColors.danger
                    : TuLojitaBrandColors.indigo600,
                disabledBackgroundColor: TuLojitaBrandColors.borderMuted,
                disabledForegroundColor: TuLojitaBrandColors.inkSecondary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amountUsd;
  final String? prefix;
  final bool isBold;
  final Color? valueColor;

  const _BreakdownRow({
    required this.label,
    required this.amountUsd,
    this.prefix,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold
                  ? TuLojitaBrandColors.inkPrimary
                  : TuLojitaBrandColors.inkSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: DualPriceText(
            amountInUsd: amountUsd,
            prefix: prefix,
            isInline: true,
            crossAxisAlignment: CrossAxisAlignment.end,
            usdStyle: TextStyle(
              fontSize: isBold ? 13.5 : 12.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ?? TuLojitaBrandColors.inkPrimary,
            ),
            bsStyle: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: TuLojitaBrandColors.inkSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

void _showReceiptPreviewDialog(
  BuildContext context, {
  File? file,
  String? imageUrl,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 520),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: file != null
                  ? Image.file(
                      file,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 220,
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedImage01,
                            color: TuLojitaBrandColors.inkSecondary,
                            size: 40,
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      imageUrl ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 220,
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedImage01,
                            color: TuLojitaBrandColors.inkSecondary,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              radius: 16,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PaymentReportHistoryCard extends StatelessWidget {
  final Map<String, dynamic> report;

  const _PaymentReportHistoryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final status = (report['status'] ?? 'PENDING_REVIEW').toString();
    final amount =
        double.tryParse(report['amount']?.toString() ?? '0') ?? 0.0;
    final ref = report['referenceNumber']?.toString() ?? '';
    final methodMap = report['paymentMethod'] as Map?;
    final methodTitle = methodMap?['title']?.toString() ?? 'Cuenta plataforma';
    final rejectionReason = report['rejectionReason']?.toString();
    final receiptUrl =
        resolveDashboardImageUrl(report['receiptImageUrl']?.toString());
    final createdAtRaw = report['createdAt']?.toString();
    final createdAt =
        createdAtRaw != null ? DateTime.tryParse(createdAtRaw)?.toLocal() : null;
    final dateText = createdAt != null
        ? DateFormat('dd/MM/yyyy · HH:mm').format(createdAt)
        : '';

    final String statusLabel;
    final Color statusBg;
    final Color statusColor;
    switch (status) {
      case 'APPROVED':
        statusLabel = 'Aprobado';
        statusBg = TuLojitaBrandColors.positiveBg;
        statusColor = TuLojitaBrandColors.positive;
        break;
      case 'REJECTED':
        statusLabel = 'Rechazado';
        statusBg = TuLojitaBrandColors.dangerBg;
        statusColor = TuLojitaBrandColors.danger;
        break;
      default:
        statusLabel = 'En revisión';
        statusBg = TuLojitaBrandColors.indigo50;
        statusColor = TuLojitaBrandColors.indigo700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TuLojitaBrandColors.borderSubtle, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DualPriceText(
                  amountInUsd: amount,
                  isInline: true,
                  usdStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                  bsStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$methodTitle${ref.isNotEmpty ? ' · Ref: $ref' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                    if (dateText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: TuLojitaBrandColors.inkSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (receiptUrl.isNotEmpty) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _showReceiptPreviewDialog(
                    context,
                    imageUrl: receiptUrl,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.canvas,
                        border: Border.all(
                          color: TuLojitaBrandColors.borderSubtle,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.network(
                        receiptUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedImage01,
                            color: TuLojitaBrandColors.inkSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (status == 'REJECTED' &&
              rejectionReason != null &&
              rejectionReason.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Motivo: $rejectionReason',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: TuLojitaBrandColors.danger,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommissionOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _CommissionOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = (order['id'] as String?)?.split('-')[0].toUpperCase() ?? '';
    final totalAmount =
        double.tryParse(order['totalAmount']?.toString() ?? '0') ?? 0.0;
    final rawFinalAmount =
        double.tryParse(order['finalAmount']?.toString() ?? '0') ?? 0.0;
    final comm =
        double.tryParse(order['platformCommissionAmount']?.toString() ?? '0') ??
            0.0;
    double rate =
        double.tryParse(order['platformCommissionRate']?.toString() ?? '0') ??
            0.0;
    if (comm > 0 &&
        totalAmount > comm &&
        (rate <= 0 || (rate - 4.76).abs() < 0.05)) {
      rate = double.parse(
        ((comm / (totalAmount - comm)) * 100).toStringAsFixed(2),
      );
    }
    final rateLabel = (rate - rate.roundToDouble()).abs() < 0.01
        ? '${rate.toStringAsFixed(1)}%'
        : '${rate.toStringAsFixed(2)}%';
    final isPartial = order['isPartialPayment'] == true;
    final status = (order['status'] as String?) ?? '';
    final isFullyPaid = status == 'FULLY_PAID';
    final statusLabel = isFullyPaid ? 'Pagada' : 'Abonada';
    final statusColor = isFullyPaid
        ? TuLojitaBrandColors.positive
        : TuLojitaBrandColors.indigo700;
    final statusBg = isFullyPaid
        ? TuLojitaBrandColors.positiveBg
        : TuLojitaBrandColors.indigo50;
    final amount =
        (totalAmount > 0 && !isPartial && rawFinalAmount > totalAmount + 0.009)
            ? totalAmount
            : rawFinalAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TuLojitaBrandColors.borderSubtle, width: 1.3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Orden #$orderId',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Venta:',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                    DualPriceText(
                      amountInUsd: amount,
                      isInline: true,
                      usdStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                      bsStyle: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                    Text(
                      '· ${isPartial ? 'Cuotas' : 'Contado'}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DualPriceText(
                amountInUsd: comm,
                prefix: '- ',
                crossAxisAlignment: CrossAxisAlignment.end,
                usdStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C3AED),
                ),
                bsStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
              Text(
                'Tasa: $rateLabel',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorStateCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TuLojitaBrandColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TuLojitaBrandColors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: TuLojitaBrandColors.danger,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TuLojitaBrandColors.indigo600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreDebtsShimmerSkeleton extends StatelessWidget {
  const _StoreDebtsShimmerSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: TuLojitaBrandColors.borderSubtle),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  width: 190,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                SizedBox(height: 8),
                ShimmerWidget(
                  width: double.infinity,
                  height: 12,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: TuLojitaBrandColors.borderSubtle),
            ),
            child: const Column(
              children: [
                ShimmerWidget(
                  width: 160,
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                SizedBox(height: 12),
                ShimmerWidget(
                  width: 130,
                  height: 32,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(height: 18),
                ShimmerWidget(
                  width: double.infinity,
                  height: 76,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                SizedBox(height: 16),
                ShimmerWidget(
                  width: double.infinity,
                  height: 46,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const ShimmerWidget(
            width: 170,
            height: 18,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: TuLojitaBrandColors.borderSubtle),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  width: 150,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                SizedBox(height: 10),
                ShimmerWidget(
                  width: double.infinity,
                  height: 13,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                SizedBox(height: 8),
                ShimmerWidget(
                  width: 210,
                  height: 13,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCommissionPaymentModal extends ConsumerStatefulWidget {
  final String storeId;
  final String billingId;
  final double debtAmount;
  final List<PlatformPaymentMethod> methods;
  final PlatformPaymentMethod? initialMethod;
  final Future<File?> Function(ImageSource source)? receiptPickerOverride;
  final VoidCallback onSuccess;

  const _ReportCommissionPaymentModal({
    required this.storeId,
    required this.billingId,
    required this.debtAmount,
    required this.methods,
    this.initialMethod,
    this.receiptPickerOverride,
    required this.onSuccess,
  });

  @override
  ConsumerState<_ReportCommissionPaymentModal> createState() =>
      _ReportCommissionPaymentModalState();
}

class _ReportCommissionPaymentModalState
    extends ConsumerState<_ReportCommissionPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();
  PlatformPaymentMethod? _selectedMethod;
  File? _receiptFile;
  bool _isSubmitting = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialMethod;
  }

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (widget.receiptPickerOverride != null) {
      final file = await widget.receiptPickerOverride!(source);
      if (file != null && mounted) {
        setState(() => _receiptFile = file);
      }
      return;
    }
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _receiptFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMethod == null) {
      NotificationService.showWarning(context, 'Selecciona el método de pago');
      return;
    }
    if (_receiptFile == null) {
      NotificationService.showWarning(
        context,
        'Adjunta el comprobante del pago',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final imageDataSource = ref.read(imageRemoteDataSourceProvider);
    String? uploadedReceiptUrl;
    try {
      uploadedReceiptUrl = await imageDataSource.uploadImage(_receiptFile!);

      final dio = ref.read(dioProvider);
      await dio.post(
        '/commissions/stores/${widget.storeId}/payment-reports',
        data: {
          'billingId': widget.billingId,
          'amount': widget.debtAmount,
          'paymentMethodId': _selectedMethod!.id,
          'referenceNumber': _refController.text.trim(),
          'receiptImageUrl': uploadedReceiptUrl,
        },
      );

      widget.onSuccess();
    } catch (_) {
      if (uploadedReceiptUrl != null && uploadedReceiptUrl.isNotEmpty) {
        await imageDataSource.deleteImage(uploadedReceiptUrl);
      }
      if (mounted) {
        NotificationService.showError(
          context,
          'Error al enviar reporte de pago',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reportar Pago de Comisiones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Monto a liquidar:',
                    style: TextStyle(
                      fontSize: 13,
                      color: TuLojitaBrandColors.inkSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  DualPriceText(
                    amountInUsd: widget.debtAmount,
                    isInline: true,
                    usdStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: TuLojitaBrandColors.indigo700,
                    ),
                    bsStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'El pago se realiza en Bolívares según la tasa vigente del día.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: TuLojitaBrandColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PlatformPaymentMethod>(
                isExpanded: true,
                initialValue:
                    widget.methods.any((m) => m.id == _selectedMethod?.id)
                        ? widget.methods
                            .firstWhere((m) => m.id == _selectedMethod?.id)
                        : null,
                decoration: InputDecoration(
                  labelText: 'Cuenta Destino',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: widget.methods.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m.title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedMethod = val),
                validator: (val) => val == null ? 'Selecciona método' : null,
              ),
              if (_selectedMethod?.qrImageUrl != null &&
                  _selectedMethod!.qrImageUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => PlatformQrDialog.show(
                      context,
                      qrImageUrl: _selectedMethod!.qrImageUrl!,
                      title: _selectedMethod!.title,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.indigo50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: TuLojitaBrandColors.indigo100,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedQrCode,
                            color: TuLojitaBrandColors.indigo600,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Ver Código QR de esta cuenta',
                            style: TextStyle(
                              color: TuLojitaBrandColors.indigo700,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _refController,
                decoration: InputDecoration(
                  labelText: 'Número de Referencia',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Comprobante de Pago (Captura):',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_receiptFile != null)
                Stack(
                  children: [
                    InkWell(
                      onTap: () => _showReceiptPreviewDialog(
                        context,
                        file: _receiptFile,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        height: 168,
                        decoration: BoxDecoration(
                          color: TuLojitaBrandColors.canvas,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: TuLojitaBrandColors.indigo100,
                            width: 1.4,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _receiptFile!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedImage01,
                                  color: TuLojitaBrandColors.inkSecondary,
                                  size: 32,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.zoom_in_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Toca para ampliar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton(
                        key: const Key('remove_receipt_btn'),
                        tooltip: 'Quitar imagen',
                        onPressed: () => setState(() => _receiptFile = null),
                        icon: const CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 14,
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCamera01,
                          color: TuLojitaBrandColors.indigo600,
                          size: 16,
                        ),
                        label: const Text('Cámara'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedImage01,
                          color: TuLojitaBrandColors.indigo600,
                          size: 16,
                        ),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TuLojitaBrandColors.indigo600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirmar y Enviar Comprobante',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
