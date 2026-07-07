import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:core_network/core_network.dart';

class CourierLocationEngine {
  final ApiClient _apiClient;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;

  CourierLocationEngine(this._apiClient);

  bool get isTracking => _isTracking;

  /// Konum Takip Motorunu Başlatır (Nöbet Açılınca)
  Future<void> startTracking() async {
    if (_isTracking) return;

    // 1. GPS İzinlerini Kontrol Et
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permission denied forever");
      return;
    }

    _isTracking = true;

    // 2. Saniyede bir veya 10 metrede bir konum dinleyicisini kur
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // En az 10 metre hareket edince tetiklenir
      ),
    ).listen(
      (Position position) {
        _streamLocationToBackend(position);
      },
      onError: (error) {
        debugPrint("🚨 GPS Stream Error: $error");
      },
    );
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
        '/api/couriers/location',
        body: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'bearing': pos.heading, // Hareket yönü açısı θ
        },
        requiresAuth: true,
      );
    } catch (e) {
      debugPrint("🚨 Konum akıtma hatası: $e");
    }
  }
}
