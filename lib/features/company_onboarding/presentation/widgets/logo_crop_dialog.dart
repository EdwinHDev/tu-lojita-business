import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hugeicons/hugeicons.dart';

class LogoCropDialog extends StatefulWidget {
  final File imageFile;

  const LogoCropDialog({
    super.key,
    required this.imageFile,
  });

  static Future<File?> show(BuildContext context, File imageFile) {
    return showDialog<File>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LogoCropDialog(imageFile: imageFile),
    );
  }

  @override
  State<LogoCropDialog> createState() => _LogoCropDialogState();
}

class _LogoCropDialogState extends State<LogoCropDialog> {
  final GlobalKey _previewKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  bool _isProcessing = false;

  static const double _viewportSize = 250.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _syncSliderFromController() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.02) {
      setState(() {
        _currentScale = scale.clamp(0.5, 3.5);
      });
    }
  }

  void _onSliderChanged(double newScale) {
    final double currentScale = _transformationController.value.getMaxScaleOnAxis();
    final double scaleFactor = newScale / (currentScale == 0 ? 1 : currentScale);

    const center = Offset(_viewportSize / 2, _viewportSize / 2);
    final matrix = _transformationController.value.clone();
    // ignore: deprecated_member_use
    matrix.translate(center.dx, center.dy);
    // ignore: deprecated_member_use
    matrix.scale(scaleFactor);
    // ignore: deprecated_member_use
    matrix.translate(-center.dx, -center.dy);

    _transformationController.value = matrix;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _resetTransform() {
    setState(() {
      _transformationController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  Future<void> _applyCrop() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.pop(context, widget.imageFile);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) Navigator.pop(context, widget.imageFile);
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final fileName = 'logo_crop_${DateTime.now().millisecondsSinceEpoch}.png';
      final croppedFile = File('${tempDir.path}/$fileName');
      await croppedFile.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context, croppedFile);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, widget.imageFile);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedImage02,
                    color: Colors.indigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ajustar Logo de la Empresa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Arrastra para centrar y usa el zoom para encuadrar tu logo dentro del círculo.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Visor con Guía Circular y Captura Cuadrada 1:1
            Stack(
              alignment: Alignment.center,
              children: [
                // RepaintBoundary que captura la imagen cuadrada 1:1 completa (sin transparencias)
                RepaintBoundary(
                  key: _previewKey,
                  child: ClipRect(
                    child: Container(
                      width: _viewportSize,
                      height: _viewportSize,
                      color: Colors.white,
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 3.5,
                        boundaryMargin: const EdgeInsets.all(200),
                        onInteractionUpdate: (_) => _syncSliderFromController(),
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // Borde guía visual circular (Safe Zone)
                IgnorePointer(
                  child: Container(
                    width: _viewportSize,
                    height: _viewportSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.indigo, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Controles de Zoom
            Row(
              children: [
                const Icon(
                  Icons.zoom_out,
                  color: Colors.indigo,
                  size: 22,
                ),
                Expanded(
                  child: Slider(
                    value: _currentScale,
                    min: 0.5,
                    max: 3.5,
                    activeColor: Colors.indigo,
                    inactiveColor: Colors.indigo.withValues(alpha: 0.2),
                    onChanged: _onSliderChanged,
                  ),
                ),
                const Icon(
                  Icons.zoom_in,
                  color: Colors.indigo,
                  size: 22,
                ),
                IconButton(
                  tooltip: 'Restablecer',
                  icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                  onPressed: _resetTransform,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _applyCrop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Aplicar Logo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
