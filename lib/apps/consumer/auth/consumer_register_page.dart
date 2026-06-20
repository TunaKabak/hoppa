import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'consumer_otp_verify_page.dart';
import 'widgets/auth_layout.dart';
import 'widgets/auth_text_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _selectedCountryCode = "+90";

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startRegister() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);

    if (_nameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    String phoneInput = _phoneController.text.trim();

    if (_selectedCountryCode == "+90" &&
        (phoneInput.length != 10 || !phoneInput.startsWith('5'))) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Lütfen geçerli bir telefon numarası giriniz (5xxxxxxxxx)",
          ),
        ),
      );
      return;
    }

    String phone = "$_selectedCountryCode$phoneInput";

    setState(() => _isLoading = true);

    try {
      // Check if user exists on the NestJS backend
      final response = await ref.read(apiClientProvider).get('/api/auth/check-phone/$phone');
      final exists = response['data']?['exists'] == true;

      if (exists) {
        if (mounted) {
          setState(() => _isLoading = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                "Bu numara ile zaten kayıtlı bir kullanıcı var. Lütfen giriş yapınız.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Send OTP via backend
      ref.read(authControllerProvider.notifier).sendOtp(phone);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text("Bir hata oluştu: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final authState = ref.watch(authControllerProvider);
    final isAuthLoading = authState is AuthLoading || _isLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next is AuthError) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next is OtpSentState) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerifyPage(
              verificationId: "",
              phoneNumber: next.phoneNumber,
              firstName: _nameController.text.trim(),
              lastName: _surnameController.text.trim(),
            ),
          ),
        );
      }
    });

    return AuthLayout(
      showAppBar: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: theme.colorScheme.onSurface,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/hoppa_logo.png',
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Hemen Başlayın",
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Siparişlerinizi takip etmek için bilgilerinizi eksiksiz giriniz.",
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _buildInputLabel("Adınız", textTheme),
          const SizedBox(height: 8),
          AuthTextField(
            controller: _nameController,
            hint: "Adınızı giriniz",
            icon: Icons.person_rounded,
            primaryColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _buildInputLabel("Soyadınız", textTheme),
          const SizedBox(height: 8),
          AuthTextField(
            controller: _surnameController,
            hint: "Soyadınızı giriniz",
            icon: Icons.person_outline_rounded,
            primaryColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _buildInputLabel("Telefon Numarası", textTheme),
          const SizedBox(height: 8),
          AuthTextField(
            controller: _phoneController,
            hint: "5xxxxxxxxx",
            icon: Icons.phone_android_rounded,
            isPhone: true,
            primaryColor: theme.colorScheme.primary,
            selectedCode: _selectedCountryCode,
            onCodeChanged: (val) => setState(() => _selectedCountryCode = val),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isAuthLoading ? null : _startRegister,
              child: isAuthLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Doğrulama Kodu Gönder"),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: RichText(
              text: TextSpan(
                text: "Zaten hesabınız var mı? ",
                style: textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: "Giriş Yap",
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, TextTheme textTheme) {
    return Text(label, style: textTheme.labelSmall);
  }
}
