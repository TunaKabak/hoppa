Epic: Payment & Checkout UX Improvements
Task: Story 12.1 - İki Aşamalı Ödeme Gruplama ve Akıllı Tarih Giriş Biçimlendirici Entegrasyonu

DİKKAT (AGENT İÇİN): Bu görev .agent/rules (Sistem Anayasası) kurallarına tabidir. Mevcut çalışan hiçbir iş mantığını bozmadan, sadece belirtilen dosyaları güncelleyerek ilerle.

🛠️ ADIM 1: Akıllı Tarih Giriş Biçimlendiricisi (Input Formatter) Oluşturulması

Kullanıcıların kredi kartı son kullanma tarihini (AA/YY) girerken manuel olarak bölü (/) tuşunu aramalarını engellemek için akıllı bir biçimlendirici yazacağız.

apps/consumer_app/lib/utils/card_input_formatters.dart (veya ilgili utils klasörü) adında bir dosya oluştur.

Dosya içerisine, kullanıcının sadece rakam yazarak son kullanma tarihini AA/YY formatına getirmesini sağlayan CardExpiryInputFormatter sınıfını ekle.

Bu sınıfın, kullanıcı silme tuşuna (Backspace) bastığında sapıtmamasını ve karakterleri düzgün yönetmesini sağla.

🎨 ADIM 2: İki Aşamalı Ödeme Seçimi (Two-Tier Payment Selection) UI Tasarımı

Mevcut yan yana sığmayan orantısız ödeme butonlarını kaldırıp, daha profesyonel ve düzenli bir gruplama mimarisine geçeceğiz.

apps/consumer_app/lib/screens/checkout/payment_page.dart (veya ilgili sepet/ödeme ekranı) dosyasını aç.

Mevcut ödeme seçeneği seçim alanını kaldır ve yerine iki aşamalı bir seçim yapısı kur:

Seçenek 1: Kredi / Banka Kartı (Online Ödeme)

Seçenek 2: Kapıda Ödeme

Eğer kullanıcı Kredi / Banka Kartı seçeneğini seçerse, kart bilgileri formu görünür kalsın.

Eğer kullanıcı Kapıda Ödeme seçeneğini seçerse, kart formu yumuşak bir animasyonla (AnimatedCrossFade veya AnimatedContainer) gizlensin ve hemen altında iki küçük alt buton (Sub-Options) açılsın:

Kapıda Nakit

Kapıda Kredi Kartı

Bu iki aşamalı yapı sayesinde ekranın yatayda taşmasını ve görsel kirliliği tamamen engelle.

✏️ ADIM 3: Terminoloji ve Formatter Entegrasyonu

Ödeme sayfasındaki tüm "Online Kart", "Online Kredi Kartı" gibi eski ibareleri, kullanıcıya daha çok güven veren "Kredi / Banka Kartı" ifadesiyle değiştir.

Kart son kullanma tarihi (Expiry Date) TextFormField widget'ını güncelle:

keyboardType özelliğini TextInputType.number yap (kullanıcının önüne sadece rakam klavyesi çıksın).

inputFormatters listesine CardExpiryInputFormatter sınıfını ve karakter sınırı için LengthLimitingTextInputFormatter(5)'i ekle.

🔄 ADIM 4: Sipariş Gönderim (Payload) Mantığının Güncellenmesi

Sipariş onay butonuna basıldığında backend'e gönderilen sipariş paketindeki (Order Payload) paymentMethod değerini kullanıcının yeni iki aşamalı seçimine göre eşleştir:

Kredi / Banka Kartı seçildiyse -> ONLINE_PAYMENT

Kapıda Ödeme ve Nakit seçildiyse -> CASH_ON_DELIVERY (veya mevcut nakit karşılığı)

Kapıda Ödeme ve Kart seçildiyse -> CARD_ON_DELIVERY (veya mevcut kart karşılığı)

📢 DOĞRULAMA VE RAPORLAMA

cd apps/consumer_app && flutter analyze çalıştırarak statik analiz uyarılarını temizle.

UI tasarımlarını kontrol et ve uygulamanın hatasız çalıştığını raporla.