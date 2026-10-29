import 'package:flutter/material.dart';

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  const ShimmerWidget.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        shape = BoxShape.circle,
        borderRadius = null;

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? (widget.borderRadius ?? BorderRadius.circular(8))
                : null,
            gradient: LinearGradient(
              begin: Alignment(-1.5 + _controller.value * 3.0, -0.3),
              end: Alignment(0.5 + _controller.value * 3.0, 0.3),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
                Color(0xFFCBD5E1),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.0, 0.35, 0.65, 1.0],
            ),
          ),
        );
      },
    );
  }
}
