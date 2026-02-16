import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/models/business_product.dart';
import 'package:hoppa/models/campaign.dart';
import 'package:hoppa/core/services/campaign_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<BusinessProduct> _products = [];
  List<BusinessProduct> get products => _products;

  List<Campaign> _activeCampaigns = [];
  List<Campaign> get activeCampaigns => _activeCampaigns;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  DocumentSnapshot? _lastDocument;

  void resetState() {
    _products = [];
    _lastDocument = null;
    _hasMore = true;
    _isLoading = false;
    notifyListeners();
  }

  String _selectedCategory = 'Tümü';
  String _selectedSubCategory = 'Tümü';
  String _selectedSortOption = 'Önerilen';

  final int _limit = 20;

  String get selectedCategory => _selectedCategory;
  String get selectedSubCategory => _selectedSubCategory;
  String get selectedSortOption => _selectedSortOption;

  void setCategory(String category) {
    _selectedCategory = category;
    _selectedSubCategory = 'Tümü';

    // State resetlenince otomatik fetch çağrılmıyor, UI'dan çağrılmalı.
    // Ancak veri bütünlüğü için burada resetlemek yeterli.
    _products = [];
    _activeCampaigns = []; // Reset campaigns too
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();
  }

  void setSubCategory(String subCategory) {
    if (_selectedSubCategory == subCategory) return;
    _selectedSubCategory = subCategory;
    _products = [];
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();
  }

  void setSortOption(String sortOption) {
    if (_selectedSortOption == sortOption) return;
    _selectedSortOption = sortOption;
    _products = [];
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();
  }

  Future<void> fetchProducts({required String businessId}) async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    debugPrint(
      "🔍 İşletme Ürünleri Çekiliyor ($businessId)... Kat: $_selectedCategory",
    );

    try {
      // KAMPANYALARI ÇEK (Sadece ilk sayfada veya liste boşken)
      if (_products.isEmpty) {
        try {
          // Stream'i tek seferlik Future'a çeviriyoruz
          final campaigns = await CampaignService()
              .getActiveCampaigns(businessId)
              .first;
          _activeCampaigns = campaigns;
        } catch (e) {
          debugPrint("Kampanya çekme hatası: $e");
          // Kampanya hatası ürünleri engellememeli
        }
      }

      // SORGULAMA: business_products koleksiyonundan
      Query query = _db
          .collection('business_products')
          .where('businessId', isEqualTo: businessId);

      // FİLTRELER (Embed edilmiş product_details üzerinden)
      if (_selectedCategory != 'Tümü') {
        query = query.where(
          'product_details.category',
          isEqualTo: _selectedCategory,
        );
      }

      if (_selectedSubCategory != 'Tümü') {
        query = query.where(
          'product_details.subCategory',
          isEqualTo: _selectedSubCategory,
        );
      }

      // SIRALAMA VE SAYFALAMA
      final bool isFilteredOrSorted =
          _selectedCategory != 'Tümü' || _selectedSortOption != 'Önerilen';

      if (!isFilteredOrSorted) {
        if (_lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }
        query = query.limit(_limit);
      }

      final snapshot = await query.get();

      if (!isFilteredOrSorted && snapshot.docs.length < _limit) {
        _hasMore = false;
      } else if (isFilteredOrSorted) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        if (!isFilteredOrSorted) _lastDocument = snapshot.docs.last;

        List<BusinessProduct> newProducts = snapshot.docs.map((doc) {
          return BusinessProduct.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        // CLIENT SIDE SORTING
        if (_selectedSortOption != 'Önerilen') {
          _sortProductsList(newProducts);
        }

        _products.addAll(newProducts);
      }
    } catch (e) {
      debugPrint("❌ Ürün çekme hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortProductsList(List<BusinessProduct> list) {
    switch (_selectedSortOption) {
      case 'Fiyat Artan':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Fiyat Azalan':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'İsim A-Z':
        list.sort((a, b) => a.product.name.compareTo(b.product.name));
        break;
      case 'İsim Z-A':
        list.sort((a, b) => b.product.name.compareTo(a.product.name));
        break;
    }
  }
}
