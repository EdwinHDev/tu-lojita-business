import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';

/// Shared BoxDecoration for Bento cards in the item details view.
BoxDecoration itemBentoCardDecoration({
  Color color = TuLojitaBrandColors.surface,
  Color borderColor = TuLojitaBrandColors.borderMuted,
  double radius = 16,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.025),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

/// Resolves relative image paths returned by the API against [Envs.apiBaseUrlImages].
String resolveItemImageUrl(String? rawPath) {
  if (rawPath == null || rawPath.trim().isEmpty) return '';
  final trimmed = rawPath.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '${Envs.apiBaseUrlImages}/$cleanPath';
}

/// Strips inline `|color|image` metadata suffixes from a variant axis value.
String stripVariantAxisMetadata(String value) {
  return value.contains('|') ? value.split('|').first.trim() : value.trim();
}

/// Formats variant axis entries into a readable combination label.
String formatVariantCombinationLabel(Map<String, String> axisValues) {
  return axisValues.values
      .map(stripVariantAxisMetadata)
      .where((v) => v.isNotEmpty)
      .join(' · ');
}

/// Opens a zoomable fullscreen gallery lightbox for item images.
void showItemImageLightbox(
  BuildContext context,
  List<String> images,
  int initialIndex,
) {
  if (images.isEmpty) return;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.95),
    builder: (ctx) => _ItemImageLightboxDialog(
      images: images,
      initialIndex: initialIndex,
    ),
  );
}

class _ItemImageLightboxDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ItemImageLightboxDialog({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ItemImageLightboxDialog> createState() =>
      _ItemImageLightboxDialogState();
}

class _ItemImageLightboxDialogState extends State<_ItemImageLightboxDialog> {
  late final PageController _controller;
  late int _pageIndex;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _pageIndex = index),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final imgUrl = resolveItemImageUrl(widget.images[index]);
              return Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 200,
                      height: 200,
                      color: const Color(0xFF1E293B),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No se pudo cargar la imagen',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          if (widget.images.length > 1)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pageIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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
