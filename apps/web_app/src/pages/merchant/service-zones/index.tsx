import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { 
  MapPin, Plus, Save, RotateCcw, Trash2, CheckCircle2, 
  AlertTriangle, Sparkles, Shapes, Globe, Layers, ShieldCheck,
  Edit3, ArrowRight, DollarSign, Clock, Truck, SlidersHorizontal,
  Maximize2, LayoutGrid, Eye, Target
} from 'lucide-react';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import KktcServiceZoneDrawerMap, { 
  KktcServiceZone, ServiceZonePoint 
} from '../../../components/merchant/KktcServiceZoneDrawerMap';
import { 
  getMerchantProfile, merchantApiFetch 
} from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';
import { KKTC_POLYGON } from '../../../utils/kktcBoundary';

const DEFAULT_COLOR_PALETTE = [
  { name: 'Hoppa Turuncu', hex: '#FF6B00' },
  { name: 'Zümrüt Yeşil', hex: '#00A651' },
  { name: 'Safir Mavi', hex: '#2563EB' },
  { name: 'Asil Mor', hex: '#7C3AED' },
  { name: 'Gül Pembesi', hex: '#E11D48' },
  { name: 'Altın Kehribar', hex: '#D97706' },
];

const PRESET_DISTRICT_ZONES: KktcServiceZone[] = [
  {
    id: 'preset-lefkosa',
    name: 'Lefkoşa Merkez & Çevre',
    district: 'Lefkoşa',
    isActive: true,
    minOrderAmount: 150,
    baseDeliveryFee: 35,
    deliveryTime: '25-40 dk',
    colorHex: '#FF6B00',
    description: 'Dereboyu, Gönyeli, Ortaköy, Hamitköy, Taşkınköy, Küçük Kaymaklı ve Haspolat kapsamı.',
    polygon: [
      { lat: 35.240, lng: 33.260 },
      { lat: 35.250, lng: 33.360 },
      { lat: 35.220, lng: 33.430 },
      { lat: 35.170, lng: 33.410 },
      { lat: 35.168, lng: 33.360 },
      { lat: 35.174, lng: 33.325 },
      { lat: 35.180, lng: 33.270 },
      { lat: 35.210, lng: 33.240 },
    ],
  },
  {
    id: 'preset-girne',
    name: 'Girne Sahil Şeridi',
    district: 'Girne',
    isActive: true,
    minOrderAmount: 200,
    baseDeliveryFee: 40,
    deliveryTime: '30-45 dk',
    colorHex: '#2563EB',
    description: 'Girne Merkez, Alsancak, Lapta, Karaoğlanoğlu, Karakum, Ozanköy ve Çatalköy.',
    polygon: [
      { lat: 35.370, lng: 33.150 },
      { lat: 35.380, lng: 33.300 },
      { lat: 35.370, lng: 33.420 },
      { lat: 35.320, lng: 33.400 },
      { lat: 35.310, lng: 33.250 },
      { lat: 35.330, lng: 33.150 },
    ],
  },
  {
    id: 'preset-magusa',
    name: 'Gazimağusa & DAÜ Kampüs',
    district: 'Gazimağusa',
    isActive: true,
    minOrderAmount: 150,
    baseDeliveryFee: 35,
    deliveryTime: '20-35 dk',
    colorHex: '#00A651',
    description: 'Suriçi, Sakarya, Baykal, Karakol, Gülseren ve DAÜ Kampüs Bölgesi.',
    polygon: [
      { lat: 35.170, lng: 33.880 },
      { lat: 35.175, lng: 33.950 },
      { lat: 35.120, lng: 33.970 },
      { lat: 35.095, lng: 33.960 },
      { lat: 35.100, lng: 33.880 },
      { lat: 35.140, lng: 33.870 },
    ],
  },
  {
    id: 'preset-guzelyurt',
    name: 'Güzelyurt & Lefke Bölgesi',
    district: 'Güzelyurt',
    isActive: true,
    minOrderAmount: 175,
    baseDeliveryFee: 35,
    deliveryTime: '30-50 dk',
    colorHex: '#D97706',
    description: 'Güzelyurt Merkez, ODTÜ KKK Kampüsü, Yayla, Bostancı ve Lefke LAÜ Bölgesi.',
    polygon: [
      { lat: 35.250, lng: 32.850 },
      { lat: 35.240, lng: 33.020 },
      { lat: 35.150, lng: 33.050 },
      { lat: 35.110, lng: 32.840 },
      { lat: 35.160, lng: 32.800 },
    ],
  },
  {
    id: 'preset-iskele',
    name: 'İskele & Long Beach',
    district: 'İskele',
    isActive: true,
    minOrderAmount: 200,
    baseDeliveryFee: 45,
    deliveryTime: '35-50 dk',
    colorHex: '#7C3AED',
    description: 'İskele Merkez, Long Beach Sahili, Boğaz, Ötüken ve Bafra Turizm Bölgesi.',
    polygon: [
      { lat: 35.340, lng: 33.850 },
      { lat: 35.350, lng: 34.020 },
      { lat: 35.250, lng: 33.950 },
      { lat: 35.230, lng: 33.860 },
    ],
  },
];

