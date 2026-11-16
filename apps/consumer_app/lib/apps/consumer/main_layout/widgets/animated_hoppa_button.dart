import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';

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

class _AnimatedHoppaButtonState extends State<AnimatedHoppaButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = (screenWidth * 0.18).clamp(62.0, 74.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onLongPress,
      onTap: widget.onTap,
      child: SizedBox(
        width: buttonSize,
        height: 64,
        child: OverflowBox(
          minWidth: 0,
          minHeight: 0,
          maxWidth: buttonSize + 24,
          maxHeight: buttonSize + 24,
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: ClipOval(
              child: Container(
                width: buttonSize,
                height: buttonSize,
                padding: const EdgeInsets.all(4.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFEAD8), Color(0xFFFFCFA8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: HoppaDesignTokens.brandOrange.withValues(
                        alpha: _isPressed ? 0.34 : 0.22,
                      ),
                      blurRadius: _isPressed ? 18 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HoppaBrandMark(
                      size: buttonSize * 0.62,
                      borderRadius: buttonSize * 0.16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
