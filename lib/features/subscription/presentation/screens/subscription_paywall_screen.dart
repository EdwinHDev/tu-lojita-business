import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../providers/subscription_provider.dart';
import '../../domain/entities/platform_payment_method.dart';

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

    final success = await ref
        .read(subscriptionProvider.notifier)
        .reportSubscriptionPayment(
          amount: 20.0,
          paymentMethodId: _selectedMethod!.id,
          referenceNumber: _refController.text.trim(),
          receiptFile: _receiptFile!,
        );

    if (success && mounted) {
      context.go('/subscription/pending');
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    NotificationService.showSuccess(context, '$label copiado al portapapeles');
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '\$20.00',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'USD / mes',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                      (m) => _buildPaymentMethodCard(m, isDark),
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
                            initialValue: _selectedMethod,
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

  Widget _buildPaymentMethodCard(PlatformPaymentMethod m, bool isDark) {
    final d = m.accountDetails;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m.type,
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (d['bankName'] != null)
            _buildCopyField('Banco:', d['bankName'].toString()),
          if (d['phoneNumber'] != null)
            _buildCopyField('Teléfono:', d['phoneNumber'].toString()),
          if (d['idNumber'] != null)
            _buildCopyField('C.I. / RIF:', d['idNumber'].toString()),
          if (d['accountNumber'] != null)
            _buildCopyField('Nº Cuenta:', d['accountNumber'].toString()),
          if (d['binancePayId'] != null)
            _buildCopyField('Binance Pay ID:', d['binancePayId'].toString()),
          if (d['email'] != null)
            _buildCopyField('Correo:', d['email'].toString()),
        ],
      ),
    );
  }

  Widget _buildCopyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label ',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          InkWell(
            onTap: () => _copyToClipboard(value, label.replaceAll(':', '')),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCopy01,
                color: Colors.indigo,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
