import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  bool _isLoading = true;
  double _balance = 0.0;
  List<dynamic> _transactions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/api/consumer/wallet');
      final data = response['data'];
      
      if (data != null && data['wallet'] != null) {
        final walletData = data['wallet'];
        setState(() {
          _balance = double.tryParse(walletData['balance'].toString()) ?? 0.0;
          _transactions = walletData['transactions'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Cüzdan bilgileri alınamadı.';
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

  Future<void> _depositMoney(double amount) async {
    Navigator.pop(context); // Close bottom sheet
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE95D22)),
      ),
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/api/consumer/wallet/deposit',
        body: {'amount': amount},
      );

      Navigator.pop(context); // Dismiss loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${amount.toStringAsFixed(2)} TL başarıyla cüzdanınıza yüklendi!'),
          backgroundColor: const Color(0xFF00A651),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchWalletData(); // Refresh wallet
    } catch (e) {
      Navigator.pop(context); // Dismiss loading dialog
      _showErrorSnackBar('İşlem sırasında bir hata oluştu: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDepositBottomSheet() {
    double? customAmount;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bakiye Yükle',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Yüklemek istediğiniz tutarı seçin veya girin:',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAmountChip(100),
                    _buildAmountChip(250),
                    _buildAmountChip(500),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Diğer Tutar (TL)',
                    prefixIcon: const Icon(Icons.add_card_rounded, color: Color(0xFFE95D22)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE95D22), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen bir tutar girin.';
                    }
                    final amt = double.tryParse(value);
                    if (amt == null || amt <= 0) {
                      return 'Lütfen geçerli bir tutar girin.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    if (value != null) {
                      customAmount = double.tryParse(value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      if (customAmount != null) {
                        _depositMoney(customAmount!);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE95D22),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Devam Et', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountChip(double amount) {
    return ActionChip(
      label: Text(
        '${amount.toStringAsFixed(0)} TL',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE95D22)),
      ),
      backgroundColor: const Color(0xFFE95D22).withOpacity(0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () => _depositMoney(amount),
    );
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
                          'Hoppa Cüzdanım',
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
                                    onPressed: _fetchWalletData,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE95D22)),
                                    child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
                                  )
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchWalletData,
                              color: const Color(0xFFE95D22),
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Balance Card
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                        border: Border.all(color: Colors.grey.shade100),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Toplam Bakiyeniz',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${_balance.toStringAsFixed(2)} TL',
                                            style: GoogleFonts.outfit(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFE95D22),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 50,
                                            child: ElevatedButton.icon(
                                              onPressed: _showDepositBottomSheet,
                                              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                                              label: const Text(
                                                'Bakiye Yükle',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF00A651),
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
                                    const SizedBox(height: 28),
                                    Text(
                                      'Son Cüzdan Hareketleri',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (_transactions.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(40),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.grey.shade100),
                                        ),
                                        child: const Column(
                                          children: [
                                            Icon(Icons.history_rounded, color: Colors.grey, size: 48),
                                            SizedBox(height: 12),
                                            Text(
                                              'Henüz bir işlem geçmişiniz bulunmuyor.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.grey, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _transactions.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final tx = _transactions[index];
                                          return _buildTransactionItem(tx);
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

  Widget _buildTransactionItem(dynamic tx) {
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final type = tx['type'].toString();
    final description = tx['description'] ?? 'Cüzdan İşlemi';
    final createdAtStr = tx['createdAt'].toString();
    final DateTime createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(createdAt.toLocal());
    final expiresAtStr = tx['expiresAt']?.toString();
    final DateTime? expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
    
    IconData iconData;
    Color iconColor;
    String sign = amount >= 0 ? '+' : '';

    if (type == 'DEPOSIT') {
      iconData = Icons.arrow_upward_rounded;
      iconColor = const Color(0xFF00A651); // Green
    } else if (type == 'WITHDRAW') {
      iconData = Icons.arrow_downward_rounded;
      iconColor = Colors.red;
    } else if (type == 'REFUND') {
      iconData = Icons.keyboard_return_rounded;
      iconColor = Colors.blue;
    } else if (type == 'REFERRAL_BONUS') {
      iconData = Icons.card_giftcard_rounded;
      iconColor = Colors.orange;
    } else if (type == 'REVIEW_BONUS') {
      iconData = Icons.rate_review_rounded;
      iconColor = Colors.amber.shade700;
    } else {
      iconData = Icons.payment_rounded;
      iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                if (expiresAt != null && type != 'WITHDRAW' && tx['isExpiredProcessed'] == false) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.hourglass_bottom_rounded, color: Colors.orange, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Son gün: ${DateFormat('dd.MM.yyyy').format(expiresAt.toLocal())}',
                        style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
          Text(
            '$sign${amount.toStringAsFixed(2)} TL',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: amount >= 0 ? const Color(0xFF00A651) : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
