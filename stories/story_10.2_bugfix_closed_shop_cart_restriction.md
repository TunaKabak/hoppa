Epic: Consumer App User Experience (UX)
Task: Bugfix - Kapalı Dükkanlarda Sepete Ürün Eklemenin Kesin Olarak Engellenmesi

DİKKAT (AGENT İÇİN): Bu görev .agent/rules anayasasına tabidir. Önceki geliştirmede dükkan kapalı olmasına rağmen sepete ürün ekleme fonksiyonunun hala çalıştığı tespit edilmiştir. Lütfen aşağıdaki adımları sırayla ve KESİN çözüm sağlayacak şekilde uygula.

ADIM 1: Veritabanı ve Model Alanı Kontrolü

backend/prisma/schema.prisma dosyasında dükkanın açık/kapalı durumunu tutan alanın adını doğrula (isActive veya ilgili alan).

Tüketici (Consumer) uygulamasındaki Shop model dosyasını aç ve bu alanın Dart tarafında doğru şekilde parse edildiğinden emin ol.

ADIM 2: UI Seviyesinde Kesin Engelleme (Alt Bileşenler Dahil)

apps/consumer_app/lib/screens/shop_detail_page.dart dosyasını aç.

Sadece ana sayfayı değil, ürünlerin listelendiği tüm alt bileşenleri (Varsa ProductCard, ProductTile, ProductListItem vb.) incele.

Eğer dükkan KAPALIYSA (isActive == false):

Ürün kartlarındaki sepete ekleme butonlarının (Artı simgeleri, "Sepete Ekle" butonları) onPressed metodunu KESİNLİKLE null yap (böylece butonlar otomatik olarak grileşir ve tıklanamaz hale gelir).

Butonun görselliğini pasif (disabled) duruma getirerek kullanıcının dükkanın kapalı olduğunu net bir şekilde anlamasını sağla.

ADIM 3: State / Controller Seviyesinde Çift Kilit (Garantili Çözüm)

Kullanıcı bir şekilde UI engellerini aşsa bile (örneğin gecikmeli yüklenen bir state durumunda), sepet kontrolörü kapalı dükkandan ürün eklenmesini reddetmelidir.

Sepet işlemlerini yöneten Riverpod state notifier/controller dosyasını (Örn: cart_provider.dart veya cart_controller.dart) bul.

addItem veya addToCart fonksiyonunun içerisine şu kontrolü ekle:

// Eğer eklenmek istenen ürünün dükkanı aktif değilse işlemi sessizce durdur veya hata fırlat
if (product.shop?.isActive == false) {
  throw Exception("Bu dükkan kapalı olduğu için sepetinize ürün eklenemez.");
}


ADIM 4: Doğrulama ve Statik Analiz

Değişiklikleri yaptıktan sonra terminalde cd apps/consumer_app && flutter analyze çalıştırarak hiçbir hata veya uyarı kalmadığını doğrula.

Yapılan düzeltmeyi ve hatanın tam olarak nerede unutulduğunu kullanıcıya raporla.