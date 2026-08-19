import 'package:flutter/material.dart';

class HoppaHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final double curveRadius;

  const HoppaHeader({
    super.key,
    required this.child,
    this.height = 76,
    this.curveRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      height: height + statusBarHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE95D22), // Hoppa Orange
            Color(0xFFFF8C00), // Orange-Yellow
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(curveRadius),
          bottomRight: Radius.circular(curveRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE95D22).withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: statusBarHeight,
        bottom: 8,
      ),
      child: child,
    );
  }
}
