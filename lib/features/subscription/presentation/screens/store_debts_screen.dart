import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../providers/subscription_provider.dart';
import '../../domain/entities/platform_payment_method.dart';

class StoreDebtsScreen extends ConsumerStatefulWidget {
  final String storeId;

  const StoreDebtsScreen({super.key, required this.storeId});

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
      final res = await dio.get('/commissions/stores/${widget.storeId}/debt-hub');
      setState(() {
        _debtData = res.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al consultar deudas de la tienda';
        _isLoading = false;
      });
    }
  }

  void _showReportPaymentModal() {
    final subState = ref.read(subscriptionProvider);
    final billing = _debtData?['currentBilling'];
    final billingId = billing?['id'];
    final currentDebt = double.tryParse(
            _debtData?['store']?['accumulatedCommissionDebt']?.toString() ?? '0') ??
        0.0;

    if (billingId == null && currentDebt <= 0) {
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
        billingId: billingId ?? '',
        debtAmount: currentDebt,
        methods: subState.paymentMethods,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deudas con la Plataforma')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _debtData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deudas con la Plataforma')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Error desconocido'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadDebtData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final store = _debtData!['store'];
    final debt = double.tryParse(store['accumulatedCommissionDebt']?.toString() ?? '0') ?? 0.0;
    final isSuspended = store['status'] == 'SUSPENDED';
    final recentOrders = (_debtData!['recentOrders'] as List?) ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Deudas de Comisiones'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: Colors.indigo,
              size: 20,
            ),
            onPressed: _loadDebtData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDebtData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner de Alerta por Suspensión o Período de Gracia (Task 3.6)
              if (isSuspended)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAlert02,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TIENDA SUSPENDIDA POR MORA',
                              style: TextStyle(
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tus productos están ocultos del catálogo. Realiza el pago para reactivar tu tienda de inmediato.',
                              style: TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (debt > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedClock01,
                        color: Colors.amber,
                        size: 26,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Período de Gracia Activo',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Corte semanal: Lunes. Tienes hasta el Miércoles a las 11:59 PM para reportar tu pago antes de la aplicación de multas.',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Tarjeta de Deuda Principal
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total en Comisiones por Liquidar',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${debt.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: debt > 0 ? Colors.redAccent : const Color(0xFF10B981),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Dólares Americanos (USD)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: debt > 0 ? _showReportPaymentModal : null,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Reportar Pago de Comisiones',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Auditoría de Ventas con Comisión
              const Text(
                'Ventas Recientes & Comisión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),

              if (recentOrders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'No hay ventas con comisiones registradas aún.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                )
              else
                ...recentOrders.map((ord) {
                  final orderId = (ord['id'] as String?)?.split('-')[0].toUpperCase() ?? '';
                  final amount = double.tryParse(ord['finalAmount']?.toString() ?? '0') ?? 0.0;
                  final comm = double.tryParse(ord['platformCommissionAmount']?.toString() ?? '0') ?? 0.0;
                  final rate = double.tryParse(ord['platformCommissionRate']?.toString() ?? '0') ?? 0.0;
                  final isPartial = ord['isPartialPayment'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Orden #$orderId',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Venta: \$${amount.toStringAsFixed(2)} • ${isPartial ? "En Cuotas" : "Contado"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '-\$${comm.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            Text(
                              'Tasa: ${rate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCommissionPaymentModal extends ConsumerStatefulWidget {
  final String storeId;
  final String billingId;
  final double debtAmount;
  final List<PlatformPaymentMethod> methods;
  final VoidCallback onSuccess;

  const _ReportCommissionPaymentModal({
    required this.storeId,
    required this.billingId,
    required this.debtAmount,
    required this.methods,
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

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
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
      NotificationService.showWarning(context, 'Adjunta el comprobante del pago');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final imageDataSource = ref.read(imageRemoteDataSourceProvider);
      final receiptUrl = await imageDataSource.uploadImage(_receiptFile!);

      final dio = ref.read(dioProvider);
      await dio.post(
        '/commissions/stores/${widget.storeId}/payment-reports',
        data: {
          'billingId': widget.billingId,
          'amount': widget.debtAmount,
          'paymentMethodId': _selectedMethod!.id,
          'referenceNumber': _refController.text.trim(),
          'receiptImageUrl': receiptUrl,
        },
      );

      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Error al enviar reporte de pago');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Monto a liquidar: \$${widget.debtAmount.toStringAsFixed(2)} USD',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<PlatformPaymentMethod>(
                initialValue: _selectedMethod,
                decoration: InputDecoration(
                  labelText: 'Cuenta Destino',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

              const SizedBox(height: 12),

              TextFormField(
                controller: _refController,
                decoration: InputDecoration(
                  labelText: 'Número de Referencia',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCamera01,
                        color: Colors.indigo,
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
                        color: Colors.indigo,
                        size: 16,
                      ),
                      label: const Text('Galería'),
                    ),
                  ),
                ],
              ),

              if (_receiptFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '✓ Comprobante seleccionado: ${_receiptFile!.path.split('/').last}',
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmar y Enviar Comprobante', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
