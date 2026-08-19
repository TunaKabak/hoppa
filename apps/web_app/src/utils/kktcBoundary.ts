export interface LatLngPoint {
  lat: number;
  lng: number;
}

/**
 * KKTC (Kuzey Kıbrıs Türk Cumhuriyeti) Resmi Sınır Poligon Koordinatları
 */
export const KKTC_POLYGON: LatLngPoint[] = [
  // Erenköy Enclave & Yeşilırmak / Batı Sahili
  { lat: 35.190, lng: 32.640 },
  { lat: 35.200, lng: 32.690 },
  { lat: 35.185, lng: 32.740 },
  { lat: 35.160, lng: 32.780 },
  { lat: 35.155, lng: 32.840 },
  { lat: 35.210, lng: 32.900 },
  // Güzelyurt Körfezi / Koruçam (Cape Kormakitis)
  { lat: 35.340, lng: 32.910 },
  { lat: 35.415, lng: 32.910 },
  { lat: 35.430, lng: 32.960 },
  // Kuzey Sahili (Girne / Beşparmak Dağları Silsilesi)
  { lat: 35.380, lng: 33.100 },
  { lat: 35.370, lng: 33.300 },
  { lat: 35.365, lng: 33.500 },
  { lat: 35.375, lng: 33.700 },
  { lat: 35.420, lng: 33.880 },
  { lat: 35.480, lng: 34.050 },
  // Karpaz Yarımadası Kuzey Sahili
  { lat: 35.540, lng: 34.200 },
  { lat: 35.620, lng: 34.380 },
  { lat: 35.690, lng: 34.520 },
  { lat: 35.720, lng: 34.620 }, // Zafer Burnu (Cape Apostolos Andreas)
  // Karpaz Yarımadası Güney Sahili
  { lat: 35.670, lng: 34.590 },
  { lat: 35.580, lng: 34.430 },
  { lat: 35.460, lng: 34.240 },
  { lat: 35.340, lng: 34.120 }, // Bafra / Mehmetçik Sahili
  // Mağusa Körfezi & Sahili
  { lat: 35.280, lng: 33.960 }, // İskele Boğaz
  { lat: 35.190, lng: 33.930 }, // Yeniboğaziçi / Salamis
  { lat: 35.120, lng: 33.970 }, // Gazimağusa Limanı
  { lat: 35.095, lng: 33.980 }, // Derinya / Maraş Güney Sınırı
  // Yeşil Hat (Buffer Zone) - Doğudan Batıya
  { lat: 35.065, lng: 33.910 }, // Düzce / Güvercinlik
  { lat: 35.040, lng: 33.800 }, // Beyarmudu / SBA Sınırı
  { lat: 35.030, lng: 33.700 }, // Pergamos
  { lat: 35.035, lng: 33.580 }, // Paşaköy / Dilekkaya bölgesi
  { lat: 34.990, lng: 33.480 }, // Akıncılar (Louroujina) çıkıntısı
  { lat: 35.010, lng: 33.430 }, // Akıncılar Batısı
  { lat: 35.080, lng: 33.410 }, // Ercan Güneyi / Kırklar
  { lat: 35.150, lng: 33.375 }, // Lefkoşa Doğu (Haspolat)
  { lat: 35.168, lng: 33.360 }, // Lefkoşa Surlariçi Yeşil Hat Sınırı
  { lat: 35.174, lng: 33.325 }, // Lefkoşa Batı (Metehan Sınırı)
  { lat: 35.170, lng: 33.220 }, // Alayköy / Gürpınar
  { lat: 35.155, lng: 33.090 }, // Serhatköy / Zümrütköy
  { lat: 35.140, lng: 32.950 }, // Bostancı Güney Sınırı
  { lat: 35.085, lng: 32.845 }, // Lefke / Bağlıköy Güney Sınırı
  { lat: 35.070, lng: 32.795 }, // Bademliköy Güneyi
  { lat: 35.125, lng: 32.735 }, // Yeşilırmak Güney Sınırı
  { lat: 35.165, lng: 32.665 }, // Erenköy Güney Sınırı
];

/**
 * Koordinatın KKTC sınırları içerisinde olup olmadığını doğrular (Ray-Casting Algoritması)
 */
export function isLocationInKktc(lat: number, lng: number): boolean {
  if (typeof lat !== 'number' || typeof lng !== 'number' || isNaN(lat) || isNaN(lng)) {
    return false;
  }
  let inside = false;
  const n = KKTC_POLYGON.length;
  let j = n - 1;
  for (let i = 0; i < n; i++) {
    const xi = KKTC_POLYGON[i].lat;
    const yi = KKTC_POLYGON[i].lng;
    const xj = KKTC_POLYGON[j].lat;
    const yj = KKTC_POLYGON[j].lng;

    const intersect = ((yi > lng) !== (yj > lng)) && 
      (lat < ((xj - xi) * (lng - yi)) / (yj - yi) + xi);

    if (intersect) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

export const KKTC_DEFAULT_CENTER = { lat: 35.1856, lng: 33.3823 };

/**
 * Leaflet Inverted Mask Polygon coordinates:
 * Covers the entire world bounds with a hole for KKTC.
 */
export const KKTC_INVERTED_WORLD_MASK = [
  // Outer rectangle: whole world
  [
    [-90, -180],
    [-90, 180],
    [90, 180],
    [90, -180],
  ],
  // Inner hole: KKTC Polygon
  KKTC_POLYGON.map((p) => [p.lat, p.lng]),
];
