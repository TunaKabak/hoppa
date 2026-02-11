import 'package:flutter/material.dart';
import 'package:kktc_market/models/address.dart';

class DeliveryProvider extends ChangeNotifier {
  Address? _selectedAddress;

  Address? get selectedAddress => _selectedAddress;

  bool get hasAddress => _selectedAddress != null;

  void setAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  // Sipariş sonrası veya çıkışta temizlemek için
  void clearAddress() {
    _selectedAddress = null;
    notifyListeners();
  }
}
