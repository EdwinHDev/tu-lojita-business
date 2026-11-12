import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'item_detail_helpers.dart';

/// Shows the preventive confirmation modal before pausing/unpublishing an active item.
Future<bool> showItemUnpublishConfirmDialog(
  BuildContext context,
  Item item,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: TuLojitaBrandColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '¿Pausar artículo?',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: TuLojitaBrandColors.inkPrimary,
        ),
      ),
      content: Text(
        'Al pausar "${item.title}", dejará de ser visible para los compradores hasta que vuelvas a publicarlo.',
        style: const TextStyle(
          fontSize: 14,
          color: TuLojitaBrandColors.inkSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: TuLojitaBrandColors.amber700,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Despublicar'),
        ),
      ],
    ),
  );
  return result == true;
}

/// Keyboard-aware modal sheet allowing authorized users (`canChangePrices`)
/// to adjust base USD price and optional offer price with live `~ Bs.` preview.
Future<Item?> showQuickPriceSheet(
  BuildContext context,
  Item item,
) {
  return showModalBottomSheet<Item>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _QuickPriceSheetContent(item: item),
  );
}

class _QuickPriceSheetContent extends ConsumerStatefulWidget {
  final Item item;

  const _QuickPriceSheetContent({required this.item});

  @override
  ConsumerState<_QuickPriceSheetContent> createState() =>
      _QuickPriceSheetContentState();
}

