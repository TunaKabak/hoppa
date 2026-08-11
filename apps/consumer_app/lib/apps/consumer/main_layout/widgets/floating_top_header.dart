import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FloatingTopHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onLocationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  final bool isCollapsed;

  const FloatingTopHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onLocationTap,
    this.onSearchTap,
    this.onProfileTap,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      top: topPadding + (isCollapsed ? 8 : 12),
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        height: isCollapsed ? 50 : 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isCollapsed ? 0.12 : 0.06),
              blurRadius: isCollapsed ? 18 : 12,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isCollapsed ? 16 : 10,
              sigmaY: isCollapsed ? 16 : 10,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E).withValues(alpha: 0.88)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // Location Pin / Header Icon
                  GestureDetector(
                    onTap: onLocationTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE95D22).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFE95D22),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title & Subtitle
                  Expanded(
                    child: GestureDetector(
                      onTap: onLocationTap,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: GoogleFonts.outfit(
                                    fontSize: isCollapsed ? 13 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: Color(0xFFE95D22),
                              ),
                            ],
                          ),
                          if (subtitle != null && !isCollapsed)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Search Action
                  if (onSearchTap != null)
                    IconButton(
                      icon: const Icon(Icons.search_rounded, size: 22),
                      onPressed: onSearchTap,
                      color: isDark ? Colors.white70 : Colors.black54,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                  // Profile Action
                  if (onProfileTap != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onProfileTap,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: Color(0xFFE95D22),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
