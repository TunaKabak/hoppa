import 'package:flutter/material.dart';
import 'package:hoppa/apps/consumer/auth/consumer_auth_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConsumerAuthWrapper()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Logo rengi turuncu olduğu için arka planı Beyaz yapıyoruz ki net görünsün.
    // İstenirse turuncu arka plan yapılıp logo beyaz yapılabilir (ancak elimizdeki logo renkli).
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Merkez Logo ve Slogan
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Image.asset(
                    'assets/images/hoppa_logo.png',
                    width: 200,
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _controller,
                  child: Text(
                    "Hoppa: Siparişin en kısa yolu.",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: const Color(0xFFE95D22), // Turuncu tonu (logodan)
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alt Kısım: Yükleniyor...
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00A651),
                      ), // Yeşil şerit
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Yükleniyor...",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
