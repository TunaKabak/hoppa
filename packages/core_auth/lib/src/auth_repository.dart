import 'dart:convert';
import 'package:core_network/core_network.dart';
import 'auth_user.dart';

abstract class IAuthRepository {
  Future<void> requestOtp(String phoneNumber);
  Future<AuthUser?> verifyOtp(
    String phoneNumber,
    String code, {
    String? name,
    String? surname,
  });
  Future<AuthUser?> checkAuthStatus();
  Future<void> logout();

  /// Merchant için e-posta + şifre ile giriş.
  /// Başarılı ise JWT kaydeder ve [AuthUser] (merchant bilgileriyle) döndürür.
  Future<AuthUser?> loginWithEmail(String email, String password);

  /// Yeni merchant kaydı.
  Future<void> registerMerchant({
    required String email,
    required String password,
    required String businessName,
    String? msNumber,
    String? taxNumber,
    String? phone,
    String? district,
    String? fullAddress,
  });

  /// Merchant revizyon bilgilerini backend'e gönderir.
  Future<void> submitMerchantRevision({
    required String merchantId,
    required String businessName,
    String? msNumber,
    String? taxNumber,
    String? phone,
    String? district,
    String? fullAddress,
  });

  /// Cihazda kayıtlı çoklu profilleri getirir.
  Future<List<Map<String, String>>> getSavedProfiles();

  /// Belirli bir profili cihazdan siler.
  Future<void> removeSavedProfile(String email);
}

class AuthRepository implements IAuthRepository {
  final ApiClient _apiClient;

  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userPhoneKey = 'user_phone';
  static const String _userNameKey = 'user_name';
  static const String _userSurnameKey = 'user_surname';
  static const String _userRoleKey = 'user_role';

  // Merchant-specific storage keys
  static const String _merchantEmailKey = 'merchant_email';
  static const String _merchantBusinessNameKey = 'merchant_business_name';
  static const String _merchantStatusKey = 'merchant_status';
  static const String _merchantRevisionMsgKey = 'merchant_revision_message';
  static const String _merchantBusinessIdKey = 'merchant_business_id';
  static const String _savedProfilesKey = 'saved_merchant_profiles';

  AuthRepository(this._apiClient);

  @override
  Future<void> requestOtp(String phoneNumber) async {
    await _apiClient.post(
      '/api/auth/request-otp',
      body: {'phoneNumber': phoneNumber},
      requiresAuth: false,
    );
  }

  @override
  Future<AuthUser?> verifyOtp(
    String phoneNumber,
    String code, {
    String? name,
    String? surname,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/verify-otp',
      body: {
        'phoneNumber': phoneNumber,
        'code': code,
        if (name != null) 'name': name,
        if (surname != null) 'surname': surname,
      },
      requiresAuth: false,
    );

    final data = response['data'];
    if (data != null && data['token'] != null) {
      await _apiClient.saveToken(data['token'].toString());

      final userMap = data['user'];
      if (userMap is Map<String, dynamic>) {
        final user = AuthUser.fromMap(userMap);
        await _saveUser(user);
        return user;
      }

      final minimalUser = AuthUser(id: '', phone: phoneNumber);
      return minimalUser;
    }
    return null;
  }

  @override
  Future<AuthUser?> loginWithEmail(String email, String password) async {
    final response = await _apiClient.post(
      '/api/merchant/auth/login',
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );

    // Backend: { error: false, data: { token, merchant: {...} } }
    final data = response['data'];
    if (data != null && data['token'] != null) {
      await _apiClient.saveToken(data['token'].toString());

      final merchantMap = data['merchant'];
      if (merchantMap is Map<String, dynamic>) {
        final user = AuthUser.fromMerchantMap(merchantMap);
        await _saveMerchantUser(user);
        await _appendSavedProfile(user);
        return user;
      }
    }
    return null;
  }

  @override
  Future<void> registerMerchant({
    required String email,
    required String password,
    required String businessName,
    String? msNumber,
    String? taxNumber,
    String? phone,
    String? district,
    String? fullAddress,
  }) async {
    await _apiClient.post(
      '/api/merchant/auth/register',
      body: {
        'email': email,
        'password': password,
        'businessName': businessName,
        if (msNumber != null) 'msNumber': msNumber,
        if (taxNumber != null) 'taxNumber': taxNumber,
        if (phone != null) 'phone': phone,
        if (district != null) 'district': district,
        if (fullAddress != null) 'fullAddress': fullAddress,
      },
      requiresAuth: false,
    );
  }

  @override
  Future<void> submitMerchantRevision({
    required String merchantId,
    required String businessName,
    String? msNumber,
    String? taxNumber,
    String? phone,
    String? district,
    String? fullAddress,
  }) async {
    await _apiClient.post(
      '/api/merchant/auth/submit-revision',
      body: {
        'merchantId': merchantId,
        'businessName': businessName,
        if (msNumber != null) 'msNumber': msNumber,
        if (taxNumber != null) 'taxNumber': taxNumber,
        if (phone != null) 'phone': phone,
        if (district != null) 'district': district,
        if (fullAddress != null) 'fullAddress': fullAddress,
      },
      requiresAuth: true,
    );
  }

