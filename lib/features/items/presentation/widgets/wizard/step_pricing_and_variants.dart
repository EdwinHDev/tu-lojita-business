import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/variant_management_section.dart';
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(itemFormProvider);
    final notifier = ref.read(itemFormProvider.notifier);
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canChangePrice = user?.canChangePrices ?? true;
    final canManageStock = user?.canManageStock ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Precios
            _buildSectionHeader(
              title: 'Precios y Ofertas',
              subtitle: 'Establece el esquema de cobro y ofertas para tus clientes.',
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
                child: Row(
                  children: const [
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
            _buildCard([
              // Price Type Dropdown
              DropdownButtonFormField<PriceType>(
                key: ValueKey('priceType_${state.itemId ?? "new"}'),
                initialValue: state.priceType,
                decoration: _inputDecoration('Tipo de precio'),
                items: [
                  DropdownMenuItem(
                    value: PriceType.fixed,
                    child: _dropdownItem(HugeIcons.strokeRoundedCircleLock01, 'Precio Fijo'),
                  ),
                  DropdownMenuItem(
                    value: PriceType.startingAt,
                    child: _dropdownItem(HugeIcons.strokeRoundedCursorMagicSelection01, 'Precio "Desde"'),
                  ),
                  DropdownMenuItem(
                    value: PriceType.negotiable,
                    child: _dropdownItem(HugeIcons.strokeRoundedChat01, 'Negociable'),
                  ),
                  DropdownMenuItem(
                    value: PriceType.onDemand,
                    child: _dropdownItem(HugeIcons.strokeRoundedCustomerService, 'Bajo Pedido'),
                  ),
                  DropdownMenuItem(
                    value: PriceType.free,
                    child: _dropdownItem(HugeIcons.strokeRoundedStar, 'Gratis'),
                  ),
                ],
                onChanged: canChangePrice ? (v) => notifier.onPriceTypeChanged(v!) : null,
              ),
              const SizedBox(height: 16),

              // Base Price & Discount Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('price_${state.itemId ?? "new"}'),
                      selectAllOnFocus: false,
                      initialValue: state.price == 0 ? '' : state.price.toString(),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 15),
                      onChanged: (v) => notifier.onPriceChanged(double.tryParse(v) ?? 0),
                      validator: (v) {
                        if (state.priceType == PriceType.free) return null;
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final num = double.tryParse(v);
                        if (num == null || num < 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('discountPrice_${state.itemId ?? "new"}'),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 15),
                      onChanged: (v) => notifier.onDiscountPriceChanged(double.tryParse(v)),
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
                  ),
                ],
              ),

              // Calculadora de comisiones
              if (state.effectivePrice > 0) ...[
                const SizedBox(height: 16),
                Container(
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
                              'Calculadora de Precio al Cliente',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Contado (+${state.singleCommissionRate.toStringAsFixed(1)}% com.):',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${state.customerSingleFinalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'En Cuotas (+${state.installmentCommissionRate.toStringAsFixed(1)}% com.):',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${state.customerInstallmentFinalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '* La comisión de plataforma se añade a la factura del cliente y la tienda la transfiere en el corte semanal.',
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
              _buildSectionHeader(
                title: 'Disponibilidad del Servicio',
                subtitle: 'Los servicios se gestionan por horarios y citas, no por stock de almacén.',
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
                            style: TextStyle(fontSize: 12, color: Color(0xFF6D28D9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildSectionHeader(
                title: 'Inventario y Logística',
                subtitle: 'Control automático de existencias para evitar ventas sin stock.',
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
                    decoration: _inputDecoration('Cantidad disponible en stock', hint: 'Ej. 50'),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 15),
                    onChanged: (v) => notifier.onStockQuantityChanged(double.tryParse(v)),
                    validator: (v) {
                      if (!state.trackInventory || state.hasVariants) return null;
                      if (v == null || v.trim().isEmpty) return 'Indica el stock disponible';
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

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
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

  InputDecoration _inputDecoration(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix != null
          ? Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: prefix)
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      floatingLabelStyle: const TextStyle(color: Color(0xFF4F46E5)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _dropdownItem(dynamic iconData, String text) {
    return Row(
      children: [
        HugeIcon(icon: iconData, size: 20, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }
}
