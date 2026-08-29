import React, { useState, useEffect, useMemo } from 'react';
import Head from 'next/head';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import ProductModal from '../../../components/merchant/product-modal';
import OptionGroupBuilder from '../../../components/merchant/option-group-builder';
import CatalogImportModal from '../../../components/merchant/catalog-import-modal';
import { 
  Package, Plus, Search, Layers, Database, Edit, Trash2, 
  Check, Power, DollarSign, LayoutGrid, List, Download, FileSpreadsheet
} from 'lucide-react';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

export default function MerchantProductsPage() {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [products, setProducts] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Filters & State
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('ALL');
  const [stockFilter, setStockFilter] = useState('ALL');
  const [viewMode, setViewMode] = useState<'table' | 'grid'>('table');

  // Bulk Selection
  const [selectedProductIds, setSelectedProductIds] = useState<string[]>([]);
  const [isBulkProcessing, setIsBulkProcessing] = useState(false);
  const [showBulkPriceModal, setShowBulkPriceModal] = useState(false);
  const [bulkPriceType, setBulkPriceType] = useState<'PERCENTAGE_INCREASE' | 'PERCENTAGE_DECREASE' | 'FIXED_ADD'>('PERCENTAGE_INCREASE');
  const [bulkPriceValue, setBulkPriceValue] = useState<number>(10);

  // Modals
  const [activeProductForEdit, setActiveProductForEdit] = useState<any | null>(null);
  const [showProductModal, setShowProductModal] = useState(false);
  const [activeProductForOptions, setActiveProductForOptions] = useState<any | null>(null);
  const [showOptionBuilder, setShowOptionBuilder] = useState(false);
  const [showCatalogImport, setShowCatalogImport] = useState(false);

  // Inline Price Editing state
  const [editingPriceId, setEditingPriceId] = useState<string | null>(null);
  const [editingPriceVal, setEditingPriceVal] = useState<string>('');

  useEffect(() => {
    fetchProducts();
    fetchCategories();
  }, []);

  const fetchProducts = async () => {
    setIsLoading(true);
    try {
      const res = await merchantApiFetch('/merchant/products');
      if (res.data) {
        setProducts(res.data);
      }
    } catch (err: any) {
      console.error('Ürünler yüklenirken hata:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const res = await merchantApiFetch('/merchant/categories');
      if (res.data) {
        setCategories(res.data);
      }
    } catch (err) {
      console.error('Kategoriler alınamadı:', err);
    }
  };

  // Filtered Products
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      // Search
      const matchesSearch = 
        !searchQuery ||
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (p.barcode && p.barcode.includes(searchQuery));

      // Category
      const matchesCategory =
        selectedCategory === 'ALL' ||
        p.categoryId === selectedCategory ||
        p.category?.id === selectedCategory;

      // Stock Status
      let matchesStock = true;
      if (stockFilter === 'ACTIVE') matchesStock = p.isActive === true;
      if (stockFilter === 'INACTIVE') matchesStock = p.isActive === false;
      if (stockFilter === 'TRACKED_LOW') matchesStock = p.trackStock && (p.stockQuantity || 0) <= 5;

      return matchesSearch && matchesCategory && matchesStock;
    });
  }, [products, searchQuery, selectedCategory, stockFilter]);

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
    } catch (err: any) {
      alert(err.message || 'Ürün durumu değiştirilemedi.');
    }
  };

  // Delete Product
  const handleDeleteProduct = async (product: any) => {
    if (!confirm(`"${product.name}" ürününü silmek istediğinize emin misiniz?`)) return;

    try {
      await merchantApiFetch(`/merchant/products/${product.id}`, {
        method: 'DELETE',
      });
      setProducts((prev) => prev.filter((item) => item.id !== product.id));
      setSelectedProductIds((prev) => prev.filter((id) => id !== product.id));
    } catch (err: any) {
      alert(err.message || 'Ürün silinirken hata oluştu.');
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
    } catch (err: any) {
      alert(err.message || 'Fiyat güncellenemedi.');
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
    if (selectedProductIds.length === filteredProducts.length) {
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
      setSelectedProductIds([]);
    } catch (err: any) {
      alert(err.message || 'Toplu işlem başarısız oldu.');
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
      setShowBulkPriceModal(false);
      fetchProducts();
      setSelectedProductIds([]);
    } catch (err: any) {
      alert(err.message || 'Toplu fiyat güncelleme başarısız.');
    } finally {
      setIsBulkProcessing(false);
    }
  };

  const activeCount = products.filter((p) => p.isActive).length;

  const handleExportCSV = () => {
    if (products.length === 0) return;
    const headers = ['Ürün Adı', 'Kategori', 'Fiyat (TL)', 'Birim', 'Barkod', 'Stok', 'Durum'];
    const rows = filteredProducts.map(p => [
      `"${(p.name || '').replace(/"/g, '""')}"`,
      `"${(p.category?.name || p.categoryId || '').replace(/"/g, '""')}"`,
      p.price,
      p.unit || 'ADET',
      p.barcode || '',
      p.trackStock ? (p.stockQuantity ?? 0) : 'Sınırsız',
      p.isActive ? 'Aktif' : 'Pasif'
    ]);
    const csvContent = 'data:text/csv;charset=utf-8,\uFEFF' + [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `hoppa_urun_katalogu_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const productHeaderActions = (
    <div className="flex flex-wrap items-center gap-2.5">
      {/* CSV Export Button */}
      <button
        onClick={handleExportCSV}
        disabled={products.length === 0}
        className="px-3.5 py-2.5 rounded-xl bg-white/20 hover:bg-white/30 backdrop-blur-md border border-white/30 text-white font-bold text-xs flex items-center gap-2 transition-all disabled:opacity-50"
        title="Ürün Kataloğunu Excel/CSV Olarak İndir"
      >
        <Download className="w-4 h-4 text-white" />
        <span className="hidden sm:inline">Dışa Aktar (CSV)</span>
      </button>

      {/* Catalog Import Button */}
      <button
        onClick={() => setShowCatalogImport(true)}
        className="px-4 py-2.5 rounded-xl bg-white/20 hover:bg-white/30 backdrop-blur-md border border-white/30 text-white font-bold text-xs flex items-center gap-2 transition-all"
      >
        <Database className="w-4 h-4 text-white" />
        <span>Global Katalogdan Aktar</span>
      </button>

      {/* Add Product Button */}
      <button
        onClick={() => {
          setActiveProductForEdit(null);
          setShowProductModal(true);
        }}
        className="px-5 py-2.5 rounded-xl bg-white text-[#E95D22] hover:bg-white/90 font-black text-xs flex items-center gap-2 transition-all transform active:scale-95 shadow-sm"
      >
        <Plus className="w-4 h-4 text-[#E95D22]" />
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
      <div className="space-y-6">

        {/* Filters & Search Toolbar */}
        <div className={`border rounded-3xl p-4 flex flex-col md:flex-row items-center justify-between gap-4 transition-colors ${
          isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
        }`}>
          {/* Search Box */}
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

          {/* Dropdown Filters & View Toggle */}
          <div className="flex flex-wrap items-center gap-3 w-full md:w-auto">
            {/* Category Filter */}
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className={`border rounded-xl px-3 py-2 text-xs font-semibold hoppa-select ${
                isDark ? 'bg-slate-950 border-slate-800 text-slate-200' : 'bg-slate-50 border-slate-200 text-slate-700'
              }`}
            >
              <option value="ALL">Tüm Kategoriler ({categories.length})</option>
              {categories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>

            {/* Stock Filter */}
            <select
              value={stockFilter}
              onChange={(e) => setStockFilter(e.target.value)}
              className={`border rounded-xl px-3 py-2 text-xs font-semibold hoppa-select ${
                isDark ? 'bg-slate-950 border-slate-800 text-slate-200' : 'bg-slate-50 border-slate-200 text-slate-700'
              }`}
            >
              <option value="ALL">Tüm Durumlar</option>
              <option value="ACTIVE">Sadece Aktif (Satışta)</option>
              <option value="INACTIVE">Sadece Pasif / Tükenenler</option>
              <option value="TRACKED_LOW">Kritik Stok (≤ 5 adet)</option>
            </select>

            {/* View Mode Toggle */}
            <div className={`flex items-center border rounded-xl p-1 ${
              isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-100 border-slate-200'
            }`}>
              <button
                onClick={() => setViewMode('table')}
                className={`p-1.5 rounded-lg transition-colors ${
                  viewMode === 'table' ? 'bg-[#FF6B00] text-white font-bold' : 'text-slate-400 hover:text-slate-700'
                }`}
                title="Tablo Görünümü"
              >
                <List className="w-4 h-4" />
              </button>
              <button
                onClick={() => setViewMode('grid')}
                className={`p-1.5 rounded-lg transition-colors ${
                  viewMode === 'grid' ? 'bg-[#FF6B00] text-white font-bold' : 'text-slate-400 hover:text-slate-700'
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
              <div className="w-8 h-8 rounded-xl bg-[#FF6B00] text-white font-black flex items-center justify-center text-xs">
                {selectedProductIds.length}
              </div>
              <span className="text-xs font-bold text-[#FF6B00]">
                Seçili Ürün Üzerinde Toplu İşlem Yap:
              </span>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <button
                onClick={() => handleBulkStockToggle(true)}
                disabled={isBulkProcessing}
                className="px-3 py-1.5 rounded-xl bg-[#00A651]/20 hover:bg-[#00A651]/30 border border-[#00A651]/40 text-[#00A651] font-bold text-xs transition-all"
              >
                Hepsini Satışa Aç
              </button>
              <button
                onClick={() => handleBulkStockToggle(false)}
                disabled={isBulkProcessing}
                className="px-3 py-1.5 rounded-xl bg-rose-500/20 hover:bg-rose-500/30 border border-rose-500/40 text-rose-500 font-bold text-xs transition-all"
              >
                Hepsini Satışa Kapat
              </button>
              <button
                onClick={() => setShowBulkPriceModal(true)}
                disabled={isBulkProcessing}
                className="px-3 py-1.5 rounded-xl bg-[#FF6B00]/20 hover:bg-[#FF6B00]/30 border border-[#FF6B00]/40 text-[#FF6B00] font-bold text-xs flex items-center gap-1 transition-all"
              >
                <DollarSign className="w-3.5 h-3.5" />
                <span>Toplu Fiyat Değiştir</span>
              </button>
              <button
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
          <div className={`text-center py-20 rounded-3xl border ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
          }`}>
            <div className="w-10 h-10 border-3 border-[#FF6B00] border-t-transparent rounded-full animate-spin mx-auto mb-3" />
            <p className="text-xs text-slate-400 font-semibold">Ürün kataloğunuz yükleniyor...</p>
          </div>
        ) : filteredProducts.length === 0 ? (
          <div className={`text-center py-20 rounded-3xl border ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
          }`}>
            <Package className="w-12 h-12 text-slate-400 mx-auto mb-3" />
            <h3 className="font-bold text-slate-700 dark:text-slate-300">Henüz kayıtlı ürün bulunamadı</h3>
            <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
              Sağ üstteki "Yeni Ürün Ekle" butonuna basarak veya "Global Katalogdan Aktar" seçeneğini kullanarak ürünlerinizi ekleyebilirsiniz.
            </p>
          </div>
        ) : viewMode === 'table' ? (
          /* Table (Data Grid) View */
          <div className={`border rounded-3xl overflow-hidden transition-colors ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
          }`}>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className={`border-b uppercase tracking-wider font-extrabold ${
                    isDark ? 'bg-slate-950 border-slate-800 text-slate-400' : 'bg-slate-100 border-slate-200 text-slate-600'
                  }`}>
                    <th className="p-4 w-10 text-center">
                      <input
                        type="checkbox"
                        checked={selectedProductIds.length === filteredProducts.length && filteredProducts.length > 0}
                        onChange={toggleSelectAll}
                        className="rounded border-slate-300 text-[#FF6B00] focus:ring-0 cursor-pointer"
                      />
                    </th>
                    <th className="p-4">Ürün</th>
                    <th className="p-4">Barkod / Birim</th>
                    <th className="p-4">Kategori</th>
                    <th className="p-4 text-right">Satış Fiyatı (₺)</th>
                    <th className="p-4 text-center">Stok Durumu</th>
                    <th className="p-4 text-center">Varyasyon/Opsiyon</th>
                    <th className="p-4 text-right">Aksiyonlar</th>
                  </tr>
                </thead>
                <tbody className={`divide-y ${isDark ? 'divide-slate-800' : 'divide-slate-200'}`}>
                  {filteredProducts.map((p) => {
                    const isSelected = selectedProductIds.includes(p.id);
                    const optionCount = (p.optionGroups || []).length;

                    return (
                      <tr key={p.id} className={`transition-colors ${
                        isSelected 
                          ? 'bg-[#FF6B00]/10' 
                          : isDark ? 'hover:bg-slate-850' : 'hover:bg-slate-50'
                      }`}>
                        {/* Checkbox */}
                        <td className="p-4 text-center">
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => toggleSelectProduct(p.id)}
                            className="rounded border-slate-300 text-[#FF6B00] focus:ring-0 cursor-pointer"
                          />
                        </td>

                        {/* Product Info */}
                        <td className="p-4">
                          <div className="flex items-center gap-3">
                            <div className={`w-12 h-12 rounded-xl border p-1 shrink-0 overflow-hidden ${
                              isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-100 border-slate-200'
                            }`}>
                              <img
                                src={p.imageUrl || '/images/default-product.png'}
                                alt={p.name}
                                className="w-full h-full object-contain"
                              />
                            </div>
                            <div>
                              <h4 className="font-bold text-sm">{p.name}</h4>
                              <p className="text-[11px] text-slate-400 line-clamp-1">{p.description || 'Açıklama yok'}</p>
                            </div>
                          </div>
                        </td>

                        {/* Barcode & Unit */}
                        <td className="p-4">
                          <span className="font-mono text-slate-700 dark:text-slate-300 block">{p.barcode || '—'}</span>
                          <span className="text-[10px] font-bold text-slate-400 uppercase">{p.unit || 'ADET'}</span>
                        </td>

                        {/* Category */}
                        <td className="p-4">
                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold border ${
                            isDark 
                              ? 'bg-slate-950 border-slate-800 text-slate-300' 
                              : 'bg-slate-100 border-slate-200 text-slate-700'
                          }`}>
                            {p.category?.name || 'Genel'}
                          </span>
                        </td>

                        {/* Inline Editable Price */}
                        <td className="p-4 text-right font-bold">
                          {editingPriceId === p.id ? (
                            <div className="flex items-center justify-end gap-1">
                              <input
                                type="number"
                                step="0.5"
                                autoFocus
                                value={editingPriceVal}
                                onChange={(e) => setEditingPriceVal(e.target.value)}
                                onKeyDown={(e) => {
                                  if (e.key === 'Enter') handleSaveInlinePrice(p.id);
                                  if (e.key === 'Escape') setEditingPriceId(null);
                                }}
                                className={`w-20 border border-[#FF6B00] rounded p-1 text-xs font-bold text-[#FF6B00] text-right outline-none ${
                                  isDark ? 'bg-slate-950' : 'bg-white'
                                }`}
                              />
                              <button onClick={() => handleSaveInlinePrice(p.id)} className="p-1 text-[#FF6B00]">
                                <Check className="w-4 h-4" />
                              </button>
                            </div>
                          ) : (
                            <button
                              onClick={() => {
                                setEditingPriceId(p.id);
                                setEditingPriceVal(p.price.toString());
                              }}
                              className="group inline-flex items-center gap-1 hover:text-[#FF6B00] transition-colors"
                              title="Tıkla Fiyatı Değiştir"
                            >
                              <span className="text-[#FF6B00] text-sm font-black">₺{Number(p.price).toFixed(2)}</span>
                              <Edit className="w-3 h-3 text-slate-400 group-hover:text-[#FF6B00] opacity-0 group-hover:opacity-100 transition-opacity" />
                            </button>
                          )}
                        </td>

                        {/* Stock Toggle Switch */}
                        <td className="p-4 text-center">
                          <button
                            onClick={() => handleToggleProductActive(p)}
                            className={`px-3 py-1 rounded-full text-xs font-bold inline-flex items-center gap-1.5 transition-all ${
                              p.isActive
                                ? 'bg-[#00A651]/15 text-[#00A651] border border-[#00A651]/30'
                                : 'bg-rose-500/15 text-rose-500 border border-rose-500/30'
                            }`}
                          >
                            <Power className="w-3 h-3" />
                            <span>{p.isActive ? 'Stokta' : 'Tükendi'}</span>
                          </button>
                        </td>

                        {/* Options Group Count */}
                        <td className="p-4 text-center">
                          <button
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

                        {/* Actions */}
                        <td className="p-4 text-right">
                          <div className="flex items-center justify-end gap-2">
                            <button
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
                              onClick={() => handleDeleteProduct(p)}
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
          /* Card (Grid) View */
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
                    <div className={`relative aspect-square rounded-2xl border p-2 mb-3 overflow-hidden flex items-center justify-center ${
                      isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                    }`}>
                      <img
                        src={p.imageUrl || '/images/default-product.png'}
                        alt={p.name}
                        className="w-full h-full object-contain"
                      />
                      <button
                        onClick={() => handleToggleProductActive(p)}
                        className={`absolute top-2 right-2 px-2.5 py-1 rounded-full text-[10px] font-bold shadow-md ${
                          p.isActive ? 'bg-[#00A651] text-white' : 'bg-rose-500 text-white'
                        }`}
                      >
                        {p.isActive ? 'Stokta' : 'Tükendi'}
                      </button>
                    </div>

                    <h4 className="font-bold text-sm line-clamp-1">{p.name}</h4>
                    <p className="text-xs text-slate-400 mt-0.5 line-clamp-2">{p.description || 'Açıklama yok'}</p>
                  </div>

                  <div className="mt-4 pt-3 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
                    <div>
                      <span className="text-[10px] font-bold text-slate-400 block uppercase">Fiyat</span>
                      <span className="text-base font-black text-[#FF6B00]">₺{Number(p.price).toFixed(2)}</span>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <button
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
                        onClick={() => {
                          setActiveProductForEdit(p);
                          setShowProductModal(true);
                        }}
                        className="p-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300"
                        title="Düzenle"
                      >
                        <Edit className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Product Create / Edit Modal */}
      {showProductModal && (
        <ProductModal
          product={activeProductForEdit}
          onClose={() => setShowProductModal(false)}
          onSuccess={() => {
            setShowProductModal(false);
            fetchProducts();
          }}
          onOpenOptionBuilder={(prod) => {
            setShowProductModal(false);
            setActiveProductForOptions(prod);
            setShowOptionBuilder(true);
          }}
        />
      )}

      {/* Option Group Builder Modal */}
      {showOptionBuilder && activeProductForOptions && (
        <OptionGroupBuilder
          product={activeProductForOptions}
          onClose={() => setShowOptionBuilder(false)}
          onSuccess={() => {
            setShowOptionBuilder(false);
            fetchProducts();
          }}
        />
      )}

      {/* Global Catalog Import Modal */}
      {showCatalogImport && (
        <CatalogImportModal
          onClose={() => setShowCatalogImport(false)}
          onSuccess={() => {
            setShowCatalogImport(false);
            fetchProducts();
          }}
        />
      )}

      {/* Bulk Price Adjust Modal */}
      {showBulkPriceModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-md flex items-center justify-center p-4">
          <div className={`border rounded-3xl p-6 w-full max-w-md space-y-4 ${
            isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900 shadow-xl'
          }`}>
            <h3 className="font-bold text-base">Toplu Fiyat Güncelleme</h3>
            <p className="text-xs text-slate-500">
              Seçili <span className="text-[#FF6B00] font-bold">{selectedProductIds.length}</span> ürün için fiyat güncelleme kuralı seçin:
            </p>

            <div className="space-y-3">
              <div>
                <label className="block text-xs font-bold mb-1 text-slate-400 uppercase">İşlem Türü</label>
                <select
                  value={bulkPriceType}
                  onChange={(e: any) => setBulkPriceType(e.target.value)}
                  className={`w-full border rounded-xl p-3 text-xs font-bold hoppa-select ${
                    isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-800'
                  }`}
                >
                  <option value="PERCENTAGE_INCREASE">Yüzdesel Zam Artışı (%)</option>
                  <option value="PERCENTAGE_DECREASE">Yüzdesel İndirim (%)</option>
                  <option value="FIXED_ADD">Sabit Tutar Ekle (₺)</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold mb-1 text-slate-400 uppercase">Uygulanacak Değer</label>
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
                onClick={() => setShowBulkPriceModal(false)}
                className="px-4 py-2 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold"
              >
                Vazgeç
              </button>
              <button
                onClick={handleApplyBulkPrice}
                disabled={isBulkProcessing}
                className="px-5 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-bold shadow-md"
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
