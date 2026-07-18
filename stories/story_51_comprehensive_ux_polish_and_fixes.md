# 📊 Story 51: Kapsamlı UX İyileştirmeleri ve Hata Düzeltmeleri (Comprehensive UX Polish & Fixes)

Bu döküman, Hoppa projesinde kullanıcı deneyimini (UX) mükemmelleştirmek, cüzdan ve davet sistemlerindeki fonksiyonel hataları gidermek ve esnaf panelinde kampanya/reklam yönetimini tamamlamak üzere yapılacak geliştirmeleri tanımlar.

---

## 🏛️ 1. STRATEJİK İNCELEME & DEĞİŞİKLİK MATRİSİ

Uygulamanın hem tüketici (Consumer) hem de esnaf (Merchant) taraflarında tespit edilen 18 adet iyileştirme/düzeltme başlığı aşağıda kategorize edilmiştir:

| No | Bileşen | Başlık | Geliştirme Detayı |
|:---|:---|:---|:---|
| **1** | Frontend | Filtrele/Sırala Butonları Aktif Durumu | Filtre veya sıralama aktifse hem ikon hem metin gösterilecek; aktif değilse (varsayılan) sadece ikon gösterilerek arayüz sadeleştirilecek. |
| **2** | Frontend | Yapışkan (Sticky) Filtre Barı | Dükkan listesindeki filtre, sıralama ve kategori barı aşağı kaydırıldığında turuncu üst curve'ün hemen altına yapışacak (`SliverPersistentHeader` kullanılacak). |
| **3** | Backend/FE | Kampanya & Reklam Yönetim Akışı | Esnaf panelinde oluşturulan SQL tabanlı reklam ve afişler (`ShopCampaign`), tüketici dükkan detay sayfasında tıklanabilir kampanya banner'ı olarak gösterilecek ve tıklandığında kampanya detay sayfasına yönlendirecek. |
| **4** | Frontend | Farklı Dükkan Uyarısı | Farklı dükkandan ürün eklenirken çıkan standart `AlertDialog`, kurumsal `HoppaDialog` ile değiştirilecek. |
| **5** | Frontend | Sepet Teslimat Uyarı Mesajları | `CompactDeliveryStatus` içindeki kafa karıştırıcı "Kurye ücreti bedava! Kalan: X TL" gibi metinler daha anlaşılır ve kullanıcı dostu hale getirilecek. |
| **6** | Frontend | Dükkan Detay Collapsed Header | Dükkan detayında aşağı kaydırılınca küçülen AppBar, Hoppa turuncusu (`0xFFE95D22`) rengine bürünecek ve alt köşeleri curve (kavisli) olacak. |
| **7** | Frontend | Dükkan Kartlarında Min Sepet Tutarı | Dükkan listesindeki kartların altında "Paket Servis" yerine minimum sepet tutarı (örneğin "Min: ₺250") yazacak. |
| **8** | Frontend | Sepeti Görüntüle Butonu | Ana ekrandaki (SelectionCategoryPage) sepeti görüntüle butonu modern gradientler, gölgeler ve yuvarlatılmış köşelerle premium seviyeye taşınacak. |
| **9** | Frontend | Sepet Detayında İşletme Adı | Sepet detay sayfasında sepetin hangi dükkana ait olduğu ("Sepetim - Dükkan Adı") şeklinde başlıkta gösterilecek. |
| **10** | Frontend | Alışverişe Devam Et Butonu | Sepet detayındayken "Alışverişe Devam Et" butonu, sepetin ait olduğu dükkanın detay sayfasına (`selectBusiness`) yönlendirecek. |
| **11** | Teknik | Kampanya vs Reklam Mimarisi | Firestore tabanlı eski `Campaign` yapısı ile SQL tabanlı yeni `ShopCampaign` yapısının rolleri netleştirilecek (Açıklama aşağıda). |
| **12** | FE/BE | Kampanya Resmi Önizleme & Rol Hatası | Kampanya afişi yüklerken resim seçilir seçilmez yerel dosya önizlemesi (`Image.file`) gösterilecek. Ayrıca `'merchant'` rolüne sahip kullanıcıların menüde Kampanyalar ve Reklam & Afiş sekmelerini görememesi hatası düzeltilecek. |
| **13** | Database/FE | Kampanya Ürün Kapsamı | `ShopCampaign` tablosuna `targetProducts String[]` alanı eklenerek esnafın kampanya oluştururken bu kampanyanın hangi ürünleri kapsadığını seçebilmesi sağlanacak. |
| **14** | Backend/FE | Hoppa Cüzdan Hatası | Cüzdan API endpoint'inin (`/api/consumer/wallet`) response formatındaki `data` sarmalı eksikliği giderilecek; cüzdan hareketleri (transactions) API'ye entegre edilecek. |
| **15** | Backend/FE | Davet Et & Kazan Hatası | Davet sistemi API endpoint'i (`GET /api/consumer/referral`) ve ilişkili alt route'lar tamamlanacak. Davet geçmişindeki status kontrolü tamamlanmış siparişlere göre dinamik hesaplanacak. |
| **16** | Frontend | Cohesiveness (Ortak Header) | Dil seçimi, Favorilerim, Sipariş Detay, Değerlendirmelerim, Bildirim Ayarları ve Canlı Destek ekranlarına premium `HoppaHeader` eklenecek. |
| **17** | Frontend | Adres Seçim Kartı Tasarımı | Adres listesinde seçili olan adres kartının görünümü daha modern, ince kenarlıklı ve soft gölgeli hale getirilecek. |
| **18** | Frontend | Sepet Temizleme Onay Diyaloğu | Sepeti boşaltma onay ekranı düz `AlertDialog` yerine `HoppaDialog` olarak güncellenecek. |

