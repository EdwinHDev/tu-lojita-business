import 'package:flutter/material.dart';
import '../../../../core/config/envs.dart';

class ReceiptImageViewer extends StatelessWidget {
  final String imageUrl;

  const ReceiptImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = _resolveImageUrl(imageUrl);
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full Screen Interactive Image
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                fullImageUrl,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No se pudo cargar la imagen',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          
          // Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: SafeArea(
              child: Material(
                color: Colors.white24,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath';
  }
}
