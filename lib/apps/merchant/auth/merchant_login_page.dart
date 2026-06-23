import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:hoppa/shared/core/services/database_seeder.dart';
import 'widgets/auth_layout.dart';
import 'widgets/auth_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'merchant_register_screen.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  List<Map<String, String>> _savedProfiles = [];
  Map<String, String>? _selectedProfile;
  bool _isChooserMode = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedProfiles();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _loadSavedProfiles() async {
    final repo = ref.read(authRepositoryProvider);
    final list = await repo.getSavedProfiles();
    setState(() {
      _savedProfiles = list;
      _isChooserMode = list.isNotEmpty;
    });
  }

  void _loginWithCredentials() async {
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen kullanıcı adı/e-posta ve şifrenizi giriniz"),
        ),
      );
      return;
    }

    await ref.read(authControllerProvider.notifier).loginWithEmail(username, password);
  }

  void _selectProfile(Map<String, String> profile) {
    setState(() {
      _selectedProfile = profile;
      _usernameController.text = profile['email'] ?? '';
      _passwordController.clear();
      _isChooserMode = false;
    });
    // Auto focus password node
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _passwordFocusNode.requestFocus();
      }
    });
  }

  void _removeProfile(String email) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.removeSavedProfile(email);
    final list = await repo.getSavedProfiles();
    setState(() {
      _savedProfiles = list;
      if (list.isEmpty) {
        _isChooserMode = false;
        _selectedProfile = null;
        _usernameController.clear();
      } else if (_selectedProfile?['email'] == email) {
        _selectedProfile = null;
        _isChooserMode = true;
      }
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      if (parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final hash = name.hashCode;
    final colors = [
      const Color(0xFF00A651), // Emerald
      const Color(0xFFE95D22), // Orange
      const Color(0xFF0288D1), // Light Blue
      const Color(0xFF795548), // Brown
      const Color(0xFFD81B60), // Pink
      const Color(0xFF673AB7), // Deep Purple
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryColor = Color(0xFF00A651);
    const kSecondaryColor = Color(0xFFE95D22);

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
      }
    });

    return AuthLayout(
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
            const SizedBox(height: 36),

            if (_isChooserMode) ...[
              // ACCOUNT CHOOSER VIEW
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Hesap Seçin",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Devam etmek istediğiniz işletmeyi seçin.",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _savedProfiles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final profile = _savedProfiles[index];
                    final name = profile['businessName'] ?? 'Bilinmeyen İşletme';
                    final email = profile['email'] ?? '';

                    return InkWell(
                      onTap: () => _selectProfile(profile),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: _getAvatarColor(name),
                              child: Text(
                                _getInitials(name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                              onPressed: () => _removeProfile(email),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isChooserMode = false;
                    _selectedProfile = null;
                    _usernameController.clear();
                    _passwordController.clear();
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text("Başka Bir Hesap Ekle"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  side: const BorderSide(color: kPrimaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ] else ...[
              // LOGIN FORM VIEW
              if (_selectedProfile != null) ...[
                // PASSWORD ONLY HEADER CARD
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isChooserMode = true;
                      });
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18, color: kPrimaryColor),
                    label: const Text(
                      "Hesap Seçimine Dön",
                      style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _getAvatarColor(_selectedProfile!['businessName'] ?? ''),
                        child: Text(
                          _getInitials(_selectedProfile!['businessName'] ?? ''),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedProfile!['businessName'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedProfile!['email'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                // STANDARD HEADERS
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
              ],

              if (_selectedProfile == null) ...[
                AuthTextField(
                  controller: _usernameController,
                  hint: "Kullanıcı Adı veya E-posta",
                  icon: Icons.store_mall_directory_rounded,
                  primaryColor: kPrimaryColor,
                ),
                const SizedBox(height: 16),
              ],

              AuthTextField(
                controller: _passwordController,
                hint: "Şifre",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                focusNode: _passwordFocusNode,
                primaryColor: kPrimaryColor,
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _loginWithCredentials,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
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

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MerchantRegisterScreen()),
                  );
                },
                child: Text(
                  "Hesabınız yok mu? İşletme Başvurusu Yap",
                  style: GoogleFonts.inter(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            // GİZLİ MENU
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
                  await DatabaseSeeder().seedSystem();
                  if (!context.mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Veriler başarıyla sıfırlandı!"),
                    ),
                  );
                  _loadSavedProfiles();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "v1.0.0 (Custom Backend)",
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
        String targetPhrase = widget.phrases[_phraseIndex];
        for (int i = 0; i <= targetPhrase.length; i++) {
          if (!mounted) return;
          setState(() {
            _currentText = targetPhrase.substring(0, i);
          });
          await Future.delayed(const Duration(milliseconds: 100));
        }

        if (!mounted) return;
        _isTyping = false;
        await Future.delayed(const Duration(seconds: 2));
      } else {
        for (int i = _currentText.length; i >= 0; i--) {
          if (!mounted) return;
          setState(() {
            _currentText = _currentText.substring(0, i);
          });
          await Future.delayed(const Duration(milliseconds: 50));
        }

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
        if (_isTyping)
          Text(
            "|",
            style: widget.style.copyWith(
              color: const Color(0xFFE95D22).withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}


class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
        Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
