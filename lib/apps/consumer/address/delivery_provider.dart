import 'package:flutter/material.dart';
import 'package:hoppa/shared/models/address.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryProvider extends ChangeNotifier {
  Address? _selectedAddress;
  String? _userId;

  DeliveryProvider() {
    _loadAddress();
  }

  Address? get selectedAddress => _selectedAddress;

  bool get hasAddress => _selectedAddress != null;

  String get _storageKey {
    final cleanId = _userId ?? 'guest';
    return 'selected_address_$cleanId';
  }

  Future<void> updateUserId(String? newUserId) async {
    final cleanId = newUserId ?? 'guest';
    if (_userId == cleanId) return;
    _userId = cleanId;
    await _loadAddress();
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final addressJson = prefs.getString(_storageKey);
    if (addressJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(addressJson);
        final id = data['id'] as String? ?? '';
        _selectedAddress = Address.fromMap(data, id);
        notifyListeners();
      } catch (e) {
        _selectedAddress = null;
        notifyListeners();
      }
    } else {
      _selectedAddress = null;
      notifyListeners();
    }
  }

  Future<void> setAddress(Address address) async {
    _selectedAddress = address;
    notifyListeners();
    
    // Adresi SharedPreferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    final addressMap = address.toMap();
    // fromMap metodunun doğru çalışması için ID'yi de JSON içine koyalım
    addressMap['id'] = address.id;
    await prefs.setString(_storageKey, jsonEncode(addressMap));
  }

  // Sipariş sonrası veya çıkışta temizlemek için
  Future<void> clearAddress() async {
    _selectedAddress = null;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
