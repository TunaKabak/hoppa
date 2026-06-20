Epic: Order & Checkout Management (Sipariş ve Sepet Yönetimi)
Task: Story 6 - E2E Test Senaryosu ve Teknik Dökümantasyon

Tüm geliştirme süreçleri harika bir şekilde tamamlandı. Eline sağlık! Artık fiziksel cihazlarla E2E testlerine hazırız. 

Son adım olarak senden projeyi canlı ortam gibi düşündüğümüz bir "Test Dökümantasyonu" hazırlamanı istiyorum. Lütfen kök dizinde `e2e_live_test_plan.md` (veya benzer bir isimde) bir Markdown dosyası oluştur. Bu dosya, benim gibi projeyi fiziksel cihazlarla test edecek kişi için adım adım bir rehber olsun. 

İçeriğinde şunlar KESİNLİKLE yer alsın:

1.  **Hazırlık (TCP Reverse):** Hem Merchant (Tablet) hem Consumer (Telefon) için `adb reverse tcp:3000 tcp:3000` komutlarının çalıştırılması ve Prisma'nın `DATABASE_URL` / `DIRECT_URL` üzerinden Supabase'e bağlı olduğunun teyidi.
2.  **Senaryo 1: Onboarding ve Dükkan Aktivasyonu:** 
    *   Satıcının kayıt olup "Lazy Onboarding" kısıtlamasına takılması (Eksik VKN vs.).
    *   Ayarlardan eksik bilgilerin girilip Dükkanın `isActive: true` yapılması.
3.  **Senaryo 2: Katalog ve "Altın Kural":** 
    *   Tüketicinin A dükkanından sepete ürün atması.
    *   Sonra B dükkanından ürün eklemeye çalışıp `AlertDialog` (Sepeti Temizle) ekranını görmesi.
4.  **Senaryo 3: Mükerrer Sipariş (Double Submit) ve Başarılı Ödeme:**
    *   Sepet onayında "Siparişi Tamamla" butonuna basıp loading (yükleniyor) halinin görülmesi ve Supabase'deki `Order` ile `OrderItem` tablolarına verinin Atomik olarak (transaction ile) yansıması.

Lütfen sadece bu Markdown dökümanını oluştur. Ben bu dökümanı referans alarak telefonum ve tabletimle fiziksel testleri gerçekleştireceğim!