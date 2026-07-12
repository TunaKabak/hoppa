import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_network/core_network.dart';
import 'package:core_auth/core_auth.dart';

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

  void _showAddCardDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final holderController = TextEditingController();
    final numberController = TextEditingController();
    String selectedCardType = "Visa";

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
                          LengthLimitingTextInputFormatter(16),
                          // Optional: Card space formatter
                        ],
                        decoration: InputDecoration(
                          hintText: "16 haneli kart numarası",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v!.length < 16 ? "Lütfen 16 haneli numarayı tam girin" : null,
                      ),
                      const SizedBox(height: 16),

                      // Card Type Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Kart Tipi", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedCardType,
                                      isExpanded: true,
                                      items: ["Visa", "Mastercard", "Troy"]
                                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() => selectedCardType = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                                  'cardNumber': numberController.text.trim(),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "Kayıtlı Kartlarım",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading && _cards.isEmpty
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade800, Colors.grey.shade900],
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
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                    onPressed: () => _deleteCard(id),
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
              const Icon(Icons.nfc_rounded, color: Colors.white30, size: 28),
            ],
          ),
        ],
      ),
    );
  }
}
