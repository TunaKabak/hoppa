import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:hoppa/shared/core/services/navigation_service.dart';
import 'package:hoppa/apps/consumer/orders/order_detail_page.dart';
import 'package:hoppa/apps/merchant/merchant_order_list_page.dart';

class NotificationNavigationHelper {
  static void handleNotificationClick(Map<String, dynamic> data) {
    final String? orderId = data['orderId'];
    final String? type = data['type'];

    if (orderId == null || orderId.isEmpty) return;

    if (type == 'ORDER_STATUS') {
      final flavor = FlavorConfig.instance.name;
      if (flavor == 'consumer') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(orderId: orderId),
          ),
        );
      } else if (flavor == 'merchant') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => MerchantOrderListPage(orderId: orderId),
          ),
        );
      }
    }
  }
}