export default function KktcServiceZonesPage() {
  const router = useRouter();
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [profile, setProfile] = useState<any>(null);
  const [zones, setZones] = useState<KktcServiceZone[]>([]);
  const [activeZoneId, setActiveZoneId] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isSaving, setIsSaving] = useState<boolean>(false);
  const [saveSuccessMessage, setSaveSuccessMessage] = useState<string | null>(null);
  const [layoutMode, setLayoutMode] = useState<'split' | 'canvas'>('split');

  // New Zone Creation Draft
  const [isDrawingNew, setIsDrawingNew] = useState<boolean>(false);
  const [newZoneName, setNewZoneName] = useState<string>('Yeni Hizmet Bölgesi');
  const [newZoneDistrict, setNewZoneDistrict] = useState<string>('Lefkoşa');
  const [newZoneColor, setNewZoneColor] = useState<string>('#FF6B00');
  const [newZoneMinOrder, setNewZoneMinOrder] = useState<number>(150);
  const [newZoneDeliveryFee, setNewZoneDeliveryFee] = useState<number>(35);
  const [newZoneDeliveryTime, setNewZoneDeliveryTime] = useState<string>('30-45 dk');
  const [newZoneDraftPolygon, setNewZoneDraftPolygon] = useState<ServiceZonePoint[]>([]);

  useEffect(() => {
    const currentProfile = getMerchantProfile();
    if (!currentProfile) {
      router.push('/merchant/login');
      return;
    }

    if (currentProfile.role !== 'super_admin' && currentProfile.role !== 'admin') {
      alert('⚠️ Bu sayfaya yalnızca sistem yöneticileri (Admin) erişebilir.');
      router.push('/merchant/dashboard');
      return;
    }

    setProfile(currentProfile);
    fetchServiceZones();
  }, []);

  const fetchServiceZones = async () => {
    setIsLoading(true);
    try {
      const res = await merchantApiFetch('/admin/service-zones');
      if (res.data && Array.isArray(res.data) && res.data.length > 0) {
        setZones(res.data);
        setActiveZoneId(res.data[0].id);
      } else {
        // Fallback to presets
        setZones(PRESET_DISTRICT_ZONES);
        setActiveZoneId(PRESET_DISTRICT_ZONES[0].id);
      }
    } catch (err) {
      console.warn('Hizmet bölgeleri API’den alınamadı, şablon verisi yükleniyor:', err);
      setZones(PRESET_DISTRICT_ZONES);
      setActiveZoneId(PRESET_DISTRICT_ZONES[0].id);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSaveAll = async () => {
    setIsSaving(true);
    setSaveSuccessMessage(null);
    try {
      await merchantApiFetch('/admin/service-zones', {
        method: 'PUT',
        body: JSON.stringify({ zones }),
      });
      setSaveSuccessMessage('✅ KKTC hizmet bölgeleri ve poligon sınırları başarıyla kaydedildi!');
      setTimeout(() => setSaveSuccessMessage(null), 5000);
    } catch (err: any) {
      alert('Kayıt başarısız: ' + (err.message || 'Bilinmeyen hata'));
    } finally {
      setIsSaving(false);
    }
  };

  const handleUpdateZonePolygon = (zoneId: string, polygon: ServiceZonePoint[]) => {
    setZones((prev) =>
      prev.map((z) => (z.id === zoneId ? { ...z, polygon } : z))
    );
  };

  const handleUpdateZoneField = (zoneId: string, fields: Partial<KktcServiceZone>) => {
    setZones((prev) =>
      prev.map((z) => (z.id === zoneId ? { ...z, ...fields } : z))
    );
  };

  const handleDeleteZone = (zoneId: string) => {
    if (confirm('Bu hizmet bölgesini silmek istediğinize emin misiniz?')) {
      const updated = zones.filter((z) => z.id !== zoneId);
      setZones(updated);
      if (activeZoneId === zoneId) {
        setActiveZoneId(updated.length > 0 ? updated[0].id : null);
      }
    }
  };

  const handleStartDrawingNew = () => {
    setIsDrawingNew(true);
    setNewZoneName(`Özel Bölge ${zones.length + 1}`);
    setNewZoneDraftPolygon([]);
    setActiveZoneId(null);
  };

  const handleFinishDrawingNew = () => {
    if (newZoneDraftPolygon.length < 3) {
      alert('Geçerli bir kapalı alan (poligon) için en az 3 köşe noktası gereklidir.');
      return;
    }

    const newZone: KktcServiceZone = {
      id: `zone-${Date.now()}`,
      name: newZoneName,
      district: newZoneDistrict,
      isActive: true,
      minOrderAmount: newZoneMinOrder,
      baseDeliveryFee: newZoneDeliveryFee,
      deliveryTime: newZoneDeliveryTime,
      colorHex: newZoneColor,
      polygon: newZoneDraftPolygon,
    };

    const updated = [...zones, newZone];
    setZones(updated);
    setActiveZoneId(newZone.id);
    setIsDrawingNew(false);
    setNewZoneDraftPolygon([]);
  };

  const handleCancelDrawingNew = () => {
    setIsDrawingNew(false);
    setNewZoneDraftPolygon([]);
    if (zones.length > 0) {
      setActiveZoneId(zones[0].id);
    }
  };

  const handleLoadFullKktcBoundary = () => {
    if (confirm('Tüm KKTC resmi sınır poligonunu yeni bir hizmet bölgesi olarak eklemek istiyor musunuz?')) {
      const fullKktcZone: KktcServiceZone = {
        id: `zone-kktc-all-${Date.now()}`,
        name: 'Tüm KKTC Kapsamı',
        district: 'KKTC Genel',
        isActive: true,
        minOrderAmount: 250,
        baseDeliveryFee: 50,
        deliveryTime: '45-60 dk',
        colorHex: '#FF6B00',
        description: 'Tüm Kuzey Kıbrıs Türk Cumhuriyeti resmi sınırlarını kapsayan platform ana hizmet alanı.',
        polygon: KKTC_POLYGON,
      };

      setZones((prev) => [...prev, fullKktcZone]);
      setActiveZoneId(fullKktcZone.id);
    }
  };

  const handleResetToPresets = () => {
    if (confirm('Tüm bölgeleri varsayılan 5 ilçe şablonuna sıfırlamak istiyor musunuz? Kaydedilmemiş değişiklikler kaybolacaktır.')) {
      setZones(PRESET_DISTRICT_ZONES);
      setActiveZoneId(PRESET_DISTRICT_ZONES[0].id);
      setIsDrawingNew(false);
    }
  };

  const activeZone = zones.find((z) => z.id === activeZoneId);

  return (
    <MerchantLayout
      title="KKTC Hizmet Alanları & Sınır Yönetimi"
      subtitle="Kuzey Kıbrıs genelinde platform teslimat kapsamını ve ilçe hizmet sınırlarını serbest poligon çizerek geniş ekranda yönetin."
      headerIcon={MapPin}
      activeTab="service-zones"
      headerActions={
        <div className="flex items-center gap-2">
          {/* Layout Mode Toggle */}
          <div className="flex items-center gap-1 p-1 rounded-xl bg-white/20 backdrop-blur-md border border-white/20 mr-1">
            <button
              type="button"
              onClick={() => setLayoutMode('split')}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                layoutMode === 'split' ? 'bg-white text-[#FF6B00] shadow-sm' : 'text-white/90 hover:text-white'
              }`}
              title="Bölünmüş Panel Görünümü"
            >
              Panelli Görünüm
            </button>
            <button
              type="button"
              onClick={() => setLayoutMode('canvas')}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                layoutMode === 'canvas' ? 'bg-white text-[#FF6B00] shadow-sm' : 'text-white/90 hover:text-white'
              }`}
              title="Genişletilmiş Harita Odak Modu"
            >
              Geniş Harita Modu
            </button>
          </div>

          <button
            type="button"
            onClick={handleStartDrawingNew}
            className="px-4 py-2.5 rounded-xl bg-white text-[#FF6B00] font-black text-xs shadow-sm hover:bg-orange-50 active:scale-[0.98] transition-all flex items-center gap-1.5"
          >
            <Plus className="w-4 h-4" />
            <span>+ Yeni Bölge Çiz</span>
          </button>

          <button
            type="button"
            onClick={handleSaveAll}
            disabled={isSaving}
            className="px-5 py-2.5 rounded-xl bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-black text-xs shadow-md hover:opacity-90 active:scale-[0.98] transition-all flex items-center gap-2"
          >
            {isSaving ? (
              <span className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
            ) : (
              <Save className="w-4 h-4" />
            )}
            <span>{isSaving ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet'}</span>
          </button>
        </div>
      }
    >
      <div className="w-full max-w-[1700px] mx-auto space-y-6">
        {/* Success Alert Banner */}
        {saveSuccessMessage && (
          <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-700 dark:text-emerald-300 text-xs font-black flex items-center justify-between shadow-xs">
            <div className="flex items-center gap-2">
              <CheckCircle2 className="w-5 h-5 text-emerald-500" />
              <span>{saveSuccessMessage}</span>
            </div>
            <button 
              type="button" 
              onClick={() => setSaveSuccessMessage(null)}
              className="text-xs opacity-70 hover:opacity-100 font-bold"
            >
              Kapat
            </button>
          </div>
        )}

        {/* Quick Summary Metric Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className={`p-4 rounded-2xl border transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs'
          }`}>
            <span className="text-[10px] font-black uppercase tracking-wider text-slate-400 block">Toplam Hizmet Bölgesi</span>
            <div className="flex items-baseline justify-between mt-1">
              <span className="text-2xl font-black text-slate-900 dark:text-white">{zones.length}</span>
              <span className="text-xs font-bold text-slate-500">Bölge Tanımlı</span>
            </div>
          </div>

          <div className={`p-4 rounded-2xl border transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs'
          }`}>
            <span className="text-[10px] font-black uppercase tracking-wider text-emerald-500 block">Aktif Teslimat Alanları</span>
            <div className="flex items-baseline justify-between mt-1">
              <span className="text-2xl font-black text-emerald-600 dark:text-emerald-400">
                {zones.filter((z) => z.isActive).length}
              </span>
              <span className="text-xs font-bold text-emerald-500/80">Canlı Kapsamda</span>
            </div>
          </div>

          <div className={`p-4 rounded-2xl border transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs'
          }`}>
            <span className="text-[10px] font-black uppercase tracking-wider text-blue-500 block">Harita Çizim Motoru</span>
            <div className="flex items-baseline justify-between mt-1">
              <span className="text-sm font-black text-blue-600 dark:text-blue-400">Leaflet Çoklu Poligon</span>
              <span className="text-xs font-bold text-slate-400">Genişletilmiş Tuval</span>
            </div>
          </div>

          <div className={`p-4 rounded-2xl border transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs'
          }`}>
            <span className="text-[10px] font-black uppercase tracking-wider text-[#FF6B00] block">Yetki Seviyesi</span>
            <div className="flex items-baseline justify-between mt-1">
              <span className="text-sm font-black text-[#FF6B00] uppercase">Admin / Super Admin</span>
              <span className="px-1.5 py-0.5 rounded text-[9px] bg-[#FF6B00] text-white font-black">PLATFORM</span>
            </div>
          </div>
        </div>

        {/* Main Workspace Layout */}
        {layoutMode === 'split' ? (
          /* Split View: Left Column (3.8 cols) / Right Column Map (8.2 cols) */
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            {/* Left Column: Zones List & Editor */}
            <div className="lg:col-span-4 space-y-4">
              {/* Presets & Quick Tools */}
              <div className={`p-4 rounded-2xl border ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs'
              }`}>
                <div className="flex items-center justify-between pb-3 mb-3 border-b border-slate-100 dark:border-slate-800">
                  <span className="text-xs font-black uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
                    <SlidersHorizontal className="w-3.5 h-3.5 text-[#FF6B00]" />
                    Hızlı Şablonlar
                  </span>
                  <button
                    type="button"
                    onClick={handleResetToPresets}
                    className="text-[11px] font-bold text-slate-500 hover:text-[#FF6B00] flex items-center gap-1 transition-colors"
                  >
                    <RotateCcw className="w-3 h-3" />
                    <span>Şablonlara Sıfırla</span>
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={handleLoadFullKktcBoundary}
                    className="p-2.5 rounded-xl border border-dashed border-orange-300 dark:border-orange-900/50 hover:bg-orange-50/50 dark:hover:bg-orange-950/20 text-left transition-colors"
                  >
                    <span className="text-xs font-black text-[#FF6B00] block">Tüm KKTC Sınırı</span>
                    <span className="text-[10px] text-slate-500 block mt-0.5">Resmi sınır poligonu</span>
                  </button>

                  <button
                    type="button"
                    onClick={handleStartDrawingNew}
                    className="p-2.5 rounded-xl border border-dashed border-blue-300 dark:border-blue-900/50 hover:bg-blue-50/50 dark:hover:bg-blue-950/20 text-left transition-colors"
                  >
                    <span className="text-xs font-black text-blue-600 dark:text-blue-400 block">+ Yeni Bölge Çiz</span>
                    <span className="text-[10px] text-slate-500 block mt-0.5">Haritada özel alan</span>
                  </button>
                </div>
              </div>

              {/* If Drawing New Zone Form */}
              {isDrawingNew && (
                <div className={`p-5 rounded-2xl border-2 border-blue-500/40 bg-blue-500/5 ${
                  isDark ? 'border-slate-800' : 'shadow-sm'
                }`}>
                  <div className="flex items-center justify-between pb-3 mb-4 border-b border-blue-200 dark:border-blue-900/50">
                    <h3 className="text-sm font-black text-blue-600 dark:text-blue-400 flex items-center gap-2">
                      <Shapes className="w-4 h-4" />
                      <span>Yeni Bölge Bilgileri</span>
                    </h3>
                    <span className="text-xs font-extrabold text-blue-600">
                      {newZoneDraftPolygon.length} Nokta
                    </span>
                  </div>

                  <div className="space-y-3.5">
                    <div>
                      <label className="text-[11px] font-black uppercase text-slate-500 block mb-1">
                        Bölge Adı
                      </label>
                      <input
                        type="text"
                        value={newZoneName}
                        onChange={(e) => setNewZoneName(e.target.value)}
                        placeholder="Örn: Girne Alsancak Özel Bölgesi"
                        className={`w-full border rounded-xl p-2.5 text-xs font-bold outline-none focus:border-blue-500 ${
                          isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-white border-slate-200'
                        }`}
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-2.5">
                      <div>
                        <label className="text-[11px] font-black uppercase text-slate-500 block mb-1">
                          İlçe / Şehir
                        </label>
                        <select
                          value={newZoneDistrict}
                          onChange={(e) => setNewZoneDistrict(e.target.value)}
                          className={`w-full border rounded-xl p-2.5 text-xs font-bold outline-none focus:border-blue-500 ${
                            isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-white border-slate-200'
                          }`}
                        >
                          <option value="Lefkoşa">Lefkoşa</option>
                          <option value="Girne">Girne</option>
                          <option value="Gazimağusa">Gazimağusa</option>
                          <option value="Güzelyurt">Güzelyurt</option>
                          <option value="İskele">İskele</option>
                          <option value="Lefke">Lefke</option>
                          <option value="KKTC Genel">KKTC Genel</option>
                        </select>
                      </div>

                      <div>
                        <label className="text-[11px] font-black uppercase text-slate-500 block mb-1">
                          Bölge Rengi
                        </label>
                        <div className="flex items-center gap-1.5 pt-1">
                          {DEFAULT_COLOR_PALETTE.map((c) => (
                            <button
                              key={c.hex}
                              type="button"
                              onClick={() => setNewZoneColor(c.hex)}
                              className={`w-6 h-6 rounded-full transition-transform ${
                                newZoneColor === c.hex ? 'scale-125 ring-2 ring-blue-500 ring-offset-2' : 'hover:scale-110'
                              }`}
                              style={{ backgroundColor: c.hex }}
                              title={c.name}
                            />
                          ))}
                        </div>
                      </div>
                    </div>

                    <div className="grid grid-cols-3 gap-2">
                      <div>
                        <label className="text-[10px] font-black uppercase text-slate-500 block mb-1">
                          Min. Tutar (₺)
                        </label>
                        <input
                          type="number"
                          value={newZoneMinOrder}
                          onChange={(e) => setNewZoneMinOrder(Number(e.target.value))}
                          className={`w-full border rounded-xl p-2 text-xs font-bold outline-none ${
                            isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-white border-slate-200'
                          }`}
                        />
                      </div>

                      <div>
                        <label className="text-[10px] font-black uppercase text-slate-500 block mb-1">
                          Teslimat (₺)
                        </label>
                        <input
                          type="number"
                          value={newZoneDeliveryFee}
                          onChange={(e) => setNewZoneDeliveryFee(Number(e.target.value))}
                          className={`w-full border rounded-xl p-2 text-xs font-bold outline-none ${
                            isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-white border-slate-200'
                          }`}
                        />
                      </div>

                      <div>
                        <label className="text-[10px] font-black uppercase text-slate-500 block mb-1">
                          Süre
                        </label>
                        <input
                          type="text"
                          value={newZoneDeliveryTime}
                          onChange={(e) => setNewZoneDeliveryTime(e.target.value)}
                          placeholder="30-45 dk"
                          className={`w-full border rounded-xl p-2 text-xs font-bold outline-none ${
                            isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-white border-slate-200'
                          }`}
                        />
                      </div>
                    </div>

                    <div className="pt-2 flex items-center justify-end gap-2">
                      <button
                        type="button"
                        onClick={handleCancelDrawingNew}
                        className="px-3 py-2 rounded-xl border text-xs font-bold text-slate-600 dark:text-slate-300"
                      >
                        İptal
                      </button>
                      <button
                        type="button"
                        onClick={handleFinishDrawingNew}
                        disabled={newZoneDraftPolygon.length < 3}
                        className={`px-4 py-2 rounded-xl text-xs font-black flex items-center gap-1.5 ${
                          newZoneDraftPolygon.length >= 3 
                            ? 'bg-blue-600 text-white shadow-md hover:bg-blue-700' 
                            : 'bg-slate-200 dark:bg-slate-800 text-slate-400 cursor-not-allowed'
                        }`}
                      >
                        <CheckCircle2 className="w-4 h-4" />
                        <span>Bölgeyi Kaydet ({newZoneDraftPolygon.length} Nokta)</span>
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* Zones List */}
              <div className="space-y-3">
                <div className="flex items-center justify-between px-1">
                  <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                    Kayıtlı Hizmet Bölgeleri ({zones.length})
                  </span>
                </div>

                <div className="max-h-[640px] overflow-y-auto space-y-2.5 pr-1 scrollbar-thin">
                  {zones.map((zone) => {
                    const isSelected = zone.id === activeZoneId;
                    return (
                      <div
                        key={zone.id}
                        className={`rounded-2xl border transition-all duration-200 overflow-hidden ${
                          isSelected
                            ? 'border-[#FF6B00] shadow-md ring-1 ring-[#FF6B00]/30'
                            : isDark
                              ? 'bg-slate-900/80 border-slate-800 hover:border-slate-700'
                              : 'bg-white border-slate-200 hover:border-slate-300 shadow-xs'
                        }`}
                      >
                        {/* Zone Header Item */}
                        <div 
                          onClick={() => {
                            if (!isDrawingNew) {
                              setActiveZoneId(isSelected ? null : zone.id);
                            }
                          }}
                          className={`p-3.5 flex items-center justify-between cursor-pointer transition-colors ${
                            isSelected 
                              ? isDark ? 'bg-orange-500/10' : 'bg-orange-50/70' 
                              : ''
                          }`}
                        >
                          <div className="flex items-center gap-3 min-w-0">
                            <span 
                              className="w-3.5 h-3.5 rounded-full shrink-0 shadow-sm"
                              style={{ backgroundColor: zone.colorHex || '#FF6B00' }}
                            />
                            <div className="min-w-0">
                              <div className="flex items-center gap-2">
                                <h4 className="font-extrabold text-sm truncate text-slate-900 dark:text-white">
                                  {zone.name}
                                </h4>
                                <span className="px-1.5 py-0.5 rounded text-[9px] font-bold bg-slate-100 dark:bg-slate-800 text-slate-500 shrink-0">
                                  {zone.district}
                                </span>
                              </div>
                              <p className="text-[11px] font-semibold text-slate-500 dark:text-slate-400 truncate mt-0.5">
                                Min: ₺{zone.minOrderAmount} • Teslimat: ₺{zone.baseDeliveryFee} • {zone.deliveryTime}
                              </p>
                            </div>
                          </div>

                          <div className="flex items-center gap-2 shrink-0">
                            <button
                              type="button"
                              onClick={(e) => {
                                e.stopPropagation();
                                handleUpdateZoneField(zone.id, { isActive: !zone.isActive });
                              }}
                              className={`px-2.5 py-1 rounded-full text-[10px] font-black transition-colors ${
                                zone.isActive
                                  ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30'
                                  : 'bg-slate-200 dark:bg-slate-800 text-slate-500'
                              }`}
                            >
                              {zone.isActive ? 'AKTİF' : 'PASİF'}
                            </button>
                          </div>
                        </div>

                        {/* Zone Edit Drawer */}
                        {isSelected && (
                          <div className="p-4 pt-2 border-t border-slate-100 dark:border-slate-800 space-y-3 bg-slate-50/50 dark:bg-slate-950/40">
                            <div>
                              <label className="text-[10px] font-black uppercase text-slate-400 block mb-1">
                                Bölge Adı
                              </label>
                              <input
                                type="text"
                                value={zone.name}
                                onChange={(e) => handleUpdateZoneField(zone.id, { name: e.target.value })}
                                className={`w-full border rounded-xl p-2 text-xs font-bold outline-none ${
                                  isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200'
                                }`}
                              />
                            </div>

                            <div className="grid grid-cols-2 gap-2">
                              <div>
                                <label className="text-[10px] font-black uppercase text-slate-400 block mb-1">
                                  İlçe
                                </label>
                                <select
                                  value={zone.district}
                                  onChange={(e) => handleUpdateZoneField(zone.id, { district: e.target.value })}
                                  className={`w-full border rounded-xl p-2 text-xs font-bold outline-none ${
                                    isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200'
                                  }`}
                                >
                                  <option value="Lefkoşa">Lefkoşa</option>
                                  <option value="Girne">Girne</option>
                                  <option value="Gazimağusa">Gazimağusa</option>
                                  <option value="Güzelyurt">Güzelyurt</option>
                                  <option value="İskele">İskele</option>
                                  <option value="Lefke">Lefke</option>
                                  <option value="KKTC Genel">KKTC Genel</option>
                                </select>
                              </div>

                              <div>
                                <label className="text-[10px] font-black uppercase text-slate-400 block mb-1">
                                  Renk
                                </label>
                                <div className="flex items-center gap-1 pt-1">
                                  {DEFAULT_COLOR_PALETTE.map((c) => (
                                    <button
                                      key={c.hex}
                                      type="button"
                                      onClick={() => handleUpdateZoneField(zone.id, { colorHex: c.hex })}
                                      className={`w-5 h-5 rounded-full transition-transform ${
                                        zone.colorHex === c.hex ? 'scale-125 ring-2 ring-[#FF6B00]' : 'opacity-80 hover:opacity-100'
                                      }`}
                                      style={{ backgroundColor: c.hex }}
                                    />
                                  ))}
                                </div>
                              </div>
                            </div>

                            <div className="grid grid-cols-3 gap-2">
                              <div>
                                <label className="text-[10px] font-black uppercase text-slate-400 block mb-1">
                                  Min. (₺)
                                </label>
                                <input
                                  type="number"
                                  value={zone.minOrderAmount}
                                  onChange={(e) => handleUpdateZoneField(zone.id, { minOrderAmount: Number(e.target.value) })}
                                  className={`w-full border rounded-xl p-2 text-xs font-bold outline-none ${
                                    isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200'
                                  }`}
                                />
                              </div>

                              <div>
                                <label className="text-[10px] font-black uppercase text-slate-400 block mb-1">
                                  Teslimat (₺)
                                </label>
                                <input
                                  type="number"
                                  value={zone.baseDeliveryFee}
                                  onChange={(e) => handleUpdateZoneField(zone.id, { baseDeliveryFee: Number(e.target.value) })}
                                  className={`w-full border rounded-xl p-2 text-xs font-bold outline-none ${
                                    isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200'
                                  }`}
                                />
                              </div>

                              <div>
                                <label className="text-[10px] font-black uppercase text-slate-400 block mb-1">
                                  Süre
                                </label>
                                <input
                                  type="text"
                                  value={zone.deliveryTime}
                                  onChange={(e) => handleUpdateZoneField(zone.id, { deliveryTime: e.target.value })}
                                  className={`w-full border rounded-xl p-2 text-xs font-bold outline-none ${
                                    isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200'
                                  }`}
                                />
                              </div>
                            </div>

                            <div className="pt-2 flex items-center justify-between border-t border-slate-200/60 dark:border-slate-800">
                              <span className="text-[11px] font-bold text-slate-400">
                                {zone.polygon?.length || 0} köşe noktası
                              </span>
                              <button
                                type="button"
                                onClick={() => handleDeleteZone(zone.id)}
                                className="px-2.5 py-1.5 rounded-lg text-xs font-black text-rose-500 hover:bg-rose-500/10 flex items-center gap-1 transition-colors"
                              >
                                <Trash2 className="w-3.5 h-3.5" />
                                <span>Sil</span>
                              </button>
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Right Column: Large Interactive Leaflet Map (8 cols) */}
            <div className="lg:col-span-8">
              <div className={`p-4 rounded-3xl border transition-all ${
                isDark ? 'bg-slate-900/80 border-slate-800' : 'bg-white border-slate-200 shadow-md'
              }`}>
                <div className="flex items-center justify-between pb-3 mb-2 border-b border-slate-100 dark:border-slate-800">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-[#E95D22] to-[#FF8C00] text-white flex items-center justify-center font-bold">
                      <Globe className="w-4 h-4" />
                    </div>
                    <div>
                      <h3 className="text-sm font-black text-slate-900 dark:text-white">
                        KKTC Canlı Poligon Çizim Tuvali (Genişletilmiş)
                      </h3>
                      <p className="text-[11px] text-slate-500 font-medium">
                        Haritaya tıklayarak nokta ekleyin veya mevcut beyaz noktaları sürükleyip silin.
                      </p>
                    </div>
                  </div>
                </div>

                <KktcServiceZoneDrawerMap
                  zones={zones}
                  activeZoneId={activeZoneId}
                  onSelectZone={(id) => setActiveZoneId(id)}
                  onUpdateZonePolygon={handleUpdateZonePolygon}
                  isDrawingNew={isDrawingNew}
                  newZoneDraftPolygon={newZoneDraftPolygon}
                  onUpdateNewZoneDraftPolygon={setNewZoneDraftPolygon}
                  onFinishDrawingNew={handleFinishDrawingNew}
                  onCancelDrawingNew={handleCancelDrawingNew}
                  heightClass="h-[760px]"
                />
              </div>
            </div>
          </div>
        ) : (
          /* Full Canvas Mode (12-cols full width map) */
          <div className="space-y-4">
            {/* Quick Floating Action Bar for Full Canvas */}
            <div className={`p-4 rounded-2xl border flex flex-col md:flex-row md:items-center justify-between gap-3 ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
            }`}>
              <div className="flex items-center gap-2 overflow-x-auto pb-1 md:pb-0 scrollbar-none">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400 mr-2 shrink-0 flex items-center gap-1.5">
                  <Shapes className="w-4 h-4 text-[#FF6B00]" />
                  Bölge Seç:
                </span>
                {zones.map((z) => (
                  <button
                    key={z.id}
                    type="button"
                    onClick={() => setActiveZoneId(z.id)}
                    className={`px-3.5 py-1.5 rounded-xl text-xs font-black whitespace-nowrap flex items-center gap-2 transition-all ${
                      z.id === activeZoneId
                        ? 'bg-[#FF6B00] text-white shadow-sm ring-2 ring-[#FF6B00]/40'
                        : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-200 hover:border-[#FF6B00]'
                    }`}
                  >
                    <span 
                      className="w-2.5 h-2.5 rounded-full" 
                      style={{ backgroundColor: z.colorHex || '#FF6B00' }} 
                    />
                    <span>{z.name}</span>
                    <span className="text-[10px] opacity-75 font-normal">({z.polygon?.length || 0} pt)</span>
                  </button>
                ))}
              </div>

              <div className="flex items-center gap-2 shrink-0">
                <button
                  type="button"
                  onClick={handleLoadFullKktcBoundary}
                  className="px-3 py-1.5 rounded-xl border border-dashed border-orange-300 dark:border-orange-900/50 text-[#FF6B00] text-xs font-black hover:bg-orange-50/50 transition-colors"
                >
                  Tüm KKTC Sınırı
                </button>
                <button
                  type="button"
                  onClick={handleStartDrawingNew}
                  className="px-3.5 py-1.5 rounded-xl bg-blue-600 text-white text-xs font-black hover:bg-blue-700 transition-colors flex items-center gap-1"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>Yeni Bölge</span>
                </button>
              </div>
            </div>

            {/* Huge Full-Width Map Canvas */}
            <div className={`p-4 rounded-3xl border transition-all ${
              isDark ? 'bg-slate-900/80 border-slate-800' : 'bg-white border-slate-200 shadow-xl'
            }`}>
              <KktcServiceZoneDrawerMap
                zones={zones}
                activeZoneId={activeZoneId}
                onSelectZone={(id) => setActiveZoneId(id)}
                onUpdateZonePolygon={handleUpdateZonePolygon}
                isDrawingNew={isDrawingNew}
                newZoneDraftPolygon={newZoneDraftPolygon}
                onUpdateNewZoneDraftPolygon={setNewZoneDraftPolygon}
                onFinishDrawingNew={handleFinishDrawingNew}
                onCancelDrawingNew={handleCancelDrawingNew}
                heightClass="h-[840px]"
              />
            </div>
          </div>
        )}
      </div>
    </MerchantLayout>
  );
}
