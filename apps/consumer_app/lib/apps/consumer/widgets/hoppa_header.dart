import 'package:flutter/material.dart';

class ConcaveHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    // Draw a quadratic Bezier curve to arch the bottom inwards in the center (Concave)
    path.quadraticBezierTo(
      size.width / 2,
      size.height - 18, // Curves upwards in the center by 18px
      size.width,
      size.height,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

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

    return ClipPath(
      clipper: ConcaveHeaderClipper(),
      child: Container(
        height: height + statusBarHeight,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE95D22), // Hoppa Orange
              Color(0xFFFF8C00), // Orange-Yellow
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.only(
          top: statusBarHeight,
          bottom: 18, // Account for the concave curve bottom clearance
        ),
        child: child,
      ),
    );
  }
}
