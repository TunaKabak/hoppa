import 'package:core_network/core_network.dart';
import 'auth_user.dart';

abstract class IAuthRepository {
  Future<void> requestOtp(String phoneNumber);
  Future<AuthUser?> verifyOtp(String phoneNumber, String code);
  Future<AuthUser?> checkAuthStatus();
  Future<void> logout();
}

class AuthRepository implements IAuthRepository {
  final ApiClient _apiClient;

  static const String _userIdKey = 'user_id';
  static const String _userPhoneKey = 'user_phone';
  static const String _userNameKey = 'user_name';
  static const String _userSurnameKey = 'user_surname';
  static const String _userRoleKey = 'user_role';

  AuthRepository(this._apiClient);

  @override
  Future<void> requestOtp(String phoneNumber) async {
    // Requires no auth
    await _apiClient.post(
      '/api/auth/request-otp',
      body: {'phoneNumber': phoneNumber},
      requiresAuth: false,
    );
  }

  @override
  Future<AuthUser?> verifyOtp(String phoneNumber, String code) async {
    final response = await _apiClient.post(
      '/api/auth/verify-otp',
      body: {'phoneNumber': phoneNumber, 'code': code},
      requiresAuth: false,
    );

    // Backend response: { data: { token: "...", user: {...} } }
    final data = response['data'];
    if (data != null && data['token'] != null) {
      await _apiClient.saveToken(data['token'].toString());

      // Kullanıcı bilgilerini kaydet
      final userMap = data['user'];
      if (userMap is Map<String, dynamic>) {
        final user = AuthUser.fromMap(userMap);
        await _saveUser(user);
        return user;
      }

      // Kullanıcı verisi yoksa telefon numarasıyla minimal bir kullanıcı dön
      final minimalUser = AuthUser(id: '', phone: phoneNumber);
      return minimalUser;
    }
    return null;
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

  // --- Local User Storage ---
  Future<void> _saveUser(AuthUser user) async {
    await _apiClient.saveValue(_userIdKey, user.id);
    await _apiClient.saveValue(_userPhoneKey, user.phone);
    if (user.name != null) await _apiClient.saveValue(_userNameKey, user.name!);
    if (user.surname != null) await _apiClient.saveValue(_userSurnameKey, user.surname!);
    if (user.role != null) await _apiClient.saveValue(_userRoleKey, user.role!);
  }

  Future<AuthUser?> _getSavedUser() async {
    final id = await _apiClient.getValue(_userIdKey);
    final phone = await _apiClient.getValue(_userPhoneKey);
    if (phone == null) return null;
    return AuthUser(
      id: id ?? '',
      phone: phone,
      name: await _apiClient.getValue(_userNameKey),
      surname: await _apiClient.getValue(_userSurnameKey),
      role: await _apiClient.getValue(_userRoleKey),
    );
  }

  Future<void> _clearUser() async {
    await _apiClient.deleteValue(_userIdKey);
    await _apiClient.deleteValue(_userPhoneKey);
    await _apiClient.deleteValue(_userNameKey);
    await _apiClient.deleteValue(_userSurnameKey);
    await _apiClient.deleteValue(_userRoleKey);
  }
}
