import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/domain/entities/property_template.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';

class StepCustomizationsAndRules extends ConsumerStatefulWidget {
  final String storeId;
  final GlobalKey<FormState> formKey;

  const StepCustomizationsAndRules({
    super.key,
    required this.storeId,
    required this.formKey,
  });

  @override
  ConsumerState<StepCustomizationsAndRules> createState() =>
      _StepCustomizationsAndRulesState();
}

class _StepCustomizationsAndRulesState
    extends ConsumerState<StepCustomizationsAndRules>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _attrKeyController = TextEditingController();
  final _attrValueController = TextEditingController();
  bool _showManualProperties = false;

  @override
  void dispose() {
    _attrKeyController.dispose();
    _attrValueController.dispose();
    super.dispose();
  }

  void _addAttribute() {
    if (_attrKeyController.text.trim().isEmpty ||
        _attrValueController.text.trim().isEmpty) {
      return;
    }
    ref.read(itemFormProvider.notifier).addAttribute(
          _attrKeyController.text.trim(),
          _attrValueController.text.trim(),
        );
    _attrKeyController.clear();
    _attrValueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(itemFormProvider);
    final notifier = ref.read(itemFormProvider.notifier);
    final storeState = ref.watch(storeDetailsProvider).forStore(widget.storeId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Personalización y Extras
            _buildSectionHeader(
              title: 'Opciones de Personalización y Extras',
              subtitle: 'Permite a los clientes elegir aderezos, ingredientes, empaques o complementos.',
            ),
            const SizedBox(height: 12),
            _buildCustomizationsCard(state, notifier),

            const SizedBox(height: 24),

            // 2. Propiedades de Categoría y Ficha Técnica
            _buildSectionHeader(
              title: 'Propiedades y Ficha Técnica',
              subtitle: 'Atributos específicos como marca, material, garantía o características técnicas.',
            ),
            const SizedBox(height: 12),
            _buildAttributesCard(state, notifier),

            const SizedBox(height: 24),

            // 3. Condiciones Comerciales y Financiación
            _buildSectionHeader(
              title: 'Pagos Parcelados y Cuotas',
              subtitle: 'Habilita a los compradores pagar este producto en cuotas semanales o mensuales.',
            ),
            const SizedBox(height: 12),
            _buildInstallmentsCard(state, notifier, storeState),

            const SizedBox(height: 24),

            // 4. Reglas de Publicación y Visibilidad
            _buildSectionHeader(
              title: 'Reglas y Visibilidad de Negocio',
              subtitle: 'Controla si el producto está publicado, destacado o requiere reserva.',
            ),
            const SizedBox(height: 12),
            _buildBusinessFlagsCard(state, notifier),
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

  // --- CUSTOMIZATION GROUPS ---
  Widget _buildCustomizationsCard(ItemFormState state, ItemFormNotifier notifier) {
    return _buildCard([
      if (state.customizationGroups.isEmpty) ...[
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No hay grupos de personalización configurados.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
        ),
      ] else ...[
        ...state.customizationGroups.map((group) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ExpansionTile(
              initiallyExpanded: true,
              shape: const Border(),
              title: Text(
                group.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: Text(
                'Mínimo: ${group.minSelect} | Máximo: ${group.maxSelect}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Eliminar Grupo'),
                      content: Text('¿Estás seguro de que deseas eliminar el grupo "${group.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCELAR'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final newList = state.customizationGroups.where((g) => g.id != group.id).toList();
                            notifier.onCustomizationGroupsChanged(newList);
                          },
                          child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInlineTextField(
                        key: ValueKey('${state.itemId ?? "new"}_${group.id}_name'),
                        initialValue: group.name,
                        label: 'Nombre del grupo de personalización',
                        onChanged: (val) {
                          final newList = state.customizationGroups.map((g) {
                            if (g.id == group.id) {
                              return CustomizationGroup(
                                id: g.id,
                                name: val.trim(),
                                minSelect: g.minSelect,
                                maxSelect: g.maxSelect,
                                options: g.options,
                              );
                            }
                            return g;
                          }).toList();
                          notifier.onCustomizationGroupsChanged(newList);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedStar, size: 18, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 8),
                          const Text(
                            '¿Es obligatorio?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const Spacer(),
                          Switch.adaptive(
                            value: group.minSelect > 0,
                            activeThumbColor: const Color(0xFF4F46E5),
                            onChanged: (val) {
                              final newList = state.customizationGroups.map((g) {
                                if (g.id == group.id) {
                                  return CustomizationGroup(
                                    id: g.id,
                                    name: g.name,
                                    minSelect: val ? (g.minSelect > 0 ? g.minSelect : 1) : 0,
                                    maxSelect: g.maxSelect,
                                    options: g.options,
                                  );
                                }
                                return g;
                              }).toList();
                              notifier.onCustomizationGroupsChanged(newList);
                            },
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 2, bottom: 12),
                        child: Text(
                          'Si se marca, el cliente debe elegir al menos una opción de este grupo.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInlineTextField(
                              key: ValueKey('${state.itemId ?? "new"}_${group.id}_minSelect'),
                              initialValue: group.minSelect.toString(),
                              label: 'Mín. Selecciones',
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final numVal = int.tryParse(val) ?? 0;
                                final newList = state.customizationGroups.map((g) {
                                  if (g.id == group.id) {
                                    return CustomizationGroup(
                                      id: g.id,
                                      name: g.name,
                                      minSelect: numVal,
                                      maxSelect: g.maxSelect,
                                      options: g.options,
                                    );
                                  }
                                  return g;
                                }).toList();
                                notifier.onCustomizationGroupsChanged(newList);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInlineTextField(
                              key: ValueKey('${state.itemId ?? "new"}_${group.id}_maxSelect'),
                              initialValue: group.maxSelect.toString(),
                              label: 'Máx. Selecciones',
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final numVal = int.tryParse(val) ?? 0;
                                final newList = state.customizationGroups.map((g) {
                                  if (g.id == group.id) {
                                    return CustomizationGroup(
                                      id: g.id,
                                      name: g.name,
                                      minSelect: g.minSelect,
                                      maxSelect: numVal,
                                      options: g.options,
                                    );
                                  }
                                  return g;
                                }).toList();
                                notifier.onCustomizationGroupsChanged(newList);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'OPCIONES DEL GRUPO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 10),
                      if (group.options.isEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No hay opciones añadidas a este grupo aún.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ] else ...[
                        ...group.options.map((opt) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (context) => _OptionFormBottomSheet(
                                    group: group,
                                    option: opt,
                                    state: state,
                                    ref: ref,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4F46E5)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            opt.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Mín: ${opt.minQuantity} | Máx: ${opt.maxQuantity}',
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: opt.price > 0
                                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        opt.price > 0 ? '+\$${opt.price.toStringAsFixed(2)}' : 'Incluido',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: opt.price > 0 ? const Color(0xFF047857) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      onPressed: () {
                                        final newList = state.customizationGroups.map((g) {
                                          if (g.id == group.id) {
                                            return CustomizationGroup(
                                              id: g.id,
                                              name: g.name,
                                              minSelect: g.minSelect,
                                              maxSelect: g.maxSelect,
                                              options: g.options.where((o) => o.id != opt.id).toList(),
                                            );
                                          }
                                          return g;
                                        }).toList();
                                        notifier.onCustomizationGroupsChanged(newList);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => _OptionFormBottomSheet(
                                group: group,
                                state: state,
                                ref: ref,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Agregar Opción'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            final newId = DateTime.now().millisecondsSinceEpoch.toString();
            final newList = [
              ...state.customizationGroups,
              CustomizationGroup(
                id: newId,
                name: 'Nueva Personalización',
                minSelect: 0,
                maxSelect: 0,
                options: const [],
              ),
            ];
            notifier.onCustomizationGroupsChanged(newList);
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar Grupo de Opciones'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4F46E5),
            side: const BorderSide(color: Color(0xFF4F46E5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }

  // --- ATTRIBUTES & TEMPLATES ---
  Widget _buildAttributesCard(ItemFormState state, ItemFormNotifier notifier) {
    if (state.isLoadingTemplates) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.categoryId == null) {
      return _buildCard([
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Selecciona una categoría en el Paso 1 para desbloquear propiedades específicas',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
        ),
      ]);
    }

    final extraAttributes = state.attributes.entries
        .where((e) => !state.availableTemplates.any((t) => t.name == e.key));

    return _buildCard([
      if (state.availableTemplates.isNotEmpty) ...[
        ...state.availableTemplates.map((template) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildDynamicInput(template, state, notifier),
          );
        }),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'PROPIEDADES PERSONALIZADAS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ),
      ],
      if (!_showManualProperties)
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _showManualProperties = true),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir propiedad personalizada'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        )
      else ...[
        Row(
          children: [
            const Text(
              'Propiedad personalizada',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _showManualProperties = false),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _attrKeyController,
                selectAllOnFocus: false,
                decoration: _inputDecoration('Nombre', hint: 'Ej. Marca'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _attrValueController,
                selectAllOnFocus: false,
                decoration: _inputDecoration('Valor', hint: 'Ej. Nike'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addAttribute,
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
      if (extraAttributes.isNotEmpty) ...[
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: extraAttributes.map((entry) {
            return Chip(
              label: Text('${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 12)),
              backgroundColor: const Color(0xFFF1F5F9),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onDeleted: () => notifier.removeAttribute(entry.key),
              deleteIcon: const Icon(Icons.close, size: 14),
            );
          }).toList(),
        ),
      ],
    ]);
  }

  Widget _buildDynamicInput(PropertyTemplate template, ItemFormState state, ItemFormNotifier notifier) {
    final value = state.attributes[template.name];

    switch (template.type) {
      case PropertyType.boolean:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(template.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          value: value ?? false,
          activeThumbColor: const Color(0xFF4F46E5),
          onChanged: (v) => notifier.onAttributeChanged(template.name, v),
        );

      case PropertyType.number:
        return TextFormField(
          selectAllOnFocus: false,
          initialValue: value?.toString() ?? '',
          decoration: _inputDecoration(template.name, hint: template.config?['unit'] ?? '0.00'),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 14),
          onChanged: (v) => notifier.onAttributeChanged(template.name, double.tryParse(v) ?? 0),
        );

      case PropertyType.dropdown:
        final List<String> options = List<String>.from(template.config?['options'] ?? []);
        return DropdownButtonFormField<String>(
          initialValue: value,
          decoration: _inputDecoration(template.name),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: (v) => notifier.onAttributeChanged(template.name, v),
        );

      default:
        return TextFormField(
          selectAllOnFocus: false,
          initialValue: value?.toString() ?? '',
          decoration: _inputDecoration(template.name, hint: 'Escribe aquí...'),
          style: const TextStyle(fontSize: 14),
          onChanged: (v) => notifier.onAttributeChanged(template.name, v),
        );
    }
  }

  // --- INSTALLMENTS & CUOTAS ---
  Widget _buildInstallmentsCard(ItemFormState state, ItemFormNotifier notifier, StoreDetailsData storeState) {
    return _buildCard([
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Permitir pagos en cuotas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: const Text('El cliente podrá pagar este producto en partes', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        value: state.allowInstallments,
        activeThumbColor: const Color(0xFF10B981),
        onChanged: (v) {
          if (v && storeState.store != null && !storeState.store!.allowPartialPayments) {
            NotificationService.showError(
              context,
              'Debes habilitar los pagos parciales en la configuración de la tienda primero.',
            );
            return;
          }
          notifier.onAllowInstallmentsChanged(v);
        },
      ),
      if (state.allowInstallments) ...[
        const Divider(height: 24),
        TextFormField(
          key: ValueKey('lateFee_${state.itemId ?? "new"}'),
          selectAllOnFocus: false,
          initialValue: state.lateFeePercentage == 0 ? '' : state.lateFeePercentage.toString(),
          decoration: _inputDecoration(
            'Porcentaje de multa por retraso (%)',
            hint: 'Ej. 5.0',
            prefix: const Icon(Icons.percent, size: 16, color: Color(0xFF64748B)),
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 14),
          onChanged: (v) => notifier.onLateFeePercentageChanged(double.tryParse(v) ?? 0),
        ),
      ],
    ]);
  }

  // --- BUSINESS FLAGS & RULES ---
  Widget _buildBusinessFlagsCard(ItemFormState state, ItemFormNotifier notifier) {
    return _buildCard([
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Producto Publicado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: const Text('Visible públicamente para los compradores en la tienda', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        value: state.isActive,
        activeThumbColor: const Color(0xFF10B981),
        onChanged: (v) => notifier.onIsActiveChanged(v),
      ),
      const Divider(height: 20),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Producto Destacado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: const Text('Aparece en las vitrinas principales de la tienda', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        value: state.isFeatured,
        activeThumbColor: const Color(0xFFF59E0B),
        onChanged: (v) => notifier.onIsFeaturedChanged(v),
      ),
      const Divider(height: 20),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          state.itemType == ItemType.service
              ? 'Agenda y Reserva de Turnos'
              : 'Venta por Preventa / Bajo Demanda',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          state.itemType == ItemType.service
              ? 'Permite a los clientes elegir horario y fecha específica según tu disponibilidad.'
              : 'Vende artículos bajo pedido o importación previa con abono inicial.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        value: state.requiresBooking,
        activeThumbColor: const Color(0xFF4F46E5),
        onChanged: (v) => notifier.onRequiresBookingChanged(v),
      ),
      if (state.requiresBooking) ...[
        const SizedBox(height: 12),
        if (state.itemType == ItemType.service)
          _buildServiceSlotConfigurator(state, notifier)
        else
          _buildProductPreorderConfigurator(state, notifier),
      ],
      const Divider(height: 20),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Restricción de Edad (+18)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: const Text('Solo para compradores mayores de edad (tabaco, bebidas alcohólicas, etc.)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        value: state.isAgeRestricted,
        activeThumbColor: const Color(0xFFEF4444),
        onChanged: (v) => notifier.onIsAgeRestrictedChanged(v),
      ),
    ]);
  }

  Widget _buildHelpButton({
    required String title,
    required String explanation,
    String? example,
    IconData? icon,
    Color? color,
  }) {
    final themeColor = color ?? const Color(0xFF7C3AED);
    return Tooltip(
      message: 'Ver explicación de $title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _showHelpModal(
              title: title,
              explanation: explanation,
              example: example,
              icon: icon,
              color: themeColor,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: themeColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpModal({
    required String title,
    required String explanation,
    String? example,
    IconData? icon,
    Color? color,
  }) {
    final themeColor = color ?? const Color(0xFF7C3AED);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon ?? Icons.info_outline_rounded, size: 22, color: themeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              explanation,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
            if (example != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        example,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int? day) {
    switch (day) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Todos los días';
    }
  }

  Widget _buildServiceLocationOption({
    required String title,
    required String description,
    required IconData icon,
    required String value,
    required String groupValue,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F3FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF5B21B6) : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSlotConfigurator(ItemFormState state, ItemFormNotifier notifier) {
    final config = Map<String, dynamic>.from(state.slotConfig);
    final minNoticeHours = config['minNoticeHours'] ?? 2;
    final durationMinutes = config['serviceDurationMinutes'] ?? 60;
    final maxConcurrent = config['maxConcurrentBookings'] ?? 1;
    final allowSameDay = config['allowSameDay'] ?? true;
    final slots = List<Map<String, dynamic>>.from(config['slots'] ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.schedule, size: 20, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración de Turnos y Agenda',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6)),
                    ),
                    Text(
                      'Reglas de aviso previo, capacidad y horarios de atención.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  selectAllOnFocus: false,
                  initialValue: minNoticeHours.toString(),
                  decoration: _inputDecoration(
                    'Aviso Mínimo',
                    hint: '2 hrs',
                    suffix: _buildHelpButton(
                      title: 'Aviso Mínimo de Reserva',
                      explanation: 'Tiempo mínimo de anticipación (en horas) con el que un cliente puede agendar antes del inicio del turno. Te protege de reservas imprevistas de última hora.',
                      example: 'Ejemplo: Si configuras 2 horas y son las 2:00 PM, los clientes solo podrán reservar turnos a partir de las 4:00 PM.',
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final intVal = int.tryParse(val) ?? 0;
                    config['minNoticeHours'] = intVal;
                    notifier.onSlotConfigChanged(config);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  selectAllOnFocus: false,
                  initialValue: durationMinutes.toString(),
                  decoration: _inputDecoration(
                    'Duración',
                    hint: '60 min',
                    suffix: _buildHelpButton(
                      title: 'Duración Estimada del Servicio',
                      explanation: 'Tiempo promedio en minutos que toma atender y completar el servicio.',
                      example: 'Ejemplo: 45 min para corte de cabello, 60 min para masaje, 120 min para colorimetría.',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final intVal = int.tryParse(val) ?? 60;
                    config['serviceDurationMinutes'] = intVal;
                    notifier.onSlotConfigChanged(config);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            selectAllOnFocus: false,
            initialValue: maxConcurrent.toString(),
            decoration: _inputDecoration(
              'Capacidad Simultánea por Turno',
              hint: '1 cupo',
              suffix: _buildHelpButton(
                title: 'Capacidad Simultánea por Turno',
                explanation: 'Cantidad máxima de clientes que pueden reservar y ser atendidos a la misma hora en el mismo turno.',
                example: 'Ejemplo: Si tienes 3 colaboradores o puestos en simultáneo, coloca 3. Si atiendes solo tú de forma individual, coloca 1.',
                icon: Icons.people_outline_rounded,
                color: const Color(0xFF7C3AED),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final intVal = int.tryParse(val) ?? 1;
              config['maxConcurrentBookings'] = intVal;
              notifier.onSlotConfigChanged(config);
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.today_rounded, size: 20, color: Color(0xFF7C3AED)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Reservas el Mismo Día',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildHelpButton(
                            title: 'Reservas el Mismo Día',
                            explanation: 'Indica si permites que los clientes agenden citas para el día de hoy (respetando siempre las horas de aviso mínimo). Si lo desactivas, solo podrán reservar a partir de mañana.',
                            example: 'Ejemplo: Actívalo si aceptas citas espontáneas el mismo día. Desactívalo si requieres preparar insumos el día anterior.',
                            icon: Icons.today_rounded,
                            color: const Color(0xFF7C3AED),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Permitir que los clientes reserven citas para la jornada de hoy.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: allowSameDay,
                  activeThumbColor: const Color(0xFF7C3AED),
                  onChanged: (val) {
                    config['allowSameDay'] = val;
                    notifier.onSlotConfigChanged(config);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lugar de Atención / Realización',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Define dónde se prestará el servicio a tus clientes.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    _buildHelpButton(
                      title: 'Lugar de Atención',
                      explanation:
                          '• Presencial en el Local: El cliente acude al local del negocio. En el proceso de compra no se le solicita dirección de entrega ni costo de envío.\n• A Domicilio: Te trasladas al domicilio del cliente.\n• A Elección del Cliente: El cliente escoge en el checkout si asiste al local o solicita a domicilio.',
                      example:
                          'Ejemplo: Peluquería/Taller = Presencial en Local. Cerrajería/Limpieza = A Domicilio. Masajes/Entrenador = A Elección del Cliente.',
                      icon: Icons.location_on_outlined,
                      color: const Color(0xFF7C3AED),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildServiceLocationOption(
                  title: 'Presencial en el Local',
                  description: 'El cliente acude a la dirección física del comercio.',
                  icon: Icons.storefront_rounded,
                  value: 'ON_SITE',
                  groupValue: config['serviceLocationType']?.toString() ?? 'ON_SITE',
                  onSelected: (val) {
                    config['serviceLocationType'] = val;
                    notifier.onSlotConfigChanged(config);
                  },
                ),
                const SizedBox(height: 8),
                _buildServiceLocationOption(
                  title: 'A Domicilio',
                  description: 'Te trasladas a la casa o dirección del cliente.',
                  icon: Icons.home_work_outlined,
                  value: 'HOME_SERVICE',
                  groupValue: config['serviceLocationType']?.toString() ?? 'ON_SITE',
                  onSelected: (val) {
                    config['serviceLocationType'] = val;
                    notifier.onSlotConfigChanged(config);
                  },
                ),
                const SizedBox(height: 8),
                _buildServiceLocationOption(
                  title: 'A Elección del Cliente',
                  description: 'El cliente escoge en el checkout si acude al local o pide a domicilio.',
                  icon: Icons.alt_route_rounded,
                  value: 'CUSTOMER_CHOICE',
                  groupValue: config['serviceLocationType']?.toString() ?? 'ON_SITE',
                  onSelected: (val) {
                    config['serviceLocationType'] = val;
                    notifier.onSlotConfigChanged(config);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'HORARIOS Y TURNOS DE ATENCIÓN',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9), letterSpacing: 0.5),
                ),
              ),
              _buildHelpButton(
                title: 'Horarios y Turnos',
                explanation: 'Ventanas de atención configuradas. Puedes agregar turnos repetitivos por día de la semana o turnos con fechas concretas con selección visual de hora.',
                icon: Icons.calendar_month_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (slots.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDE9FE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No hay turnos registrados. Agrega horarios habituales para que tus clientes puedan reservar con selector de hora interactivo.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            )
          else
            ...slots.asMap().entries.map((entry) {
              final idx = entry.key;
              final slot = entry.value;
              final dayVal = slot['dayOfWeek'] as int?;
              final specificDate = slot['specificDate'] as String?;
              final dayLabel = specificDate != null
                  ? '📅 $specificDate'
                  : _getDayName(dayVal);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEDE9FE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                slot['label'] ?? 'Turno',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  dayLabel,
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF5B21B6)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${slot['startTime']} - ${slot['endTime']}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                      tooltip: 'Eliminar Turno',
                      onPressed: () {
                        slots.removeAt(idx);
                        config['slots'] = slots;
                        notifier.onSlotConfigChanged(config);
                      },
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showAddSlotBottomSheet(config, notifier),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Colors.white),
              label: const Text(
                'Agregar Turno o Franja Horaria',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 1,
                shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPreorderConfigurator(ItemFormState state, ItemFormNotifier notifier) {
    final config = Map<String, dynamic>.from(state.preorderConfig);
    final depositType = config['depositType'] ?? 'PERCENTAGE';
    final depositValue = config['depositValue'] ?? 50.0;
    final leadMin = config['estimatedLeadDaysMin'] ?? 7;
    final leadMax = config['estimatedLeadDaysMax'] ?? 15;
    final maxUnits = config['maxPreOrderUnits'] ?? 50;
    final settlementWindowHours = config['settlementWindowHours'] ?? 48;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Condiciones de Preventa (Bajo Demanda)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    ),
                    Text(
                      'Define el abono inicial, plazo de entrega y cupo máximo de reservas.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: depositType,
            decoration: _inputDecoration(
              'Modalidad de Abono Inicial',
              suffix: _buildHelpButton(
                title: 'Modalidad de Abono Inicial',
                explanation: 'Especifica cómo el cliente confirma su reserva:\n• Porcentaje (%): Abona una parte y liquida contra entrega.\n• Monto Fijo (\$): Abona una cantidad exacta en dólares.\n• 100%: Paga el total por adelantado.\n• Gratuita (\$0): Reserva sin costo y paga al recibir.',
                icon: Icons.payments_outlined,
                color: const Color(0xFF2563EB),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'PERCENTAGE', child: Text('Porcentaje del Total (%)')),
              DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Monto Fijo en Dólares (\$ USD)')),
              DropdownMenuItem(value: 'FULL_PAYMENT', child: Text('Pago Completo Anticipado (100%)')),
              DropdownMenuItem(value: 'FREE', child: Text('Reserva Gratuita (\$0)')),
            ],
            onChanged: (val) {
              if (val != null) {
                config['depositType'] = val;
                notifier.onPreorderConfigChanged(config);
              }
            },
          ),
          if (depositType == 'PERCENTAGE' || depositType == 'FIXED_AMOUNT') ...[
            const SizedBox(height: 12),
            TextFormField(
              selectAllOnFocus: false,
              initialValue: depositValue.toString(),
              decoration: _inputDecoration(
                depositType == 'PERCENTAGE' ? 'Porcentaje Requerido (%)' : 'Monto de Abono (\$ USD)',
                hint: depositType == 'PERCENTAGE' ? '50' : '20.0',
                suffix: _buildHelpButton(
                  title: depositType == 'PERCENTAGE' ? 'Porcentaje de Abono' : 'Monto Fijo de Abono',
                  explanation: depositType == 'PERCENTAGE'
                      ? 'Porcentaje del valor total del producto que el cliente debe pagar ahora para confirmar el pedido (ej: 50%).'
                      : 'Monto fijo en dólares que el cliente debe abonar al reservar (ej: \$20 USD).',
                  icon: Icons.price_change_outlined,
                  color: const Color(0xFF2563EB),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                final dVal = double.tryParse(val) ?? 0.0;
                config['depositValue'] = dVal;
                notifier.onPreorderConfigChanged(config);
              },
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  selectAllOnFocus: false,
                  initialValue: leadMin.toString(),
                  decoration: _inputDecoration(
                    'Días Mínimos Entrega',
                    hint: '7',
                    suffix: _buildHelpButton(
                      title: 'Días Mínimos de Entrega',
                      explanation: 'La cantidad mínima de días que estimas tardará en estar listo el artículo para retiro o despacho.',
                      example: 'Ejemplo: 7 días para artículos de confección o importación estándar.',
                      icon: Icons.local_shipping_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final iVal = int.tryParse(val) ?? 1;
                    config['estimatedLeadDaysMin'] = iVal;
                    notifier.onPreorderConfigChanged(config);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  selectAllOnFocus: false,
                  initialValue: leadMax.toString(),
                  decoration: _inputDecoration(
                    'Días Máximos Entrega',
                    hint: '15',
                    suffix: _buildHelpButton(
                      title: 'Días Máximos de Entrega',
                      explanation: 'La cantidad máxima estimada de días para la entrega final.',
                      example: 'Ejemplo: 15 días. El cliente verá "Entrega estimada: 7 a 15 días".',
                      icon: Icons.date_range_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final iVal = int.tryParse(val) ?? 15;
                    config['estimatedLeadDaysMax'] = iVal;
                    notifier.onPreorderConfigChanged(config);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  selectAllOnFocus: false,
                  initialValue: maxUnits.toString(),
                  decoration: _inputDecoration(
                    'Cupo Máximo Preventa',
                    hint: '50',
                    suffix: _buildHelpButton(
                      title: 'Cupo Máximo de Preventa',
                      explanation: 'El límite de unidades que aceptas en preventa. Al llegar a este cupo, la publicación se pausará automáticamente para evitar sobreventa.',
                      example: 'Ejemplo: 50 unidades.',
                      icon: Icons.production_quantity_limits_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final iVal = int.tryParse(val) ?? 50;
                    config['maxPreOrderUnits'] = iVal;
                    notifier.onPreorderConfigChanged(config);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  selectAllOnFocus: false,
                  initialValue: settlementWindowHours.toString(),
                  decoration: _inputDecoration(
                    'Plazo Liquidación (Horas)',
                    hint: '48',
                    suffix: _buildHelpButton(
                      title: 'Plazo para Liquidar Saldo',
                      explanation: 'Tiempo en horas que tiene el comprador para pagar el saldo restante tras recibir la notificación de que su artículo llegó a la tienda.',
                      example: 'Ejemplo: 48 horas (2 días).',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final iVal = int.tryParse(val) ?? 48;
                    config['settlementWindowHours'] = iVal;
                    notifier.onPreorderConfigChanged(config);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddSlotBottomSheet(Map<String, dynamic> config, ItemFormNotifier notifier) {
    TimeOfDay selectedStartTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay selectedEndTime = const TimeOfDay(hour: 11, minute: 0);
    bool isRecurrent = true;
    int? selectedDayOfWeek = 1; // 1 = Lunes
    DateTime? selectedSpecificDate;
    final labelCtrl = TextEditingController(text: 'Turno Mañana');

    final days = [
      {'val': 1, 'label': 'Lun', 'full': 'Lunes'},
      {'val': 2, 'label': 'Mar', 'full': 'Martes'},
      {'val': 3, 'label': 'Mié', 'full': 'Miércoles'},
      {'val': 4, 'label': 'Jue', 'full': 'Jueves'},
      {'val': 5, 'label': 'Vie', 'full': 'Viernes'},
      {'val': 6, 'label': 'Sáb', 'full': 'Sábado'},
      {'val': 7, 'label': 'Dom', 'full': 'Domingo'},
    ];

    final suggestions = [
      'Turno Mañana',
      'Turno Tarde',
      'Turno Noche',
      'Jornada Continua',
      'Horario Extendido',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final startMinutes = selectedStartTime.hour * 60 + selectedStartTime.minute;
            final endMinutes = selectedEndTime.hour * 60 + selectedEndTime.minute;
            final durationMinutes = endMinutes - startMinutes;
            final isValidTime = durationMinutes > 0;

            String formatTime(TimeOfDay t) {
              final h = t.hour.toString().padLeft(2, '0');
              final m = t.minute.toString().padLeft(2, '0');
              return '$h:$m';
            }

            String formatTimeDisplay(TimeOfDay t) {
              final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
              final m = t.minute.toString().padLeft(2, '0');
              final period = t.period == DayPeriod.am ? 'AM' : 'PM';
              return '$hour12:$m $period';
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetCtx).size.height * 0.88,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.alarm_add_rounded, color: Color(0xFF7C3AED), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nuevo Turno / Horario',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'Configura días y ventana de atención',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Modalidad / Frecuencia
                            const Text(
                              'Tipo de Programación',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    avatar: Icon(
                                      Icons.repeat_rounded,
                                      size: 16,
                                      color: isRecurrent ? const Color(0xFF5B21B6) : const Color(0xFF64748B),
                                    ),
                                    label: const Center(child: Text('Día Habitual')),
                                    selected: isRecurrent,
                                    selectedColor: const Color(0xFFDDD6FE),
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    labelStyle: TextStyle(
                                      color: isRecurrent ? const Color(0xFF5B21B6) : const Color(0xFF64748B),
                                      fontWeight: isRecurrent ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 12.5,
                                    ),
                                    onSelected: (v) {
                                      if (v) {
                                        setSheetState(() {
                                          isRecurrent = true;
                                          selectedDayOfWeek ??= 1;
                                          selectedSpecificDate = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ChoiceChip(
                                    avatar: Icon(
                                      Icons.event_available_rounded,
                                      size: 16,
                                      color: !isRecurrent ? const Color(0xFF5B21B6) : const Color(0xFF64748B),
                                    ),
                                    label: const Center(child: Text('Fecha Concreta')),
                                    selected: !isRecurrent,
                                    selectedColor: const Color(0xFFDDD6FE),
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    labelStyle: TextStyle(
                                      color: !isRecurrent ? const Color(0xFF5B21B6) : const Color(0xFF64748B),
                                      fontWeight: !isRecurrent ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 12.5,
                                    ),
                                    onSelected: (v) {
                                      if (v) {
                                        setSheetState(() {
                                          isRecurrent = false;
                                          selectedSpecificDate ??= DateTime.now();
                                          selectedDayOfWeek = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (isRecurrent) ...[
                              const Text(
                                'Día de repetición semanal:',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Todos los días'),
                                    selected: selectedDayOfWeek == null,
                                    selectedColor: const Color(0xFFDDD6FE),
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    labelStyle: TextStyle(
                                      color: selectedDayOfWeek == null ? const Color(0xFF5B21B6) : const Color(0xFF64748B),
                                      fontWeight: selectedDayOfWeek == null ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 11.5,
                                    ),
                                    onSelected: (sel) {
                                      if (sel) {
                                        setSheetState(() => selectedDayOfWeek = null);
                                      }
                                    },
                                  ),
                                  ...days.map((d) {
                                    final isSel = selectedDayOfWeek == d['val'];
                                    return ChoiceChip(
                                      label: Text(d['label'] as String),
                                      selected: isSel,
                                      selectedColor: const Color(0xFFDDD6FE),
                                      backgroundColor: const Color(0xFFF8FAFC),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      labelStyle: TextStyle(
                                        color: isSel ? const Color(0xFF5B21B6) : const Color(0xFF64748B),
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 11.5,
                                      ),
                                      onSelected: (sel) {
                                        if (sel) {
                                          setSheetState(() => selectedDayOfWeek = d['val'] as int);
                                        }
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ] else ...[
                              const Text(
                                'Fecha específica del turno:',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: sheetCtx,
                                    initialDate: selectedSpecificDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedSpecificDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF7C3AED)),
                                      const SizedBox(width: 10),
                                      Text(
                                        selectedSpecificDate != null
                                            ? '${selectedSpecificDate!.year}-${selectedSpecificDate!.month.toString().padLeft(2, '0')}-${selectedSpecificDate!.day.toString().padLeft(2, '0')}'
                                            : 'Toca para elegir fecha',
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            const Text(
                              'Rango Horario de Atención:',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: sheetCtx,
                                        initialTime: selectedStartTime,
                                      );
                                      if (picked != null) {
                                        setSheetState(() => selectedStartTime = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Hora Inicio', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF7C3AED)),
                                              const SizedBox(width: 6),
                                              Text(
                                                formatTimeDisplay(selectedStartTime),
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: sheetCtx,
                                        initialTime: selectedEndTime,
                                      );
                                      if (picked != null) {
                                        setSheetState(() => selectedEndTime = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Hora Fin', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time_filled_rounded, size: 18, color: Color(0xFF7C3AED)),
                                              const SizedBox(width: 6),
                                              Text(
                                                formatTimeDisplay(selectedEndTime),
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: isValidTime ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isValidTime ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isValidTime ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                                    size: 17,
                                    color: isValidTime ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isValidTime
                                          ? 'Ventana válida: ${durationMinutes ~/ 60 > 0 ? '${durationMinutes ~/ 60}h ' : ''}${durationMinutes % 60 > 0 ? '${durationMinutes % 60}min' : ''} (${formatTime(selectedStartTime)} a ${formatTime(selectedEndTime)})'
                                          : 'La hora de fin debe ser posterior a la hora de inicio.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isValidTime ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Etiqueta / Nombre del Turno:',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: labelCtrl,
                              selectAllOnFocus: false,
                              decoration: _inputDecoration(
                                'Nombre del Turno',
                                hint: 'Ej: Turno Mañana',
                                prefix: const Icon(Icons.label_outline, size: 18, color: Color(0xFF7C3AED)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: suggestions.map((s) {
                                return ActionChip(
                                  label: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF6D28D9))),
                                  backgroundColor: const Color(0xFFF5F3FF),
                                  side: const BorderSide(color: Color(0xFFDDD6FE)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onPressed: () {
                                    setSheetState(() => labelCtrl.text = s);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Action button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: !isValidTime
                              ? null
                              : () {
                                  final slots = List<Map<String, dynamic>>.from(config['slots'] ?? []);
                                  final formattedStart = formatTime(selectedStartTime);
                                  final formattedEnd = formatTime(selectedEndTime);

                                  slots.add({
                                    'label': labelCtrl.text.trim().isEmpty ? 'Turno' : labelCtrl.text.trim(),
                                    'startTime': formattedStart,
                                    'endTime': formattedEnd,
                                    'dayOfWeek': isRecurrent ? selectedDayOfWeek : null,
                                    'specificDate': !isRecurrent && selectedSpecificDate != null
                                        ? '${selectedSpecificDate!.year}-${selectedSpecificDate!.month.toString().padLeft(2, '0')}-${selectedSpecificDate!.day.toString().padLeft(2, '0')}'
                                        : null,
                                    'isActive': true,
                                  });
                                  config['slots'] = slots;
                                  notifier.onSlotConfigChanged(config);
                                  Navigator.pop(sheetCtx);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            disabledBackgroundColor: Colors.grey[300],
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Guardar Turno en la Agenda',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix != null
          ? Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: prefix)
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 6), child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      floatingLabelStyle: const TextStyle(color: Color(0xFF4F46E5)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildInlineTextField({
    Key? key,
    required String initialValue,
    required String label,
    TextInputType? keyboardType,
    required void Function(String) onChanged,
  }) {
    return TextFormField(
      key: key,
      selectAllOnFocus: false,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}

class _OptionFormBottomSheet extends StatefulWidget {
  final CustomizationGroup group;
  final CustomizationOption? option;
  final ItemFormState state;
  final WidgetRef ref;

  const _OptionFormBottomSheet({
    required this.group,
    this.option,
    required this.state,
    required this.ref,
  });

  @override
  State<_OptionFormBottomSheet> createState() => _OptionFormBottomSheetState();
}

class _OptionFormBottomSheetState extends State<_OptionFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _minQtyCtrl;
  late final TextEditingController _maxQtyCtrl;
  late final TextEditingController _defaultQtyCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.option?.name ?? '');
    _priceCtrl = TextEditingController(
        text: widget.option != null && widget.option!.price > 0 ? widget.option!.price.toStringAsFixed(2) : '');
    _minQtyCtrl = TextEditingController(
        text: widget.option != null ? widget.option!.minQuantity.toString() : '0');
    _maxQtyCtrl = TextEditingController(
        text: widget.option != null ? widget.option!.maxQuantity.toString() : '1');
    _defaultQtyCtrl = TextEditingController(
        text: widget.option != null ? widget.option!.defaultQuantity.toString() : '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _minQtyCtrl.dispose();
    _maxQtyCtrl.dispose();
    _defaultQtyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final minQty = int.tryParse(_minQtyCtrl.text) ?? 0;
    final maxQty = int.tryParse(_maxQtyCtrl.text) ?? 1;
    final defaultQty = int.tryParse(_defaultQtyCtrl.text) ?? 0;

    final CustomizationOption finalOption;
    if (widget.option != null) {
      finalOption = CustomizationOption(
        id: widget.option!.id,
        name: _nameCtrl.text.trim(),
        price: price,
        minQuantity: minQty,
        maxQuantity: maxQty,
        defaultQuantity: defaultQty,
      );
    } else {
      finalOption = CustomizationOption(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        price: price,
        minQuantity: minQty,
        maxQuantity: maxQty,
        defaultQuantity: defaultQty,
      );
    }

    final newList = widget.state.customizationGroups.map((g) {
      if (g.id == widget.group.id) {
        final List<CustomizationOption> newOptions = [...g.options];
        if (widget.option != null) {
          final idx = newOptions.indexWhere((o) => o.id == widget.option!.id);
          if (idx >= 0) {
            newOptions[idx] = finalOption;
          }
        } else {
          newOptions.add(finalOption);
        }
        return CustomizationGroup(
          id: g.id,
          name: g.name,
          minSelect: g.minSelect,
          maxSelect: g.maxSelect,
          options: newOptions,
        );
      }
      return g;
    }).toList();

    widget.ref.read(itemFormProvider.notifier).onCustomizationGroupsChanged(newList);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.option != null ? 'Editar Opción' : 'Nueva Opción',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                selectAllOnFocus: false,
                decoration: InputDecoration(
                  labelText: 'Nombre de la opción',
                  hintText: 'Ej. Queso Cheddar Extra',
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                selectAllOnFocus: false,
                decoration: InputDecoration(
                  labelText: 'Precio adicional (\$)',
                  hintText: '0.00 (Dejar en blanco si es gratis)',
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.tune, size: 16, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text(
                    'LÍMITES DE CANTIDAD POR ARTÍCULO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minQtyCtrl,
                      selectAllOnFocus: false,
                      decoration: InputDecoration(
                        labelText: 'Cantidad Mínima',
                        hintText: '0',
                        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxQtyCtrl,
                      selectAllOnFocus: false,
                      decoration: InputDecoration(
                        labelText: 'Cantidad Máxima',
                        hintText: '1',
                        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _defaultQtyCtrl,
                selectAllOnFocus: false,
                decoration: InputDecoration(
                  labelText: 'Cantidad por Defecto (Incluida en precio base)',
                  hintText: '0 (Por ejemplo: 1 para indicar que ya viene preseleccionada)',
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.option != null ? 'GUARDAR CAMBIOS' : 'AGREGAR OPCIÓN',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
