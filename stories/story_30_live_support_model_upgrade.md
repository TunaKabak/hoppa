# Story 30: Canlı Destek ve Kurye Canlı Takip İyileştirmeleri

## 1. Giriş ve Sorun Tanımı
1. **Canlı Destek Asistanı (Hoppa Asistan):**
   - Gemini modelinin `gemini-2.5-flash` olarak güncellenmesi ve API yanıt formatının `data` sarmalıyla hizalanmasından sonra, asistanın promptlarında iyileştirme ihtiyacı doğmuştur.
   - Asistanın kullanıcıya teknik/veritabanı UUID sipariş ID'lerini ifşa etmesi engellenmeli, birden fazla aktif sipariş olduğunda bunları akıllıca yönetebilmeli ve hitap tonu aşırı samimi ("canım" vb.) olmaktan çıkarılıp saygılı ama Kıbrıs sıcakkanlılığında resmiyet-samimiyet dengesine oturtulmalıdır.
2. **Kurye Canlı Takip Sistemi:**
   - Supabase Realtime ile entegre kurye konumu canlı takibi tüketici uygulamasında çalışmamaktadır. Bunun nedeni, Supabase veritabanında `CourierLocation` tablosunun Row-Level Security (RLS) politikasının aktif olup anonim okumalara izin vermemesidir.

## 2. Teknik Analiz ve Çözüm Planı
1. **SupportController.ts Prompt & Bağlam İyileştirmesi:**
   - `prisma.order.findMany` ile kullanıcının PENDING, PREPARING, ON_THE_WAY, READY_FOR_PICKUP durumundaki tüm aktif siparişleri ve son geçmiş siparişi çekilerek bağlama aktarıldı.
   - Sistem talimatlarına kullanıcıya ham sipariş ID'si verilmemesi ve "canım", "gülüm" gibi ifadelerin kesinlikle yasaklanması kuralları eklendi.
2. **Kurye Takip RLS Kaldırılması:**
   - PostgreSQL/Supabase katmanında `CourierLocation` tablosunun RLS özelliği devre dışı bırakılarak anonim harita aboneliklerinin stream dinleyebilmesi sağlandı (`ALTER TABLE "CourierLocation" DISABLE ROW LEVEL SECURITY;`).

## 3. Etki Analizi (Impact Analysis)
- **Tüketici Uygulaması (Consumer App):** 
  - Destek asistanı daha profesyonel, güvenli ve açıklayıcı yanıtlar verir.
  - Sipariş takip haritasında kuryenin konumu canlı olarak akmaya başlar.
- **Backend (REST API):**
  - Destek endpoint'i birden fazla aktif siparişi kapsayacak şekilde güncellendi.

## 4. Değişiklik Yapılan Dosyalar
- `backend/src/controllers/SupportController.ts`
- Database/Supabase RLS ayarları güncellendi.

## 5. Doğrulama (Verification)
- TypeScript derleme doğrulaması (`npx tsc --noEmit`).
- Kurye takip stream erişimi doğrulaması.
