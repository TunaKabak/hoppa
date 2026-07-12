# Story 39: Açılışta Kategoriler, Misafir Modu ve Sepet Kuralları

Bu hikaye, Hoppa tüketici uygulamasının açılış akışını optimize etmeyi, kullanıcıların giriş yapmadan dükkanları ve ürünleri gezebilmesini sağlamayı, sepet aşamasında giriş ve adres zorunluluğu getirmeyi ve arayüzü görsel olarak parlatmayı hedefler.

---

## 📋 Gereksinimler

1. **Açılışta Kategoriler Ekranı:** Uygulama açıldığında doğrudan giriş ekranı yerine İşletme Kategorileri sayfası (`SelectionCategoryPage`) açılmalıdır.
2. **Misafir Modu Gezinti (Bypass):** Kullanıcı giriş yapmamış olsa dahi kategorileri, dükkanları ve ürünleri listeleyebilmeli ve gezebilmelidir.
3. **Giriş & Adres Zorunluluğu (Sepet Kuralı):**
   * Kullanıcı sepete ürün eklemek istediğinde giriş yapmış olmalı ve seçili bir teslimat adresi bulunmalıdır.
   * Giriş yapılmadıysa "Giriş Yapmalısınız" uyarısı verilerek Login ekranına yönlendirilmelidir.
   * Adres seçilmediyse "Adres Seçmelisiniz" uyarısı verilerek Adres Seçim ekranına yönlendirilmelidir.
4. **Giriş Yap/Üye Ol Kartı:** Giriş yapmamış kullanıcılar için açılış ekranının en altında, yönlendirme amaçlı şık bir "Giriş Yap veya Üye Ol" kartı ve açıklaması bulunmalıdır.
5. **Hoppa Reklam Alanı:** Giriş kartının hemen üstünde, Hoppa'ya özel, video/görsel içerebilen premium bir reklam banner alanı yer almalıdır.
6. **Üst Hoş Geldin & Global Arama:**
   * Açılış sayfasının en üstünde modern bir hoş geldin mesajı bulunmalıdır.
   * Arama çubuğu eklenmelidir. Bu arama; kategorileri, işletmeleri ve ürünleri kapsayan global bir arama olmalıdır.
7. **Header Bar Modernizasyonu:** Açılış ekranındaki üst header bar daha şık, modern ve premium bir tasarıma kavuşturulmalıdır.
8. **Kategori Görsel Geçişleri (Smooth Blend):** Kategori kartlarındaki 3D görsellerin keskin kare sınırları yerine, kartın pastel gradyan rengiyle yumuşak bir şekilde bütünleşmesini (smooth blend) sağlayacak maskeleme uygulanmalıdır.

---

## 🛠️ Teknik Tasarım

### 1. Veritabanı & Backend API
* **Bypass Auth (Optional Authentication Middleware):**
  * Katalog ve kategori görüntüleme endpoint'lerinin misafirler tarafından da kullanılabilmesi için backend tarafında `optionalAuthMiddleware` tanımlanacaktır.
  * `/shops`, `/shops/:id/products`, `/shops/:id/categories`, `/campaigns`, `/business-categories` yolları isteğe bağlı kimlik doğrulamaya geçirilecektir.
* **Global Arama Endpoint'i (`/api/consumer/search/global`):**
  * Verilen `q` parametresine göre `BusinessCategory`, `Shop` ve `Product` tablolarında arama yapıp gruplanmış sonuçlar dönecektir.

### 2. Mobil Uygulama (Frontend)
* **Kimlik Doğrulama Akışı:**
  * `ConsumerAuthWrapper` artık misafir kullanıcıları da `MainLayoutPage`'e yönlendirecektir.
  * Giriş ekranı (`LoginPage`) can pop desteğine kavuşturularak kapatilebilir olacaktır.
* **Sepet Validasyonu:**
  * `CartValidation` adında merkezi bir yardımcı sınıf oluşturulacak ve sepete ekleme butonlarında bu validasyon çalıştırılacaktır.
* **Smooth Blend (Görsel Maskeleme):**
  * `CategoryGridItem` içindeki görseller `ShaderMask` ve `RadialGradient` kullanılarak top-left kısımlarından transparanlaşacak şekilde yumuşatılacaktır.
* **Arama Entegrasyonu:**
  * `SearchPage` hem belirli bir dükkan içindeki aramayı hem de `selectedBusiness` null iken global aramayı (kategori, dükkan, ürün) destekleyecek şekilde güncellenecektir.
