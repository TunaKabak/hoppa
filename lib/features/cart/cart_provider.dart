import 'package:flutter/material.dart';
import 'package:kktc_market/models/business_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Sepet Öğesi artık BusinessProduct tutuyor
class CartItem {
  final BusinessProduct businessProduct;
  double quantity;

  CartItem({required this.businessProduct, this.quantity = 1.0});
}

enum AddToCartResult { success, outOfStock, marketConflict }

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<CartItem> _items = [];
  String? _currentBusinessId;

  List<CartItem> get items => _items;
  String? get currentBusinessId => _currentBusinessId;

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      // Fiyat artık businessProduct içinde
      total += item.businessProduct.price * item.quantity;
    }
    return total;
  }

  // Firestore'dan sepeti getir
  Future<void> fetchCart(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      _items.clear();
      _currentBusinessId = null;

      if (snapshot.docs.isNotEmpty) {
        // İlk elemandan businessId'yi al (hepsi aynı işletme olmalı)
        // final firstData = snapshot.docs.first.data();
        // BusinessProduct'ı yeniden oluşturmak gerekebilir ama şimdilik basitleştirelim.
        // NOT: BusinessProduct karmaşık bir obje. Firestore'a tamamını kaydetmek yerine
        // ID'leri tutup live fetch yapmak daha doğrusu olurdu ama
        // "Kalıcılık" istendiği için snapshot verisini parse edip geri yüklemeye çalışacağız.
        // Basitlik adına, şimdilik sadece BusinessProduct'ı JSON olarak sakladığımızı varsayalım.

        // Ancak BusinessProduct modeli fromJson desteklemiyor olabilir.
        // Bu yüzden şimdilik sadece RAM'deki mantığı koruyup, temel ID ve Miktarı db'ye yazacağız.
        // Ve UI tarafında (veya burada) o ID ile ürün detayını tekrar çekmek gerekebilir.

        // ÇÖZÜM: BusinessProduct modelini ve altındaki Product modelini JSON'dan dönecek şekilde güncellemek uzun iş.
        // Hızlı çözüm: CartItem'ı JSON olarak kaydet/yükle.

        for (var doc in snapshot.docs) {
          var data = doc.data();
          // BusinessProduct nesnesini JSON'dan oluşturmamız lazım.
          // Bu projede modellerde fromJson yoksa, manuel maplememiz gerekir.
          // Ve bu obje çok iç içe (Category, BusinessType, vs).

          // *KRITIK*: Veri yapısı çok karmaşık olduğu için,
          // Product servisinden ID ile çekmek en temizi ama bu asenkron ve yavaş olabilir.

          // Şimdilik 'persistence' için nesneyi JSON olarak saklayıp geri okumayı deneyelim.
          // Eğer modelde fromMap yoksa, dynamic yapı kullanacağız.
          try {
            BusinessProduct bp = BusinessProduct.fromMap(
              data['businessProduct'],
              data['businessProduct']['id'] ?? '',
            );
            _items.add(
              CartItem(
                businessProduct: bp,
                quantity: (data['quantity'] as num).toDouble(),
              ),
            );
            if (_currentBusinessId == null) {
              _currentBusinessId = bp.businessId;
            }
          } catch (e) {
            print("Cart Parse Error: $e");
          }
        }
      }
      notifyListeners();
    } catch (e) {
      print("Fetch Cart Error: $e");
    }
  }

  // Firestore'a kaydet (Tek ürün)
  Future<void> _saveItemToFirestore(CartItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(item.businessProduct.id) // Ürün ID'si döküman ID olsun
          .set({
            'businessProduct': item.businessProduct
                .toMap(), // Modelde toMap olduğunu varsayıyoruz veya ekleyeceğiz
            'quantity': item.quantity,
            'updated_at': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print("Save Item Error: $e");
    }
  }

  // Firestore'dan sil (Tek ürün)
  Future<void> _deleteItemFromFirestore(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(productId)
          .delete();
    } catch (e) {
      print("Delete Item Error: $e");
    }
  }

  // Firestore'u komple temizle
  Future<void> _clearFirestoreCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print("Clear Firestore Error: $e");
    }
  }

  Future<AddToCartResult> addToCart(BusinessProduct product) async {
    // 1. İŞLETME KONTROLÜ
    if (_items.isNotEmpty && _currentBusinessId != null) {
      if (_currentBusinessId != product.businessId) {
        return AddToCartResult.marketConflict;
      }
    }

    // ID kontrolü
    int index = _items.indexWhere(
      (item) => item.businessProduct.id == product.id,
    );

    // Tartılı ürün kontrolü
    double increment = product.product.isWeighted ? 0.5 : 1.0;

    double currentQty = index >= 0 ? _items[index].quantity : 0.0;
    double newQty = currentQty + increment;

    // 2. STOK KONTROLÜ
    if (newQty > product.stock) {
      return AddToCartResult.outOfStock;
    }

    // 3. İŞLEM
    CartItem? updatedItem;
    if (index >= 0) {
      _items[index].quantity = newQty;
      updatedItem = _items[index];
    } else {
      updatedItem = CartItem(
        businessProduct: product,
        quantity: product.product.isWeighted ? 1.0 : 1.0,
      );
      _items.add(updatedItem);
      _currentBusinessId = product.businessId;
    }

    notifyListeners();

    // DB SYNC
    // DB SYNC
    await _saveItemToFirestore(updatedItem);

    return AddToCartResult.success;
  }

  Future<void> removeFromCart(String productId) async {
    int index = _items.indexWhere(
      (item) => item.businessProduct.id == productId,
    );

    if (index >= 0) {
      // Ürünü bulduk, şimdi miktarını azaltacağız
      final product = _items[index].businessProduct;
      double decrement = product.product.isWeighted ? 0.5 : 1.0;

      // bool shouldDelete = false;

      if (_items[index].quantity > decrement + 0.01) {
        _items[index].quantity -= decrement;
        // DB SYNC UPDATE
        await _saveItemToFirestore(_items[index]);
      } else {
        _items.removeAt(index);
        // shouldDelete = true; // Unused
        // DB SYNC DELETE
        await _deleteItemFromFirestore(productId);
      }

      if (_items.isEmpty) {
        _currentBusinessId = null;
      }

      notifyListeners();
    }
  }

  // Logout yaparken db silinmez, sadece RAM temizlenir (default)
  // Sipariş tamamlanınca db silinir (deleteFromDb: true)
  Future<void> clearCart({bool deleteFromDb = false}) async {
    _items.clear();
    _currentBusinessId = null;
    notifyListeners();

    if (deleteFromDb) {
      await _clearFirestoreCart();
    }
  }

  void removeGroup(String groupBy, String groupName) {
    // Toplu silme işlemi için şimdilik basit döngü
    // Bu metod çok sık kullanılmıyor gibi, ama güncelleyelim.
    // DB sync biraz maliyetli olabilir toplu silmede.
    if (groupBy == 'brand') {
      // Silinecekleri bul
      var toRemove = _items
          .where((item) => item.businessProduct.product.brand == groupName)
          .toList();
      for (var item in toRemove) {
        removeFromCart(
          item.businessProduct.id,
        ); // Tek tek siler ve DB'yi günceller (biraz verimsiz ama güvenli)
      }
    } else {
      var toRemove = _items
          .where((item) => item.businessProduct.product.category == groupName)
          .toList();
      for (var item in toRemove) {
        removeFromCart(item.businessProduct.id);
      }
    }
  }
}
