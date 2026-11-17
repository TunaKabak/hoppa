import 'package:core_auth/core_auth.dart';
import 'package:core_shared/core_shared.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _selectedCountryCode = '+90';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _buildValidatedPhone() {
    var digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen cep telefonu numaranızı girin.')),
      );
      return null;
    }

    if (_selectedCountryCode == '+90') {
      if (digits.startsWith('90') && digits.length == 12) {
        digits = digits.substring(2);
      }
      if (digits.startsWith('0') && digits.length == 11) {
        digits = digits.substring(1);
      }
      if (digits.length != 10 || !digits.startsWith('5')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen 5XX XXX XX XX biçiminde 10 haneli numara girin.'),
            backgroundColor: HoppaDesignTokens.statusDanger,
          ),
        );
        return null;
      }
    } else if (digits.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir telefon numarası girin.'),
          backgroundColor: HoppaDesignTokens.statusDanger,
        ),
      );
      return null;
    }

    return '$_selectedCountryCode$digits';
  }

  void _loginWithPhone() {
    FocusScope.of(context).unfocus();
    final phone = _buildValidatedPhone();
    if (phone == null) return;
    ref.read(authControllerProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? HoppaDesignTokens.textPrimaryDark
        : HoppaDesignTokens.textPrimaryLight;
    final textSecondary = isDark
        ? HoppaDesignTokens.textSecondaryDark
        : HoppaDesignTokens.textSecondaryLight;
    final borderSubtle =
        isDark ? HoppaDesignTokens.borderDark : HoppaDesignTokens.borderLight;
    final primary = theme.colorScheme.primary;

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: HoppaDesignTokens.statusDanger,
          ),
        );
      } else if (next is OtpSentState) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerifyPage(
              verificationId: '',
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
              tooltip: 'Geri Dön',
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: textPrimary,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: HoppaBrandLogo(height: 44)),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 15, color: primary),
                  const SizedBox(width: 5),
                  Text(
                    'KKTC Hızlı Market & Yemek',
                    style: GoogleFonts.plusJakartaSans(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Hoppa'ya Hoş Geldiniz",
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
            'Siparişlerinizi oluşturmak ve anlık takip etmek için telefon numaranızla devam edin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cep Telefonu Numarası',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
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
              if (!isLoading) _loginWithPhone();
            },
            onCodeChanged: (val) =>
                setState(() => _selectedCountryCode = val),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _loginWithPhone,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? HoppaDesignTokens.surfaceSubtleDark
                  : HoppaDesignTokens.surfaceSubtleLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sms_outlined, size: 16, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Telefonunuza 6 haneli tek kullanımlık doğrulama kodu gönderilir; şifre gerekmez.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: borderSubtle, height: 1),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: HoppaDesignTokens.brandOrange,
                side: BorderSide(
                  color: HoppaDesignTokens.brandOrange.withValues(alpha: 0.45),
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Yeni Hesap Oluştur',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (canPop) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(
                  'Üye olmadan mağazalara göz at',
                  style: GoogleFonts.plusJakartaSans(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
