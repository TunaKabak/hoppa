import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_shared/core_shared.dart';
import 'package:core_ui/core_ui.dart';
import 'package:consumer_app/apps/consumer/auth/consumer_auth_wrapper.dart';
import 'package:http/http.dart' as http;

// Splash ekranının olası durumları (Flutter'ın ConnectionState sınıfı ile çakışmaması için SplashConnectionState adını kullanıyoruz)
enum SplashConnectionState { loading, offline, serverDown }

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  SplashConnectionState _currentState = SplashConnectionState.loading;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startSystemChecks();
  }

  Future<void> _startSystemChecks() async {
    if (_isRetrying && _currentState == SplashConnectionState.loading) return;

    setState(() {
      _currentState = SplashConnectionState.loading;
      _isRetrying = true;
    });

    final startTime = DateTime.now();

    // 1. Adım: Cihazın internet bağlantısı var mı?
    final hasInternet = await _checkPhysicalConnection();
    if (!hasInternet) {
      _setSplashState(SplashConnectionState.offline);
      return;
    }

    // 2. Adım: Hoppa Backend sağlıklı mı? (apiClientProvider URL üzerinden okunur, prod'da .env gerektirmez)
    final isServerUp = await _checkServerHealth();
    if (!isServerUp) {
      _setSplashState(SplashConnectionState.serverDown);
      return;
    }

    // 3. Minimum görsel geçiş süresi (1.5s)
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(milliseconds: 1500);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    _proceedToApp();
  }

  Future<bool> _checkPhysicalConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'hoppa-backend.onrender.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 4));
        return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> _checkServerHealth() async {
    try {
      final baseUrl = ref.read(apiClientProvider).baseUrl.replaceAll(RegExp(r'/+$'), '');
      final url = Uri.parse('$baseUrl/api/public/health');

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return true;
      }

      // Render cold-start / routing fallback için /health uç noktasını da dene
      final rootHealthUrl = Uri.parse('$baseUrl/health');
      final fallbackRes = await http
          .get(rootHealthUrl)
          .timeout(const Duration(seconds: 8));
      return fallbackRes.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _setSplashState(SplashConnectionState state) {
    if (mounted) {
      setState(() {
        _currentState = state;
        _isRetrying = false;
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _proceedToApp() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConsumerAuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = _currentState == SplashConnectionState.loading;

    return Scaffold(
      backgroundColor: isLoading
          ? theme.scaffoldBackgroundColor
          : (isDark ? HoppaDesignTokens.surfaceDark : HoppaDesignTokens.brandOrange),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBodyForState(theme, isDark),
        ),
      ),
    );
  }

  Widget _buildBodyForState(ThemeData theme, bool isDark) {
    switch (_currentState) {
      case SplashConnectionState.loading:
        return Center(
          key: const ValueKey('loading'),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const HoppaBrandLogo(height: 58),
              const SizedBox(height: 20),
              Text(
                'Hoppa: Siparişin en kısa yolu.',
                style: GoogleFonts.plusJakartaSans(
                  color: isDark
                      ? HoppaDesignTokens.textSecondaryDark
                      : HoppaDesignTokens.textSecondaryLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 48.0, left: 80.0, right: 80.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        color: HoppaDesignTokens.brandGreen,
                        backgroundColor: isDark
                            ? HoppaDesignTokens.borderDark
                            : HoppaDesignTokens.borderLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bağlantı doğrulanıyor...',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark
                            ? HoppaDesignTokens.textMutedDark
                            : HoppaDesignTokens.textMutedLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case SplashConnectionState.offline:
        return _buildErrorStateUI(
          key: const ValueKey('offline'),
          icon: Icons.wifi_off_rounded,
          title: 'İnternet Bağlantısı Yok',
          description:
              'Hoppa ile hızlı siparişe ulaşabilmek için aktif internet bağlantınız olmalıdır. Lütfen bağlantınızı kontrol edip tekrar deneyin.',
          buttonText: 'Tekrar Dene',
          theme: theme,
        );

      case SplashConnectionState.serverDown:
        return _buildErrorStateUI(
          key: const ValueKey('server_down'),
          icon: Icons.cloud_off_rounded,
          title: 'Sunuculara Ulaşılıyor...',
          description:
              'Sistem kısa süreli bir uyanma veya bakım sürecinde olabilir. Birkaç saniye içinde tekrar bağlanmayı deneyebilirsiniz.',
          buttonText: 'Yeniden Dene',
          theme: theme,
        );
    }
  }

  Widget _buildErrorStateUI({
    required Key key,
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required ThemeData theme,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 68, color: Colors.white),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: HoppaDesignTokens.brandOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _startSystemChecks,
              child: Text(
                buttonText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
