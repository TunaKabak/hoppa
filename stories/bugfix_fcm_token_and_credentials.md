Bugfix: Satıcı Token Kayıt Hatası (P2003) ve Canlı Sunucu Firebase Bağlantısı

Bu görev; satıcı uygulamasının bildirim token kaydı yaparken aldığı Foreign Key ilişkisel hatasını çözmeyi ve Render canlı sunucusundaki Firebase bağlantı uyarılarını gidermeyi amaçlar.

🚨 1. ADIM: Satıcı (Merchant) Kimlik Doğrulama ve Token Uyuşmazlığının Çözülmesi

Sorun: DeviceToken tablosu User tablosuna bağlıdır (DeviceToken.userId -> User.id). Satıcı uygulamasından gelen token kayıt isteğindeki userId (JWT'den çözülen ID) User tablosunda bulunamadığı için PostgreSQL P2003 (Foreign Key Constraint) hatası fırlatıyor.

Mühendislik Analizi: Satıcı uygulamasının giriş/token üretim mekanizmasını kontrol et. Satıcının JWT token'ı üretilirken id alanı olarak Shop.id veya Merchant.id mi veriliyor?

Çözüm Yolları (Agent Tarafından İncelenmeli):

Seçenek A: Satıcının da her halükarda User tablosunda bir kaydı olmalıdır. Satıcı giriş yaptığında JWT içerisindeki id mutlaka User.id (rolü MERCHANT olan kullanıcı) olmalıdır. Eğer JWT'ye Shop.id yazılıyorsa, token kayıt endpoint'inde userId yerine shopId veya satıcının gerçek kullanıcı ID'si bulunarak DeviceToken tablosuna yazılmalıdır.

Seçenek B: Eğer satıcılar User tablosunda değil, tamamen bağımsız bir Merchant veya Shop tablosunda tutuluyorsa, schema.prisma dosyasındaki DeviceToken modelini gevşeterek satıcı token'larının da kaydolabilmesi için userId ilişkisini opsiyonel yap veya shopId / merchantId kolonunu ekle.

Öneri: En temiz yol, her satıcının da bir User kaydının olması ve JWT'deki id'nin User.id olmasıdır. Agent bu uyuşmazlığı tespit edip kod seviyesinde düzeltecektir.

🔑 2. ADIM: Render Üzerinde Canlı Firebase Anahtar Doğrulaması

Sorun: Render loglarında WARNING: Firebase credentials not found, running in MOCK mode uyarısı yer alıyor.

Çözüm:

Render Dashboard'daki Environment Variables alanına git.

Eklediğin değişkenlerin isimlerinin backend kodundaki NotificationService.ts veya .env okuma mantığıyla tam olarak eşleştiğinden emin ol:

FIREBASE_PROJECT_ID

FIREBASE_CLIENT_EMAIL

FIREBASE_PRIVATE_KEY

Özel Dikkat (FIREBASE_PRIVATE_KEY): Render panelinde FIREBASE_PRIVATE_KEY değerini girerken başındaki ve sonundaki çift tırnakları (") kaldırıp ham şekilde girdiğinden emin ol. Ayrıca kodun içindeki replace(/\\n/g, '\n') mantığının bu anahtarı düzgün çevirip çevirmediğini doğrula.

📢 DOĞRULAMA PLANI

cd backend && npx tsc --noEmit ile hatasız derlendiği doğrulanacak.

Render sunucusu yeniden başladıktan sonra loglarda Firebase Admin SDK initialized successfully yazısı aranacak (Mock mode uyarısı kalkmalıdır).

Satıcı uygulaması açıldığında Supabase DeviceToken tablosuna satıcının token'ının başarıyla yazıldığı doğrulanacak.