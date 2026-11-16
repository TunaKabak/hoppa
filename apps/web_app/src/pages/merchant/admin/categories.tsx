import React, { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import {
  LayoutGrid,
  Plus,
  Edit3,
  Trash2,
  ArrowUp,
  ArrowDown,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
  X,
  Save,
  UtensilsCrossed,
  ShoppingBag,
  Droplet,
  Flower2,
  Leaf,
  Beef,
  Store,
  Upload,
} from 'lucide-react';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import HoppaSelect from '../../../components/merchant/HoppaSelect';
import { useConfirm, useToast } from '../../../components/merchant/ToastContext';
import { getMerchantProfile, merchantApiFetch } from '../../../utils/merchant-auth';
import { uploadMerchantMedia } from '../../../utils/media-upload';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

const COLOR_PRESETS = ['#FF6B00', '#00A651', '#2563EB', '#DB2777', '#7C3AED', '#0D9488'];

const CATEGORY_ICON_META: Record<
  string,
  { label: string; Icon: React.ComponentType<{ className?: string }> }
> = {
  restaurant: { label: 'Restoran', Icon: UtensilsCrossed },
  shopping_basket: { label: 'Market', Icon: ShoppingBag },
  water_drop: { label: 'Su Bayi', Icon: Droplet },
  local_florist: { label: 'Çiçekçi', Icon: Flower2 },
  eco: { label: 'Manav', Icon: Leaf },
  set_meal: { label: 'Kasap', Icon: Beef },
  store: { label: 'Genel', Icon: Store },
};

function renderCategoryIcon(iconKey: string) {
  const entry = CATEGORY_ICON_META[iconKey] || CATEGORY_ICON_META.store;
  const IconComp = entry.Icon;
  return <IconComp className="w-4 h-4" />;
}

interface BusinessCategoryItem {
  id: string;
  name: string;
  icon: string;
  color: string;
  badge?: string | null;
  avgDeliveryTime?: string | null;
  subtitle?: string | null;
  imageUrl?: string | null;
  isActive: boolean;
  order: number;
  shopCount?: number;
}

interface CategoryFormState {
  name: string;
  icon: string;
  color: string;
  badge: string;
  avgDeliveryTime: string;
  subtitle: string;
  imageUrl: string;
  isActive: boolean;
}

const DEFAULT_FORM: CategoryFormState = {
  name: '',
  icon: 'restaurant',
  color: '#FF6B00',
  badge: '',
  avgDeliveryTime: '25-40 dk',
  subtitle: '',
  imageUrl: '',
  isActive: true,
};

export default function AdminCategoriesPage() {
  const router = useRouter();
  const { theme } = useMerchantTheme();
  const toast = useToast();
  const { confirm } = useConfirm();
  const isDark = theme === 'dark';

  const [isAuthorized, setIsAuthorized] = useState(false);
  const [categories, setCategories] = useState<BusinessCategoryItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isUploadingImage, setIsUploadingImage] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<CategoryFormState>(DEFAULT_FORM);

  const fetchCategories = useCallback(async () => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      const res = await merchantApiFetch('/admin/business-categories');
      setCategories(Array.isArray(res.data) ? (res.data as BusinessCategoryItem[]) : []);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Kategoriler getirilemedi.');
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
    fetchCategories();
  }, [router, fetchCategories]);

  const openCreateModal = () => {
    setEditingId(null);
    setForm(DEFAULT_FORM);
    setIsModalOpen(true);
  };

  const openEditModal = (cat: BusinessCategoryItem) => {
    setEditingId(cat.id);
    setForm({
      name: cat.name,
      icon: cat.icon,
      color: cat.color,
      badge: cat.badge || '',
      avgDeliveryTime: cat.avgDeliveryTime || '',
      subtitle: cat.subtitle || '',
      imageUrl: cat.imageUrl || '',
      isActive: cat.isActive,
    });
    setIsModalOpen(true);
  };

  const handleSaveCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim() || !form.icon.trim() || !form.color.trim()) {
      const msg = 'Kategori adı, ikon ve renk kodu zorunludur.';
      setErrorMsg(msg);
      toast.warning(msg);
      return;
    }

    setIsSaving(true);
    setErrorMsg(null);
    setSuccessMsg(null);

    const payload = {
      name: form.name.trim(),
      icon: form.icon.trim(),
      color: form.color.trim(),
      badge: form.badge.trim() || null,
      avgDeliveryTime: form.avgDeliveryTime.trim() || null,
      subtitle: form.subtitle.trim() || null,
      imageUrl: form.imageUrl.trim() || null,
      isActive: form.isActive,
      ...(editingId === null ? { order: categories.length } : {}),
    };

    try {
      if (editingId) {
        await merchantApiFetch(`/admin/business-categories/${editingId}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
        setSuccessMsg('Kategori başarıyla güncellendi.');
        toast.success('Kategori başarıyla güncellendi.');
      } else {
        await merchantApiFetch('/admin/business-categories', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        setSuccessMsg('Yeni işletme kategorisi oluşturuldu.');
        toast.success('Yeni işletme kategorisi oluşturuldu.');
      }
      setIsModalOpen(false);
      await fetchCategories();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Kategori kaydedilemedi.';
      setErrorMsg(msg);
      toast.error(msg);
    } finally {
      setIsSaving(false);
    }
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setIsUploadingImage(true);
    setErrorMsg(null);
    try {
      const url = await uploadMerchantMedia(file);
      setForm((prev) => ({ ...prev, imageUrl: url }));
      toast.success('Kategori görseli yüklendi.');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Görsel yüklenemedi.';
      setErrorMsg(msg);
      toast.error(msg);
    } finally {
      setIsUploadingImage(false);
      e.target.value = '';
    }
  };

  const handleToggleActive = async (cat: BusinessCategoryItem) => {
    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      await merchantApiFetch(`/admin/business-categories/${cat.id}`, {
        method: 'PUT',
        body: JSON.stringify({ isActive: !cat.isActive }),
      });
      const msg = `${cat.name} durumu güncellendi.`;
      setSuccessMsg(msg);
      toast.success(msg);
      await fetchCategories();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Durum değiştirilemedi.';
      setErrorMsg(msg);
      toast.error(msg);
    }
  };

  const handleDelete = async (cat: BusinessCategoryItem) => {
    const ok = await confirm({
      title: 'Kategoriyi Sil',
      message: `"${cat.name}" kategorisini silmek istediğinize emin misiniz?`,
      confirmText: 'Sil',
      tone: 'danger',
    });
    if (!ok) return;

    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      const res = await merchantApiFetch(`/admin/business-categories/${cat.id}`, {
        method: 'DELETE',
      });
      const msg = res.message || 'Kategori silindi.';
      setSuccessMsg(msg);
      toast.success(msg);
      await fetchCategories();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Kategori silinemedi.';
      setErrorMsg(msg);
      toast.error(msg);
    }
  };

  const handleMove = async (index: number, direction: 'up' | 'down') => {
    const targetIndex = direction === 'up' ? index - 1 : index + 1;
    if (targetIndex < 0 || targetIndex >= categories.length) return;

    const reordered = [...categories];
    const current = reordered[index];
    reordered[index] = reordered[targetIndex];
    reordered[targetIndex] = current;

    const ordersPayload = reordered.map((item, idx) => ({
      id: item.id,
      order: idx,
    }));

    setErrorMsg(null);
    try {
      await merchantApiFetch('/admin/business-categories/reorder', {
        method: 'PUT',
        body: JSON.stringify({ orders: ordersPayload }),
      });
      setCategories(reordered.map((item, idx) => ({ ...item, order: idx })));
      setSuccessMsg('Kategori sıralaması güncellendi.');
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Sıralama güncellenemedi.');
    }
  };

  if (!isAuthorized) {
    return null;
  }

  return (
    <MerchantLayout
      title="İşletme Kategorileri"
      subtitle="Tüketici uygulamasındaki ana işletme kategorilerini, rozetlerini ve gösterim sırasını yönetin"
      headerIcon={LayoutGrid}
      activeTab="admin-categories"
      headerActions={
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={fetchCategories}
            disabled={isLoading}
            className={`px-3 py-2 rounded-xl border text-xs font-black flex items-center gap-1.5 ${
              isDark
                ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
                : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
            }`}
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isLoading ? 'animate-spin' : ''}`} />
            <span>Yenile</span>
          </button>
          <button
            type="button"
            onClick={openCreateModal}
            className="px-4 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black flex items-center gap-1.5"
          >
            <Plus className="w-4 h-4" />
            <span>Yeni Kategori</span>
          </button>
        </div>
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

        <div
          className={`rounded-2xl border overflow-hidden ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
          }`}
        >
          {isLoading ? (
            <div className="py-16 flex flex-col items-center justify-center gap-3 text-slate-400">
              <div className="w-6 h-6 border-2 border-[#FF6B00] border-t-transparent rounded-full animate-spin" />
              <span className="text-xs font-bold">Kategoriler yükleniyor...</span>
            </div>
          ) : categories.length === 0 ? (
            <div className="py-16 text-center space-y-2 text-slate-400">
              <LayoutGrid className="w-10 h-10 mx-auto opacity-50" />
              <p className="text-sm font-bold">Henüz işletme kategorisi tanımlanmamış.</p>
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
                    <th className="py-3.5 px-4">Sıra</th>
                    <th className="py-3.5 px-4">Kategori</th>
                    <th className="py-3.5 px-4">Rozet & Süre</th>
                    <th className="py-3.5 px-4">Aktif Dükkan</th>
                    <th className="py-3.5 px-4">Durum</th>
                    <th className="py-3.5 px-4 text-right">İşlemler</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800 text-xs">
                  {categories.map((cat, index) => (
                    <tr
                      key={cat.id}
                      className={isDark ? 'hover:bg-slate-800/40' : 'hover:bg-slate-50/70'}
                    >
                      <td className="py-3.5 px-4">
                        <div className="inline-flex items-center gap-1">
                          <span className="w-6 font-black tabular-nums text-slate-400">
                            {index + 1}
                          </span>
                          <button
                            type="button"
                            disabled={index === 0}
                            onClick={() => handleMove(index, 'up')}
                            className="p-1 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-700 disabled:opacity-30"
                            title="Yukarı Taşı"
                          >
                            <ArrowUp className="w-3.5 h-3.5" />
                          </button>
                          <button
                            type="button"
                            disabled={index === categories.length - 1}
                            onClick={() => handleMove(index, 'down')}
                            className="p-1 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-700 disabled:opacity-30"
                            title="Aşağı Taşı"
                          >
                            <ArrowDown className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </td>
                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-3">
                          <span
                            className="w-8 h-8 rounded-xl flex items-center justify-center text-white font-black text-xs shrink-0"
                            style={{ backgroundColor: cat.color || '#FF6B00' }}
                          >
                            {renderCategoryIcon(cat.icon)}
                          </span>
                          <div>
                            <div className="font-black text-sm">{cat.name}</div>
                            <div className="text-[11px] text-slate-400">
                              {cat.subtitle || CATEGORY_ICON_META[cat.icon]?.label || 'Genel'}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="py-3.5 px-4">
                        <div className="flex flex-wrap items-center gap-1.5">
                          {cat.badge ? (
                            <span className="px-2 py-0.5 rounded-md text-[11px] font-semibold border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 text-slate-600 dark:text-slate-300">
                              {cat.badge}
                            </span>
                          ) : (
                            <span className="text-slate-400">-</span>
                          )}
                          {cat.avgDeliveryTime && (
                            <span className="text-[11px] text-slate-400 tabular-nums">
                              • {cat.avgDeliveryTime}
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="py-3.5 px-4 font-black tabular-nums">
                        {cat.shopCount ?? 0} dükkan
                      </td>
                      <td className="py-3.5 px-4">
                        <button
                          type="button"
                          onClick={() => handleToggleActive(cat)}
                          className={`px-2.5 py-1 rounded-md border text-[11px] font-semibold inline-flex items-center gap-1.5 transition-colors ${
                            isDark
                              ? 'bg-slate-950/80 border-slate-800 text-slate-200 hover:border-slate-700'
                              : 'bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100'
                          }`}
                        >
                          <span
                            className={`w-1.5 h-1.5 rounded-full shrink-0 ${
                              cat.isActive ? 'bg-[#00A651]' : 'bg-slate-400'
                            }`}
                            aria-hidden="true"
                          />
                          <span>{cat.isActive ? 'Aktif' : 'Pasif'}</span>
                        </button>
                      </td>
                      <td className="py-3.5 px-4 text-right">
                        <div className="inline-flex items-center gap-2">
                          <button
                            type="button"
                            onClick={() => openEditModal(cat)}
                            className={`px-3 py-1.5 rounded-xl border text-[11px] font-black inline-flex items-center gap-1 ${
                              isDark
                                ? 'border-slate-700 text-slate-200 hover:bg-slate-800'
                                : 'border-slate-200 text-slate-700 hover:bg-slate-100'
                            }`}
                          >
                            <Edit3 className="w-3.5 h-3.5" />
                            <span>Düzenle</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => handleDelete(cat)}
                            className="p-1.5 rounded-xl text-rose-500 hover:bg-rose-500/10"
                            title="Sil"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Create/Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4">
          <form
            onSubmit={handleSaveCategory}
            className={`w-full max-w-lg rounded-3xl border p-6 shadow-2xl space-y-4 ${
              isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900'
            }`}
          >
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <h3 className="text-base font-black">
                {editingId ? 'Kategoriyi Düzenle' : 'Yeni İşletme Kategorisi'}
              </h3>
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                className="p-2 rounded-xl text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
              <div>
                <label className="block text-[11px] font-black uppercase text-slate-400 mb-1">
                  Kategori Adı
                </label>
                <input
                  type="text"
                  required
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="Örn: Restoran, Market, Manav"
                  className={`w-full px-3 py-2.5 rounded-xl border font-semibold outline-none ${
                    isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                  }`}
                />
              </div>

              <HoppaSelect
                label="İkon Kodu"
                value={form.icon}
                onChange={(val) => setForm({ ...form, icon: val })}
                options={[
                  { value: 'restaurant', label: 'Restoran (restaurant)' },
                  { value: 'shopping_basket', label: 'Market (shopping_basket)' },
                  { value: 'water_drop', label: 'Su Bayi (water_drop)' },
                  { value: 'local_florist', label: 'Çiçek (local_florist)' },
                  { value: 'eco', label: 'Manav (eco)' },
                  { value: 'set_meal', label: 'Kasap (set_meal)' },
                  { value: 'store', label: 'Genel (store)' },
                ]}
              />

              <div>
                <label className="block text-[11px] font-black text-slate-400 mb-1">
                  Tema Rengi (Hex)
                </label>
                <div className="flex items-center gap-2">
                  <input
                    type="color"
                    aria-label="Kategori tema rengi seçici"
                    value={/^#[0-9A-Fa-f]{6}$/.test(form.color) ? form.color : '#FF6B00'}
                    onChange={(e) => setForm({ ...form, color: e.target.value })}
                    className="w-10 h-10 rounded-xl border border-slate-200 dark:border-slate-700 bg-transparent cursor-pointer shrink-0 p-0.5"
                  />
                  <input
                    type="text"
                    required
                    value={form.color}
                    onChange={(e) => setForm({ ...form, color: e.target.value })}
                    placeholder="#FF6B00"
                    className={`w-full px-3 py-2.5 rounded-xl border font-semibold tabular-nums outline-none ${
                      isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                    }`}
                  />
                </div>
                <div className="flex items-center gap-1.5 mt-2">
                  {COLOR_PRESETS.map((preset) => (
                    <button
                      key={preset}
                      type="button"
                      onClick={() => setForm({ ...form, color: preset })}
                      aria-label={`Renk ${preset}`}
                      className={`w-5 h-5 rounded-full border-2 transition-transform hover:scale-110 ${
                        form.color.toUpperCase() === preset
                          ? 'border-slate-900 dark:border-white scale-110'
                          : 'border-transparent'
                      }`}
                      style={{ backgroundColor: preset }}
                    />
                  ))}
                </div>
              </div>

              <HoppaSelect
                label="Rozet (Badge)"
                value={form.badge}
                onChange={(val) => setForm({ ...form, badge: val })}
                options={[
                  { value: '', label: 'Otomatik Hesapla' },
                  { value: 'yakında', label: 'yakında (Giriş Kilitli)' },
                  { value: 'yeni', label: 'yeni' },
                  { value: 'popüler', label: 'popüler' },
                ]}
              />

              <div>
                <label className="block text-[11px] font-black text-slate-400 mb-1">
                  Ort. Teslimat Süresi
                </label>
                <input
                  type="text"
                  value={form.avgDeliveryTime}
                  onChange={(e) => setForm({ ...form, avgDeliveryTime: e.target.value })}
                  placeholder="25-40 dk"
                  className={`w-full px-3 py-2.5 rounded-xl border font-semibold outline-none ${
                    isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                  }`}
                />
              </div>

              <div>
                <label className="block text-[11px] font-black text-slate-400 mb-1">
                  Alt Başlık
                </label>
                <input
                  type="text"
                  value={form.subtitle}
                  onChange={(e) => setForm({ ...form, subtitle: e.target.value })}
                  placeholder="Sıcak yemekler & kafeler"
                  className={`w-full px-3 py-2.5 rounded-xl border font-semibold outline-none ${
                    isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                  }`}
                />
              </div>
            </div>

            <div className="text-xs">
              <label className="block text-[11px] font-black text-slate-400 mb-1">
                Görsel URL veya Dosya Yükleme (Opsiyonel)
              </label>
              <div className="flex flex-col sm:flex-row gap-2">
                <input
                  type="text"
                  value={form.imageUrl}
                  onChange={(e) => setForm({ ...form, imageUrl: e.target.value })}
                  placeholder="https://..."
                  className={`flex-1 px-3 py-2.5 rounded-xl border font-semibold outline-none ${
                    isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                  }`}
                />
                <label className="px-3.5 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-900 dark:bg-slate-700 text-white font-black text-xs inline-flex items-center justify-center gap-1.5 cursor-pointer shrink-0 transition-colors">
                  <Upload className="w-3.5 h-3.5" />
                  <span>{isUploadingImage ? 'Yükleniyor...' : 'Dosya Yükle'}</span>
                  <input
                    type="file"
                    accept="image/*"
                    disabled={isUploadingImage}
                    onChange={handleImageUpload}
                    className="hidden"
                  />
                </label>
              </div>
            </div>

            <label className="flex items-center gap-2 text-xs font-bold cursor-pointer">
              <input
                type="checkbox"
                checked={form.isActive}
                onChange={(e) => setForm({ ...form, isActive: e.target.checked })}
                className="rounded border-slate-300 text-[#FF6B00] focus:ring-0"
              />
              <span>Tüketici Uygulamasında Aktif Görünsün</span>
            </label>

            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                className="px-4 py-2 rounded-xl border border-slate-300 dark:border-slate-700 text-xs font-black"
              >
                Vazgeç
              </button>
              <button
                type="submit"
                disabled={isSaving}
                className="px-4 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black inline-flex items-center gap-1.5 disabled:opacity-50"
              >
                <Save className="w-3.5 h-3.5" />
                <span>{isSaving ? 'Kaydediliyor...' : 'Kaydet'}</span>
              </button>
            </div>
          </form>
        </div>
      )}
    </MerchantLayout>
  );
}
