import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/variant_management_section.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/wizard/wizard_contextual_help.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';

class StepPricingAndVariants extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;

  const StepPricingAndVariants({
    super.key,
    required this.formKey,
  });

  @override
  ConsumerState<StepPricingAndVariants> createState() =>
      _StepPricingAndVariantsState();
}

class _StepPricingAndVariantsState extends ConsumerState<StepPricingAndVariants>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _priceTypeDescription(PriceType priceType) {
    switch (priceType) {
      case PriceType.fixed:
        return 'El cliente verá el precio exacto listo para compra inmediata.';
      case PriceType.startingAt:
        return 'Ideal cuando el precio varía según tamaño, alcance o variante ("Desde \$X").';
      case PriceType.negotiable:
        return 'Muestra un precio referencial e indica que acepta acuerdos.';
      case PriceType.onDemand:
        return 'Para cotizaciones personalizadas según requerimiento.';
      case PriceType.free:
        return 'Publicación sin costo (\$0.00) o cortesía promocional.';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(itemFormProvider);
    final notifier = ref.read(itemFormProvider.notifier);
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canChangePrice = user?.canChangePrices ?? true;
    final canManageStock = user?.canManageStock ?? true;

    final hasValidOffer = state.discountPrice != null &&
        state.discountPrice! > 0 &&
        state.discountPrice! < state.price &&
        state.price > 0;
    final discountSavingsPercent = hasValidOffer
        ? (((state.price - state.discountPrice!) / state.price) * 100).round()
        : 0;

    return SingleChildScrollView(
      key: const PageStorageKey('step_pricing_and_variants_scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Precios
            const WizardSectionHeader(
              title: 'Precios y Ofertas',
              subtitle:
                  'Define cuánto deseas recibir neto; el sistema calcula el precio al público y su referencia BCV.',
              helpButton: WizardContextualHelpButton(
                title: 'Esquemas de Precio y Tu Ganancia',
                explanation:
                    'Tú ingresas el monto neto en USD que deseas recibir ("Tu Ganancia / Precio Base"). Tu Lojita incorpora automáticamente la comisión de servicio en el precio final que ve el cliente y muestra su equivalente en Bolívares a tasa BCV.',
                bulletPoints: [
                  'Precio Fijo: Monto único cerrado.',
                  'Precio "Desde": Se activa automáticamente si tus variantes tienen distintos precios.',
                  'Precio Oferta: Si es menor al base, el cliente verá el precio anterior tachado y una insignia de descuento (-X%).',
                ],
                example:
                    'Si colocas \$20.00 de base y \$15.00 de oferta, el comprador verá un ahorro del -25% y tu ganancia se calculará sobre \$15.00.',
              ),
            ),
            const SizedBox(height: 12),
            if (!canChangePrice)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: Color(0xFFB45309)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modo Inventario: Los precios están bloqueados por permisos de tu rol.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (state.hasVaryingVariantPrices)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFB45309), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Variantes con diferentes precios detectadas. El producto se establece obligatoriamente en "A partir de" usando el precio menor como referencia.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildCard([
              // Price Type Dropdown
              DropdownButtonFormField<PriceType>(
                key: ValueKey(
                  'priceType_${state.itemId ?? "new"}_${state.priceType.name}',
                ),
                initialValue: state.priceType,
                isExpanded: true,
                decoration: _inputDecoration('Tipo de precio'),
                items: [
                  DropdownMenuItem(
                    value: PriceType.fixed,
                    enabled: !state.hasVaryingVariantPrices,
                    child: _dropdownItem(
                      HugeIcons.strokeRoundedCircleLock01,
                      'Precio Fijo',
                      isEnabled: !state.hasVaryingVariantPrices,
                    ),
                  ),
                  DropdownMenuItem(
                    value: PriceType.startingAt,
                    child: _dropdownItem(
                      HugeIcons.strokeRoundedCursorMagicSelection01,
                      'Precio "Desde"',
                    ),
                  ),
                  DropdownMenuItem(
                    value: PriceType.negotiable,
                    child: _dropdownItem(
                      HugeIcons.strokeRoundedChat01,
                      'Negociable',
                    ),
                  ),
                  DropdownMenuItem(
                    value: PriceType.onDemand,
                    child: _dropdownItem(
                      HugeIcons.strokeRoundedCustomerService,
                      'Bajo Pedido',
                    ),
                  ),
                  DropdownMenuItem(
                    value: PriceType.free,
                    child: _dropdownItem(
                      HugeIcons.strokeRoundedStar,
                      'Gratis',
                    ),
                  ),
                ],
                onChanged: canChangePrice && !state.hasVaryingVariantPrices
                    ? (v) => notifier.onPriceTypeChanged(v!)
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                _priceTypeDescription(state.priceType),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),

              // Base Price & Discount Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: ValueKey('price_${state.itemId ?? "new"}'),
                          selectAllOnFocus: false,
                          initialValue:
                              state.price == 0 ? '' : state.price.toString(),
                          enabled: canChangePrice,
                          decoration: _inputDecoration(
                            'Precio Base',
                            hint: '0.00',
                            prefix: const Text(
                              '\$ ',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(fontSize: 15),
                          onChanged: (v) =>
                              notifier.onPriceChanged(double.tryParse(v) ?? 0),
                          validator: (v) {
                            if (state.priceType == PriceType.free) return null;
                            if (v == null || v.trim().isEmpty) {
                              return 'Requerido';
                            }
                            final num = double.tryParse(v);
                            if (num == null || num < 0) return 'Inválido';
                            return null;
                          },
                        ),
                        WizardLiveBcvHelper(
                          key: const Key('wizard_base_price_bcv_helper'),
                          amountInUsd: state.price,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: ValueKey(
                            'discountPrice_${state.itemId ?? "new"}',
                          ),
                          selectAllOnFocus: false,
                          initialValue: state.discountPrice?.toString() ?? '',
                          enabled: canChangePrice,
                          decoration: _inputDecoration(
                            'Precio Oferta',
                            hint: 'Opcional',
                            prefix: const Text(
                              '\$ ',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(fontSize: 15),
                          onChanged: (v) => notifier.onDiscountPriceChanged(
                            double.tryParse(v),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final num = double.tryParse(v);
                            if (num == null) return 'Inválido';
                            if (num >= state.price && state.price > 0) {
                              return 'Debe ser menor al base';
                            }
                            return null;
                          },
                        ),
                        WizardLiveBcvHelper(
                          key: const Key('wizard_discount_price_bcv_helper'),
                          amountInUsd: state.discountPrice,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (hasValidOffer && discountSavingsPercent > 0) ...[
                const SizedBox(height: 10),
                Container(
                  key: const Key('wizard_discount_savings_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.positiveBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: TuLojitaBrandColors.positive.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_offer_rounded,
                        size: 15,
                        color: TuLojitaBrandColors.positive,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Oferta activa: -$discountSavingsPercent% de ahorro visible para el comprador',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: TuLojitaBrandColors.positive,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Calculadora de comisiones y precios finales al cliente
              if (state.effectivePrice > 0) ...[
                const SizedBox(height: 16),
                Container(
                  key: const Key('wizard_commission_breakdown_card'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCalculator,
                            color: Color(0xFF4F46E5),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Desglose de Ganancia y Precio al Cliente',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          WizardContextualHelpButton(
                            title: '¿Cómo se calcula el Precio al Cliente?',
                            explanation:
                                'Tu ganancia neta está protegida: recibes exactamente el precio base (u oferta) que configuraste. El porcentaje de comisión de plataforma se suma de forma transparente al precio de vitrina que ve el comprador.',
                            bulletPoints: [
                              'Tu ganancia neta: Lo que recibe tu tienda por cada venta.',
                              'Precio al Contado: Precio público en un solo pago.',
                              'Precio en Cuotas: Precio público cuando el cliente financia en cuotas.',
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Tu ganancia neta:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DualPriceText(
                            amountInUsd: state.effectivePrice,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            useScaleDown: false,
                            usdStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            bsStyle: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 16,
                        thickness: 0.8,
                        color: Color(0xFFE2E8F0),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Precio al Contado (+${state.singleCommissionRate.toStringAsFixed(1)}% com.):',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DualPriceText(
                            amountInUsd: state.customerSingleFinalPrice,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            useScaleDown: false,
                            usdStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5),
                            ),
                            bsStyle: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Precio en Cuotas (+${state.installmentCommissionRate.toStringAsFixed(1)}% com.):',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DualPriceText(
                            amountInUsd: state.customerInstallmentFinalPrice,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            useScaleDown: false,
                            usdStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                            bsStyle: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '* La comisión de la plataforma ya está incorporada en el precio al cliente. No se le mostrará ningún recargo de servicio de plataforma al pagar.',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]),

            const SizedBox(height: 24),

            // Variantes de Producto
            const VariantManagementSection(),

            const SizedBox(height: 24),

            // Inventario y Logística o Información de Disponibilidad para Servicios
            if (state.itemType == ItemType.service) ...[
              const WizardSectionHeader(
                title: 'Disponibilidad del Servicio',
                subtitle:
                    'Los servicios se gestionan por horarios y citas, no por stock de almacén.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: const Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      color: Color(0xFF7C3AED),
                      size: 26,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disponibilidad por Turnos y Capacidad',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B21B6),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Para este servicio no necesitas ingresar stock físico. En el siguiente paso podrás definir tus horarios de atención, aviso mínimo y cupos simultáneos.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const WizardSectionHeader(
                title: 'Inventario y Logística',
                subtitle:
                    'Control automático de existencias para evitar ventas sin stock.',
                helpButton: WizardContextualHelpButton(
                  title: 'Control Automático de Stock',
                  explanation:
                      'Al activar el control de stock, cada pedido confirmado descuenta automáticamente las unidades compradas.',
                  bulletPoints: [
                    'Si usas Variantes (tallas/colores), el stock se define en cada variante.',
                    'Cuando el stock llega a 0, el artículo se marca como "Agotado" hasta que repongas.',
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildCard([
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Controlar stock',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Descuenta unidades de forma automática en cada venta',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  value: state.trackInventory,
                  activeThumbColor: const Color(0xFF4F46E5),
                  onChanged: (v) => notifier.onTrackInventoryChanged(v),
                ),
                if (state.trackInventory) ...[
                  const Divider(height: 24),
                  if (state.hasVariants)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: const Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedInformationCircle,
                            color: Color(0xFF4F46E5),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'El stock se gestiona individualmente por cada combinación en la sección de Variantes.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3730A3),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    TextFormField(
                      key: ValueKey('stock_${state.itemId ?? "new"}'),
                      selectAllOnFocus: false,
                      initialValue: state.stockQuantity?.toString() ?? '',
                      enabled: canManageStock,
                      decoration: _inputDecoration(
                        'Cantidad disponible en stock',
                        hint: 'Ej. 50',
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 15),
                      onChanged: (v) => notifier.onStockQuantityChanged(
                        double.tryParse(v),
                      ),
                      validator: (v) {
                        if (!state.trackInventory || state.hasVariants) {
                          return null;
                        }
                        if (v == null || v.trim().isEmpty) {
                          return 'Indica el stock disponible';
                        }
                        final num = double.tryParse(v);
                        if (num == null || num < 0) return 'Cantidad inválida';
                        return null;
                      },
                    ),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix != null
          ? Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: prefix,
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      floatingLabelStyle: const TextStyle(color: Color(0xFF4F46E5)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _dropdownItem(dynamic iconData, String text, {bool isEnabled = true}) {
    return Row(
      children: [
        HugeIcon(
          icon: iconData,
          size: 20,
          color: isEnabled ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  isEnabled ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }
}
