import 'package:flutter/material.dart';
import 'package:hoppa/apps/merchant/services/merchant_auth_service.dart';
import 'package:hoppa/shared/core/services/database_seeder.dart';
import 'widgets/auth_layout.dart';
import 'widgets/auth_text_field.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final MerchantAuthService _auth = MerchantAuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

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
    _usernameController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // --- YENİ: API ile B2B Giriş Akışı ---
  void _loginWithCredentials() async {
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen kullanıcı adı ve şifrenizi giriniz"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.loginWithCredentials(username, password);
      // Başarılı girişte wrapper otomatik yönlendirecek
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'assets/images/hoppa_merchant_logo.jpg',
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
                "İşletme paneline erişmek için bilgilerinizi giriniz.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 24),

            AuthTextField(
              controller: _usernameController,
              hint: "Kullanıcı Adı",
              icon: Icons.store_mall_directory_rounded,
              primaryColor: kPrimaryColor,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              hint: "Şifre",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              primaryColor: kPrimaryColor,
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginWithCredentials,
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

            // Veya kaldırıldı, sadece tek giriş metodu
            const SizedBox(height: 16),

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
                  setState(() => _isLoading = true);
                  await DatabaseSeeder().seedSystem();
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Veriler başarıyla sıfırlandı!"),
                    ),
                  );
                }
              },
              onDoubleTap: () async {
                if (mounted) {
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
