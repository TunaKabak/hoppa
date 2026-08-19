# KKTC (Northern Cyprus) polygon definition and test

KKTC_POLYGON = [
    # Erenköy Enclave & Yeşilırmak / West Coast
    {"lat": 35.185, "lng": 32.650},
    {"lat": 35.195, "lng": 32.690},
    {"lat": 35.180, "lng": 32.740},
    {"lat": 35.160, "lng": 32.790},
    {"lat": 35.165, "lng": 32.840},
    {"lat": 35.210, "lng": 32.900},
    # Morphou Bay / Koruçam (Cape Kormakitis)
    {"lat": 35.340, "lng": 32.920},
    {"lat": 35.410, "lng": 32.915},
    {"lat": 35.420, "lng": 32.960},
    # North Coast (Girne / Kyrenia Range)
    {"lat": 35.370, "lng": 33.100},
    {"lat": 35.360, "lng": 33.300},
    {"lat": 35.355, "lng": 33.500},
    {"lat": 35.365, "lng": 33.700},
    {"lat": 35.410, "lng": 33.880},
    {"lat": 35.470, "lng": 34.050},
    # Karpaz Peninsula North Coast
    {"lat": 35.530, "lng": 34.200},
    {"lat": 35.600, "lng": 34.380},
    {"lat": 35.670, "lng": 34.520},
    {"lat": 35.710, "lng": 34.615}, # Zafer Burnu (Cape Apostolos Andreas)
    # Karpaz Peninsula South Coast
    {"lat": 35.660, "lng": 34.580},
    {"lat": 35.570, "lng": 34.420},
    {"lat": 35.470, "lng": 34.250},
    {"lat": 35.370, "lng": 34.080},
    # Famagusta Bay & Coast
    {"lat": 35.300, "lng": 33.940},
    {"lat": 35.190, "lng": 33.920},
    {"lat": 35.120, "lng": 33.960},
    {"lat": 35.095, "lng": 33.975}, # Derinya / Maraş South Border
    # Green Line (Buffer Zone) - East to West
    {"lat": 35.070, "lng": 33.910}, # Düzce / Güvercinlik
    {"lat": 35.045, "lng": 33.800}, # Beyarmudu / SBA Border
    {"lat": 35.035, "lng": 33.700}, # Pergamos
    {"lat": 35.040, "lng": 33.580}, # Paşaköy / Pile area
    {"lat": 34.995, "lng": 33.480}, # Louroujina / Akıncılar salient
    {"lat": 35.010, "lng": 33.440}, # Akıncılar West
    {"lat": 35.080, "lng": 33.420}, # Ercan South / Kırklar
    {"lat": 35.155, "lng": 33.375}, # Nicosia East (Haspolat)
    {"lat": 35.172, "lng": 33.360}, # Nicosia Old City Center Green Line
    {"lat": 35.178, "lng": 33.330}, # Nicosia West (Metehan / Ayios Dometios border)
    {"lat": 35.175, "lng": 33.220}, # Alayköy / Gürpınar
    {"lat": 35.160, "lng": 33.100}, # Serhatköy / Zümrütköy
    {"lat": 35.145, "lng": 32.950}, # Bostancı South border
    {"lat": 35.090, "lng": 32.850}, # Lefke / Bağlıköy South border
    {"lat": 35.075, "lng": 32.800}, # Bademliköy South
    {"lat": 35.130, "lng": 32.740}, # Yeşilırmak South border
    {"lat": 35.170, "lng": 32.670}, # Erenköy South
]

def is_point_in_polygon(lat, lng, polygon):
    inside = False
    n = len(polygon)
    j = n - 1
    for i in range(n):
        xi, yi = polygon[i]["lat"], polygon[i]["lng"]
        xj, yj = polygon[j]["lat"], polygon[j]["lng"]
        intersect = ((yi > lng) != (yj > lng)) and (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi)
        if intersect:
            inside = not inside
        j = i
    return inside

# Test KKTC Locations (MUST BE TRUE)
kktc_tests = [
    ("Lefkoşa (Center)", 35.1856, 33.3823),
    ("Gönyeli", 35.2100, 33.3100),
    ("Girne", 35.3364, 33.3184),
    ("Alsancak", 35.3450, 33.2200),
    ("Lapta", 35.3400, 33.1600),
    ("Çatalköy", 35.3300, 33.4000),
    ("Esentepe", 35.3400, 33.5800),
    ("Tatlısu", 35.3700, 33.7600),
    ("Gazimağusa", 35.1250, 33.9400),
    ("İskele", 35.2850, 33.8900),
    ("Boğaz", 35.3100, 33.9500),
    ("Bafra", 35.3600, 34.0900),
    ("Dipkarpaz", 35.5900, 34.3800),
    ("Güzelyurt", 35.1980, 32.9900),
    ("Lefke", 35.1100, 32.8400),
    ("Gemikonağı", 35.1400, 32.8500),
    ("Ercan Havalimanı", 35.1500, 33.5000),
    ("Geçitkale", 35.2400, 33.7200),
    ("Yeşilırmak", 35.1700, 32.7400),
]

# Test Non-KKTC Locations (MUST BE FALSE)
outside_tests = [
    ("Larnaca (South Cyprus)", 34.9100, 33.6200),
    ("Limassol (South Cyprus)", 34.7000, 33.0400),
    ("Paphos (South Cyprus)", 34.7700, 32.4200),
    ("Ayia Napa (South Cyprus)", 34.9800, 34.0000),
    ("Ankara (Turkey)", 39.9334, 32.8597),
    ("London (UK)", 51.5074, -0.1278),
    ("Open Sea North", 35.8500, 33.5000),
    ("Open Sea South", 34.5000, 33.5000),
]

print("=== KKTC TESTS ===")
all_pass = True
for name, lat, lng in kktc_tests:
    res = is_point_in_polygon(lat, lng, KKTC_POLYGON)
    print(f"{name} ({lat}, {lng}): {'PASS (Inside)' if res else 'FAIL (Outside)'}")
    if not res:
        all_pass = False

print("\n=== OUTSIDE TESTS ===")
for name, lat, lng in outside_tests:
    res = is_point_in_polygon(lat, lng, KKTC_POLYGON)
    print(f"{name} ({lat}, {lng}): {'PASS (Outside)' if not res else 'FAIL (Inside)'}")
    if res:
        all_pass = False

print(f"\nOverall Result: {'ALL PASSED' if all_pass else 'SOME FAILED'}")
