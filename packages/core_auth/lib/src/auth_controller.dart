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

  Future<void> verifyOtp(
    String phoneNumber,
    String code, {
    String? name,
    String? surname,
  }) async {
    state = AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.verifyOtp(
        phoneNumber,
        code,
        name: name,
        surname: surname,
      );
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

  Future<void> loginWithEmail(String email, String password) async {
    state = AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.loginWithEmail(email, password);
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthError("Giriş başarısız oldu. Hatalı e-posta veya şifre.");
      }
    } on AppException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError("Bilinmeyen bir hata oluştu: ${e.toString()}");
    }
  }

  Future<void> submitMerchantRevision({
    required String businessName,
    String? msNumber,
    String? taxNumber,
    String? phone,
    String? district,
    String? fullAddress,
  }) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    state = AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.submitMerchantRevision(
        merchantId: currentState.user.id,
        businessName: businessName,
        msNumber: msNumber,
        taxNumber: taxNumber,
        phone: phone,
        district: district,
        fullAddress: fullAddress,
      );

      // Başarılı güncelleme sonrası state'i PENDING yapıyoruz (User modelini güncelleyerek)
      final updatedUser = currentState.user.copyWith(
        status: 'PENDING',
        revisionMessage: null,
      );
      state = AuthAuthenticated(updatedUser);
    } on AppException catch (e) {
      state = AuthAuthenticated(currentState.user);
      rethrow;
    } catch (e) {
      state = AuthAuthenticated(currentState.user);
      rethrow;
    }
  }
}


// --- Dependency Injection / Providers ---

String getBaseUrl() {
  return 'https://hoppa-backend.onrender.com';
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: getBaseUrl());
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
