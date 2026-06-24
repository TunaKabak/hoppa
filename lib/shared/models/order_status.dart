import 'package:flutter/material.dart';

/// Sipariş durumu enum'u — tüm uygulama genelinde tek kaynak.
enum OrderStatus {
  pending,
  preparing,
  onWay,
  readyForPickup,
  delivered,
  cancelled;

  /// Firestore/backend'de kullanılan string karşılığı
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.onWay:
        return 'on_way';
      case OrderStatus.readyForPickup:
        return 'ready_for_pickup';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Kullanıcıya gösterilecek Türkçe etiket
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Onay Bekliyor';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.onWay:
        return 'Yolda';
      case OrderStatus.readyForPickup:
        return 'Hazır (Bekleniyor)';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  /// Sipariş durumu rengi
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.onWay:
        return Colors.purple;
      case OrderStatus.readyForPickup:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  /// Varsayılan ikon
  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_top;
      case OrderStatus.preparing:
        return Icons.inventory_2;
      case OrderStatus.onWay:
        return Icons.delivery_dining;
      case OrderStatus.readyForPickup:
        return Icons.shopping_bag;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// İlerleme çubuğu değeri (0.0 - 1.0)
  double get progressValue {
    switch (this) {
      case OrderStatus.pending:
        return 0.15;
      case OrderStatus.preparing:
        return 0.50;
      case OrderStatus.onWay:
        return 0.85;
      case OrderStatus.readyForPickup:
        return 0.90;
      case OrderStatus.delivered:
        return 1.0;
      case OrderStatus.cancelled:
        return 0.0;
    }
  }

  /// Stepper'da hangi adım olduğu (0-indexed)
  int get stepIndex {
    switch (this) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.onWay:
        return 2;
      case OrderStatus.readyForPickup:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  /// Aktif sipariş mi? (UI'da gösterilmeli mi)
  bool get isActive =>
      this == pending ||
      this == preparing ||
      this == onWay ||
      this == readyForPickup;

  /// Tamamlanmış mı?
  bool get isCompleted => this == delivered || this == cancelled;

  /// String'den OrderStatus'a dönüştür
  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'on_way':
      case 'on_the_way':
        return OrderStatus.onWay;
      case 'ready_for_pickup':
        return OrderStatus.readyForPickup;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}