---

## 🛠️ 2. TEKNİK TASARIM VE VERİTABANI DEĞİŞİKLİKLERİ

### A. Veritabanı Şeması Güncellemesi (`schema.prisma`)
`ShopCampaign` modeline esnafın kampanyaya özel seçtiği ürünlerin barcode/ID listesini tutabilmek için `targetProducts` dizisi eklenir:

```prisma
model ShopCampaign {
  id            String   @id @default(uuid())
  shopId        String
  shop          Shop     @relation(fields: [shopId], references: [id], onDelete: Cascade)
  title         String
  description   String
  imageUrl      String
  targetArea    String   // "SHOP_DETAIL", "CATEGORY_SLIDER", "MAIN_SLIDER"
  status        String   @default("PENDING_APPROVAL")
  designService Boolean  @default(false)
  isActive      Boolean  @default(true)
  targetProducts String[] @default([]) // [YENİ] Kampanyanın kapsadığı ürün barkodları
  createdAt     DateTime @default(now())
  orders        Order[]

  @@index([shopId])
}
```

### B. Hoppa Cüzdan API Formatı
`WalletController.ts` içindeki `getWallet` metodunun dönüş yapısı tüketici uygulamasındaki beklentiye (`data.wallet.transactions` vb.) uygun hale getirilir:

```typescript
// GET /api/consumer/wallet response structure
{
  "error": false,
  "data": {
    "wallet": {
      "id": "wallet-uuid",
      "balance": 150.00,
      "transactions": [
        {
          "id": "tx-uuid",
          "amount": 100.00,
          "type": "DEPOSIT",
          "description": "Bakiye Yükleme",
          "createdAt": "2026-07-18T20:00:00.000Z"
        }
      ],
      "createdAt": "...",
      "updatedAt": "..."
    }
  }
}
```

### C. Davet Et & Kazan API Entegrasyonu
`ReferralController.ts` ve `referralRoutes.ts` altına `GET /` ana route'u eklenecektir. Bu route:
1. Kullanıcının `referralCode` bilgisini alır (yoksa oluşturur).
2. Kullanıcının davet ettiği kullanıcıları (`ReferralService.getReferrals`) çeker.
3. Davet edilen kullanıcıların sipariş durumunu inceler. Eğer kullanıcının en az 1 adet `DELIVERED` siparişi varsa, davet durumunu `COMPLETED` olarak işaretler.
4. Toplam kazancı (`completedCount * 100`) hesaplar ve geri döner.

---

## 🚀 3. UYGULAMA ADIMLARI VE DOĞRULAMA PLANININ ONAYLANMASI

Geliştirmeler, Hoppa Anayasası (`AGENTS.md`) uyarınca küçük, doğrulanabilir adımlarla gerçekleştirilecek olup, her adım sonrası derleme kontrolleri çalıştırılacaktır.
Hikaye onayından sonra `task.md` ve `implementation_plan.md` dosyaları oluşturulacak ve kod yazımına başlanacaktır.
