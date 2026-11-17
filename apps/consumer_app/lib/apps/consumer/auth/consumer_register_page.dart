import 'package:core_auth/core_auth.dart';
import 'package:core_shared/core_shared.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _selectedCountryCode = '+90';

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _startRegister() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);

    final firstName = _nameController.text.trim();
    final lastName = _surnameController.text.trim();
    var digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (firstName.isEmpty || lastName.isEmpty || digits.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Lütfen ad, soyad ve telefon alanlarını doldurun.')),
      );
      return;
    }

    if (_selectedCountryCode == '+90') {
      if (digits.startsWith('90') && digits.length == 12) {
        digits = digits.substring(2);
      }
      if (digits.startsWith('0') && digits.length == 11) {
        digits = digits.substring(1);
      }
      if (digits.length != 10 || !digits.startsWith('5')) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Lütfen 5XX XXX XX XX biçiminde 10 haneli numara girin.'),
            backgroundColor: HoppaDesignTokens.statusDanger,
          ),
        );
        return;
      }
    } else if (digits.length < 7) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir telefon numarası girin.'),
          backgroundColor: HoppaDesignTokens.statusDanger,
        ),
      );
      return;
    }

    final phone = '$_selectedCountryCode$digits';
    setState(() => _isLoading = true);

    try {
      final response = await ref
          .read(apiClientProvider)
          .get('/api/auth/check-phone/${Uri.encodeComponent(phone)}');
      final exists = response['data']?['exists'] == true;

      if (exists) {
        if (mounted) {
          setState(() => _isLoading = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Bu numara zaten kayıtlı. Giriş ekranından devam edebilirsiniz.',
              ),
              backgroundColor: HoppaDesignTokens.statusWarning,
            ),
          );
        }
        return;
      }

      await ref.read(authControllerProvider.notifier).sendOtp(phone);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Bağlantı kurulamadı. Lütfen tekrar deneyin.'),
            backgroundColor: HoppaDesignTokens.statusDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final textPrimary = isDark
        ? HoppaDesignTokens.textPrimaryDark
        : HoppaDesignTokens.textPrimaryLight;
    final textSecondary = isDark
        ? HoppaDesignTokens.textSecondaryDark
        : HoppaDesignTokens.textSecondaryLight;
    final borderSubtle =
        isDark ? HoppaDesignTokens.borderDark : HoppaDesignTokens.borderLight;

    final authState = ref.watch(authControllerProvider);
    final isAuthLoading = authState is AuthLoading || _isLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next is AuthError) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: HoppaDesignTokens.statusDanger,
          ),
        );
      } else if (next is OtpSentState) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerifyPage(
              verificationId: '',
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
      enableGlass: true,
      leading: IconButton(
        tooltip: 'Geri Dön',
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: HoppaBrandLogo(height: 44)),
          const SizedBox(height: 16),
          Text(
            'Yeni Hesap Oluştur',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hızlı teslimatlar ve sipariş takibi için temel bilgilerinizi tamamlayın.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          _buildInputLabel('Adınız', textPrimary),
          const SizedBox(height: 8),
          AuthTextField(
            controller: _nameController,
            hint: 'Örn: Ahmet',
            icon: Icons.person_outline_rounded,
            primaryColor: primary,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildInputLabel('Soyadınız', textPrimary),
          const SizedBox(height: 8),
          AuthTextField(
            controller: _surnameController,
            hint: 'Örn: Yılmaz',
            icon: Icons.badge_outlined,
            primaryColor: primary,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildInputLabel('Cep Telefonu Numarası', textPrimary),
          const SizedBox(height: 8),
          AuthTextField(
            controller: _phoneController,
            hint: '5XX XXX XX XX',
            icon: Icons.phone_android_rounded,
            isPhone: true,
            primaryColor: primary,
            selectedCode: _selectedCountryCode,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isAuthLoading) _startRegister();
            },
            onCodeChanged: (val) =>
                setState(() => _selectedCountryCode = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isAuthLoading ? null : _startRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isAuthLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Doğrulama Kodu Gönder',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 19),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: borderSubtle, height: 1),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: RichText(
              text: TextSpan(
                text: 'Zaten hesabınız var mı? ',
                style: GoogleFonts.plusJakartaSans(
                  color: textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: 'Giriş Yap',
                    style: GoogleFonts.plusJakartaSans(
                      color: HoppaDesignTokens.brandOrange,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
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

  Widget _buildInputLabel(String label, Color color) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
