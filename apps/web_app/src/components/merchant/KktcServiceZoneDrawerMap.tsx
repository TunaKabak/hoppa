import React, { useEffect, useRef, useState, useCallback } from 'react';
import { 
  MapPin, Search, Loader2, Trash2, Shapes, CheckCircle2, 
  X, Layers, Compass, Plus, Undo2, MousePointerClick, 
  HelpCircle, Eye, EyeOff, Sparkles, Navigation, Maximize2, 
  Minimize2, ZoomIn, ZoomOut, Target, Crosshair
} from 'lucide-react';
import { useMerchantTheme } from '../../context/MerchantThemeContext';
import { isLocationInKktc, KKTC_DEFAULT_CENTER, KKTC_INVERTED_WORLD_MASK } from '../../utils/kktcBoundary';

export interface ServiceZonePoint {
  lat: number;
  lng: number;
}

export interface KktcServiceZone {
  id: string;
  name: string;
  district: string;
  polygon: ServiceZonePoint[];
  isActive: boolean;
  minOrderAmount: number;
  baseDeliveryFee: number;
  deliveryTime: string;
  colorHex: string;
  description?: string;
}

interface KktcServiceZoneDrawerMapProps {
  zones: KktcServiceZone[];
  activeZoneId: string | null;
  onSelectZone: (zoneId: string) => void;
  onUpdateZonePolygon: (zoneId: string, polygon: ServiceZonePoint[]) => void;
  isDrawingNew: boolean;
  newZoneDraftPolygon: ServiceZonePoint[];
  onUpdateNewZoneDraftPolygon: (polygon: ServiceZonePoint[]) => void;
  onFinishDrawingNew: () => void;
  onCancelDrawingNew: () => void;
  heightClass?: string;
}

const DISTRICT_CENTERS: Record<string, { lat: number; lng: number; zoom: number }> = {
  'KKTC Genel': { lat: 35.2500, lng: 33.5500, zoom: 10 },
  'Lefkoşa': { lat: 35.1856, lng: 33.3823, zoom: 13 },
  'Girne': { lat: 35.3364, lng: 33.3173, zoom: 13 },
  'Gazimağusa': { lat: 35.1250, lng: 33.9350, zoom: 13 },
  'Güzelyurt': { lat: 35.1983, lng: 32.9933, zoom: 13 },
  'İskele': { lat: 35.2869, lng: 33.8881, zoom: 13 },
  'Lefke': { lat: 35.1167, lng: 32.8500, zoom: 13 },
};

/**
 * Point-in-Polygon Check via Ray-Casting
 */
