import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Interactive 3-slide educational tutorial for first-branch setup.
/// Explains the Company ➔ Branch structure, reassures single-store owners,
/// and illustrates clean customer-facing marketplace naming.
class FirstBranchTutorialCarousel extends StatefulWidget {
  final VoidCallback onComplete;
  final bool isModal;

  const FirstBranchTutorialCarousel({
    super.key,
    required this.onComplete,
    this.isModal = false,
  });

  @override
  State<FirstBranchTutorialCarousel> createState() =>
      _FirstBranchTutorialCarouselState();
}

class _FirstBranchTutorialCarouselState
    extends State<FirstBranchTutorialCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Top Bar with Slide info and Skip / Close button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button if past slide 0
                if (_currentPage > 0)
                  InkWell(
                    onTap: _previousPage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowLeft01,
                            color: Color(0xFF475569),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Atrás',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Guía Inicial',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),

                // Skip or Modal Close
                if (widget.isModal)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: const Color(0xFF64748B),
                    tooltip: 'Cerrar guía',
                  )
                else if (_currentPage < _totalPages - 1)
                  TextButton(
                    onPressed: widget.onComplete,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Saltar tutorial'),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),

          // Carousel Pages
          Expanded(
            flex: widget.isModal ? 0 : 1,
            child: widget.isModal
                ? SizedBox(
                    height: 480,
                    child: _buildPageView(),
                  )
                : _buildPageView(),
          ),

          // Bottom Bar: Dots indicator & Primary Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _totalPages,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Button: Next or Done
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _totalPages - 1
                              ? '¡Entendido, vamos a configurar! 🚀'
                              : 'Siguiente',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_currentPage < _totalPages - 1) ...[
                          const SizedBox(width: 8),
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowRight01,
                            color: Colors.white,
                            size: 18,
                          ),
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
        _buildSlide1Growth(),
        _buildSlide2SingleStore(),
        _buildSlide3ClientAppLook(),
      ],
    );
  }

  // -------------------------------------------------------------
  // SLIDE 1: ESTRUCTURA EMPRESARIAL PARA CRECER
  // -------------------------------------------------------------
  Widget _buildSlide1Growth() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          // Icon Illustration Circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedStore01,
                color: Color(0xFF4F46E5),
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Tu Negocio Crece a tu Ritmo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'En Tu Lojita, tu cuenta empresarial está diseñada para soportar tu crecimiento sin límites.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),

          // Visual Architecture Diagram Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Company Box
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedStore01,
                          color: Color(0xFF4F46E5),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🏢 Tu Empresa (Marca Matriz)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'RIF, identidad legal y catálogo maestro',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Arrow down
                const Icon(
                  Icons.arrow_downward_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 10),

                // Branches Grid
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🏪 Sede 1',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ej. Principal',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🏪 Sede 2...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Futura expansión',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 2: ¿SOLO TIENES UNA TIENDA? CERO COMPLICACIONES
  // -------------------------------------------------------------
  Widget _buildSlide2SingleStore() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          // Icon Illustration Circle (Emerald green reassurance)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: Color(0xFF10B981),
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            '¿Tienes una Sola Tienda?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '¡No te preocupes! Todo está preparado para ti.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 20),

          // Reassurance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              children: [
                _buildBulletRow(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  iconColor: const Color(0xFF16A34A),
                  title: 'Tu única tienda es tu Sede Principal',
                  description:
                      'No necesitas configurar cadenas ni estructuras difíciles. Tu tienda opera automáticamente como tu sede central.',
                ),
                const Divider(height: 22, color: Color(0xFFDCFCE7)),
                _buildBulletRow(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  iconColor: const Color(0xFF16A34A),
                  title: 'Nombre pre-rellenado: "Principal"',
                  description:
                      'Ya dejamos el nombre listo en el formulario. Puedes dejarlo así con un solo toque o personalizarlo si prefieres.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 3: CÓMO LO VEN TUS CLIENTES
  // -------------------------------------------------------------
  Widget _buildSlide3ClientAppLook() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          // Icon Illustration Circle (Device / Phone)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSmartPhone01,
                color: Color(0xFF7C3AED),
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Tus Clientes Solo Ven tu Marca',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'En la app de compras, tus clientes nunca verán textos confusos como "Sucursal Principal".',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          // Comparison Preview Cards
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Case 1: 1 Store (Active Now)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TU CASO AHORA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Con 1 sola tienda:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFEEF2FF),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedStore01,
                          color: Color(0xFF4F46E5),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Tu Tienda Comercial',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'El cliente solo ve el nombre de tu empresa ✨',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Case 2: Multi-store in future
                const Text(
                  'Solo si abres 2 o más sedes en el futuro:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFF1F5F9),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedStore01,
                          color: Color(0xFF64748B),
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tu Tienda (Sucursal Chacao / Sede 2)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletRow({
    required dynamic icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: HugeIcon(icon: icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper modal to show the tutorial inside a BottomSheet anytime on demand.
class FirstBranchTutorialBottomSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: FirstBranchTutorialCarousel(
              isModal: true,
              onComplete: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
      },
    );
  }
}
