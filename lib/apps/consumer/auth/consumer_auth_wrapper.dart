import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoppa/apps/consumer/services/customer_auth_service.dart';
import 'package:hoppa/apps/consumer/auth/consumer_login_page.dart';
import 'package:hoppa/apps/consumer/main_layout/main_layout_page.dart';

class ConsumerAuthWrapper extends StatelessWidget {
  const ConsumerAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomerAuthService authService = CustomerAuthService();

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
              final isMerchant = (role == 'merchant');

              // GUARD: Consumer flavor'a merchant girişi yasak
              if (isMerchant) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "İşletme hesapları tüketici uygulamasına giriş yapamaz.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  authService.signOut();
                });
                return const LoginPage();
              }

              return MainLayoutPage(key: ValueKey(snapshot.data?.uid));
            },
          );
        }

        // Giriş yapılmamışsa
        return const LoginPage();
      },
    );
  }
}
