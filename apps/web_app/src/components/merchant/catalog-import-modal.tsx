import React, { useState, useEffect } from 'react';
import { X, Search, Plus, Check, Database, AlertCircle } from 'lucide-react';
import { merchantApiFetch } from '../../utils/merchant-auth';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

interface CatalogImportModalProps {
  onClose: () => void;
  onSuccess: () => void;
}

export default function CatalogImportModal({ onClose, onSuccess }: CatalogImportModalProps) {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [selectedItems, setSelectedItems] = useState<Record<string, { price: number; stockQuantity: number }>>({});
  const [isLoading, setIsLoading] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    handleSearch('');
  }, []);

  const handleSearch = async (query: string) => {
    setIsLoading(true);
    try {
      const res = await merchantApiFetch(`/merchant/products/catalog?q=${encodeURIComponent(query)}`);
      if (res.data) {
        setSearchResults(res.data);
      }
    } catch (err: any) {
      console.error('Katalog arama hatası:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleSelectItem = (item: any) => {
    const key = item.barcode || item.id;
    if (selectedItems[key]) {
      const updated = { ...selectedItems };
      delete updated[key];
      setSelectedItems(updated);
    } else {
      setSelectedItems({
        ...selectedItems,
        [key]: {
          price: Number(item.shownPrice || item.regularPrice || 50),
          stockQuantity: 10,
        },
      });
    }
  };

  const handlePriceChange = (key: string, price: number) => {
    if (!selectedItems[key]) return;
    setSelectedItems({
      ...selectedItems,
      [key]: { ...selectedItems[key], price },
    });
  };

  const handleStockChange = (key: string, stockQuantity: number) => {
    if (!selectedItems[key]) return;
    setSelectedItems({
      ...selectedItems,
      [key]: { ...selectedItems[key], stockQuantity },
    });
  };

  const handleImport = async () => {
    const keys = Object.keys(selectedItems);
    if (keys.length === 0) {
      alert('Lütfen içe aktarmak istediğiniz en az bir ürün seçiniz.');
      return;
    }

    setIsImporting(true);
    setErrorMsg(null);

    try {
      const itemsToImport = searchResults
        .filter((item) => selectedItems[item.barcode || item.id])
        .map((item) => {
          const sel = selectedItems[item.barcode || item.id];
          return {
            barcode: item.barcode,
            price: sel.price,
            stockQuantity: sel.stockQuantity,
            trackStock: true,
          };
        });

      await merchantApiFetch('/merchant/products/catalog/bulk-add', {
        method: 'POST',
        body: JSON.stringify({ items: itemsToImport }),
      });

      onSuccess();
    } catch (err: any) {
      setErrorMsg(err.message || 'Ürünler aktarılırken hata oluştu.');
    } finally {
      setIsImporting(false);
    }
  };

  const selectedCount = Object.keys(selectedItems).length;

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-md flex items-center justify-center p-4 overflow-y-auto font-sans">
      <div className={`border rounded-3xl w-full max-w-4xl overflow-hidden shadow-2xl my-8 transition-colors ${
        isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900'
      }`}>
        {/* Modal Header */}
        <div className={`px-6 py-5 border-b flex items-center justify-between transition-colors ${
          isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
        }`}>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#00A651] text-white flex items-center justify-center font-bold">
              <Database className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold">Global Katalog Kütüphanesinden Ürün Aktar</h2>
              <p className="text-xs text-slate-400">20.000+ Kayıtlı Hazır Üründen Barkod/İsimle Mağazanıza Ekleyin</p>
            </div>
          </div>
          <button onClick={onClose} className="p-2 rounded-xl text-slate-400 hover:text-slate-700 dark:hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Search Bar */}
        <div className={`p-6 border-b transition-colors ${
          isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
        }`}>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              handleSearch(searchQuery);
            }}
            className="relative flex items-center gap-3"
          >
            <div className="relative flex-1">
              <Search className="absolute left-4 top-3.5 w-5 h-5 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Barkod numarası veya ürün adı yazın... (Örn: Süt, Coca Cola, Nutella)"
                className={`w-full border rounded-2xl py-3.5 pl-12 pr-4 text-sm font-semibold outline-none focus:border-[#00A651] ${
                  isDark ? 'bg-slate-900 border-slate-800 text-white placeholder-slate-500' : 'bg-white border-slate-200 text-slate-900 placeholder-slate-400'
                }`}
              />
            </div>
            <button
              type="submit"
              className="px-6 py-3.5 rounded-2xl bg-[#00A651] hover:bg-[#008C44] text-white font-black text-sm transition-all shadow-md shadow-[#00A651]/20"
            >
              Ara
            </button>
          </form>
        </div>

        {/* Catalog Results Grid */}
        <div className="p-6 max-h-[60vh] overflow-y-auto space-y-3">
          {errorMsg && (
            <div className="p-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-500 text-xs font-bold flex items-center gap-2">
              <AlertCircle className="w-5 h-5 text-rose-500 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {isLoading ? (
            <div className="text-center py-12">
              <div className="w-8 h-8 border-3 border-[#00A651] border-t-transparent rounded-full animate-spin mx-auto mb-3" />
              <p className="text-xs text-slate-400 font-semibold">Master Katalog Aranıyor...</p>
            </div>
          ) : searchResults.length === 0 ? (
            <div className="text-center py-12 text-slate-400">
              <Database className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p className="text-sm font-semibold">Aradığınız kriterde ürün bulunamadı.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {searchResults.map((item) => {
                const key = item.barcode || item.id;
                const isSelected = Boolean(selectedItems[key]);
                const sel = selectedItems[key];

                return (
                  <div
                    key={key}
                    className={`p-4 rounded-2xl border transition-all flex items-start gap-4 ${
                      isSelected
                        ? 'bg-[#00A651]/10 border-[#00A651]/40'
                        : isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                    }`}
                  >
                    <div className={`w-16 h-16 rounded-xl border p-1 flex items-center justify-center shrink-0 ${
                      isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'
                    }`}>
                      <img
                        src={item.imageUrl || '/images/default-product.png'}
                        alt={item.name}
                        className="w-full h-full object-contain"
                      />
                    </div>

                    <div className="flex-1 min-w-0">
                      <h4 className="font-bold text-sm truncate">{item.name}</h4>
                      <p className="text-xs text-slate-400 mt-0.5">
                        Barkod: <span className="font-mono">{item.barcode || '—'}</span>
                      </p>

                      {isSelected ? (
                        <div className="mt-3 pt-3 border-t border-slate-200 dark:border-slate-800 grid grid-cols-2 gap-2">
                          <div>
                            <label className="block text-[10px] font-bold text-[#00A651] uppercase">Satış Fiyatınız (₺)</label>
                            <input
                              type="number"
                              step="0.5"
                              value={sel.price}
                              onChange={(e) => handlePriceChange(key, Number(e.target.value))}
                              className={`w-full border border-[#00A651]/40 rounded-lg p-1.5 text-xs font-bold text-[#00A651] text-center outline-none ${
                                isDark ? 'bg-slate-900' : 'bg-white'
                              }`}
                            />
                          </div>
                          <div>
                            <label className="block text-[10px] font-bold text-slate-400 uppercase">Stok Adedi</label>
                            <input
                              type="number"
                              min="0"
                              value={sel.stockQuantity}
                              onChange={(e) => handleStockChange(key, Number(e.target.value))}
                              className={`w-full border rounded-lg p-1.5 text-xs font-bold text-center outline-none ${
                                isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200 text-slate-900'
                              }`}
                            />
                          </div>
                        </div>
                      ) : (
                        <p className="text-xs text-[#00A651] font-bold mt-2">
                          Önerilen Fiyat: ₺{Number(item.shownPrice || item.regularPrice || 0).toFixed(2)}
                        </p>
                      )}
                    </div>

                    <button
                      type="button"
                      onClick={() => toggleSelectItem(item)}
                      className={`p-2.5 rounded-xl transition-all ${
                        isSelected
                          ? 'bg-[#00A651] text-white font-bold'
                          : isDark ? 'bg-slate-800 text-slate-300' : 'bg-slate-200 text-slate-700'
                      }`}
                    >
                      {isSelected ? <Check className="w-5 h-5" /> : <Plus className="w-5 h-5" />}
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className={`px-6 py-4 border-t flex items-center justify-between transition-colors ${
          isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
        }`}>
          <span className="text-xs text-slate-400 font-semibold">
            Seçilen Ürün Sayısı: <span className="text-[#00A651] font-bold">{selectedCount}</span>
          </span>

          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-5 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 font-bold text-xs transition-colors"
            >
              Kapat
            </button>
            <button
              type="button"
              onClick={handleImport}
              disabled={isImporting || selectedCount === 0}
              className="px-6 py-2.5 rounded-xl bg-[#00A651] hover:bg-[#008C44] text-white font-black text-xs shadow-lg shadow-[#00A651]/20 flex items-center gap-2 transition-all disabled:opacity-50"
            >
              {isImporting ? (
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <Check className="w-4 h-4" />
                  <span>Seçilenleri Dükkanıma Aktar</span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
