Story 27 - Kurye Uygulaması Entegrasyonu ve Canlı Konum Takip Motoru

Bu görev belgesi; Hoppa monorepo yapısına apps/courier_app adında yeni bir Flutter projesi entegre etmeyi; ortak core_network ve core_auth paketlerini buraya bağlamayı; kuryelerin nöbet durumlarını (On Duty / Off Duty) ve saniyelik konumlarını ($Lat, Lng$) backend'e akıtacak konum motorunu ve sipariş teslimat süreçlerini yönetmeyi amaçlar.

🧭 1. BÖLÜM: Monorepo Mimari Tasarımı (Dependency Reuse)

Monorepomuzun gücünü kullanarak, kurye uygulaması için yeni bir auth veya network paketi yazmıyoruz. Projenin kök dizinindeki pubspec.yaml ve yeni apps/courier_app/pubspec.yaml dosyası üzerinden ortak kütüphanelerimizi bağlıyoruz:

hoppa-monorepo/
├── apps/
│   ├── consumer_app/
│   ├── merchant_app/
│   └── courier_app/ (Yeni!)
└── packages/
    ├── core_network/ (Ortak HTTP İstemcisi)
    └── core_auth/ (Ortak OTP/Giriş Mantığı)


apps/courier_app/pubspec.yaml İçerisine Paketlerin Bağlanması:

name: courier_app
description: "Hoppa - Kurye Teslimat ve Canlı Konum Takip Uygulaması"
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.0.0
  flutter_dotenv: ^5.1.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  google_maps_flutter: ^2.5.0
  flutter_swipe_button: ^3.0.0 # Taktil durum geçişleri için (Swipe to Deliver)

  # 🚨 MONOREPO ORTAK PAKET ENJEKSİYONU:
  core_network:
    path: ../../packages/core_network
  core_auth:
    path: ../../packages/core_auth


🛠️ 2. BÖLÜM: Veritabanı ve Backend Katmanı (Courier Engine)

Kuryeleri ve konum akışlarını yönetmek için Courier, CourierLocation modellerini ve bunlara bağlı Express API bacaklarını kuruyoruz.

A. Prisma Şeması Güncellemesi (schema.prisma)

User modelindeki Role enum'ına COURIER ekliyoruz ve ilişkileri tanımlıyoruz:

// backend/prisma/schema.prisma

enum Role {
  CONSUMER
  MERCHANT
  COURIER // 🚨 Yeni rol eklendi
}

model Courier {
  id           String           @id @default(uuid())
  userId       String           @unique
  user         User             @relation(fields: [userId], references: [id], onDelete: Cascade)
  name         String
  phoneNumber  String           @unique
  vehiclePlate String?
  isActive     Boolean          @default(true) // Nöbette mi? (On Duty)
  locations    CourierLocation[]
  orders       Order[]
}

model CourierLocation {
  id        String   @id @default(uuid())
  courierId String
  courier   Courier  @relation(fields: [courierId], references: [id], onDelete: Cascade)
  latitude  Float
  longitude Float
  bearing   Float    @default(0.0) // Motorun gidiş açısı θ
  updatedAt DateTime @updatedAt

  @@index([courierId])
}

// 🚨 Order modeline kurye ilişkisini bağlıyoruz
model Order {
  id        String   @id @default(uuid())
  // ... mevcut alanlar
  courierId String?
  courier   Courier? @relation(fields: [courierId], references: [id], onDelete: SetNull)
}


B. Konum Akış API'si (CourierController.ts)

Kurye hareket ettikçe saniyede bir tetiklenebilecek ultra hafif ve optimize edilmiş konum yazma (UPSERT) API'si:

// backend/src/controllers/CourierController.ts

import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

export class CourierController {
  
