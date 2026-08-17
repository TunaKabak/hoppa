import React, { useState, useEffect } from 'react';
import Head from 'next/head';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import GuidedOnboardingWidget from '../../../components/merchant/GuidedOnboardingWidget';
import LocationRadiusPickerMap, { LocationPolygonPoint } from '../../../components/merchant/LocationRadiusPickerMap';
import { 
  Settings, Clock, MapPin, Store, Check, Save, AlertCircle, Phone, Upload, Map,
  Building2, FileText, Image as ImageIcon, CreditCard, Truck, ShieldAlert, Sparkles, Copy, Trash2
} from 'lucide-react';
import { merchantApiFetch, getMerchantToken } from '../../../utils/merchant-auth';
import { uploadMerchantMedia } from '../../../utils/media-upload';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';
import { KKTC_CITIES, KKTC_DISTRICTS } from '../../../data/kktcDistricts';

const DAYS_KEY_MAP: Record<string, string> = {
  monday: 'Pazartesi',
  tuesday: 'Salı',
  wednesday: 'Çarşamba',
  thursday: 'Perşembe',
  friday: 'Cuma',
  saturday: 'Cumartesi',
  sunday: 'Pazar',
};

const DEFAULT_DAYS = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

interface DaySchedule {
  isOpen: boolean;
  open: string;
  close: string;
}

