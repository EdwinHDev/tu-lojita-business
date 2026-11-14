import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Descarga local, apertura nativa sin permisos y comparticion de la Hoja de Control de Venta en PDF.
class OrderSalesControlDownloader {
  static const MethodChannel _pdfOpenerChannel =
      MethodChannel('com.tulojita/pdf_opener');

  @visibleForTesting
  static Future<bool> Function(Uint8List bytes, String filename)?
      sharePdfHandlerForTest;

  @visibleForTesting
  static bool? isAndroidOverrideForTest;

  static String buildFileName(String orderId) {
    final code = OrderPdfHelpers.shortOrderCode(orderId);
    return 'control_venta_$code.pdf';
  }

  /// Genera y guarda el PDF en almacenamiento propio de la app (Descargas privadas o Documentos).
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
      }
    } catch (_) {
      targetDir = null;
    }

    if (targetDir == null || !targetDir.existsSync()) {
      try {
        targetDir = await getApplicationDocumentsDirectory();
        displayLocation = 'Documentos';
      } catch (_) {
        targetDir = null;
      }
    }

    if (targetDir == null || !targetDir.existsSync()) {
      targetDir = await getTemporaryDirectory();
      displayLocation = 'Documentos';
    }

    if (!targetDir.existsSync()) {
      await targetDir.create(recursive: true);
    }

    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);

    return SalesControlDownloadResult(
      file: file,
      fileName: fileName,
      displayLocation: displayLocation,
    );
  }

  /// Intenta abrir el PDF en Android vía FileProvider nativo y ofrece fallback seguro a compartir.
  static Future<void> openOrSharePdf(
    BuildContext context,
    SalesControlDownloadResult result,
  ) async {
    final isAndroid = isAndroidOverrideForTest ?? Platform.isAndroid;
    if (isAndroid) {
      try {
        final opened = await _pdfOpenerChannel
            .invokeMethod<bool>('openPdf', {'path': result.file.path})
            .timeout(const Duration(seconds: 4));
        if (opened == true) {
          return;
        }
      } catch (e) {
        debugPrint('Native PDF opener failed ($e). Trying share fallback.');
      }
    }

    await _fallbackShare(result);
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

    await _sharePdfBytes(pdfBytes, buildFileName(order.id));
  }

  static Future<void> _fallbackShare(SalesControlDownloadResult result) async {
    try {
      final bytes = await result.file.readAsBytes();
      await _sharePdfBytes(bytes, result.fileName);
    } catch (e) {
      debugPrint('Error sharing sales control PDF fallback: $e');
    }
  }

  static Future<void> _sharePdfBytes(
    Uint8List bytes,
    String filename,
  ) async {
    final testHandler = sharePdfHandlerForTest;
    if (testHandler != null) {
      await testHandler(bytes, filename).timeout(const Duration(seconds: 4));
      return;
    }
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    ).timeout(const Duration(seconds: 4));
  }
}
