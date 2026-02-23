import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hoppa/apps/consumer/services/customer_auth_service.dart';
import 'package:hoppa/shared/models/address.dart';
import 'package:hoppa/apps/consumer/address/delivery_provider.dart';
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/apps/consumer/checkout/payment_page.dart';
import 'package:hoppa/shared/core/widgets/animated_sliding_toggle.dart';
import 'package:hoppa/apps/consumer/address/address_list_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _phoneController = TextEditingController();

  Address? _selectedAddress;

  // YENİ: Teslimat Yöntemi State'i
  bool _isPickUp = false; // false: Eve Teslim, true: Gel Al

  // Teslimat Zamanı State'leri
  bool _isScheduled = false;
  int _selectedDayIndex = 0;
  String? _selectedTimeSlot;

  final Color kPrimaryColor = const Color(0xFF00A651);

  // SAAT DİLİMLERİ (Dinamik Oluşturulacak)
  List<String> _deliverySlots = [];
  List<String> _pickupSlots = [];

  List<String> _generateTimeSlots(
    int startHour,
    int endHour,
    int intervalMinutes,
  ) {
    List<String> slots = [];
    DateTime currentTime = DateTime(2024, 1, 1, startHour, 0);
    DateTime endTime = DateTime(2024, 1, 1, endHour, 0);

    while (currentTime.isBefore(endTime)) {
      DateTime nextTime = currentTime.add(Duration(minutes: intervalMinutes));
      if (nextTime.isAfter(endTime)) break;

      String startStr =
          "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}";
      String endStr =
          "${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}";

      slots.add("$startStr - $endStr");
      currentTime = nextTime;
    }
    return slots;
  }

  @override
  void initState() {
    super.initState();
    _deliverySlots = _generateTimeSlots(8, 22, 120); // 08:00 - 22:00, 2 saatlik
    _pickupSlots = _generateTimeSlots(8, 22, 30); // 08:00 - 22:00, 30 dakikalık

    final deliveryProvider = Provider.of<DeliveryProvider>(
      context,
      listen: false,
    );
    _selectedAddress = deliveryProvider.selectedAddress;

    final auth = Provider.of<CustomerAuthService>(context, listen: false);
    final userPhone = auth.currentUser?.phoneNumber;

    if (userPhone != null && userPhone.isNotEmpty) {
      _phoneController.text = userPhone;
    } else {
      _phoneController.text = "0533 876 54 32";
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // YÖNTEME GÖRE SAATLERİ FİLTRELE
  List<String> _getAvailableSlots() {
    // 1. Hangi listeyi kullanacağız?
    List<String> targetList = _isPickUp ? _pickupSlots : _deliverySlots;

    // 2. Bugün değilse (Yarın vb.) hepsini göster
    if (_selectedDayIndex > 0) return targetList;

    // 3. Bugün ise geçmiş saatleri gizle
    final now = DateTime.now();
    return targetList.where((slot) {
      // Slotun başlangıç saatini al (örn: "08:30" -> saat:8, dk:30)
      String startPart = slot.split('-')[0].trim(); // "08:30"
      int startHour = int.parse(startPart.split(':')[0]);
      int startMin = int.parse(startPart.split(':')[1]);

      // Şu anki zamandan en az 30 dk sonrası için izin ver (Hazırlık payı)
      DateTime slotTime = DateTime(
        now.year,
        now.month,
        now.day,
        startHour,
        startMin,
      );
      return slotTime.isAfter(now.add(const Duration(minutes: 30)));
    }).toList();
  }

  String _getDeliverySummaryText() {
    String typeText = _isPickUp ? "Teslim alma zamanı:" : "Teslimat zamanı:";
    if (!_isScheduled) {
      return "$typeText Ortalama ${_isPickUp ? '15-20' : '25-45'} dakika.";
    }
    if (_selectedTimeSlot == null) return "Lütfen bir saat aralığı seçiniz.";

    String dayName = "";
    if (_selectedDayIndex == 0) {
      dayName = "Bugün";
    } else if (_selectedDayIndex == 1)
      dayName = "Yarın";
    else {
      final date = DateTime.now().add(Duration(days: _selectedDayIndex));
      dayName = DateFormat('dd MMM').format(date);
    }
    return "$typeText $dayName, saat $_selectedTimeSlot aralığı.";
  }

  void _proceedToPayment() {
    // Validasyonlar
    if (!_isPickUp && _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen adres seçiniz"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("İletişim numarası giriniz"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_isScheduled) {
      if (_getAvailableSlots().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Seçili gün için uygun saat yok."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedTimeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen saat seçiniz"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Teslimat Zamanı Metni
    String deliveryTimeText;
    if (!_isScheduled) {
      deliveryTimeText = "Hemen (${_isPickUp ? 'Hazırlanıyor' : '25-45 dk'})";
    } else {
      final date = DateTime.now().add(Duration(days: _selectedDayIndex));
      final dateStr = DateFormat('dd MMM yyyy', 'tr_TR').format(date);
      deliveryTimeText = "$dateStr, $_selectedTimeSlot (Randevulu)";
    }

    // Adres Belirleme (Gel Al ise İşletme Adresi)
    Address finalAddress;
    if (_isPickUp) {
      final selectedBusiness = Provider.of<BusinessProvider>(
        context,
        listen: false,
      ).selectedBusiness!;
      finalAddress = Address(
        id: 'business',
        title: selectedBusiness.name, // İşletme Adı Başlık Olsun
        city: 'Gazimağusa',
        district: selectedBusiness.name,
        fullDetails: selectedBusiness.address,
        latitude: selectedBusiness.latitude,
        longitude: selectedBusiness.longitude,
      );
    } else {
      finalAddress = _selectedAddress!;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          deliveryAddress: finalAddress,
          phoneNumber: _phoneController.text,
          deliveryTime: deliveryTimeText,
          isPickUp: _isPickUp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Teslimat Bilgileri",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. TESLİMAT YÖNTEMİ ---
                  _sectionTitle(
                    "Teslimat Yöntemi",
                    Icons.local_shipping_outlined,
                  ),
                  const SizedBox(height: 12),
                  AnimatedSlidingToggle(
                    labels: const ["Eve Teslim", "Gel Al"],
                    selectedIndex: _isPickUp ? 1 : 0,
                    activeColor: kPrimaryColor,
                    onChanged: (index) => setState(() {
                      _isPickUp = index == 1;
                      // Yöntem değişince saat seçimini sıfırla, çünkü listeler farklı
                      _selectedTimeSlot = null;
                    }),
                  ),

                  const SizedBox(height: 24),

                  // --- 2. ADRES KARTI (Duruma Göre Değişir) ---
                  _sectionTitle(
                    _isPickUp ? "Teslim Alma Noktası" : "Teslimat Adresi",
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),

                  if (_isPickUp)
                    // GEL AL: İşletme Adresi
                    Consumer<BusinessProvider>(
                      builder: (context, businessProvider, child) {
                        final business = businessProvider.selectedBusiness;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.store,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      business?.name ?? "İşletme Seçilmedi",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      business?.address ?? "",
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    // EVE TESLİM: Kullanıcı Adresi
                    GestureDetector(
                      onTap: () async {
                        final selectedAddress = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AddressListPage(isSelectionMode: true),
                          ),
                        );

                        if (selectedAddress != null) {
                          setState(() {
                            _selectedAddress = selectedAddress;
                          });
                          Provider.of<DeliveryProvider>(
                            context,
                            listen: false,
                          ).setAddress(selectedAddress);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.home_filled,
                                color: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedAddress?.title ?? "Adres Seçin",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedAddress != null
                                        ? "${_selectedAddress!.district}, ${_selectedAddress!.city}"
                                        : "Lütfen bir teslimat adresi seçiniz.",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // --- 3. TELEFON ---
                  _sectionTitle("İletişim", Icons.phone_outlined),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.phone, color: kPrimaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "İletişim Numarası",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _phoneController.text,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 4. ZAMANLAMA ---
                  _sectionTitle(
                    _isPickUp ? "Teslim Alma Zamanı" : "Teslimat Zamanı",
                    Icons.access_time,
                  ),
                  const SizedBox(height: 12),

                  // Toggle (Hemen / Randevulu)
                  AnimatedSlidingToggle(
                    labels: const ["Hemen", "Randevulu"],
                    selectedIndex: _isScheduled ? 1 : 0,
                    activeColor: kPrimaryColor,
                    onChanged: (index) => setState(() {
                      _isScheduled = index == 1;
                      _selectedTimeSlot = null;
                    }),
                  ),

                  const SizedBox(height: 16),

                  if (!_isScheduled)
                    // HEMEN
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kPrimaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.rocket_launch, color: kPrimaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPickUp
                                      ? "Tahmini Hazırlanma Süresi"
                                      : "Tahmini Teslimat Süresi",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _isPickUp
                                      ? "15 - 20 Dakika"
                                      : "25 - 45 Dakika",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // RANDEVULU: Gün Seçimi
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          bool isSelected = _selectedDayIndex == index;
                          DateTime date = DateTime.now().add(
                            Duration(days: index),
                          );
                          String dayName;
                          if (index == 0) {
                            dayName = "Bugün";
                          } else if (index == 1)
                            dayName = "Yarın";
                          else
                            dayName = DateFormat(
                              'dd MMM',
                              'tr_TR',
                            ).format(date);

                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedDayIndex = index;
                              _selectedTimeSlot = null;
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? kPrimaryColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? kPrimaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  dayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_getAvailableSlots().isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Bugün için uygun saat kalmadı.",
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: _getAvailableSlots().length,
                        itemBuilder: (context, index) {
                          String slot = _getAvailableSlots()[index];
                          bool isSelected = _selectedTimeSlot == slot;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedTimeSlot = slot),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? kPrimaryColor.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? kPrimaryColor
                                      : Colors.grey.shade300,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                slot,
                                style: TextStyle(
                                  color: isSelected
                                      ? kPrimaryColor
                                      : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // ÖZET KUTUSU
                    if (_selectedTimeSlot != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getDeliverySummaryText(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // BUTON
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
                onPressed: _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Ödemeye Geç",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
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
}