export default function MerchantSettingsPage() {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [activeTab, setActiveTab] = useState<'profile' | 'operation' | 'location'>('profile');

  // Profile Tab State
  const [businessName, setBusinessName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [taxNumber, setTaxNumber] = useState('');
  const [identityNumber, setIdentityNumber] = useState('');
  const [logoUrl, setLogoUrl] = useState('');
  const [headerImageUrl, setHeaderImageUrl] = useState('');

  const [isUploadingLogo, setIsUploadingLogo] = useState(false);
  const [isUploadingHeader, setIsUploadingHeader] = useState(false);

  // Operation & Order Rules State
  const [minOrderAmount, setMinOrderAmount] = useState<number>(150);
  const [deliveryTime, setDeliveryTime] = useState<string>('30-45 dk');
  const [deliveryPricingType, setDeliveryPricingType] = useState<string>('FIXED');
  const [baseDeliveryFee, setBaseDeliveryFee] = useState<number>(30);
  const [deliveryFeePerKm, setDeliveryFeePerKm] = useState<number>(5);
  const [freeDeliveryThreshold, setFreeDeliveryThreshold] = useState<number | ''>('');

  // Payment Methods
  const [supportsOnline, setSupportsOnline] = useState<boolean>(true);
  const [supportsCash, setSupportsCash] = useState<boolean>(true);
  const [supportsCard, setSupportsCard] = useState<boolean>(true);

  // Fulfillment Models
  const [supportsPlatformDelivery, setSupportsPlatformDelivery] = useState<boolean>(true);
  const [supportsSelfDelivery, setSupportsSelfDelivery] = useState<boolean>(false);
  const [supportsPickup, setSupportsPickup] = useState<boolean>(true);

  // 7-day Working Hours State (Object keyed by day)
  const [workingHours, setWorkingHours] = useState<Record<string, DaySchedule>>({
    monday: { isOpen: true, open: '08:00', close: '22:00' },
    tuesday: { isOpen: true, open: '08:00', close: '22:00' },
    wednesday: { isOpen: true, open: '08:00', close: '22:00' },
    thursday: { isOpen: true, open: '08:00', close: '22:00' },
    friday: { isOpen: true, open: '08:00', close: '22:00' },
    saturday: { isOpen: true, open: '08:00', close: '22:00' },
    sunday: { isOpen: true, open: '08:00', close: '22:00' },
  });

  // Location & Zone State
  const [selectedCity, setSelectedCity] = useState<string>('Lefkoşa');
  const [selectedDistrict, setSelectedDistrict] = useState<string>('');
  const [addressLine, setAddressLine] = useState('');
  const [latitude, setLatitude] = useState<number>(35.1856);
  const [longitude, setLongitude] = useState<number>(33.3823);
  const [deliveryRadiusKm, setDeliveryRadiusKm] = useState<number>(5);
  const [isPolygonMode, setIsPolygonMode] = useState<boolean>(false);
  const [deliveryPolygon, setDeliveryPolygon] = useState<LocationPolygonPoint[]>([]);

  // Page State
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    fetchShopDetails();
  }, []);

  const parseAddressParts = (rawAddress: string) => {
    if (!rawAddress) return;
    const parts = rawAddress.split(',').map((p) => p.trim());
    if (parts.length >= 3) {
      const cityCand = parts[parts.length - 1];
      const distCand = parts[parts.length - 2];
      if (KKTC_CITIES.includes(cityCand as any)) {
        setSelectedCity(cityCand);
        setSelectedDistrict(distCand);
        setAddressLine(parts.slice(0, parts.length - 2).join(', '));
        return;
      }
    }
    setAddressLine(rawAddress);
  };

  const fetchShopDetails = async () => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      const res = await merchantApiFetch('/merchant/shop');
      if (res.data) {
        const shop = res.data;
        setBusinessName(shop.businessName || shop.name || '');
        setPhoneNumber(shop.businessPhone || shop.phone || shop.merchant?.businessPhone || '');
        setTaxNumber(shop.taxNumber || shop.merchant?.taxNumber || '');
        setIdentityNumber(shop.identityNumber || shop.merchant?.identityNumber || '');
        setLogoUrl(shop.imageUrl || shop.logoUrl || '');
        setHeaderImageUrl(shop.headerImageUrl || '');

        setMinOrderAmount(shop.minOrderAmount ?? shop.minimumOrderAmount ?? 150);
        setDeliveryTime(shop.deliveryTime || '30-45 dk');
        setDeliveryPricingType(shop.deliveryPricingType || 'FIXED');
        setBaseDeliveryFee(shop.baseDeliveryFee ?? 30);
        setDeliveryFeePerKm(shop.deliveryFeePerKm ?? 5);
        setFreeDeliveryThreshold(shop.freeDeliveryThreshold !== null && shop.freeDeliveryThreshold !== undefined ? shop.freeDeliveryThreshold : '');

        // Payment Methods
        const paymentMethods: string[] = shop.allowedPaymentMethods || ['ONLINE_PAYMENT', 'CASH_ON_DELIVERY', 'CARD_ON_DELIVERY'];
        setSupportsOnline(paymentMethods.includes('ONLINE_PAYMENT'));
        setSupportsCash(paymentMethods.includes('CASH_ON_DELIVERY'));
        setSupportsCard(paymentMethods.includes('CARD_ON_DELIVERY'));

        // Fulfillment Models
        const fulfillmentModels: string[] = shop.allowedFulfillmentModels || ['PLATFORM_DELIVERY', 'PICKUP'];
        setSupportsPlatformDelivery(fulfillmentModels.includes('PLATFORM_DELIVERY'));
        setSupportsSelfDelivery(fulfillmentModels.includes('SELF_DELIVERY'));
        setSupportsPickup(fulfillmentModels.includes('PICKUP'));

        // Location & Map
        setLatitude(shop.latitude || 35.1856);
        setLongitude(shop.longitude || 33.3823);
        setDeliveryRadiusKm(shop.deliveryRadiusKm || 5);
        if (shop.deliveryPolygon && Array.isArray(shop.deliveryPolygon) && shop.deliveryPolygon.length > 0) {
          setIsPolygonMode(true);
          setDeliveryPolygon(shop.deliveryPolygon);
        } else {
          setIsPolygonMode(false);
          setDeliveryPolygon([]);
        }

        parseAddressParts(shop.address || '');

        // Working Hours Hydration
        if (shop.workingHours) {
          if (Array.isArray(shop.workingHours)) {
            // Legacy Array format conversion
            const mapObj: Record<string, DaySchedule> = {};
            const trMap: Record<string, string> = {
              Pazartesi: 'monday',
              Salı: 'tuesday',
              Çarşamba: 'wednesday',
              Perşembe: 'thursday',
              Cuma: 'friday',
              Cumartesi: 'saturday',
              Pazar: 'sunday',
            };
            DEFAULT_DAYS.forEach((d) => {
              mapObj[d] = { isOpen: true, open: '08:00', close: '22:00' };
            });
            shop.workingHours.forEach((wh: any) => {
              const key = trMap[wh.day] || wh.day?.toLowerCase();
              if (key && mapObj[key]) {
                mapObj[key] = {
                  isOpen: !wh.isClosed,
                  open: wh.open || '08:00',
                  close: wh.close || '22:00',
                };
              }
            });
            setWorkingHours(mapObj);
          } else if (typeof shop.workingHours === 'object') {
            const mapObj: Record<string, DaySchedule> = {};
            DEFAULT_DAYS.forEach((d) => {
              const existing = shop.workingHours[d];
              mapObj[d] = existing ? {
                isOpen: existing.isOpen !== undefined ? Boolean(existing.isOpen) : true,
                open: existing.open || '08:00',
                close: existing.close || '22:00',
              } : { isOpen: true, open: '08:00', close: '22:00' };
            });
            setWorkingHours(mapObj);
          }
        }
      }
    } catch (err: any) {
      console.error('Mağaza detayları alınamadı:', err);
      setErrorMsg(err.message || 'Mağaza bilgileri yüklenirken bir hata oluştu.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleDayScheduleChange = (dayKey: string, field: keyof DaySchedule, value: any) => {
    setWorkingHours((prev) => ({
      ...prev,
      [dayKey]: {
        ...prev[dayKey],
        [field]: value,
      },
    }));
  };

  const copyMondayScheduleToAll = () => {
    const mondaySched = workingHours['monday'];
    if (!mondaySched) return;

    if (confirm("Pazartesi gününün çalışma saatleri tüm haftaya kopyalansın mı?")) {
      const updated: Record<string, DaySchedule> = {};
      DEFAULT_DAYS.forEach((d) => {
        updated[d] = { ...mondaySched };
      });
      setWorkingHours(updated);
    }
  };

  // Upload Handler for Logo / Header
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>, type: 'logo' | 'header') => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 5 * 1024 * 1024) {
      alert('Görsel boyutu maksimum 5MB olmalıdır.');
      return;
    }

    if (type === 'logo') setIsUploadingLogo(true);
    else setIsUploadingHeader(true);

    try {
      const finalUrl = await uploadMerchantMedia(file);

      if (type === 'logo') {
        setLogoUrl(finalUrl);
      } else {
        setHeaderImageUrl(finalUrl);
      }
    } catch (err: any) {
      alert(err.message || 'Görsel yüklenirken hata oluştu.');
    } finally {
      if (type === 'logo') setIsUploadingLogo(false);
      else setIsUploadingHeader(false);
    }
  };

  const handleSaveSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    setSuccessMsg(null);
    setErrorMsg(null);

    // Validations
    if (!supportsOnline && !supportsCash && !supportsCard) {
      setErrorMsg('En az bir ödeme yöntemi kabul edilmelidir.');
      setIsSaving(false);
      return;
    }

    if (!supportsPlatformDelivery && !supportsSelfDelivery && !supportsPickup) {
      setErrorMsg('En az bir teslimat veya hizmet yöntemi kabul edilmelidir.');
      setIsSaving(false);
      return;
    }

    if (isPolygonMode && deliveryPolygon.length > 0 && deliveryPolygon.length < 3) {
      setErrorMsg('Geçerli bir özel teslimat poligonu için en az 3 köşe noktası belirlenmelidir.');
      setIsSaving(false);
      return;
    }

    const fullAddressString = [
      addressLine.trim(),
      selectedDistrict.trim(),
      selectedCity.trim(),
    ].filter(Boolean).join(', ');

    const payload = {
      name: businessName,
      businessName,
      phone: phoneNumber,
      businessPhone: phoneNumber,
      taxNumber: taxNumber.trim(),
      identityNumber: identityNumber.trim(),
      imageUrl: logoUrl,
      logoUrl,
      headerImageUrl,

      minOrderAmount: Number(minOrderAmount) || 0,
      minimumOrderAmount: Number(minOrderAmount) || 0,
      deliveryTime,
      deliveryPricingType,
      baseDeliveryFee: Number(baseDeliveryFee) || 0,
      deliveryFeePerKm: Number(deliveryFeePerKm) || 0,
      freeDeliveryThreshold: freeDeliveryThreshold !== '' ? Number(freeDeliveryThreshold) : null,

      allowedPaymentMethods: [
        supportsOnline ? 'ONLINE_PAYMENT' : null,
        supportsCash ? 'CASH_ON_DELIVERY' : null,
        supportsCard ? 'CARD_ON_DELIVERY' : null,
      ].filter(Boolean) as string[],

      allowedFulfillmentModels: [
        supportsPlatformDelivery ? 'PLATFORM_DELIVERY' : null,
        supportsSelfDelivery ? 'SELF_DELIVERY' : null,
        supportsPickup ? 'PICKUP' : null,
      ].filter(Boolean) as string[],

      workingHours,

      address: fullAddressString,
      latitude: Number(latitude),
      longitude: Number(longitude),
      deliveryRadiusKm: isPolygonMode ? 5.0 : Number(deliveryRadiusKm),
      deliveryPolygon: isPolygonMode ? deliveryPolygon : null,
    };

    try {
      const res = await merchantApiFetch('/merchant/shop', {
        method: 'PUT',
        body: JSON.stringify(payload),
      });

      if (res.data) {
        setSuccessMsg('Mağaza profiliniz, çalışma saatleriniz ve teslimat ayarlarınız başarıyla güncellendi!');
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Ayarlar kaydedilirken bir hata oluştu.');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <MerchantLayout title="Mağaza Ayarları & Konum" activeTab="settings">
      <Head>
        <title>Mağaza Ayarları | Hoppa Merchant</title>
      </Head>

      <div className="space-y-6">
        {/* Sticky Header Bar with Actions */}
        <div className={`sticky top-0 z-30 backdrop-blur-md flex flex-col sm:flex-row sm:items-center justify-between gap-4 border rounded-3xl p-6 transition-all ${
          isDark ? 'bg-slate-900/90 border-slate-800' : 'bg-white/90 border-slate-200 shadow-md'
        }`}>
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-[#FF6B00] text-white flex items-center justify-center font-bold shadow-lg shadow-[#FF6B00]/25">
              <Settings className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-2xl font-black tracking-tight">Mağaza Ayarları</h1>
              <p className="text-xs font-semibold text-slate-500 dark:text-slate-400 mt-0.5">
                Profil bilgileri, çalışma saatleri, ödeme & teslimat kuralları ve harita alanı
              </p>
            </div>
          </div>

          <button
            onClick={handleSaveSettings}
            disabled={isSaving}
            className="px-6 py-3 rounded-2xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-xs shadow-lg shadow-[#FF6B00]/25 flex items-center justify-center gap-2 transition-all disabled:opacity-50 shrink-0"
          >
            {isSaving ? (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : (
              <>
                <Save className="w-4 h-4" />
                <span>Tüm Değişiklikleri Kaydet</span>
              </>
            )}
          </button>
        </div>

        {/* Guided Onboarding Bar */}
        <GuidedOnboardingWidget hasWorkingHours={Object.values(workingHours).some((w) => w.isOpen)} />

        {/* Alert Feedback Messages */}
        {successMsg && (
          <div className="p-4 rounded-2xl bg-[#00A651]/15 border border-[#00A651]/30 text-[#00A651] text-xs font-bold flex items-center gap-2">
            <Check className="w-5 h-5 shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        {errorMsg && (
          <div className="p-4 rounded-2xl bg-rose-500/15 border border-rose-500/30 text-rose-600 dark:text-rose-400 text-xs font-bold flex items-center gap-2">
            <ShieldAlert className="w-5 h-5 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* 3 Main Tab Switcher Pills */}
        <div className="flex border-b border-slate-200 dark:border-slate-800 gap-2 overflow-x-auto pb-1">
          <button
            type="button"
            onClick={() => setActiveTab('profile')}
            className={`px-5 py-3 rounded-2xl font-black text-xs flex items-center gap-2 transition-all whitespace-nowrap ${
              activeTab === 'profile'
                ? 'bg-[#FF6B00] text-white shadow-lg shadow-[#FF6B00]/20'
                : 'text-slate-500 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800'
            }`}
          >
            <Store className="w-4 h-4" />
            <span>1. Mağaza Profili & Görseller</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('operation')}
            className={`px-5 py-3 rounded-2xl font-black text-xs flex items-center gap-2 transition-all whitespace-nowrap ${
              activeTab === 'operation'
                ? 'bg-[#FF6B00] text-white shadow-lg shadow-[#FF6B00]/20'
                : 'text-slate-500 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800'
            }`}
          >
            <Clock className="w-4 h-4" />
            <span>2. Operasyon, Ödeme & Saatler</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('location')}
            className={`px-5 py-3 rounded-2xl font-black text-xs flex items-center gap-2 transition-all whitespace-nowrap ${
              activeTab === 'location'
                ? 'bg-[#FF6B00] text-white shadow-lg shadow-[#FF6B00]/20'
                : 'text-slate-500 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800'
            }`}
          >
            <MapPin className="w-4 h-4" />
            <span>3. Adres & Teslimat Bölgesi</span>
          </button>
        </div>

        {/* Tab Contents */}
        <form onSubmit={handleSaveSettings} className="space-y-6">
          {/* TAB 1: STORE PROFILE & MEDIA */}
          {activeTab === 'profile' && (
            <div className="space-y-6">
              {/* Basic Info Block */}
              <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}>
                <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                  <Building2 className="w-5 h-5 text-[#FF6B00]" />
                  <h3 className="font-extrabold text-sm uppercase tracking-wider">Mağaza Temel Bilgileri</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Mağaza Ticari Adı *
                    </label>
                    <input
                      type="text"
                      required
                      value={businessName}
                      onChange={(e) => setBusinessName(e.target.value)}
                      placeholder="Örn: Kebapçı İbo Usta"
                      className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      İletişim Telefon Numarası *
                    </label>
                    <input
                      type="text"
                      required
                      value={phoneNumber}
                      onChange={(e) => setPhoneNumber(e.target.value)}
                      placeholder="+90 533 000 0000"
                      className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    />
                  </div>
                </div>
              </div>

              {/* Official Merchant Details */}
              <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}>
                <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                  <FileText className="w-5 h-5 text-[#FF6B00]" />
                  <h3 className="font-extrabold text-sm uppercase tracking-wider">Resmi Kayıt & Vergi Bilgileri</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Vergi Numarası
                    </label>
                    <input
                      type="text"
                      value={taxNumber}
                      onChange={(e) => setTaxNumber(e.target.value)}
                      placeholder="Örn: 1234567890"
                      className={`w-full border rounded-xl p-3 text-sm font-mono font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Şahıs / Kimlik Numarası
                    </label>
                    <input
                      type="text"
                      value={identityNumber}
                      onChange={(e) => setIdentityNumber(e.target.value)}
                      placeholder="Örn: 11111111111"
                      className={`w-full border rounded-xl p-3 text-sm font-mono font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    />
                  </div>
                </div>
              </div>

              {/* Brand Visual Assets Upload */}
              <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}>
                <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                  <ImageIcon className="w-5 h-5 text-[#FF6B00]" />
                  <h3 className="font-extrabold text-sm uppercase tracking-wider">Mağaza Görselleri (Logo & Kapak)</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* Logo Upload Box */}
                  <div className="space-y-3">
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-400">
                      Mağaza Logosu
                    </label>
                    <div className="flex items-center gap-4">
                      <div className="relative w-24 h-24 rounded-2xl border-2 border-dashed border-slate-300 dark:border-slate-700 overflow-hidden bg-slate-100 dark:bg-slate-950 flex items-center justify-center shrink-0">
                        {logoUrl ? (
                          <img src={logoUrl} alt="Logo" className="w-full h-full object-cover" />
                        ) : (
                          <div className="w-full h-full bg-gradient-to-br from-[#FF6B00] to-[#E56000] flex items-center justify-center text-white font-black text-2xl">
                            {businessName ? businessName[0].toUpperCase() : 'H'}
                          </div>
                        )}
                        {isUploadingLogo && (
                          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center">
                            <div className="w-6 h-6 border-2 border-white border-t-transparent rounded-full animate-spin" />
                          </div>
                        )}
                      </div>

                      <div className="space-y-2 flex-1">
                        <label className="px-4 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-bold text-xs shadow-md shadow-[#FF6B00]/20 flex items-center justify-center gap-2 cursor-pointer transition-all">
                          <Upload className="w-4 h-4" />
                          <span>Logo Yükle</span>
                          <input
                            type="file"
                            accept="image/*"
                            onChange={(e) => handleFileUpload(e, 'logo')}
                            className="hidden"
                          />
                        </label>
                        {logoUrl && (
                          <button
                            type="button"
                            onClick={() => setLogoUrl('')}
                            className="text-[11px] font-bold text-rose-500 hover:underline block"
                          >
                            Görseli Kaldır
                          </button>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Header Banner Upload Box */}
                  <div className="space-y-3">
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-400">
                      Kapak Görseli (Banner)
                    </label>
                    <div className="space-y-3">
                      <div className="relative w-full h-24 rounded-2xl border-2 border-dashed border-slate-300 dark:border-slate-700 overflow-hidden bg-slate-100 dark:bg-slate-950 flex items-center justify-center">
                        {headerImageUrl ? (
                          <img src={headerImageUrl} alt="Kapak" className="w-full h-full object-cover" />
                        ) : (
                          <div className="w-full h-full bg-gradient-to-r from-orange-100 to-amber-100 dark:from-slate-800 dark:to-slate-900 flex items-center justify-center text-slate-400 font-bold text-xs">
                            Kapak Görseli Eklenmedi (Varsayılan Degrade)
                          </div>
                        )}
                        {isUploadingHeader && (
                          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center">
                            <div className="w-6 h-6 border-2 border-white border-t-transparent rounded-full animate-spin" />
                          </div>
                        )}
                      </div>

                      <div className="flex items-center gap-3">
                        <label className="px-4 py-2.5 rounded-xl bg-slate-800 dark:bg-slate-700 hover:bg-slate-900 text-white font-bold text-xs shadow-md flex items-center justify-center gap-2 cursor-pointer transition-all">
                          <Upload className="w-4 h-4" />
                          <span>Kapak Yükle</span>
                          <input
                            type="file"
                            accept="image/*"
                            onChange={(e) => handleFileUpload(e, 'header')}
                            className="hidden"
                          />
                        </label>
                        {headerImageUrl && (
                          <button
                            type="button"
                            onClick={() => setHeaderImageUrl('')}
                            className="text-[11px] font-bold text-rose-500 hover:underline"
                          >
                            Kapağı Kaldır
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: OPERATION, PAYMENT & HOURS */}
          {activeTab === 'operation' && (
            <div className="space-y-6">
              {/* Order Rules & Delivery Time */}
              <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}>
                <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                  <Truck className="w-5 h-5 text-[#FF6B00]" />
                  <h3 className="font-extrabold text-sm uppercase tracking-wider">Sipariş & Teslimat Ayarları</h3>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Min. Sepet Tutarı (₺)
                    </label>
                    <input
                      type="number"
                      min="0"
                      value={minOrderAmount}
                      onChange={(e) => setMinOrderAmount(Number(e.target.value))}
                      className={`w-full border rounded-xl p-3 text-sm font-black text-[#FF6B00] outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                      }`}
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Ort. Teslimat Süresi
                    </label>
                    <select
                      value={deliveryTime}
                      onChange={(e) => setDeliveryTime(e.target.value)}
                      className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    >
                      <option value="15-30 dk">15-30 dk</option>
                      <option value="30-45 dk">30-45 dk</option>
                      <option value="45-60 dk">45-60 dk</option>
                      <option value="60+ dk">60+ dk</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Ücretlendirme Tipi
                    </label>
                    <select
                      value={deliveryPricingType}
                      onChange={(e) => setDeliveryPricingType(e.target.value)}
                      className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    >
                      <option value="FIXED">Sabit Ücret</option>
                      <option value="DISTANCE_BASED">Mesafeye Göre</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Temel Teslimat Ücreti (₺)
                    </label>
                    <input
                      type="number"
                      min="0"
                      value={baseDeliveryFee}
                      onChange={(e) => setBaseDeliveryFee(Number(e.target.value))}
                      className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    />
                  </div>

                  {deliveryPricingType === 'DISTANCE_BASED' && (
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                        Km Başına Ücret (₺)
                      </label>
                      <input
                        type="number"
                        min="0"
                        value={deliveryFeePerKm}
                        onChange={(e) => setDeliveryFeePerKm(Number(e.target.value))}
                        className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                          isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                        }`}
                      />
                    </div>
                  )}

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Ücretsiz Teslimat Limiti (₺)
                    </label>
                    <input
                      type="number"
                      min="0"
                      placeholder="İsteğe Bağlı (Örn: 500)"
                      value={freeDeliveryThreshold}
                      onChange={(e) => setFreeDeliveryThreshold(e.target.value === '' ? '' : Number(e.target.value))}
                      className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    />
                  </div>
                </div>
              </div>

              {/* Payment Methods & Fulfillment Models */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Accepted Payment Methods */}
                <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
                  isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
                }`}>
                  <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                    <CreditCard className="w-5 h-5 text-[#00A651]" />
                    <h3 className="font-extrabold text-sm uppercase tracking-wider">Kabul Edilen Ödeme Yöntemleri</h3>
                  </div>

                  <div className="space-y-3">
                    <label className="flex items-center justify-between p-3.5 rounded-2xl border cursor-pointer hover:border-[#FF6B00] transition-all">
                      <div>
                        <p className="font-extrabold text-xs">Online Ödeme (Kredi/Banka Kartı)</p>
                        <p className="text-[11px] text-slate-400">Uygulama içi güvenli kart ile ödeme</p>
                      </div>
                      <input
                        type="checkbox"
                        checked={supportsOnline}
                        onChange={(e) => setSupportsOnline(e.target.checked)}
                        className="w-5 h-5 rounded border-slate-300 text-[#FF6B00] focus:ring-[#FF6B00]"
                      />
                    </label>

                    <label className="flex items-center justify-between p-3.5 rounded-2xl border cursor-pointer hover:border-[#FF6B00] transition-all">
                      <div>
                        <p className="font-extrabold text-xs">Kapıda Nakit</p>
                        <p className="text-[11px] text-slate-400">Teslimat sırasında nakit ödeme</p>
                      </div>
                      <input
                        type="checkbox"
                        checked={supportsCash}
                        onChange={(e) => setSupportsCash(e.target.checked)}
                        className="w-5 h-5 rounded border-slate-300 text-[#FF6B00] focus:ring-[#FF6B00]"
                      />
                    </label>

                    <label className="flex items-center justify-between p-3.5 rounded-2xl border cursor-pointer hover:border-[#FF6B00] transition-all">
                      <div>
                        <p className="font-extrabold text-xs">Kapıda Kredi Kartı</p>
                        <p className="text-[11px] text-slate-400">Teslimatta mobil POS ile ödeme</p>
                      </div>
                      <input
                        type="checkbox"
                        checked={supportsCard}
                        onChange={(e) => setSupportsCard(e.target.checked)}
                        className="w-5 h-5 rounded border-slate-300 text-[#FF6B00] focus:ring-[#FF6B00]"
                      />
                    </label>
                  </div>
                </div>

                {/* Fulfillment Models */}
                <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
                  isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
                }`}>
                  <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                    <Truck className="w-5 h-5 text-indigo-500" />
                    <h3 className="font-extrabold text-sm uppercase tracking-wider">Teslimat & Hizmet Seçenekleri</h3>
                  </div>

                  <div className="space-y-3">
                    <label className="flex items-center justify-between p-3.5 rounded-2xl border cursor-pointer hover:border-indigo-500 transition-all">
                      <div>
                        <p className="font-extrabold text-xs">Hoppa Kuryesi (Platform Teslimatı)</p>
                        <p className="text-[11px] text-slate-400">Siparişleri bağımsız Hoppa kuryeleri taşır</p>
                      </div>
                      <input
                        type="checkbox"
                        checked={supportsPlatformDelivery}
                        onChange={(e) => setSupportsPlatformDelivery(e.target.checked)}
                        className="w-5 h-5 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                      />
                    </label>

                    <label className="flex items-center justify-between p-3.5 rounded-2xl border cursor-pointer hover:border-indigo-500 transition-all">
                      <div>
                        <p className="font-extrabold text-xs">İşletme Kuryesi (Esnaf Teslimatı)</p>
                        <p className="text-[11px] text-slate-400">Kendi moto-kurye ekibinizle teslimat</p>
                      </div>
                      <input
                        type="checkbox"
                        checked={supportsSelfDelivery}
                        onChange={(e) => setSupportsSelfDelivery(e.target.checked)}
                        className="w-5 h-5 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                      />
                    </label>

                    <label className="flex items-center justify-between p-3.5 rounded-2xl border cursor-pointer hover:border-indigo-500 transition-all">
                      <div>
                        <p className="font-extrabold text-xs">Gel-Al (Müşteri Alımı)</p>
                        <p className="text-[11px] text-slate-400">Müşterinin dükkandan kendisinin teslim alması</p>
                      </div>
                      <input
                        type="checkbox"
                        checked={supportsPickup}
                        onChange={(e) => setSupportsPickup(e.target.checked)}
                        className="w-5 h-5 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                      />
                    </label>
                  </div>
                </div>
              </div>

              {/* 7-Day Working Hours Schedule */}
              <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}>
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-200 dark:border-slate-800">
                  <div className="flex items-center gap-2">
                    <Clock className="w-5 h-5 text-[#FF6B00]" />
                    <h3 className="font-extrabold text-sm uppercase tracking-wider">7 Günlük Çalışma Saatleri</h3>
                  </div>

                  <button
                    type="button"
                    onClick={copyMondayScheduleToAll}
                    className="px-3.5 py-1.5 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-[#FF6B00]/10 hover:text-[#FF6B00] text-xs font-bold flex items-center gap-1.5 transition-all self-start sm:self-auto"
                  >
                    <Copy className="w-3.5 h-3.5 text-[#FF6B00]" />
                    <span>Pazartesi'yi Tümüne Uygula</span>
                  </button>
                </div>

                <div className="space-y-3">
                  {DEFAULT_DAYS.map((dayKey) => {
                    const sched = workingHours[dayKey] || { isOpen: true, open: '08:00', close: '22:00' };
                    return (
                      <div
                        key={dayKey}
                        className={`p-3.5 rounded-2xl border flex flex-col sm:flex-row sm:items-center justify-between gap-3 ${
                          isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                        }`}
                      >
                        <div className="w-28 font-extrabold text-sm flex items-center gap-2">
                          <span>{DAYS_KEY_MAP[dayKey]}</span>
                        </div>

                        <div className="flex items-center gap-4">
                          <label className="flex items-center gap-2 text-xs font-bold cursor-pointer">
                            <input
                              type="checkbox"
                              checked={!sched.isOpen}
                              onChange={(e) => handleDayScheduleChange(dayKey, 'isOpen', !e.target.checked)}
                              className="rounded border-slate-300 text-rose-500 focus:ring-0"
                            />
                            <span className={!sched.isOpen ? 'text-rose-500 font-black' : 'text-emerald-500 font-black'}>
                              {!sched.isOpen ? 'KAPALI (Tatil)' : 'Açık'}
                            </span>
                          </label>

                          {sched.isOpen && (
                            <div className="flex items-center gap-2">
                              <input
                                type="time"
                                value={sched.open}
                                onChange={(e) => handleDayScheduleChange(dayKey, 'open', e.target.value)}
                                className={`border rounded-lg p-1.5 text-xs font-mono font-bold ${
                                  isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200 text-slate-900'
                                }`}
                              />
                              <span className="text-xs text-slate-400 font-bold">-</span>
                              <input
                                type="time"
                                value={sched.close}
                                onChange={(e) => handleDayScheduleChange(dayKey, 'close', e.target.value)}
                                className={`border rounded-lg p-1.5 text-xs font-mono font-bold ${
                                  isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200 text-slate-900'
                                }`}
                              />
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: ADDRESS & MAP DELIVERY ZONE */}
          {activeTab === 'location' && (
            <div className="space-y-6">
              {/* KKTC City, District & Address Details */}
              <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}>
                <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                  <MapPin className="w-5 h-5 text-[#FF6B00]" />
                  <h3 className="font-extrabold text-sm uppercase tracking-wider">Fiziki Dükkan Adresi (KKTC)</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Şehir (İl) *
                    </label>
                    <select
                      value={selectedCity}
                      onChange={(e) => {
                        const newCity = e.target.value;
                        setSelectedCity(newCity);
                        const districts = KKTC_DISTRICTS[newCity] || [];
                        setSelectedDistrict(districts[0] || '');
                      }}
                      className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    >
                      {KKTC_CITIES.map((c) => (
                        <option key={c} value={c}>
                          {c}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Semt (İlçe / Bölge) *
                    </label>
                    <select
                      value={selectedDistrict}
                      onChange={(e) => setSelectedDistrict(e.target.value)}
                      className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    >
                      {(KKTC_DISTRICTS[selectedCity] || []).map((d) => (
                        <option key={d} value={d}>
                          {d}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="md:col-span-2">
                    <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                      Açık Adres (Cadde, Sokak, Bina No)
                    </label>
                    <input
                      type="text"
                      value={addressLine}
                      onChange={(e) => setAddressLine(e.target.value)}
                      placeholder="Örn: Dereboyu Cad. No:12 Daire:4"
                      className={`w-full border rounded-xl p-3 text-sm font-semibold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    />
                  </div>
                </div>
              </div>

              {/* Interactive Map & Zone Selector */}
              <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}>
                <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                  <Map className="w-5 h-5 text-[#FF6B00]" />
                  <h3 className="font-extrabold text-sm uppercase tracking-wider">İnteraktif Harita & Teslimat Bölgesi</h3>
                </div>

                <LocationRadiusPickerMap
                  latitude={latitude}
                  longitude={longitude}
                  radiusKm={deliveryRadiusKm}
                  isPolygonMode={isPolygonMode}
                  deliveryPolygon={deliveryPolygon}
                  onLocationChange={(lat, lng) => {
                    setLatitude(lat);
                    setLongitude(lng);
                  }}
                  onRadiusChange={(r) => setDeliveryRadiusKm(r)}
                  onPolygonModeChange={(isPoly) => setIsPolygonMode(isPoly)}
                  onPolygonChange={(poly) => setDeliveryPolygon(poly)}
                />
              </div>
            </div>
          )}

          {/* Bottom Save Action Button */}
          <div className="flex justify-end pt-4">
            <button
              type="submit"
              disabled={isSaving}
              className="px-8 py-3.5 rounded-2xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-sm shadow-xl shadow-[#FF6B00]/25 flex items-center justify-center gap-2 transition-all disabled:opacity-50"
            >
              {isSaving ? (
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <Save className="w-5 h-5" />
                  <span>Tüm Değişiklikleri Kaydet</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </MerchantLayout>
  );
}
