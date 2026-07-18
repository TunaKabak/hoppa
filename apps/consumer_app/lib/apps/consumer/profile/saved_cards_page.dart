import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_shared/shared/core/utils/card_input_formatters.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_dialog.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';

class SavedCardsPage extends ConsumerStatefulWidget {
  const SavedCardsPage({super.key});

  @override
  ConsumerState<SavedCardsPage> createState() => _SavedCardsPageState();
}

class _SavedCardsPageState extends ConsumerState<SavedCardsPage> {
  List<dynamic> _cards = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/api/consumer/cards');
      if (mounted) {
        setState(() {
          _cards = response['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error loading cards: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCard(String cardId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete('/api/consumer/cards/$cardId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kart başarıyla silindi.")),
        );
      }
      _loadCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kart silinemedi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(String cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => HoppaDialog(
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        title: "Kartı Sil",
        content: "Bu kartı silmek istediğinize emin misiniz?",
        cancelText: "Vazgeç",
        confirmText: "Sil",
        isDestructive: true,
        onCancel: () => Navigator.pop(context, false),
        onConfirm: () => Navigator.pop(context, true),
      ),
    );

    if (confirm == true) {
      _deleteCard(cardId);
    }
  }

  Future<void> _setDefaultCard(String cardId) async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.put('/api/consumer/cards/$cardId/default');
      _loadCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddCardDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final holderController = TextEditingController();
    final numberController = TextEditingController();
    String selectedCardType = "Visa";
    String cardLogo = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        const kPrimaryColor = Color(0xFF00A651);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Yeni Kart Ekle 💳",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Card Title
                      Text("Kart Başlığı", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: "Örn: Maaş Kartım, Bonus",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v!.trim().isEmpty ? "Kart başlığı girin" : null,
                      ),
                      const SizedBox(height: 16),

                      // Holder Name
                      Text("Kart Üzerindeki İsim", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: holderController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: "Örn: AHMET YILMAZ",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v!.trim().isEmpty ? "Kart üzerindeki ismi girin" : null,
                      ),
                      const SizedBox(height: 16),

                      // Card Number
                      Text("Kart Numarası", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                          CardNumberInputFormatter(),
                        ],
                        onChanged: (val) {
                          final cleanNum = val.replaceAll(' ', '');
                          setModalState(() {
                            if (cleanNum.startsWith('4')) {
                              selectedCardType = "Visa";
                              cardLogo = "💳 Visa";
                            } else if (cleanNum.startsWith('5')) {
                              selectedCardType = "Mastercard";
                              cardLogo = "💳 MasterCard";
                            } else if (cleanNum.startsWith('9792')) {
                              selectedCardType = "Troy";
                              cardLogo = "💳 Troy";
                            } else {
                              selectedCardType = "Visa";
                              cardLogo = "";
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Örn: 4355 2412 3456 7890",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: cardLogo.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    cardLogo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.credit_card),
                        ),
                        validator: (v) => v!.replaceAll(' ', '').length < 16 ? "Lütfen 16 haneli numarayı tam girin" : null,
                      ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            
                            Navigator.pop(context); // Close sheet
                            
                            setState(() => _isLoading = true);
                            try {
                              final apiClient = ref.read(apiClientProvider);
                              await apiClient.post(
                                '/api/consumer/cards',
                                body: {
                                  'cardTitle': titleController.text.trim(),
                                  'cardHolderName': holderController.text.trim(),
                                  'cardNumber': numberController.text.replaceAll(' ', ''),
                                  'cardType': selectedCardType,
                                },
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Kartınız başarıyla kaydedildi!")),
                                );
                              }
                              _loadCards();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            "Kaydet",
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryColor = Color(0xFF00A651);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 48.0),
                        child: Text(
                          "Kayıtlı Kartlarım",
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
                  child: _isLoading && _cards.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                      : _cards.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.credit_card_off_rounded, size: 80, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Kayıtlı kredi kartınız bulunmuyor.",
                                    style: GoogleFonts.inter(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _cards.length,
                              itemBuilder: (context, index) {
                                final card = _cards[index];
                                return _buildCardItem(card);
                              },
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardDialog,
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Kart Ekle", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCardItem(dynamic card) {
    final String title = card['cardTitle'] ?? 'Kayıtlı Kart';
    final String holder = card['cardHolderName'] ?? '';
    final String hiddenNum = card['cardNumberHidden'] ?? '';
    final String type = card['cardType'] ?? 'Visa';
    final String id = card['id'] ?? '';
    final bool isDefault = card['isDefault'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDefault
              ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
              : [const Color(0xFF1E272C), const Color(0xFF0F1416)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  Text(
                    type.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _confirmDelete(id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            hiddenNum,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "KART SAHİBİ",
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    holder.toUpperCase(),
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade300, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Varsayılan",
                        style: GoogleFonts.poppins(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.star_outline_rounded, color: Colors.white70, size: 14),
                  label: Text(
                    "Varsayılan Yap",
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _setDefaultCard(id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
