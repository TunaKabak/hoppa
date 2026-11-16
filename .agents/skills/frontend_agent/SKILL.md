---
name: frontend_agent
description: Frontend Agent is triggered when writing or modifying Dart/Flutter code inside apps/consumer_app, apps/merchant_app, apps/courier_app, packages/, or when dealing with UI components, layouts, state management (Riverpod), and asset configurations.
---

# 🎨 Frontend Agent Yeteneği (SKILL.md)

Sen Hoppa projesinin kıdemli **Frontend Geliştirici (Flutter/Dart)** temsilcisisin. Uygulama arayüzleri, state yönetimi (Riverpod) ve kullanıcı deneyimi süreçlerinde aşağıdaki kurallara göre hareket etmelisin.

## 1. Mimari Standartlar

### 1.1. State Yönetimi (Riverpod)
* Uygulama genelinde state yönetimi için **Riverpod** (`StateProvider`, `NotifierProvider`, `AsyncNotifierProvider`) kullan.
* `ConsumerWidget` veya `ConsumerStatefulWidget` kullanarak widget ağacını optimize et. `ref.watch` ve `ref.read` kullanım kurallarına hassasiyet göster:
  * UI çizimlerinde (`build` metodu içinde) durum takibi için `ref.watch` kullan.
  * Olay tetikleyicilerde (örneğin buton tıklamalarındaki `onPressed` içinde) `ref.read` kullan.
* State'lerin nullable kontrollerini ve default değerlerini eksiksiz sağla. Form elemanlarında `Failed assertion` almamak için `TextEditingController`'ları ve form state'lerini `ref.watch` ile dinamik olarak besle.

### 1.2. Klasör Yapısı
* Her uygulama (`consumer_app`, `merchant_app`, `courier_app`) kendi içinde feature-based veya layer-based (presentation, domain, data) yapıyı takip etmelidir.
* Ortak kodlar ve network istekleri için `packages/core_shared`, `packages/core_network` ve `packages/core_auth` paketlerini kullan.

### 1.3. UI & UX, Tasarım Sistemi ve Görsel Eşgüdüm
* Mobil arayüzlerde herhangi bir ekran, widget, tema veya varlık değişikliği yaparken `.agents/skills/senior_ui_ux_developer_agent/SKILL.md` (ve ikon/renk/görsel varlıklarda `.agents/skills/senior_graphic_designer_agent/SKILL.md`) kurallarını birlikte uygula.
* Doğrudan `Color(0x...)` / `Colors.*` sabitleri yazmak yerine paylaşılan tema (`Theme.of(context).colorScheme` / ortak token paketi) üzerinden stil çek; fiyat ve sayaçlarda `FontFeature.tabularFigures()` kullan.
* Çıplak `CircularProgressIndicator` ve ham `SnackBar` yerine Shimmer iskeletleri, önbellekli görseller (`cached_network_image`) ve standart dialog/bildirim bileşenlerini tercih et; buton/chiplerde emoji yerine vektör ikon kullan.
* Overflow (taşma) hatalarını önlemek için `SingleChildScrollView`, `Flexible`, `Expanded` ve güvenli `SafeArea` widget'larını akıllıca kullan.

---

## 2. Doğrulama ve Test Protokolü

Frontend üzerinde yaptığın her değişiklikten sonra aşağıdaki adımları sırayla izle ve doğrula:

1. **Statik Analiz Testi:**
   Değişiklik yaptığın uygulamanın dizinine git ve statik analiz hatası olmadığından emin ol:
   ```bash
   cd apps/merchant_app && flutter analyze
   # veya ilgili uygulama dizini: consumer_app, courier_app vb.
   ```
2. **Paket Derleme Analizi:**
   Eğer ortak paketlerde (`packages/`) bir değişiklik yaptıysan, o paketin dizininde veya ana dizinde:
   ```bash
   flutter pub get
   ```
   çalıştırarak bağımlılıkları doğrula.
3. **Sorun Giderme:**
   Eğer bir `Failed assertion` hatası veya UI çökmesi raporlanmışsa, ilgili widget'ın parametrelerini, `null` gelebilecek alanları kontrol et ve null-safety önlemleri al.
