import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedHoppaButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AnimatedHoppaButton({
    super.key,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<AnimatedHoppaButton> createState() => _AnimatedHoppaButtonState();
}

class _AnimatedHoppaButtonState extends State<AnimatedHoppaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), // Smooth 1.4s rotation
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = (screenWidth * 0.21).clamp(70.0, 92.0);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _glowController.repeat();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _glowController.stop();
        _glowController.value = 0.0;
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _glowController.stop();
        _glowController.value = 0.0;
      },
      onLongPress: widget.onLongPress,
      onTap: widget.onTap,
      child: SizedBox(
        width: buttonSize,
        height: 64,
        child: OverflowBox(
          minWidth: 0,
          minHeight: 0,
          maxWidth: buttonSize + 50,
          maxHeight: buttonSize + 50,
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: _isPressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutBack,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (_isPressed)
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final angle = _glowController.value * 2 * math.pi;
                      final dx = 10 * math.cos(angle);
                      final dy = 10 * math.sin(angle);
                      return Container(
                        width: buttonSize - 8,
                        height: buttonSize - 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FF66).withValues(alpha: 0.45),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: Offset(dx, dy),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF7043).withValues(alpha: 0.45),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: Offset(-dx, -dy),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/hoppa_button.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
