# Story 31.1: Kurye Canlı Takip Sıcak Düzeltmesi (Hotfix)

## 1. Giriş ve Sorun Tanımı
Kullanıcılardan gelen geri bildirimlere göre, tüketici uygulamasındaki sipariş takip ekranında kuryenin konumu canlı olarak güncellenmemekte, haritada sabit veya eski bir konumda kalmaktadır.

### Hata Analizi
1. Veritabanındaki `CourierLocation` tablosunda, bir kuryeye (`courierId: bd0ce625-2a97-4625-9463-b0082d35335b`) ait birden fazla konum kaydı bulunmaktadır. Bunlardan biri random UUID'ye sahip eski bir kayıt (`id: cfb1afe9-9075-4793-87aa-5ce95d78f518`), diğeri ise kuryenin asıl ID'sine sahip güncel kayıttır (`id: bd0ce625-2a97-4625-9463-b0082d35335b`).
2. Kurye uygulamasından gelen konum güncelleme isteklerinde `CourierController.ts`, konumu `where: { id: courier.id }` üzerinden günceller. Bu, kuryenin ID'si ile eşleşen `id` alanına sahip satırı günceller veya yaratır.
3. Ancak tüketici uygulamasındaki `courierLocationStreamProvider` stream sorgusu `.eq('courierId', courierId)` filtresini kullanarak tüm eşleşen kayıtları çekmekte ve içlerinden ilkini (`data.first`) döndürmektedir.
4. Sıralamada eski, güncellenmeyen ve random UUID'li kayıt ilk sırada geldiği için tüketici uygulamasında kurye konumu hep sabit/eski görünmektedir.

## 2. Teknik Çözüm
1. **İstemci Tarafında (Consumer App):**
   `courierLocationStreamProvider` içindeki filtrelemeyi `.eq('courierId', courierId)` yerine `.eq('id', courierId)` olarak değiştireceğiz. Çünkü backend kurye konumunu her zaman `id = courierId` olacak şekilde upsert etmektedir. Bu sayede her zaman doğrudan güncellenen tekil kaydı dinleyeceğiz.
2. **Veritabanı Temizliği:**
   Veritabanında `id != courierId` olan hatalı/eski kayıtları silerek mükerrerliği ortadan kaldıracağız.
3. **Supabase RLS ve Cache Eşitlemesi:**
   Supabase Realtime ve PostgREST servislerinin RLS önbellek uyuşmazlığından dolayı istemci dinleme sırasında `PostgrestException: new row violates Row-Level Security policy` (42501) hatası dönmekteydi. 
   Bunu gidermek amacıyla `CourierLocation` tablosunda RLS aktif hale getirilip anonim ve doğrulanmış kullanıcılara açık bir `SELECT` politikası tanımlandı (`CREATE POLICY "Allow select for all" ON "CourierLocation" FOR SELECT USING (true);`). Ardından `NOTIFY pgrst, 'reload schema';` ile PostgREST şema önbelleği yenilendi.

## 3. Değişiklik Yapılacak Dosyalar
- `apps/consumer_app/lib/apps/consumer/orders/order_tracking_page.dart`
- Veritabanı temizlik scripti (`backend/clean_locations.js`)
- RLS politika ve cache yenileme scripti (`backend/setup_rls_policy.js`)
