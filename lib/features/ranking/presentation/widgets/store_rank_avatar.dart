import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/config/envs.dart';

/// Componente universal que envuelve el avatar/logo de una tienda con el
/// marco ornamental de su división/rango comercial.
///
/// Sigue el estándar 1:1 estricto con un círculo interior central del 65%
/// reservado para el logo de la tienda y un 35% exterior para los ornamentos
/// (alas, coronas, gemas y blasones).
class StoreRankAvatar extends StatelessWidget {
  final String? logoUrl;
  final String? divisionFrameUrl;
  final String division;
  final double size;
  final VoidCallback? onTap;

  const StoreRankAvatar({
    super.key,
    required this.logoUrl,
    this.divisionFrameUrl,
    this.division = 'PUESTO_AMBULANTE',
    this.size = 72.0,
    this.onTap,
  });

  String _resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$clean';
  }

  static String normalizeDivision(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'puesto_ambulante';
    final upper = raw.trim().toUpperCase();
    switch (upper) {
      case 'HIERRO':
      case 'PUESTO_AMBULANTE':
        return 'puesto_ambulante';
      case 'BRONCE':
      case 'CARRITO_VENTAS':
        return 'carrito_ventas';
      case 'PLATA':
      case 'TIENDITA_BARRIO':
        return 'tiendita_barrio';
      case 'ORO':
      case 'LOCAL_ESTABLECIDO':
        return 'local_establecido';
      case 'PLATINO':
      case 'TIENDA_MARCA':
        return 'tienda_marca';
      case 'ESMERALDA':
      case 'GRAN_DISTRIBUIDOR':
        return 'gran_distribuidor';
      case 'DIAMANTE':
      case 'IMPERIO_COMERCIAL':
        return 'imperio_comercial';
      case 'MAESTRO':
      case 'MAGNATE_MERCADO':
        return 'magnate_mercado';
      default:
        return raw.trim().toLowerCase().replaceAll(' ', '_');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgDiscSize = size * 0.82;
    final avatarSize = size * 0.65;
    final resolvedLogo = _resolveUrl(logoUrl);
    final resolvedFrame = _resolveUrl(divisionFrameUrl);
    final slug = normalizeDivision(division);

    Widget avatarWidget = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 0. Base circular blanca sólida (rellena el espacio interior del marco y elimina la transparencia)
          Container(
            width: bgDiscSize,
            height: bgDiscSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),

          // 1. Logo circular de la tienda (65% del tamaño total)
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: resolvedLogo.isNotEmpty
                  ? Image.network(
                      resolvedLogo,
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultStoreIcon(avatarSize),
                    )
                  : _buildDefaultStoreIcon(avatarSize),
            ),
          ),

          // 2. Marco Ornamental Exterior (100% del tamaño total)
          // Intenta cargar URL remota si existe; si falla (404/red) o está vacía,
          // recurre al asset local oficial de la división. Si el asset falta, usa el borde procedural.
          if (resolvedFrame.isNotEmpty)
            Image.network(
              resolvedFrame,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackFrame(context, slug),
            )
          else
            _buildFallbackFrame(context, slug),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildDefaultStoreIcon(double size) {
    return Container(
      color: const Color(0xFFEEF2FF),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedStore01,
          color: const Color(0xFF4F46E5),
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildFallbackFrame(BuildContext context, String slug) {
    return Image.asset(
      'assets/images/frames/$slug.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _buildProceduralBorder(),
    );
  }

  Widget _buildProceduralBorder() {
    final Color ringColor = _getDivisionColor(division);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ringColor,
          width: size * 0.06,
        ),
      ),
    );
  }

  Color _getDivisionColor(String div) {
    switch (div.toUpperCase()) {
      case 'MAGNATE_MERCADO':
        return const Color(0xFFDC2626); // Master Red
      case 'IMPERIO_COMERCIAL':
        return const Color(0xFF2563EB); // Diamond Blue
      case 'GRAN_DISTRIBUIDOR':
        return const Color(0xFF059669); // Emerald Green
      case 'TIENDA_MARCA':
        return const Color(0xFF0D9488); // Platinum Teal
      case 'LOCAL_ESTABLECIDO':
        return const Color(0xFFF59E0B); // Gold Amber
      case 'TIENDITA_BARRIO':
        return const Color(0xFF94A3B8); // Silver Slate
      case 'CARRITO_VENTAS':
        return const Color(0xFFD97706); // Bronze
      case 'PUESTO_AMBULANTE':
      default:
        return const Color(0xFF64748B); // Iron Gray
    }
  }
}
