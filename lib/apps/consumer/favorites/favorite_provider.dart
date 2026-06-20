import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _favoriteProductIds = [];

  List<String> get favoriteProductIds => _favoriteProductIds;

  FavoriteProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        _listenToFavorites(user.uid);
      } else {
        try {
          await _auth.signInAnonymously();
        } catch (e) {
          print("FavoriteProvider anonymous sign in error: $e");
        }
      }
    });
  }

  void _listenToFavorites(String userId) {
    _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
          _favoriteProductIds = snapshot.docs.map((doc) => doc.id).toList();
          notifyListeners();
        });
  }

  bool isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(productId);

    if (isFavorite(productId)) {
      await docRef.delete();
      _favoriteProductIds.remove(productId);
    } else {
      await docRef.set({'addedAt': FieldValue.serverTimestamp()});
      _favoriteProductIds.add(productId);
    }
    notifyListeners();
  }
}
