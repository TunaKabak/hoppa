import 'package:flutter/material.dart';

/// Consumer'a özel sepete ekleme animasyonu.
/// Ürün eklendiğinde sepet ikonuna "zıplama" ve "parlama" efekti uygular.
class CartAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAnimationComplete;

  const CartAnimation({
    super.key,
    required this.child,
    this.onAnimationComplete,
  });

  @override
  State<CartAnimation> createState() => CartAnimationState();
}

class CartAnimationState extends State<CartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  /// Dışarıdan tetiklenebilir animasyon.
  void trigger() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (_glowAnimation.value > 0)
                  BoxShadow(
                    color: colorScheme.primary.withValues(
                      alpha: _glowAnimation.value * 0.5,
                    ),
                    blurRadius: 16 * _glowAnimation.value,
                    spreadRadius: 4 * _glowAnimation.value,
                  ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
