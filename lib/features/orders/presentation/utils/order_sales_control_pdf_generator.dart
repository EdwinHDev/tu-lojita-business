import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order_item.dart';
import 'package:tu_lojita_business/features/orders/presentation/utils/order_pdf_helpers.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_detail_helpers.dart';

/// Generador puro de la Hoja de Control y Liquidacion de Venta en PDF para comercios.
///
/// Usa [pw.MultiPage] en A4 con marcas de tiempo en hora de Venezuela (UTC-4),
/// conversion dual USD/Bs. BCV y cumplimiento estricto de permisos RBAC.
class OrderSalesControlPdfGenerator {
  static final _primaryColor = PdfColor.fromInt(0xFF4F46E5);
  static final _darkColor = PdfColor.fromInt(0xFF0F172A);
  static final _slateColor = PdfColor.fromInt(0xFF334155);
  static final _mutedColor = PdfColor.fromInt(0xFF64748B);
  static final _lightBg = PdfColor.fromInt(0xFFF8FAFC);
  static final _borderColor = PdfColor.fromInt(0xFFE2E8F0);
  static final _successBg = PdfColor.fromInt(0xFFECFDF5);
  static final _successBorder = PdfColor.fromInt(0xFFA7F3D0);
  static final _successColor = PdfColor.fromInt(0xFF047857);
  static final _warningColor = PdfColor.fromInt(0xFFB45309);
  static final _purpleBg = PdfColor.fromInt(0xFFF5F3FF);
  static final _purpleColor = PdfColor.fromInt(0xFF6D28D9);

