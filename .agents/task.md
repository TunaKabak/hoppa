# Görev Takip Listesi (task.md)

## 📍 1. İşletme Mesafesi Formatlaması (1km Altı Metre Gösterimi)
- [x] `packages/core_shared/lib/shared/core/utils/location_utils.dart` içerisine `LocationUtils.formatDistance(km)` metodunun eklenmesi
- [x] `apps/consumer_app` mesafe metinlerinin güncellenmesi (0 Hata)

## 🎨 2. Satıcı Web Paneli Kavisli Header & Flat Buton Tasarım Sistemi (Story 86)
- [x] `MerchantLayout.tsx` kavisli Hoppa degrade header entegrasyonu
- [x] Web paneli turuncu neon gölgelerinin temizlenmesi
- [x] `npx tsc --noEmit` ile derleme kontrolü (0 Hata)

## 🛑 3. En Az 1 Ürün Şartı & Tüketici Görünürlük Koruması
- [x] `backend/src/controllers/ShopController.ts` açılış engeli (0 ürün ile dükkan açma yasaklandı)
- [x] `backend/src/controllers/ProductController.ts` son aktif ürün pasife/silinmeye alındığında dükkanı otomatik kapatma
- [x] `backend/src/controllers/ConsumerShopController.ts` ürünü olmayan/pasif dükkanların tüketicilere listelenmesini engelleme
- [x] `merchant_dashboard_page.dart` ve `MerchantLayout.tsx` ürün yoksa uyarı pop-up'ı ve ürünlere yönlendirme

## 🎨 4. Consumer App Kategori Seçimi Border & Shadow Modernizasyonu
- [x] `hoppa_category_badge.dart` ve `shop_detail_page.dart`: Seçili kategori kartlarındaki aşırı kalın border (2.5px -> 1.5px/0.8px) ve yoğun turuncu parlama (glow) gölgelerinin daha yumuşak, modern ve zarif hale getirilmesi.

## 🏷️ 5. Boş Kategoriler İçin "Yakında" Etiketi & Giriş Engellemesi
- [x] `BusinessCategoryController.ts`: Hiç aktif işletmesi olmayan kategorilere otomatik `badge: "yakında"` ve `isComingSoon: true` atanması.
- [x] `category_badge.dart`: Gri/slate temalı şık "YAKINDA" rozeti eklenmesi.
- [x] `selection_category_page.dart`: Yakında rozetli kategorilere tıklanınca boş ekrana girmek yerine *"Bu kategori yakında hizmetinizde"* bilgilendirme bildirimi verilmesi.

## 💳 6. Ödeme & Onay Adımında Zorunlu Alan Form Validasyonu ve Buton Kilidi
- [x] `checkout_page.dart`: Adres, telefon veya teslimat zamanı seçilmeden "Ödemeye Geç" butonunun pasif kalması ve metninin *"Eksik Bilgileri Tamamlayın"* olarak güncellenmesi.
- [x] `payment_page.dart`: Online kredi kartı seçiminde yeni kart veya kayıtlı kart CVC kuralı tamamlanmadan "Siparişi Onayla" butonunun kilitlenmesi.

## 🚀 7. Satıcı Paneli Mağaza Hazırlık ve Aktivasyon Merkezi (Story 87 UYGULANDI)
- [x] `backend/src/controllers/ShopController.ts`: `GET /api/merchant/shop/readiness` endpoint'inin yazılması (6 prosedür adımının dinamik puanlaması: %0 - %100).
- [x] `backend/src/routes/merchantRoutes.ts`: `/shop/readiness` rotasının tanımlanması.
- [x] `apps/web_app/src/components/merchant/StoreReadinessWidget.tsx`: Satıcı web paneli için canlı ilerleme çubuğu, profil doluluk oranı ve hızlı aksiyon kartları widget'ı.
- [x] `apps/web_app/src/components/merchant/StoreReadinessModal.tsx`: 6 prosedür adımını ve eksikleri detaylandıran interaktif diyalog penceresi.
- [x] `apps/merchant_app/lib/apps/merchant/widgets/store_readiness_card.dart`: Satıcı mobil uygulaması dashboard hazırlık kartı.

