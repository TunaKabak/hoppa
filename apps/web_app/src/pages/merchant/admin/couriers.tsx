import React, { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import {
  Truck,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
  Plus,
  Trash2,
  Sparkles,
  Store,
  Navigation,
  Phone,
  ShieldCheck,
} from 'lucide-react';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import HoppaSelect from '../../../components/merchant/HoppaSelect';
import { getMerchantProfile, merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

type CourierStatusType = 'APPLIED' | 'INTERVIEWING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED';
type VehicleType = 'MOTORCYCLE' | 'CAR' | 'BICYCLE' | 'FOOT';

interface ShopSummary {
  id: string;
  name: string;
  type?: string;
}

interface CourierShopAssignment {
  id: string;
  shopId: string;
  shop: ShopSummary;
}

interface AdminCourierItem {
  id: string;
  name: string;
  phoneNumber: string;
  vehiclePlate?: string | null;
  vehicleType: VehicleType;
  status: CourierStatusType;
  isActive: boolean;
  maxServiceDistanceKm: number;
  shops: CourierShopAssignment[];
  createdAt: string;
}

interface OptimizedBatchItem {
  shopId: string;
  shopName: string;
  orders: {
    id: string;
    consumerName: string;
    status: string;
  }[];
  totalDistanceKm: number;
  estimatedPrepTimeMins: number;
  totalCostScore: number;
}

interface FleetOptimizeResponse {
  timestamp: string;
  totalBatchesCreated: number;
  batches: OptimizedBatchItem[];
}

const COURIER_STATUS_STYLES: Record<CourierStatusType, { label: string; cls: string }> = {
  APPLIED: {
    label: 'Başvuru Alındı',
    cls: 'bg-amber-500/15 text-amber-600 dark:text-amber-400 border-amber-500/30',
  },
  INTERVIEWING: {
    label: 'Mülakat Aşamasında',
    cls: 'bg-sky-500/15 text-sky-600 dark:text-sky-400 border-sky-500/30',
  },
  APPROVED: {
    label: 'Onaylı Kurye',
    cls: 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/30',
  },
  SUSPENDED: {
    label: 'Askıda',
    cls: 'bg-slate-500/15 text-slate-600 dark:text-slate-300 border-slate-500/30',
  },
  REJECTED: {
    label: 'Reddedildi',
    cls: 'bg-rose-500/15 text-rose-600 dark:text-rose-400 border-rose-500/30',
  },
};

export default function AdminCouriersPage() {
  const router = useRouter();
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [isAuthorized, setIsAuthorized] = useState(false);
  const [couriers, setCouriers] = useState<AdminCourierItem[]>([]);
  const [shops, setShops] = useState<ShopSummary[]>([]);
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [dutyFilter, setDutyFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const [assignShopMap, setAssignShopMap] = useState<Record<string, string>>({});
  const [fleetResult, setFleetResult] = useState<FleetOptimizeResponse | null>(null);
  const [isOptimizingFleet, setIsOptimizingFleet] = useState(false);

  const loadData = useCallback(async (statusVal: string, dutyVal: string) => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      const params = new URLSearchParams();
      if (statusVal !== 'ALL') params.set('status', statusVal);
      if (dutyVal !== 'ALL') params.set('isActive', dutyVal);

      const queryStr = params.toString();
      const [couriersRes, shopsRes] = await Promise.all([
        merchantApiFetch(`/admin/couriers${queryStr ? `?${queryStr}` : ''}`),
        merchantApiFetch('/consumer/shops'),
      ]);

      setCouriers(Array.isArray(couriersRes.data) ? (couriersRes.data as AdminCourierItem[]) : []);
      setShops(Array.isArray(shopsRes.data) ? (shopsRes.data as ShopSummary[]) : []);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Kurye listesi yüklenemedi.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    const profile = getMerchantProfile();
    if (!profile) {
      router.replace('/merchant/login');
      return;
    }
    if (profile.role !== 'super_admin' && profile.role !== 'admin') {
      router.replace('/merchant/dashboard');
      return;
    }
    setIsAuthorized(true);
    loadData('ALL', 'ALL');
  }, [router, loadData]);

  const handleUpdateCourierStatus = async (courierId: string, status: CourierStatusType) => {
    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      const res = await merchantApiFetch(`/admin/couriers/${courierId}/status`, {
        method: 'PUT',
        body: JSON.stringify({ status }),
      });
      setSuccessMsg(res.message || 'Kurye durumu güncellendi.');
      await loadData(statusFilter, dutyFilter);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Kurye durumu güncellenemedi.');
    }
  };

  const handleAssignShop = async (courierId: string) => {
    const shopId = assignShopMap[courierId];
    if (!shopId) {
      setErrorMsg('Lütfen atamak için bir mağaza seçiniz.');
      return;
    }
    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      const res = await merchantApiFetch(`/admin/couriers/${courierId}/shops`, {
        method: 'POST',
        body: JSON.stringify({ shopId }),
      });
      setSuccessMsg(res.message || 'Kurye mağazaya atandı.');
      setAssignShopMap((prev) => ({ ...prev, [courierId]: '' }));
      await loadData(statusFilter, dutyFilter);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Mağaza ataması yapılamadı.');
    }
  };

  const handleRemoveShop = async (courierId: string, shopId: string) => {
    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      const res = await merchantApiFetch(`/admin/couriers/${courierId}/shops/${shopId}`, {
        method: 'DELETE',
      });
      setSuccessMsg(res.message || 'Mağaza ataması kaldırıldı.');
      await loadData(statusFilter, dutyFilter);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Atama kaldırılamadı.');
    }
  };

  const handleOptimizeFleet = async () => {
    setIsOptimizingFleet(true);
    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      const res = await merchantApiFetch('/admin/fleet/optimize', { method: 'POST' });
      if (res.data) {
        setFleetResult(res.data as FleetOptimizeResponse);
      }
      setSuccessMsg(res.message || 'Filo AI optimizasyonu tamamlandı.');
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Filo optimizasyonu başarısız oldu.');
    } finally {
      setIsOptimizingFleet(false);
    }
  };

  if (!isAuthorized) {
    return null;
  }

  return (
    <MerchantLayout
      title="Kurye Yönetimi & Filo AI"
      subtitle="Kurye onayları, özel mağaza atamaları ve akıllı rota kümeleme merkezi"
      headerIcon={Truck}
      activeTab="admin-couriers"
      headerActions={
        <button
          type="button"
          onClick={handleOptimizeFleet}
          disabled={isOptimizingFleet}
          className="px-4 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black flex items-center gap-1.5 transition-colors disabled:opacity-50"
        >
          <Sparkles className={`w-3.5 h-3.5 ${isOptimizingFleet ? 'animate-spin' : ''}`} />
          <span>{isOptimizingFleet ? 'Hesaplanıyor...' : 'Filo AI Optimize Et'}</span>
        </button>
      }
    >
      <div className="space-y-6">
        {errorMsg && (
          <div className="p-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-500 text-xs font-bold flex items-center gap-2.5">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}
        {successMsg && (
          <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 dark:text-emerald-400 text-xs font-bold flex items-center gap-2.5">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        {/* Fleet AI Result Card */}
        {fleetResult && (
          <div
            className={`p-5 rounded-2xl border ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <Navigation className="w-4 h-4 text-[#FF6B00]" />
                <h3 className="text-sm font-black">Filo AI Kümeleme Sonucu</h3>
              </div>
              <span className="text-xs font-bold text-slate-400 tabular-nums">
                {fleetResult.totalBatchesCreated} Paket Grubu Oluşturuldu
              </span>
            </div>

            {fleetResult.batches.length === 0 ? (
              <p className="text-xs text-slate-400 font-semibold">
                Şu anda kurye bekleyen uygun açık sipariş kümesi bulunmuyor.
              </p>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {fleetResult.batches.map((batch, idx) => (
                  <div
                    key={`${batch.shopId}-${idx}`}
                    className={`p-3.5 rounded-xl border text-xs space-y-1.5 ${
                      isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-slate-50 border-slate-200'
                    }`}
                  >
                    <div className="flex items-center justify-between font-black">
                      <span>{batch.shopName}</span>
                      <span className="text-[#FF6B00] tabular-nums">
                        {batch.totalDistanceKm.toFixed(2)} km • ~{batch.estimatedPrepTimeMins} dk
                      </span>
                    </div>
                    <div className="text-slate-400 font-semibold tabular-nums">
                      Siparişler ({batch.orders.length}):{' '}
                      {batch.orders.map((o) => o.consumerName || o.id.slice(0, 6)).join(', ')}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Filter Bar */}
        <div
          className={`p-4 rounded-2xl border grid grid-cols-1 sm:grid-cols-3 gap-3 items-end ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
          }`}
        >
          <HoppaSelect
            label="Başvuru / Onay Durumu"
            value={statusFilter}
            onChange={(val) => {
              setStatusFilter(val);
              loadData(val, dutyFilter);
            }}
            options={[
              { value: 'ALL', label: 'Tüm Kuryeler' },
              { value: 'APPLIED', label: 'Başvuru Alındı' },
              { value: 'INTERVIEWING', label: 'Mülakat' },
              { value: 'APPROVED', label: 'Onaylı Kuryeler' },
              { value: 'SUSPENDED', label: 'Askıya Alınanlar' },
              { value: 'REJECTED', label: 'Reddedilenler' },
            ]}
          />
          <HoppaSelect
            label="Nöbet Durumu"
            value={dutyFilter}
            onChange={(val) => {
              setDutyFilter(val);
              loadData(statusFilter, val);
            }}
            options={[
              { value: 'ALL', label: 'Tümü (Aktif & Pasif)' },
              { value: 'true', label: 'Şu An Nöbette (Aktif)' },
              { value: 'false', label: 'Nöbet Dışı (Pasif)' },
            ]}
          />
          <button
            type="button"
            onClick={() => loadData(statusFilter, dutyFilter)}
            className={`py-2.5 px-4 rounded-xl border text-xs font-black flex items-center justify-center gap-1.5 ${
              isDark
                ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
                : 'bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100'
            }`}
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isLoading ? 'animate-spin' : ''}`} />
            <span>Listeyi Yenile</span>
          </button>
        </div>

        {/* Couriers List */}
        {isLoading ? (
          <div className="py-16 flex flex-col items-center justify-center gap-3 text-slate-400">
            <div className="w-6 h-6 border-2 border-[#FF6B00] border-t-transparent rounded-full animate-spin" />
            <span className="text-xs font-bold">Kuryeler yükleniyor...</span>
          </div>
        ) : couriers.length === 0 ? (
          <div
            className={`py-16 rounded-2xl border text-center space-y-2 text-slate-400 ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'
            }`}
          >
            <Truck className="w-10 h-10 mx-auto opacity-50" />
            <p className="text-sm font-bold">Kayıtlı kurye bulunamadı.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {couriers.map((courier) => {
              const badge = COURIER_STATUS_STYLES[courier.status];
              return (
                <div
                  key={courier.id}
                  className={`p-5 rounded-2xl border space-y-4 ${
                    isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
                  }`}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2">
                        <h3 className="text-sm font-black">{courier.name}</h3>
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-black ${
                            courier.isActive
                              ? 'bg-emerald-500/15 text-emerald-500'
                              : 'bg-slate-500/15 text-slate-400'
                          }`}
                        >
                          {courier.isActive ? 'NÖBETTE' : 'PASİF'}
                        </span>
                      </div>
                      <div className="text-xs text-slate-400 font-semibold flex items-center gap-3 mt-1 tabular-nums">
                        <span className="inline-flex items-center gap-1">
                          <Phone className="w-3 h-3" />
                          {courier.phoneNumber}
                        </span>
                        <span>• {courier.vehicleType}</span>
                        {courier.vehiclePlate && <span>• {courier.vehiclePlate}</span>}
                        <span>• {courier.maxServiceDistanceKm} km</span>
                      </div>
                    </div>

                    <span className={`px-2.5 py-1 rounded-full text-[11px] font-black border ${badge.cls}`}>
                      {badge.label}
                    </span>
                  </div>

                  {/* Status Switcher */}
                  <div className="flex flex-wrap items-center gap-2 pt-2 border-t border-slate-100 dark:border-slate-800">
                    {courier.status !== 'APPROVED' && (
                      <button
                        type="button"
                        onClick={() => handleUpdateCourierStatus(courier.id, 'APPROVED')}
                        className="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-[11px] font-black inline-flex items-center gap-1"
                      >
                        <ShieldCheck className="w-3.5 h-3.5" />
                        <span>Onayla</span>
                      </button>
                    )}
                    {courier.status === 'APPLIED' && (
                      <button
                        type="button"
                        onClick={() => handleUpdateCourierStatus(courier.id, 'INTERVIEWING')}
                        className="px-3 py-1.5 rounded-xl bg-sky-600 hover:bg-sky-700 text-white text-[11px] font-black"
                      >
                        Mülakata Al
                      </button>
                    )}
                    {courier.status !== 'SUSPENDED' && (
                      <button
                        type="button"
                        onClick={() => handleUpdateCourierStatus(courier.id, 'SUSPENDED')}
                        className="px-3 py-1.5 rounded-xl bg-amber-600 hover:bg-amber-700 text-white text-[11px] font-black"
                      >
                        Askıya Al
                      </button>
                    )}
                    {courier.status !== 'REJECTED' && (
                      <button
                        type="button"
                        onClick={() => handleUpdateCourierStatus(courier.id, 'REJECTED')}
                        className="px-3 py-1.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-[11px] font-black"
                      >
                        Reddet
                      </button>
                    )}
                  </div>

                  {/* Dedicated Shop Assignments */}
                  <div className="space-y-2 pt-2 border-t border-slate-100 dark:border-slate-800">
                    <div className="text-[11px] font-black uppercase tracking-wider text-slate-400">
                      Özel Atanmış Mağazalar ({courier.shops.length})
                    </div>
                    {courier.shops.length > 0 && (
                      <div className="flex flex-wrap gap-1.5">
                        {courier.shops.map((assignment) => (
                          <span
                            key={assignment.id}
                            className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-[11px] font-bold border ${
                              isDark
                                ? 'bg-slate-950 border-slate-800 text-slate-200'
                                : 'bg-slate-50 border-slate-200 text-slate-700'
                            }`}
                          >
                            <Store className="w-3 h-3 text-[#FF6B00]" />
                            <span>{assignment.shop.name}</span>
                            <button
                              type="button"
                              onClick={() => handleRemoveShop(courier.id, assignment.shopId)}
                              className="text-slate-400 hover:text-rose-500 ml-0.5"
                              title="Atamayı Kaldır"
                            >
                              <Trash2 className="w-3 h-3" />
                            </button>
                          </span>
                        ))}
                      </div>
                    )}

                    <div className="flex items-center gap-2 pt-1">
                      <div className="flex-1">
                        <HoppaSelect
                          size="sm"
                          searchable={shops.length > 5}
                          placeholder="Özel mağaza ata..."
                          value={assignShopMap[courier.id] || ''}
                          onChange={(val) =>
                            setAssignShopMap((prev) => ({ ...prev, [courier.id]: val }))
                          }
                          options={shops.map((s) => ({
                            value: s.id,
                            label: s.name,
                            badge: s.type || 'MAĞAZA',
                          }))}
                        />
                      </div>
                      <button
                        type="button"
                        onClick={() => handleAssignShop(courier.id)}
                        className="px-3 py-1.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black inline-flex items-center gap-1 shrink-0"
                      >
                        <Plus className="w-3.5 h-3.5" />
                        <span>Ata</span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </MerchantLayout>
  );
}
