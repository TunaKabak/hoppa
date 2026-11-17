import 'dart:async';
import 'dart:ui';
import 'package:core_auth/core_auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as p;
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:consumer_app/apps/consumer/repositories/address_repository.dart';
import 'package:consumer_app/apps/consumer/checkout/checkout_page.dart';
import 'widgets/auth_layout.dart';
import 'name_surname_input_page.dart';

class OtpVerifyPage extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;

  const OtpVerifyPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
  });

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _timer;
  int _secondsRemaining = 180;
  final GlobalKey _otpInputKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted && _otpInputKey.currentContext != null) {
            Scrollable.ensureVisible(
              _otpInputKey.currentContext!,
              alignment: 0.5,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 180;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _timerText {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPhoneDisplay(String raw) {
    if (raw.startsWith('+90') && raw.length == 13) {
      final n = raw.substring(3);
      return '+90 ${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6, 8)} ${n.substring(8, 10)}';
    }
    return raw;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyCode(String smsCode) {
    if (smsCode.length < 6) return;
    _focusNode.unfocus();

    ref.read(authControllerProvider.notifier).verifyOtp(
          widget.phoneNumber,
          smsCode,
          name: widget.firstName,
          surname: widget.lastName,
        );
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
    final boxBg = isDark
        ? HoppaDesignTokens.surfaceSubtleDark
        : HoppaDesignTokens.surfaceSubtleLight;
    final borderDefault =
        isDark ? HoppaDesignTokens.borderDark : HoppaDesignTokens.borderLight;

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      if (!mounted) return;
      if (next is AuthError) {
        _otpController.clear();
        _focusNode.requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: HoppaDesignTokens.statusDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next is AuthAuthenticated) {
        final user = next.user;
        final isNew =
            user.name == 'Misafir' && user.surname == 'Kullanıcı';
        final fromCheckout =
            widget.firstName == 'checkout' || widget.lastName == 'checkout';

        if (isNew) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NameSurnameInputPage(
                fromCheckout: fromCheckout,
              ),
            ),
          );
        } else {
          final deliveryProvider =
              p.Provider.of<DeliveryProvider>(context, listen: false);
          final guestAddress = deliveryProvider.selectedAddress;

          if (guestAddress != null && guestAddress.id.startsWith('guest')) {
            try {
              final addressRepo = ref.read(addressRepositoryProvider);
              final savedAddress = await addressRepo.createAddress(guestAddress);
              await deliveryProvider.setAddress(savedAddress);
            } catch (e) {
              debugPrint('Guest address migration failed: $e');
            }
          }

          if (!context.mounted) return;
          if (fromCheckout) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CheckoutPage()),
              (route) => route.isFirst,
            );
          } else {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        }
      }
    });

    return AuthLayout(
      showAppBar: true,
      enableGlass: true,
      leading: IconButton(
        tooltip: 'Geri Dön',
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: primary.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 30,
              color: primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Doğrulama Kodu',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aşağıdaki numaraya gönderilen 6 haneli tek kullanımlık kodu girin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: boxBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatPhoneDisplay(widget.phoneNumber),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: HoppaDesignTokens.brandOrange,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Düzenle',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: HoppaDesignTokens.brandOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Stack(
            key: _otpInputKey,
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0,
                child: TextField(
                  controller: _otpController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  onChanged: (value) {
                    setState(() {});
                    if (value.length == 6) {
                      _verifyCode(value);
                    }
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  final focusScope = FocusScope.of(context);
                  if (!_focusNode.hasFocus) {
                    focusScope.requestFocus(_focusNode);
                  } else {
                    _focusNode.unfocus();
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted) focusScope.requestFocus(_focusNode);
                    });
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final char = index < _otpController.text.length
                        ? _otpController.text[index]
                        : '';
                    final isFilled = char.isNotEmpty;
                    final isFocused = index == _otpController.text.length &&
                        _otpController.text.length < 6;

                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isFilled
                              ? primary.withValues(alpha: 0.08)
                              : boxBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (isFocused && !isLoading) || isFilled
                                ? primary
                                : borderDefault,
                            width: isFocused && !isLoading ? 2.0 : 1.3,
                          ),
                        ),
                        child: Text(
                          char,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading || _otpController.text.length < 6
                  ? null
                  : () => _verifyCode(_otpController.text),
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
                  : Text(
                      'Doğrula ve Devam Et',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          if (_secondsRemaining > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: boxBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderDefault),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 15, color: textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Yeni kod için ',
                    style: GoogleFonts.plusJakartaSans(
                      color: textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _timerText,
                    style: GoogleFonts.plusJakartaSans(
                      color: textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            )
          else
            TextButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yeni doğrulama kodu gönderiliyor...'),
                        ),
                      );
                      _startTimer();
                      ref
                          .read(authControllerProvider.notifier)
                          .sendOtp(widget.phoneNumber);
                    },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: HoppaDesignTokens.brandOrange,
              ),
              label: Text(
                'Doğrulama Kodunu Tekrar Gönder',
                style: GoogleFonts.plusJakartaSans(
                  color: HoppaDesignTokens.brandOrange,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
