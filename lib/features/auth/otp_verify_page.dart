import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kktc_market/core/services/auth_service.dart';
import 'package:kktc_market/features/auth/widgets/auth_layout.dart';

class OtpVerifyPage extends StatefulWidget {
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
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  // Tek bir controller ve focus node kullanıyoruz
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Otomatik odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyCode(String smsCode) async {
    if (smsCode.length < 6) return;

    _focusNode.unfocus();
    setState(() => _isLoading = true);

    try {
      final user = await _auth.signInWithSmsCode(
        widget.verificationId,
        smsCode,
      );

      if (user != null) {
        if (widget.firstName != null && widget.lastName != null) {
          await _auth.saveUserToFirestore(
            user,
            name: widget.firstName,
            surname: widget.lastName,
          );
        } else {
          await _auth.saveUserToFirestore(user);
        }

        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _otpController.clear();
        _focusNode.requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Hatalı kod! Lütfen tekrar deneyiniz."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            alignment: Alignment.center,
            children: [
              // 1. Gizli TextField (Arkada çalışır)
              Opacity(
                opacity: 0,
                child: TextField(
                  controller: _otpController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
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
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tekrar gönderme talebi alındı."),
                    ),
                  );
                  // TODO: Resend logic here
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
