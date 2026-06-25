🔍 Story 18 - Teknik Tasarım ve Uygulama Planı Değerlendirmesi

Genel Değerlendirme Derecesi: İyi (Good)

Plan, REST mimarisi ve Flutter bileşen tasarımı açısından çok başarılı; ancak veritabanı bütünlüğü ve ondalıklı sayı matematiği konularında can sıkıcı bug'lara yol açabilecek birkaç kritik eksik içeriyor.

🚨 1. KRİTİK KÖR NOKTA: CartItem.quantity Eksikliği (Veritabanı Seviyesi)

📌 Sorun:

Önerilen planda OrderItem.quantity alanını Float tipine dönüştürüyorsun ancak CartItem.quantity alanına dokunmuyorsun.

Bir kullanıcı manav dikeyinde sepetine $1.5\text{ kg}$ patates eklemek istediğinde, mobil uygulama sepet API'sine quantity: 1.5 gönderecektir.

Eğer veritabanında CartItem.quantity hala Int (Tam Sayı) olarak kalırsa, Prisma ya yazma aşamasında hata fırlatacak ya da bu küsuratı aşağıya yuvarlayarak ($1.5 \rightarrow 1$) veriyi kıracaktır. Bu durum sepet ile sipariş arasında tutarsızlığa yol açar.

🛠️ Çözüm (Düzeltici Aksiyon):

schema.prisma dosyasındaki güncellemelere mutlaka CartItem modelini de dahil etmeliyiz:

model CartItem {
  id        String   @id @default(uuid())
  cartId    String
  productId String
  quantity  Float    // Kesinlikle Int -> Float olarak güncellenmeli!
}


⚡ 2. MÜHENDİSLİK DETAYI: Dart / JS Ondalıklı Sayı Hassasiyeti (Floating Point Precision)

📌 Sorun:

Dart ve JavaScript (dolayısıyla PostgreSQL double precision ve Dart double tipleri), sayıları ikilik (binary) sistemde temsil eder. Bu durum meşhur ondalıklı toplama/çıkarma hatalarına yol açar:


$$0.1 + 0.2 \ne 0.3 \quad (\text{Sonuç: } 0.30000000000000004)$$

Kullanıcı $0.25\text{ kg}$ artış adımıyla sepetine sürekli ekleme yaptığında (Örn: $0.25 \rightarrow 0.5 \rightarrow 0.75 \rightarrow 1.0$), Dart tarafında miktar bir süre sonra 1.0000000000000002 gibi saçma bir değere dönüşebilir. Bu da:

qty == qty.roundToDouble() kontrolünü bozarak arayüzde 1 KG yerine 1.00 KG (hatta 1.0000000000000002 KG) yazmasına neden olur.

quantity < minQuantity karşılaştırmalarında beklenmeyen mantıksal hatalara yol açar.

🛠️ Çözüm (Düzeltici Aksiyon):

QuantityFormatter veya CartProvider içerisine, ondalıklı sayıları güvenli bir şekilde yuvarlayacak (epsilon/rounding) bir yardımcı fonksiyon eklemeliyiz.

// Belirli bir hassasiyete göre double yuvarlama fonksiyonu
double roundDouble(double val, {int places = 2}) {
  double mod = math.pow(10.0, places).toDouble();
  return ((val * mod).round().toDouble() / mod);
}


Sepete ekleme yaparken veya eksiltirken yeni miktarı mutlaka bu fonksiyondan (veya double.parse(qty.toStringAsFixed(2))) geçirerek normalize etmeliyiz.

📈 3. KULLANICI DENEYİMİ (UX) ÖNERİSİ: Dinamik Minimum Miktar Kontrolü

📌 Sorun:

Kullanıcı sepetindeki $0.5\text{ kg}$ olan patates miktarını azaltmak için [-] butonuna bastığında, doğrudan $0.25$ değerine düşmemelidir. Çünkü ürünün minQuantity değeri $0.5$ olarak belirlenmiştir.

🛠️ Çözüm (Düzeltici Aksiyon):

cart_provider.dart içerisindeki miktar azaltma mantığı şu kuralı işletmelidir:

Eğer currentQuantity - stepSize < product.minQuantity ise, miktarı azaltmak yerine ürünü sepetten tamamen çıkarmalıdır.

Bu sayede kullanıcının minimum sipariş miktarının altında (Örn: $0.25\text{ kg}$) ürün satın alması doğrudan arayüz ve provider seviyesinde engellenir.

🏆 Sonuç

Bu üç kritik düzeltmeyi planımıza dahil ettiğimizde, Story 18 süpermarket/manav dikeyinde uluslararası standartlarda, hatasız ve kurşun geçirmez bir operasyonel kararlılığa ulaşacaktır.