import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoppa/apps/consumer/business/widgets/category_badge.dart';

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
              transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? Colors.black.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: _isPressed ? 8 : 10,
                    offset: Offset(0, _isPressed ? 2 : 4),
                  ),
                ],
                border: widget.isFeatured
                    ? null
                    : Border.all(color: Colors.grey.shade100),
                image: widget.isFeatured && widget.backgroundImage != null
                    ? DecorationImage(
                        image: AssetImage(widget.backgroundImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isClosed ? null : _handleTap,
                  borderRadius: BorderRadius.circular(16),
                  splashColor:
                      (widget.category['color'] as Color?)?.withValues(alpha: 0.2) ??
                      Colors.blue.withValues(alpha: 0.2),
                  highlightColor:
                      (widget.category['color'] as Color?)?.withValues(alpha: 0.1) ??
                      Colors.blue.withValues(alpha: 0.1),
                  child: Stack(
                    children: [
                      // Gradient overlay for featured items
                      if (widget.isFeatured)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),

                      // Closed overlay
                      if (isClosed)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon for non-featured items
                            if (!widget.isFeatured) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (widget.category['color'] as Color)
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.category['icon'] as IconData,
                                  size: 26,
                                  color: widget.category['color'] as Color,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],

                            // Category name
                            Text(
                              catName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: widget.isFeatured ? 22 : 13,
                                color: widget.isFeatured
                                    ? Colors.white
                                    : Colors.black,
                                shadows: widget.isFeatured
                                    ? [
                                        const Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),

                            // Subtitle
                            if (widget.subtitle != null &&
                                !widget.isFeatured) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],

                            // Category info (business count, delivery time)
                            if ((widget.businessCount != null ||
                                    widget.avgDeliveryTime != null) &&
                                !widget.isFeatured) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.businessCount != null) ...[
                                    Icon(
                                      Icons.store,
                                      size: 10,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${widget.businessCount}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                  if (widget.businessCount != null &&
                                      widget.avgDeliveryTime != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Text(
                                        '•',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  if (widget.avgDeliveryTime != null) ...[
                                    Icon(
                                      Icons.access_time,
                                      size: 10,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      widget.avgDeliveryTime!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
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
    );
  }
}
