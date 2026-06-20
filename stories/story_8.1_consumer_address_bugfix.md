Epic: Checkout & User Experience
Task: Bugfix - Tüketici Uygulamasında Adres Kaydetme İşleminin Onarılması

Sorun: Tüketici (Consumer) uygulamasında AddAddressPage sayfasında veriler girilip "Kaydet" butonuna basıldığında adres kaydedilemiyor/işlem tamamlanamıyor.

Lütfen aşağıdaki adımları sırayla izleyerek bu entegrasyon sorununu çöz:

Frontend "Kaydet" Mantığını İncele:

apps/consumer_app/lib/.../add_address_page.dart dosyasını aç. "Kaydet" butonunun hangi Riverpod provider'ını veya Repository'i çağırdığını kontrol et.

Kritik: Eğer burada hala FirebaseFirestore.instance... kullanılıyorsa, bunu DERHAL SİL.

Frontend Adres Repository / API Client Bağlantısı:

Adres kaydetme işleminin core_network paketindeki ApiClient üzerinden Backend REST API'mize (POST /api/consumer/addresses veya benzeri bir endpoint) istek attığından emin ol.

Gerekirse address_repository.dart ve address_controller.dart (Riverpod) dosyalarını bu yeni API yapısına göre güncelle. Hataları UI'da göstermek için try/catch ve SnackBar mantığını kur.

Backend API ve Route Kontrolü:

backend dizinine git. İstemcinin çağırdığı adresi karşılayacak bir Endpoint var mı kontrol et.

Eğer yoksa: AddressController.ts oluştur ve req.user.id kullanarak Prisma ile Address tablosuna (title, city, district, fullAddress vb.) yeni kayıt ekleyen bir metod yaz.

consumerRoutes.ts dosyasına bu rotayı (Örn: POST /addresses) bağla.

Lütfen Frontend ve Backend arasındaki bu iletişimi uçtan uca test edilebilir hale getir. İşlemi bitirdiğinde hatanın kaynağının (Firebase kalıntısı mı yoksa eksik API mi) ne olduğunu bana kısaca raporla.