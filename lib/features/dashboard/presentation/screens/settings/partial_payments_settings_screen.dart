import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../providers/store_settings_notifier.dart';
import '../../providers/store_settings_state.dart';
import '../../../domain/entities/store.dart';

class PartialPaymentsSettingsScreen extends ConsumerStatefulWidget {
  final String storeId;
  const PartialPaymentsSettingsScreen({super.key, required this.storeId});

  @override
  ConsumerState<PartialPaymentsSettingsScreen> createState() => _PartialPaymentsSettingsScreenState();
}

class _PartialPaymentsSettingsScreenState extends ConsumerState<PartialPaymentsSettingsScreen> {
  final TextEditingController _creditLimitController = TextEditingController();
  bool _isCreditLimitControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(storeSettingsProvider).store == null) {
        ref.read(storeSettingsProvider.notifier).loadStore(widget.storeId);
      }
    });
  }

  @override
  void dispose() {
    _creditLimitController.dispose();
    super.dispose();
  }

  bool _areFrequenciesEqual(
    List<StoreInstallmentFrequency> a,
    List<StoreInstallmentFrequency>? b,
  ) {
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.any((e) => e.value == item.value && e.unit == item.unit)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);

    final store = state.store;

    if (store != null && !_isCreditLimitControllerInitialized) {
      final initialVal = state.maxCreditLimit;
      _creditLimitController.text = initialVal != null ? initialVal.toStringAsFixed(0) : '';
      _isCreditLimitControllerInitialized = true;
    }

    final hasChanges = store == null ||
        state.allowPartialPayments != store.allowPartialPayments ||
        state.feePercentage != store.partialPaymentsFeePercentage ||
        state.minInitialPercentage != store.minInitialPaymentPercentage ||
        state.maxInstallments != store.maxInstallments ||
        state.allowInstallmentExtensions != store.allowInstallmentExtensions ||
        state.maxExtensionDays != store.maxExtensionDays ||
        state.maxCreditLimit != store.maxCreditLimit ||
        !_areFrequenciesEqual(state.installmentFrequencyOptions, store.installmentFrequencyOptions);

    ref.listen(storeSettingsProvider.select((s) => s.successMessage), (prev, next) {
      if (next != null && next.isNotEmpty) {
        NotificationService.showSuccess(context, next);
      }
    });

    ref.listen(storeSettingsProvider.select((s) => s.error), (prev, next) {
      if (next != null && next.isNotEmpty) {
        NotificationService.showError(context, next);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF111827),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pagos Parciales',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildToggle(state),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildCostCard(state),
                            const SizedBox(height: 24),
                            _buildTermsCard(state),
                            const SizedBox(height: 24),
                            _buildExtensionsCard(state),
                            const SizedBox(height: 24),
                            _buildCreditLimitCard(state),
                          ],
                        ),
                        crossFadeState: state.allowPartialPayments
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                        firstCurve: Curves.easeInOut,
                        secondCurve: Curves.easeInOut,
                        sizeCurve: Curves.easeInOut,
                      ),
                      const SizedBox(height: 40),
                      _buildSaveButton(state, hasChanges),
                    ],
                  ),
                ),
                if (state.isSaving)
                  Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildToggle(StoreSettingsState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4F46E5).withValues(alpha: 0.05),
            const Color(0xFF6366F1).withValues(alpha: 0.02)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCreditCard,
              color: const Color(0xFF4F46E5),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permitir pagos parciales',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Permite a tus clientes pagar en cuotas flexibles. Los costos de recargo e inicial se aplicarán según lo configurado.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: state.allowPartialPayments,
            activeTrackColor: const Color(0xFF4F46E5),
            activeThumbColor: Colors.white,
            onChanged: (val) => ref.read(storeSettingsProvider.notifier).updatePartialPayments(val),
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard(StoreSettingsState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedPercent,
                color: const Color(0xFF4F46E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Costos y Condiciones',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "Porcentaje de recargo",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151), fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${state.feePercentage.toStringAsFixed(1)}%",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4F46E5),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF4F46E5),
              overlayColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              valueIndicatorColor: const Color(0xFF4F46E5),
              valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            child: Slider(
              value: state.feePercentage.clamp(0.0, 50.0),
              min: 0.0,
              max: 50.0,
              divisions: 100,
              label: "${state.feePercentage.toStringAsFixed(1)}%",
              onChanged: (val) {
                ref.read(storeSettingsProvider.notifier).updateFeePercentage(double.parse(val.toStringAsFixed(1)));
              },
            ),
          ),
          Text(
            "Costo adicional cobrado sobre el total de la compra por el servicio de cuotas.",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "Pago inicial mínimo",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151), fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${state.minInitialPercentage.toStringAsFixed(0)}%",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4F46E5),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF4F46E5),
              overlayColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              valueIndicatorColor: const Color(0xFF4F46E5),
              valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            child: Slider(
              value: state.minInitialPercentage.clamp(0.0, 100.0),
              min: 0.0,
              max: 100.0,
              divisions: 20,
              label: "${state.minInitialPercentage.toStringAsFixed(0)}%",
              onChanged: (val) {
                ref.read(storeSettingsProvider.notifier).updateMinInitialPercentage(val.roundToDouble());
              },
            ),
          ),
          Text(
            "Monto mínimo que el cliente debe pagar al iniciar la orden.",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard(StoreSettingsState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar03,
                color: const Color(0xFF4F46E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Plazos y Frecuencias',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "Número máximo de cuotas",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151), fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  if (state.maxInstallments != (state.store?.maxInstallments ?? 0)) ...[
                    IconButton(
                      onPressed: () {
                        ref.read(storeSettingsProvider.notifier).updateMaxInstallments(state.store?.maxInstallments ?? 12);
                      },
                      icon: const Icon(
                        Icons.restore,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                      tooltip: 'Restablecer original',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ],
                  IconButton(
                    onPressed: state.maxInstallments <= 2 ? null : () {
                      ref.read(storeSettingsProvider.notifier).updateMaxInstallments(state.maxInstallments - 1);
                    },
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: state.maxInstallments <= 2 ? Colors.grey.shade400 : const Color(0xFF4F46E5),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      "${state.maxInstallments}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827)),
                    ),
                  ),
                  IconButton(
                    onPressed: state.maxInstallments >= 12 ? null : () {
                      ref.read(storeSettingsProvider.notifier).updateMaxInstallments(state.maxInstallments + 1);
                    },
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: state.maxInstallments >= 12 ? Colors.grey.shade400 : const Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32, thickness: 1, color: Color(0xFFE5E7EB)),
          _buildFrequencySelector(state),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector(StoreSettingsState state) {
    final availableOptions = [
      {'label': 'Diario', 'value': 1, 'unit': 'DAYS', 'icon': HugeIcons.strokeRoundedCalendar01},
      {'label': 'Semanal', 'value': 7, 'unit': 'DAYS', 'icon': HugeIcons.strokeRoundedCalendar02},
      {'label': 'Quincenal', 'value': 15, 'unit': 'DAYS', 'icon': HugeIcons.strokeRoundedCalendar03},
      {'label': 'Mensual', 'value': 1, 'unit': 'MONTHS', 'icon': HugeIcons.strokeRoundedCalendar04},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frecuencias de cuotas permitidas',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151)),
        ),
        const SizedBox(height: 12),
        ...availableOptions.map((opt) {
          final isSelected = state.installmentFrequencyOptions.any((e) =>
              e.value == opt['value'] && e.unit == opt['unit']);
          final icon = opt['icon'] as dynamic;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4F46E5).withValues(alpha: 0.02) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: InkWell(
              onTap: () {
                ref.read(storeSettingsProvider.notifier).toggleFrequencyOption(
                      opt['value'] as int,
                      opt['unit'] as String,
                      opt['label'] as String,
                    );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: HugeIcon(
                        icon: icon,
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['label'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getFrequencyDescription(
                                opt['value'] as int, opt['unit'] as String),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 12)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _getFrequencyDescription(int value, String unit) {
    if (unit == 'DAYS') {
      if (value == 1) return 'Los clientes deberán realizar pagos cada día.';
      if (value == 7) return 'Los clientes deberán realizar pagos cada semana.';
      if (value == 15) return 'Los clientes deberán realizar pagos cada 15 días.';
      return 'Los clientes deberán realizar pagos cada $value días.';
    }
    if (unit == 'MONTHS') {
      if (value == 1) return 'Los clientes deberán realizar pagos cada mes.';
      return 'Los clientes deberán realizar pagos cada $value meses.';
    }
    return '';
  }

  Widget _buildSaveButton(StoreSettingsState state, bool hasChanges) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (state.isSaving || !hasChanges)
            ? null
            : () async {
                final navigator = Navigator.of(context);
                final success = await ref.read(storeSettingsProvider.notifier).saveSettings(
                      widget.storeId,
                      specificData: {
                        'allowPartialPayments': state.allowPartialPayments,
                        'partialPaymentsFeePercentage': state.feePercentage,
                        'minInitialPaymentPercentage': state.minInitialPercentage,
                        'maxInstallments': state.maxInstallments,
                        'installmentIntervalValue': state.installmentIntervalValue,
                        'installmentIntervalUnit': state.installmentIntervalUnit,
                        'installmentFrequencyOptions': state.installmentFrequencyOptions.map((e) => e.toJson()).toList(),
                        'allowInstallmentExtensions': state.allowInstallmentExtensions,
                        'maxExtensionDays': state.maxExtensionDays,
                        'maxCreditLimit': state.maxCreditLimit,
                      },
                    );
                if (success && mounted) {
                  navigator.pop();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          disabledForegroundColor: const Color(0xFF9CA3AF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: state.isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Guardar Cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildExtensionsCard(StoreSettingsState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar03,
                color: const Color(0xFF4F46E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Políticas de Prórrogas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Permitir prórrogas",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Clientes podrán solicitar días adicionales para pagar cuotas.",
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: state.allowInstallmentExtensions,
                activeTrackColor: const Color(0xFF4F46E5),
                activeThumbColor: Colors.white,
                onChanged: (val) => ref.read(storeSettingsProvider.notifier).updateAllowInstallmentExtensions(val),
              ),
            ],
          ),
          if (state.allowInstallmentExtensions) ...[
            const Divider(height: 32, thickness: 1, color: Color(0xFFE5E7EB)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Días máximos de prórroga",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151), fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${state.maxExtensionDays} días",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF4F46E5),
                inactiveTrackColor: Colors.grey.shade200,
                thumbColor: const Color(0xFF4F46E5),
                overlayColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                valueIndicatorColor: const Color(0xFF4F46E5),
                valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              child: Slider(
                value: state.maxExtensionDays.toDouble().clamp(1, 30),
                min: 1,
                max: 30,
                divisions: 29,
                label: "${state.maxExtensionDays} días",
                onChanged: (val) {
                  ref.read(storeSettingsProvider.notifier).updateMaxExtensionDays(val.round());
                },
              ),
            ),
            Text(
              "Límite máximo de días que un cliente puede solicitar por cuota.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditLimitCard(StoreSettingsState state) {
    final hasLimit = state.maxCreditLimit != null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCreditCard,
                color: const Color(0xFF4F46E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Límite de Crédito por Cliente',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Limitar saldo adeudado",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Establece una deuda total acumulada máxima por cliente.",
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: hasLimit,
                activeTrackColor: const Color(0xFF4F46E5),
                activeThumbColor: Colors.white,
                onChanged: (val) {
                  if (val) {
                    ref.read(storeSettingsProvider.notifier).updateMaxCreditLimit(500.0);
                    _creditLimitController.text = '500';
                  } else {
                    ref.read(storeSettingsProvider.notifier).updateMaxCreditLimit(null);
                    _creditLimitController.clear();
                  }
                },
              ),
            ],
          ),
          if (hasLimit) ...[
            const Divider(height: 32, thickness: 1, color: Color(0xFFE5E7EB)),
            const Text(
              "Monto del límite de crédito (USD)",
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151), fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _creditLimitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827)),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF4F46E5)),
                hintText: "0.00",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                ),
              ),
              onChanged: (val) {
                final doubleValue = double.tryParse(val);
                ref.read(storeSettingsProvider.notifier).updateMaxCreditLimit(doubleValue);
              },
            ),
            const SizedBox(height: 8),
            Text(
              "Si el total de la deuda activa de un cliente más la nueva compra excede este valor, el checkout a cuotas será rechazado automáticamente.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

