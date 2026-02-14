import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/models/business.dart';
import 'package:hoppa/models/business_type.dart';

class BusinessService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Business>> getBusinesses() {
    return _db.collection('businesses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Mock Kategori Mantığı (Eğer veritabanında yoksa)
        List<String> categories = List<String>.from(
          doc.data().toString().contains('categories') ? doc['categories'] : [],
        );

        String lowerName = doc['name'].toString().toLowerCase();
        BusinessType type = BusinessType.market; // Varsayılan

        if (doc.data().containsKey('type')) {
          type = BusinessType.fromString(doc['type']);
        } else {
          // İsimden tür tahmini
          if (lowerName.contains('kuruyemiş') || lowerName.contains('nuts')) {
            type = BusinessType.other; // Veya uygunsa market
            if (categories.isEmpty) categories.add('Kuruyemiş');
          } else if (lowerName.contains('coffee') ||
              lowerName.contains('kahve') ||
              lowerName.contains('cafe') ||
              lowerName.contains('gloria')) {
            type = BusinessType.cafe;
            if (categories.isEmpty) categories.add('Kahve');
          } else if (lowerName.contains('sucu') ||
              lowerName == 'su dünyası' ||
              lowerName.contains('water')) {
            type = BusinessType.water;
            if (categories.isEmpty) categories.add('Su');
          } else if (lowerName.contains('restoran') ||
              lowerName.contains('yemek') ||
              lowerName.contains('burger') ||
              lowerName.contains('pizza') ||
              lowerName.contains('kebap') ||
              lowerName.contains('kitchen')) {
            type = BusinessType.restaurant;
            if (categories.isEmpty) categories.add('Yemek');
          } else if (lowerName.contains('kasap') || lowerName.contains('et')) {
            type = BusinessType.butcher;
            if (categories.isEmpty) categories.add('Kasap');
          } else if (lowerName.contains('fırın') ||
              lowerName.contains('pastane') ||
              lowerName.contains('bakery')) {
            type = BusinessType.bakery;
            if (categories.isEmpty) categories.add('Fırın');
          } else if (lowerName.contains('manav') ||
              lowerName.contains('sebze') ||
              lowerName.contains('meyve')) {
            type = BusinessType.greengrocer;
            if (categories.isEmpty) categories.add('Manav');
          } else {
            type = BusinessType.market;
            if (categories.isEmpty) categories.add('Market');
          }
        }

        return Business(
          id: doc.id,
          name: doc['name'],
          address: doc['address'],
          phone: doc['phone'],
          logoUrl: doc['logoUrl'],
          headerImageUrl: doc['headerImageUrl'],
          latitude: (doc['latitude'] ?? 0.0).toDouble(),
          longitude: (doc['longitude'] ?? 0.0).toDouble(),
          isOpen: doc['isOpen'] ?? true,
          type: type, // YENİ
          categories: categories,
        );
      }).toList();
    });
  }

  Future<List<Business>> getBusinessesFuture() async {
    final snapshot = await _db.collection('businesses').get();
    return snapshot.docs.map((doc) {
      // Mock Kategori Mantığı (Eğer veritabanında yoksa)
      List<String> categories = List<String>.from(
        doc.data().toString().contains('categories') ? doc['categories'] : [],
      );

      String lowerName = doc['name'].toString().toLowerCase();
      BusinessType type = BusinessType.market; // Varsayılan

      if (doc.data().containsKey('type')) {
        type = BusinessType.fromString(doc['type']);
      } else {
        // İsimden tür tahmini (Yukarıdaki mantığın aynısı)
        if (lowerName.contains('kuruyemiş') || lowerName.contains('nuts')) {
          type = BusinessType.other;
          if (categories.isEmpty) categories.add('Kuruyemiş');
        } else if (lowerName.contains('coffee') ||
            lowerName.contains('kahve') ||
            lowerName.contains('cafe') ||
            lowerName.contains('gloria')) {
          type = BusinessType.cafe;
          if (categories.isEmpty) categories.add('Kahve');
        } else if (lowerName.contains('sucu') ||
            lowerName == 'su dünyası' ||
            lowerName.contains('water')) {
          type = BusinessType.water;
          if (categories.isEmpty) categories.add('Su');
        } else if (lowerName.contains('restoran') ||
            lowerName.contains('yemek') ||
            lowerName.contains('burger') ||
            lowerName.contains('pizza') ||
            lowerName.contains('kebap') ||
            lowerName.contains('kitchen')) {
          type = BusinessType.restaurant;
          if (categories.isEmpty) categories.add('Yemek');
        } else if (lowerName.contains('kasap') || lowerName.contains('et')) {
          type = BusinessType.butcher;
          if (categories.isEmpty) categories.add('Kasap');
        } else if (lowerName.contains('fırın') ||
            lowerName.contains('pastane') ||
            lowerName.contains('bakery')) {
          type = BusinessType.bakery;
          if (categories.isEmpty) categories.add('Fırın');
        } else if (lowerName.contains('manav') ||
            lowerName.contains('sebze') ||
            lowerName.contains('meyve')) {
          type = BusinessType.greengrocer;
          if (categories.isEmpty) categories.add('Manav');
        } else {
          type = BusinessType.market;
          if (categories.isEmpty) categories.add('Market');
        }
      }

      return Business(
        id: doc.id,
        name: doc['name'],
        address: doc['address'],
        phone: doc['phone'],
        logoUrl: doc['logoUrl'],
        headerImageUrl: doc['headerImageUrl'],
        latitude: (doc['latitude'] ?? 0.0).toDouble(),
        longitude: (doc['longitude'] ?? 0.0).toDouble(),
        isOpen: doc['isOpen'] ?? true,
        type: type,
        categories: categories,
      );
    }).toList();
  }

  Future<Business?> getBusinessById(String id) async {
    try {
      final doc = await _db.collection('businesses').doc(id).get();
      if (!doc.exists) return null;

      // Mock Category Logic
      List<String> categories = List<String>.from(
        doc.data().toString().contains('categories') ? doc['categories'] : [],
      );

      String lowerName = doc['name'].toString().toLowerCase();
      BusinessType type = BusinessType.market;

      if (doc.data()!.containsKey('type')) {
        type = BusinessType.fromString(doc['type']);
      } else {
        if (lowerName.contains('kuruyemiş') || lowerName.contains('nuts')) {
          type = BusinessType.other;
          if (categories.isEmpty) categories.add('Kuruyemiş');
        } else if (lowerName.contains('coffee') ||
            lowerName.contains('kahve') ||
            lowerName.contains('cafe') ||
            lowerName.contains('gloria')) {
          type = BusinessType.cafe;
          if (categories.isEmpty) categories.add('Kahve');
        } else if (lowerName.contains('sucu') ||
            lowerName == 'su dünyası' ||
            lowerName.contains('water')) {
          type = BusinessType.water;
          if (categories.isEmpty) categories.add('Su');
        } else if (lowerName.contains('restoran') ||
            lowerName.contains('yemek') ||
            lowerName.contains('burger') ||
            lowerName.contains('pizza') ||
            lowerName.contains('kebap') ||
            lowerName.contains('kitchen')) {
          type = BusinessType.restaurant;
          if (categories.isEmpty) categories.add('Yemek');
        } else if (lowerName.contains('kasap') || lowerName.contains('et')) {
          type = BusinessType.butcher;
          if (categories.isEmpty) categories.add('Kasap');
        } else if (lowerName.contains('fırın') ||
            lowerName.contains('pastane') ||
            lowerName.contains('bakery')) {
          type = BusinessType.bakery;
          if (categories.isEmpty) categories.add('Fırın');
        } else if (lowerName.contains('manav') ||
            lowerName.contains('sebze') ||
            lowerName.contains('meyve')) {
          type = BusinessType.greengrocer;
          if (categories.isEmpty) categories.add('Manav');
        } else {
          type = BusinessType.market;
          if (categories.isEmpty) categories.add('Market');
        }
      }

      return Business(
        id: doc.id,
        name: doc['name'],
        address: doc['address'],
        phone: doc['phone'],
        logoUrl: doc['logoUrl'],
        headerImageUrl: doc['headerImageUrl'],
        latitude: (doc['latitude'] ?? 0.0).toDouble(),
        longitude: (doc['longitude'] ?? 0.0).toDouble(),
        isOpen: doc['isOpen'] ?? true,
        type: type,
        categories: categories,
      );
    } catch (e) {
      print('Error fetching business: $e');
      return null;
    }
  }

  Future<void> updateBusiness(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection('businesses').doc(businessId).update(data);
    } catch (e) {
      print('İşletme güncelleme hatası: $e');
      rethrow;
    }
  }
}
