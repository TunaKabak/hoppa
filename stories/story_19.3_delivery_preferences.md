Story 19.3 - Eve Teslimat Tercihleri (Zili Çalma & Kapıya Bırak) Entegrasyon Planı

Bu görev belgesi; tüketicilerin eve teslim siparişlerinde temassız ve sessiz teslimat tercihlerini (Zili Çalma, Kapıya Bırak) belirleyebilmesini, bu verilerin veritabanına işlenmesini ve kuryelerin/satıcıların bu kritik teslimat notlarını arayüzde belirgin uyarı pencereleriyle görmesini sağlamak için gereken adımları içerir.

🧭 1. Bölüm: Mimari ve Veri Akış Tasarımı

Müşteri siparişi tamamlarken bu seçenekleri işaretlediğinde, veriler sipariş kaydıyla birlikte veritabanına kilitlenir. Kurye adrese ulaştığında bu tercihleri harita ve sipariş detay ekranında parlak uyarı etiketleri şeklinde görür.

Veritabanı Değişikliği (Prisma)

Order modeline teslimat tercihlerini tutacak iki adet boolean alan ekliyoruz.

// backend/prisma/schema.prisma içindeki Order modeline eklenecek alanlar:

model Order {
  id                    String              @id @default(uuid())
  // ... mevcut diğer alanlar ...
  
  // 🚪 Temassız & Sessiz Teslimat Tercihleri
  dontRingBell          Boolean             @default(false) // True ise zil çalınmaz, kapı vurulur/telefon edilir
  leaveAtDoor           Boolean             @default(false) // True ise sipariş kapıya bırakılır
}


🛠️ 2. Bölüm: Backend Entegrasyonu (API & Controller)

A. Sipariş Oluşturma Validasyonunun Güncellenmesi (OrderController.ts)

POST /api/orders (sipariş oluşturma) endpoint'inde gelen gövdeden (body) dontRingBell ve leaveAtDoor boolean alanlarını yakalayıp sipariş kaydına yazıyoruz.

// backend/src/controllers/OrderController.ts içindeki sipariş oluşturma koduna eklenecek mantık:

public static async createOrder(req: Request, res: Response): Promise<void> {
    try {
        const { 
            shopId, 
            items, 
            paymentMethod, 
            deliveryAddress,
            dontRingBell, // 🔕 Zili Çalma Tercihi
            leaveAtDoor   // 🚪 Kapıya Bırak Tercihi
        } = req.body;

        // Prisma create bloğuna bu verileri güvenli varsayılanlarla ekliyoruz
        const newOrder = await prisma.order.create({
            data: {
                shopId,
                userId: req.user!.id,
                paymentMethod,
                deliveryAddress,
                dontRingBell: dontRingBell === true,
                leaveAtDoor: leaveAtDoor === true,
                // ... diğer alanlar
            }
        });

        res.status(201).json({ error: false, data: newOrder });
    } catch (error) {
        console.error("Sipariş oluşturma hatası:", error);
        res.status(500).json({ error: true, message: "Sipariş oluşturulurken bir hata oluştu." });
    }
}


📱 3. Bölüm: Tüketici Uygulaması (Consumer App) UI Entegrasyonu

A. Ödeme / Onay Ekranı Geliştirmesi (payment_page.dart veya checkout_page.dart)

Sadece "Eve Teslim" (Home Delivery) seçildiğinde görünecek şekilde, ödeme butonunun hemen üzerine şık bir "Teslimat Tercihleri" kartı ekliyoruz.

// apps/consumer_app/lib/screens/checkout/payment_page.dart içine eklenecek widget ve state mantığı:

bool _dontRingBell = false;
bool _leaveAtDoor = false;

Widget _buildDeliveryPreferencesCard(ThemeData theme) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Teslimat Tercihleri",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // 1. Seçenek: Temassız Teslimat (Kapıya Bırak)
          SwitchListTile(
            value: _leaveAtDoor,
            title: const Text("Kapıya Bırak", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Sipariş kapınıza bırakılır, kurye ile temas etmezsiniz."),
            secondary: Icon(Icons.door_front_door_outlined, color: theme.colorScheme.primary),
            onChanged: (bool value) {
              setState(() {
                _leaveAtDoor = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          
          // 2. Seçenek: Sessiz Teslimat (Zili Çalma)
          SwitchListTile(
            value: _dontRingBell,
            title: const Text("Zili Çalma", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Zil çalınmaz; kapı hafifçe vurulur veya telefonla aranır."),
            secondary: Icon(Icons.notifications_off_outlined, color: theme.colorScheme.primary),
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
  );
}


📱 4. Bölüm: Satıcı & Kurye Uygulaması (Merchant App) UI Entegrasyonu

Kuryenin adrese ulaştığında zili çalarak evdekileri uyandırmasını veya temassız teslimat kuralını ihlal etmesini önlemek amacıyla, bu iki tercihi satıcı sipariş detaylarında ve kurye takip kartlarında devasa, dikkat çekici renkli rozetler (Badges) ile gösteriyoruz.

A. Sipariş Detay Kartı Güncellemesi (merchant_order_list_page.dart / order_detail_page.dart)

Sipariş kartının veya detay sayfasının en üstüne, eğer bu seçenekler aktifse göz alıcı uyarı etiketleri yerleştiriyoruz:

// apps/merchant_app/lib/apps/merchant/widgets/delivery_preference_badges.dart

Widget _buildDeliveryPreferenceBadges({
  required bool dontRingBell,
  required bool leaveAtDoor,
  required ThemeData theme,
}) {
  if (!dontRingBell && !leaveAtDoor) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        if (leaveAtDoor) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade300, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.door_front_door, size: 16, color: Colors.blue.shade800),
                const SizedBox(width: 6),
                Text(
                  "KAPIYA BIRAK 🚪",
                  style: TextStyle(
                    color: Colors.blue.shade900, 
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (dontRingBell) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade300, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_off, size: 16, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Text(
                  "ZİLİ ÇALMA 🔕",
                  style: TextStyle(
                    color: Colors.orange.shade900, 
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}


📢 Doğrulama Planı

Database Migration:

cd backend && npx prisma db push && npx prisma generate


Backend Derleme Analizi:

cd backend && npx tsc --noEmit


Flutter Statik Analizleri:

cd apps/consumer_app && flutter analyze
cd apps/merchant_app && flutter analyze


Manuel Test Senaryosu:

Tüketici uygulamasından "Zili Çalma" ve "Kapıya Bırak" seçeneklerini aktif ederek sipariş geçin.

Satıcı uygulamasına gelen yeni siparişte "ZİLİ ÇALMA 🔕" ve "KAPIYA BIRAK 🚪" renkli rozetlerinin parlak bir şekilde yandığını doğrulayın.