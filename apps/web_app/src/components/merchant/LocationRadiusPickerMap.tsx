import React, { useEffect, useRef, useState } from 'react';
import { MapPin, Navigation, Compass, Search, Loader2, X, Trash2, Shapes, Circle, AlertTriangle, ShieldCheck } from 'lucide-react';
import { useMerchantTheme } from '../../context/MerchantThemeContext';
import { isLocationInKktc, KKTC_DEFAULT_CENTER, KKTC_INVERTED_WORLD_MASK } from '../../utils/kktcBoundary';

export interface LocationPolygonPoint {
  lat: number;
  lng: number;
}

interface LocationRadiusPickerMapProps {
  latitude: number;
  longitude: number;
  radiusKm: number;
  isPolygonMode?: boolean;
  deliveryPolygon?: LocationPolygonPoint[];
  onLocationChange: (lat: number, lng: number) => void;
  onRadiusChange: (radiusKm: number) => void;
  onPolygonModeChange?: (isPolygon: boolean) => void;
  onPolygonChange?: (polygon: LocationPolygonPoint[]) => void;
}

export default function LocationRadiusPickerMap({
  latitude,
  longitude,
  radiusKm,
  isPolygonMode = false,
  deliveryPolygon = [],
  onLocationChange,
  onRadiusChange,
  onPolygonModeChange,
  onPolygonChange,
}: LocationRadiusPickerMapProps) {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);
  const markerInstanceRef = useRef<any>(null);
  const circleInstanceRef = useRef<any>(null);
  const polygonInstanceRef = useRef<any>(null);
  const maskLayerRef = useRef<any>(null);
  const vertexMarkersRef = useRef<any[]>([]);

  // Address Search & Dropdown State
  const [searchQuery, setSearchQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [showDropdown, setShowDropdown] = useState(false);
  const [kktcWarning, setKktcWarning] = useState<string | null>(null);

  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const warningTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  const showKktcWarning = (msg: string) => {
    setKktcWarning(msg);
    if (warningTimeoutRef.current) clearTimeout(warningTimeoutRef.current);
    warningTimeoutRef.current = setTimeout(() => {
      setKktcWarning(null);
    }, 5000);
  };

  // Validated Default Cyprus Coordinates (Lefkoşa)
  const initialLat = isLocationInKktc(latitude, longitude) ? latitude : KKTC_DEFAULT_CENTER.lat;
  const initialLng = isLocationInKktc(latitude, longitude) ? longitude : KKTC_DEFAULT_CENTER.lng;

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
      if (warningTimeoutRef.current) clearTimeout(warningTimeoutRef.current);
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  // ResizeObserver for fluid map sizing
  useEffect(() => {
    if (!mapContainerRef.current) return;
    const observer = new ResizeObserver(() => {
      mapInstanceRef.current?.invalidateSize();
    });
    observer.observe(mapContainerRef.current);

    const t1 = setTimeout(() => mapInstanceRef.current?.invalidateSize(), 100);
    const t2 = setTimeout(() => mapInstanceRef.current?.invalidateSize(), 400);

    return () => {
      observer.disconnect();
      clearTimeout(t1);
      clearTimeout(t2);
    };
  }, []);

  const initMap = () => {
    const L = (window as any).L;
    if (!L || !mapContainerRef.current || mapInstanceRef.current) return;

    const map = L.map(mapContainerRef.current, {
      center: [initialLat, initialLng],
      zoom: 13,
      minZoom: 9,
      maxZoom: 18,
      maxBounds: [
        [34.80, 32.10],
        [35.90, 34.80],
      ],
      maxBoundsViscosity: 0.8,
      scrollWheelZoom: true,
      zoomControl: false,
    });

    // Modern, bright, high-contrast CartoDB Voyager
    const tileUrl = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

    L.tileLayer(tileUrl, {
      attribution: '&copy; <a href="https://carto.com/">CARTO</a> &copy; OpenStreetMap',
      subdomains: 'abcd',
      maxZoom: 19,
    }).addTo(map);

    // Soft Inverted World Mask for KKTC
    const mask = L.polygon(KKTC_INVERTED_WORLD_MASK, {
      color: '#FF6B00',
      weight: 2,
      dashArray: '6, 6',
      fillColor: isDark ? '#0f172a' : '#1e293b',
      fillOpacity: isDark ? 0.25 : 0.18,
      interactive: false,
    }).addTo(map);
    maskLayerRef.current = mask;

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

    const marker = L.marker([initialLat, initialLng], {
      draggable: true,
      icon: customHoppaIcon,
    }).addTo(map);

    const circle = L.circle([initialLat, initialLng], {
      color: '#FF6B00',
      fillColor: '#FF6B00',
      fillOpacity: 0.15,
      radius: radiusKm * 1000,
    }).addTo(map);

    marker.on('dragend', () => {
      const pos = marker.getLatLng();
      if (!isLocationInKktc(pos.lat, pos.lng)) {
        showKktcWarning('⚠️ Yalnızca KKTC (Kuzey Kıbrıs Türk Cumhuriyeti) sınırları içerisinde konum seçebilirsiniz.');
        // Revert marker to previous valid location
        marker.setLatLng([latitude || initialLat, longitude || initialLng]);
        circle.setLatLng([latitude || initialLat, longitude || initialLng]);
        return;
      }
      setKktcWarning(null);
      onLocationChange(pos.lat, pos.lng);
      circle.setLatLng(pos);
    });

    map.on('click', (e: any) => {
      const { lat, lng } = e.latlng;
      if (!isLocationInKktc(lat, lng)) {
        showKktcWarning('⚠️ Seçilen konum KKTC sınırları dışındadır. Lütfen KKTC sınırları içerisine tıklayınız.');
        return;
      }
      setKktcWarning(null);

      // Ref value or latest state checked via callback
      if ((window as any)._isPolygonModeActive) {
        if (onPolygonChange) {
          const currentPoly = (window as any)._currentDeliveryPolygon || [];
          onPolygonChange([...currentPoly, { lat, lng }]);
        }
      } else {
        marker.setLatLng([lat, lng]);
        circle.setLatLng([lat, lng]);
        onLocationChange(lat, lng);
      }
    });

    mapInstanceRef.current = map;
    markerInstanceRef.current = marker;
    circleInstanceRef.current = circle;
  };

  // Keep global window refs updated for event handlers
  useEffect(() => {
    (window as any)._isPolygonModeActive = isPolygonMode;
    (window as any)._currentDeliveryPolygon = deliveryPolygon;
  }, [isPolygonMode, deliveryPolygon]);

  // Update map visual layers on state change
  useEffect(() => {
    if (!mapInstanceRef.current) return;
    const L = (window as any).L;
    if (!L) return;

    if (latitude && longitude && markerInstanceRef.current) {
      markerInstanceRef.current.setLatLng([latitude, longitude]);
      if (circleInstanceRef.current) circleInstanceRef.current.setLatLng([latitude, longitude]);
    }

    if (circleInstanceRef.current) {
      if (isPolygonMode) {
        circleInstanceRef.current.remove();
      } else {
        circleInstanceRef.current.addTo(mapInstanceRef.current);
        circleInstanceRef.current.setRadius(radiusKm * 1000);
      }
    }

    // Clear old polygon layer & vertex markers
    if (polygonInstanceRef.current) {
      polygonInstanceRef.current.remove();
      polygonInstanceRef.current = null;
    }
    vertexMarkersRef.current.forEach((m) => m.remove());
    vertexMarkersRef.current = [];

    // Render Polygon Mode Layer if active
    if (isPolygonMode && deliveryPolygon && deliveryPolygon.length > 0) {
      const latLngs = deliveryPolygon.map((pt) => [pt.lat, pt.lng]);
      const polygonLayer = L.polygon(latLngs, {
        color: '#3B82F6',
        fillColor: '#3B82F6',
        fillOpacity: 0.2,
        weight: 2,
      }).addTo(mapInstanceRef.current);
      polygonInstanceRef.current = polygonLayer;

      // Add vertex dot markers
      deliveryPolygon.forEach((pt, idx) => {
        const dot = L.circleMarker([pt.lat, pt.lng], {
          radius: 6,
          color: '#2563EB',
          fillColor: '#FFFFFF',
          fillOpacity: 1,
          weight: 2,
        }).addTo(mapInstanceRef.current);

        dot.on('click', (e: any) => {
          L.DomEvent.stopPropagation(e);
          if (onPolygonChange) {
            const updated = deliveryPolygon.filter((_, i) => i !== idx);
            onPolygonChange(updated);
          }
        });

        vertexMarkersRef.current.push(dot);
      });
    }
  }, [latitude, longitude, radiusKm, isPolygonMode, deliveryPolygon]);

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

    if (!isLocationInKktc(lat, lng)) {
      showKktcWarning('⚠️ Bu arama sonucu KKTC sınırları dışındadır. Lütfen KKTC içi bir adres seçiniz.');
      setShowDropdown(false);
      return;
    }
    setKktcWarning(null);

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
          if (!isLocationInKktc(lat, lng)) {
            showKktcWarning('⚠️ Mevcut cihaz konumunuz KKTC sınırları dışındadır. İşletme konumu yalnızca KKTC sınırları içerisinde seçilebilir.');
            return;
          }
          setKktcWarning(null);
          onLocationChange(lat, lng);

          if (mapInstanceRef.current) {
            mapInstanceRef.current.flyTo([lat, lng], 15);
          }
          if (markerInstanceRef.current) {
            markerInstanceRef.current.setLatLng([lat, lng]);
          }
          if (circleInstanceRef.current) {
            circleInstanceRef.current.setLatLng([lat, lng]);
          }
        },
        (err) => {
          showKktcWarning('Mevcut konumunuz alınamadı: ' + err.message);
        }
      );
    } else {
      showKktcWarning('Tarayıcınız konum servislerini desteklemiyor.');
    }
  };

  return (
    <div className="space-y-4 font-sans">
      {/* Mode Switcher: Radius vs Polygon Mode */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 rounded-2xl border bg-slate-50 dark:bg-slate-950 dark:border-slate-800">
        <div>
          <span className="text-xs font-black uppercase tracking-wider text-slate-400 block">
            Teslimat Bölgesi Modu
          </span>
          <p className="text-xs font-semibold text-slate-600 dark:text-slate-300 mt-0.5">
            {isPolygonMode 
              ? 'Özel Poligon Modu: Haritaya tıklayarak dükkanınızın teslimat sınır alanını belirleyin.' 
              : 'Dairesel Yarıçap Modu: Dükkanınız merkezli sabit kilometre teslimat yarıçapı.'}
          </p>
        </div>

        <div className="flex items-center gap-1.5 p-1 bg-slate-200 dark:bg-slate-900 rounded-xl shrink-0">
          <button
            type="button"
            onClick={() => onPolygonModeChange && onPolygonModeChange(false)}
            className={`px-4 py-2 rounded-lg text-xs font-extrabold flex items-center gap-2 transition-all ${
              !isPolygonMode 
                ? 'bg-white dark:bg-slate-800 text-[#FF6B00] shadow-sm' 
                : 'text-slate-500 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <Circle className="w-3.5 h-3.5" />
            <span>Yarıçap (KM)</span>
          </button>

          <button
            type="button"
            onClick={() => onPolygonModeChange && onPolygonModeChange(true)}
            className={`px-4 py-2 rounded-lg text-xs font-extrabold flex items-center gap-2 transition-all ${
              isPolygonMode 
                ? 'bg-white dark:bg-slate-800 text-blue-600 dark:text-blue-400 shadow-sm' 
                : 'text-slate-500 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <Shapes className="w-3.5 h-3.5" />
            <span>Özel Poligon</span>
          </button>
        </div>
      </div>

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
              placeholder="KKTC içinde adres/şehir ara... (Örn: Girne, Dereboyu)"
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

          {/* ABSOLUTE FLOATING DROPDOWN MENU */}
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
        <div ref={mapContainerRef} className="w-full h-96 z-10 cursor-crosshair" />

        {/* Floating KKTC Active Zone Badge */}
        <div className="absolute top-3 left-3 z-20 bg-slate-900/90 text-white backdrop-blur-md px-3 py-1.5 rounded-xl border border-slate-700 text-[11px] font-black shadow-lg flex items-center gap-2">
          <ShieldCheck className="w-3.5 h-3.5 text-[#00A651]" />
          <span>Aktif Hizmet Bölgesi: <span className="text-[#FF6B00]">KKTC</span></span>
        </div>

        {/* Floating Warning Message (if outside KKTC clicked) */}
        {kktcWarning && (
          <div className="absolute top-14 left-3 right-3 z-30 bg-rose-600 text-white text-xs font-extrabold p-3 rounded-xl shadow-2xl flex items-center gap-2 animate-bounce">
            <AlertTriangle className="w-4 h-4 shrink-0" />
            <span className="flex-1">{kktcWarning}</span>
            <button
              type="button"
              onClick={() => setKktcWarning(null)}
              className="p-1 rounded-lg hover:bg-white/20"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        )}

        {/* Floating Mode Indicator Badge */}
        {!isPolygonMode ? (
          <div className="absolute top-3 right-3 z-20 bg-white/90 dark:bg-slate-900/90 backdrop-blur-md px-3.5 py-2 rounded-2xl border border-slate-200 dark:border-slate-800 text-xs font-black shadow-lg flex items-center gap-2">
            <Compass className="w-4 h-4 text-[#FF6B00]" />
            <span>Teslimat Yarıçapı: <span className="text-[#FF6B00]">{radiusKm} KM</span></span>
          </div>
        ) : (
          <div className="absolute top-3 right-3 z-20 bg-blue-900/90 text-white backdrop-blur-md px-3.5 py-2 rounded-2xl border border-blue-700 text-xs font-black shadow-lg flex items-center gap-3">
            <Shapes className="w-4 h-4 text-blue-300" />
            <span>Poligon Köşe Sayısı: <span className="text-amber-300">{deliveryPolygon.length}</span></span>
            {deliveryPolygon.length > 0 && (
              <button
                type="button"
                onClick={() => onPolygonChange && onPolygonChange([])}
                className="px-2 py-0.5 rounded-lg bg-rose-600 hover:bg-rose-700 text-[11px] font-extrabold flex items-center gap-1 transition-all"
              >
                <Trash2 className="w-3 h-3" />
                <span>Temizle</span>
              </button>
            )}
          </div>
        )}
      </div>

      {/* Mode Controls */}
      {!isPolygonMode ? (
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
      ) : (
        <div className={`p-4 rounded-2xl border transition-colors ${
          isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
        }`}>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-extrabold text-blue-600 dark:text-blue-400 uppercase">
                Özel Poligon Bölge Noktaları
              </p>
              <p className="text-xs font-semibold text-slate-500 dark:text-slate-400 mt-0.5">
                Haritadaki herhangi bir yere tıklayarak poligon köşesi ekleyin. Bir noktayı kaldırmak için üzerine tıklayın.
              </p>
            </div>
            {deliveryPolygon.length > 0 && (
              <button
                type="button"
                onClick={() => onPolygonChange && onPolygonChange([])}
                className="px-3 py-1.5 rounded-xl bg-rose-500/10 hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 font-extrabold text-xs flex items-center gap-1.5 transition-all"
              >
                <Trash2 className="w-3.5 h-3.5" />
                <span>Tüm Noktaları Sil</span>
              </button>
            )}
          </div>

          {deliveryPolygon.length === 0 ? (
            <div className="mt-3 p-3 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-600 dark:text-amber-400 text-xs font-bold">
              ⚠️ Henüz poligon noktası eklenmedi. Teslimat alanınızı oluşturmak için haritada en az 3 nokta işaretleyin.
            </div>
          ) : deliveryPolygon.length < 3 ? (
            <div className="mt-3 p-3 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-600 dark:text-amber-400 text-xs font-bold">
              ⚠️ Geçerli bir bölge alanı için en az 3 köşe noktası gereklidir ({deliveryPolygon.length}/3 eklendi).
            </div>
          ) : (
            <div className="mt-3 p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-600 dark:text-emerald-400 text-xs font-bold flex items-center gap-2">
              <span>✓ Poligon alanı başarıyla tanımlandı ({deliveryPolygon.length} köşe noktası).</span>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
