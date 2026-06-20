# Proje Mimarisi ve Güvenlik Analizi Raporu

Bu rapor, projenin mimarisini analiz eder ve tespit edilen güvenlik eksikliklerini detaylandırır.

## 1. Proje Mimarisi

Proje, Flutter framework'ü kullanılarak geliştirilmiştir ve genel olarak iyi bir mimariye sahiptir.

- **Bağımlılıklar:** Proje, `provider` (state management), `go_router` (navigasyon), ve `firebase` (backend) gibi topluluk tarafından kabul görmüş ve güvenilir paketler kullanmaktadır. `pubspec.yaml` dosyasında zafiyet oluşturabilecek şüpheli bir pakete rastlanmamıştır.
- **Kod Yapısı:** Kod, `features` baslıklı klasörler altında özellik bazlı (feature-based) bir yapıya sahiptir. Bu, kodun okunabilirliğini, bakımını ve geliştirilmesini kolaylaştıran modern bir yaklaşımdır. `core` klasörü altında servisler, sabitler ve genel widget'lar gibi paylaşılan modüllerin bulunması da iyi bir organizasyon örneğidir.

## 2. Tespit Edilen Güvenlik Zafiyetleri ve Öneriler

### 2.1. Kritik Zafiyet: Eksik Firestore Güvenlik Kuralları

**Bulgu:**

Kod tabanında en kritik güvenlik açığı, Firestore veritabanı güvenlik kurallarını içeren `firestore.rules` dosyasının bulunmamasıdır. Bu dosya olmadan, veritabanına erişim kurallarının ne kadar güvenli olduğunu doğrulamak imkansızdır.

**Risk:**

Eğer güvenlik kuralları doğru yapılandırılmamışsa, kötü niyetli bir kullanıcılar,
- Tüm kullanıcıların verilerini okuyabilir,
- Başka kullanıcıların verilerini değiştirebilir veya silebilir,
- Sisteme yetkisiz veri ekleyebilirler.

**Öneri:**

1.  **Varsayılan Olarak Reddet (Default Deny):** Firestore kurallarının en temel prensibi, varsayılan olarak tüm okuma ve yazma işlemlerini engellemektir.
    
    ```
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        // Bütün erişimi varsayılan olarak reddet
        match /{document=**} {
          allow read, write: if false;
        }
      }
    }
    ```
    
2.  **Yetkilendirme (Authentication):** Veritabanı erişimi sadece giriş yapmış kullanıcılarla sınırlandırılmalıdır.
    
    ```
    allow read, write: if request.auth != null;
    ```
    
3.  **Rol Bazlı Erişim Kontrolü (Role-Based Access):** Kullanıcıların sadece kendi verilerine erişebilmesi sağlanmalıdır. Örneğin, `users` koleksiyonunda her kullanıcı sadece kendi belgesini okuyup yazabilmelidir.
    
    ```
    match /users/{userId} {
      allow read, update: if request.auth.uid == userId;
      allow create: if request.auth.uid != null;
    }
    ```
    
4.  **Veri Doğrulama (Data Validation):** Firestore'a yazılacak verinin formatı ve türü doğrulanmalıdır. Bu, sisteme hatalı veya kötü niyetli veri girilmesini engeller.
    
    ```
    match /products/{productId} {
      allow write: if request.resource.data.name is string &&
                      request.resource.data.price is number &&
                      request.resource.data.price > 0;
    }
    ```
    

### 2.2. Orta Dereceli Zafiyet: Kod Gizleme (Obfuscation) Eksikliği

**Bulgu:**

Android (`build.gradle.kts`) ve iOS (`project.pbxproj`) yapılandırma dosyalarında, yayın (release) modları için kod gizlemenin (obfuscation) aktif edildiğine dair bir kanıt bulunamamıştır. (Önceki geri alma işleminden sonra bu dosyaların orijinal haline döndüğü varsayılmıştır.)

**Risk:**

Kod gizleme olmadan, uygulamanın tersine mühendislik (reverse-engineering) ile kaynak kodunun kolayca analiz edilmesi mümkündür. Bu durum, saldırganların;
- Uygulama mantığını anlamasını,
- API anahtarları gibi hassas verileri (eğer varsa) bulmasını,
- Güvenlik kontrollerini atlatmak için zafiyetler aramasını kolaylaştırır.

**Öneri:**

Flutter'da kod gizleme, `build` komutuna `--obfuscate` ve `--split-debug-info` bayrakları eklenerek kolayca aktif edilebilir:

```bash
flutter build appbundle --obfuscate --split-debug-info=/<proje-dizini>/debug-info
flutter build apk --obfuscate --split-debug-info=/<proje-dizini>/debug-info
flutter build ios --obfuscate --split-debug-info=/<proje-dizini>/debug-info
```

### 2.3. Düşük Dereceli Zafiyet: Yönlendirme (Deep Link) Güvenliği Belirsizliği

**Bulgu:**

`pubspec.yaml` dosyasında `go_router` paketi bulunmasına rağmen, yönlendirme (routing) yapılandırması kod içinde tespit edilememiştir. Bu nedenle, dış bağlantılarla (deep links) uygulamanın nasıl etkileşime girdiği ve bu sürecin güvenli olup olmadığı analiz edilememiştir.

**Risk:**

Eğer yönlendirme mekanizması güvenli değilse, kötü niyetli bir web sitesi veya uygulama, özel hazırlanmış bir deep link ile;
- Kullanıcıyı beklenmedik sayfalara yönlendirebilir,
- Hassas verilere erişim sağlamaya çalışabilir.

**Öneri:**

- **Parametre Doğrulaması:** Deep link ile gelen tüm parametreler dikkatlice doğrulanmalı ve temizlenmelidir (sanitize). Beklenmeyen veya geçersiz parametreler reddedilmelidir.
- **Yetki Kontrolü:** Deep link ile erişilen sayfanın, kullanıcının yetkisi dahilinde olup olmadığı kontrol edilmelidir. Örneğin, `/profile` sayfasına yönlendirilen bir kullanıcının gerçekten giriş yapmış olup olmadığı doğrulanmalıdır.
- **Yapılandırmanın İncelenmesi:** `GoRouter` yapılandırmasının bulunduğu kodun detaylıca incelenerek, yukarıdaki risklere karşı önlem alınıp alınmadığı kontrol edilmelidir.

## 3. Sonuç

Proje, genel olarak sağlam bir mimariye sahip olsa da, özellikle **Firestore güvenlik kurallarının eksikliği** kritik bir risk teşkil etmektedir. Bu zafiyetin acilen giderilmesi, uygulamanın ve kullanıcı verilerinin güvenliği için hayati önem taşımaktadır.

Kod gizlemenin aktif edilmesi ve deep link mekanizmasının gözden geçirilmesi gibi diğer öneriler de uygulamanın genel güvenlik seviyesini artıracaktır.