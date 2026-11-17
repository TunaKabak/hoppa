import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/hoppa_design_tokens.dart';

/// Vector Hoppa Brand Emblem ("H" + smile arc + emerald shooting star).
class HoppaBrandMark extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showBackground;
  final Color? foregroundColor;

  const HoppaBrandMark({
    super.key,
    this.size = 44,
    this.borderRadius = 12,
    this.showBackground = true,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HoppaBrandMarkPainter(
          borderRadius: borderRadius,
          showBackground: showBackground,
          foregroundColor: foregroundColor,
        ),
      ),
    );
  }
}

class _HoppaBrandMarkPainter extends CustomPainter {
  final double borderRadius;
  final bool showBackground;
  final Color? foregroundColor;

  const _HoppaBrandMarkPainter({
    required this.borderRadius,
    required this.showBackground,
    this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final scale = s / 64.0;

    if (showBackground) {
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, s, s),
        Radius.circular(borderRadius),
      );
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFF7A1A),
            HoppaDesignTokens.brandOrange,
            HoppaDesignTokens.brandOrangeHover,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, s, s));
      canvas.drawRRect(bgRect, bgPaint);
    }

    canvas.save();
    canvas.scale(scale, scale);

    final fg = foregroundColor ??
        (showBackground ? Colors.white : HoppaDesignTokens.brandOrange);
    final fgPaint = Paint()
      ..color = fg
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16.5, 14, 6.2, 29.5),
        const Radius.circular(3.1),
      ),
      fgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(37.3, 14, 6.2, 29.5),
        const Radius.circular(3.1),
      ),
      fgPaint,
    );
    canvas.drawRect(const Rect.fromLTWH(21, 26.8, 18, 5.8), fgPaint);

    final smileColor = foregroundColor ??
        (showBackground ? Colors.white : HoppaDesignTokens.brandGreen);
    final smilePaint = Paint()
      ..color = smileColor
      ..style = PaintingStyle.fill;
    final smilePath = Path()
      ..moveTo(16.2, 46.0)
      ..quadraticBezierTo(29.5, 53.6, 43.2, 48.0)
      ..quadraticBezierTo(44.6, 47.4, 43.6, 49.4)
      ..quadraticBezierTo(29.2, 59.0, 15.2, 48.2)
      ..close();
    canvas.drawPath(smilePath, smilePaint);

    final starFill = foregroundColor ?? HoppaDesignTokens.brandGreen;
    final starPath = _createStarPath(const Offset(47.2, 16.5), 7.6, 3.4);
    if (showBackground && foregroundColor == null) {
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(starPath, strokePaint);
    }
    canvas.drawPath(
      starPath,
      Paint()
        ..color = starFill
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  Path _createStarPath(Offset center, double outerR, double innerR) {
    final path = Path();
    const points = 5;
    const startAngle = -math.pi / 2;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = startAngle + (i * math.pi / points);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HoppaBrandMarkPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.showBackground != showBackground ||
      oldDelegate.foregroundColor != foregroundColor;
}

/// Crisp Vector Hoppa Horizontal Logo Lockup (Emblem + Geometric Wordmark + Optional Role Pill).
class HoppaBrandLogo extends StatelessWidget {
  final double height;
  final bool isDark;
  final Color? monochromeColor;
  final String? badgeLabel;

  const HoppaBrandLogo({
    super.key,
    this.height = 44,
    this.isDark = false,
    this.monochromeColor,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final markSize = height;
    final fontSize = height * 0.62;
    final textColor = monochromeColor ??
        (isDark ? Colors.white : HoppaDesignTokens.brandOrange);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HoppaBrandMark(
          size: markSize,
          borderRadius: markSize * 0.26,
          showBackground: monochromeColor == null,
          foregroundColor: monochromeColor,
        ),
        SizedBox(width: markSize * 0.24),
        Text(
          'Hoppa',
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.8,
            height: 1.0,
          ),
        ),
        if (badgeLabel != null && badgeLabel!.isNotEmpty) ...[
          SizedBox(width: markSize * 0.2),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: markSize * 0.18,
              vertical: markSize * 0.08,
            ),
            decoration: BoxDecoration(
              color: monochromeColor != null
                  ? monochromeColor!.withValues(alpha: 0.16)
                  : HoppaDesignTokens.brandOrangeTint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: monochromeColor != null
                    ? monochromeColor!.withValues(alpha: 0.35)
                    : HoppaDesignTokens.brandOrange.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              badgeLabel!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: (height * 0.23).clamp(9.5, 13.0),
                fontWeight: FontWeight.w700,
                color: monochromeColor ?? HoppaDesignTokens.brandOrangeHover,
                letterSpacing: 0.4,
                height: 1.1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Fintech Vector Card Network Badge (replaces emoji card brand indicators).
class HoppaPaymentBadge extends StatelessWidget {
  final String brand;
  final bool compact;

  const HoppaPaymentBadge({
    super.key,
    required this.brand,
    this.compact = false,
  });

  /// Detects payment card network cleanly without emojis.
  static String detectBrand(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.length >= 6) {
      final bin = cleanNumber.substring(0, 6);
      if (['454360', '543771', '402235'].contains(bin)) {
        return 'CardPlus';
      } else if (['432042', '516888', '540061'].contains(bin)) {
        return 'PayTR';
      } else if (cleanNumber.startsWith('4')) {
        return 'Visa';
      } else if (cleanNumber.startsWith('5')) {
        return 'Mastercard';
      } else if (cleanNumber.startsWith('9792')) {
        return 'Troy';
      }
      return 'Kart';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final normalized = brand.trim().toLowerCase();
    if (normalized.isEmpty) return const SizedBox.shrink();

    if (normalized.contains('master')) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: compact ? 18 : 22,
              height: compact ? 12 : 14,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: Container(
                      width: compact ? 11 : 13,
                      height: compact ? 11 : 13,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEB001B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: compact ? 11 : 13,
                      height: compact ? 11 : 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF79E1B).withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 5),
              Text(
                'Mastercard',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Color bg = HoppaDesignTokens.surfaceSubtleLight;
    Color fg = HoppaDesignTokens.textPrimaryLight;
    Color border = HoppaDesignTokens.borderLight;
    String label = brand;

    if (normalized.contains('visa')) {
      bg = const Color(0xFF1A1F71);
      fg = Colors.white;
      border = const Color(0xFF1A1F71);
      label = 'VISA';
    } else if (normalized.contains('troy')) {
      bg = const Color(0xFF009FE3);
      fg = Colors.white;
      border = const Color(0xFF009FE3);
      label = 'TROY';
    } else if (normalized.contains('cardplus')) {
      bg = HoppaDesignTokens.brandOrangeTint;
      fg = HoppaDesignTokens.brandOrangeHover;
      border = HoppaDesignTokens.brandOrange.withValues(alpha: 0.35);
      label = 'CardPlus';
    } else if (normalized.contains('paytr')) {
      bg = const Color(0xFF0F172A);
      fg = Colors.white;
      border = const Color(0xFF0F172A);
      label = 'PAYTR';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (normalized == 'kart') ...[
            Icon(Icons.credit_card_rounded, size: compact ? 12 : 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: fg,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing:
                  normalized == 'visa' || normalized == 'troy' ? 0.6 : 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
