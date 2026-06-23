Epic: Live Data Sync & Address Persistence (UX & State Integrity)
Task: Story 11 - Canlı Durum Senkronizasyonu, Adres Kararlılığı, Pull-to-Refresh ve Ödeme Validasyon Onarımı

DİKKAT (AGENT İÇİN): Bu görev .agent/rules anayasasına tabidir. Her adımı sırayla yap, testlerini tamamla ve flutter analyze ve tsc doğrulaması yapmadan görevi teslim etme.

ADIM 1: Tüketici Adres Seçiminin Kararlı Hale Getirilmesi (State Persistence)

Seçilen adresin durup dururken kaybolmasını engellemek için Riverpod state yapısını kalıcı (persistent) ve uzun ömürlü (keepAlive) hale getireceğiz.

apps/consumer_app/lib/.../location_controller.dart (seçili adres durumunu yöneten provider) dosyasını bul.

Bu provider'ın AutoDispose özelliğini kaldır. Riverpod generator kullanıyorsan @riverpod yerine @Riverpod(keepAlive: true) kullan. Düz StateNotifierProvider kullanıyorsan AutoDisposeStateNotifierProvider yerine doğrudan StateNotifierProvider kullan.

SharedPreferences Entegrasyonu:

Kullanıcı bir adres seçtiğinde (selectAddress metodu tetiklendiğinde), seçilen adres nesnesini (veya ID'sini) SharedPreferences kullanarak cihazın yerel hafızasına kaydet.

Provider ilk başlarken (build() veya initialization aşamasında) öncelikle SharedPreferences'ı kontrol et. Eğer önceden seçilmiş bir adres varsa, state'i doğrudan o adresle başlat.

Bu sayede dükkan detaylarına girip çıkınca veya uygulama arka plana alınınca adres seçimi ASLA sıfırlanmayacaktır.

ADIM 2: İşletme Listesi İçin "Aşağı Kaydırıp Yenileme" (Pull-to-Refresh)

Kullanıcının dükkan listesini manuel olarak güncelleyebilmesi sağlanacaktır.

apps/consumer_app/lib/screens/home_screen.dart (veya dükkanların listelendiği ana sayfa) dosyasını aç.

Dükkan listesini (ListView / GridView) içeren ana widget'ı bir RefreshIndicator widget'ı ile sar.

onRefresh callback metoduna Riverpod refresh mantığını bağla:

onRefresh: () async {
  // Dükkanları çeken future provider'ı zorla yenile (invalidate/refresh)
  ref.invalidate(shopsProvider);
  await ref.read(shopsProvider.future);
}


Arayüzde aşağı kaydırınca yenileme çarkının döndüğünü ve güncel verinin başarıyla çekildiğini doğrula.

ADIM 3: Canlı Senkronizasyon (Instant Status Sync)

Satıcının dükkanı açıp kapatması gibi kritik değişikliklerin tüketiciye anında yansıması sağlanacaktır.

Supabase Realtime / Polling Altyapısı Kararı:

shopsProvider yapısını incele. Eğer Supabase istemcisini doğrudan kullanıyorsak, Shop tablosuna bir supabase.from('Shop').stream(...) veya supabase.channel(...) aboneliği (subscription) ekle.

Eğer tüm akış Node.js API'miz üzerinden yürüyorsa ve hızlı bir entegrasyon gerekiyorsa; shopsProvider içerisine bir Timer (veya Stream.periodic) ekleyerek uygulamanın odağa geldiği (App Lifecycle - Resumed) anlarda dükkan durumlarını API'den sessizce (arka planda) güncelleyen bir mekanizma kur.

Satıcı uygulamasında dükkan durumu değiştiği an (Database update), Tüketici uygulamasının dükkan listesindeki "Açık/Kapalı" etiketinin sayfayı kapatıp açmaya gerek kalmadan güncellendiğini doğrula.

ADIM 4: Ödeme Adımı "İşletme Hizmet Vermiyor" Validasyonunun Onarılması (Yeni)

Dükkan açık olmasına rağmen ödeme adımına geçerken alınan "işletme şuanda hizmet vermiyor" mantık hatası giderilecektir.

Backend Sipariş/Ödeme Controller Kontrolü:

backend/src/controllers/OrderController.ts veya sipariş oluşturma (checkout/payment) isteklerini karşılayan dosyayı aç.

Sipariş oluşturulmadan önce dükkanın durumunu doğrulayan validasyon kod bloğunu bul.

Zaman Dilimi (UTC+3) Düzeltmesi:

Eğer kod dükkanın çalışma saatlerini (örn. 09:00 - 22:00) kontrol ediyorsa, new Date() komutunun sunucu saati olan UTC'yi döndüğünü göz önünde bulundur.

Saat kontrolünü yaparken Türkiye/Kıbrıs yerel saat dilimini (UTC+3) baz alacak şekilde düzelt veya dükkanın doğrudan manuel isActive / isOpen boolean değerini birincil kontrol olarak kullan.

Mesafe ve Durum Validasyonu Sıkılaştırma:

Eğer adrese göre mesafe kontrolü yapılıyorsa ve adres koordinatları eksik gönderildiyse genel "hizmet vermiyor" hatası fırlatılmasını engelle. Koordinat yoksa anlamlı hata dön: "{ error: true, message: 'Lütfen teslimat adresi için haritadan konum seçiniz.' }"

Dükkanın durumunu doğrulamak için sadece güncel veritabanındaki isActive alanını baz al.

DOĞRULAMA (Validation):

Backend tarafında npm run build ile TypeScript derlemesini doğrula.

ADIM 5: Doğrulama ve Raporlama

Tüm değişiklikleri kaydet.

cd apps/consumer_app && flutter analyze komutu ile statik analiz hatalarını temizle.

Adresin neden seçimden çıktığını (eski hatalı mantığı), yaptığın canlı veri senkronizasyonu çözümünü ve ödeme adımındaki "hizmet vermiyor" validasyon hatasını nasıl giderdiğini detaylıca raporla.