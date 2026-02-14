import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoppa/core/services/auth_service.dart';
import 'package:hoppa/features/auth/login_page.dart';
import 'package:hoppa/features/main_layout/main_layout_page.dart';
import 'package:hoppa/features/merchant/merchant_dashboard_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInit = true; // İlk açılış kontrolü

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // Sadece ilk açılışta misafir girişi dene
  void _checkAutoLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Eğer zaten giriş yapılmışsa bekleme
    if (authService.currentUser != null) {
      if (mounted) setState(() => _isInit = false);
      return;
    }

    // Kullanıcı yoksa misafir girişi yap
    // await authService.signInAnonymously();
    if (mounted) {
      setState(() => _isInit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // 1. İlk açılışta (Auto Login denerken) Loading göster
    if (_isInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 2. Bağlantı bekleniyorsa Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 3. Kullanıcı varsa -> Ana Sayfa (Layout)
        if (snapshot.hasData) {
          // ÖNEMLİ DÜZELTME: User ID değiştiğinde (Misafir -> Üye) sayfayı sıfırdan kur.
          // Bu sayede hem Profil güncellenir hem de Ana Sayfaya (Tab 0) dönülür.
          // Rol kontrolü ve Yönlendirme (Stream ile)
          return StreamBuilder<Map<String, dynamic>?>(
            stream: authService.getUserDataStream(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final userData = userSnapshot.data;
              final role = userData?['role'];
              final businessId = userData?['businessId'];

              if (role == 'merchant' && businessId != null) {
                // İşletme Dashboard'una yönlendir
                return MerchantDashboardPage(businessId: businessId);
              }

              // Normal Kullanıcı -> Ana Sayfa
              return MainLayoutPage(key: ValueKey(snapshot.data?.uid));
            },
          );
        }

        // 4. Kullanıcı yoksa (Çıkış yapıldıysa) -> Giriş Sayfası (Login)
        return const LoginPage();
      },
    );
  }
}
