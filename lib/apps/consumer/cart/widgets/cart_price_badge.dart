import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hoppa/shared/core/services/navigation_provider.dart';
import 'package:hoppa/apps/consumer/cart/cart_provider.dart';

class CartPriceBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const CartPriceBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final totalAmount = context.watch<CartProvider>().totalAmount;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: totalAmount > 0
          ? _AnimatedCounter(totalAmount: totalAmount, onTap: onTap)
          : const SizedBox.shrink(),
    );
  }
}

class _AnimatedCounter extends StatefulWidget {
  final double totalAmount;
  final VoidCallback? onTap;

  const _AnimatedCounter({required this.totalAmount, this.onTap});

  @override
  _AnimatedCounterState createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    // Start with the initial value, don't animate on first build.
    _animation = AlwaysStoppedAnimation<double>(widget.totalAmount);
  }

  @override
  void didUpdateWidget(_AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalAmount != oldWidget.totalAmount) {
      // Create a tween from the old value to the new one.
      _animation = Tween<double>(
        begin: oldWidget.totalAmount,
        end: widget.totalAmount,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      // Start the animation.
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    return GestureDetector(
      onTap: widget.onTap ?? () => navProvider.setIndex(2),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 16,
                  color: theme.colorScheme.onSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  NumberFormat.currency(
                    locale: 'tr_TR',
                    symbol: '₺',
                    decimalDigits: 2,
                  ).format(_animation.value),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
