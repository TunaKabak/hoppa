import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:consumer_app/apps/consumer/business/widgets/category_badge.dart';

class CategoryGridItem extends StatefulWidget {
  final Map<String, dynamic> category;
  final bool isFeatured;
  final String? backgroundImage;
  final VoidCallback onTap;
  final String? badge; // "new", "popular", "promo", "closed"
  final int? businessCount;
  final String? avgDeliveryTime;
  final String? subtitle;
  final int index; // for staggered animation

  const CategoryGridItem({
    super.key,
    required this.category,
    required this.isFeatured,
    this.backgroundImage,
    required this.onTap,
    this.badge,
    this.businessCount,
    this.avgDeliveryTime,
    this.subtitle,
    this.index = 0,
  });

  @override
  State<CategoryGridItem> createState() => _CategoryGridItemState();
}

class _CategoryGridItemState extends State<CategoryGridItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Staggered entrance animation
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final catName = widget.category['name'] as String;
    final isClosed =
        widget.badge?.toLowerCase() == 'closed' ||
        widget.badge?.toLowerCase() == 'kapalı';
    final catColor = widget.category['color'] as Color? ?? Colors.green;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: isClosed ? null : _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.diagonal3Values(_isPressed ? 0.95 : 1.0, _isPressed ? 0.95 : 1.0, 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: catColor.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    catColor.withValues(alpha: 0.06),
                    catColor.withValues(alpha: 0.15),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: catColor.withValues(alpha: _isPressed ? 0.08 : 0.04),
                    blurRadius: _isPressed ? 12 : 8,
                    offset: Offset(0, _isPressed ? 4 : 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isClosed ? null : _handleTap,
                    borderRadius: BorderRadius.circular(18),
                    splashColor: catColor.withValues(alpha: 0.2),
                    highlightColor: catColor.withValues(alpha: 0.1),
                    child: Stack(
                      children: [
                        // Background image or icon fallback positioned in the bottom-right corner
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: widget.backgroundImage != null
                              ? ShaderMask(
                                  shaderCallback: (bounds) {
                                    return RadialGradient(
                                      center: Alignment.bottomRight,
                                      radius: 1.1,
                                      colors: [
                                        Colors.black,
                                        Colors.black.withValues(alpha: 0.95),
                                        Colors.black.withValues(alpha: 0.2),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.4, 0.8, 1.0],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: widget.backgroundImage!.startsWith('http')
                                      ? Image.network(
                                          widget.backgroundImage!,
                                          width: 82,
                                          height: 82,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Icon(
                                                  widget.category['icon'] as IconData,
                                                  size: 64,
                                                  color: catColor.withValues(alpha: 0.15),
                                                ),
                                              ),
                                        )
                                      : Image.asset(
                                          widget.backgroundImage!,
                                          width: 82,
                                          height: 82,
                                          fit: BoxFit.contain,
                                        ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    widget.category['icon'] as IconData,
                                    size: 64,
                                    color: catColor.withValues(alpha: 0.15),
                                  ),
                                ),
                        ),

                        // Content on the left
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    catName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (widget.subtitle != null) ...[
                                    const SizedBox(height: 3),
                                    SizedBox(
                                      width: 95, // Limit text width to prevent overlap with the image on the right
                                      child: Text(
                                        widget.subtitle!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              
                              // Average delivery time badge
                              if (widget.avgDeliveryTime != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: catColor.withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_filled_rounded,
                                        size: 10,
                                        color: catColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.avgDeliveryTime!,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Closed overlay
                        if (isClosed)
                          Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            child: const Center(
                              child: Icon(
                                Icons.do_not_disturb_on_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),

                        // Badge
                        if (widget.badge != null)
                          CategoryBadge(badgeType: widget.badge!),
                      ],
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
