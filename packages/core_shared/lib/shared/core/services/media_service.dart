import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:core_network/core_network.dart';
import 'package:http/http.dart' as http;

class MediaService {
  /// Global fallback ApiClient instance
  static ApiClient? globalApiClient;

  final ApiClient? _localApiClient;
  final ImagePicker _picker = ImagePicker();

  MediaService([this._localApiClient]);

  ApiClient get _apiClient {
    final client = _localApiClient ?? globalApiClient;
    if (client == null) {
      throw Exception("MediaService: ApiClient has not been initialized. Set globalApiClient first.");
    }
    return client;
  }

  /// Selects an image from either camera or gallery source
  Future<File?> pickImage({required ImageSource source}) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Compression
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// Uploads selected file directly to Cloudflare R2 via presigned upload URL
  Future<String?> uploadImage({
    required File file,
    required String path, // Unused: Kept for backwards compatibility
  }) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      // Map extensions to strict allowed MIME types
      String mimeType = 'image/jpeg';
      if (fileExtension == 'png') {
        mimeType = 'image/png';
      } else if (fileExtension == 'webp') {
        mimeType = 'image/webp';
      } else if (fileExtension == 'pdf') {
        mimeType = 'application/pdf';
      } else if (fileExtension == 'mp4') {
        mimeType = 'video/mp4';
      }

      // 1. Get short-lived presigned upload URL from backend
      final response = await _apiClient.post(
        '/api/media/upload-url',
        body: {
          'fileName': fileName,
          'mimeType': mimeType,
          'fileSize': file.lengthSync(),
        },
      );

      final uploadData = response['data'] as Map<String, dynamic>;
      final uploadUrl = uploadData['uploadUrl'] as String;
      final publicUrl = uploadData['publicUrl'] as String;

      // 2. Perform raw binary PUT upload directly to Cloudflare R2
      final uploadUri = Uri.parse(uploadUrl);
      final bytes = await file.readAsBytes();

      final putResponse = await http.put(
        uploadUri,
        headers: {
          'Content-Type': mimeType,
        },
        body: bytes,
      );

      if (putResponse.statusCode != 200 && putResponse.statusCode != 201) {
        throw Exception("Cloudflare R2 Direct Upload failed. HTTP Status: ${putResponse.statusCode}");
      }

      return publicUrl;
    } catch (e) {
      print("Upload Error in MediaService: $e");
      rethrow;
    }
  }
}
