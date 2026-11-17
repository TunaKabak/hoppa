import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;
  final Widget? bottomSheet;
  final bool showAppBar;
  final Widget? leading;
  final List<Widget>? actions;
  final bool enableGlass;
  final bool showTrustFooter;

  const AuthLayout({
    super.key,
    required this.child,
    this.bottomSheet,
    this.showAppBar = true,
    this.leading,
    this.actions,
    this.enableGlass = false,
    this.showTrustFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? HoppaDesignTokens.canvasDark : HoppaDesignTokens.canvasLight;
    final cardSurface =
        isDark ? HoppaDesignTokens.surfaceDark : HoppaDesignTokens.surfaceLight;
    final cardBorder =
        isDark ? HoppaDesignTokens.borderDark : HoppaDesignTokens.borderLight;

    return Scaffold(
      backgroundColor: scaffoldBg,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              leadingWidth: 64,
              leading: leading != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 14, top: 6, bottom: 6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cardSurface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Center(child: leading),
                      ),
                    )
                  : null,
              actions: actions,
            )
          : null,
      body: Stack(
        children: [
          // Marka ambiyans gradyanı (Yeşil & Turuncu soft üst hale)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HoppaDesignTokens.brandGreen
                          .withValues(alpha: isDark ? 0.14 : 0.12),
                      HoppaDesignTokens.brandOrange
                          .withValues(alpha: isDark ? 0.10 : 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minHeight =
                    (constraints.maxHeight - 24).clamp(0.0, double.infinity);
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RepaintBoundary(
                              child: enableGlass
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 28,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardSurface,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: cardBorder),
                                        boxShadow: isDark
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: const Color(0xFF0F172A)
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 28,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                      ),
                                      child: child,
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      child: child,
                                    ),
                            ),
                            if (showTrustFooter) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 14,
                                    color: isDark
                                        ? HoppaDesignTokens.textMutedDark
                                        : HoppaDesignTokens.textMutedLight,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '256-bit Şifreli • Güvenli OTP Doğrulama',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? HoppaDesignTokens.textMutedDark
                                          : HoppaDesignTokens.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: bottomSheet,
    );
  }
}
