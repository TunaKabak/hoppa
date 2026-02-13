import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoppa/core/services/order_service.dart';
import 'package:hoppa/core/services/auth_service.dart';
import 'package:hoppa/features/cart/cart_provider.dart';
import 'package:hoppa/models/address.dart';

class PaymentPage extends StatefulWidget {
  final Address deliveryAddress;
  final String phoneNumber;
  final String deliveryTime;
  final bool isPickUp;

  const PaymentPage({
    super.key,
    required this.deliveryAddress,
    required this.phoneNumber,
    required this.deliveryTime,
    this.isPickUp = false,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _noteController = TextEditingController();

  String _paymentMethod = 'cash_on_delivery';
  bool _isLoading = false;
  bool _dontRingBell = false;

  final Color kPrimaryColor = const Color(0xFF00A651);
  final Color kSecondaryColor = const Color(0xFFFF6B00);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    setState(() => _isLoading = true);

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final orderService = OrderService();

      double deliveryFee = widget.isPickUp ? 0.0 : 20.0;
      double finalTotal = cart.totalAmount + deliveryFee;

      // Clean address - just the actual address, no prefixes or notes
      String cleanAddress =
          "${widget.deliveryAddress.title} - ${widget.deliveryAddress.formattedAddress}";

      // Delivery method
      String deliveryMethod = widget.isPickUp ? 'pickup' : 'delivery';

      // User's order note - just the text
      String orderNote = _noteController.text.trim();

      // Doorbell preference
      bool dontRingBell = _dontRingBell;

      await orderService.createOrder(
        userId: auth.currentUser?.uid ?? 'guest',
        userPhone: widget.phoneNumber,
        address: cleanAddress, // Clean address only
        deliveryTime: widget.deliveryTime,
        items: cart.items,
        totalAmount: finalTotal,
        deliveryMethod: deliveryMethod, // Separate field
        orderNote: orderNote, // Separate field
        dontRingBell: dontRingBell, // Separate field
        addressLatitude: widget.deliveryAddress.latitude, // Location data
        addressLongitude: widget.deliveryAddress.longitude, // Location data
      );

      cart.clearCart(deleteFromDb: true);
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        _showSuccessDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Hata: $e",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 110, left: 16, right: 16),
          elevation: 4,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: kPrimaryColor, size: 50),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sipariş Alındı!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isPickUp
                  ? "Siparişiniz hazırlanmaya başlandı. Lütfen bildirimleri takip edin."
                  : "Siparişiniz işletmeye iletildi. Yola çıktığında bildirim alacaksınız.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Tamam"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    double deliveryFee = widget.isPickUp ? 0.0 : 20.0;
    double total = cart.totalAmount + deliveryFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Ödeme ve Onay (2/2)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. SİPARİŞ NOTU ---
                  _sectionTitle("Sipariş Notu", Icons.note_alt_outlined),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: widget.isPickUp
                          ? "Poşet istemiyorum, soğuk kalsın vb..."
                          : "Ürünler poşetsiz olsun, kapıya asın vb...",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  if (!widget.isPickUp) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          "Zili Çalma",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          "Kurye kapıya geldiğinde sizi arayarak haber verir.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        secondary: Icon(
                          Icons.notifications_off_outlined,
                          color: _dontRingBell ? kPrimaryColor : Colors.grey,
                        ),
                        activeThumbColor: kPrimaryColor,
                        value: _dontRingBell,
                        onChanged: (val) => setState(() => _dontRingBell = val),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // --- 2. ÖDEME YÖNTEMİ ---
                  _sectionTitle("Ödeme Yöntemi", Icons.wallet_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentCard(
                          id: 'cash_on_delivery',
                          title: widget.isPickUp
                              ? 'Mağazada Nakit'
                              : 'Kapıda Nakit',
                          icon: Icons.money_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPaymentCard(
                          id: 'card_on_delivery',
                          title: widget.isPickUp
                              ? 'Mağazada Kart'
                              : 'Kapıda Kart',
                          icon: Icons.credit_card_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: 0.5,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language, color: Colors.grey),
                          const SizedBox(width: 12),
                          const Text(
                            "Online Ödeme",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Çok Yakında",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 3. SİPARİŞ ÖZETİ ---
                  _sectionTitle(
                    "Sipariş Özeti",
                    Icons.shopping_basket_outlined,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(
                              "${cart.items.length} Ürün",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              "Detayları gör",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16,
                            ),
                            children: cart.items
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            item
                                                    .businessProduct
                                                    .product
                                                    .isWeighted
                                                ? item.quantity.toStringAsFixed(
                                                    1,
                                                  )
                                                : "${item.quantity.toInt()}",
                                            style: TextStyle(
                                              color: kPrimaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item.businessProduct.product.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "${(item.businessProduct.price * item.quantity).toStringAsFixed(2)} ₺",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _summaryRow(
                                "Ara Toplam",
                                "${cart.totalAmount.toStringAsFixed(2)} ₺",
                              ),
                              const SizedBox(height: 8),
                              _summaryRow(
                                widget.isPickUp
                                    ? "Teslimat Ücreti (Gel Al)"
                                    : "Teslimat Ücreti",
                                widget.isPickUp
                                    ? "0.00 ₺"
                                    : "${deliveryFee.toStringAsFixed(2)} ₺",
                                color: widget.isPickUp
                                    ? Colors.green
                                    : kSecondaryColor,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Genel Toplam",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    "${total.toStringAsFixed(2)} ₺",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 4. TESLİMAT BİLGİLERİ ---
                  _sectionTitle("Teslimat Bilgileri", Icons.info_outline),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                widget.isPickUp
                                    ? Icons.store
                                    : Icons.local_shipping,
                                color: kPrimaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.isPickUp
                                  ? "Gel Al Siparişi"
                                  : "Eve Teslimat",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              widget.deliveryTime.contains('Hemen')
                                  ? "Hemen"
                                  : "Randevulu",
                              style: TextStyle(
                                color: kSecondaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        _buildInfoRow(
                          Icons.access_time,
                          "Zaman",
                          widget.deliveryTime,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.phone,
                          "İletişim",
                          widget.phoneNumber,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.location_on,
                          widget.isPickUp ? "Teslim Noktası" : "Adres",
                          "${widget.deliveryAddress.district}, ${widget.deliveryAddress.city}\n${widget.deliveryAddress.fullDetails}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ALT BUTON
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: kPrimaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Siparişi Tamamla",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required String id,
    required String title,
    required IconData icon,
  }) {
    bool isSelected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? kPrimaryColor : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? kPrimaryColor : Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