## 🗺️ 8. Web Satıcı Panelinde Admin İçin KKTC Hizmet Alanları Sınır Çizimi (Story 88)
- [x] `backend/src/controllers/SuperAdminController.ts` & `backend/src/routes/adminRoutes.ts`: `GET /api/admin/service-zones` ve `PUT /api/admin/service-zones` rotalarının eklenmesi
- [x] `apps/web_app/src/components/merchant/MerchantLayout.tsx`: Sol menüye Admin için `KKTC Hizmet Alanları` sekmesinin eklenmesi
- [x] `apps/web_app/src/components/merchant/KktcServiceZoneDrawerMap.tsx`: Leaflet tabanlı çoklu bölge çizim, köşe düzenleme, KKTC maskeleme ve canlı nokta test bileşeninin geliştirilmesi
- [x] `apps/web_app/src/pages/merchant/service-zones/index.tsx`: Kavisli header, bölge listesi, preset şablonlar ve kaydetme yönetim sayfasının oluşturulması
- [x] TypeScript & Next.js production derleme doğrulaması (`npm run build` - 0 Hata)

## 🤖 9. Telegram Remote Agent Bridge Kurulumu ve Entegrasyonu (Story 89)
- [x] `agent-remote-bridge/` dizini ve Python 3.12 sanal ortamının (`venv`) oluşturulması
- [x] Bağımlılıkların (`python-telegram-bot`, `pydantic-settings`, `python-dotenv`) yüklenmesi
- [x] `config.py`: Pydantic Settings ile `.env` yapılandırma modelinin kodlanması
- [x] `security.py`: Allowed User ID Whitelist kimlik doğrulama dekoratörünün yazılması
- [x] `agent_runner.py`: Asenkron komut yürütücü, Flutter/Backend/Web teşhis araçları ve çıktı dilimleme
- [x] `main.py`: Telegram Bot uygulama çatısı, komut yöneticileri ve interaktif buton menüsü
- [x] `.env`, `.env.example`, `.gitignore` ve `README.md` dosyalarının oluşturulması
- [x] Terminalden Python çalışma ve doğrulama testlerinin tamamlanması



## 🏢 10. Web Satıcı Paneli Kurumsal & Enterprise Dönüşümü (Story 90 - UYGULANDI)
- [x] `stories/story_90_corporate_merchant_portal_redesign.md`: Kurumsal tasarım sistemi, Executive KPI Dashboard, Enterprise Veri Tabloları ve Çoklu Şube mimarisinin hazırlanması.
- [x] `dashboard/index.tsx`: Kurumsal Executive Yönetici Paneli, Canlı Sipariş Operasyon Akışı, Finansal Mutabakat ve Hakediş kartlarının uygulanması (0 Hata - 12/12 Sayfa Derlendi).
- [x] `MerchantLayout.tsx`: Kurumsal üst çubuk, modern breadcrumb ve profesyonel sidebar hiyerarşisinin güncellenmesi.
- [x] `products/index.tsx`: Excel / CSV kurumsal dışa aktarma (export), toplu işlem çubuğu ve kurumsal veri ızgarası entegrasyonu.
- [x] `orders/index.tsx`: Canlı operasyon takip rozetleri, termal fiş yazdırma ve sesli alarm uyarı sistemi.
- [x] Derleme Doğrulamaları: `npm run build` (0 Hata / 12/12 Sayfa) ve `npx tsc --noEmit` (0 Hata) ile doğrulandı.



