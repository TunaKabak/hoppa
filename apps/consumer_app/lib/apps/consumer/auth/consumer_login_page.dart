import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'consumer_otp_verify_page.dart';
import 'consumer_register_page.dart';
import 'widgets/auth_layout.dart';
import 'widgets/auth_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  final bool fromCheckout;
  const LoginPage({super.key, this.fromCheckout = false});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  String _selectedCountryCode = "+90";

  static const Color _kPrimaryColor = Color(0xFF00A651);
  static const Color _kSecondaryColor = Color(0xFFFF6B00);
  static const Color _kTextDark = Color(0xFF1F2937);
  static const Color _kTextMuted = Color(0xFF6B7280);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _loginWithPhone() {
    FocusScope.of(context).unfocus();

    final phoneInput = _phoneController.text.trim();
    if (phoneInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telefon numarası giriniz")),
      );
      return;
    }

    if (_selectedCountryCode == "+90" &&
        (phoneInput.length != 10 || !phoneInput.startsWith('5'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Lütfen geçerli bir telefon numarası giriniz (5xxxxxxxxx)",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final phone = "$_selectedCountryCode$phoneInput";
    ref.read(authControllerProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next is OtpSentState) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerifyPage(
              verificationId: "",
              phoneNumber: next.phoneNumber,
              firstName: widget.fromCheckout ? 'checkout' : '',
              lastName: widget.fromCheckout ? 'checkout' : '',
            ),
          ),
        );
      }
    });

    final canPop = Navigator.canPop(context);

    return AuthLayout(
      enableGlass: true,
      leading: canPop
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _kTextDark,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/images/hoppa_logo.png',
              height: 64,
              cacheHeight: 192,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kPrimaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Hızlı Teslimat • Güvenli Alışveriş",
                style: TextStyle(
                  color: _kPrimaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Hoppa'ya Hoş Geldiniz",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kTextDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Giriş yapmak veya devam etmek için cep telefonu numaranızı girin.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _kTextMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Cep Telefonu Numarası",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          AuthTextField(
            controller: _phoneController,
            hint: "5XX XXX XX XX",
            icon: Icons.phone_android_rounded,
            isPhone: true,
            primaryColor: _kPrimaryColor,
            selectedCode: _selectedCountryCode,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isLoading) _loginWithPhone();
            },
            onCodeChanged: (val) =>
                setState(() => _selectedCountryCode = val),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _loginWithPhone,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : const Text(
                      "Doğrulama Kodu Gönder",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.sms_outlined,
                  size: 16,
                  color: _kTextMuted,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Telefonunuza 6 haneli tek kullanımlık SMS doğrulama kodu gönderilecektir.",
                  style: TextStyle(
                    fontSize: 12,
                    color: _kTextMuted,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE5E7EB), height: 1),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                "Hesabınız yok mu?",
                style: TextStyle(
                  fontSize: 14,
                  color: _kTextMuted,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text(
                  "Hemen Üye Ol",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (canPop)
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text(
                  "Üye olmadan devam et",
                  style: TextStyle(
                    color: _kTextMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
