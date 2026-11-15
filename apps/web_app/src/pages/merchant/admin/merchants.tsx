import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/router';
import {
  Building2,
  Search,
  CheckCircle2,
  XCircle,
  Clock,
  PauseCircle,
  Edit3,
  Store,
  RefreshCw,
  AlertCircle,
  Phone,
  Mail,
  MapPin,
  FileText,
  ExternalLink,
  X,
} from 'lucide-react';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import HoppaSelect from '../../../components/merchant/HoppaSelect';
import {
  getMerchantProfile,
  merchantApiFetch,
  setSelectedShopId,
} from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

type MerchantStatusType = 'PENDING' | 'ACTIVE' | 'REVISION' | 'REJECTED' | 'ON_HOLD';
type StatusFilterType = 'PENDING_GROUP' | 'ALL' | MerchantStatusType;

interface AdminMerchantShop {
  id: string;
  name: string;
  isActive: boolean;
  type: string;
}

interface AdminMerchantItem {
  id: string;
  email: string;
  businessName: string;
  msNumber?: string | null;
  taxNumber?: string | null;
  phone?: string | null;
  district?: string | null;
  fullAddress?: string | null;
  status: MerchantStatusType;
  revisionMessage?: string | null;
  role: string;
  ownerFirstName: string;
  ownerLastName: string;
  ownerPhone: string;
  businessPhone: string;
  merchantType: string;
  subType?: string | null;
  hasHardware: boolean;
  countryCode: string;
  createdAt: string;
  shop?: AdminMerchantShop | null;
}

const STATUS_BADGE_MAP: Record<
  MerchantStatusType,
  { label: string; className: string }
> = {
  PENDING: {
    label: 'Onay Bekliyor',
    className: 'bg-amber-500/15 text-amber-600 dark:text-amber-400 border-amber-500/30',
  },
  ACTIVE: {
    label: 'Aktif İşletme',
    className: 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/30',
  },
  REVISION: {
    label: 'Revizyon İstendi',
    className: 'bg-sky-500/15 text-sky-600 dark:text-sky-400 border-sky-500/30',
  },
  ON_HOLD: {
    label: 'Askıda',
    className: 'bg-slate-500/15 text-slate-600 dark:text-slate-300 border-slate-500/30',
  },
  REJECTED: {
    label: 'Reddedildi',
    className: 'bg-rose-500/15 text-rose-600 dark:text-rose-400 border-rose-500/30',
  },
};

