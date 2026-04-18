import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_network/core_network.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return AuthChecking();
  }

  Future<void> _init() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      // 401 geldiğinde bu controller'ın logout'unu tetikle
      apiClient.onUnauthorized = () {
        if (state is! AuthInitial) {
          state = AuthInitial();
        }
      };

      final repo = ref.read(authRepositoryProvider);
      final user = await repo.checkAuthStatus();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthInitial();
      }
    } catch (_) {
      state = AuthInitial();
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = AuthInitial();
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.requestOtp(phoneNumber);
      state = OtpSentState(phoneNumber);
    } on AppException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError("Bilinmeyen bir hata oluştu: ${e.toString()}");
    }
  }

  Future<void> verifyOtp(String phoneNumber, String code) async {
    state = AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.verifyOtp(phoneNumber, code);
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthError("Doğrulama başarısız oldu. Gelen yanıtta token bulunamadı.");
      }
    } on AppException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError("Bilinmeyen bir hata oluştu: ${e.toString()}");
    }
  }
}

// --- Dependency Injection / Providers ---

String getLocalBaseUrl() {
  // ADB Reverse kullanıldığı için doğrudan localhost verebiliriz.
  return 'http://127.0.0.1:3000';
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: getLocalBaseUrl());
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
