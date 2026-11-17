import 'dart:io';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumLogoView extends StatelessWidget {
  final String? imageUrl;
  final File? localFile;
  final String shopName;
  final double radius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const PremiumLogoView({
    super.key,
    required this.imageUrl,
    this.localFile,
    required this.shopName,
    this.radius = 40,
    this.border,
    this.boxShadow,
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(8));

    if (localFile != null) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: effectiveBorderRadius,
          border: border,
          boxShadow: boxShadow,
          image: DecorationImage(
            image: FileImage(localFile!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (HoppaCachedImage.isValidRemoteUrl(imageUrl)) {
      final diameter = radius * 2;
      final child = HoppaCachedImage(
        imageUrl: imageUrl,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        fallbackIcon: Icons.storefront_rounded,
      );
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: effectiveBorderRadius,
          border: border,
          boxShadow: boxShadow,
        ),
        child: shape == BoxShape.circle
            ? ClipOval(child: child)
            : ClipRRect(
                borderRadius: effectiveBorderRadius ?? BorderRadius.zero,
                child: child,
              ),
      );
    }

    final initial = shopName.isNotEmpty ? shopName[0].toUpperCase() : 'H';
    final hash = shopName.hashCode;
    final List<Color> colors = hash % 3 == 0
        ? [const Color(0xFFFF7A1A), HoppaDesignTokens.brandOrange]
        : hash % 3 == 1
            ? [HoppaDesignTokens.brandGreen, HoppaDesignTokens.brandGreenHover]
            : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)];

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: effectiveBorderRadius,
        border: border,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: radius * 0.9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class PremiumHeaderView extends StatelessWidget {
  final String? imageUrl;
  final File? localFile;
  final String shopName;
  final double height;
  final double width;
  final BoxFit fit;

  const PremiumHeaderView({
    super.key,
    required this.imageUrl,
    this.localFile,
    required this.shopName,
    this.height = 120,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (localFile != null) {
      return Image.file(
        localFile!,
        fit: fit,
        width: width,
        height: height,
      );
    }

    if (HoppaCachedImage.isValidRemoteUrl(imageUrl)) {
      return HoppaCachedImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        fallbackIcon: Icons.storefront_rounded,
      );
    }

    return _buildAbstractGradientHeader();
  }

  Widget _buildAbstractGradientHeader() {
    final hash = shopName.hashCode;
    final List<Color> colors = hash % 3 == 0
        ? [HoppaDesignTokens.brandOrangeTint, const Color(0xFFFFE0D3)]
        : hash % 3 == 1
            ? [HoppaDesignTokens.brandGreenTint, const Color(0xFFC8E6C9)]
            : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)];

    final primaryColor = hash % 3 == 0
        ? HoppaDesignTokens.brandOrange
        : hash % 3 == 1
            ? HoppaDesignTokens.brandGreen
            : const Color(0xFF2563EB);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.storefront_rounded,
                size: height * 1.2,
                color: primaryColor,
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.bubble_chart_rounded,
                size: height * 0.5,
                color: primaryColor,
              ),
            ),
          ),
          Center(
            child: Opacity(
              opacity: 0.35,
              child: Text(
                shopName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: height * 0.16,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
