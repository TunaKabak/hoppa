import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';

class ReferralPage extends ConsumerStatefulWidget {
  const ReferralPage({super.key});

  @override
  ConsumerState<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends ConsumerState<ReferralPage> {
  bool _isLoading = true;
  String _referralCode = '';
  int _referralCount = 0;
  double _totalEarnings = 0.0;
  List<dynamic> _referrals = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReferralData();
  }

  Future<void> _fetchReferralData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/api/consumer/referral');
      final data = response['data'];

      if (data != null) {
        setState(() {
          _referralCode = data['referralCode'] ?? '';
          _referralCount = data['referralCount'] ?? 0;
          _totalEarnings = double.tryParse(data['totalEarnings'].toString()) ?? 0.0;
          _referrals = data['referrals'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Davet bilgileri alınamadı.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Davet kodunuz kopyalandı!'),
        backgroundColor: Color(0xFF00A651),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareReferralCode() {
    final text = 'Hoppa uygulamasında lezzetli yemekler, taze market ürünleri ve daha fazlası kapınızda! 🚀\n'
        'Benim davet kodumu kullanarak üye ol, ilk siparişine 100 TL indirim kazan! 🎁\n'
        'Davet Kodum: $_referralCode\n'
        'Hemen indir: https://hoppanow.com';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE95D22), // Hoppa Orange
              Color(0xFFFF8C00), // Orange-Yellow
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          children: [
            HoppaHeader(
              height: 70,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 48.0),
                        child: Text(
                          'Davet Et & Kazan!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE95D22)))
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                                  const SizedBox(height: 16),
                                  Text(_errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _fetchReferralData,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE95D22)),
                                    child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
                                  )
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchReferralData,
                              color: const Color(0xFFE95D22),
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Info Card / Banner
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.02),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                        border: Border.all(color: Colors.grey.shade100),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00A651).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.card_giftcard_rounded,
                                              color: Color(0xFF00A651),
                                              size: 40,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Arkadaşlarını Davet Et, Kazan!',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.outfit(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Davet kodunla üye olan arkadaşlarının yapacağı ilk alışverişte hem sen 100 TL Hoppa Para kazan hem de arkadaşın 100 TL indirim kazansın!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Promo Code Card
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.02),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                        border: Border.all(color: Colors.grey.shade100),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'BENİM DAVET KODUM',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _referralCode,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFFE95D22),
                                                    letterSpacing: 2.0,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                IconButton(
                                                  icon: const Icon(Icons.copy_rounded, color: Colors.grey),
                                                  onPressed: _copyToClipboard,
                                                  constraints: const BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                )
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 50,
                                            child: ElevatedButton.icon(
                                              onPressed: _shareReferralCode,
                                              icon: const Icon(Icons.share_rounded, color: Colors.white),
                                              label: const Text(
                                                'Kodu Arkadaşlarınla Paylaş',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFE95D22),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Stats Row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
                                            'Davet Sayısı',
                                            '$_referralCount Kişi',
                                            Icons.people_alt_rounded,
                                            Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildStatCard(
                                            'Kazanılan Ödül',
                                            '${_totalEarnings.toStringAsFixed(0)} TL',
                                            Icons.stars_rounded,
                                            const Color(0xFF00A651),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // Referral List Title
                                    Text(
                                      'Davet Ettiklerim',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    if (_referrals.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.grey.shade100),
                                        ),
                                        child: const Column(
                                          children: [
                                            Icon(Icons.people_outline_rounded, color: Colors.grey, size: 44),
                                            SizedBox(height: 12),
                                            Text(
                                              'Henüz davet ettiğiniz kimse bulunmuyor.\nHemen paylaşın ve kazanmaya başlayın!',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _referrals.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final ref = _referrals[index];
                                          final phone = ref['referredUser']?['phone'] ?? 'Misafir';
                                          final status = ref['status'].toString();
                                          
                                          // Mask phone number for privacy
                                          String maskedPhone = phone;
                                          if (phone.length > 7) {
                                            maskedPhone = '${phone.substring(0, 5)}***${phone.substring(phone.length - 4)}';
                                          }

                                          final isCompleted = status == 'COMPLETED';

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.grey.shade100),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      maskedPhone,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      isCompleted ? 'Sipariş Tamamlandı' : 'Sipariş Bekleniyor',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isCompleted ? const Color(0xFF00A651) : Colors.orange,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: isCompleted
                                                        ? const Color(0xFF00A651).withOpacity(0.1)
                                                        : Colors.orange.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    isCompleted ? '+100 TL' : 'Beklemede',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: isCompleted ? const Color(0xFF00A651) : Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
