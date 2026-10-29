import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/config/envs.dart';

class PlatformQrDialog extends StatelessWidget {
  final String qrImageUrl;
  final String title;

  const PlatformQrDialog({
    super.key,
    required this.qrImageUrl,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    required String qrImageUrl,
    required String title,
  }) {
    return showDialog(
      context: context,
      builder: (context) => PlatformQrDialog(
        qrImageUrl: qrImageUrl,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = qrImageUrl.startsWith('http')
        ? qrImageUrl
        : '${Envs.apiBaseUrlImages}$qrImageUrl';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedQrCode,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    minScale: 1.0,
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4F46E5),
                            strokeWidth: 2.5,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No se pudo cargar la imagen del código QR',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Puedes pellizcar para hacer zoom. Escanéalo desde tu app bancaria o de Binance.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Entendido / Cerrar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