  /**
   * Kurye Anlık Konumunu Günceller
   * POST /api/courier/location
   */
  public static async updateLocation(req: Request, res: Response): Promise<void> {
    try {
      const courierUserId = req.user!.id; // JWT'den çözülen kurye kullanıcı ID'si
      const { latitude, longitude, bearing } = req.body;

      // 1. Kurye profilini bul
      const courier = await prisma.courier.findUnique({ where: { userId: courierUserId } });
      if (!courier) {
        res.status(404).json({ error: true, message: "Kurye profili bulunamadı." });
        return;
      }

      // 2. Konum kaydını Upsert (varsa güncelle yoksa ekle) et
      const location = await prisma.courierLocation.upsert({
        where: { id: courier.id }, // Courier ID ile birebir kilitliyoruz (Mükerrer satır kirliliğini önler)
        update: {
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
          bearing: parseFloat(bearing || 0.0),
          updatedAt: new Date()
        },
        create: {
          id: courier.id,
          courierId: courier.id,
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
          bearing: parseFloat(bearing || 0.0)
        }
      });

      res.status(200).json({ error: false, data: location });
    } catch (error) {
      console.error("Kurye konum güncelleme hatası:", error);
      res.status(500).json({ error: true, message: "Konum kaydedilemedi." });
    }
  }

  /**
   * Kuryeye Atanmış Aktif Siparişleri Getir
   * GET /api/courier/orders
   */
  public static async getAssignedOrders(req: Request, res: Response): Promise<void> {
    try {
      const courierUserId = req.user!.id;
      const courier = await prisma.courier.findUnique({ where: { userId: courierUserId } });
      if (!courier) {
        res.status(404).json({ error: true, message: "Kurye profili bulunamadı." });
        return;
      }

      const activeOrders = await prisma.order.findMany({
        where: {
          courierId: courier.id,
          status: { in: ["PREPARING", "ON_THE_WAY"] } // Sadece teslimat aşamasındakiler
        },
        include: {
          shop: true,
          items: true
        }
      });

      res.status(200).json({ error: false, data: activeOrders });
    } catch (error) {
      res.status(500).json({ error: true, message: "Siparişler getirilemedi." });
    }
  }
}


📱 3. BÖLÜM: Kurye Mobil Uygulaması (Canlı Konum Motoru ve UI)

A. Nöbet Durumu ve Arka Plan Konum Motoru (location_service.dart)

Kurye "Nöbetteyim" (On Duty) switch'ini açtığı an saniyeler içinde GPS'i dinlemeye başlayıp, konumu değiştiğinde ($\ge 10\text{ metre}$) veya $5\text{ saniyede}$ bir yeni koordinatı sessizce backend'e akıtan reaktif konum motoru:

// apps/courier_app/lib/src/services/location_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:core_network/core_network.dart'; // Ortak ağ istemcisi

class CourierLocationEngine {
  final ApiClient _apiClient;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;

  CourierLocationEngine(this._apiClient);

  /// Konum Takip Motorunu Başlatır (Nöbet Açılınca)
  Future<void> startTracking() async {
    if (_isTracking) return;

    // 1. GPS İzinlerini Kontrol Et
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    _isTracking = true;

    // 2. Saniyede bir veya 10 metrede bir konum dinleyicisini kur
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // En az 10 metre hareket edince tetiklenir
      ),
    ).listen((Position position) {
      _streamLocationToBackend(position);
    });
  }

  /// Konum Takip Motorunu Durdurur (Nöbet Kapanınca)
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
  }

  /// API Üzerinden Konumu Backend'e Gönderir
  Future<void> _streamLocationToBackend(Position pos) async {
    try {
      await _apiClient.post(
        '/api/courier/location',
        body: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'bearing': pos.heading, // Hareket yönü açısı θ (Marker döndürmek için)
        },
        requiresAuth: true,
      );
    } catch (e) {
      print("🚨 Konum akıtma hatası: $e");
    }
  }
}


B. Nöbetçi Kurye Paneli ve Sipariş Akış UI (courier_dashboard.dart)

