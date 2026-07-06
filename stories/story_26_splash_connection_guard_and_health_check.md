Story 26 - Bağlantı Koruyucu ve Sunucu Sağlık Kontrolü (Splash Connection Guard)

Bu görev belgesi; Hoppa mobil uygulamalarının açılışında (Splash Screen) kullanıcının internet bağlantısını ve backend sunucusunun (dolayısıyla Supabase veritabanının) aktiflik durumunu doğrulamayı; bir kesinti anında kullanıcıyı şık, kurumsal ve interaktif hata pencereleriyle yönlendirerek çökmeleri sıfırlamayı amaçlar.

🧭 1. BÖLÜM: Sistem Akış Diyagramı (System Flowchart)

       [Uygulama Açılır (Splash Screen)]
                       │
                       ▼
         [1. İnternet Bağlantı Kontrolü]
                       ├─── (Yok) ───► [Görsel: Çevrimdışı Ekranı] ──► [Yeniden Dene]
                       │
                       ▼ (Var)
        [2. Sunucu Sağlık Kontrolü (GET /api/health)]
                       ├─── (Hata/Timeout) ───► [Görsel: Bakım Ekranı] ──► [Yeniden Dene]
                       │
                       ▼ (Aktif/UP)
         [Yetkilendirme (Auth) Kontrolü] ──► [Login veya Anasayfa]


🛠️ 2. BÖLÜM: Backend Katmanı (Health Check API)

Sunucunun ve Supabase veritabanı bağlantısının anlık durumunu ölçen, son derece hafif ve hızlı çalışan yeni bir sağlık kontrolü endpoint'i tasarlıyoruz.

A. Sağlık Kontrolörü ve Rota Entegrasyonu (HealthController.ts)

// backend/src/controllers/HealthController.ts

