import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:hoppa/shared/core/services/database_seeder.dart';
import 'consumer_otp_verify_page.dart';
import 'consumer_register_page.dart';
import 'widgets/auth_layout.dart';
import 'widgets/auth_text_field.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  // _isLoading Riverpod yardımıyla dinlenecek
  String _selectedCountryCode = "+90";
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // --- YENİ: Telefon ile Giriş Akışı (Riverpod Bağlantılı) ---
  void _loginWithPhone() {
    FocusScope.of(context).unfocus();

    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Telefon numarası giriniz")));
      return;
    }

    String phoneInput = _phoneController.text.trim();

    if (_selectedCountryCode == "+90") {
      if (phoneInput.length != 10 || !phoneInput.startsWith('5')) {
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
    }

    String phone = "$_selectedCountryCode$phoneInput";

    // Core Auth: OTP İsteği
    ref.read(authControllerProvider.notifier).sendOtp(phone);
  }

  void _guestLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bu özellik henüz aktif değil.")));
  }

  void _loginWithGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bu özellik henüz aktif değil.")));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final _isLoading = authState is AuthLoading || _isSeeding;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
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
              verificationId: "", // Eskiden kalma, kullanılmayacak
              phoneNumber: next.phoneNumber,
              firstName: '',
              lastName: '',
            ),
          ),
        );
      }
    });

    const kPrimaryColor = Color(0xFF00A651);
    const kSecondaryColor = Color(0xFFE95D22);

    return AuthLayout(
      // Enable glass effect for the card container
      enableGlass: true,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/hoppa_logo.png',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            // Slogan
            TypewriterSlogan(
              prefix: "Hoppa: ",
              phrases: const [
                "Siparişin en kısa yolu.",
                "Tıkla ve Rahatla.",
                "Mutluluk kapında.",
              ],
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kSecondaryColor,
              ),
            ),
            const SizedBox(height: 48),

            // Main Action Area
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "Giriş Yap",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "Devam etmek için telefon numaranızı giriniz.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 24),

            AuthTextField(
              controller: _phoneController,
              hint: "5xxxxxxxxx",
              icon: Icons.phone_android_rounded,
              isPhone: true,
              primaryColor: kPrimaryColor,
              selectedCode: _selectedCountryCode,
              onCodeChanged: (val) =>
                  setState(() => _selectedCountryCode = val),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginWithPhone,
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
                        "Giriş Yap",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                const Expanded(child: Divider(color: Colors.black12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "veya",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.black12)),
              ],
            ),

            const SizedBox(height: 32),

            // GOOGLE LOGIN
            SizedBox(
              height: 56,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _loginWithGoogle,
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  width: 24,
                  errorBuilder: (c, o, s) => const Icon(
                    Icons.g_mobiledata,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
                label: Text(
                  "Google ile Devam Et",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.5),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Hesabınız yok mu?",
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
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
                  child: Text(
                    "Hemen Üye Ol",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _guestLogin,
              child: Text(
                "Üye olmadan devam et",
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.grey.shade500,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // İŞLETME GİRİŞİ
            const SizedBox(height: 20),

            const SizedBox(height: 20),
            // GİZLİ MENU (Reset & Merchant Upgrade)
            GestureDetector(
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Verileri Sıfırla"),
                    content: const Text(
                      "Tüm veriler silinecek ve varsayılan veriler yüklenecek. Onaylıyor musunuz?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("İptal"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Sıfırla",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  setState(() => _isSeeding = true);
                  await DatabaseSeeder().seedSystem();
                  setState(() => _isSeeding = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Veriler başarıyla sıfırlandı!"),
                    ),
                  );
                }
              },
              onDoubleTap: () async {
                setState(() => _isSeeding = true);

                // Sadece veritabanı loglarını incelemek/tekrar seeder denemek için basit hook
                if (mounted) {
                  setState(() => _isSeeding = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Test Modu: Gizli menü sadece seeder çalıştırır.",
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "v1.0.0 (Dev)",
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade300,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypewriterSlogan extends StatefulWidget {
  final String prefix;
  final List<String> phrases;
  final TextStyle style;

  const TypewriterSlogan({
    super.key,
    required this.prefix,
    required this.phrases,
    required this.style,
  });

  @override
  State<TypewriterSlogan> createState() => _TypewriterSloganState();
}

class _TypewriterSloganState extends State<TypewriterSlogan> {
  int _phraseIndex = 0;
  String _currentText = "";
  bool _isTyping = true;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      if (_isTyping) {
        // Yazma efekti
        String targetPhrase = widget.phrases[_phraseIndex];
        for (int i = 0; i <= targetPhrase.length; i++) {
          if (!mounted) return;
          setState(() {
            _currentText = targetPhrase.substring(0, i);
          });
          await Future.delayed(const Duration(milliseconds: 100)); // Yazma hızı
        }

        // Yazma bitti, bekle
        if (!mounted) return;
        _isTyping = false;
        await Future.delayed(
          const Duration(seconds: 2),
        ); // Tam metin bekleme süresi
      } else {
        // Silme efekti
        for (int i = _currentText.length; i >= 0; i--) {
          if (!mounted) return;
          setState(() {
            _currentText = _currentText.substring(0, i);
          });
          await Future.delayed(const Duration(milliseconds: 50)); // Silme hızı
        }

        // Silme bitti, sonraki cümleye geç
        if (!mounted) return;
        _isTyping = true;
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % widget.phrases.length;
        });
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.prefix, style: widget.style),
        Text(_currentText, style: widget.style),
        // İmleç (Cursor)
        if (_isTyping)
          Text(
            "|",
            style: widget.style.copyWith(
              color: const Color(0xFFE95D22).withOpacity(0.5),
            ),
          ),
      ],
    );
  }
}

// Dalgalı Clipping Sınıfı
