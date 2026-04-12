import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoppa/apps/merchant/services/merchant_auth_service.dart';
import 'package:hoppa/apps/merchant/auth/merchant_login_page.dart';
import 'package:hoppa/apps/merchant/auth/merchant_revision_page.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';

class MerchantAuthWrapper extends StatelessWidget {
  const MerchantAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final MerchantAuthService authService = MerchantAuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
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
              final status = userData?['status'];
              final businessId = userData?['businessId'];
              final isMerchant = (role == 'merchant' || role == 'super_admin');

              // GUARD: Merchant flavor'a normal kullanıcı girişi yasak
              if (!isMerchant) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Bu alana sadece işletmeler giriş yapabilir.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  authService.signOut();
                });
                return const LoginPage();
              }

              // GUARD: İşletme durum kontrolleri
              if (role != 'super_admin' && (businessId == null || status != 'active')) {
                // Eğer statü revision_requested ise, Revizyon Sayfasına yönlendir
                if (status == 'revision_requested') {
                  return MerchantRevisionPage(userData: userData ?? {});
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  String message = "Yetkisiz giriş denemesi.";
                  Color bgColor = Colors.red;

                  if (status == 'pending') {
                    message = "Başvurunuz inceleme aşamasındadır. Onaylandıktan sonra giriş yapabilirsiniz.";
                    bgColor = Colors.orange.shade800;
                  } else if (status == 'on_hold') {
                    message = "Başvurunuz şu anda detaylı inceleme için beklemeye alınmıştır.";
                    bgColor = Colors.blue.shade800;
                  } else if (status == 'rejected') {
                    final reason = userData?['rejectionReason'] ?? 'Belirtilmedi';
                    message = "Başvurunuz reddedilmiştir. Sebep: $reason";
                    bgColor = Colors.red.shade900;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: bgColor,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                  authService.signOut();
                });
                return const LoginPage();
              }

              if (businessId != null || role == 'super_admin') {
                return MerchantMainLayout(
                  key: ValueKey(
                    '${snapshot.data?.uid}_${businessId ?? "admin"}',
                  ),
                  businessId: businessId ?? '',
                );
              }

              return const LoginPage();
            },
          );
        }

        // Giriş yapılmamışsa
        return const LoginPage();
      },
    );
  }
}
