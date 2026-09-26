import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/config/envs.dart';
import 'ranking_shimmer_skeleton.dart';

class DivisionEmblemWidget extends StatelessWidget {
  final String division;
  final double size;
  final String? customUrl;

  const DivisionEmblemWidget({
    super.key,
    required this.division,
    this.size = 64.0,
    this.customUrl,
  });

  static String normalize(String raw) {
    switch (raw.toUpperCase()) {
      case 'PUESTO_AMBULANTE':
      case 'HIERRO':
        return 'puesto_ambulante';
      case 'CARRITO_VENTAS':
      case 'BRONCE':
        return 'carrito_ventas';
      case 'TIENDITA_BARRIO':
      case 'PLATA':
        return 'tiendita_barrio';
      case 'LOCAL_ESTABLECIDO':
      case 'ORO':
        return 'local_establecido';
      case 'TIENDA_MARCA':
      case 'PLATINO':
        return 'tienda_marca';
      case 'GRAN_DISTRIBUIDOR':
      case 'ESMERALDA':
        return 'gran_distribuidor';
      case 'IMPERIO_COMERCIAL':
      case 'DIAMANTE':
        return 'imperio_comercial';
      case 'MAGNATE_MERCADO':
      case 'MAESTRO':
        return 'magnate_mercado';
      default:
        return 'puesto_ambulante';
    }
  }

  static String getTitle(String raw) {
    switch (raw.toUpperCase()) {
      case 'PUESTO_AMBULANTE':
      case 'HIERRO':
        return 'Puesto Ambulante';
      case 'CARRITO_VENTAS':
      case 'BRONCE':
        return 'Carrito de Ventas';
      case 'TIENDITA_BARRIO':
      case 'PLATA':
        return 'Tiendita de Barrio';
      case 'LOCAL_ESTABLECIDO':
      case 'ORO':
        return 'Local Establecido';
      case 'TIENDA_MARCA':
      case 'PLATINO':
        return 'Tienda de Marca';
      case 'GRAN_DISTRIBUIDOR':
      case 'ESMERALDA':
        return 'Gran Distribuidor';
      case 'IMPERIO_COMERCIAL':
      case 'DIAMANTE':
        return 'Imperio Comercial';
      case 'MAGNATE_MERCADO':
      case 'MAESTRO':
        return 'Magnate del Mercado';
      default:
        return 'Puesto Ambulante';
    }
  }

  @override
  Widget build(BuildContext context) {
    final slug = normalize(division);
    final serverBaseUrl = Envs.apiBaseUrl.replaceAll('/api/v1', '');
    final placeholderUrl = '$serverBaseUrl/assets/ranking/emblems/$slug.png';

    // Normalize customUrl if provided
    String? normalizedCustomUrl;
    if (customUrl != null && customUrl!.trim().isNotEmpty) {
      final trimmed = customUrl!.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        normalizedCustomUrl = trimmed;
      } else if (trimmed.startsWith('/')) {
        normalizedCustomUrl = '$serverBaseUrl$trimmed';
      } else {
        normalizedCustomUrl = '$serverBaseUrl/$trimmed';
      }
    }

    final hasCustomImage = normalizedCustomUrl != null &&
        normalizedCustomUrl != placeholderUrl;

    if (hasCustomImage) {
      final customTarget = normalizedCustomUrl;
      if (customTarget.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(
          customTarget,
          width: size,
          height: size,
          placeholderBuilder: (context) => _buildLoadingSkeleton(),
        );
      }

      // Priority 1: Custom Image -> Priority 2: Backend Placeholder Image -> Priority 3: Themed Icon
      return Image.network(
        customTarget,
        width: size,
        height: size,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingSkeleton();
        },
        errorBuilder: (context, error, stackTrace) {
          // If custom image fails (404/broken link), fallback to server placeholder
          return _buildPlaceholderImage(placeholderUrl);
        },
      );
    }

    // Default Priority: Backend Placeholder Image -> Fallback to Themed Icon
    return _buildPlaceholderImage(placeholderUrl);
  }

  Widget _buildPlaceholderImage(String placeholderUrl) {
    return Image.network(
      placeholderUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingSkeleton();
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildLoadingSkeleton() {
    return RankingShimmerSkeleton(
      width: size,
      height: size,
      shape: BoxShape.circle,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getDivisionColor(division).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.storefront,
          size: size * 0.5,
          color: _getDivisionColor(division),
        ),
      ),
    );
  }

  static Color _getDivisionColor(String division) {
    switch (normalize(division)) {
      case 'puesto_ambulante':
        return const Color(0xFF8D6E63);
      case 'carrito_ventas':
        return const Color(0xFFE65100);
      case 'tiendita_barrio':
        return const Color(0xFF2E7D32);
      case 'local_establecido':
        return const Color(0xFF1565C0);
      case 'tienda_marca':
        return const Color(0xFF7B1FA2);
      case 'gran_distribuidor':
        return const Color(0xFF37474F);
      case 'imperio_comercial':
        return const Color(0xFF0091EA);
      case 'magnate_mercado':
        return const Color(0xFFFF8F00);
      default:
        return const Color(0xFF4F46E5);
    }
  }
}