  static Future<Uint8List> generate(
    Order order, {
    ExchangeRateConfig? exchangeRate,
    bool canViewSensitiveFinances = true,
    bool canViewSensitiveCustomerData = true,
    String? storeAddress,
    String? storePhone,
    String? exportedBy,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final byteData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final orderCode = OrderPdfHelpers.shortOrderCode(order.id);
    final createdVet = order.createdAt.local;
    final generatedVet = DateTime.now().toUtc().add(AppTimezone.offset);
    final createdFormatted =
        '${createdVet.toSlashDateString()} ${createdVet.toTimeString()} (VET)';
    final generatedFormatted =
        '${generatedVet.toSlashDateString()} ${generatedVet.toTimeString()} (VET)';

    final modalities = _buildSaleModalities(order);
    final totalLateFees = order.installments.fold<double>(
      0.0,
      (sum, inst) => sum + inst.lateFeeApplied,
    );
    final effectiveOrderRate = ExchangeRateConfig.resolveForOrder(
      exchangeRate,
      order.exchangeRate,
    );
    final hasHistoricalOrderRate =
        order.exchangeRate != null && order.exchangeRate! > 0;
    final dualEnabled = PriceFormatter.isDualEnabled(effectiveOrderRate);
    final verifiedPaidTotal =
        order.totalPaidAmount > 0 ? order.totalPaidAmount : order.finalAmount;
    final netStoreIncome = order.finalAmount - order.platformCommissionAmount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 34),
        footer: (context) => _buildFooter(
          context: context,
          orderCode: orderCode,
          generatedFormatted: generatedFormatted,
        ),
        build: (context) => [
          _buildHeader(
            order: order,
            orderCode: orderCode,
            logoImage: logoImage,
            createdFormatted: createdFormatted,
            generatedFormatted: generatedFormatted,
            modalities: modalities,
          ),
          pw.SizedBox(height: 14),
          _buildStoreAndCustomerSection(
            order: order,
            exchangeRate: effectiveOrderRate,
            hasHistoricalOrderRate: hasHistoricalOrderRate,
            dualEnabled: dualEnabled,
            canViewSensitiveCustomerData: canViewSensitiveCustomerData,
            storeAddress: storeAddress,
            storePhone: storePhone,
            exportedBy: exportedBy,
          ),
          if (order.hasSlotBookings || order.isPreOrder) ...[
            pw.SizedBox(height: 12),
            _buildOperationalDetails(order),
          ],
          pw.SizedBox(height: 14),
          _buildSectionTitle('DETALLE CONTABLE DE ARTÍCULOS VENDIDOS'),
          pw.SizedBox(height: 6),
          _buildItemsTable(
            order: order,
            exchangeRate: effectiveOrderRate,
            canViewSensitiveFinances: canViewSensitiveFinances,
          ),
          pw.SizedBox(height: 14),
          _buildFinancialSummarySection(
            order: order,
            exchangeRate: effectiveOrderRate,
            hasHistoricalOrderRate: hasHistoricalOrderRate,
            totalLateFees: totalLateFees,
            verifiedPaidTotal: verifiedPaidTotal,
            netStoreIncome: netStoreIncome,
            canViewSensitiveFinances: canViewSensitiveFinances,
          ),
          pw.SizedBox(height: 14),
          _buildSectionTitle('LIBRO DE PAGOS Y REFERENCIAS BANCARIAS'),
          pw.SizedBox(height: 6),
          _buildPaymentsTable(order, effectiveOrderRate),
          if (order.installments.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _buildSectionTitle('CRONOGRAMA DE CUOTAS'),
            pw.SizedBox(height: 6),
            _buildInstallmentsTable(order, effectiveOrderRate),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static List<String> _buildSaleModalities(Order order) {
    final tags = <String>[
      order.isPartialPayment
          ? 'Crédito en Cuotas (${order.installments.length})'
          : 'Pago de Contado',
    ];
    if (order.isPreOrder) {
      tags.add('Preventa / Bajo Demanda');
    }
    if (order.hasSlotBookings) {
      tags.add('Servicio con Cita (${order.slotBookings.length})');
    }
    return tags;
  }

  static pw.Widget _buildHeader({
    required Order order,
    required String orderCode,
    required pw.MemoryImage? logoImage,
    required String createdFormatted,
    required String generatedFormatted,
    required List<String> modalities,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null) ...[
                    pw.Image(logoImage, height: 38, fit: pw.BoxFit.contain),
                    pw.SizedBox(width: 10),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TU LOJITA EMPRESA',
                          style: pw.TextStyle(
                            color: _primaryColor,
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Hoja de Control y Liquidación de Venta',
                          style: pw.TextStyle(
                            color: _slateColor,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: modalities
                              .map(
                                (tag) => pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: _lightBg,
                                    borderRadius: const pw.BorderRadius.all(
                                      pw.Radius.circular(4),
                                    ),
                                    border: pw.Border.all(color: _borderColor),
                                  ),
                                  child: pw.Text(
                                    tag,
                                    style: pw.TextStyle(
                                      color: _slateColor,
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _lightBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: _borderColor),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _successBg,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                      border: pw.Border.all(color: _successBorder),
                    ),
                    child: pw.Text(
                      'ORDEN COMPLETADA / PAGADA',
                      style: pw.TextStyle(
                        color: _successColor,
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'CONTROL #$orderCode',
                    style: pw.TextStyle(
                      color: _primaryColor,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'ID: ${order.id}',
                    style: pw.TextStyle(color: _mutedColor, fontSize: 6.8),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Orden: $createdFormatted',
                    style: pw.TextStyle(color: _mutedColor, fontSize: 7.5),
                  ),
                  pw.Text(
                    'Emisión: $generatedFormatted',
                    style: pw.TextStyle(color: _mutedColor, fontSize: 7.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _borderColor, thickness: 1),
      ],
    );
  }

  static pw.Widget _buildStoreAndCustomerSection({
    required Order order,
    required ExchangeRateConfig? exchangeRate,
    required bool hasHistoricalOrderRate,
    required bool dualEnabled,
    required bool canViewSensitiveCustomerData,
    required String? storeAddress,
    required String? storePhone,
    required String? exportedBy,
  }) {
    final user = order.user;
    final firstName = (user?['firstName']?.toString() ?? '').trim();
    final lastName = (user?['lastName']?.toString() ?? '').trim();
    final customerName = ('$firstName $lastName').trim().isNotEmpty
        ? '$firstName $lastName'.trim()
        : 'Cliente Tu Lojita';
    final rawEmail = (user?['email']?.toString() ?? '').trim();
    final rawPhone = (user?['phone']?.toString() ?? '').trim();
    final rawAddress = (user?['address']?.toString() ?? '').trim();
    final rawId = (user?['identification']?.toString() ?? '').trim();

    final displayEmail = !canViewSensitiveCustomerData
        ? 'Correo protegido'
        : (rawEmail.isNotEmpty ? rawEmail : 'No registrado');
    final displayPhone = !canViewSensitiveCustomerData
        ? 'Contacto protegido'
        : (rawPhone.isNotEmpty ? rawPhone : 'No registrado');
    final displayAddress = !canViewSensitiveCustomerData
        ? 'Dirección protegida'
        : (rawAddress.isNotEmpty ? rawAddress : 'No registrada');

    final storeName = (order.storeName?.trim().isNotEmpty == true)
        ? order.storeName!.trim()
        : 'Comercio Tu Lojita';
    final storeCode = order.storeId != null && order.storeId!.trim().isNotEmpty
        ? OrderPdfHelpers.shortOrderCode(order.storeId!)
        : null;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _lightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'COMERCIO VENDEDOR',
                  style: pw.TextStyle(
                    color: _mutedColor,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  storeName,
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (storeCode != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Código Tienda: #$storeCode',
                    style: pw.TextStyle(color: _mutedColor, fontSize: 8),
                  ),
                ],
                if (storePhone != null && storePhone.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Teléfono: ${storePhone.trim()}',
                    style: pw.TextStyle(color: _mutedColor, fontSize: 8),
                  ),
                ],
                if (storeAddress != null && storeAddress.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Dirección: ${storeAddress.trim()}',
                    style: pw.TextStyle(color: _mutedColor, fontSize: 8),
                  ),
                ],
                pw.SizedBox(height: 2),
                pw.Text(
                  'Exportado por: ${(exportedBy?.trim().isNotEmpty == true) ? exportedBy!.trim() : "Administración de Tienda"}',
                  style: pw.TextStyle(color: _slateColor, fontSize: 8),
                ),
                if (dualEnabled && exchangeRate != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    hasHistoricalOrderRate
                        ? 'Tasa BCV (Día de Venta): ${PriceFormatter.formatRateValue(exchangeRate.rate, symbol: exchangeRate.symbol)} / USD'
                        : 'Tasa Ref. BCV: ${PriceFormatter.formatRateValue(exchangeRate.rate, symbol: exchangeRate.symbol)} / USD',
                    style: pw.TextStyle(
                      color: _primaryColor,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _lightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DATOS DEL COMPRADOR',
                  style: pw.TextStyle(
                    color: _mutedColor,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  customerName,
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (canViewSensitiveCustomerData && rawId.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Doc. Identidad: $rawId',
                    style: pw.TextStyle(color: _mutedColor, fontSize: 8),
                  ),
                ],
                pw.SizedBox(height: 2),
                pw.Text(
                  'Email: $displayEmail',
                  style: pw.TextStyle(color: _mutedColor, fontSize: 8),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Teléfono: $displayPhone',
                  style: pw.TextStyle(color: _mutedColor, fontSize: 8),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Dirección: $displayAddress',
                  style: pw.TextStyle(color: _mutedColor, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildOperationalDetails(Order order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TRAZABILIDAD OPERATIVA (CITAS / PREVENTA)'),
        pw.SizedBox(height: 6),
        if (order.isPreOrder)
          pw.Container(
            width: double.infinity,
            margin: pw.EdgeInsets.only(bottom: order.hasSlotBookings ? 6 : 0),
            padding: const pw.EdgeInsets.all(9),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFEFF6FF),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFDBFE)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Preventa / Bajo Demanda: ${_formatPreOrderStatus(order.preOrderStatus)}',
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (order.settlementDeadline != null)
                  pw.Text(
                    'Plazo liquidación: ${order.settlementDeadline!.toDateTimeString()} (VET)',
                    style: pw.TextStyle(color: _slateColor, fontSize: 8),
                  ),
              ],
            ),
          ),
        if (order.hasSlotBookings)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(9),
            decoration: pw.BoxDecoration(
              color: _purpleBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFDDD6FE)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Citas / Turnos Agendados (${order.slotBookings.length}):',
                  style: pw.TextStyle(
                    color: _purpleColor,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                ...order.slotBookings.map((sb) {
                  final slot = sb['slot'] is Map ? sb['slot'] as Map : const {};
                  final date = sb['bookingDate']?.toString() ?? '-';
                  final start = slot['startTime']?.toString() ?? '';
                  final end = slot['endTime']?.toString() ?? '';
                  final label = slot['label']?.toString() ?? 'Turno';
                  final status = sb['status']?.toString() ?? 'CONFIRMED';
                  final timeRange =
                      (start.isNotEmpty || end.isNotEmpty) ? ' ($start - $end)' : '';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      '- $date | $label$timeRange | Estado: $status',
                      style: pw.TextStyle(color: _darkColor, fontSize: 8),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  static String _formatPreOrderStatus(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'AWAITING_STOCK':
        return 'Esperando Recepción de Stock';
      case 'STOCK_ARRIVED':
        return 'Stock Recibido en Tienda';
      case 'READY_FOR_SETTLEMENT':
        return 'Listo para Liquidar Saldo';
      case 'FULFILLED':
        return 'Entregado al Cliente';
      case 'CANCELLED':
        return 'Preventa Cancelada';
      default:
        return status ?? 'Activa';
    }
  }

  static pw.Widget _buildItemsTable({
    required Order order,
    required ExchangeRateConfig? exchangeRate,
    required bool canViewSensitiveFinances,
  }) {
    final columnWidths = canViewSensitiveFinances
        ? {
            0: const pw.FlexColumnWidth(3.4),
            1: const pw.FlexColumnWidth(0.75),
            2: const pw.FlexColumnWidth(1.35),
            3: const pw.FlexColumnWidth(1.35),
            4: const pw.FlexColumnWidth(1.3),
            5: const pw.FlexColumnWidth(1.55),
          }
        : {
            0: const pw.FlexColumnWidth(3.8),
            1: const pw.FlexColumnWidth(2.6),
            2: const pw.FlexColumnWidth(0.9),
            3: const pw.FlexColumnWidth(1.4),
            4: const pw.FlexColumnWidth(1.5),
          };

    final headerCells = canViewSensitiveFinances
        ? [
            _tableHeaderCell('Artículo / Variante / Opciones'),
            _tableHeaderCell('Cant.', align: pw.TextAlign.center),
            _tableHeaderCell('Base Unit.', align: pw.TextAlign.right),
            _tableHeaderCell('Público Unit.', align: pw.TextAlign.right),
            _tableHeaderCell('Comisión', align: pw.TextAlign.right),
            _tableHeaderCell('Neto Tienda', align: pw.TextAlign.right),
          ]
        : [
            _tableHeaderCell('Artículo'),
            _tableHeaderCell('Variante / Opciones'),
            _tableHeaderCell('Cant.', align: pw.TextAlign.center),
            _tableHeaderCell('Precio Unit.', align: pw.TextAlign.right),
            _tableHeaderCell('Subtotal', align: pw.TextAlign.right),
          ];

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.7),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _lightBg),
          children: headerCells,
        ),
        ...order.orderItems.map((item) {
          final hasVariants =
              item.variantLabel != null && item.variantLabel!.trim().isNotEmpty;
          final customDesc = item.selectedOptions.isNotEmpty
              ? OrderPdfCustomizationHelper.formatSingleLine(
                  selectedOptions: item.selectedOptions,
                  availableGroups: item.item?.customizationGroups ?? const [],
                )
              : '';
          final variantDesc = hasVariants
              ? (customDesc.isNotEmpty
                  ? '${item.variantLabel!.trim()} ($customDesc)'
                  : item.variantLabel!.trim())
              : (customDesc.isNotEmpty ? customDesc : 'Estándar');
          final variantColor =
              hasVariants ? VariantColorParser.parseColor(item.variantLabel!) : null;

          final unitBase = _resolveUnitBase(item);
          final lineCommission = item.commissionAmount * item.quantity;
          final lineNet = item.price > 0
              ? ((item.price - item.commissionAmount) * item.quantity)
              : (unitBase * item.quantity);
          final linePublic = item.price * item.quantity;

          final variantWidget = variantColor != null
              ? pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 6.5,
                      height: 6.5,
                      margin: const pw.EdgeInsets.only(right: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(variantColor.toARGB32()),
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(
                          color: const PdfColor.fromInt(0xFFCBD5E1),
                          width: 0.6,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        variantDesc,
                        style: pw.TextStyle(color: _mutedColor, fontSize: 7.5),
                      ),
                    ),
                  ],
                )
              : pw.Text(
                  variantDesc,
                  style: pw.TextStyle(color: _mutedColor, fontSize: 7.5),
                );

          if (canViewSensitiveFinances) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.title,
                        style: pw.TextStyle(
                          color: _darkColor,
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      variantWidget,
                    ],
                  ),
                ),
                _tableTextCell(
                  '${item.quantity}',
                  align: pw.TextAlign.center,
                  bold: true,
                ),
                _tableDualAmountCell(unitBase, exchangeRate),
                _tableDualAmountCell(item.price, exchangeRate),
                _tableDualAmountCell(
                  lineCommission,
                  exchangeRate,
                  color: _warningColor,
                  prefix: lineCommission > 0 ? '-' : null,
                ),
                _tableDualAmountCell(
                  lineNet,
                  exchangeRate,
                  color: _successColor,
                  bold: true,
                ),
              ],
            );
          }

          return pw.TableRow(
            children: [
              _tableTextCell(item.title, bold: true),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                child: variantWidget,
              ),
              _tableTextCell(
                '${item.quantity}',
                align: pw.TextAlign.center,
                bold: true,
              ),
              _tableDualAmountCell(item.price, exchangeRate),
              _tableDualAmountCell(linePublic, exchangeRate, bold: true),
            ],
          );
        }),
      ],
    );
  }

  static double _resolveUnitBase(OrderItem item) {
    if (item.basePrice > 0) return item.basePrice;
    if (item.price > 0) return item.price - item.commissionAmount;
    return 0.0;
  }

  static pw.Widget _buildFinancialSummarySection({
    required Order order,
    required ExchangeRateConfig? exchangeRate,
    required bool hasHistoricalOrderRate,
    required double totalLateFees,
    required double verifiedPaidTotal,
    required double netStoreIncome,
    required bool canViewSensitiveFinances,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _lightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'NOTAS DE AUDITORÍA CONTABLE',
                  style: pw.TextStyle(
                    color: _mutedColor,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '- Documento de control interno generado por la tienda en Tu Lojita Empresa.',
                  style: pw.TextStyle(color: _slateColor, fontSize: 7.5),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '- Todos los pagos reflejados han sido conciliados y marcados como completados en la plataforma.',
                  style: pw.TextStyle(color: _slateColor, fontSize: 7.5),
                ),
                if (PriceFormatter.isDualEnabled(exchangeRate) &&
                    exchangeRate != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    hasHistoricalOrderRate
                        ? '- Montos referenciales en ${exchangeRate.symbol} calculados a tasa del día de la venta (${PriceFormatter.formatRateValue(exchangeRate.rate, symbol: exchangeRate.symbol)} / USD).'
                        : '- Montos referenciales en ${exchangeRate.symbol} calculados a tasa ${PriceFormatter.formatRateValue(exchangeRate.rate, symbol: exchangeRate.symbol)} / USD.',
                    style: pw.TextStyle(color: _slateColor, fontSize: 7.5),
                  ),
                ],
                if (!canViewSensitiveFinances) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '- Desglose de comisiones e ingreso neto restringido por perfil de colaborador.',
                    style: pw.TextStyle(
                      color: _warningColor,
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(11),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: _borderColor, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RESUMEN FINANCIERO Y LIQUIDACIÓN',
                  style: pw.TextStyle(
                    color: _mutedColor,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                _summaryRow(
                  'Subtotal Artículos (Público)',
                  order.totalAmount,
                  exchangeRate,
                ),
                if (order.feeAmount > 0) ...[
                  pw.SizedBox(height: 4),
                  _summaryRow(
                    'Recargo por Cuotas Tienda',
                    order.feeAmount,
                    exchangeRate,
                    prefix: '+',
                  ),
                ],
                if (totalLateFees > 0) ...[
                  pw.SizedBox(height: 4),
                  _summaryRow(
                    'Recargos por Mora Aplicados',
                    totalLateFees,
                    exchangeRate,
                    prefix: '+',
                  ),
                ],
                pw.SizedBox(height: 4),
                _summaryRow(
                  'Total Bruto Cobrado al Cliente',
                  order.finalAmount,
                  exchangeRate,
                  isBold: true,
                ),
                pw.SizedBox(height: 4),
                _summaryRow(
                  'Total Verificado / Pagado',
                  verifiedPaidTotal,
                  exchangeRate,
                ),
                if (canViewSensitiveFinances) ...[
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    child: pw.Divider(color: _borderColor, height: 1),
                  ),
                  if (order.platformCommissionAmount > 0) ...[
                    _summaryRow(
                      order.platformCommissionRate > 0
                          ? 'Comisión Plataforma (${order.platformCommissionRate.toStringAsFixed(2)}%)'
                          : 'Comisión Plataforma',
                      order.platformCommissionAmount,
                      exchangeRate,
                      prefix: '-',
                      valueColor: _warningColor,
                    ),
                    pw.SizedBox(height: 6),
                  ],
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: _successBg,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                      border: pw.Border.all(color: _successBorder),
                    ),
                    child: _summaryRow(
                      'INGRESO NETO REAL TIENDA',
                      netStoreIncome,
                      exchangeRate,
                      isBold: true,
                      labelColor: _successColor,
                      valueColor: _successColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentsTable(
    Order order,
    ExchangeRateConfig? exchangeRate,
  ) {
    if (order.payments.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _lightBg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: _borderColor),
        ),
        child: pw.Text(
          'Orden marcada como pagada en tienda / sin comprobantes digitales individuales registrados.',
          style: pw.TextStyle(color: _mutedColor, fontSize: 8),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.7),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.1),
        1: const pw.FlexColumnWidth(1.6),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.6),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _lightBg),
          children: [
            _tableHeaderCell('Concepto'),
            _tableHeaderCell('Fecha (VET)'),
            _tableHeaderCell('Método'),
            _tableHeaderCell('Referencia'),
            _tableHeaderCell('Estado', align: pw.TextAlign.center),
            _tableHeaderCell('Monto', align: pw.TextAlign.right),
          ],
        ),
        ...order.payments.map((payment) {
          final dateLocal = payment.createdAt.local;
          final dateStr =
              '${dateLocal.toSlashDateString()}\n${dateLocal.toTimeString()}';
          final methodStr =
              OrderDetailHelpers.formatPaymentMethod(payment.paymentMethod);
          final refStr = (payment.reference != null &&
                  payment.reference!.trim().isNotEmpty)
              ? payment.reference!.trim()
              : 'N/A';
          final statusStr = _formatPaymentStatus(payment.status);
          final paymentRate = ExchangeRateConfig.resolveForOrder(
            exchangeRate,
            payment.exchangeRate ?? order.exchangeRate,
          );

          return pw.TableRow(
            children: [
              _tableTextCell(payment.getQuotaLabel(order), bold: true),
              _tableTextCell(dateStr),
              _tableTextCell(methodStr),
              _tableTextCell(refStr),
              _tableTextCell(
                statusStr,
                align: pw.TextAlign.center,
                color: payment.status.toUpperCase() == 'APPROVED'
                    ? _successColor
                    : _slateColor,
                bold: payment.status.toUpperCase() == 'APPROVED',
              ),
              _tableDualAmountCell(
                payment.amount,
                paymentRate,
                bold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildInstallmentsTable(
    Order order,
    ExchangeRateConfig? exchangeRate,
  ) {
    final sorted = [...order.installments]..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.7),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.0),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(1.4),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.4),
        6: const pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _lightBg),
          children: [
            _tableHeaderCell('Cuota', align: pw.TextAlign.center),
            _tableHeaderCell('Vencimiento'),
            _tableHeaderCell('Fecha Pago'),
            _tableHeaderCell('Monto Base', align: pw.TextAlign.right),
            _tableHeaderCell('Mora', align: pw.TextAlign.right),
            _tableHeaderCell('Pagado', align: pw.TextAlign.right),
            _tableHeaderCell('Estado', align: pw.TextAlign.center),
          ],
        ),
        ...sorted.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final inst = entry.value;
          final dueStr =
              inst.dueDate != null ? inst.dueDate!.local.toSlashDateString() : 'N/A';
          final paidDateStr = inst.paymentDate != null
              ? inst.paymentDate!.local.toSlashDateString()
              : '-';

          return pw.TableRow(
            children: [
              _tableTextCell(
                '#$index',
                align: pw.TextAlign.center,
                bold: true,
              ),
              _tableTextCell(dueStr),
              _tableTextCell(paidDateStr),
              _tableDualAmountCell(inst.amount, exchangeRate),
              _tableDualAmountCell(
                inst.lateFeeApplied,
                exchangeRate,
                color: inst.lateFeeApplied > 0 ? _warningColor : _mutedColor,
              ),
              _tableDualAmountCell(
                inst.paidAmount,
                exchangeRate,
                bold: true,
              ),
              _tableTextCell(
                _formatInstallmentStatus(inst.status),
                align: pw.TextAlign.center,
                color: inst.status.toUpperCase() == 'PAID'
                    ? _successColor
                    : _slateColor,
                bold: inst.status.toUpperCase() == 'PAID',
              ),
            ],
          );
        }),
      ],
    );
  }

  static String _formatPaymentStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'Aprobado';
      case 'WAITING_VERIFICATION':
        return 'Por verificar';
      case 'PENDING':
        return 'Pendiente';
      case 'REJECTED':
        return 'Rechazado';
      case 'REFUNDED':
        return 'Reembolsado';
      default:
        return status;
    }
  }

  static String _formatInstallmentStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'Pagada';
      case 'PARTIAL':
        return 'Parcial';
      case 'OVERDUE':
        return 'Vencida';
      case 'PENDING':
        return 'Pendiente';
      default:
        return status;
    }
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _darkColor,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.4,
      ),
    );
  }

  static pw.Widget _tableHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: _darkColor,
          fontSize: 7.8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _tableTextCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: color ?? _darkColor,
          fontSize: 7.8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _tableDualAmountCell(
    double amountUsd,
    ExchangeRateConfig? exchangeRate, {
    bool bold = false,
    PdfColor? color,
    String? prefix,
  }) {
    final lines = PriceFormatter.formatDualLines(
      amountUsd,
      exchangeRate,
      prefix: prefix,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            lines.first,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: color ?? _darkColor,
              fontSize: 8,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          if (lines.length > 1)
            pw.Text(
              lines[1],
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(color: _mutedColor, fontSize: 6.8),
            ),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    double amountUsd,
    ExchangeRateConfig? exchangeRate, {
    bool isBold = false,
    String? prefix,
    PdfColor? labelColor,
    PdfColor? valueColor,
  }) {
    final valueText = PriceFormatter.formatDualInline(
      amountUsd,
      exchangeRate,
      prefix: prefix,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: labelColor ?? (isBold ? _darkColor : _slateColor),
              fontSize: isBold ? 8.8 : 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          valueText,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            color: valueColor ?? (isBold ? _darkColor : _slateColor),
            fontSize: isBold ? 8.8 : 8,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter({
    required pw.Context context,
    required String orderCode,
    required String generatedFormatted,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 0.7)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Tu Lojita Empresa - Control Interno #$orderCode | Emitido: $generatedFormatted',
            style: pw.TextStyle(color: _mutedColor, fontSize: 7.2),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(
              color: _mutedColor,
              fontSize: 7.2,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
