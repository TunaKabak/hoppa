import 'package:flutter/material.dart';

class HoppaHeader extends StatelessWidget {
  final Widget child;
  final double height;

  const HoppaHeader({
    super.key,
    required this.child,
    this.height = 76,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: height + statusBarHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE95D22), // Hoppa Orange
            Color(0xFFFF8C00), // Orange-Yellow
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: statusBarHeight,
        bottom: 12, // Standard bottom clearance for status-bar aligned content
      ),
      child: child,
    );
  }
}
