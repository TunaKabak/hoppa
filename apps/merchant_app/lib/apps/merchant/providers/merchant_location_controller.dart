import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:core_shared/shared/core/data/kktc_districts.dart';

class MerchantLocationResult {
  final String address;
  final String streetAddress;
  final String city;
  final String district;
  final double latitude;
  final double longitude;

  MerchantLocationResult({
    required this.address,
    required this.streetAddress,
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
  });
}

class MerchantLocationNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return null;
  }

  Future<MerchantLocationResult> determineLocation() async {
    state = const AsyncLoading();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Konum servisleri devre dışı.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Konum izni reddedildi.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Konum izinleri kalıcı olarak engellenmiş.");
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));

      if (placemarks.isEmpty) {
        throw Exception("Adres bilgisi çözümlenemedi.");
      }

      final place = placemarks.first;
      
      String streetAddress = '';
      String city = '';
      String district = '';

      // 1. Unnamed Road filtering and streetAddress formatting
      String streetField = place.street ?? '';
      String thoroughfareField = place.thoroughfare ?? '';

      if (streetField.toLowerCase().contains("unnamed road")) {
        streetField = "";
      }
      if (thoroughfareField.toLowerCase().contains("unnamed road")) {
        thoroughfareField = "";
      }

      // We prioritize thoroughfare/street if not unnamed road
      if (streetField.isNotEmpty) {
        streetAddress = streetField;
      } else if (thoroughfareField.isNotEmpty) {
        streetAddress = thoroughfareField;
      }

      // 2. City prioritization with mapping
      final kktcCities = ['Lefkoşa', 'Girne', 'Gazimağusa', 'İskele', 'Güzelyurt', 'Lefke'];
      final Map<String, String> cityMapping = {
        'nicosia': 'Lefkoşa',
        'lefkosia': 'Lefkoşa',
        'kyrenia': 'Girne',
        'keryneia': 'Girne',
        'famagusta': 'Gazimağusa',
        'gazimagusa': 'Gazimağusa',
        'magusa': 'Gazimağusa',
        'ammochostos': 'Gazimağusa',
        'iskele': 'İskele',
        'trikomo': 'İskele',
        'güzelyurt': 'Güzelyurt',
        'guzelyurt': 'Güzelyurt',
        'morphou': 'Güzelyurt',
        'lefke': 'Lefke',
        'lefka': 'Lefke',
      };
      
      String resolvedCity = '';
      for (final field in [place.locality, place.subAdministrativeArea, place.administrativeArea]) {
        if (field != null && field.isNotEmpty) {
          final valLower = field.toLowerCase();
          for (final entry in cityMapping.entries) {
            if (valLower.contains(entry.key) || entry.key.contains(valLower)) {
              resolvedCity = entry.value;
              break;
            }
          }
          if (resolvedCity.isEmpty) {
            for (final kc in kktcCities) {
              if (valLower.contains(kc.toLowerCase()) || kc.toLowerCase().contains(valLower)) {
                resolvedCity = kc;
                break;
              }
            }
          }
        }
        if (resolvedCity.isNotEmpty) break;
      }
      city = resolvedCity;

      // 3. District prioritization based on resolved city
      String resolvedDistrict = '';
      if (city.isNotEmpty) {
        final districts = kKktcDistricts[city] ?? [];
        for (final field in [place.subLocality, place.thoroughfare, place.street, place.name]) {
          if (field != null && field.isNotEmpty) {
            final fLower = field.toLowerCase();
            for (final d in districts) {
              if (fLower.contains(d.toLowerCase()) || d.toLowerCase().contains(fLower)) {
                resolvedDistrict = d;
                break;
              }
            }
          }
          if (resolvedDistrict.isNotEmpty) break;
        }
      }

      if (resolvedDistrict.isEmpty) {
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          resolvedDistrict = place.subLocality!;
        } else if (place.subAdministrativeArea != null && 
                   place.subAdministrativeArea!.isNotEmpty && 
                   resolvedCity.isNotEmpty &&
                   !place.subAdministrativeArea!.toLowerCase().contains(resolvedCity.toLowerCase())) {
          resolvedDistrict = place.subAdministrativeArea!;
        }
      }
      district = resolvedDistrict;

      // Fallbacks
      if (city.isEmpty && place.locality != null) {
        city = place.locality!;
      }
      if (district.isEmpty && place.subLocality != null) {
        district = place.subLocality!;
      }

      final combinedParts = [
        if (streetAddress.isNotEmpty) streetAddress,
        if (district.isNotEmpty) district,
        if (city.isNotEmpty) city,
      ];
      final address = combinedParts.isEmpty ? "Bilinmeyen Konum" : combinedParts.join(", ");
      
      state = AsyncData(address);
      return MerchantLocationResult(
        address: address,
        streetAddress: streetAddress,
        city: city,
        district: district,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }
}

final merchantLocationProvider = AsyncNotifierProvider<MerchantLocationNotifier, String?>(
  MerchantLocationNotifier.new,
);
