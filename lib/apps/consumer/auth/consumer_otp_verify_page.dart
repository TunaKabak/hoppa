import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'widgets/auth_layout.dart';

class OtpVerifyPage extends ConsumerStatefulWidget {
  final String verificationId; // Eskiden kalma, doğrudan param olarak durabilir
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
  // _isLoading Riverpod yardımıyla dinlenecek

  // Tek bir controller ve focus node kullanıyoruz
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
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _otpInputKey.currentContext != null) {
            Scrollable.ensureVisible(
              _otpInputKey.currentContext!,
              alignment: 0.5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    // Otomatik odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 180;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _timerText {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
    
    // Core Auth: OTP Doğrulama İsteği
    ref.read(authControllerProvider.notifier).verifyOtp(
      widget.phoneNumber,
      smsCode,
      name: widget.firstName,
      surname: widget.lastName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final _isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next is AuthError) {
        _otpController.clear();
        _focusNode.requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next is AuthAuthenticated) {
        // Giriş yapıldı, anasayfaya dön veya yönlendir.
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });

    const kPrimaryColor = Color(0xFF00A651);
    const kSecondaryColor = Color(0xFFE95D22);

    return AuthLayout(
      showAppBar: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon visual
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_open_rounded,
              size: 48,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            "Doğrulama Kodu",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: widget.phoneNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const TextSpan(text: "\nnumarasına gönderilen kodu giriniz."),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // --- GİZLİ INPUT VE GÖRSEL KUTULAR ---
          Stack(
            key: _otpInputKey,
            alignment: Alignment.center,
            children: [
              // 1. Gizli TextField (Arkada çalışır)
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
                    setState(() {}); // Görseli güncelle
                    if (value.length == 6) {
                      _verifyCode(value);
                    }
                  },
                ),
              ),

              // 2. Görsel Kutular (Önde gösterilir)
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    String char = "";
                    if (index < _otpController.text.length) {
                      char = _otpController.text[index];
                    }

                    bool isFocused = index == _otpController.text.length;

                    return Container(
                      width: 45,
                      height: 55,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: isFocused && !_isLoading
                            ? Border.all(color: kPrimaryColor, width: 2)
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        char,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kSecondaryColor,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _verifyCode(_otpController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Doğrula",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Kod gelmedi mi? ",
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
              if (_secondsRemaining > 0)
                Text(
                  _timerText,
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Yeni kod gönderiliyor...")),
                    );
                    _startTimer();

                    // Core Auth ile yeni SMS isteğinde bulun
                    ref.read(authControllerProvider.notifier).sendOtp(widget.phoneNumber);
                  },
                  child: Text(
                    "Tekrar Gönder",
                    style: GoogleFonts.inter(
                      color: kSecondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
