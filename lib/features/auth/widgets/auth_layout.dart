import 'dart:ui';
import 'package:flutter/material.dart';

class AuthLayout extends StatefulWidget {
  final Widget child;
  final Widget? bottomSheet;
  final bool showAppBar;
  final Widget? leading;
  final bool enableGlass;

  const AuthLayout({
    super.key,
    required this.child,
    this.bottomSheet,
    this.showAppBar = true,
    this.leading,
    this.enableGlass = false,
  });

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _showSmallLogo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.showAppBar) {
      _scrollController.addListener(_scrollListener);
    }
  }

  void _scrollListener() {
    if (_scrollController.offset > 100 && !_showSmallLogo) {
      setState(() => _showSmallLogo = true);
    } else if (_scrollController.offset <= 100 && _showSmallLogo) {
      setState(() => _showSmallLogo = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;
    if (bottomInset == 0) {
      // Keyboard closed, scroll to top slightly deferred
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: _showSmallLogo
                  ? Colors.white.withOpacity(0.9)
                  : Colors.transparent,
              elevation: _showSmallLogo ? 1 : 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              leading: widget.leading,
              title: AnimatedOpacity(
                opacity: _showSmallLogo ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Image.asset(
                  'assets/images/hoppa_logo.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          // 1. Background Image (Full Cover)
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.white),
            ),
          ),

          // 2. Blur / Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.7),
                      Colors.white.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Center(
              child: widget.enableGlass
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: 24,
                              bottom: 24 + bottomInset,
                            ),
                            child: widget.child,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 24,
                        bottom: 24 + bottomInset,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: widget.child,
                      ),
                    ),
            ),
          ),
        ],
      ),
      bottomSheet: widget.bottomSheet != null
          ? Container(color: Colors.transparent, child: widget.bottomSheet)
          : null,
    );
  }
}