import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class HealthController {
  
  /**
   * Sunucu ve Supabase Veritabanı Sağlık Durumunu Kontrol Eder
   * GET /api/public/health
   */
  public static async checkHealth(req: Request, res: Response): Promise<void> {
    try {
      // 🚨 Supabase / PostgreSQL bağlantısını en hafif SQL sorgusuyla test et
      await prisma.$queryRaw`SELECT 1`;

      res.status(200).json({
        error: false,
        status: "UP",
        database: "CONNECTED",
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      console.error("🚨 Sunucu Sağlık Kontrolü Başarısız:", error);
      
      res.status(503).json({
        error: true,
        status: "DOWN",
        database: "DISCONNECTED",
        message: "Veritabanı bağlantısı kurulamadı."
      });
    }
  }
}


B. Rotanın Tanımlanması (publicRoutes.ts)

Yetkilendirme (Auth/JWT) filtrelerine takılmadan herkesin erişebileceği kamuya açık rotalar dosyasına ekleyin:

GET /api/public/health -> HealthController.checkHealth

📱 3. BÖLÜM: Tüketici Uygulaması (Flutter Splash Screen Redesign)

Açılış ekranımızı dinamik bir Durum Makinesine (State Machine) çevirerek internet kopukluklarını ve sunucu çökmelerini yönetiyoruz.

A. Splash Ekranı Durum Yönetimi ve UI Kod Bloğu (splash_page.dart)

// apps/consumer_app/lib/screens/splash/splash_page.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Splash ekranının olası durumları
enum ConnectionState { loading, offline, serverDown }

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  ConnectionState _currentState = ConnectionState.loading;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startSystemChecks();
  }

  // Tüm ağ ve sistem kontrollerini başlatır
  Future<void> _startSystemChecks() async {
    if (_isRetrying) return;
    
    setState(() {
      _currentState = ConnectionState.loading;
      _isRetrying = true;
    });

    // 1. Adım: Cihazın internet bağlantısı var mı? (Hızlı DNS Sorgusu)
    final hasInternet = await _checkPhysicalConnection();
    if (!hasInternet) {
      _setSplashState(ConnectionState.offline);
      return;
    }

    // 2. Adım: Hoppa Backend & Supabase Sağlıklı mı?
    final isServerUp = await _checkServerHealth();
    if (!isServerUp) {
      _setSplashState(ConnectionState.serverDown);
      return;
    }

    // 3. Adım: Her şey yolundaysa uygulamaya geçiş yap
    _proceedToApp();
  }

  // Fiziksel internet kontrolü
  Future<bool> _checkPhysicalConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // API Sağlık Kontrolü (Hoppa Health Endpoint)
  Future<bool> _checkServerHealth() async {
    try {
      // API_URL çevre değişkeninizden veya config'den okunmalıdır
      final url = Uri.parse("[https://hoppa-api.com/api/public/health](https://hoppa-api.com/api/public/health)");
      
      final response = await http.get(url)
          .timeout(const Duration(seconds: 5)); // 5 saniye içinde cevap gelmelidir
          
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _setSplashState(ConnectionState state) {
    setState(() {
      _currentState = state;
      _isRetrying = false;
    });
    HapticFeedback.warningImpact(); // Hafif titreşim uyarısı
  }

  void _proceedToApp() {
    // Auth kontrol adımlarına güvenle dallan (Giriş yapılmışsa Anasayfa, yoksa Login)
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary, // Marka ana yeşili
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
      case ConnectionState.loading:
        return Center(
          key: const ValueKey('loading'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/images/logo_white.png', width: 140, errorBuilder: (_, __, ___) => const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 80)),
              const SizedBox(height: 24),
              // Şık Beyaz Yükleme Çemberi
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
            ],
          ),
        );

      // 2. DURUM: Cihaz Çevrimdışı (No Internet)
      case ConnectionState.offline:
        return _buildErrorStateUI(
          key: const ValueKey('offline'),
          icon: Icons.wifi_off_rounded,
          title: "İnternet Bağlantısı Yok",
          description: "Hoppa ile lezzetli anlara ulaşabilmek için aktif bir internet bağlantınızın olması gerekir. Lütfen ayarlarınızı kontrol edip tekrar deneyiniz.",
          buttonText: "Tekrar Dene",
          theme: theme,
        );

      // 3. DURUM: Sunucu Kapalı veya Bakımda (Server Down)
      case ConnectionState.serverDown:
        return _buildErrorStateUI(
          key: const ValueKey('server_down'),
          icon: Icons.cloud_off_rounded,
          title: "Size Daha İyi Hizmet Verebilmek İçin Bakımdayız",
          description: "Sistemlerimizi güncelliyor ve sizin için Hoppa'yı daha hızlı hale getiriyoruz. Kısa süre sonra tekrar yanınızda olacağız.",
          buttonText: "Sistemi Kontrol Et",
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
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: Colors.white),
          ),
          const SizedBox(height: 32),
          
          // Kurumsal Başlık
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
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
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                _startSystemChecks();
              },
              child: const Text(
                "Yeniden Dene",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


📢 4. BÖLÜM: Doğrulama ve Test Senaryoları

A. Otomatik Test Adımları

Express Derleme Analizi:
cd backend && npx tsc --noEmit çalıştırarak /api/public/health bacağında hata olmadığını doğrulayın.

Flutter Statik Analizleri:
cd apps/consumer_app && flutter analyze çalıştırarak SplashPage durum yönetiminin (Haptic ve HTTP çağrıları dahil) uyarı vermediğini teyit edin.

B. Manuel Test Senaryoları

İnternetsiz Giriş Engeli (Offline Test):
Telefonu uçak moduna alın veya interneti kapatıp uygulamayı açın. Beyaz yükleme çemberinden sonra anında "İnternet Bağlantısı Yok" uyarısının ve şık kablosuz bağlantı kesik ikonunun parladığını doğrulayın. İnterneti geri açıp "Yeniden Dene" tuşuna basıldığında uygulamanın içeriye sızdığını gözlemleyin.

Sunucu Çökmesi / Bakım Engeli (Server Down Test):
Lokal backend sunucusunu terminalden tamamen kapatın (Ctrl+C ile durdurun) ve uygulamayı açın. Uygulamanın donup kilitlenmek yerine anında "Sistem Bakımdayız" kurumsal mesajını verdiğini teyit edin. Sunucuyu yeniden başlattıktan sonra "Yeniden Dene" basıldığında uygulamanın pürüzsüzce açıldığını doğrulayın.