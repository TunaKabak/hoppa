import 'package:flutter_flavor/flutter_flavor.dart';

class NotificationNavigationHelper {
  static void Function(String orderId)? onConsumerNavigate;
  static void Function(String orderId)? onMerchantNavigate;

  static void handleNotificationClick(Map<String, dynamic> data) {
    final String? orderId = data['orderId']?.toString();

    if (orderId == null || orderId.isEmpty) return;

    final flavor = FlavorConfig.instance.name;
    if (flavor == 'consumer') {
      onConsumerNavigate?.call(orderId);
    } else if (flavor == 'merchant') {
      onMerchantNavigate?.call(orderId);
    }
  }
}
