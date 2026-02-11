import 'package:flutter/material.dart';
import 'package:kktc_market/models/business.dart';

class BusinessProvider extends ChangeNotifier {
  Business? _selectedBusiness;
  String? _selectedCategory;

  Business? get selectedBusiness => _selectedBusiness;
  String? get selectedCategory => _selectedCategory;

  // Kategori Seçimi
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearCategory() {
    _selectedCategory = null;
    notifyListeners();
  }

  // İşletme Seçimi
  void selectBusiness(Business business) {
    _selectedBusiness = business;
    notifyListeners();
  }

  // İşletme Seçimini İptal Et
  void clearBusiness() {
    _selectedBusiness = null;
    notifyListeners();
  }
}
