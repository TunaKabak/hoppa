# Story 64: Ödeme Yöntemlerinde Hoppa Cüzdan (Bakiye) Entegrasyonu

## 1. Amaç ve Kapsam
Bu hikaye kapsamında Hoppa Tüketici Uygulamasındaki (`consumer_app`) ödeme ve onay sayfasında (`payment_page.dart`) ve arka planda (`backend`) aşağıdaki geliştirmeler gerçekleştirilecektir:

1. **Ödeme Yöntemlerine Hoppa Cüzdanım Eklemesi:**
   - Ödeme seçenekleri arasına **"Hoppa Cüzdanım"** (`WALLET`) ödeme seçeneği dahil edilecek.
   - Kullanıcının anlık cüzdan bakiyesi (`/api/consumer/wallet`) çekilerek ödeme kartı üzerinde canlı bakiye bilgisi gösterilecek.
   - Bakiye yeterli ise yeşil "Bakiye Yeterli" rozeti, yetersiz ise turuncu "Yetersiz Bakiye" uyarısı ve hızlı Bakiye Yükle yönlendirmesi sunulacak.

2. **Sipariş Oluşturma ve Temassız Teslimat Uyumluğu:**
   - `WALLET` ödeme yöntemi seçildiğinde kart bilgisi girilmesine gerek kalmadan doğrudan cüzdan bakiyesinden düşüm yapılarak sipariş oluşturulacak.
   - Hoppa Cüzdan ile ödemelerde temassız teslimat ("Kapıya Bırak") seçeneği aktif tutulacak.
   - Backend tarafında tüm dükkanlar için Hoppa Cüzdan ödeme yöntemi geçerli kabul edilecek ve bakiye düşümü güvenli işlem (`$transaction`) ile gerçekleşecek.
