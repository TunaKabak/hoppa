import React, { useState, useEffect } from 'react';
import Head from 'next/head';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import GuidedOnboardingWidget from '../../../components/merchant/GuidedOnboardingWidget';
import LocationRadiusPickerMap from '../../../components/merchant/LocationRadiusPickerMap';
import { 
  Settings, Clock, MapPin, CreditCard, Store, Check, Save, AlertCircle, Phone, Upload, Map 
} from 'lucide-react';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

export default function MerchantSettingsPage() {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [businessName, setBusinessName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [address, setAddress] = useState('');
  const [minOrderAmount, setMinOrderAmount] = useState<number>(50);
  const [deliveryRadiusKm, setDeliveryRadiusKm] = useState<number>(5);
  const [latitude, setLatitude] = useState<number>(35.1856);
  const [longitude, setLongitude] = useState<number>(33.3823);
  const [iban, setIban] = useState('TR560006200000000000000000');
  const [logoUrl, setLogoUrl] = useState('');

  // 7-day working hours state
  const [workingHours, setWorkingHours] = useState([
    { day: 'Pazartesi', open: '09:00', close: '22:00', isClosed: false },
    { day: 'Salı', open: '09:00', close: '22:00', isClosed: false },
    { day: 'Çarşamba', open: '09:00', close: '22:00', isClosed: false },
    { day: 'Perşembe', open: '09:00', close: '22:00', isClosed: false },
    { day: 'Cuma', open: '09:00', close: '23:00', isClosed: false },
    { day: 'Cumartesi', open: '10:00', close: '23:00', isClosed: false },
    { day: 'Pazar', open: '10:00', close: '22:00', isClosed: false },
  ]);

  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  useEffect(() => {
    fetchShopDetails();
  }, []);

  const fetchShopDetails = async () => {
    setIsLoading(true);
    try {
      const res = await merchantApiFetch('/merchant/shop');
      if (res.data) {
        setBusinessName(res.data.name || res.data.businessName || '');
        setPhoneNumber(res.data.phone || '');
        setAddress(res.data.address || '');
        setMinOrderAmount(res.data.minOrderAmount || 50);
        setDeliveryRadiusKm(res.data.deliveryRadiusKm || 5);
        setLatitude(res.data.latitude || 35.1856);
        setLongitude(res.data.longitude || 33.3823);
        setIban(res.data.iban || 'TR560006200000000000000000');
        setLogoUrl(res.data.logoUrl || '');
        if (res.data.workingHours && Array.isArray(res.data.workingHours)) {
          setWorkingHours(res.data.workingHours);
        }
      }
    } catch (err) {
      console.error('Mağaza detayları alınamadı:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleWorkingHourChange = (idx: number, field: string, val: any) => {
    const updated = [...workingHours];
    (updated[idx] as any)[field] = val;
    setWorkingHours(updated);
  };

  const handleSaveSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    setSuccessMsg(null);

    try {
      await merchantApiFetch('/merchant/shop', {
        method: 'PUT',
        body: JSON.stringify({
          name: businessName,
          phone: phoneNumber,
          address,
          minOrderAmount: Number(minOrderAmount),
          deliveryRadiusKm: Number(deliveryRadiusKm),
          latitude: Number(latitude),
          longitude: Number(longitude),
          iban,
          logoUrl,
          workingHours,
        }),
      });
      setSuccessMsg('Mağaza profiliniz, harita konumunuz ve çalışma saatleriniz başarıyla güncellendi!');
    } catch (err: any) {
      alert(err.message || 'Ayarlar kaydedilemedi.');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <MerchantLayout title="Mağaza Ayarları & Harita Konumu" activeTab="settings">
      <div className="space-y-6">
        {/* Top Header */}
        <div className={`sticky top-0 z-30 backdrop-blur-md flex flex-col sm:flex-row sm:items-center justify-between gap-4 border rounded-3xl p-6 transition-all ${
          isDark ? 'bg-slate-900/90 border-slate-800' : 'bg-white/90 border-slate-200 shadow-md'
        }`}>
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-[#FF6B00] text-white flex items-center justify-center font-bold shadow-lg shadow-[#FF6B00]/25">
              <Settings className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-2xl font-black tracking-tight">Mağaza Ayarları & Harita Konumu</h1>
              <p className="text-xs font-semibold text-slate-500 dark:text-slate-400 mt-0.5">
                Harita konumu pinleme, teslimat yarıçapı, çalışma saatleri ve hakediş IBAN bilgileri
              </p>
            </div>
          </div>

          <button
            onClick={handleSaveSettings}
            disabled={isSaving}
            className="px-6 py-3 rounded-2xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-xs shadow-lg shadow-[#FF6B00]/25 flex items-center justify-center gap-2 transition-all disabled:opacity-50"
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
        <GuidedOnboardingWidget hasWorkingHours={workingHours.some(w => !w.isClosed)} />

        {successMsg && (
          <div className="p-4 rounded-2xl bg-[#00A651]/15 border border-[#00A651]/30 text-[#00A651] text-xs font-bold flex items-center gap-2">
            <Check className="w-5 h-5 shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        <form onSubmit={handleSaveSettings} className="space-y-6">
          
          {/* Section 1: Interactive Map Pinning & Delivery Radius Picker */}
          <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
          }`}>
            <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
              <Map className="w-5 h-5 text-[#FF6B00]" />
              <h3 className="font-extrabold text-sm uppercase tracking-wider">İnteraktif Harita Konum Pinleme & Teslimat Bölgesi</h3>
            </div>

            <LocationRadiusPickerMap
              latitude={latitude}
              longitude={longitude}
              radiusKm={deliveryRadiusKm}
              onLocationChange={(lat, lng) => {
                setLatitude(lat);
                setLongitude(lng);
              }}
              onRadiusChange={(r) => setDeliveryRadiusKm(r)}
            />
          </div>

          {/* Section 2: Store Basic Profile */}
          <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
          }`}>
            <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
              <Store className="w-5 h-5 text-[#FF6B00]" />
              <h3 className="font-extrabold text-sm uppercase tracking-wider">Mağaza Profil Bilgileri</h3>
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
                  className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                    isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                  }`}
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                  İletişim Telefonu
                </label>
                <input
                  type="text"
                  value={phoneNumber}
                  onChange={(e) => setPhoneNumber(e.target.value)}
                  placeholder="+90 533 000 0000"
                  className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                    isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                  }`}
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                  Fiziki Açık Adres
                </label>
                <input
                  type="text"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="Örn: Dereboyu Cad. No:12 Lefkoşa"
                  className={`w-full border rounded-xl p-3 text-sm font-semibold outline-none ${
                    isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                  }`}
                />
              </div>
            </div>
          </div>

          {/* Section 3: 7-Day Operating Hours */}
          <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
          }`}>
            <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
              <div className="flex items-center gap-2">
                <Clock className="w-5 h-5 text-[#FF6B00]" />
                <h3 className="font-extrabold text-sm uppercase tracking-wider">7 Günlük Çalışma Saatleri</h3>
              </div>
              <span className="text-xs text-slate-400 font-bold">Otomatik Açılış & Kapanış</span>
            </div>

            <div className="space-y-3">
              {workingHours.map((wh, idx) => (
                <div key={idx} className={`p-3.5 rounded-2xl border flex flex-col sm:flex-row sm:items-center justify-between gap-3 ${
                  isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                }`}>
                  <div className="w-28 font-extrabold text-sm">{wh.day}</div>

                  <div className="flex items-center gap-3">
                    <label className="flex items-center gap-2 text-xs font-bold cursor-pointer">
                      <input
                        type="checkbox"
                        checked={wh.isClosed}
                        onChange={(e) => handleWorkingHourChange(idx, 'isClosed', e.target.checked)}
                        className="rounded border-slate-300 text-rose-500 focus:ring-0"
                      />
                      <span className={wh.isClosed ? 'text-rose-500 font-black' : 'text-slate-400'}>
                        {wh.isClosed ? 'KAPALI (Tatil)' : 'Açık'}
                      </span>
                    </label>

                    {!wh.isClosed && (
                      <div className="flex items-center gap-2">
                        <input
                          type="time"
                          value={wh.open}
                          onChange={(e) => handleWorkingHourChange(idx, 'open', e.target.value)}
                          className={`border rounded-lg p-1.5 text-xs font-mono font-bold ${
                            isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200 text-slate-900'
                          }`}
                        />
                        <span className="text-xs text-slate-400 font-bold">-</span>
                        <input
                          type="time"
                          value={wh.close}
                          onChange={(e) => handleWorkingHourChange(idx, 'close', e.target.value)}
                          className={`border rounded-lg p-1.5 text-xs font-mono font-bold ${
                            isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200 text-slate-900'
                          }`}
                        />
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Section 4: Delivery Radius & Payout IBAN */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            
            {/* Delivery Settings */}
            <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
            }`}>
              <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                <MapPin className="w-5 h-5 text-[#00A651]" />
                <h3 className="font-extrabold text-sm uppercase tracking-wider">Teslimat Kapsamı</h3>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                    Minimum Sipariş Tutarı (₺)
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
                    Maksimum Teslimat Yarıçapı (KM)
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="50"
                    value={deliveryRadiusKm}
                    onChange={(e) => setDeliveryRadiusKm(Number(e.target.value))}
                    className={`w-full border rounded-xl p-3 text-sm font-black outline-none ${
                      isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                    }`}
                  />
                </div>
              </div>
            </div>

            {/* Payout IBAN Settings */}
            <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
            }`}>
              <div className="flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                <CreditCard className="w-5 h-5 text-indigo-500" />
                <h3 className="font-extrabold text-sm uppercase tracking-wider">Hakediş Banka Hesabı</h3>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                    TR / KKTC IBAN Numarası
                  </label>
                  <input
                    type="text"
                    value={iban}
                    onChange={(e) => setIban(e.target.value.toUpperCase())}
                    placeholder="TR00 0000 0000 0000 0000 0000 00"
                    className="w-full border border-indigo-500/50 rounded-xl p-3 text-xs font-mono font-bold text-indigo-500 outline-none bg-white dark:bg-slate-950"
                  />
                </div>
                <p className="text-[11px] text-slate-400">
                  Haftalık komisyon düşülmüş hakedişleriniz bu IBAN numarasına otomatik olarak transfer edilir.
                </p>
              </div>
            </div>

          </div>
        </form>
      </div>
    </MerchantLayout>
  );
}
