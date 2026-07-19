# Story 54: Merchant Settings Page Refresh Bug Fix

## 1. Analiz ve Bulgular

### 1.1. Problem
İşletme uygulamasında (`merchant_app`) aktif olarak yönetilen işletme değiştirildiğinde (`selectedMerchantBusinessIdProvider` güncellendiğinde), Ayarlar ekranı (`merchant_settings_page.dart`) yeni seçilen işletmenin bilgilerini göstermek yerine bir önceki işletmenin bilgilerini göstermeye devam etmektedir.

### 1.2. Neden
`merchant_settings_page.dart` içerisindeki `build` fonksiyonunda dükkan bilgisi alındıktan sonra denetleyicilerin (`TextEditingController` vb.) başlatılması `_isInitialized` bayrağı ile kontrol edilmektedir:
```dart
if (shopAsync.hasValue && shopAsync.value != null) {
  final shop = shopAsync.value!;

  if (!_isInitialized) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _initControllers(shop);
      });
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
```
Sayfa ilk yüklendikten sonra `_isInitialized` değeri `true` olmaktadır.
Aktif dükkan değiştirildiğinde sayfa yeniden oluşturulur. Ancak `_isInitialized` zaten `true` olduğu için `if (!_isInitialized)` bloğuna girilmez ve `_initControllers(shop)` **asla çağrılmaz**. Bu yüzden form alanları eski dükkanın verilerini göstermeye devam eder.

## 2. Çözüm Önerisi

### 2.1. İstemci Değişikliği (`merchant_settings_page.dart`)
`build` fonksiyonunda gelen dükkanın ID'si, o an başlatılmış olan `_shop` dükkanının ID'sinden farklı ise `_isInitialized` bayrağı `false` yapılacaktır:
```dart
    if (shopAsync.hasValue && shopAsync.value != null) {
      final shop = shopAsync.value!;

      if (_isInitialized && _shop?.id != shop.id) {
        _isInitialized = false;
      }

      if (!_isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _initControllers(shop);
          });
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
```
Bu sayede dükkan değiştiğinde:
1. `_isInitialized` değeri `false` olur.
2. Sayfa bir yükleme göstergesi (`CircularProgressIndicator`) gösterir.
3. Post frame callback ile `_initControllers(shop)` çalışarak tüm denetleyicileri ve durumları yeni dükkan verileriyle günceller ve `_isInitialized = true` yapar.
4. Sayfa güncel form alanlarıyla yeniden çizilir.
