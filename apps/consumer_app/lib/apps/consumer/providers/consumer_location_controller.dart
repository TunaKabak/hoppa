import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ConsumerLocationResult {
  final String address;
  final String streetAddress;
  final String city;
  final String district;
  final double latitude;
  final double longitude;

  ConsumerLocationResult({
    required this.address,
    required this.streetAddress,
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
  });
}

class ConsumerLocationNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return null;
  }

  Future<ConsumerLocationResult> determineLocation() async {
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

      if (streetField.isNotEmpty) {
        streetAddress = streetField;
      } else if (thoroughfareField.isNotEmpty) {
        streetAddress = thoroughfareField;
      }

      // Prioritize City & District
      final kktcCities = ['Lefkoşa', 'Girne', 'Gazimağusa', 'İskele', 'Güzelyurt', 'Lefke'];
      
      String resolvedCity = '';
      for (final field in [place.locality, place.subAdministrativeArea, place.administrativeArea]) {
        if (field != null && field.isNotEmpty) {
          final fLower = field.toLowerCase();
          // Check standard names
          for (final kc in kktcCities) {
            if (fLower.contains(kc.toLowerCase()) || kc.toLowerCase().contains(fLower)) {
              resolvedCity = kc;
              break;
            }
          }
          if (resolvedCity.isNotEmpty) break;

          // English translations mapping for KKTC
          if (fLower.contains('nicosia')) {
            resolvedCity = 'Lefkoşa';
          } else if (fLower.contains('kyrenia')) {
            resolvedCity = 'Girne';
          } else if (fLower.contains('famagusta') || fLower.contains('magusa') || fLower.contains('gazimagusa')) {
            resolvedCity = 'Gazimağusa';
          } else if (fLower.contains('iskele') || fLower.contains('trikomo')) {
            resolvedCity = 'İskele';
          } else if (fLower.contains('guzelyurt') || fLower.contains('morphou')) {
            resolvedCity = 'Güzelyurt';
          } else if (fLower.contains('lefke')) {
            resolvedCity = 'Lefke';
          }
        }
        if (resolvedCity.isNotEmpty) break;
      }
      city = resolvedCity;

      String resolvedDistrict = '';
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        resolvedDistrict = place.subLocality!;
      } else if (place.subAdministrativeArea != null && 
                 place.subAdministrativeArea!.isNotEmpty && 
                 resolvedCity.isNotEmpty &&
                 !place.subAdministrativeArea!.toLowerCase().contains(resolvedCity.toLowerCase())) {
        resolvedDistrict = place.subAdministrativeArea!;
      }
      district = resolvedDistrict;

      // Fallbacks if unresolved
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
      return ConsumerLocationResult(
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

final consumerLocationProvider = AsyncNotifierProvider<ConsumerLocationNotifier, String?>(
  ConsumerLocationNotifier.new,
);
