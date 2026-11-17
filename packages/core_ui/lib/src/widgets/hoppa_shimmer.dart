import 'package:flutter/material.dart';
import '../theme/hoppa_design_tokens.dart';

/// Animated shimmer placeholder box adapting automatically to light and dark themes.
class HoppaShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  const HoppaShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<HoppaShimmerBox> createState() => _HoppaShimmerBoxState();
}

class _HoppaShimmerBoxState extends State<HoppaShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? HoppaDesignTokens.surfaceSubtleDark
        : HoppaDesignTokens.borderLight;
    final highlightColor = isDark
        ? HoppaDesignTokens.borderOutdoorDark
        : HoppaDesignTokens.surfaceLight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double slide = (_controller.value * 2) - 1.0;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.2 + slide * 1.5, -0.2),
              end: Alignment(0.2 + slide * 1.5, 0.2),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer loading skeleton matching `ModernProductCard` grid & list layouts.
class HoppaProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final EdgeInsetsGeometry padding;

  const HoppaProductGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? HoppaDesignTokens.surfaceDark
        : HoppaDesignTokens.surfaceLight;
    final borderColor =
        isDark ? HoppaDesignTokens.borderDark : HoppaDesignTokens.borderLight;

    if (crossAxisCount == 1) {
      return Padding(
        padding: padding,
        child: Column(
          children: List.generate(itemCount, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: const Row(
                children: [
                  HoppaShimmerBox(width: 88, height: 88, borderRadius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HoppaShimmerBox(width: 80, height: 12, borderRadius: 6),
                        SizedBox(height: 8),
                        HoppaShimmerBox(height: 16, borderRadius: 6),
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            HoppaShimmerBox(
                              width: 72,
                              height: 18,
                              borderRadius: 6,
                            ),
                            HoppaShimmerBox(
                              width: 34,
                              height: 34,
                              shape: BoxShape.circle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: crossAxisCount == 2 ? 0.69 : 0.62,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: HoppaShimmerBox(borderRadius: 14),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HoppaShimmerBox(
                            width: 64,
                            height: 10,
                            borderRadius: 5,
                          ),
                          SizedBox(height: 6),
                          HoppaShimmerBox(height: 14, borderRadius: 6),
                        ],
                      ),
                      HoppaShimmerBox(width: 70, height: 16, borderRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shimmer card list skeleton for shops, orders, addresses, and courier tasks.
class HoppaListCardSkeleton extends StatelessWidget {
  final int itemCount;
  final double cardHeight;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;

  const HoppaListCardSkeleton({
    super.key,
    this.itemCount = 4,
    this.cardHeight = 108,
    this.padding = const EdgeInsets.all(16),
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? HoppaDesignTokens.surfaceDark
        : HoppaDesignTokens.surfaceLight;
    final borderColor =
        isDark ? HoppaDesignTokens.borderDark : HoppaDesignTokens.borderLight;

    final children = List.generate(itemCount, (index) {
      return Container(
        margin: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(minHeight: cardHeight),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusLg),
          border: Border.all(color: borderColor),
        ),
        child: const Row(
          children: [
            HoppaShimmerBox(width: 56, height: 56, borderRadius: 12),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HoppaShimmerBox(width: 140, height: 14, borderRadius: 6),
                  SizedBox(height: 8),
                  HoppaShimmerBox(height: 12, borderRadius: 6),
                  SizedBox(height: 8),
                  HoppaShimmerBox(width: 96, height: 12, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
      );
    });

    if (shrinkWrap) {
      return Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }

    return ListView(
      padding: padding,
      children: children,
    );
  }
}
