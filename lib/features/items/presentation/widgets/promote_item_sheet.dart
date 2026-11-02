import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_promotion_provider.dart';

class PromoteItemSheet extends ConsumerStatefulWidget {
  final Item item;
  final String storeId;

  const PromoteItemSheet({
    super.key,
    required this.item,
    required this.storeId,
  });

  static Future<bool?> show(BuildContext context, Item item, String storeId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PromoteItemSheet(item: item, storeId: storeId),
    );
  }

  @override
  ConsumerState<PromoteItemSheet> createState() => _PromoteItemSheetState();
}

class _PromoteItemSheetState extends ConsumerState<PromoteItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _picker = ImagePicker();

  int _selectedDays = 7;
  File? _receiptFile;

  final List<int> _quickDays = [3, 7, 15, 30];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemPromotionProvider.notifier).loadConfigAndMethods(widget.item.id);
    });
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _receiptFile = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'No se pudo cargar la imagen');
      }
    }
  }

  Future<void> _submit(double totalCost) async {
    if (!_formKey.currentState!.validate()) return;

    if (_receiptFile == null) {
      NotificationService.showWarning(context, 'Adjunta la captura del comprobante');
      return;
    }

    final success = await ref.read(itemPromotionProvider.notifier).submitPromotionRequest(
          itemId: widget.item.id,
          durationDays: _selectedDays,
          amountPaid: totalCost,
          paymentReference: _referenceController.text.trim(),
          receiptFile: _receiptFile!,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      NotificationService.showSuccess(
        context,
        '¡Solicitud enviada! Tu promoción será activada tras verificación administrativa.',
      );
    } else {
      NotificationService.showError(
        context,
        ref.read(itemPromotionProvider).errorMessage ?? 'Error al enviar solicitud',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final promoState = ref.watch(itemPromotionProvider);
    final config = promoState.config;
    final pricePerDay = config.pricePerDay;
    final double totalCost = (_selectedDays * pricePerDay).toDouble();

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.9,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: promoState.isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra superior de agarre
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contenido Scrolleable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cabecera con Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Promocionar en el Home',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      'Aparece en la vitrina principal para miles de clientes',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Tarjeta del Producto
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                    image: widget.item.mainImage.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(widget.item.mainImage),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: widget.item.mainImage.isEmpty
                                      ? const Icon(Icons.image, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '\$${widget.item.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Selector de Días
                          const Text(
                            'Duración de la Promoción',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: _quickDays.map((days) {
                              final isSelected = _selectedDays == days;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedDays = days),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$days',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                          ),
                                          Text(
                                            'días',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Desglose de Inversión
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Inversión Total',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    Text(
                                      '$_selectedDays días × \$${pricePerDay.toStringAsFixed(2)} / día',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '\$${totalCost.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Cuentas de Cobro Oficiales
                          const Text(
                            'Datos de Pago Oficiales',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (promoState.paymentMethods.isEmpty)
                            const Text(
                              'Cuentas bancarias de la plataforma en preparación.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            )
                          else
                            Column(
                              children: promoState.paymentMethods.map((m) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.account_balance_rounded, size: 20, color: Color(0xFF475569)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.title,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            if (m.accountDetails.isNotEmpty)
                                              Text(
                                                m.accountDetails.entries
                                                    .map((e) => '${e.key}: ${e.value}')
                                                    .join(' • '),
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF2563EB)),
                                        tooltip: 'Copiar datos',
                                        onPressed: () {
                                          final details = m.accountDetails.entries
                                              .map((e) => '${e.key}: ${e.value}')
                                              .join('\n');
                                          final text = '${m.title}\n$details';
                                          Clipboard.setData(ClipboardData(text: text));
                                          NotificationService.showSuccess(context, 'Datos copiados');
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 16),

                          // Formulario de Reporte
                          const Text(
                            'Reportar Transferencia',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 10),

                          TextFormField(
                            controller: _referenceController,
                            decoration: InputDecoration(
                              labelText: 'Número de Referencia Bancaria *',
                              hintText: 'Ej. 004829104',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Ingresa la referencia de pago';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Adjuntar Comprobante
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (ctx) => SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.photo_camera),
                                        title: const Text('Tomar Foto'),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _pickReceipt(ImageSource.camera);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library),
                                        title: const Text('Elegir de Galería'),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _pickReceipt(ImageSource.gallery);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _receiptFile != null
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _receiptFile != null
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFCBD5E1),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _receiptFile != null
                                        ? Icons.check_circle_rounded
                                        : Icons.cloud_upload_outlined,
                                    color: _receiptFile != null
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _receiptFile != null
                                          ? 'Comprobante adjuntado: ${_receiptFile!.path.split(Platform.pathSeparator).last}'
                                          : 'Toca para adjuntar foto del comprobante *',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: _receiptFile != null ? FontWeight.bold : FontWeight.normal,
                                        color: _receiptFile != null ? const Color(0xFF047857) : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  if (_receiptFile != null)
                                    const Icon(Icons.edit, size: 16, color: Color(0xFF10B981)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botón Inferior
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: promoState.isSubmitting ? null : () => _submit(totalCost),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: promoState.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Enviar Reporte de Pago (\$${totalCost.toStringAsFixed(2)})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