## 📥 Telegram'dan Gelen Onaylı Görevler
- [x] Web satıcı panelinde dropdownlar modern olmalı (Hoppa turuncusu Chevron ve kavisli stil entegre edildi - 0 Hata)
- [x] Planı uygulayalım (Tüm web satıcı dropdown'ları .hoppa-select ile modernize edildi)
- [x] [ID:8a6de2b8] Satıcı paneli daha kurumsal olmalı iyileştirme planı oluştur (Story 90 oluşturuldu)
- [x] [ID:16f857b7] Satıcı paneli daha kurumsal olmalı iyileştirme planı oluştur (Story 90 oluşturuldu)
- [x] [ID:a5fae42c] Satıcı paneli daha kurumsal olmalı iyileştirme planı oluştur (Story 90 oluşturuldu)

## 🧹 Faz 0: Çalışma Ağacı Hijyeni ve Koruma Kuralları
- [x] `BusinessCategoryController.ts`: Genişletilmiş kategori alias'larını koruyup `products: { some: { isActive: true } }` ve `merchant: { status: "ACTIVE" }` filtrelerini geri yüklemek
- [x] `selection_category_page.dart`: `"yakında"` / `"coming_soon"` tıklama engelleyici SnackBar korumasını geri yüklemek
- [x] `business_selection_page.dart`: Kategori alias iyileştirmesini korumak ve doğrulamak

## 🛡️ Faz 1: Web Süper Admin Yönetim Merkezi (Story 91)
- [x] `backend/`: `SuperAdminController.getPendingMerchants` `?status=` & `?search=` desteği, `ReviewController.getAdminReviews`, `ShopCampaignController.getAdminCampaigns` ve `adminRoutes.ts` (`GET /reviews`, `GET /campaigns`)
- [x] `apps/web_app/`: `MerchantLayout.tsx` Süper Admin Merkezi menüsü + `admin/merchants.tsx`, `admin/couriers.tsx`, `admin/moderation.tsx`, `admin/categories.tsx` sayfaları
- [x] Faz 1 doğrulaması (`backend` `tsc --noEmit` + `web_app` `tsc --noEmit` & `npm run build`)

## 🔐 Faz 2: Web Satıcı Çoklu Hesap Girişi, Yorumlar ve Sponsorlu Vitrin (Story 92)
- [x] `backend/`: `ReviewController.getMerchantShopReviews` ve `merchantRoutes.ts` `GET /reviews`
- [x] `apps/web_app/`: Güvenli çoklu hesap (`auth.types.ts`, `saved-accounts.ts`, `AccountChooser.tsx`, `MerchantLoginForm.tsx`, `login.tsx`) + `reviews/index.tsx` & `promotions/index.tsx` + `MerchantLayout.tsx` menü güncellemeleri
- [x] Faz 2 doğrulaması (`backend` `tsc --noEmit` + `web_app` `tsc --noEmit` & `npm run build`)

## 🛵 Faz 3: Kurye Uygulaması Production Dönüşümü (Story 93)
- [x] `backend/`: `CourierController` (`GET /me`, `POST /me/apply`, `GET /orders/history`, `PATCH/PUT /orders/:id/pickup`, `getAssignedOrders` options/consumer/READY_FOR_PICKUP) ve `courierRoutes.ts`
- [x] `apps/courier_app/`: Sabit test verilerinin kaldırılması, modüler onboarding durum kapısı, `isActive` + `CourierLocationEngine` senkronizasyonu, 2 aşamalı teslimat ve geçmiş/kazanç sekmesi
- [x] Faz 3 doğrulaması (`backend` `tsc --noEmit` + `courier_app` `flutter analyze`)

## 💳 Faz 4: Sanal POS 3D Secure Mimarisi ve Gerçek Zamanlı SSE (Story 94)
- [x] `backend/` + `consumer_app/`: `IPaymentProvider` (Sandbox, CardPlus, PayTR, Stripe), dinamik `PUBLIC_BASE_URL`, HMAC doğrulamalı `/api/payments/3d-callback` (`$transaction`) ve `ThreeDSecurePage` güncellemesi
- [x] `backend/` + `web_app/`: `RealtimeEventService.ts` + `GET /api/events/stream` + `realtime-client.ts` ve `MerchantLayout` / `orders` / `dashboard` canlı güncellemeleri
- [x] Faz 4 ve genel monorepo doğrulaması (`backend`, `web_app`, `consumer_app`, `courier_app`)

## 🎨🛡️ Story 95: Kıdemli Tasarım/UX Agent'ları & Prod Öncesi Tam Denetim
- [x] `.agents/skills/senior_graphic_designer_agent/` & `references/hoppa_brand_and_visual_standards.md` oluşturulması (eski `designer_agent` kaldırıldı)
- [x] `.agents/skills/senior_ui_ux_developer_agent/` & `references/design_system_ux_and_security_checklist.md` oluşturulması
- [x] `.agents/skills/qa_agent/SKILL.md` (AppSec kapıları), `web_agent/SKILL.md`, `frontend_agent/SKILL.md`, `.agents/AGENTS.md` ve `agent-remote-bridge/task_analyzer.py` güncellemeleri
- [x] Web, Satıcı Paneli, SuperAdmin, 3 Mobil Uygulama (`consumer`, `merchant`, `courier`) ve Backend/Web/Mobil Prod Güvenlik derin kod denetiminin tamamlanıp `stories/story_95_senior_design_ux_agents_and_prod_audit.md` ile raporlanması
- [x] Faz A (Story 95A): Prodüksiyon Kritik & Yüksek Güvenlik Açıklarının (`C-01`..`C-09`, `H-01`..`H-10`) Giderilmesi
- [x] Faz B (Story 95B): Hoppa Design System v2.0 Token'ları, Vektör Logomark/SVG Seti & Varlık Optimizasyonu
- [x] Faz C (Story 95C): Public Web, Kurumsal Satıcı Paneli & SuperAdmin UX/UI Dönüşümü
- [x] Faz D (Story 95D): `consumer_app`, `merchant_app` & `courier_app` UX, Dönüşüm ve Saha Ergonomisi Dönüşümü



