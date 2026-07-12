import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:core_auth/core_auth.dart';
import 'package:provider/provider.dart';
import 'package:consumer_app/apps/consumer/main_layout/main_layout_page.dart';
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:consumer_app/apps/consumer/providers/consumer_location_controller.dart';

class ConsumerAuthWrapper extends ConsumerWidget {
  const ConsumerAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    final deliveryProvider = Provider.of<DeliveryProvider>(
      context,
      listen: false,
    );
    if (authState is AuthAuthenticated) {
      deliveryProvider.updateUserId(authState.user.id);
    } else {
      deliveryProvider.updateUserId('guest');
    }

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthInitial) {
        deliveryProvider.clearAddress();
        ref.invalidate(consumerLocationProvider);
      }
    });

    if (authState is AuthChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Hem giriş yapmış olan hem de giriş yapmamış (guest) kullanıcıları MainLayoutPage'e yönlendiriyoruz.
    return const MainLayoutPage();
  }
}
