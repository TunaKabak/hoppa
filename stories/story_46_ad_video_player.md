# Story #46: Ana Ekranda Hoppa Reklam Videosunun Oynatılması

## Teknik Tasarım ve Kapsam

Bu hikaye, Hoppa tüketici uygulamasının (`consumer_app`) ana ekranında bulunan "HOPPA ÖZEL REKLAM" alanına dokunulduğunda, yerel olarak barındırılan reklam videosunun (`assets/videos/hoppa_reklam.mp4`) açılacak bir diyalog penceresinde oynatılabilmesini amaçlar.

### 1. Bağımlılıkların ve Assetlerin Eklenmesi
* **Video Oynatıcı Paketi:** `pubspec.yaml` dosyasına `video_player: ^2.8.6` paketi eklenecek ve `flutter pub get` çalıştırılacaktır.
* **Asset Tanımlaması:** `pubspec.yaml` altındaki `assets` kısmına `- assets/videos/hoppa_reklam.mp4` kaydı eklenecektir.

### 2. Video Oynatıcı Arayüzü Tasarımı (`HoppaVideoPlayerDialog`)
* **Görünüm:** Kullanıcı reklam alanına tıkladığında ekranın ortasında açılan, modern, köşeleri yuvarlatılmış (radius: 24), koyu temalı (premium dark backdrop) ve şık bir diyalog penceresi.
* **Kontroller:**
  * Video yüklendiğinde otomatik oynatma.
  * Oynat/Duraklat (Play/Pause) butonu.
  * Ses Aç/Kapat (Mute/Unmute) butonu.
  * İlerleme çubuğu (Video progress indicator / Slider) - videodaki mevcut konumu ve toplam süreyi gösteren, sürüklemeye/tıklamaya duyarlı ince bir zaman çizgisi.
  * Sağ üst köşede kapatma (X) butonu.
  * Video bittiğinde tekrar oynatma (Replay) butonu.
* **Kaynak Yönetimi:** Diyalog kapatıldığında `VideoPlayerController` düzgün şekilde dispose edilecek (kaynak sızıntılarını önlemek için).

### 3. Reklam Alanı Tıklama Tetikleyicisi (`selection_category_page.dart`)
* `selection_category_page.dart` içerisindeki "HOPPA SPECIAL ADVERTISING BANNER" bileşeni bir `InkWell` veya `GestureDetector` ile sarmalanacak.
* Tıklama anında `showDialog` yardımıyla `HoppaVideoPlayerDialog` açılacak.

## Doğrulama Protokolü
* `flutter analyze` komutu çalıştırılarak projede statik analiz hatası olmadığı doğrulanır.
* Tüketici uygulamasının başarıyla derlendiği doğrulanır.
* Reklam alanına tıklandığında videonun düzgün yüklenip oynatılabildiği, ses ve oynatma kontrollerinin çalıştığı doğrulanır.
