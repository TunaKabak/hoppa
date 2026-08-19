import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// KKTC (Kuzey Kıbrıs Türk Cumhuriyeti) Resmi Sınır Poligon Koordinatları
const List<LatLng> kKktcPolygon = [
  // Erenköy Enclave & Yeşilırmak / Batı Sahili
  LatLng(35.190, 32.640),
  LatLng(35.200, 32.690),
  LatLng(35.185, 32.740),
  LatLng(35.160, 32.780),
  LatLng(35.155, 32.840),
  LatLng(35.210, 32.900),
  // Güzelyurt Körfezi / Koruçam (Cape Kormakitis)
  LatLng(35.340, 32.910),
  LatLng(35.415, 32.910),
  LatLng(35.430, 32.960),
  // Kuzey Sahili (Girne / Beşparmak Dağları Silsilesi)
  LatLng(35.380, 33.100),
  LatLng(35.370, 33.300),
  LatLng(35.365, 33.500),
  LatLng(35.375, 33.700),
  LatLng(35.420, 33.880),
  LatLng(35.480, 34.050),
  // Karpaz Yarımadası Kuzey Sahili
  LatLng(35.540, 34.200),
  LatLng(35.620, 34.380),
  LatLng(35.690, 34.520),
  LatLng(35.720, 34.620), // Zafer Burnu (Cape Apostolos Andreas)
  // Karpaz Yarımadası Güney Sahili
  LatLng(35.670, 34.590),
  LatLng(35.580, 34.430),
  LatLng(35.460, 34.240),
  LatLng(35.340, 34.120), // Bafra / Mehmetçik Sahili
  // Mağusa Körfezi & Sahili
  LatLng(35.280, 33.960), // İskele Boğaz
  LatLng(35.190, 33.930), // Yeniboğaziçi / Salamis
  LatLng(35.120, 33.970), // Gazimağusa Limanı
  LatLng(35.095, 33.980), // Derinya / Maraş Güney Sınırı
  // Yeşil Hat (Buffer Zone) - Doğudan Batıya
  LatLng(35.065, 33.910), // Düzce / Güvercinlik
  LatLng(35.040, 33.800), // Beyarmudu / SBA Sınırı
  LatLng(35.030, 33.700), // Pergamos
  LatLng(35.035, 33.580), // Paşaköy / Dilekkaya bölgesi
  LatLng(34.990, 33.480), // Akıncılar (Louroujina) çıkıntısı
  LatLng(35.010, 33.430), // Akıncılar Batısı
  LatLng(35.080, 33.410), // Ercan Güneyi / Kırklar
  LatLng(35.150, 33.375), // Lefkoşa Doğu (Haspolat)
  LatLng(35.168, 33.360), // Lefkoşa Surlariçi Yeşil Hat Sınırı
  LatLng(35.174, 33.325), // Lefkoşa Batı (Metehan Sınırı)
  LatLng(35.170, 33.220), // Alayköy / Gürpınar
  LatLng(35.155, 33.090), // Serhatköy / Zümrütköy
  LatLng(35.140, 32.950), // Bostancı Güney Sınırı
  LatLng(35.085, 32.845), // Lefke / Bağlıköy Güney Sınırı
  LatLng(35.070, 32.795), // Bademliköy Güneyi
  LatLng(35.125, 32.735), // Yeşilırmak Güney Sınırı
  LatLng(35.165, 32.665), // Erenköy Güney Sınırı
];

/// Verilen koordinatın KKTC sınırları içerisinde olup olmadığını doğrular (Ray-Casting Algoritması)
bool isLocationInKktc(double latitude, double longitude) {
  bool inside = false;
  final int n = kKktcPolygon.length;
  int j = n - 1;
  for (int i = 0; i < n; i++) {
    final double xi = kKktcPolygon[i].latitude;
    final double yi = kKktcPolygon[i].longitude;
    final double xj = kKktcPolygon[j].latitude;
    final double yj = kKktcPolygon[j].longitude;

    final bool intersect = ((yi > longitude) != (yj > longitude)) &&
        (latitude < (xj - xi) * (longitude - yi) / (yj - yi) + xi);

    if (intersect) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

/// KKTC merkez koordinatı (Lefkoşa)
const LatLng kKktcDefaultCenter = LatLng(35.1856, 33.3823);

/// KKTC harita görünüm sınırları
final LatLngBounds kKktcMapBounds = LatLngBounds(
  const LatLng(34.80, 32.10),
  const LatLng(35.90, 34.80),
);

/// FlutterMap için KKTC dışındaki alanları karartıp pasif gösteren ters poligon (World Inverted Mask)
final List<LatLng> kWorldOuterBounds = [
  const LatLng(-90.0, -180.0),
  const LatLng(-90.0, 180.0),
  const LatLng(90.0, 180.0),
  const LatLng(90.0, -180.0),
];
