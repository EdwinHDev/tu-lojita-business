import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_item.dart';
import 'onboarding_slide.dart';

class OnboardingCarousel extends StatefulWidget {
  final List<OnboardingItem> items;

  const OnboardingCarousel({
    super.key,
    required this.items,
  });

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingSlide(item: widget.items[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildIndicators(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.items.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _currentIndex == index ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentIndex == index
                ? Theme.of(context).primaryColor
                : const Color(0xFFC7D2FE),
          ),
        ),
      ),
    );
  }
}