export function isPointInPolygon(point: ServiceZonePoint, vs: ServiceZonePoint[]): boolean {
  const x = point.lat;
  const y = point.lng;
  let inside = false;
  for (let i = 0, j = vs.length - 1; i < vs.length; j = i++) {
    const xi = vs[i].lat, yi = vs[i].lng;
    const xj = vs[j].lat, yj = vs[j].lng;
    const intersect = ((yi > y) !== (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

export default function KktcServiceZoneDrawerMap({
  zones,
  activeZoneId,
  onSelectZone,
  onUpdateZonePolygon,
  isDrawingNew,
  newZoneDraftPolygon,
  onUpdateNewZoneDraftPolygon,
  onFinishDrawingNew,
  onCancelDrawingNew,
  heightClass = 'h-[720px]',
}: KktcServiceZoneDrawerMapProps) {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);
  const zoneLayersRef = useRef<Map<string, any>>(new Map());
  const vertexMarkersRef = useRef<any[]>([]);
  const draftPolygonLayerRef = useRef<any>(null);
  const testMarkerRef = useRef<any>(null);

  // Address & Test Pin Drop State
  const [searchQuery, setSearchQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [showDropdown, setShowDropdown] = useState(false);
  const [testPoint, setTestPoint] = useState<ServiceZonePoint | null>(null);
  const [testResult, setTestResult] = useState<{ insideZones: string[]; isInsideKktc: boolean } | null>(null);
  const [isTestMode, setIsTestMode] = useState<boolean>(false);
  const [selectedDistrict, setSelectedDistrict] = useState<string>('KKTC Genel');
  const [isFullscreen, setIsFullscreen] = useState<boolean>(false);
  const [cursorCoords, setCursorCoords] = useState<{ lat: number; lng: number } | null>(null);
  const [zoomLevel, setZoomLevel] = useState<number>(10);

  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Initialize Leaflet Map
  useEffect(() => {
    if (typeof window === 'undefined') return;

    if (!document.getElementById('leaflet-css')) {
      const link = document.createElement('link');
      link.id = 'leaflet-css';
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      document.head.appendChild(link);
    }

    if (!(window as any).L) {
      const script = document.createElement('script');
      script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      script.onload = () => initMap();
      document.head.appendChild(script);
    } else {
      initMap();
    }

    return () => {
      if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current);
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
      center: [KKTC_DEFAULT_CENTER.lat, KKTC_DEFAULT_CENTER.lng],
      zoom: 10,
      minZoom: 8,
      maxZoom: 18,
      maxBounds: [
        [34.50, 31.80],
        [36.20, 35.10],
      ],
      maxBoundsViscosity: 0.8,
      scrollWheelZoom: true,
      zoomControl: false, // Custom styled zoom controls
    });

    const tileUrl = isDark 
      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' 
      : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

    L.tileLayer(tileUrl, {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(map);

    // Inverted World Mask for KKTC
    L.polygon(KKTC_INVERTED_WORLD_MASK, {
      color: '#FF6B00',
      weight: 1.5,
      dashArray: '5, 5',
      fillColor: isDark ? '#020617' : '#0f172a',
      fillOpacity: isDark ? 0.60 : 0.40,
      interactive: false,
    }).addTo(map);

    // Track Cursor & Zoom Level
    map.on('mousemove', (e: any) => {
      setCursorCoords({
        lat: Number(e.latlng.lat.toFixed(5)),
        lng: Number(e.latlng.lng.toFixed(5)),
      });
    });

    map.on('zoomend', () => {
      setZoomLevel(map.getZoom());
    });

    // Map Click Listener for Drawing
    map.on('click', (e: any) => {
      const { lat, lng } = e.latlng;
      const point = { lat: Number(lat.toFixed(5)), lng: Number(lng.toFixed(5)) };

      // 1. If Test Mode is active
      if ((window as any)._isTestModeActive) {
        handleTestLocation(point);
        return;
      }

      // 2. If Drawing New Zone
      if ((window as any)._isDrawingNewActive) {
        const currentDraft = (window as any)._newZoneDraftPolygon || [];
        onUpdateNewZoneDraftPolygon([...currentDraft, point]);
        return;
      }

      // 3. If an existing zone is active for editing
      const activeId = (window as any)._activeZoneId;
      if (activeId) {
        const zone = (window as any)._allZones?.find((z: any) => z.id === activeId);
        if (zone) {
          const updatedPolygon = [...(zone.polygon || []), point];
          onUpdateZonePolygon(activeId, updatedPolygon);
        }
      }
    });

    mapInstanceRef.current = map;
    renderAllPolygons();
  };

  // Resize listener when fullscreen or container size changes
  useEffect(() => {
    if (mapInstanceRef.current) {
      setTimeout(() => {
        mapInstanceRef.current?.invalidateSize();
      }, 150);
    }
  }, [isFullscreen, heightClass]);

  // Keep window global refs synced for Leaflet callbacks
  useEffect(() => {
    (window as any)._isTestModeActive = isTestMode;
    (window as any)._isDrawingNewActive = isDrawingNew;
    (window as any)._newZoneDraftPolygon = newZoneDraftPolygon;
    (window as any)._activeZoneId = activeZoneId;
    (window as any)._allZones = zones;
  }, [isTestMode, isDrawingNew, newZoneDraftPolygon, activeZoneId, zones]);

  // Render Polygons & Vertices
  const renderAllPolygons = useCallback(() => {
    const map = mapInstanceRef.current;
    const L = (window as any).L;
    if (!map || !L) return;

    // Clear old zone polygon layers
    zoneLayersRef.current.forEach((layer) => layer.remove());
    zoneLayersRef.current.clear();

    // Clear old vertex markers
    vertexMarkersRef.current.forEach((m) => m.remove());
    vertexMarkersRef.current = [];

    // Clear draft layer
    if (draftPolygonLayerRef.current) {
      draftPolygonLayerRef.current.remove();
      draftPolygonLayerRef.current = null;
    }

    // 1. Render all saved zones
    zones.forEach((zone) => {
      if (!zone.polygon || zone.polygon.length === 0) return;

      const isSelected = zone.id === activeZoneId;
      const latLngs = zone.polygon.map((p) => [p.lat, p.lng]);

      const polygonLayer = L.polygon(latLngs, {
        color: zone.colorHex || '#FF6B00',
        weight: isSelected ? 3.5 : 2,
        fillColor: zone.colorHex || '#FF6B00',
        fillOpacity: isSelected ? 0.38 : (zone.isActive ? 0.20 : 0.07),
        dashArray: zone.isActive ? undefined : '6, 6',
      }).addTo(map);

      // Tooltip label
      polygonLayer.bindTooltip(`
        <div style="font-family: inherit; font-weight: 800; font-size: 12px; padding: 2px 4px;">
          <span>${zone.name}</span>
          <span style="display: block; font-size: 10px; font-weight: 600; opacity: 0.85;">${zone.district} • ${zone.isActive ? 'Aktif' : 'Pasif'} • Min: ₺${zone.minOrderAmount}</span>
        </div>
      `, {
        permanent: false,
        direction: 'center',
        className: 'zone-map-tooltip',
      });

      polygonLayer.on('click', (e: any) => {
        L.DomEvent.stopPropagation(e);
        if (!isDrawingNew && !isTestMode) {
          onSelectZone(zone.id);
        }
      });

      zoneLayersRef.current.set(zone.id, polygonLayer);

      // If this zone is currently selected, add draggable vertices
      if (isSelected && !isDrawingNew) {
        zone.polygon.forEach((pt, idx) => {
          const vertexMarker = L.circleMarker([pt.lat, pt.lng], {
            radius: 7.5,
            color: '#FFFFFF',
            fillColor: zone.colorHex || '#FF6B00',
            fillOpacity: 1,
            weight: 3,
          }).addTo(map);

          // Click vertex to delete
          vertexMarker.on('click', (e: any) => {
            L.DomEvent.stopPropagation(e);
            const filtered = zone.polygon.filter((_, i) => i !== idx);
            onUpdateZonePolygon(zone.id, filtered);
          });

          vertexMarkersRef.current.push(vertexMarker);
        });
      }
    });

    // 2. Render Draft Polygon if Drawing New
    if (isDrawingNew && newZoneDraftPolygon && newZoneDraftPolygon.length > 0) {
      const draftLatLngs = newZoneDraftPolygon.map((p) => [p.lat, p.lng]);
      const draftLayer = L.polygon(draftLatLngs, {
        color: '#2563EB',
        weight: 3,
        fillColor: '#3B82F6',
        fillOpacity: 0.35,
        dashArray: '5, 5',
      }).addTo(map);
      draftPolygonLayerRef.current = draftLayer;

      // Add vertex dots for draft with index indicator
      newZoneDraftPolygon.forEach((pt, idx) => {
        const dot = L.circleMarker([pt.lat, pt.lng], {
          radius: 8,
          color: '#FFFFFF',
          fillColor: '#2563EB',
          fillOpacity: 1,
          weight: 3,
        }).addTo(map);

        dot.on('click', (e: any) => {
          L.DomEvent.stopPropagation(e);
          const filtered = newZoneDraftPolygon.filter((_, i) => i !== idx);
          onUpdateNewZoneDraftPolygon(filtered);
        });

        vertexMarkersRef.current.push(dot);
      });
    }
  }, [zones, activeZoneId, isDrawingNew, newZoneDraftPolygon, isTestMode, onSelectZone, onUpdateZonePolygon, onUpdateNewZoneDraftPolygon]);

  useEffect(() => {
    renderAllPolygons();
  }, [renderAllPolygons]);

  // Fit camera bounds to a polygon
  const handleFitZoneBounds = (polygon: ServiceZonePoint[]) => {
    if (!mapInstanceRef.current || !polygon || polygon.length === 0) return;
    const L = (window as any).L;
    if (!L) return;

    const bounds = L.latLngBounds(polygon.map((p) => [p.lat, p.lng]));
    mapInstanceRef.current.fitBounds(bounds, { padding: [60, 60], maxZoom: 15 });
  };

  // Undo Last Vertex
  const handleUndoLastVertex = () => {
    if (isDrawingNew) {
      if (newZoneDraftPolygon.length > 0) {
        onUpdateNewZoneDraftPolygon(newZoneDraftPolygon.slice(0, -1));
      }
    } else if (activeZoneId) {
      const currentZone = zones.find((z) => z.id === activeZoneId);
      if (currentZone && currentZone.polygon && currentZone.polygon.length > 0) {
        onUpdateZonePolygon(activeZoneId, currentZone.polygon.slice(0, -1));
      }
    }
  };

  // Test Location Checker
  const handleTestLocation = (point: ServiceZonePoint) => {
    const L = (window as any).L;
    if (!L || !mapInstanceRef.current) return;

    setTestPoint(point);

    // Check KKTC Boundary
    const inKktc = isLocationInKktc(point.lat, point.lng);

    // Check which zones contain this point
    const matchingZones: string[] = [];
    zones.forEach((z) => {
      if (z.isActive && z.polygon && z.polygon.length >= 3) {
        if (isPointInPolygon(point, z.polygon)) {
          matchingZones.push(z.name);
        }
      }
    });

    setTestResult({
      insideZones: matchingZones,
      isInsideKktc: inKktc,
    });

    // Place or move test marker
    if (testMarkerRef.current) {
      testMarkerRef.current.setLatLng([point.lat, point.lng]);
    } else {
      const customPin = L.divIcon({
        className: 'test-location-pin',
        html: `
          <div style="
            width: 40px;
            height: 40px;
            background: #2563EB;
            border-radius: 50% 50% 50% 0;
            transform: rotate(-45deg);
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 10px 24px rgba(37, 99, 235, 0.55);
            border: 3px solid #ffffff;
          ">
            <span style="transform: rotate(45deg); color: white; font-size: 18px; font-weight: bold;">📍</span>
          </div>
        `,
        iconSize: [40, 40],
        iconAnchor: [20, 40],
      });

      const marker = L.marker([point.lat, point.lng], {
        icon: customPin,
        draggable: true,
      }).addTo(mapInstanceRef.current);

      marker.on('dragend', () => {
        const pos = marker.getLatLng();
        handleTestLocation({ lat: pos.lat, lng: pos.lng });
      });

      testMarkerRef.current = marker;
    }
  };

  const handleDistrictChange = (district: string) => {
    setSelectedDistrict(district);
    const target = DISTRICT_CENTERS[district];
    if (target && mapInstanceRef.current) {
      mapInstanceRef.current.flyTo([target.lat, target.lng], target.zoom, { duration: 1.2 });
    }
  };

  // Search Address
  const handleQueryChange = (text: string) => {
    setSearchQuery(text);
    if (!text.trim()) {
      setSearchResults([]);
      setShowDropdown(false);
      return;
    }

    if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current);
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
        if (Array.isArray(data)) {
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
      mapInstanceRef.current.flyTo([lat, lng], 15);
    }
    handleTestLocation({ lat, lng });
    setSearchQuery(item.display_name.split(',')[0]);
    setShowDropdown(false);
  };

  const clearTestMarker = () => {
    if (testMarkerRef.current) {
      testMarkerRef.current.remove();
      testMarkerRef.current = null;
    }
    setTestPoint(null);
    setTestResult(null);
  };

  const activeZone = zones.find((z) => z.id === activeZoneId);

  return (
    <div className={`space-y-4 font-sans ${isFullscreen ? 'fixed inset-0 z-[100] p-4 sm:p-6 bg-slate-950/90 backdrop-blur-xl flex flex-col justify-between overflow-hidden' : ''}`}>
      {/* Top Toolbar: District Presets, Fullscreen, Mode Selector & Address Search */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3 p-3.5 rounded-2xl border bg-slate-50 dark:bg-slate-950 dark:border-slate-800 shadow-xs shrink-0">
        {/* District Quick Focus Pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 lg:pb-0 scrollbar-none">
          <span className="text-[11px] font-black uppercase tracking-wider text-slate-400 mr-1 shrink-0 flex items-center gap-1">
            <Compass className="w-3.5 h-3.5 text-[#FF6B00]" />
            İlçe Odak:
          </span>
          {Object.keys(DISTRICT_CENTERS).map((d) => (
            <button
              key={d}
              type="button"
              onClick={() => handleDistrictChange(d)}
              className={`px-3 py-1.5 rounded-xl text-xs font-extrabold whitespace-nowrap transition-all ${
                selectedDistrict === d
                  ? 'bg-[#FF6B00] text-white shadow-sm'
                  : 'bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-800 hover:border-[#FF6B00]'
              }`}
            >
              {d}
            </button>
          ))}
        </div>

        {/* Action Modes (Test Mode, Undo, Fullscreen) */}
        <div className="flex items-center gap-2 shrink-0">
          {(isDrawingNew || activeZone) && (
            <button
              type="button"
              onClick={handleUndoLastVertex}
              className="px-3 py-2 rounded-xl text-xs font-black bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 flex items-center gap-1.5 shadow-xs transition-all"
              title="Eklenen son köşe noktasını geri al"
            >
              <Undo2 className="w-3.5 h-3.5 text-amber-500" />
              <span>Son Noktayı Geri Al</span>
            </button>
          )}

          <button
            type="button"
            onClick={() => {
              setIsTestMode(!isTestMode);
              if (isTestMode) clearTestMarker();
            }}
            className={`px-3.5 py-2 rounded-xl text-xs font-black flex items-center gap-1.5 transition-all ${
              isTestMode
                ? 'bg-blue-600 text-white shadow-sm ring-2 ring-blue-400/40'
                : 'bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-200 hover:border-blue-500 shadow-xs'
            }`}
          >
            <Navigation className="w-3.5 h-3.5" />
            <span>{isTestMode ? 'Test Kapat' : 'Konum Testi'}</span>
          </button>

          <button
            type="button"
            onClick={() => setIsFullscreen(!isFullscreen)}
            className="p-2 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-200 hover:text-[#FF6B00] shadow-xs transition-all"
            title={isFullscreen ? 'Tam Ekrandan Çık' : 'Tam Ekran Çizim Modu'}
          >
            {isFullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Address Search Bar */}
      <div className="relative shrink-0">
        <div className="relative">
          <Search className="absolute left-3.5 top-3 w-4 h-4 text-slate-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => handleQueryChange(e.target.value)}
            onFocus={() => {
              if (searchResults.length > 0) setShowDropdown(true);
            }}
            placeholder="KKTC içinde sokak, mahalle veya mekan ara (Örn: Dereboyu Caddesi, Girne Liman)..."
            className={`w-full border rounded-xl py-2.5 pl-10 pr-9 text-xs font-semibold outline-none focus:border-[#FF6B00] transition-colors shadow-xs ${
              isDark 
                ? 'bg-slate-950 border-slate-800 text-white placeholder-slate-500' 
                : 'bg-slate-50 border-slate-200 text-slate-900 placeholder-slate-400'
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

        {/* Dropdown Results */}
        {showDropdown && searchResults.length > 0 && (
          <div className={`absolute z-30 top-full left-0 right-0 mt-1 border rounded-xl shadow-2xl overflow-hidden max-h-60 overflow-y-auto ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'
          }`}>
            {searchResults.map((item, idx) => (
              <button
                key={idx}
                type="button"
                onClick={() => selectSearchResult(item)}
                className={`w-full text-left px-4 py-3 text-xs font-semibold flex items-center gap-2.5 border-b last:border-0 transition-colors ${
                  isDark ? 'border-slate-800 hover:bg-slate-800 text-slate-200' : 'border-slate-100 hover:bg-orange-50/60 text-slate-800'
                }`}
              >
                <MapPin className="w-4 h-4 text-[#FF6B00] shrink-0" />
                <span className="truncate">{item.display_name}</span>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Active Mode Banner */}
      {isDrawingNew ? (
        <div className="p-3.5 rounded-2xl bg-blue-500/10 border border-blue-500/30 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-blue-600 text-white flex items-center justify-center font-bold shrink-0 animate-pulse">
              <Plus className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-xs font-black text-blue-700 dark:text-blue-400 uppercase tracking-wider">
                Yeni Hizmet Bölgesi Çiziliyor
              </h4>
              <p className="text-xs font-bold text-slate-600 dark:text-slate-300 mt-0.5">
                Haritaya tıklayarak sınır köşe noktalarını ekleyin ({newZoneDraftPolygon.length} nokta eklendi).
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handleUndoLastVertex}
              disabled={newZoneDraftPolygon.length === 0}
              className="px-3 py-1.5 rounded-xl border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-200 text-xs font-bold disabled:opacity-40"
            >
              Geri Al
            </button>
            <button
              type="button"
              onClick={onCancelDrawingNew}
              className="px-3 py-1.5 rounded-xl border border-slate-300 dark:border-slate-700 text-slate-600 dark:text-slate-300 text-xs font-bold hover:bg-slate-200/50 transition-colors"
            >
              İptal
            </button>
            <button
              type="button"
              onClick={onFinishDrawingNew}
              disabled={newZoneDraftPolygon.length < 3}
              className={`px-4 py-1.5 rounded-xl text-xs font-black flex items-center gap-1.5 transition-all ${
                newZoneDraftPolygon.length >= 3
                  ? 'bg-blue-600 text-white shadow-md hover:bg-blue-700'
                  : 'bg-slate-300 dark:bg-slate-800 text-slate-500 cursor-not-allowed'
              }`}
            >
              <CheckCircle2 className="w-4 h-4" />
              <span>Çizimi Tamamla</span>
            </button>
          </div>
        </div>
      ) : isTestMode ? (
        <div className="p-3.5 rounded-2xl bg-indigo-500/10 border border-indigo-500/30 flex items-center justify-between gap-3 shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-indigo-600 text-white flex items-center justify-center font-bold shrink-0">
              <Navigation className="w-5 h-5 animate-pulse" />
            </div>
            <div>
              <h4 className="text-xs font-black text-indigo-700 dark:text-indigo-400 uppercase tracking-wider">
                Canlı Konum Doğrulama Modu
              </h4>
              <p className="text-xs font-bold text-slate-600 dark:text-slate-300 mt-0.5">
                Haritada herhangi bir yere tıklayın veya adres arayın. Hizmet kapsamı anında test edilir.
              </p>
            </div>
          </div>

          {testResult && (
            <div className="px-3 py-1.5 rounded-xl bg-white dark:bg-slate-900 border border-indigo-200 dark:border-indigo-800 shadow-sm text-right shrink-0">
              <span className="text-[10px] font-black uppercase text-slate-400 block">Kapsam Durumu</span>
              {testResult.insideZones.length > 0 ? (
                <span className="text-xs font-extrabold text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  {testResult.insideZones.join(', ')}
                </span>
              ) : (
                <span className="text-xs font-extrabold text-amber-600 dark:text-amber-400">
                  {testResult.isInsideKktc ? 'Bölge Dışı (Hizmet Yok)' : 'KKTC Sınırı Dışı'}
                </span>
              )}
            </div>
          )}
        </div>
      ) : activeZone ? (
        <div className="p-3 rounded-2xl bg-orange-500/10 border border-[#FF6B00]/30 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shrink-0">
          <div className="flex items-center gap-3">
            <div 
              className="w-8 h-8 rounded-xl flex items-center justify-center font-bold text-white shrink-0 shadow-sm"
              style={{ backgroundColor: activeZone.colorHex || '#FF6B00' }}
            >
              <Shapes className="w-4 h-4" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h4 className="text-xs font-black text-slate-900 dark:text-white uppercase tracking-wider">
                  Seçili Bölge: {activeZone.name}
                </h4>
                <span className="px-2 py-0.5 rounded-md text-[10px] font-bold bg-white dark:bg-slate-800 border">
                  {activeZone.polygon?.length || 0} Köşe Noktası
                </span>
              </div>
              <p className="text-[11px] font-bold text-slate-500 dark:text-slate-400 mt-0.5">
                Haritaya tıklayarak yeni köşe ekleyebilir veya mevcut beyaz köşe noktalarına tıklayarak silebilirsiniz.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {activeZone.polygon && activeZone.polygon.length > 0 && (
              <button
                type="button"
                onClick={() => handleFitZoneBounds(activeZone.polygon)}
                className="px-3 py-1.5 rounded-xl border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-200 text-xs font-bold hover:bg-slate-100 dark:hover:bg-slate-800 flex items-center gap-1 transition-colors"
                title="Haritayı bu bölgenin sınırlarına otomatik odakla"
              >
                <Target className="w-3.5 h-3.5 text-[#FF6B00]" />
                <span>Bölgeye Odaklan</span>
              </button>
            )}

            <button
              type="button"
              onClick={() => onUpdateZonePolygon(activeZone.id, [])}
              className="px-3 py-1.5 rounded-xl border border-rose-200 dark:border-rose-900/50 text-rose-500 text-xs font-black hover:bg-rose-50 dark:hover:bg-rose-950/40 transition-colors flex items-center gap-1"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Temizle</span>
            </button>
          </div>
        </div>
      ) : null}

      {/* Map Main Canvas Container */}
      <div className={`relative rounded-3xl overflow-hidden border border-slate-200 dark:border-slate-800 shadow-xl flex-1 ${isFullscreen ? 'h-full min-h-[500px]' : ''}`}>
        <div 
          ref={mapContainerRef} 
          className={`w-full ${isFullscreen ? 'h-full min-h-[500px]' : heightClass} z-10`} 
          style={{ cursor: isDrawingNew || activeZoneId ? 'crosshair' : isTestMode ? 'pointer' : 'grab' }}
        />

        {/* Floating Custom Zoom Controls (Top Right) */}
        <div className="absolute top-4 right-4 z-20 flex flex-col gap-1.5">
          <button
            type="button"
            onClick={() => mapInstanceRef.current?.zoomIn()}
            className={`p-2.5 rounded-xl border backdrop-blur-md shadow-lg transition-all active:scale-95 ${
              isDark ? 'bg-slate-900/90 border-slate-800 text-white hover:bg-slate-800' : 'bg-white/90 border-slate-200 text-slate-800 hover:bg-white'
            }`}
            title="Yakınlaştır"
          >
            <ZoomIn className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => mapInstanceRef.current?.zoomOut()}
            className={`p-2.5 rounded-xl border backdrop-blur-md shadow-lg transition-all active:scale-95 ${
              isDark ? 'bg-slate-900/90 border-slate-800 text-white hover:bg-slate-800' : 'bg-white/90 border-slate-200 text-slate-800 hover:bg-white'
            }`}
            title="Uzaklaştır"
          >
            <ZoomOut className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => handleDistrictChange('KKTC Genel')}
            className={`p-2.5 rounded-xl border backdrop-blur-md shadow-lg transition-all active:scale-95 ${
              isDark ? 'bg-slate-900/90 border-slate-800 text-[#FF6B00] hover:bg-slate-800' : 'bg-white/90 border-slate-200 text-[#FF6B00] hover:bg-white'
            }`}
            title="Varsayılan KKTC Görünümüne Sıfırla"
          >
            <Compass className="w-4 h-4" />
          </button>
        </div>

        {/* Live Coordinate & Status HUD (Bottom Left) */}
        <div className={`absolute bottom-4 left-4 z-20 px-3 py-1.5 rounded-xl border backdrop-blur-md shadow-md text-[11px] font-mono flex items-center gap-2.5 pointer-events-none ${
          isDark ? 'bg-slate-900/85 border-slate-800 text-slate-300' : 'bg-white/85 border-slate-200 text-slate-700'
        }`}>
          <div className="flex items-center gap-1">
            <Crosshair className="w-3.5 h-3.5 text-[#FF6B00]" />
            <span>
              {cursorCoords ? `${cursorCoords.lat.toFixed(4)}°N, ${cursorCoords.lng.toFixed(4)}°E` : '35.1856°N, 33.3823°E'}
            </span>
          </div>
          <span className="text-slate-400">|</span>
          <span>Zoom: {zoomLevel}x</span>
          {activeZone && (
            <>
              <span className="text-slate-400">|</span>
              <span className="font-bold text-[#FF6B00]">{activeZone.name} ({activeZone.polygon?.length || 0} nokta)</span>
            </>
          )}
        </div>

        {/* Floating Quick Legend & Zone Selector (Bottom Right) */}
        <div className={`absolute bottom-4 right-4 z-20 p-3 rounded-2xl border backdrop-blur-md shadow-2xl flex flex-col gap-1.5 max-w-xs ${
          isDark ? 'bg-slate-900/90 border-slate-800 text-slate-200' : 'bg-white/90 border-slate-200 text-slate-800'
        }`}>
          <div className="flex items-center justify-between pb-1 border-b border-slate-200 dark:border-slate-800">
            <span className="text-[10px] font-black uppercase tracking-wider text-slate-400 flex items-center gap-1">
              <Layers className="w-3 h-3 text-[#FF6B00]" />
              Aktif Bölgeler ({zones.length})
            </span>
          </div>

          <div className="max-h-36 overflow-y-auto space-y-1 scrollbar-none">
            {zones.map((z) => (
              <button
                key={z.id}
                type="button"
                onClick={() => {
                  onSelectZone(z.id);
                  if (z.polygon && z.polygon.length > 0) {
                    handleFitZoneBounds(z.polygon);
                  }
                }}
                className={`w-full text-left flex items-center justify-between p-1.5 rounded-lg text-[11px] font-bold transition-colors ${
                  z.id === activeZoneId 
                    ? 'bg-orange-500/15 text-[#FF6B00] ring-1 ring-[#FF6B00]/40' 
                    : 'hover:bg-slate-100 dark:hover:bg-slate-800'
                }`}
              >
                <div className="flex items-center gap-2 truncate">
                  <span 
                    className="w-2.5 h-2.5 rounded-full shrink-0 shadow-xs" 
                    style={{ backgroundColor: z.colorHex || '#FF6B00' }} 
                  />
                  <span className="truncate">{z.name}</span>
                </div>
                <span className="text-[9px] text-slate-400 shrink-0 ml-2">
                  {z.polygon?.length || 0} nokta
                </span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
