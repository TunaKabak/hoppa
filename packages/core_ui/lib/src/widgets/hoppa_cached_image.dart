import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/hoppa_design_tokens.dart';
import 'hoppa_shimmer.dart';

/// Cached network image with placeholder shimmer and safe broken/placeholder URL handling.
class HoppaCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackColor;

  const HoppaCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.storefront_rounded,
    this.fallbackColor,
  });

  static bool isValidRemoteUrl(String? raw) {
    if (raw == null) return false;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return false;
    }
    if (lower.contains('via.placeholder.com') || lower.contains('placeholder')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = isValidRemoteUrl(imageUrl) ? imageUrl!.trim() : null;
    final radius = borderRadius ?? BorderRadius.zero;

    if (cleanUrl == null) {
      return ClipRRect(
        borderRadius: radius,
        child: _buildFallback(context),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: cleanUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, _) => HoppaShimmerBox(
          width: width,
          height: height,
          borderRadius: 0,
        ),
        errorWidget: (context, _, __) => _buildFallback(context),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? HoppaDesignTokens.surfaceSubtleDark
        : HoppaDesignTokens.surfaceSubtleLight;
    final iconColor = fallbackColor ??
        (isDark
            ? HoppaDesignTokens.textSecondaryDark
            : HoppaDesignTokens.textMutedLight);

    return Container(
      width: width,
      height: height,
      color: bgColor,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: iconColor,
        size: 32,
      ),
    );
  }
}