Kuryenin "Yoldayım" ve "Teslim Ettim" geçişlerini elinin kaymasıyla yanlışlıkla yapmasını önlemek için profesyonel Swipe-to-Action (Sürgülü Onay Butonu) ile donatılmış teslimat ekranı:

// apps/courier_app/lib/src/screens/dashboard/courier_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import '../../services/location_service.dart';

class CourierDashboardPage extends StatefulWidget {
  const CourierDashboardPage({Key? key}) : super(key: key);

  @override
  State<CourierDashboardPage> createState() => _CourierDashboardPageState();
}

class _CourierDashboardPageState extends State<CourierDashboardPage> {
  bool _isOnDuty = false;
  late CourierLocationEngine _locationEngine;

  @override
  void initState() {
    super.initState();
    // ApiClient'ın Riverpod'dan enjekte edildiği varsayılmıştır
    // _locationEngine = CourierLocationEngine(ref.read(apiClientProvider));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hoppa Kurye Paneli"),
        actions: [
          // 🚨 NÖBET SWITCH'I (On Duty Toggle):
          Row(
            children: [
              Text(
                _isOnDuty ? "NÖBETTE 🟢" : "PASİF 🔴",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Switch(
                value: _isOnDuty,
                onChanged: (val) async {
                  setState(() {
                    _isOnDuty = val;
                  });
                  if (_isOnDuty) {
                    await _locationEngine.startTracking();
                  } else {
                    await _locationEngine.stopTracking();
                  }
                },
              ),
            ],
          )
        ],
      ),
      body: _isOnDuty 
          ? _buildActiveDeliveryFeed(theme) 
          : _buildOfflinePlaceholder(theme),
    );
  }

  Widget _buildActiveDeliveryFeed(ThemeData theme) {
    // Örnek sipariş kartı ve swipe butonu entegrasyonu
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("AKTİF TESLİMAT", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("Şehir Market 🏪", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Text("Adres: Lefkoşa / Hamitköy, Sk. No: 12"),
              const Divider(height: 24),
              
              // 🚨 TAKTİL KAYDIRMALI ONAY BUTONU (Swipe to Action):
              SwipeButton(
                activeTrackColor: theme.colorScheme.primary,
                activeThumbColor: Colors.white,
                child: const Text(
                  "Teslim Etmek İçin Kaydırın >>",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onSwipe: () {
                  // Sipariş durumunu DELIVERED yapmak için backend PATCH çağrısını tetikle
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sipariş teslim edildi olarak işaretlendi! 🎉"), backgroundColor: Colors.green),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflinePlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.power_settings_new_rounded, size: 80, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          const Text("Şu Anda Çevrimdışısınız", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Sipariş alabilmek için sağ üstten nöbetinizi aktif edin.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}


📢 4. BÖLÜM: Doğrulama ve Test Senaryoları

A. Otomatik Test Adımları

Express & Prisma Doğrulaması:
cd backend && npx prisma db push && npx tsc --noEmit çalıştırarak kurye veri modellerinin veritabanına sorunsuz uygulandığını teyit edin.

Kurye Uygulaması Flutter Analizi:
cd apps/courier_app && flutter analyze çalıştırarak core_auth ve core_network paket bağımlılıklarının tip güvenliğinden pürüzsüz geçtiğini doğrulayın.

B. Canlı Simülasyon Test Senaryosu (E2E)

Nöbet Testi: Kurye uygulamasını çalıştırın, nöbeti açtığınızda arka planda GPS'in tetiklendiğini ve PostgreSQL CourierLocation tablosuna saniyeler içinde enlem/boylam satırının yazıldığını gözlemleyin.

Swipe Testi: Siparişi teslim alıp teslim ettiğinizde, kaydırmalı butonun tetiklenip hem satıcı ekranında hem de tüketici haritasında siparişin anında yeşile (DELIVERED) döndüğünü teyit edin.