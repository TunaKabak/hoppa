import 'package:flutter/material.dart';
import 'package:hoppa/core/services/auth_service.dart';
import 'package:hoppa/features/auth/otp_verify_page.dart';
import 'package:hoppa/features/auth/widgets/auth_layout.dart';
import 'package:hoppa/features/auth/widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final AuthService _auth = AuthService();
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
    FocusScope.of(context).unfocus();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_nameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String phoneInput = _phoneController.text.trim();

    if (_selectedCountryCode == "+90" &&
        (phoneInput.length != 10 || !phoneInput.startsWith('5'))) {
      setState(() => _isLoading = false);
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

    bool exists = await _auth.checkUserExists(phone);
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

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      codeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() => _isLoading = false);
          navigator.push(
            MaterialPageRoute(
              builder: (context) => OtpVerifyPage(
                verificationId: verificationId,
                phoneNumber: phone,
                firstName: _nameController.text.trim(),
                lastName: _surnameController.text.trim(),
              ),
            ),
          );
        }
      },
      verificationFailed: (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          messenger.showSnackBar(SnackBar(content: Text("Hata: ${e.message}")));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
              onPressed: _isLoading ? null : _startRegister,
              child: _isLoading
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
