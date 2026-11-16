import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:core_network/core_network.dart';

class LocationPermissionException implements Exception {
  final String message;
  final bool openAppSettings;
  final bool openLocationSettings;

  const LocationPermissionException(
    this.message, {
    this.openAppSettings = false,
    this.openLocationSettings = false,
  });

  @override
  String toString() => message;
}

class CourierLocationEngine {
  final ApiClient _apiClient;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;
  final ValueNotifier<Position?> latestPosition = ValueNotifier<Position?>(
    null,
  );

  CourierLocationEngine(this._apiClient);

  bool get isTracking => _isTracking;

  /// Konum Takip Motorunu Başlatır (Nöbet Açılınca)
  Future<void> startTracking() async {
    if (_isTracking) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationPermissionException(
        'Konum servisi (GPS) kapalı. Lütfen cihaz konumunu açın.',
        openLocationSettings: true,
      );
    }

    // 1. GPS İzinlerini Kontrol Et
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        throw const LocationPermissionException(
          'Konum izni reddedildi. Canlı takip için izin vermeniz gerekir.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever');
      throw const LocationPermissionException(
        'Konum izni kalıcı olarak engellendi. Ayarlardan konum izni verin.',
        openAppSettings: true,
      );
    }

    await _positionStreamSubscription?.cancel();
    _isTracking = true;

    try {
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
      if (!_isTracking) return;
      latestPosition.value = current;
      unawaited(_streamLocationToBackend(current));
    } catch (e) {
      debugPrint('⚠️ Anlık ilk konum alınamadı (son bilinen konum deneniyor): $e');
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && _isTracking) {
          latestPosition.value = lastKnown;
          unawaited(_streamLocationToBackend(lastKnown));
        }
      } catch (lastErr) {
        debugPrint('⚠️ Son bilinen konum alınamadı: $lastErr');
      }
    }

    if (!_isTracking) return;

    // 2. En az 10 metre hareket edildiğinde konum dinleyicisini tetikle
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 10,
          ),
        ).listen(
          (Position position) {
            latestPosition.value = position;
            unawaited(_streamLocationToBackend(position));
          },
          onError: (Object error) {
            debugPrint('🚨 GPS Stream Error: $error');
          },
        );
  }

  /// Konum Takip Motorunu Durdurur (Nöbet Kapanınca)
  Future<void> stopTracking() async {
    _isTracking = false;
    try {
      await _positionStreamSubscription?.cancel();
    } catch (e) {
      debugPrint('🚨 Konum dinleyicisi kapatılırken hata: $e');
    } finally {
      _positionStreamSubscription = null;
    }
  }

  void dispose() {
    unawaited(stopTracking());
    latestPosition.dispose();
  }

  /// API Üzerinden Konumu Backend'e Gönderir
  Future<void> _streamLocationToBackend(Position pos) async {
    if (!pos.latitude.isFinite || !pos.longitude.isFinite) {
      return;
    }
    final safeBearing =
        (pos.heading.isFinite && pos.heading >= 0) ? pos.heading : 0.0;
    try {
      await _apiClient.post(
        '/api/couriers/location',
        body: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'bearing': safeBearing,
        },
        requiresAuth: true,
      );
    } catch (e) {
      debugPrint('🚨 Konum akıtma hatası: $e');
    }
  }
}
