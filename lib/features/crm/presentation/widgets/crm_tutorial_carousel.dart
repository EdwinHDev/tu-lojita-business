import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';

/// Interactive 4-slide visual onboarding tutorial for Mini CRM 360°.
class CrmTutorialCarousel extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  final bool isModal;

  const CrmTutorialCarousel({
    super.key,
    required this.onComplete,
    this.onSkip,
    this.isModal = false,
  });

  @override
  State<CrmTutorialCarousel> createState() => _CrmTutorialCarouselState();
}

class _CrmTutorialCarouselState extends State<CrmTutorialCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.sizeOf(context).height;
    final modalPageHeight = (mediaHeight * 0.50).clamp(250.0, 420.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isModal
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: widget.isModal ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  InkWell(
                    onTap: _previousPage,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            size: 15,
                            color: Color(0xFF475569),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Atrás',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.indigo50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Guía Mini CRM 360°',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: TuLojitaBrandColors.indigo600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (_currentPage < _totalPages - 1)
                  TextButton(
                    onPressed: widget.onSkip ?? widget.onComplete,
                    style: TextButton.styleFrom(
                      foregroundColor: TuLojitaBrandColors.inkSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Saltar'),
                  )
                else
                  Text(
                    '4 / 4',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.isModal)
            SizedBox(
              height: modalPageHeight,
              child: _buildPageView(),
            )
          else
            Expanded(child: _buildPageView()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _totalPages,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? TuLojitaBrandColors.indigo600
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: TuLojitaBrandColors.indigo600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _currentPage == _totalPages - 1
                                ? '¡Comenzar!'
                                : 'Siguiente',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_currentPage < _totalPages - 1) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (page) => setState(() => _currentPage = page),
      children: [
        _buildSlide(
          icon: Icons.storefront_rounded,
          accentColor: TuLojitaBrandColors.indigo600,
          accentBg: TuLojitaBrandColors.indigo50,
          title: 'Directorio 360° por Sucursal',
          subtitle:
              'Unifica en un solo lugar a todos los clientes que compran, reservan o guardan favoritos en tus sedes.',
          bullets: const [
            _CrmSlideBullet(
              icon: Icons.filter_alt_outlined,
              title: 'Filtro por sede autorizada',
              detail:
                  'Alterna entre todas tus sucursales o enfócate en una tienda específica.',
            ),
            _CrmSlideBullet(
              icon: Icons.insights_outlined,
              title: 'Métricas al instante',
              detail:
                  'Consulta LTV total, deuda de cuotas, favoritos y seguimientos pendientes.',
            ),
          ],
        ),
        _buildSlide(
          icon: Icons.verified_user_outlined,
          accentColor: TuLojitaBrandColors.positive,
          accentBg: TuLojitaBrandColors.positiveBg,
          title: 'Datos Exclusivos y Contacto 1-Toque',
          subtitle:
              'El teléfono, cédula y direcciones GPS están protegidos y solo se muestran en la App Empresa.',
          bullets: const [
            _CrmSlideBullet(
              icon: Icons.chat_rounded,
              title: 'WhatsApp con plantillas inteligentes',
              detail:
                  'Envía saludos VIP, recordatorios de cuotas o seguimiento de favoritos en 1 toque.',
            ),
            _CrmSlideBullet(
              icon: Icons.location_on_outlined,
              title: 'Llamada y Mapa GPS directo',
              detail:
                  'Inicia llamadas telefónicas o abre la ubicación de entrega en Google Maps.',
            ),
          ],
        ),
        _buildSlide(
          icon: Icons.auto_awesome_outlined,
          accentColor: TuLojitaBrandColors.amber700,
          accentBg: TuLojitaBrandColors.amber100,
          title: 'Segmentos RFM, LTV y Alertas',
          subtitle:
              'RFM analiza Recencia, Frecuencia y Monto; el LTV refleja el valor acumulado de cada comprador.',
          bullets: const [
            _CrmSlideBullet(
              icon: Icons.groups_outlined,
              title: 'RFM (Recencia, Frecuencia y Monto)',
              detail:
                  'Clasifica automáticamente a tus clientes en VIP, Frecuentes, En Riesgo (>45–60 días sin comprar), Con Deuda o Con Favoritos.',
            ),
            _CrmSlideBullet(
              icon: Icons.monetization_on_outlined,
              title: 'LTV + Bitácora interna',
              detail:
                  'Consulta el LTV (compras válidas acumuladas), guarda notas privadas y recibe alertas ámbar si vence un seguimiento.',
            ),
          ],
        ),
        _buildSlide(
          icon: Icons.local_offer_outlined,
          accentColor: const Color(0xFFDB2777),
          accentBg: const Color(0xFFFCE7F3),
          title: 'Ofertas Relámpago en Favoritos',
          subtitle:
              'Convierte productos guardados en deseos en ventas reales enviando descuentos privados con fecha límite.',
          bullets: const [
            _CrmSlideBullet(
              icon: Icons.timer_outlined,
              title: 'Vigencia de 6h a 72h',
              detail:
                  'Define un precio especial menor al actual sobre cualquier favorito del cliente.',
            ),
            _CrmSlideBullet(
              icon: Icons.send_to_mobile_rounded,
              title: 'Push + Enlace profundo directo',
              detail:
                  'El comprador recibe notificación Push con enlace al artículo y también puedes reenviarlo por WhatsApp.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlide({
    required IconData icon,
    required Color accentColor,
    required Color accentBg,
    required String title,
    required String subtitle,
    required List<_CrmSlideBullet> bullets,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accentBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: accentColor, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: TuLojitaBrandColors.inkPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: TuLojitaBrandColors.inkSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.canvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TuLojitaBrandColors.borderMuted),
            ),
            child: Column(
              children: [
                for (var i = 0; i < bullets.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: TuLojitaBrandColors.borderMuted,
                          ),
                        ),
                        child: Icon(
                          bullets[i].icon,
                          size: 16,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bullets[i].title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: TuLojitaBrandColors.inkPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bullets[i].detail,
                              style: const TextStyle(
                                fontSize: 12,
                                color: TuLojitaBrandColors.inkSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrmSlideBullet {
  final IconData icon;
  final String title;
  final String detail;

  const _CrmSlideBullet({
    required this.icon,
    required this.title,
    required this.detail,
  });
}

/// Modal helper to launch [CrmTutorialCarousel] on first CRM visit or on demand.
class CrmTutorialBottomSheet {
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: CrmTutorialCarousel(
              isModal: true,
              onComplete: () => Navigator.of(ctx).pop(true),
              onSkip: () => Navigator.of(ctx).pop(true),
            ),
          ),
        );
      },
    );
  }
}
