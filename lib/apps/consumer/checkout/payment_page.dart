import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_network/core_network.dart';
import 'package:hoppa/apps/consumer/cart/cart_provider.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_order_repository.dart';
import 'package:hoppa/shared/models/address.dart';
import 'package:hoppa/apps/consumer/checkout/three_d_secure_page.dart';
import 'package:hoppa/shared/core/utils/card_input_formatters.dart';
import 'package:provider/provider.dart' as p;
import 'package:hoppa/apps/consumer/address/delivery_provider.dart';
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/shared/core/utils/quantity_formatter.dart';

class PaymentPage extends ConsumerStatefulWidget {
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
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  final _noteController = TextEditingController();

  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCVCController = TextEditingController();
  final _cardHolderController = TextEditingController();
  
  String _cardLogo = '';

  String _paymentMethod = 'online_payment';
  bool _isLoading = false;
  bool _dontRingBell = false;
  bool _leaveAtDoor = false;

  final Color kPrimaryColor = const Color(0xFF00A651);
  final Color kSecondaryColor = const Color(0xFFFF6B00);

  @override
  void initState() {
    super.initState();
    if (widget.isPickUp) {
      _paymentMethod = 'online_payment';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCVCController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  void _updateCardLogo(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.length >= 6) {
      final bin = cleanNumber.substring(0, 6);
      if (['454360', '543771', '402235'].contains(bin)) {
        setState(() => _cardLogo = '💳 Cardplus');
      } else if (['432042', '516888', '540061'].contains(bin)) {
        setState(() => _cardLogo = '💳 PAYTR');
      } else if (cleanNumber.startsWith('4')) {
        setState(() => _cardLogo = '💳 Visa');
      } else if (cleanNumber.startsWith('5')) {
        setState(() => _cardLogo = '💳 MasterCard');
      } else {
        setState(() => _cardLogo = '💳 Kart');
      }
    } else {
      setState(() => _cardLogo = '');
    }
  }

  void _submitOrder() async {
    setState(() => _isLoading = true);

    try {
      final cartState = ref.read(cartProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final orderRepo = ref.read(consumerOrderRepositoryProvider);

      final businessProvider = p.Provider.of<BusinessProvider>(context, listen: false);
      final selectedBusiness = businessProvider.selectedBusiness;
      final activeCampaigns = ref.read(cartCampaignsProvider).value ?? [];
      
      bool hasFreeDeliveryCampaign = activeCampaigns.any((c) => c.type.name.toUpperCase() == "FREE_DELIVERY_FIRST_ORDERS");
      
      double deliveryFee = selectedBusiness?.baseDeliveryFee ?? 30.0;
      if (selectedBusiness?.freeDeliveryThreshold != null && 
          cartState.totalAmount >= selectedBusiness!.freeDeliveryThreshold!) {
        deliveryFee = 0.0;
      }
      if (hasFreeDeliveryCampaign) {
        deliveryFee = 0.0;
      }
      
      if (widget.isPickUp) {
        deliveryFee = 0.0;
      }

      final deliveryProvider = p.Provider.of<DeliveryProvider>(context, listen: false);
      final userAddress = deliveryProvider.selectedAddress;

      // Clean address - just the actual address, no prefixes or notes
      String cleanAddress = widget.isPickUp
          ? (userAddress != null 
              ? "Gel Al: ${userAddress.title}: ${userAddress.fullDetails}" 
              : "Gel Al: ${widget.deliveryAddress.fullDetails}")
          : "${widget.deliveryAddress.title}: ${widget.deliveryAddress.fullDetails}";

      // User's order note - just the text
      String orderNote = _noteController.text.trim();

      String? addressId = widget.isPickUp ? userAddress?.id : widget.deliveryAddress.id;

      Map<String, dynamic>? cardDetails;
      if (_paymentMethod == 'online_payment') {
        if (_cardNumberController.text.isEmpty ||
            _cardExpiryController.text.isEmpty ||
            _cardCVCController.text.isEmpty ||
            _cardHolderController.text.isEmpty) {
          throw Exception("Lütfen kart bilgilerini eksiksiz girin.");
        }
        final expiryParts = _cardExpiryController.text.split('/');
        if (expiryParts.length != 2) {
          throw Exception("Son kullanma tarihi AA/YY formatında olmalıdır.");
        }
        
        final month = int.tryParse(expiryParts[0]) ?? 0;
        final year = int.tryParse(expiryParts[1]) ?? 0;

        if (month < 1 || month > 12) {
          throw Exception("Geçersiz ay girdiniz.");
        }

        final now = DateTime.now();
        final currentYear = now.year % 100;
        final currentMonth = now.month;

        if (year < currentYear || (year == currentYear && month < currentMonth)) {
          throw Exception("Kartın süresi dolmuş.");
        }

        cardDetails = {
          'cardNumber': _cardNumberController.text,
          'expiryMonth': expiryParts[0],
          'expiryYear': expiryParts[1],
          'cvc': _cardCVCController.text,
          'cardHolderName': _cardHolderController.text,
        };
      }

      final orderData = {
        'shopId': cartState.currentBusinessId,
        'items': cartState.items.map((item) => {
          'productId': item.businessProduct.id,
          'quantity': item.quantity.round(),
        }).toList(),
        if (addressId != null) 'addressId': addressId,
        'deliveryAddress': cleanAddress,
        'notes': orderNote,
        'paymentMethod': _paymentMethod.toUpperCase(),
        if (cardDetails != null) 'cardDetails': cardDetails,
        'dontRingBell': _dontRingBell,
        'leaveAtDoor': _leaveAtDoor,
      };

      final result = await orderRepo.createOrder(orderData);
      final paymentUrl = result['paymentUrl'] as String?;

      // Clear cart locally
      cartNotifier.clearCart();

      if (mounted) {
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => ThreeDSecurePage(paymentUrl: paymentUrl),
             ),
           );
        } else {
           Navigator.popUntil(context, (route) => route.isFirst);
           _showSuccessDialog();
        }
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is AppException) {
        errorMsg = e.message;
      } else if (e is Exception) {
        errorMsg = e.toString().replaceAll("Exception: ", "");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Hata: $errorMsg",
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
      }
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
                color: kPrimaryColor.withValues(alpha: 0.1),
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
    final cartState = ref.watch(cartProvider);
    final campaignsAsync = ref.watch(cartCampaignsProvider);
    final activeCampaigns = campaignsAsync.value ?? [];

    final businessProvider = p.Provider.of<BusinessProvider>(context);
    final selectedBusiness = businessProvider.selectedBusiness;
    
    bool hasFreeDeliveryCampaign = activeCampaigns.any((c) => c.type.name.toUpperCase() == "FREE_DELIVERY_FIRST_ORDERS");
    
    double deliveryFee = selectedBusiness?.baseDeliveryFee ?? 30.0;
    if (selectedBusiness?.freeDeliveryThreshold != null && 
        cartState.totalAmount >= selectedBusiness!.freeDeliveryThreshold!) {
      deliveryFee = 0.0;
    }
    if (hasFreeDeliveryCampaign) {
      deliveryFee = 0.0;
    }
    
    if (widget.isPickUp) {
      deliveryFee = 0.0;
    }

    double total = cartState.totalAmount + deliveryFee;

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
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.delivery_dining_outlined, color: Colors.grey, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Teslimat Tercihleri",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              value: _leaveAtDoor,
                              title: Text(
                                "Kapıya Bırak",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _paymentMethod != 'online_payment' ? Colors.grey : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                _paymentMethod != 'online_payment'
                                    ? "Kapıda ödeme seçildiğinde temassız teslimat yapılamaz."
                                    : "Sipariş kapınıza bırakılır, temassız teslim edilir.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _paymentMethod != 'online_payment' ? Colors.grey.shade400 : Colors.grey,
                                ),
                              ),
                              secondary: Icon(
                                Icons.door_front_door_outlined,
                                color: _paymentMethod != 'online_payment'
                                    ? Colors.grey.shade300
                                    : (_leaveAtDoor ? kPrimaryColor : Colors.grey),
                              ),
                              activeColor: kPrimaryColor,
                              onChanged: _paymentMethod != 'online_payment'
                                  ? null
                                  : (bool value) {
                                      setState(() {
                                        _leaveAtDoor = value;
                                      });
                                    },
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              value: _dontRingBell,
                              title: const Text("Zili Çalma", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text("Zil çalınmaz; kapı hafifçe vurulur veya telefonla aranır.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              secondary: Icon(Icons.notifications_off_outlined, color: _dontRingBell ? kPrimaryColor : Colors.grey),
                              activeColor: kPrimaryColor,
                              onChanged: (bool value) {
                                setState(() {
                                  _dontRingBell = value;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
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
                        child: _buildPaymentOption(
                          title: 'Kredi / Banka Kartı',
                          icon: Icons.credit_card,
                          isSelected: _paymentMethod == 'online_payment',
                          onTap: () => setState(() => _paymentMethod = 'online_payment'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPaymentOption(
                          title: widget.isPickUp ? 'Mağazada Ödeme' : 'Kapıda Ödeme',
                          icon: widget.isPickUp ? Icons.store_outlined : Icons.local_shipping_outlined,
                          isSelected: _paymentMethod != 'online_payment',
                          isDisabled: false,
                          onTap: () {
                            setState(() {
                              if (_paymentMethod == 'online_payment') {
                                _paymentMethod = 'cash_on_delivery';
                              }
                              _leaveAtDoor = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _paymentMethod != 'online_payment'
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Nasıl ödemek istersiniz?",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPaymentOption(
                                  title: widget.isPickUp ? 'Nakit' : 'Kapıda Nakit',
                                  icon: Icons.money_rounded,
                                  isSelected: _paymentMethod == 'cash_on_delivery',
                                  isSubOption: true,
                                  onTap: () => setState(() {
                                    _paymentMethod = 'cash_on_delivery';
                                    _leaveAtDoor = false;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPaymentOption(
                                  title: widget.isPickUp ? 'Kart' : 'Kapıda Kredi Kartı',
                                  icon: Icons.credit_card_rounded,
                                  isSelected: _paymentMethod == 'card_on_delivery',
                                  isSubOption: true,
                                  onTap: () => setState(() {
                                    _paymentMethod = 'card_on_delivery';
                                    _leaveAtDoor = false;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox(width: double.infinity, height: 0),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _paymentMethod == 'online_payment'
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: _buildCreditCardForm(),
                    secondChild: const SizedBox(width: double.infinity, height: 0),
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
                          color: Colors.black.withValues(alpha: 0.02),
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
                              "${cartState.items.length} Ürün",
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
                            children: cartState.items.map((item) {
                              double price = item.businessProduct.price;
                              if (activeCampaigns.isNotEmpty) {
                                try {
                                  final campaign = activeCampaigns
                                      .firstWhere(
                                        (c) => c.targetProducts.contains(
                                          item.businessProduct.productBarcode,
                                        ),
                                      );
                                  price = campaign.calculateDiscountedPrice(
                                    price,
                                  );
                                } catch (_) {}
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        QuantityFormatter.formatValue(item.quantity),
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
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      "${(price * item.quantity).toStringAsFixed(2)} ₺",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _summaryRow(
                                "Ara Toplam",
                                "${cartState.totalAmount.toStringAsFixed(2)} ₺",
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.isPickUp
                                        ? "Teslimat Ücreti (Gel Al)"
                                        : "Teslimat Ücreti",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                  Row(
                                    children: [
                                      if (deliveryFee == 0 && !widget.isPickUp) ...[
                                        Text(
                                          "${(selectedBusiness?.baseDeliveryFee ?? 30.0).toStringAsFixed(2)} ₺",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            "Ücretsiz",
                                            style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          widget.isPickUp
                                              ? "0.00 ₺"
                                              : "${deliveryFee.toStringAsFixed(2)} ₺",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: widget.isPickUp ? Colors.green : kSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
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
                          color: Colors.black.withValues(alpha: 0.02),
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
                                color: kPrimaryColor.withValues(alpha: 0.1),
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
                                  fontWeight: FontWeight.bold, fontSize: 16),
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                  shadowColor: kPrimaryColor.withValues(alpha: 0.4),
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

  Widget _buildPaymentOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onTap,
    bool isSubOption = false,
    bool isDisabled = false,
  }) {
    final active = isSelected && !isDisabled;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: isSubOption ? 12 : 20, horizontal: 12),
          decoration: BoxDecoration(
            color: active ? kPrimaryColor.withValues(alpha: isSubOption ? 0.08 : 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? kPrimaryColor : Colors.grey.shade200,
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: active ? kPrimaryColor : Colors.grey,
                size: isSubOption ? 24 : 32,
              ),
              SizedBox(height: isSubOption ? 6 : 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: active ? kPrimaryColor : Colors.grey[700],
                  fontSize: isSubOption ? 13 : 14,
                ),
              ),
            ],
          ),
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

  Widget _buildCreditCardForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Kart Bilgileri",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_cardLogo.isNotEmpty)
                Text(
                  _cardLogo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            maxLength: 19,
            onChanged: _updateCardLogo,
            decoration: InputDecoration(
              labelText: "Kart Numarası",
              counterText: "",
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cardExpiryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(5),
                    CardExpiryInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: "AA/YY",
                    counterText: "",
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cardCVCController,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "CVC",
                    counterText: "",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cardHolderController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: "Kart Üzerindeki İsim",
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
