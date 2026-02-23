import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoppa/apps/merchant/services/merchant_auth_service.dart';
import 'package:hoppa/apps/merchant/auth/merchant_login_page.dart';
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
              final businessId = userData?['businessId'];
              final isMerchant = (role == 'merchant');

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

              if (businessId != null) {
                return MerchantMainLayout(
                  key: ValueKey(snapshot.data?.uid),
                  businessId: businessId,
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