export default function AdminMerchantsPage() {
  const router = useRouter();
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [isAuthorized, setIsAuthorized] = useState(false);
  const [merchants, setMerchants] = useState<AdminMerchantItem[]>([]);
  const [statusFilter, setStatusFilter] = useState<StatusFilterType>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const [selectedMerchant, setSelectedMerchant] = useState<AdminMerchantItem | null>(null);
  const [revisionNote, setRevisionNote] = useState('');
  const [isUpdatingId, setIsUpdatingId] = useState<string | null>(null);

  const fetchMerchants = useCallback(async (filter: StatusFilterType, search: string) => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      const params = new URLSearchParams();
      params.set('status', filter);
      if (search.trim()) {
        params.set('search', search.trim());
      }
      const res = await merchantApiFetch(`/admin/merchants/pending?${params.toString()}`);
      if (Array.isArray(res.data)) {
        setMerchants(res.data as AdminMerchantItem[]);
      } else {
        setMerchants([]);
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'İşletmeler yüklenemedi.';
      setErrorMsg(message);
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
    fetchMerchants('ALL', '');
  }, [router, fetchMerchants]);

  const handleStatusUpdate = async (
    merchantId: string,
    nextStatus: MerchantStatusType,
    note?: string
  ) => {
    if (nextStatus === 'REVISION' && (!note || !note.trim())) {
      setErrorMsg('Revizyon talebi göndermek için açıklama notu girmelisiniz.');
      return;
    }

    setIsUpdatingId(merchantId);
    setErrorMsg(null);
    setSuccessMsg(null);

    try {
      const res = await merchantApiFetch(`/admin/merchants/${merchantId}/status`, {
        method: 'PUT',
        body: JSON.stringify({
          status: nextStatus,
          ...(note !== undefined ? { revisionMessage: note.trim() } : {}),
        }),
      });
      setSuccessMsg(res.message || 'İşletme durumu başarıyla güncellendi.');
      setSelectedMerchant(null);
      setRevisionNote('');
      await fetchMerchants(statusFilter, searchQuery);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'İşletme durumu güncellenemedi.';
      setErrorMsg(message);
    } finally {
      setIsUpdatingId(null);
    }
  };

  const handleManageShop = (shopId: string) => {
    setSelectedShopId(shopId);
    router.push('/merchant/dashboard');
  };

  const kpiStats = useMemo(() => {
    return {
      total: merchants.length,
      pending: merchants.filter((m) => m.status === 'PENDING' || m.status === 'REVISION').length,
      active: merchants.filter((m) => m.status === 'ACTIVE').length,
      holdOrRejected: merchants.filter((m) => m.status === 'ON_HOLD' || m.status === 'REJECTED').length,
    };
  }, [merchants]);

  if (!isAuthorized) {
    return null;
  }

  return (
    <MerchantLayout
      title="İşletme Başvuruları & Yönetimi"
      subtitle="Satıcı başvurularını inceleyin, onaylayın veya mağaza bağlamında yönetin"
      headerIcon={Building2}
      activeTab="admin-merchants"
      headerActions={
        <button
          type="button"
          onClick={() => fetchMerchants(statusFilter, searchQuery)}
          disabled={isLoading}
          className={`px-3 py-2 rounded-xl border text-xs font-black flex items-center gap-1.5 transition-colors ${
            isDark
              ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
              : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
          }`}
        >
          <RefreshCw className={`w-3.5 h-3.5 ${isLoading ? 'animate-spin' : ''}`} />
          <span>Yenile</span>
        </button>
      }
    >
      <div className="space-y-6">
        {/* KPI Row */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { label: 'Listelenen İşletme', value: kpiStats.total, icon: Building2, color: 'text-[#FF6B00]' },
            { label: 'Onay / Revizyon Bekleyen', value: kpiStats.pending, icon: Clock, color: 'text-amber-500' },
            { label: 'Aktif İşletmeler', value: kpiStats.active, icon: CheckCircle2, color: 'text-emerald-500' },
            { label: 'Askıda / Reddedilen', value: kpiStats.holdOrRejected, icon: PauseCircle, color: 'text-rose-500' },
          ].map((stat) => {
            const Icon = stat.icon;
            return (
              <div
                key={stat.label}
                className={`p-4 rounded-2xl border ${
                  isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                    {stat.label}
                  </span>
                  <Icon className={`w-4 h-4 ${stat.color}`} />
                </div>
                <p className="text-2xl font-black tabular-nums">{stat.value}</p>
              </div>
            );
          })}
        </div>

        {/* Alerts */}
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

        {/* Filter Bar */}
        <div
          className={`p-4 rounded-2xl border flex flex-col sm:flex-row gap-3 items-stretch sm:items-center justify-between ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
          }`}
        >
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  fetchMerchants(statusFilter, searchQuery);
                }
              }}
              placeholder="İşletme adı, e-posta veya yetkili adı ara..."
              className={`w-full pl-10 pr-4 py-2.5 rounded-xl border text-xs font-semibold outline-none transition-colors ${
                isDark
                  ? 'bg-slate-950 border-slate-800 text-white focus:border-[#FF6B00]'
                  : 'bg-slate-50 border-slate-200 text-slate-900 focus:border-[#FF6B00]'
              }`}
            />
          </div>

          <div className="w-full sm:w-64">
            <HoppaSelect
              value={statusFilter}
              onChange={(val) => {
                const next = val as StatusFilterType;
                setStatusFilter(next);
                fetchMerchants(next, searchQuery);
              }}
              options={[
                { value: 'ALL', label: 'Tüm İşletmeler' },
                { value: 'PENDING_GROUP', label: 'Bekleyen / Revizyon / Askıda' },
                { value: 'PENDING', label: 'Sadece Onay Bekleyenler' },
                { value: 'ACTIVE', label: 'Aktif İşletmeler' },
                { value: 'REVISION', label: 'Revizyon Bekleyenler' },
                { value: 'ON_HOLD', label: 'Askıya Alınanlar' },
                { value: 'REJECTED', label: 'Reddedilenler' },
              ]}
            />
          </div>

          <button
            type="button"
            onClick={() => fetchMerchants(statusFilter, searchQuery)}
            className="px-4 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black transition-colors shrink-0"
          >
            Filtrele
          </button>
        </div>

        {/* Table */}
        <div
          className={`rounded-2xl border overflow-hidden ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
          }`}
        >
          {isLoading ? (
            <div className="py-16 flex flex-col items-center justify-center gap-3 text-slate-400">
              <div className="w-6 h-6 border-2 border-[#FF6B00] border-t-transparent rounded-full animate-spin" />
              <span className="text-xs font-bold">İşletme kayıtları yükleniyor...</span>
            </div>
          ) : merchants.length === 0 ? (
            <div className="py-16 text-center space-y-2 text-slate-400">
              <Building2 className="w-10 h-10 mx-auto opacity-50" />
              <p className="text-sm font-bold">Seçili filtreye uygun işletme bulunamadı.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr
                    className={`border-b text-[11px] font-black uppercase tracking-wider text-slate-400 ${
                      isDark ? 'bg-slate-950/50 border-slate-800' : 'bg-slate-50 border-slate-200'
                    }`}
                  >
                    <th className="py-3.5 px-4">İşletme & Yetkili</th>
                    <th className="py-3.5 px-4">Tür & Bölge</th>
                    <th className="py-3.5 px-4">Durum</th>
                    <th className="py-3.5 px-4">Kayıt Tarihi</th>
                    <th className="py-3.5 px-4 text-right">İşlemler</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800 text-xs">
                  {merchants.map((m) => {
                    const badge = STATUS_BADGE_MAP[m.status];
                    return (
                      <tr
                        key={m.id}
                        className={isDark ? 'hover:bg-slate-800/40' : 'hover:bg-slate-50/70'}
                      >
                        <td className="py-3.5 px-4">
                          <div className="font-black text-sm">{m.businessName}</div>
                          <div className="text-slate-400 font-semibold mt-0.5">
                            {m.ownerFirstName || m.ownerLastName
                              ? `${m.ownerFirstName} ${m.ownerLastName}`.trim()
                              : m.email}
                          </div>
                          <div className="text-[11px] text-slate-400">{m.email}</div>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="px-2 py-0.5 rounded-md text-[10px] font-black bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                            {m.merchantType}
                          </span>
                          <div className="text-[11px] text-slate-400 mt-1">
                            {m.district || 'Bölge belirtilmedi'}
                          </div>
                        </td>
                        <td className="py-3.5 px-4">
                          <span
                            className={`inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-black border ${badge.className}`}
                          >
                            {badge.label}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 font-semibold text-slate-400 tabular-nums">
                          {new Date(m.createdAt).toLocaleDateString('tr-TR')}
                        </td>
                        <td className="py-3.5 px-4 text-right">
                          <div className="inline-flex items-center gap-2">
                            {m.shop?.id && (
                              <button
                                type="button"
                                onClick={() => handleManageShop(m.shop!.id)}
                                className="px-3 py-1.5 rounded-xl bg-orange-500/10 text-[#FF6B00] hover:bg-orange-500/20 font-black text-[11px] inline-flex items-center gap-1 transition-colors"
                                title="Bu mağaza bağlamına geç"
                              >
                                <Store className="w-3.5 h-3.5" />
                                <span>Mağazayı Yönet</span>
                              </button>
                            )}
                            <button
                              type="button"
                              onClick={() => {
                                setSelectedMerchant(m);
                                setRevisionNote(m.revisionMessage || '');
                              }}
                              className={`px-3 py-1.5 rounded-xl border font-black text-[11px] inline-flex items-center gap-1 transition-colors ${
                                isDark
                                  ? 'border-slate-700 text-slate-200 hover:bg-slate-800'
                                  : 'border-slate-200 text-slate-700 hover:bg-slate-100'
                              }`}
                            >
                              <ExternalLink className="w-3.5 h-3.5" />
                              <span>İncele</span>
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Inspection Modal */}
      {selectedMerchant && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div
            className={`w-full max-w-xl rounded-3xl border p-6 shadow-2xl space-y-5 max-h-[90vh] overflow-y-auto ${
              isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900'
            }`}
          >
            <div className="flex items-start justify-between gap-4 border-b border-slate-100 dark:border-slate-800 pb-4">
              <div>
                <h3 className="text-lg font-black">{selectedMerchant.businessName}</h3>
                <p className="text-xs text-slate-400 font-semibold mt-0.5">
                  İşletme Başvuru ve Durum Yönetimi
                </p>
              </div>
              <button
                type="button"
                onClick={() => setSelectedMerchant(null)}
                className="p-2 rounded-xl text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
              <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-950/60 space-y-1">
                <div className="text-slate-400 font-bold flex items-center gap-1.5">
                  <Mail className="w-3.5 h-3.5" /> E-Posta
                </div>
                <div className="font-bold">{selectedMerchant.email}</div>
              </div>
              <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-950/60 space-y-1">
                <div className="text-slate-400 font-bold flex items-center gap-1.5">
                  <Phone className="w-3.5 h-3.5" /> İletişim
                </div>
                <div className="font-bold tabular-nums">
                  {selectedMerchant.businessPhone || selectedMerchant.ownerPhone || selectedMerchant.phone || '-'}
                </div>
              </div>
              <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-950/60 space-y-1">
                <div className="text-slate-400 font-bold flex items-center gap-1.5">
                  <FileText className="w-3.5 h-3.5" /> Vergi / Şirket No
                </div>
                <div className="font-bold tabular-nums">
                  {selectedMerchant.taxNumber || '-'} / {selectedMerchant.msNumber || '-'}
                </div>
              </div>
              <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-950/60 space-y-1">
                <div className="text-slate-400 font-bold flex items-center gap-1.5">
                  <MapPin className="w-3.5 h-3.5" /> Adres & Bölge
                </div>
                <div className="font-bold">
                  {selectedMerchant.district || '-'} — {selectedMerchant.fullAddress || '-'}
                </div>
              </div>
            </div>

            <div>
              <label className="block text-[11px] font-black uppercase tracking-wider text-slate-400 mb-1.5">
                Revizyon / Yönetici Notu
              </label>
              <textarea
                rows={3}
                value={revisionNote}
                onChange={(e) => setRevisionNote(e.target.value)}
                placeholder="Revizyon gerekiyorsa eksik belgeleri veya düzeltme notunu yazın..."
                className={`w-full p-3 rounded-xl border text-xs font-semibold outline-none ${
                  isDark
                    ? 'bg-slate-950 border-slate-800 text-white focus:border-[#FF6B00]'
                    : 'bg-slate-50 border-slate-200 text-slate-900 focus:border-[#FF6B00]'
                }`}
              />
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-2">
              <button
                type="button"
                disabled={isUpdatingId === selectedMerchant.id}
                onClick={() => handleStatusUpdate(selectedMerchant.id, 'ACTIVE')}
                className="py-2.5 px-3 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-black flex items-center justify-center gap-1.5 disabled:opacity-50"
              >
                <CheckCircle2 className="w-4 h-4" />
                <span>Onayla</span>
              </button>
              <button
                type="button"
                disabled={isUpdatingId === selectedMerchant.id}
                onClick={() => handleStatusUpdate(selectedMerchant.id, 'REVISION', revisionNote)}
                className="py-2.5 px-3 rounded-xl bg-sky-600 hover:bg-sky-700 text-white text-xs font-black flex items-center justify-center gap-1.5 disabled:opacity-50"
              >
                <Edit3 className="w-4 h-4" />
                <span>Revizyon</span>
              </button>
              <button
                type="button"
                disabled={isUpdatingId === selectedMerchant.id}
                onClick={() => handleStatusUpdate(selectedMerchant.id, 'ON_HOLD', revisionNote)}
                className="py-2.5 px-3 rounded-xl bg-amber-600 hover:bg-amber-700 text-white text-xs font-black flex items-center justify-center gap-1.5 disabled:opacity-50"
              >
                <PauseCircle className="w-4 h-4" />
                <span>Askıya Al</span>
              </button>
              <button
                type="button"
                disabled={isUpdatingId === selectedMerchant.id}
                onClick={() => handleStatusUpdate(selectedMerchant.id, 'REJECTED', revisionNote)}
                className="py-2.5 px-3 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-black flex items-center justify-center gap-1.5 disabled:opacity-50"
              >
                <XCircle className="w-4 h-4" />
                <span>Reddet</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </MerchantLayout>
  );
}
