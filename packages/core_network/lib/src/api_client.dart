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

  /// 401 alındığında ve token yenilenemediğinde çağrılacak callback (örn. AuthController.logout())
  void Function()? onUnauthorized;

  /// 401 alındığında sessiz token yenilemeyi deneyecek callback
  Future<bool> Function()? onTokenRefresh;

  /// Süper Admin'in işlem yapmak istediği dükkanın ID'si
  String? activeBusinessId;

  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';

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

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: _refreshTokenKey);
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

    if (activeBusinessId != null && activeBusinessId!.isNotEmpty) {
      headers['x-business-id'] = activeBusinessId!;
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
      await deleteRefreshToken();
      // UI katmanını bilgilendir (AuthController'ın logout tetiklemesi için)
      onUnauthorized?.call();
      throw UnauthorizedException(message);
    } else if (response.statusCode >= 500) {
      throw ServerException(message);
    } else {
      throw AppException(response.statusCode, message);
    }
  }

  // --- Generic Request Executor with Silent Refresh ---
  Future<Map<String, dynamic>> _executeWithAuthRetry(
    String endpoint,
    Future<http.Response> Function(Map<String, String> headers) requestFn, {
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth);
      if (extraHeaders != null) {
        headers.addAll(extraHeaders);
      }

      var response = await requestFn(headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Bağlantı zaman aşımına uğradı"),
      );

      final isAuthEndpoint = endpoint.contains('/auth/login') ||
          endpoint.contains('/auth/verify-otp') ||
          endpoint.contains('/auth/refresh');

      if (response.statusCode == 401 && requiresAuth && !isAuthEndpoint && onTokenRefresh != null) {
        final refreshed = await onTokenRefresh!();
        if (refreshed) {
          final newHeaders = await _buildHeaders(requiresAuth);
          if (extraHeaders != null) {
            newHeaders.addAll(extraHeaders);
          }
          response = await requestFn(newHeaders).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException("Bağlantı zaman aşımına uğradı"),
          );
        }
      }

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

  // --- HTTP Methods ---
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _executeWithAuthRetry(
      endpoint,
      (headers) => _client.get(uri, headers: headers),
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _executeWithAuthRetry(
      endpoint,
      (reqHeaders) => _client.post(
        uri,
        headers: reqHeaders,
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
      extraHeaders: headers,
    );
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _executeWithAuthRetry(
      endpoint,
      (headers) => _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _executeWithAuthRetry(
      endpoint,
      (headers) => _client.delete(uri, headers: headers),
      requiresAuth: requiresAuth,
    );
  }
}
