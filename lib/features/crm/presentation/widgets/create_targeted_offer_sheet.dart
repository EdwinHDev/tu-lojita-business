import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import '../../domain/entities/crm_entities.dart';
import '../providers/crm_providers.dart';
import 'crm_action_helpers.dart';
import 'crm_guides_catalog.dart';

class CreateTargetedOfferSheet extends ConsumerStatefulWidget {
  final String companyId;
  final CrmCustomer customer;
  final List<CrmFavoriteItem> favoriteItems;
  final String? initialItemId;

  const CreateTargetedOfferSheet({
    super.key,
    required this.companyId,
    required this.customer,
    required this.favoriteItems,
    this.initialItemId,
  });

  @override
  ConsumerState<CreateTargetedOfferSheet> createState() =>
      _CreateTargetedOfferSheetState();
}

class _CreateTargetedOfferSheetState
    extends ConsumerState<CreateTargetedOfferSheet> {
  late CrmFavoriteItem _selectedItem;
  late final TextEditingController _priceController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  int _durationHours = 24;
  String? _selectedPaymentMethod;
  bool _submitting = false;
  CrmTargetedOfferSummary? _createdOffer;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.favoriteItems.firstWhere(
      (i) => i.itemId == widget.initialItemId,
      orElse: () => widget.favoriteItems.first,
    );
    final suggested = (_selectedItem.price * 0.85).toStringAsFixed(2);
    _priceController = TextEditingController(text: suggested);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _onSelectItem(CrmFavoriteItem item) {
    setState(() {
      _selectedItem = item;
      _priceController.text = (item.price * 0.85).toStringAsFixed(2);
    });
  }

  Future<void> _submit(CrmOffersConfig config) async {
    final offerPrice =
        double.tryParse(_priceController.text.replaceAll(',', '.').trim());
    if (offerPrice == null ||
        offerPrice <= 0 ||
        offerPrice >= _selectedItem.price) {
      NotificationService.showWarning(
        context,
        'Ingresa un precio válido menor a \$${_selectedItem.price.toStringAsFixed(2)} USD.',
      );
      return;
    }

    if (config.feePerCampaign > 0) {
      if ((_selectedPaymentMethod == null || _selectedPaymentMethod!.isEmpty) ||
          _referenceController.text.trim().isEmpty) {
        NotificationService.showWarning(
          context,
          'Selecciona un método de pago de plataforma y registra tu número de referencia.',
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final created =
          await ref.read(crmRepositoryProvider).createTargetedOffer(
                widget.companyId,
                widget.customer.customerId,
                itemId: _selectedItem.itemId,
                offerPrice: offerPrice,
                durationHours: _durationHours,
                paymentMethod: _selectedPaymentMethod,
                paymentReference: _referenceController.text.trim(),
                messageToCustomer: _messageController.text.trim(),
              );
      ref.invalidate(crmCustomerDetailProvider(widget.customer.customerId));
      ref.invalidate(crmCustomersProvider);
      ref.invalidate(crmSummaryProvider);
      if (mounted) {
        setState(() {
          _createdOffer = created;
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        NotificationService.showError(
          context,
          'Error al crear oferta: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(crmOffersConfigProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (_createdOffer != null) {
      final offer = _createdOffer!;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: TuLojitaBrandColors.positiveBg,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: TuLojitaBrandColors.positive,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '¡Oferta Especial Activada!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Enviamos notificación Push a ${widget.customer.firstName} con código ${offer.offerCode} (-${offer.discountPercent.toStringAsFixed(0)}%, válida ${offer.durationHours}h). Refuerza el cierre compartiéndola por WhatsApp o copiando su enlace directo.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.customer.phone.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: TuLojitaBrandColors.positive,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('Enviar Oferta ahora por WhatsApp'),
                    onPressed: () => launchDirectWhatsApp(
                      context,
                      widget.customer.phone,
                      message: offer.whatsappShareText,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                  final copyBtn = OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    label: const Text('Copiar Enlace'),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: offer.deepLinkUrl),
                      );
                      NotificationService.showSuccess(
                        context,
                        'Enlace profundo copiado.',
                      );
                    },
                  );
                  final closeBtn = TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Cerrar'),
                  );

                  if (constraints.maxWidth < 320 || textScale >= 1.2) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        copyBtn,
                        const SizedBox(height: 6),
                        closeBtn,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: copyBtn),
                      const SizedBox(width: 8),
                      Expanded(child: closeBtn),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    final parsedOffer =
        double.tryParse(_priceController.text.replaceAll(',', '.').trim()) ?? 0;
    final discountPct = _selectedItem.price > 0 && parsedOffer > 0
        ? (((_selectedItem.price - parsedOffer) / _selectedItem.price) * 100)
            .clamp(0, 99.9)
        : 0.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  color: TuLojitaBrandColors.amber700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Oferta Relámpago para ${widget.customer.firstName}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const CrmGuideButton(
                  key: ValueKey('offer_sheet_guide_btn'),
                  guide: CrmGuidesCatalog.targetedOffers,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Disponible exclusivamente para artículos en favoritos del cliente.',
              style: TextStyle(
                fontSize: 12.5,
                color: TuLojitaBrandColors.inkSecondary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Artículo en Favoritos',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedItem.itemId,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: widget.favoriteItems
                  .map(
                    (f) => DropdownMenuItem<String>(
                      value: f.itemId,
                      child: Text(
                        '${f.title} (${PriceFormatter.formatNumeric(f.price)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                final found = widget.favoriteItems.firstWhere(
                  (i) => i.itemId == val,
                  orElse: () => _selectedItem,
                );
                _onSelectItem(found);
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                final compact = constraints.maxWidth < 320 || textScale >= 1.2;
                final priceField = TextField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Precio Especial (USD)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
                final discountCard = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.amber50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TuLojitaBrandColors.amber400),
                  ),
                  child: Column(
                    crossAxisAlignment: compact
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-${discountPct.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: TuLojitaBrandColors.amber800,
                          fontSize: 13,
                        ),
                      ),
                      if (parsedOffer > 0)
                        DualPriceText(
                          amountInUsd: parsedOffer,
                          usdStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          bsStyle: const TextStyle(
                            fontSize: 10,
                            color: TuLojitaBrandColors.inkSecondary,
                          ),
                        ),
                    ],
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      priceField,
                      const SizedBox(height: 10),
                      discountCard,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: priceField),
                    const SizedBox(width: 12),
                    discountCard,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Vigencia de la Oferta',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [6, 12, 24, 48, 72]
                  .map(
                    (h) => ChoiceChip(
                      label: Text('${h}h'),
                      selected: _durationHours == h,
                      onSelected: (_) => setState(() => _durationHours = h),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Mensaje personal para el comprador (opcional)',
                hintText: 'Ej: ¡Vimos que te encantó! Aprovecha hoy con envío prioritario.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            configAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text(
                'No se pudo cargar tarifa del servicio: $err',
                style: const TextStyle(color: TuLojitaBrandColors.danger),
              ),
              data: (config) {
                if (!config.enabled) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TuLojitaBrandColors.dangerBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'El envío de Ofertas Especiales CRM se encuentra deshabilitado temporalmente por administración.',
                      style: TextStyle(
                        color: TuLojitaBrandColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: config.feePerCampaign <= 0
                            ? TuLojitaBrandColors.positiveBg
                            : TuLojitaBrandColors.indigo50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            config.feePerCampaign <= 0
                                ? Icons.celebration_rounded
                                : Icons.payments_outlined,
                            color: config.feePerCampaign <= 0
                                ? TuLojitaBrandColors.positive
                                : TuLojitaBrandColors.indigo700,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: config.feePerCampaign <= 0
                                ? const Text(
                                    'Campaña promocional gratuita (\$0.00). Envía sin registro de pago.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: TuLojitaBrandColors.positive,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tarifa de Plataforma por Campaña:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      DualPriceText(
                                        amountInUsd: config.feePerCampaign,
                                        usdStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: TuLojitaBrandColors.indigo700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (config.feePerCampaign > 0) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPaymentMethod,
                        hint: const Text('Selecciona cuenta/método de plataforma'),
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: config.platformPaymentMethods
                            .map(
                              (m) => DropdownMenuItem<String>(
                                value: m.title,
                                child: Text('${m.title} (${m.type})'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPaymentMethod = val),
                      ),
                      if (_selectedPaymentMethod != null) ...[
                        const SizedBox(height: 6),
                        Builder(
                          builder: (_) {
                            final method = config.platformPaymentMethods
                                .where((m) => m.title == _selectedPaymentMethod)
                                .firstOrNull;
                            if (method == null) return const SizedBox.shrink();
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: TuLojitaBrandColors.canvas,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: TuLojitaBrandColors.borderMuted,
                                ),
                              ),
                              child: Text(
                                method.accountDetails.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(' · '),
                                style: const TextStyle(fontSize: 11.5),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          labelText: 'Referencia de Pago',
                          hintText: 'Ej: 00458912',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: TuLojitaBrandColors.indigo600,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            _submitting ? null : () => _submit(config),
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _submitting
                              ? 'Activando oferta...'
                              : 'Activar y Enviar Oferta',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
