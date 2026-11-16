import React, { useState, useEffect, useMemo, useCallback } from 'react';
import Head from 'next/head';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import ProductModal from '../../../components/merchant/product-modal';
import OptionGroupBuilder from '../../../components/merchant/option-group-builder';
import CatalogImportModal from '../../../components/merchant/catalog-import-modal';
import HoppaSelect from '../../../components/merchant/HoppaSelect';
import SlideOverDrawer from '../../../components/merchant/SlideOverDrawer';
import { useConfirm, useToast } from '../../../components/merchant/ToastContext';
import {
  Package,
  Plus,
  Search,
  Layers,
  Database,
  Edit,
  Trash2,
  Check,
  DollarSign,
  LayoutGrid,
  List,
  Download,
  FolderTree,
  ArrowUpDown,
  Save,
  X,
} from 'lucide-react';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

type SortField = 'name' | 'price' | 'stock';
type SortDirection = 'asc' | 'desc';

export default function MerchantProductsPage() {
  const { theme } = useMerchantTheme();
  const toast = useToast();
  const { confirm } = useConfirm();
  const isDark = theme === 'dark';

  const [products, setProducts] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Filters, Sorting & View State
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('ALL');
  const [stockFilter, setStockFilter] = useState('ALL');
  const [viewMode, setViewMode] = useState<'table' | 'grid'>('table');
  const [sortBy, setSortBy] = useState<SortField>('name');
  const [sortDir, setSortDir] = useState<SortDirection>('asc');

  // Bulk Selection
  const [selectedProductIds, setSelectedProductIds] = useState<string[]>([]);
  const [isBulkProcessing, setIsBulkProcessing] = useState(false);
  const [showBulkPriceModal, setShowBulkPriceModal] = useState(false);
  const [bulkPriceType, setBulkPriceType] = useState<
    'PERCENTAGE_INCREASE' | 'PERCENTAGE_DECREASE' | 'FIXED_ADD'
  >('PERCENTAGE_INCREASE');
  const [bulkPriceValue, setBulkPriceValue] = useState<number>(10);

  // Modals / Drawers
  const [activeProductForEdit, setActiveProductForEdit] = useState<any | null>(null);
  const [showProductModal, setShowProductModal] = useState(false);
  const [activeProductForOptions, setActiveProductForOptions] = useState<any | null>(null);
  const [showOptionBuilder, setShowOptionBuilder] = useState(false);
  const [showCatalogImport, setShowCatalogImport] = useState(false);

  // Category Management Drawer State
  const [showCategoryDrawer, setShowCategoryDrawer] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState('');
  const [editingCategoryId, setEditingCategoryId] = useState<string | null>(null);
  const [editingCategoryName, setEditingCategoryName] = useState('');
  const [isSavingCategory, setIsSavingCategory] = useState(false);

  // Inline Price Editing state
  const [editingPriceId, setEditingPriceId] = useState<string | null>(null);
  const [editingPriceVal, setEditingPriceVal] = useState<string>('');

  const fetchProducts = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await merchantApiFetch('/merchant/products');
      if (res.data) {
        setProducts(res.data);
      }
    } catch (err: any) {
      console.error('Ürünler yüklenirken hata:', err);
      toast.error(err.message || 'Ürünler yüklenemedi.');
    } finally {
      setIsLoading(false);
    }
  }, [toast]);

  const fetchCategories = useCallback(async () => {
    try {
      const res = await merchantApiFetch('/merchant/categories');
      if (res.data) {
        setCategories(res.data);
      }
    } catch (err) {
      console.error('Kategoriler alınamadı:', err);
    }
  }, []);

  useEffect(() => {
    void fetchProducts();
    void fetchCategories();
  }, [fetchProducts, fetchCategories]);

  // Filtered & Sorted Products
  const filteredProducts = useMemo(() => {
    const filtered = products.filter((p) => {
      const q = searchQuery.trim().toLocaleLowerCase('tr-TR');
      const matchesSearch =
        !q ||
        String(p.name || '').toLocaleLowerCase('tr-TR').includes(q) ||
        (p.barcode && String(p.barcode).includes(searchQuery));

      const matchesCategory =
        selectedCategory === 'ALL' ||
        p.categoryId === selectedCategory ||
        p.category?.id === selectedCategory;

      let matchesStock = true;
      if (stockFilter === 'ACTIVE') matchesStock = p.isActive === true;
      if (stockFilter === 'INACTIVE') matchesStock = p.isActive === false;
      if (stockFilter === 'TRACKED_LOW') {
        matchesStock = p.trackStock && (p.stockQuantity || 0) <= 5;
      }

      return matchesSearch && matchesCategory && matchesStock;
    });

    return [...filtered].sort((a, b) => {
      const dir = sortDir === 'asc' ? 1 : -1;
      if (sortBy === 'price') {
        return (Number(a.price || 0) - Number(b.price || 0)) * dir;
      }
      if (sortBy === 'stock') {
        const stockA = a.isActive ? (a.trackStock ? Number(a.stockQuantity || 0) : 99999) : -1;
        const stockB = b.isActive ? (b.trackStock ? Number(b.stockQuantity || 0) : 99999) : -1;
        return (stockA - stockB) * dir;
      }
      return String(a.name || '').localeCompare(String(b.name || ''), 'tr-TR') * dir;
    });
  }, [products, searchQuery, selectedCategory, stockFilter, sortBy, sortDir]);

  const handleSort = (field: SortField) => {
    if (sortBy === field) {
      setSortDir((prev) => (prev === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortBy(field);
      setSortDir('asc');
    }
  };

  // Toggle Single Product Stock Status
  const handleToggleProductActive = async (product: any) => {
    try {
      const newActive = !product.isActive;
      await merchantApiFetch(`/merchant/products/${product.id}`, {
        method: 'PUT',
        body: JSON.stringify({ isActive: newActive }),
      });
      setProducts((prev) =>
        prev.map((item) => (item.id === product.id ? { ...item, isActive: newActive } : item))
      );
      toast.success(
        `"${product.name}" ${newActive ? 'satışa açıldı' : 'satışa kapatıldı'}.`
      );
    } catch (err: any) {
      toast.error(err.message || 'Ürün durumu değiştirilemedi.');
    }
  };

  // Delete Product
  const handleDeleteProduct = async (product: any) => {
    const ok = await confirm({
      title: 'Ürünü Sil',
      message: `"${product.name}" ürününü menünüzden kalıcı olarak silmek istediğinize emin misiniz?`,
      confirmText: 'Ürünü Sil',
      tone: 'danger',
    });
    if (!ok) return;

    try {
      await merchantApiFetch(`/merchant/products/${product.id}`, {
        method: 'DELETE',
      });
      setProducts((prev) => prev.filter((item) => item.id !== product.id));
      setSelectedProductIds((prev) => prev.filter((id) => id !== product.id));
      toast.info(`"${product.name}" silindi.`);
    } catch (err: any) {
      toast.error(err.message || 'Ürün silinirken hata oluştu.');
    }
  };

  // Inline Price Save
  const handleSaveInlinePrice = async (productId: string) => {
    const val = Number(editingPriceVal);
    if (isNaN(val) || val <= 0) {
      setEditingPriceId(null);
      return;
    }

    try {
      await merchantApiFetch(`/merchant/products/${productId}`, {
        method: 'PUT',
        body: JSON.stringify({ price: val }),
      });
      setProducts((prev) =>
        prev.map((item) => (item.id === productId ? { ...item, price: val } : item))
      );
      toast.success('Ürün fiyatı güncellendi.');
    } catch (err: any) {
      toast.error(err.message || 'Fiyat güncellenemedi.');
    } finally {
      setEditingPriceId(null);
    }
  };

  // Selection handlers
  const toggleSelectProduct = (id: string) => {
    setSelectedProductIds((prev) =>
      prev.includes(id) ? prev.filter((i) => i !== id) : [...prev, id]
    );
  };

  const toggleSelectAll = () => {
    if (selectedProductIds.length === filteredProducts.length && filteredProducts.length > 0) {
      setSelectedProductIds([]);
    } else {
      setSelectedProductIds(filteredProducts.map((p) => p.id));
    }
  };

  // Bulk Stock Toggle
  const handleBulkStockToggle = async (isActive: boolean) => {
    if (selectedProductIds.length === 0) return;
    setIsBulkProcessing(true);
    try {
      await merchantApiFetch('/merchant/products/bulk-stock', {
        method: 'PUT',
        body: JSON.stringify({
          productIds: selectedProductIds,
          isActive,
        }),
      });
      setProducts((prev) =>
        prev.map((item) =>
          selectedProductIds.includes(item.id) ? { ...item, isActive } : item
        )
      );
      toast.success(
        `${selectedProductIds.length} ürün ${isActive ? 'satışa açıldı' : 'satışa kapatıldı'}.`
      );
      setSelectedProductIds([]);
    } catch (err: any) {
      toast.error(err.message || 'Toplu işlem başarısız oldu.');
    } finally {
      setIsBulkProcessing(false);
    }
  };

  // Bulk Price Apply
  const handleApplyBulkPrice = async () => {
    if (selectedProductIds.length === 0) return;
    setIsBulkProcessing(true);
    try {
      await merchantApiFetch('/merchant/products/bulk-price', {
        method: 'PUT',
        body: JSON.stringify({
          productIds: selectedProductIds,
          updateType: bulkPriceType,
          value: bulkPriceValue,
        }),
      });
      toast.success(`${selectedProductIds.length} ürünün fiyatı güncellendi.`);
      setShowBulkPriceModal(false);
      await fetchProducts();
      setSelectedProductIds([]);
    } catch (err: any) {
      toast.error(err.message || 'Toplu fiyat güncelleme başarısız.');
    } finally {
      setIsBulkProcessing(false);
    }
  };

  // Menu Category CRUD Handlers
  const handleCreateCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = newCategoryName.trim();
    if (trimmed.length < 2) {
      toast.warning('Kategori adı en az 2 karakter olmalıdır.');
      return;
    }
    setIsSavingCategory(true);
    try {
      await merchantApiFetch('/merchant/categories', {
        method: 'POST',
        body: JSON.stringify({ name: trimmed }),
      });
      setNewCategoryName('');
      toast.success('Yeni menü kategorisi eklendi.');
      await fetchCategories();
    } catch (err: any) {
      toast.error(err.message || 'Kategori oluşturulamadı.');
    } finally {
      setIsSavingCategory(false);
    }
  };

  const handleSaveCategoryName = async (categoryId: string) => {
    const trimmed = editingCategoryName.trim();
    if (trimmed.length < 2) {
      toast.warning('Kategori adı en az 2 karakter olmalıdır.');
      return;
    }
    setIsSavingCategory(true);
    try {
      await merchantApiFetch(`/merchant/categories/${categoryId}`, {
        method: 'PUT',
        body: JSON.stringify({ name: trimmed }),
      });
      setEditingCategoryId(null);
      setEditingCategoryName('');
      toast.success('Kategori adı güncellendi.');
      await Promise.all([fetchCategories(), fetchProducts()]);
    } catch (err: any) {
      toast.error(err.message || 'Kategori güncellenemedi.');
    } finally {
      setIsSavingCategory(false);
    }
  };

  const handleDeleteCategory = async (cat: any) => {
    const ok = await confirm({
      title: 'Kategoriyi Sil',
      message: `"${cat.name}" kategorisini silmek istediğinize emin misiniz?`,
      confirmText: 'Kategoriyi Sil',
      tone: 'danger',
    });
    if (!ok) return;

    try {
      await merchantApiFetch(`/merchant/categories/${cat.id}`, {
        method: 'DELETE',
      });
      if (selectedCategory === cat.id) {
        setSelectedCategory('ALL');
      }
      toast.info(`"${cat.name}" kategorisi silindi.`);
      await fetchCategories();
    } catch (err: any) {
      toast.error(err.message || 'Kategori silinemedi.');
    }
  };

  const activeCount = products.filter((p) => p.isActive).length;

  const handleExportCSV = () => {
    if (products.length === 0) return;
    const headers = ['Ürün Adı', 'Kategori', 'Fiyat (TL)', 'Birim', 'Barkod', 'Stok', 'Durum'];
    const rows = filteredProducts.map((p) => [
      `"${(p.name || '').replace(/"/g, '""')}"`,
      `"${(p.category?.name || p.categoryId || '').replace(/"/g, '""')}"`,
      p.price,
      p.unit || 'ADET',
      p.barcode || '',
      p.trackStock ? (p.stockQuantity ?? 0) : 'Sınırsız',
      p.isActive ? 'Aktif' : 'Pasif',
    ]);
    const csvContent =
      'data:text/csv;charset=utf-8,\uFEFF' +
      [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute(
      'download',
      `hoppa_urun_katalogu_${new Date().toISOString().slice(0, 10)}.csv`
    );
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const productHeaderActions = (
    <div className="flex flex-wrap items-center gap-2">
      <button
        type="button"
        onClick={() => setShowCategoryDrawer(true)}
        className={`px-3.5 py-2 rounded-xl border font-bold text-xs flex items-center gap-2 transition-colors ${
          isDark
            ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
            : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
        }`}
      >
        <FolderTree className="w-3.5 h-3.5 text-[#FF6B00]" />
        <span>Menü Kategorileri</span>
      </button>

      <button
        type="button"
        onClick={handleExportCSV}
        disabled={products.length === 0}
        className={`px-3.5 py-2 rounded-xl border font-bold text-xs flex items-center gap-2 transition-colors disabled:opacity-50 ${
          isDark
            ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
            : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
        }`}
        title="Ürün Kataloğunu Excel/CSV Olarak İndir"
      >
        <Download className="w-3.5 h-3.5" />
        <span className="hidden sm:inline">Dışa Aktar (CSV)</span>
      </button>

      <button
        type="button"
        onClick={() => setShowCatalogImport(true)}
        className={`px-3.5 py-2 rounded-xl border font-bold text-xs flex items-center gap-2 transition-colors ${
          isDark
            ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
            : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
        }`}
      >
        <Database className="w-3.5 h-3.5" />
        <span>Global Katalogdan Aktar</span>
      </button>

      <button
        type="button"
        onClick={() => {
          setActiveProductForEdit(null);
          setShowProductModal(true);
        }}
        className="px-4 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-xs flex items-center gap-2 transition-colors shadow-2xs"
      >
        <Plus className="w-4 h-4" />
        <span>Yeni Ürün Ekle</span>
      </button>
    </div>
  );

  return (
    <MerchantLayout
      title="Ürün & Menü Portalı"
      subtitle={`Toplam ${products.length} ürün listeleniyor (${activeCount} tanesi aktif satışta)`}
      headerIcon={Package}
      headerActions={productHeaderActions}
      activeTab="products"
    >
      <Head>
        <title>Ürün & Menü Portalı | Hoppa Merchant</title>
      </Head>

      <div className="space-y-6">
        {/* Filters & Search Toolbar */}
        <div
          className={`border rounded-3xl p-4 flex flex-col md:flex-row items-center justify-between gap-4 transition-colors ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
          }`}
        >
          <div className="relative w-full md:w-80">
            <Search className="absolute left-3.5 top-3 w-4 h-4 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Ürün adı veya barkod ara..."
              className={`w-full border rounded-xl py-2.5 pl-10 pr-4 text-xs font-semibold outline-none transition-all ${
                isDark
                  ? 'bg-slate-950 border-slate-800 text-white placeholder-slate-500 focus:border-[#FF6B00]'
                  : 'bg-slate-50 border-slate-200 text-slate-900 placeholder-slate-400 focus:border-[#FF6B00]'
              }`}
            />
          </div>

          <div className="flex flex-wrap items-center gap-2.5 w-full md:w-auto">
            <div className="min-w-[180px]">
              <HoppaSelect
                value={selectedCategory}
                onChange={(val) => setSelectedCategory(val)}
                options={[
                  { value: 'ALL', label: `Tüm Kategoriler (${categories.length})` },
                  ...categories.map((cat) => ({
                    value: cat.id,
                    label: cat.name,
                  })),
                ]}
                size="sm"
                variant="subtle"
                searchable={categories.length > 5}
                searchPlaceholder="Kategori ara..."
              />
            </div>

            <div className="min-w-[170px]">
              <HoppaSelect
                value={stockFilter}
                onChange={(val) => setStockFilter(val)}
                options={[
                  { value: 'ALL', label: 'Tüm Durumlar' },
                  { value: 'ACTIVE', label: 'Sadece Aktif (Satışta)', badge: 'Canlı' },
                  { value: 'INACTIVE', label: 'Sadece Pasif / Tükenen' },
                  { value: 'TRACKED_LOW', label: 'Kritik Stok (≤ 5 adet)', badge: 'Kritik' },
                ]}
                size="sm"
                variant="subtle"
              />
            </div>

            <div
              className={`flex items-center border rounded-xl p-1 shrink-0 ${
                isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-100 border-slate-200'
              }`}
            >
              <button
                type="button"
                aria-label="Tablo görünümü"
                onClick={() => setViewMode('table')}
                className={`p-1.5 rounded-lg transition-colors ${
                  viewMode === 'table'
                    ? 'bg-[#FF6B00] text-white font-bold'
                    : 'text-slate-400 hover:text-slate-700'
                }`}
                title="Tablo Görünümü"
              >
                <List className="w-4 h-4" />
              </button>
              <button
                type="button"
                aria-label="Kart görünümü"
                onClick={() => setViewMode('grid')}
                className={`p-1.5 rounded-lg transition-colors ${
                  viewMode === 'grid'
                    ? 'bg-[#FF6B00] text-white font-bold'
                    : 'text-slate-400 hover:text-slate-700'
                }`}
                title="Kart Görünümü"
              >
                <LayoutGrid className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* Bulk Operations Action Bar */}
        {selectedProductIds.length > 0 && (
          <div className="bg-[#FF6B00]/10 border border-[#FF6B00]/30 rounded-2xl p-4 flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-xl bg-[#FF6B00] text-white font-black flex items-center justify-center text-xs tabular-nums">
                {selectedProductIds.length}
              </div>
              <span className="text-xs font-bold text-[#FF6B00]">
                Seçili Ürün Üzerinde Toplu İşlem Yap:
              </span>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <button
                type="button"
                onClick={() => void handleBulkStockToggle(true)}
                disabled={isBulkProcessing}
                className="px-3 py-1.5 rounded-xl bg-[#00A651]/20 hover:bg-[#00A651]/30 border border-[#00A651]/40 text-[#00A651] font-bold text-xs transition-all"
              >
                Hepsini Satışa Aç
              </button>
              <button
                type="button"
                onClick={() => void handleBulkStockToggle(false)}
                disabled={isBulkProcessing}
                className="px-3 py-1.5 rounded-xl bg-rose-500/20 hover:bg-rose-500/30 border border-rose-500/40 text-rose-500 font-bold text-xs transition-all"
              >
                Hepsini Satışa Kapat
              </button>
              <button
                type="button"
                onClick={() => setShowBulkPriceModal(true)}
                disabled={isBulkProcessing}
                className="px-3 py-1.5 rounded-xl bg-[#FF6B00]/20 hover:bg-[#FF6B00]/30 border border-[#FF6B00]/40 text-[#FF6B00] font-bold text-xs flex items-center gap-1 transition-all"
              >
                <DollarSign className="w-3.5 h-3.5" />
                <span>Toplu Fiyat Değiştir</span>
              </button>
              <button
                type="button"
                onClick={() => setSelectedProductIds([])}
                className="px-3 py-1.5 rounded-xl bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-400 font-bold text-xs"
              >
                Seçimi Temizle
              </button>
            </div>
          </div>
        )}

        {/* Product List Content */}
        {isLoading ? (
          <div
            className={`text-center py-20 rounded-3xl border ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
            }`}
          >
            <div className="w-10 h-10 border-3 border-[#FF6B00] border-t-transparent rounded-full animate-spin mx-auto mb-3" />
            <p className="text-xs text-slate-400 font-semibold">Ürün kataloğunuz yükleniyor...</p>
          </div>
        ) : filteredProducts.length === 0 ? (
          <div
            className={`text-center py-16 px-4 rounded-3xl border space-y-4 ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
            }`}
          >
            <Package className="w-12 h-12 text-slate-400 mx-auto" />
            <div>
              <h3 className="font-bold text-slate-700 dark:text-slate-300">
                Henüz kayıtlı ürün bulunamadı
              </h3>
              <p className="text-xs text-slate-500 mt-1 max-w-md mx-auto">
                Yeni ürün oluşturabilir, global 20.000+ ürün kütüphanesinden aktarabilir veya önce menü kategorilerinizi düzenleyebilirsiniz.
              </p>
            </div>
            <div className="flex flex-wrap items-center justify-center gap-2.5 pt-2">
              <button
                type="button"
                onClick={() => {
                  setActiveProductForEdit(null);
                  setShowProductModal(true);
                }}
                className="px-4 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-xs inline-flex items-center gap-2"
              >
                <Plus className="w-4 h-4" />
                <span>Yeni Ürün Ekle</span>
              </button>
              <button
                type="button"
                onClick={() => setShowCatalogImport(true)}
                className="px-4 py-2.5 rounded-xl bg-[#00A651] hover:bg-[#008C44] text-white font-black text-xs inline-flex items-center gap-2"
              >
                <Database className="w-4 h-4" />
                <span>Global Katalogdan Aktar</span>
              </button>
              <button
                type="button"
                onClick={() => setShowCategoryDrawer(true)}
                className={`px-4 py-2.5 rounded-xl border font-bold text-xs inline-flex items-center gap-2 ${
                  isDark
                    ? 'bg-slate-800 border-slate-700 text-slate-200'
                    : 'bg-slate-50 border-slate-200 text-slate-700'
                }`}
              >
                <FolderTree className="w-4 h-4 text-[#FF6B00]" />
                <span>Kategori Oluştur</span>
              </button>
            </div>
          </div>
        ) : viewMode === 'table' ? (
          /* Table View */
          <div
            className={`border rounded-3xl overflow-hidden transition-colors ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
            }`}
          >
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr
                    className={`border-b tracking-wide font-extrabold ${
                      isDark
                        ? 'bg-slate-950 border-slate-800 text-slate-400'
                        : 'bg-slate-100 border-slate-200 text-slate-600'
                    }`}
                  >
                    <th className="p-4 w-10 text-center">
                      <input
                        type="checkbox"
                        checked={
                          selectedProductIds.length === filteredProducts.length &&
                          filteredProducts.length > 0
                        }
                        onChange={toggleSelectAll}
                        aria-label="Tüm ürünleri seç"
                        className="rounded border-slate-300 text-[#FF6B00] focus:ring-0 cursor-pointer"
                      />
                    </th>
                    <th className="p-4">
                      <button
                        type="button"
                        onClick={() => handleSort('name')}
                        className="inline-flex items-center gap-1 hover:text-[#FF6B00]"
                      >
                        <span>Ürün</span>
                        <ArrowUpDown className="w-3.5 h-3.5" />
                      </button>
                    </th>
                    <th className="p-4">Barkod / Birim</th>
                    <th className="p-4">Kategori</th>
                    <th className="p-4 text-right">
                      <button
                        type="button"
                        onClick={() => handleSort('price')}
                        className="inline-flex items-center gap-1 hover:text-[#FF6B00]"
                      >
                        <span>Satış Fiyatı (₺)</span>
                        <ArrowUpDown className="w-3.5 h-3.5" />
                      </button>
                    </th>
                    <th className="p-4 text-center">
                      <button
                        type="button"
                        onClick={() => handleSort('stock')}
                        className="inline-flex items-center gap-1 hover:text-[#FF6B00]"
                      >
                        <span>Stok Durumu</span>
                        <ArrowUpDown className="w-3.5 h-3.5" />
                      </button>
                    </th>
                    <th className="p-4 text-center">Varyasyon / Opsiyon</th>
                    <th className="p-4 text-right">Aksiyonlar</th>
                  </tr>
                </thead>
                <tbody className={`divide-y ${isDark ? 'divide-slate-800' : 'divide-slate-200'}`}>
                  {filteredProducts.map((p) => {
                    const isSelected = selectedProductIds.includes(p.id);
                    const optionCount = (p.optionGroups || []).length;

                    return (
                      <tr
                        key={p.id}
                        className={`transition-colors ${
                          isSelected
                            ? 'bg-[#FF6B00]/10'
                            : isDark
                              ? 'hover:bg-slate-800/80'
                              : 'hover:bg-slate-50'
                        }`}
                      >
                        <td className="p-4 text-center">
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => toggleSelectProduct(p.id)}
                            aria-label={`${p.name} seç`}
                            className="rounded border-slate-300 text-[#FF6B00] focus:ring-0 cursor-pointer"
                          />
                        </td>

                        <td className="p-4">
                          <div className="flex items-center gap-3">
                            <div
                              className={`w-12 h-12 rounded-xl border p-1 shrink-0 overflow-hidden ${
                                isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-100 border-slate-200'
                              }`}
                            >
                              <img
                                src={p.imageUrl || '/images/default-product.svg'}
                                alt={p.name}
                                className="w-full h-full object-contain"
                              />
                            </div>
                            <div>
                              <h4 className="font-bold text-sm">{p.name}</h4>
                              <p className="text-[11px] text-slate-400 line-clamp-1">
                                {p.description || 'Açıklama yok'}
                              </p>
                            </div>
                          </div>
                        </td>

                        <td className="p-4">
                          <span className="font-mono text-slate-700 dark:text-slate-300 block">
                            {p.barcode || '—'}
                          </span>
                          <span className="text-[10px] font-bold text-slate-400">
                            {p.unit || 'ADET'}
                          </span>
                        </td>

                        <td className="p-4">
                          <span
                            className={`inline-flex items-center px-2.5 py-1 rounded-md text-[11px] font-semibold border ${
                              isDark
                                ? 'bg-slate-950 border-slate-800 text-slate-300'
                                : 'bg-slate-100 border-slate-200 text-slate-700'
                            }`}
                          >
                            {p.category?.name || 'Genel'}
                          </span>
                        </td>

                        <td className="p-4 text-right font-bold tabular-nums">
                          {editingPriceId === p.id ? (
                            <div className="flex items-center justify-end gap-1">
                              <input
                                type="number"
                                step="0.5"
                                autoFocus
                                value={editingPriceVal}
                                onChange={(e) => setEditingPriceVal(e.target.value)}
                                onKeyDown={(e) => {
                                  if (e.key === 'Enter') void handleSaveInlinePrice(p.id);
                                  if (e.key === 'Escape') setEditingPriceId(null);
                                }}
                                className={`w-20 border border-[#FF6B00] rounded p-1 text-xs font-bold text-[#FF6B00] text-right outline-none ${
                                  isDark ? 'bg-slate-950' : 'bg-white'
                                }`}
                              />
                              <button
                                type="button"
                                aria-label="Fiyatı kaydet"
                                onClick={() => void handleSaveInlinePrice(p.id)}
                                className="p-1 text-[#FF6B00]"
                              >
                                <Check className="w-4 h-4" />
                              </button>
                            </div>
                          ) : (
                            <button
                              type="button"
                              onClick={() => {
                                setEditingPriceId(p.id);
                                setEditingPriceVal(String(p.price));
                              }}
                              className="group inline-flex items-center gap-1 hover:text-[#FF6B00] transition-colors"
                              title="Tıkla Fiyatı Değiştir"
                            >
                              <span className="text-[#FF6B00] text-sm font-black tabular-nums">
                                ₺{Number(p.price).toFixed(2)}
                              </span>
                              <Edit className="w-3 h-3 text-slate-400 group-hover:text-[#FF6B00] opacity-0 group-hover:opacity-100 transition-opacity" />
                            </button>
                          )}
                        </td>

                        <td className="p-4 text-center">
                          <button
                            type="button"
                            onClick={() => void handleToggleProductActive(p)}
                            className={`px-2.5 py-1 rounded-lg border text-xs font-semibold inline-flex items-center gap-1.5 transition-colors ${
                              isDark
                                ? 'bg-slate-950/80 border-slate-800 text-slate-200 hover:border-slate-700'
                                : 'bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100'
                            }`}
                          >
                            <span
                              className={`w-1.5 h-1.5 rounded-full shrink-0 ${
                                p.isActive ? 'bg-[#00A651]' : 'bg-rose-500'
                              }`}
                              aria-hidden="true"
                            />
                            <span>{p.isActive ? 'Stokta' : 'Tükendi'}</span>
                          </button>
                        </td>

                        <td className="p-4 text-center">
                          <button
                            type="button"
                            onClick={() => {
                              setActiveProductForOptions(p);
                              setShowOptionBuilder(true);
                            }}
                            className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-xl border text-xs font-bold transition-colors ${
                              isDark
                                ? 'bg-slate-950 border-slate-800 text-[#FF6B00]'
                                : 'bg-slate-50 border-slate-200 text-[#FF6B00]'
                            }`}
                          >
                            <Layers className="w-3.5 h-3.5" />
                            <span>{optionCount} Opsiyon</span>
                          </button>
                        </td>

                        <td className="p-4 text-right">
                          <div className="flex items-center justify-end gap-2">
                            <button
                              type="button"
                              aria-label="Ürünü düzenle"
                              onClick={() => {
                                setActiveProductForEdit(p);
                                setShowProductModal(true);
                              }}
                              className="p-2 rounded-xl border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-300 transition-colors"
                              title="Ürünü Düzenle"
                            >
                              <Edit className="w-4 h-4" />
                            </button>
                            <button
                              type="button"
                              aria-label="Ürünü sil"
                              onClick={() => void handleDeleteProduct(p)}
                              className="p-2 rounded-xl border border-slate-200 dark:border-slate-800 hover:bg-rose-500/20 text-slate-400 hover:text-rose-500 transition-colors"
                              title="Ürünü Sil"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        ) : (
          /* Card (Grid) View with Selection & Delete Parity */
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {filteredProducts.map((p) => {
              const isSelected = selectedProductIds.includes(p.id);

              return (
                <div
                  key={p.id}
                  className={`border rounded-3xl p-4 flex flex-col justify-between transition-all ${
                    isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
                  } ${isSelected ? 'ring-2 ring-[#FF6B00]' : ''}`}
                >
                  <div>
                    <div
                      className={`relative aspect-square rounded-2xl border p-2 mb-3 overflow-hidden flex items-center justify-center ${
                        isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                      }`}
                    >
                      <img
                        src={p.imageUrl || '/images/default-product.svg'}
                        alt={p.name}
                        className="w-full h-full object-contain"
                      />
                      <label className="absolute top-2.5 left-2.5 cursor-pointer bg-white/90 dark:bg-slate-900/90 p-1 rounded-lg border border-slate-200 dark:border-slate-700 shadow-xs">
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => toggleSelectProduct(p.id)}
                          aria-label={`${p.name} seç`}
                          className="rounded border-slate-300 text-[#FF6B00] focus:ring-0 block"
                        />
                      </label>
                      <button
                        type="button"
                        onClick={() => void handleToggleProductActive(p)}
                        className={`absolute top-2 right-2 px-2.5 py-1 rounded-lg border text-[11px] font-semibold inline-flex items-center gap-1.5 shadow-xs transition-colors ${
                          isDark
                            ? 'bg-slate-950/90 border-slate-800 text-slate-200'
                            : 'bg-white/95 border-slate-200 text-slate-700'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full shrink-0 ${
                            p.isActive ? 'bg-[#00A651]' : 'bg-rose-500'
                          }`}
                          aria-hidden="true"
                        />
                        <span>{p.isActive ? 'Stokta' : 'Tükendi'}</span>
                      </button>
                    </div>

                    <h4 className="font-bold text-sm line-clamp-1">{p.name}</h4>
                    <p className="text-xs text-slate-400 mt-0.5 line-clamp-2">
                      {p.description || 'Açıklama yok'}
                    </p>
                  </div>

                  <div className="mt-4 pt-3 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
                    <div>
                      <span className="text-[10px] font-bold text-slate-400 block">Fiyat</span>
                      <span className="text-base font-black text-[#FF6B00] tabular-nums">
                        ₺{Number(p.price).toFixed(2)}
                      </span>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <button
                        type="button"
                        onClick={() => {
                          setActiveProductForOptions(p);
                          setShowOptionBuilder(true);
                        }}
                        className="p-2 rounded-xl border border-slate-200 dark:border-slate-800 text-[#FF6B00]"
                        title="Opsiyonları Düzenle"
                      >
                        <Layers className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setActiveProductForEdit(p);
                          setShowProductModal(true);
                        }}
                        className="p-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300"
                        title="Düzenle"
                      >
                        <Edit className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => void handleDeleteProduct(p)}
                        className="p-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-400 hover:text-rose-500"
                        title="Sil"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Category Management Drawer */}
      <SlideOverDrawer
        isOpen={showCategoryDrawer}
        onClose={() => {
          setShowCategoryDrawer(false);
          setEditingCategoryId(null);
        }}
        title="Menü Kategorileri Yönetimi"
        subtitle="Menünüzdeki ürün kategorilerini ekleyin, düzenleyin veya kaldırın"
        icon={<FolderTree className="w-5 h-5" />}
        widthClass="max-w-lg"
      >
        <form onSubmit={handleCreateCategory} className="flex items-center gap-2">
          <input
            type="text"
            value={newCategoryName}
            onChange={(e) => setNewCategoryName(e.target.value)}
            placeholder="Yeni kategori adı (Örn: Izgaralar, Tatlılar)..."
            className={`flex-1 border rounded-xl px-3.5 py-2.5 text-xs font-bold outline-none focus:border-[#FF6B00] ${
              isDark
                ? 'bg-slate-950 border-slate-800 text-white placeholder-slate-500'
                : 'bg-slate-50 border-slate-200 text-slate-900 placeholder-slate-400'
            }`}
          />
          <button
            type="submit"
            disabled={isSavingCategory}
            className="px-4 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black inline-flex items-center gap-1.5 shrink-0 disabled:opacity-50"
          >
            <Plus className="w-4 h-4" />
            <span>Ekle</span>
          </button>
        </form>

        <div className="space-y-2.5 pt-2">
          {categories.length === 0 ? (
            <div className="py-10 text-center text-xs font-semibold text-slate-400">
              Henüz menü kategorisi bulunmuyor. Yukarıdan ilk kategorinizi oluşturun.
            </div>
          ) : (
            categories.map((cat) => {
              const isEditing = editingCategoryId === cat.id;
              const productCount = cat._count?.products ?? 0;

              return (
                <div
                  key={cat.id}
                  className={`p-3.5 rounded-2xl border flex items-center justify-between gap-3 ${
                    isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-slate-50 border-slate-200'
                  }`}
                >
                  {isEditing ? (
                    <div className="flex-1 flex items-center gap-2">
                      <input
                        type="text"
                        value={editingCategoryName}
                        onChange={(e) => setEditingCategoryName(e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            e.preventDefault();
                            void handleSaveCategoryName(cat.id);
                          }
                          if (e.key === 'Escape') {
                            setEditingCategoryId(null);
                          }
                        }}
                        autoFocus
                        className={`flex-1 border border-[#FF6B00] rounded-xl px-3 py-1.5 text-xs font-bold outline-none ${
                          isDark ? 'bg-slate-900 text-white' : 'bg-white text-slate-900'
                        }`}
                      />
                      <button
                        type="button"
                        onClick={() => void handleSaveCategoryName(cat.id)}
                        disabled={isSavingCategory}
                        className="p-2 rounded-lg bg-[#00A651] text-white"
                        title="Kaydet"
                      >
                        <Save className="w-3.5 h-3.5" />
                      </button>
                      <button
                        type="button"
                        onClick={() => setEditingCategoryId(null)}
                        className="p-2 rounded-lg bg-slate-200 dark:bg-slate-800 text-slate-500"
                        title="İptal"
                      >
                        <X className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  ) : (
                    <>
                      <div className="min-w-0">
                        <p className="text-sm font-bold truncate">{cat.name}</p>
                        <span className="text-[11px] font-semibold text-slate-400 tabular-nums">
                          {productCount} ürün bağlı
                        </span>
                      </div>
                      <div className="flex items-center gap-1.5 shrink-0">
                        <button
                          type="button"
                          onClick={() => {
                            setEditingCategoryId(cat.id);
                            setEditingCategoryName(cat.name);
                          }}
                          className="p-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-500 hover:text-[#FF6B00]"
                          title="Adını Düzenle"
                        >
                          <Edit className="w-3.5 h-3.5" />
                        </button>
                        <button
                          type="button"
                          onClick={() => void handleDeleteCategory(cat)}
                          className="p-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-400 hover:text-rose-500"
                          title="Kategoriyi Sil"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </>
                  )}
                </div>
              );
            })
          )}
        </div>
      </SlideOverDrawer>

      {/* Product Create / Edit Drawer */}
      {showProductModal && (
        <ProductModal
          product={activeProductForEdit}
          onClose={() => setShowProductModal(false)}
          onSuccess={() => {
            setShowProductModal(false);
            toast.success(
              activeProductForEdit ? 'Ürün güncellendi.' : 'Yeni ürün menünüze eklendi.'
            );
            void fetchProducts();
          }}
          onOpenOptionBuilder={(prod) => {
            setShowProductModal(false);
            setActiveProductForOptions(prod);
            setShowOptionBuilder(true);
          }}
        />
      )}

      {/* Option Group Builder Drawer */}
      {showOptionBuilder && activeProductForOptions && (
        <OptionGroupBuilder
          product={activeProductForOptions}
          onClose={() => setShowOptionBuilder(false)}
          onSuccess={() => {
            setShowOptionBuilder(false);
            toast.success('Opsiyon grupları kaydedildi.');
            void fetchProducts();
          }}
        />
      )}

      {/* Global Catalog Import Modal */}
      {showCatalogImport && (
        <CatalogImportModal
          onClose={() => setShowCatalogImport(false)}
          onSuccess={() => {
            setShowCatalogImport(false);
            toast.success('Seçilen katalog ürünleri mağazanıza aktarıldı.');
            void fetchProducts();
          }}
        />
      )}

      {/* Bulk Price Adjust Modal */}
      {showBulkPriceModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-md flex items-center justify-center p-4">
          <div
            className={`border rounded-3xl p-6 w-full max-w-md space-y-4 ${
              isDark
                ? 'bg-slate-900 border-slate-800 text-white'
                : 'bg-white border-slate-200 text-slate-900 shadow-xl'
            }`}
          >
            <h3 className="font-bold text-base">Toplu Fiyat Güncelleme</h3>
            <p className="text-xs text-slate-500">
              Seçili{' '}
              <span className="text-[#FF6B00] font-bold tabular-nums">
                {selectedProductIds.length}
              </span>{' '}
              ürün için fiyat güncelleme kuralı seçin:
            </p>

            <div className="space-y-3">
              <div>
                <HoppaSelect
                  label="İşlem Türü"
                  value={bulkPriceType}
                  onChange={(val) =>
                    setBulkPriceType(
                      val as 'PERCENTAGE_INCREASE' | 'PERCENTAGE_DECREASE' | 'FIXED_ADD'
                    )
                  }
                  options={[
                    { value: 'PERCENTAGE_INCREASE', label: 'Yüzdesel Zam Artışı (%)' },
                    { value: 'PERCENTAGE_DECREASE', label: 'Yüzdesel İndirim (%)' },
                    { value: 'FIXED_ADD', label: 'Sabit Tutar Ekle (₺)' },
                  ]}
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold mb-1 text-slate-400">
                  Uygulanacak Değer
                </label>
                <input
                  type="number"
                  min="0"
                  step="1"
                  value={bulkPriceValue}
                  onChange={(e) => setBulkPriceValue(Number(e.target.value))}
                  className={`w-full border border-[#FF6B00] rounded-xl p-3 text-sm font-black text-[#FF6B00] outline-none ${
                    isDark ? 'bg-slate-950' : 'bg-white'
                  }`}
                />
              </div>
            </div>

            <div className="pt-3 border-t border-slate-200 dark:border-slate-800 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowBulkPriceModal(false)}
                className="px-4 py-2 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold"
              >
                Vazgeç
              </button>
              <button
                type="button"
                onClick={() => void handleApplyBulkPrice()}
                disabled={isBulkProcessing}
                className="px-5 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-bold shadow-md disabled:opacity-50"
              >
                Uygula
              </button>
            </div>
          </div>
        </div>
      )}
    </MerchantLayout>
  );
}
