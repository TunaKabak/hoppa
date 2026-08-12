import React, { useEffect, useRef, useState } from 'react';
import { MapPin, Navigation, Compass, Search, Loader2, X } from 'lucide-react';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

interface LocationRadiusPickerMapProps {
  latitude: number;
  longitude: number;
  radiusKm: number;
  onLocationChange: (lat: number, lng: number) => void;
  onRadiusChange: (radiusKm: number) => void;
}

export default function LocationRadiusPickerMap({
  latitude,
  longitude,
  radiusKm,
  onLocationChange,
  onRadiusChange,
}: LocationRadiusPickerMapProps) {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);
  const markerInstanceRef = useRef<any>(null);
  const circleInstanceRef = useRef<any>(null);

  // Address Search & Dropdown State
  const [searchQuery, setSearchQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [showDropdown, setShowDropdown] = useState(false);

  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Default Cyprus Coordinates (Lefkoşa)
  const defaultLat = latitude || 35.1856;
  const defaultLng = longitude || 33.3823;

  useEffect(() => {
    if (typeof window === 'undefined') return;

    // Load Leaflet CSS
    if (!document.getElementById('leaflet-css')) {
      const link = document.createElement('link');
      link.id = 'leaflet-css';
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      document.head.appendChild(link);
    }

    // Load Leaflet JS
    if (!(window as any).L) {
      const script = document.createElement('script');
      script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      script.onload = () => initMap();
      document.head.appendChild(script);
    } else {
      initMap();
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  const initMap = () => {
    const L = (window as any).L;
    if (!L || !mapContainerRef.current || mapInstanceRef.current) return;

    const map = L.map(mapContainerRef.current, {
      center: [defaultLat, defaultLng],
      zoom: 13,
      scrollWheelZoom: true,
    });

    const tileUrl = isDark 
      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' 
      : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

    L.tileLayer(tileUrl, {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(map);

    // Official Hoppa Logo Custom Map Pin Marker
    const customHoppaIcon = L.divIcon({
      className: 'custom-hoppa-logo-pin',
      html: `
        <div style="
          position: relative;
          width: 44px;
          height: 44px;
          background: #FF6B00;
          border-radius: 50% 50% 50% 0;
          transform: rotate(-45deg);
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 12px 28px rgba(255, 107, 0, 0.45);
          border: 3px solid #ffffff;
        ">
          <img src="/logo-square-orange.png" style="
            width: 26px;
            height: 26px;
            border-radius: 50%;
            transform: rotate(45deg);
            object-fit: cover;
          " />
        </div>
      `,
      iconSize: [44, 44],
      iconAnchor: [22, 44],
    });

    const marker = L.marker([defaultLat, defaultLng], {
      draggable: true,
      icon: customHoppaIcon,
    }).addTo(map);

    const circle = L.circle([defaultLat, defaultLng], {
      color: '#FF6B00',
      fillColor: '#FF6B00',
      fillOpacity: 0.15,
      radius: radiusKm * 1000,
    }).addTo(map);

    marker.on('dragend', () => {
      const pos = marker.getLatLng();
      onLocationChange(pos.lat, pos.lng);
      circle.setLatLng(pos);
    });

    map.on('click', (e: any) => {
      const { lat, lng } = e.latlng;
      marker.setLatLng([lat, lng]);
      circle.setLatLng([lat, lng]);
      onLocationChange(lat, lng);
    });

    mapInstanceRef.current = map;
    markerInstanceRef.current = marker;
    circleInstanceRef.current = circle;
  };

  useEffect(() => {
    if (!mapInstanceRef.current) return;
    const L = (window as any).L;
    if (!L) return;

    if (latitude && longitude && markerInstanceRef.current) {
      markerInstanceRef.current.setLatLng([latitude, longitude]);
      circleInstanceRef.current.setLatLng([latitude, longitude]);
    }

    if (circleInstanceRef.current) {
      circleInstanceRef.current.setRadius(radiusKm * 1000);
    }
  }, [latitude, longitude, radiusKm]);

  // Live Auto-suggest Debounced Search as user types
  const handleQueryChange = (text: string) => {
    setSearchQuery(text);
    if (!text.trim()) {
      setSearchResults([]);
      setShowDropdown(false);
      return;
    }

    if (searchTimeoutRef.current) {
      clearTimeout(searchTimeoutRef.current);
    }

    setIsSearching(true);
    searchTimeoutRef.current = setTimeout(async () => {
      try {
        const query = text.toLowerCase().includes('kıbrıs') || text.toLowerCase().includes('cyprus') 
          ? text 
          : `${text}, Cyprus`;

        const response = await fetch(
          `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=5`
        );
        const data = await response.json();

        if (data && Array.isArray(data)) {
          setSearchResults(data);
          setShowDropdown(data.length > 0);
        }
      } catch (err) {
        console.error('Konum arama hatası:', err);
      } finally {
        setIsSearching(false);
      }
    }, 300);
  };

  const selectSearchResult = (item: any) => {
    const lat = parseFloat(item.lat);
    const lng = parseFloat(item.lon);

    if (mapInstanceRef.current) {
      mapInstanceRef.current.flyTo([lat, lng], 16);
    }
    if (markerInstanceRef.current) {
      markerInstanceRef.current.setLatLng([lat, lng]);
    }
    if (circleInstanceRef.current) {
      circleInstanceRef.current.setLatLng([lat, lng]);
    }
    onLocationChange(lat, lng);
    setSearchQuery(item.display_name.split(',')[0]);
    setShowDropdown(false);
  };

  // Browser Geolocation
  const handleGetCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const lat = pos.coords.latitude;
          const lng = pos.coords.longitude;
          onLocationChange(lat, lng);

          if (mapInstanceRef.current) {
            mapInstanceRef.current.flyTo([lat, lng], 15);
          }
        },
        (err) => {
          alert('Mevcut konumunuz alınamadı: ' + err.message);
        }
      );
    } else {
      alert('Tarayıcınız konum servislerini desteklemiyor.');
    }
  };

  return (
    <div className="space-y-4 font-sans">
      {/* Top Address Search & GPS Toolbar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
        {/* Relative Container for Floating Auto-suggest Dropdown */}
        <div className="relative flex-1">
          <div className="relative">
            <Search className="absolute left-3.5 top-3 w-4 h-4 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => handleQueryChange(e.target.value)}
              onFocus={() => {
                if (searchResults.length > 0) setShowDropdown(true);
              }}
              placeholder="Haritada adres/şehir ara... (Yazdıkça canlı öneriler çıkar)"
              className={`w-full border rounded-xl py-2.5 pl-10 pr-9 text-xs font-semibold outline-none focus:border-[#FF6B00] transition-colors ${
                isDark ? 'bg-slate-950 border-slate-800 text-white placeholder-slate-500' : 'bg-slate-50 border-slate-200 text-slate-900 placeholder-slate-400'
              }`}
            />
            {isSearching ? (
              <Loader2 className="absolute right-3 top-3 w-4 h-4 animate-spin text-[#FF6B00]" />
            ) : searchQuery ? (
              <button
                type="button"
                onClick={() => {
                  setSearchQuery('');
                  setSearchResults([]);
                  setShowDropdown(false);
                }}
                className="absolute right-3 top-3 text-slate-400 hover:text-slate-600"
              >
                <X className="w-4 h-4" />
              </button>
            ) : null}
          </div>

          {/* ABSOLUTE FLOATING DROPDOWN MENU (Öneriler Alan Kaplamadan Üstte Açar) */}
          {showDropdown && searchResults.length > 0 && (
            <div className={`absolute top-full left-0 right-0 z-50 mt-1.5 p-2 border rounded-2xl shadow-2xl backdrop-blur-xl max-h-60 overflow-y-auto space-y-1 transition-all ${
              isDark ? 'bg-slate-900/95 border-slate-800 text-white' : 'bg-white/95 border-slate-200 text-slate-900'
            }`}>
              <div className="px-2 py-1 flex items-center justify-between text-[10px] font-bold text-slate-400 uppercase tracking-wider border-b border-slate-100 dark:border-slate-800 mb-1">
                <span>Konum Önerileri</span>
                <span>{searchResults.length} sonuç</span>
              </div>
              {searchResults.map((res: any, idx: number) => (
                <button
                  key={idx}
                  type="button"
                  onClick={() => selectSearchResult(res)}
                  className="w-full text-left p-2.5 rounded-xl text-xs font-semibold hover:bg-[#FF6B00]/10 hover:text-[#FF6B00] flex items-start gap-2.5 transition-colors group"
                >
                  <div className="w-6 h-6 rounded-lg bg-[#FF6B00]/15 text-[#FF6B00] flex items-center justify-center shrink-0 mt-0.5 group-hover:bg-[#FF6B00] group-hover:text-white transition-colors">
                    <MapPin className="w-3.5 h-3.5" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-bold truncate">{res.display_name.split(',')[0]}</p>
                    <p className="text-[11px] text-slate-400 truncate">{res.display_name}</p>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* GPS Locator Button */}
        <button
          type="button"
          onClick={handleGetCurrentLocation}
          className="px-4 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-xs font-bold flex items-center gap-2 transition-all shrink-0"
        >
          <Navigation className="w-4 h-4 text-[#FF6B00]" />
          <span>GPS İle Konumumu Bul</span>
        </button>
      </div>

      {/* Map Container Canvas */}
      <div className="relative rounded-3xl overflow-hidden border border-slate-200 dark:border-slate-800 shadow-md">
        <div ref={mapContainerRef} className="w-full h-96 z-10" />

        {/* Floating Delivery Radius Indicator */}
        <div className="absolute top-3 right-3 z-20 bg-white/90 dark:bg-slate-900/90 backdrop-blur-md px-3.5 py-2 rounded-2xl border border-slate-200 dark:border-slate-800 text-xs font-black shadow-lg flex items-center gap-2">
          <Compass className="w-4 h-4 text-[#FF6B00]" />
          <span>Teslimat Yarıçapı: <span className="text-[#FF6B00]">{radiusKm} KM</span></span>
        </div>
      </div>

      {/* Interactive Delivery Radius Slider */}
      <div className={`p-4 rounded-2xl border transition-colors ${
        isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
      }`}>
        <div className="flex justify-between items-center mb-2">
          <label className="block text-xs font-bold text-slate-400 uppercase">
            Teslimat Yarıçapı Çemberi (1 - 25 KM)
          </label>
          <span className="text-sm font-black text-[#FF6B00]">{radiusKm} KM</span>
        </div>
        <input
          type="range"
          min="1"
          max="25"
          step="0.5"
          value={radiusKm}
          onChange={(e) => onRadiusChange(Number(e.target.value))}
          className="w-full accent-[#FF6B00] cursor-pointer"
        />
      </div>
    </div>
  );
}
