import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage({required ImageSource source}) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Sıkıştırma
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<String?> uploadImage({
    required File file,
    required String path,
  }) async {
    try {
      if (!file.existsSync()) {
        throw Exception("Dosya bulunamadı: ${file.path}");
      }
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;

      if (snapshot.state != TaskState.success) {
        throw Exception("Yükleme başarısız. Durum: ${snapshot.state}");
      }

      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Hata yönetimi
      print("Upload Error: $e");
      rethrow;
    }
  }
}
