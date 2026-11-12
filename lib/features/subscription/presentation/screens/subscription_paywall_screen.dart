import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import '../providers/subscription_provider.dart';
import '../../domain/entities/platform_payment_method.dart';
import '../../domain/entities/company_subscription.dart';
import '../widgets/platform_payment_method_card.dart';

class SubscriptionPaywallScreen extends ConsumerStatefulWidget {
  const SubscriptionPaywallScreen({super.key});

  @override
  ConsumerState<SubscriptionPaywallScreen> createState() =>
      _SubscriptionPaywallScreenState();
}

class _SubscriptionPaywallScreenState
    extends ConsumerState<SubscriptionPaywallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();
  PlatformPaymentMethod? _selectedMethod;
  File? _receiptFile;
  final _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(subscriptionProvider.notifier).loadSubscriptionAndMethods(),
    );
  }

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _receiptFile = File(picked.path);
      });
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMethod == null) {
      NotificationService.showWarning(context, 'Selecciona una cuenta receptora');
      return;
    }
    if (_receiptFile == null) {
      NotificationService.showWarning(context, 'Adjunta la foto o captura del comprobante');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ref
          .read(subscriptionProvider.notifier)
          .reportSubscriptionPayment(
            amount: 20.0,
            paymentMethodId: _selectedMethod!.id,
            referenceNumber: _refController.text.trim(),
            receiptFile: _receiptFile!,
          );

      if (!mounted) return;

      if (success) {
        context.go('/subscription/pending');
      } else {
        setState(() {
          _isSubmitting = false;
        });
        NotificationService.showError(
          context,
          'No se pudo registrar el pago. Por favor intenta de nuevo.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        NotificationService.showError(context, 'Error al enviar comprobante: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final sub = subState.subscription;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isProcessing = _isSubmitting ||
        subState.isReportingPayment ||
        (sub != null && sub.status == SubscriptionStatus.pendingVerification);

    if (isProcessing) {
      if (sub != null && sub.status == SubscriptionStatus.pendingVerification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/subscription/pending');
        });
      }

      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF818CF8).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Procesando comprobante...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Registrando transferencia y sincronizando tu estado de suscripción.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Membresía Empresarial'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              color: Colors.redAccent,
              size: 22,
            ),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: subState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Principal
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedCrown,
                          color: Colors.amber,
                          size: 44,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tu Lojita Empresa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Plan Único Empresarial',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const DualPriceText(
                            amountInUsd: 20.0,
                            suffix: ' USD / mes',
                            crossAxisAlignment: CrossAxisAlignment.center,
                            usdStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                            bsStyle: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Beneficios Clave
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Qué incluye tu suscripción?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildBenefitRow(
                          'Cubre toda tu empresa y todas tus tiendas sin costos extras.',
                        ),
                        _buildBenefitRow(
                          'Gestión ilimitada de productos, inventarios y variaciones.',
                        ),
                        _buildBenefitRow(
                          'Venta de contado y pagos en cuotas automáticos.',
                        ),
                        _buildBenefitRow(
                          'Chat directo en vivo con compradores de tus tiendas.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cuentas de la Plataforma
                  const Text(
                    'Cuentas para Transferir:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (subState.paymentMethods.isEmpty)
                    const Text('No hay cuentas configuradas actualmente.')
                  else
                    ...subState.paymentMethods.map(
                      (m) => PlatformPaymentMethodCard(
                        method: m,
                        isDarkOverride: isDark,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Formulario de Pago
                  Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Reportar Pago de Membresía',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Selector de Método
                          DropdownButtonFormField<PlatformPaymentMethod>(
                            initialValue: subState.paymentMethods.any((m) => m.id == _selectedMethod?.id)
                                ? subState.paymentMethods.firstWhere((m) => m.id == _selectedMethod?.id)
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Método Utilizado',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: subState.paymentMethods.map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text(m.title, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedMethod = val;
                              });
                            },
                            validator: (val) => val == null
                                ? 'Selecciona el método de pago'
                                : null,
                          ),

                          const SizedBox(height: 14),

                          // Número de referencia
                          TextFormField(
                            controller: _refController,
                            decoration: InputDecoration(
                              labelText: 'Número de Referencia',
                              hintText: 'Ej: 04829104',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Ingresa el número de referencia'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // Selector de Comprobante
                          const Text(
                            'Comprobante de Pago (Captura):',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_receiptFile != null)
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _receiptFile!,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => _receiptFile = null),
                                  icon: const CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 14,
                                    child: Icon(Icons.close,
                                        size: 16, color: Colors.white),
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
                                      color: Colors.indigo,
                                      size: 18,
                                    ),
                                    label: const Text('Cámara'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedImage01,
                                      color: Colors.indigo,
                                      size: 18,
                                    ),
                                    label: const Text('Galería'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 24),

                          // Botón Enviar
                          ElevatedButton(
                            onPressed: subState.isReportingPayment
                                ? null
                                : _submitPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: subState.isReportingPayment
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Enviar Comprobante (\$20.00 USD)',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
