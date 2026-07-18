import 'dart:io';
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
    if (localFile != null) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(8)),
          border: border,
          boxShadow: boxShadow,
          image: DecorationImage(
            image: FileImage(localFile!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final hasImage = imageUrl != null &&
        imageUrl!.trim().isNotEmpty &&
        imageUrl!.startsWith('http') &&
        !imageUrl!.toLowerCase().contains('placeholder');
    if (hasImage) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(8)),
          border: border,
          boxShadow: boxShadow,
          image: DecorationImage(
            image: NetworkImage(imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Modern Premium Gradient Initials Fallback
    final initial = shopName.isNotEmpty ? shopName[0].toUpperCase() : 'H';
    
    // Choose a stable gradient based on the shop's name hash
    final hash = shopName.hashCode;
    final List<Color> colors = hash % 3 == 0
        ? [const Color(0xFFE95D22), const Color(0xFFFF8C00)] // Orange gradient
        : hash % 3 == 1
            ? [const Color(0xFF00A651), const Color(0xFF007A3E)] // Green gradient
            : [const Color(0xFF2979FF), const Color(0xFF1565C0)]; // Blue gradient

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(8)),
        border: border,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: radius * 0.9,
            fontWeight: FontWeight.bold,
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

    final hasImage = imageUrl != null &&
        imageUrl!.trim().isNotEmpty &&
        imageUrl!.startsWith('http') &&
        !imageUrl!.toLowerCase().contains('placeholder');
    if (hasImage) {
      return Image.network(
        imageUrl!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildAbstractGradientHeader(),
      );
    }

    return _buildAbstractGradientHeader();
  }

  Widget _buildAbstractGradientHeader() {
    final hash = shopName.hashCode;
    final List<Color> colors = hash % 3 == 0
        ? [const Color(0xFFFFF3EE), const Color(0xFFFFE0D3)] // Soft Warm gradient
        : hash % 3 == 1
            ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)] // Soft Green gradient
            : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)]; // Soft Blue gradient

    final primaryColor = hash % 3 == 0
        ? const Color(0xFFE95D22)
        : hash % 3 == 1
            ? const Color(0xFF00A651)
            : const Color(0xFF2979FF);

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
          // Subtle decorative shapes
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
                style: GoogleFonts.poppins(
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
