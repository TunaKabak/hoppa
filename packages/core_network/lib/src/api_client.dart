import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'exceptions.dart';

class ApiClient {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;
  final String baseUrl;

  /// 401 alındığında çağrılacak callback (örn. AuthController.logout())
  void Function()? onUnauthorized;

  static const String _tokenKey = 'jwt_token';

  ApiClient({
    http.Client? client,
    FlutterSecureStorage? secureStorage,
    required this.baseUrl,
  }) : _client = client ?? http.Client(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // --- Token Management ---
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // --- Generic Key-Value Storage ---
  Future<void> saveValue(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getValue(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteValue(String key) async {
    await _secureStorage.delete(key: key);
  }

  // --- Header Construction ---
  Future<Map<String, String>> _buildHeaders(bool requiresAuth) async {
    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      HttpHeaders.acceptHeader: 'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }

    return headers;
  }

  // --- Response Wrapper ---
  Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    String message = "Bilinmeyen bir hata oluştu";
    dynamic data;

    try {
      final decodedJson = jsonDecode(response.body);
      if (decodedJson is Map<String, dynamic>) {
        if (decodedJson.containsKey('message')) {
          message = decodedJson['message'];
        }
        if (decodedJson.containsKey('data')) {
          data = decodedJson['data'];
        }
      }
    } catch (_) {
      message = response.reasonPhrase ?? message;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'message': message, 'data': data};
    }

    if (response.statusCode == 400) {
      throw BadRequestException(message);
    } else if (response.statusCode == 401) {
      await deleteToken();
      // UI katmanını bilgilendir (AuthController'ın logout tetiklemesi için)
      onUnauthorized?.call();
      throw UnauthorizedException(message);
    } else if (response.statusCode >= 500) {
      throw ServerException(message);
    } else {
      throw AppException(response.statusCode, message);
    }
  }

  // --- HTTP Methods ---
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(requiresAuth);

      final response = await _client.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Bağlantı zaman aşımına uğradı"),
      );
      return await _processResponse(response);
    } on SocketException catch (_) {
      throw NetworkException("İnternet bağlantınızı kontrol edin.");
    } on TimeoutException catch (e) {
      throw NetworkException(e.message ?? "Zaman aşımı");
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(requiresAuth);

      final response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Bağlantı zaman aşımına uğradı"),
      );

      return await _processResponse(response);
    } on SocketException catch (_) {
      throw NetworkException("İnternet bağlantınızı kontrol edin.");
    } on TimeoutException catch (e) {
      throw NetworkException(e.message ?? "Zaman aşımı");
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(requiresAuth);

      final response = await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Bağlantı zaman aşımına uğradı"),
      );

      return await _processResponse(response);
    } on SocketException catch (_) {
      throw NetworkException("İnternet bağlantınızı kontrol edin.");
    } on TimeoutException catch (e) {
      throw NetworkException(e.message ?? "Zaman aşımı");
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(requiresAuth);

      final response = await _client.delete(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Bağlantı zaman aşımına uğradı"),
      );

      return await _processResponse(response);
    } on SocketException catch (_) {
      throw NetworkException("İnternet bağlantınızı kontrol edin.");
    } on TimeoutException catch (e) {
      throw NetworkException(e.message ?? "Zaman aşımı");
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }
  }
}
