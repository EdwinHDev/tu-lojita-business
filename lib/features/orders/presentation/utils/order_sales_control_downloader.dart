import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'package:tu_lojita_business/features/orders/presentation/utils/order_pdf_helpers.dart';
import 'package:tu_lojita_business/features/orders/presentation/utils/order_sales_control_pdf_generator.dart';

class SalesControlDownloadResult {
  final File file;
  final String fileName;
  final String displayLocation;

  const SalesControlDownloadResult({
    required this.file,
    required this.fileName,
    required this.displayLocation,
  });
}

/// Descarga local, apertura nativa y comparticion de la Hoja de Control de Venta en PDF.
class OrderSalesControlDownloader {
  static String buildFileName(String orderId) {
    final code = OrderPdfHelpers.shortOrderCode(orderId);
    return 'control_venta_$code.pdf';
  }

  /// Genera y guarda el PDF en Descargas (Android) o Documentos (iOS/fallback).
  static Future<SalesControlDownloadResult> saveSalesControlLocally(
    Order order, {
    ExchangeRateConfig? exchangeRate,
    bool canViewSensitiveFinances = true,
    bool canViewSensitiveCustomerData = true,
    String? storeAddress,
    String? storePhone,
    String? exportedBy,
  }) async {
    final pdfBytes = await OrderSalesControlPdfGenerator.generate(
      order,
      exchangeRate: exchangeRate,
      canViewSensitiveFinances: canViewSensitiveFinances,
      canViewSensitiveCustomerData: canViewSensitiveCustomerData,
      storeAddress: storeAddress,
      storePhone: storePhone,
      exportedBy: exportedBy,
    );

    final fileName = buildFileName(order.id);
    Directory? targetDir;
    var displayLocation = 'Descargas';

    try {
      if (Platform.isAndroid) {
        targetDir = await getDownloadsDirectory();
        if (targetDir == null || !targetDir.existsSync()) {
          final publicDownload = Directory('/storage/emulated/0/Download');
          if (publicDownload.existsSync()) {
            targetDir = publicDownload;
          }
        }
      }
    } catch (_) {
      targetDir = null;
    }

    if (targetDir == null || !targetDir.existsSync()) {
      targetDir = await getApplicationDocumentsDirectory();
      displayLocation = 'Documentos';
    }

    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);

    return SalesControlDownloadResult(
      file: file,
      fileName: fileName,
      displayLocation: displayLocation,
    );
  }

  /// Intenta abrir el PDF con el visor nativo y ofrece fallback seguro a compartir.
  static Future<void> openOrSharePdf(
    BuildContext context,
    SalesControlDownloadResult result,
  ) async {
    try {
      final openResult = await OpenFilex.open(result.file.path)
          .timeout(const Duration(seconds: 4));

      if (openResult.type == ResultType.noAppToOpen) {
        await _fallbackShare(result);
      }
    } catch (_) {
      await _fallbackShare(result);
    }
  }

  /// Genera el PDF en memoria y abre la hoja nativa de comparticion del dispositivo.
  static Future<void> sharePdfDirectly(
    Order order, {
    ExchangeRateConfig? exchangeRate,
    bool canViewSensitiveFinances = true,
    bool canViewSensitiveCustomerData = true,
    String? storeAddress,
    String? storePhone,
    String? exportedBy,
  }) async {
    final pdfBytes = await OrderSalesControlPdfGenerator.generate(
      order,
      exchangeRate: exchangeRate,
      canViewSensitiveFinances: canViewSensitiveFinances,
      canViewSensitiveCustomerData: canViewSensitiveCustomerData,
      storeAddress: storeAddress,
      storePhone: storePhone,
      exportedBy: exportedBy,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: buildFileName(order.id),
    );
  }

  static Future<void> _fallbackShare(SalesControlDownloadResult result) async {
    try {
      final bytes = await result.file.readAsBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: result.fileName,
      );
    } catch (e) {
      debugPrint('Error sharing sales control PDF fallback: $e');
    }
  }
}
