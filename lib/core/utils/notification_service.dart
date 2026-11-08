import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/widgets/premium_snackbar.dart';

class NotificationService {
  static OverlayEntry? _currentEntry;

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, SnackBarType.success);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, SnackBarType.error);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, SnackBarType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, SnackBarType.info);
  }

  static void _show(
    BuildContext context,
    String message,
    SnackBarType type,
  ) {
    _dismissCurrent();

    final overlayState = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);
    if (overlayState == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _OverlayNotificationWidget(
        message: message,
        type: type,
        onDismissed: () {
          if (_currentEntry == entry) {
            _dismissCurrent();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  static void _dismissCurrent() {
    if (_currentEntry != null) {
      _currentEntry?.remove();
      _currentEntry = null;
    }
  }
}

class _OverlayNotificationWidget extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final VoidCallback onDismissed;

  const _OverlayNotificationWidget({
    required this.message,
    required this.type,
    required this.onDismissed,
  });

  @override
  State<_OverlayNotificationWidget> createState() =>
      _OverlayNotificationWidgetState();
}

class _OverlayNotificationWidgetState extends State<_OverlayNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 3), () {
      _dismiss();
    });
  }

  void _dismiss() async {
    _autoDismissTimer?.cancel();
    if (!mounted) return;
    try {
      await _controller.reverse();
    } catch (_) {}
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Positioned(
      bottom: viewInsets.bottom + 16,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: true,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.down,
            onDismissed: (_) => widget.onDismissed(),
            child: SlideTransition(
              position: _offsetAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: PremiumSnackBarContent(
                  message: widget.message,
                  type: widget.type,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