class _QuickPriceSheetContentState
    extends ConsumerState<_QuickPriceSheetContent> {
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initialBase =
        widget.item.basePrice > 0 ? widget.item.basePrice : widget.item.price;
    _priceController = TextEditingController(
      text: initialBase > 0 ? initialBase.toStringAsFixed(2) : '',
    );
    _discountController = TextEditingController(
      text: widget.item.discountPrice != null && widget.item.discountPrice! > 0
          ? widget.item.discountPrice!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double? _parseMoney(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _formatBsPreview(double? usd, ExchangeRateConfig? config) {
    if (usd == null || usd <= 0 || config == null) return '';
    if (!PriceFormatter.isDualEnabled(config)) return '';
    return '~ Bs. ${PriceFormatter.formatBsNumeric(usd * config.rate)}';
  }

  Future<void> _submit() async {
    final price = _parseMoney(_priceController.text);
    final discount = _parseMoney(_discountController.text);

    if (price == null || price <= 0) {
      setState(() => _errorText = 'Ingresa un precio válido mayor a 0.');
      return;
    }
    if (discount != null && (discount <= 0 || discount >= price)) {
      setState(
        () => _errorText =
            'El precio de oferta debe ser mayor a 0 y menor al precio base.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final payload = <String, dynamic>{
        'price': price,
        'discountPrice': discount ?? 0,
      };
      final updated = await ref
          .read(itemRepositoryProvider)
          .updateItem(widget.item.id, payload);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
      NotificationService.showSuccess(
        context,
        'Precio actualizado correctamente.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(exchangeRateProvider).asData?.value;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: TuLojitaBrandColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.borderMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ajustar Precio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() => _errorText = null),
                decoration: InputDecoration(
                  labelText: 'Precio base (USD)',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Builder(
                builder: (_) {
                  final preview = _formatBsPreview(
                    _parseMoney(_priceController.text),
                    config,
                  );
                  if (preview.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      preview,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TuLojitaBrandColors.indigo600,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _discountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() => _errorText = null),
                decoration: InputDecoration(
                  labelText: 'Precio de oferta (USD, opcional)',
                  prefixText: '\$ ',
                  hintText: 'Deja vacío para quitar oferta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Builder(
                builder: (_) {
                  final preview = _formatBsPreview(
                    _parseMoney(_discountController.text),
                    config,
                  );
                  if (preview.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      preview,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TuLojitaBrandColors.positive,
                      ),
                    ),
                  );
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TuLojitaBrandColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: TuLojitaBrandColors.indigo600,
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child:
                          Text(_isSaving ? 'Guardando...' : 'Guardar Precio'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keyboard-aware modal sheet for adjusting stock of a single-SKU item.
Future<Item?> showQuickStockSheet(
  BuildContext context,
  Item item,
) {
  return showModalBottomSheet<Item>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _QuickStockSheetContent(item: item),
  );
}

class _QuickStockSheetContent extends ConsumerStatefulWidget {
  final Item item;

  const _QuickStockSheetContent({required this.item});

  @override
  ConsumerState<_QuickStockSheetContent> createState() =>
      _QuickStockSheetContentState();
}

class _QuickStockSheetContentState
    extends ConsumerState<_QuickStockSheetContent> {
  late final TextEditingController _stockController;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(
      text: (widget.item.stockQuantity ?? 0).toInt().toString(),
    );
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_stockController.text.trim());
    if (qty == null || qty < 0) {
      setState(
        () => _errorText = 'Ingresa una cantidad entera igual o mayor a 0.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final updated = await ref
          .read(itemRepositoryProvider)
          .updateItem(widget.item.id, {'stockQuantity': qty});
      if (!mounted) return;
      Navigator.of(context).pop(updated);
      NotificationService.showSuccess(
        context,
        'Stock actualizado correctamente.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: TuLojitaBrandColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajustar Inventario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.item.title,
                style: const TextStyle(
                  fontSize: 13,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _errorText = null),
                decoration: InputDecoration(
                  labelText: 'Cantidad disponible',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TuLojitaBrandColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: TuLojitaBrandColors.indigo600,
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child: Text(_isSaving ? 'Guardando...' : 'Guardar Stock'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keyboard-aware modal sheet to update per-variant stock, active state, and
/// optional price overrides subject to collaborator RBAC.
Future<Item?> showQuickVariantsSheet(
  BuildContext context,
  Item item, {
  required bool canManageStock,
  required bool canChangePrices,
}) {
  return showModalBottomSheet<Item>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _QuickVariantsSheetContent(
      item: item,
      canManageStock: canManageStock,
      canChangePrices: canChangePrices,
    ),
  );
}

class _QuickVariantsSheetContent extends ConsumerStatefulWidget {
  final Item item;
  final bool canManageStock;
  final bool canChangePrices;

  const _QuickVariantsSheetContent({
    required this.item,
    required this.canManageStock,
    required this.canChangePrices,
  });

  @override
  ConsumerState<_QuickVariantsSheetContent> createState() =>
      _QuickVariantsSheetContentState();
}

class _QuickVariantsSheetContentState
    extends ConsumerState<_QuickVariantsSheetContent> {
  late final List<TextEditingController> _stockControllers;
  late final List<TextEditingController> _priceControllers;
  late final List<bool> _activeStates;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _stockControllers = widget.item.variants
        .map(
          (v) => TextEditingController(text: v.stockQuantity.toInt().toString()),
        )
        .toList();
    _priceControllers = widget.item.variants.map((v) {
      final p = v.basePrice ?? v.price ?? widget.item.basePrice;
      return TextEditingController(text: p > 0 ? p.toStringAsFixed(2) : '');
    }).toList();
    _activeStates = widget.item.variants.map((v) => v.isActive).toList();
  }

  @override
  void dispose() {
    for (final c in _stockControllers) {
      c.dispose();
    }
    for (final c in _priceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      final variantsPayload = <Map<String, dynamic>>[];
      for (int i = 0; i < widget.item.variants.length; i++) {
        final v = widget.item.variants[i];
        final entry = <String, dynamic>{
          if (v.id != null) 'id': v.id,
          'axisValues': v.axisValues,
        };
        if (widget.canManageStock) {
          if (widget.item.trackInventory) {
            entry['stockQuantity'] =
                double.tryParse(_stockControllers[i].text.trim()) ??
                    v.stockQuantity;
          }
          entry['isActive'] = _activeStates[i];
        }
        if (widget.canChangePrices) {
          final parsedPrice = double.tryParse(
            _priceControllers[i].text.trim().replaceAll(',', '.'),
          );
          if (parsedPrice != null && parsedPrice >= 0) {
            entry['price'] = parsedPrice;
          }
        }
        variantsPayload.add(entry);
      }

      final updated = await ref
          .read(itemRepositoryProvider)
          .updateItem(widget.item.id, {'variants': variantsPayload});
      if (!mounted) return;
      Navigator.of(context).pop(updated);
      NotificationService.showSuccess(
        context,
        'Variantes actualizadas correctamente.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      NotificationService.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exchangeConfig = ref.watch(exchangeRateProvider).asData?.value;
    final showBsPreview =
        exchangeConfig != null && PriceFormatter.isDualEnabled(exchangeConfig);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: TuLojitaBrandColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestionar Variantes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: TuLojitaBrandColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.item.variants.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final v = widget.item.variants[index];
                  final label = formatVariantCombinationLabel(v.axisValues);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TuLojitaBrandColors.canvas,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: TuLojitaBrandColors.borderMuted),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label.isNotEmpty
                                    ? label
                                    : 'Variante ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: TuLojitaBrandColors.inkPrimary,
                                ),
                              ),
                            ),
                            if (widget.canManageStock)
                              Switch(
                                value: _activeStates[index],
                                onChanged: (val) =>
                                    setState(() => _activeStates[index] = val),
                              ),
                          ],
                        ),
                        if ((widget.canManageStock &&
                                widget.item.trackInventory) ||
                            widget.canChangePrices) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (widget.canManageStock &&
                                  widget.item.trackInventory)
                                Expanded(
                                  child: TextField(
                                    controller: _stockControllers[index],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Stock',
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              if (widget.canManageStock &&
                                  widget.item.trackInventory &&
                                  widget.canChangePrices)
                                const SizedBox(width: 10),
                              if (widget.canChangePrices)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _priceControllers[index],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          labelText: 'Precio (USD)',
                                          prefixText: '\$ ',
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      if (showBsPreview) ...[
                                        Builder(
                                          builder: (_) {
                                            final parsed = double.tryParse(
                                              _priceControllers[index]
                                                  .text
                                                  .trim()
                                                  .replaceAll(',', '.'),
                                            );
                                            if (parsed == null || parsed <= 0) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                                left: 2,
                                              ),
                                              child: Text(
                                                '~ Bs. ${PriceFormatter.formatBsNumeric(parsed * exchangeConfig.rate)}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: TuLojitaBrandColors
                                                      .indigo600,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: TuLojitaBrandColors.indigo600,
                    ),
                    onPressed: _isSaving ? null : _submit,
                    child: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
