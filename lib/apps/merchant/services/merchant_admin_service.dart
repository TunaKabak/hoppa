import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/core/config/app_config.dart';

class MerchantAdminService {
  final http.Client _httpClient;
  final String _baseUrl;

  MerchantAdminService({
    http.Client? httpClient,
    String? baseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUrl = baseUrl ?? AppConfig.merchantApiBaseUrl;

  Future<bool> approveMerchant(String targetUserId) async {
    final String url = "$_baseUrl/admin/approve";

    try {
      final response = await _httpClient
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'targetUserId': targetUserId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(data['message'] ?? 'Onaylama başarısız.');
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Sunucu Hatası: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Sunucu yanıt vermedi (Timeout).');
    } catch (e) {
      throw Exception('Onaylama sırasında hata oluştu: $e');
    }
  }

  Future<bool> rejectMerchant(String targetUserId, String reason) async {
    final String url = "$_baseUrl/admin/reject";
    try {
      final response = await _httpClient
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'targetUserId': targetUserId, 'reason': reason}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return true;
        throw Exception(data['message'] ?? 'Reddetme başarısız.');
      }
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Sunucu Hatası: ${response.statusCode}');
    } on TimeoutException {
      throw Exception('Sunucu yanıt vermedi (Timeout).');
    } catch (e) {
      throw Exception('Reddetme sırasında hata oluştu: $e');
    }
  }

  Future<bool> requestRevisionMerchant(String targetUserId, String message) async {
    final String url = "$_baseUrl/admin/request-revision";
    try {
      final response = await _httpClient
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'targetUserId': targetUserId, 'message': message}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return true;
        throw Exception(data['message'] ?? 'İşlem başarısız.');
      }
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Sunucu Hatası: ${response.statusCode}');
    } on TimeoutException {
      throw Exception('Sunucu yanıt vermedi (Timeout).');
    } catch (e) {
      throw Exception('İşlem sırasında hata oluştu: $e');
    }
  }

  Future<bool> holdMerchant(String targetUserId) async {
    final String url = "$_baseUrl/admin/hold";
    return _sendSimplePost(url, targetUserId);
  }

  Future<bool> deleteMerchant(String targetUserId) async {
    final String url = "$_baseUrl/admin/delete";
    return _sendSimplePost(url, targetUserId);
  }

  Future<bool> _sendSimplePost(String url, String targetUserId) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'targetUserId': targetUserId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return true;
        throw Exception(data['message'] ?? 'İşlem başarısız.');
      }
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Sunucu Hatası: ${response.statusCode}');
    } on TimeoutException {
      throw Exception('Sunucu yanıt vermedi (Timeout).');
    } catch (e) {
      throw Exception('İşlem sırasında hata oluştu: $e');
    }
  }
}
