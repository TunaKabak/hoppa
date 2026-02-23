import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/shared/models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all categories ordered by 'order' field
  Stream<List<Category>> getCategoriesStream() {
    return _firestore.collection('categories').orderBy('order').snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
      },
    );
  }

  // Get only active categories
  Stream<List<Category>> getActiveCategoriesStream() {
    return _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Category.fromFirestore(doc))
              .toList();
        });
  }

  // Get all active categories (one-time fetch)
  Future<List<Category>> getActiveCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  // Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    final doc = await _firestore.collection('categories').doc(categoryId).get();

    if (!doc.exists) return null;
    return Category.fromFirestore(doc);
  }

  // Get business count for a specific category
  Future<int> getBusinessCountForCategory(String categoryId) async {
    final businessSnapshot = await _firestore
        .collection('businesses')
        .where('category', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .get();

    return businessSnapshot.size;
  }

  // Update business count for a category
  Future<void> updateBusinessCount(String categoryId) async {
    final count = await getBusinessCountForCategory(categoryId);

    await _firestore.collection('categories').doc(categoryId).update({
      'businessCount': count,
    });
  }

  // Create or update a category
  Future<void> saveCategory(Category category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .set(category.toMap(), SetOptions(merge: true));
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  // Toggle category active status
  Future<void> toggleCategoryStatus(String categoryId, bool isActive) async {
    await _firestore.collection('categories').doc(categoryId).update({
      'isActive': isActive,
    });
  }
}
