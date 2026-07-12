import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:consumer_app/apps/consumer/auth/consumer_auth_wrapper.dart';
import 'package:http/http.dart' as http;

// Splash ekranının olası durumları (Flutter'ın ConnectionState sınıfı ile çakışmaması için SplashConnectionState adını kullanıyoruz)
enum SplashConnectionState { loading, offline, serverDown }

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  SplashConnectionState _currentState = SplashConnectionState.loading;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startSystemChecks();
  }

  // Tüm ağ ve sistem kontrollerini başlatır
  Future<void> _startSystemChecks() async {
    if (_isRetrying && _currentState == SplashConnectionState.loading) return;

    setState(() {
      _currentState = SplashConnectionState.loading;
      _isRetrying = true;
    });

    final startTime = DateTime.now();

    // 1. Adım: Cihazın internet bağlantısı var mı? (Hızlı DNS Sorgusu)
    final hasInternet = await _checkPhysicalConnection();
    if (!hasInternet) {
      _setSplashState(SplashConnectionState.offline);
      return;
    }

    // 2. Adım: Hoppa Backend & Supabase Sağlıklı mı?
    final isServerUp = await _checkServerHealth();
    if (!isServerUp) {
      _setSplashState(SplashConnectionState.serverDown);
      return;
    }

    // 3. Adım: Her şey yolundaysa minimum bekleme süresini (2 saniye) tamamla ve uygulamaya geçiş yap
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(seconds: 2);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    _proceedToApp();
  }

  // Fiziksel internet kontrolü
  Future<bool> _checkPhysicalConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // API Sağlık Kontrolü (Hoppa Health Endpoint)
  Future<bool> _checkServerHealth() async {
    try {
      // API_URL çevre değişkeninizden veya config'den okunmalıdır
      final baseUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:3000';
      final url = Uri.parse("$baseUrl/api/public/health");

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 5),
          ); // 5 saniye içinde cevap gelmelidir

      return response.statusCode == 200;
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
      HapticFeedback.mediumImpact(); // Hafif/orta titreşim uyarısı
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

    return Scaffold(
      backgroundColor:
          theme.colorScheme.secondary, // Marka ana turuncusu (vurgu)
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBodyForState(theme),
        ),
      ),
    );
  }

  Widget _buildBodyForState(ThemeData theme) {
    switch (_currentState) {
      // 1. DURUM: Sistem Yükleniyor (Standart Splash)
      case SplashConnectionState.loading:
        return Center(
          key: const ValueKey('loading'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo_white.png',
                width: 140,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/hoppa_icon.png',
                  width: 140,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.shopping_basket_rounded,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Şık Beyaz Yükleme Çemberi
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        );

      // 2. DURUM: Cihaz Çevrimdışı (No Internet)
      case SplashConnectionState.offline:
        return _buildErrorStateUI(
          key: const ValueKey('offline'),
          icon: Icons.wifi_off_rounded,
          title: "İnternet Bağlantısı Yok",
          description:
              "Hoppa ile lezzetli anlara ulaşabilmek için aktif bir internet bağlantınızın olması gerekir. Lütfen ayarlarınızı kontrol edip tekrar deneyiniz.",
          buttonText: "Tekrar Dene",
          theme: theme,
        );

      // 3. DURUM: Sunucu Kapalı veya Bakımda (Server Down)
      case SplashConnectionState.serverDown:
        return _buildErrorStateUI(
          key: const ValueKey('server_down'),
          icon: Icons.cloud_off_rounded,
          title: "Size Daha İyi Hizmet Verebilmek İçin Bakımdayız",
          description:
              "Sistemlerimizi güncelliyor ve sizin için Hoppa'yı daha hızlı hale getiriyoruz. Kısa süre sonra tekrar yanınızda olacağız.",
          buttonText: "Yeniden Dene",
          theme: theme,
        );
    }
  }

  // Kurumsal Hata Pencerelerini Çizen Şablon Widget
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
          // Şık Hata İllüstrasyonu (İkonlu)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: Colors.white),
          ),
          const SizedBox(height: 32),

          // Kurumsal Başlık
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Sakinleştirici Açıklama Metni
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),

          // İnteraktif Yeniden Dene Butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.secondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                _startSystemChecks();
              },
              child: Text(
                buttonText,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