  @override
  Future<AuthUser?> checkAuthStatus() async {
    final token = await _apiClient.getToken();
    if (token == null || token.isEmpty) return null;
    return await _getSavedUser();
  }

  @override
  Future<void> logout() async {
    await _apiClient.deleteToken();
    await _clearUser();
  }

  // --- Local Consumer User Storage ---
  Future<void> _saveUser(AuthUser user) async {
    await _apiClient.saveValue(_userIdKey, user.id);
    await _apiClient.saveValue(_userPhoneKey, user.phone);
    if (user.name != null) await _apiClient.saveValue(_userNameKey, user.name!);
    if (user.surname != null) await _apiClient.saveValue(_userSurnameKey, user.surname!);
    if (user.role != null) await _apiClient.saveValue(_userRoleKey, user.role!);
  }

  // --- Local Merchant User Storage ---
  Future<void> _saveMerchantUser(AuthUser user) async {
    await _apiClient.saveValue(_userIdKey, user.id);
    await _apiClient.saveValue(_userPhoneKey, user.phone);
    if (user.role != null) await _apiClient.saveValue(_userRoleKey, user.role!);
    if (user.email != null) await _apiClient.saveValue(_merchantEmailKey, user.email!);
    if (user.businessName != null) await _apiClient.saveValue(_merchantBusinessNameKey, user.businessName!);
    if (user.status != null) await _apiClient.saveValue(_merchantStatusKey, user.status!);
    if (user.revisionMessage != null) await _apiClient.saveValue(_merchantRevisionMsgKey, user.revisionMessage!);
    if (user.businessId != null) await _apiClient.saveValue(_merchantBusinessIdKey, user.businessId!);
  }

  Future<AuthUser?> _getSavedUser() async {
    final id = await _apiClient.getValue(_userIdKey);
    final phone = await _apiClient.getValue(_userPhoneKey);
    final role = await _apiClient.getValue(_userRoleKey);

    // Phone zorunlu değilse (Merchant) id veya email kontrolü yeterli
    if (id == null && phone == null) return null;

    return AuthUser(
      id: id ?? '',
      phone: phone ?? '',
      name: await _apiClient.getValue(_userNameKey),
      surname: await _apiClient.getValue(_userSurnameKey),
      role: role,
      email: await _apiClient.getValue(_merchantEmailKey),
      businessName: await _apiClient.getValue(_merchantBusinessNameKey),
      status: await _apiClient.getValue(_merchantStatusKey),
      revisionMessage: await _apiClient.getValue(_merchantRevisionMsgKey),
      businessId: await _apiClient.getValue(_merchantBusinessIdKey),
    );
  }

  Future<void> _clearUser() async {
    for (final key in [
      _userIdKey, _userPhoneKey, _userNameKey, _userSurnameKey, _userRoleKey,
      _merchantEmailKey, _merchantBusinessNameKey, _merchantStatusKey,
      _merchantRevisionMsgKey, _merchantBusinessIdKey,
    ]) {
      await _apiClient.deleteValue(key);
    }
  }

  // --- Saved Profiles Management ---

  @override
  Future<List<Map<String, String>>> getSavedProfiles() async {
    try {
      final val = await _apiClient.getValue(_savedProfilesKey);
      if (val == null || val.isEmpty) return [];
      final parsed = jsonDecode(val);
      if (parsed is List) {
        return parsed.map((item) {
          if (item is Map) {
            return item.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
          return <String, String>{};
        }).where((m) => m.isNotEmpty).toList();
      }
    } catch (e) {
      print('[AuthRepository] Failed to parse saved profiles: $e');
    }
    return [];
  }

  @override
  Future<void> removeSavedProfile(String email) async {
    try {
      final profiles = await getSavedProfiles();
      final filtered = profiles.where((p) => p['email'] != email).toList();
      await _apiClient.saveValue(_savedProfilesKey, jsonEncode(filtered));
    } catch (e) {
      print('[AuthRepository] Failed to remove saved profile: $e');
    }
  }

  Future<void> _appendSavedProfile(AuthUser user) async {
    if (user.email == null || user.email!.isEmpty) return;

    try {
      final profiles = await getSavedProfiles();
      // Remove any existing duplicate email
      final filtered = profiles.where((p) => p['email'] != user.email).toList();

      final newProfile = {
        'id': user.id,
        'email': user.email!,
        'businessName': user.businessName ?? user.displayName,
        'lastLoginAt': DateTime.now().toIso8601String(),
      };

      final updated = [newProfile, ...filtered];
      await _apiClient.saveValue(_savedProfilesKey, jsonEncode(updated));
    } catch (e) {
      print('[AuthRepository] Failed to append saved profile: $e');
    }
  }
}
