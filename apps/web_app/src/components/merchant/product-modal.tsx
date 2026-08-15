import React, { useState, useEffect } from 'react';
import { X, Upload, Plus, Check, AlertCircle, Layers } from 'lucide-react';
import { merchantApiFetch, getMerchantToken } from '../../utils/merchant-auth';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

interface ProductModalProps {
  product?: any | null;
  onClose: () => void;
  onSuccess: () => void;
  onOpenOptionBuilder?: (product: any) => void;
}

export default function ProductModal({ product, onClose, onSuccess, onOpenOptionBuilder }: ProductModalProps) {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';
  const isEdit = Boolean(product && product.id);

  const [name, setName] = useState(product?.name || '');
  const [description, setDescription] = useState(product?.description || '');
  const [price, setPrice] = useState<number | string>(product?.price !== undefined ? product.price : '');
  const [regularPrice, setRegularPrice] = useState<number | string>(product?.regularPrice !== undefined ? product.regularPrice : '');
  const [discountRate, setDiscountRate] = useState<number>(product?.discountRate || 0);
  const [barcode, setBarcode] = useState(product?.barcode || '');
  const [categoryId, setCategoryId] = useState(product?.categoryId || product?.category?.id || '');
  const [unit, setUnit] = useState(product?.unit || 'ADET');
  const [brand, setBrand] = useState(product?.brand || '');
  const [trackStock, setTrackStock] = useState<boolean>(product?.trackStock || false);
  const [stockQuantity, setStockQuantity] = useState<number>(product?.stockQuantity || 0);
  const [isActive, setIsActive] = useState<boolean>(product?.isActive !== false);
  const [imageUrl, setImageUrl] = useState(product?.imageUrl || '');

  const [categories, setCategories] = useState<any[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    fetchCategories();
  }, []);

  const fetchCategories = async () => {
    try {
      const res = await merchantApiFetch('/merchant/categories');
      if (res.data) {
        setCategories(res.data);
        if (!categoryId && res.data.length > 0) {
          setCategoryId(res.data[0].id);
        }
      }
    } catch (err) {
      console.error('Kategoriler alınamadı:', err);
    }
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 5 * 1024 * 1024) {
      alert('Görsel boyutu maksimum 5MB olmalıdır.');
      return;
    }

    setIsUploading(true);
    try {
      const mimeType = file.type || 'image/jpeg';
      const presignRes = await merchantApiFetch('/media/upload-url', {
        method: 'POST',
        body: JSON.stringify({
          fileName: file.name,
          mimeType: mimeType,
          contentType: mimeType,
          fileSize: file.size,
        }),
      });

      const { uploadUrl, fileKey, publicUrl } = presignRes.data;

      const token = getMerchantToken();
      const uploadRes = await fetch(uploadUrl, {
        method: 'PUT',
        headers: {
          'Content-Type': mimeType,
          ...(token ? { 'Authorization': `Bearer ${token}` } : {})
        },
        body: file,
      });

      if (!uploadRes.ok) {
        throw new Error('Görsel sunucuya yüklenemedi.');
      }

      const finalUrl = publicUrl || `/uploads/${fileKey}`;
      setImageUrl(finalUrl);
    } catch (err: any) {
      alert(err.message || 'Görsel yüklenirken hata oluştu.');
    } finally {
      setIsUploading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setErrorMsg('Ürün adı zorunludur.');
      return;
    }
    if (!price || Number(price) <= 0) {
      setErrorMsg('Lütfen geçerli bir satış fiyatı giriniz.');
      return;
    }

    setIsSaving(true);
    setErrorMsg(null);

    try {
      const payload = {
        name: name.trim(),
        description: description.trim(),
        price: Number(price),
        regularPrice: regularPrice ? Number(regularPrice) : Number(price),
        discountRate: Number(discountRate) || 0,
        barcode: barcode.trim() || null,
        categoryId: categoryId || null,
        unit: unit || 'ADET',
        brand: brand.trim() || null,
        trackStock,
        stockQuantity: trackStock ? Number(stockQuantity) : 0,
        isActive,
        imageUrl: imageUrl.trim() || null,
      };

      if (isEdit) {
        await merchantApiFetch(`/merchant/products/${product.id}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
      } else {
        await merchantApiFetch('/merchant/products', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
      }

      onSuccess();
    } catch (err: any) {
      setErrorMsg(err.message || 'Ürün kaydedilirken bir hata oluştu.');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-md flex items-center justify-center p-4 overflow-y-auto font-sans">
      <div className={`border rounded-3xl w-full max-w-2xl overflow-hidden shadow-2xl my-8 transition-colors ${
        isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900'
      }`}>
        {/* Modal Header */}
        <div className={`px-6 py-5 border-b flex items-center justify-between transition-colors ${
          isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
        }`}>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#FF6B00] text-white flex items-center justify-center font-bold">
              <Plus className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold">
                {isEdit ? 'Ürün Detaylarını Düzenle' : 'Yeni Ürün Ekle'}
              </h2>
              <p className="text-xs text-slate-400">Ürün fiyat, stok, kategori ve görsel bilgilerini ayarlayın</p>
            </div>
          </div>
          <button onClick={onClose} className="p-2 rounded-xl text-slate-400 hover:text-slate-700 dark:hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <form onSubmit={handleSubmit} className="p-6 space-y-5 max-h-[75vh] overflow-y-auto">
          {errorMsg && (
            <div className="p-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-500 text-xs font-bold flex items-center gap-2">
              <AlertCircle className="w-5 h-5 text-rose-500 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {/* Image & Main Info Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Image Upload Box */}
            <div className="md:col-span-1">
              <label className="block text-xs font-bold uppercase tracking-wider mb-2 text-slate-400">
                Ürün Görseli
              </label>
              <div className={`relative aspect-square rounded-2xl border-2 border-dashed overflow-hidden flex flex-col items-center justify-center text-center p-4 hover:border-[#FF6B00] transition-colors group ${
                isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
              }`}>
                {imageUrl ? (
                  <>
                    <img src={imageUrl} alt="Ürün" className="w-full h-full object-contain" />
                    <div className="absolute inset-0 bg-slate-950/70 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity">
                      <label className="cursor-pointer bg-[#FF6B00] text-white px-3 py-1.5 rounded-xl text-xs font-bold shadow-md">
                        Değiştir
                        <input type="file" accept="image/*" onChange={handleImageUpload} className="hidden" />
                      </label>
                    </div>
                  </>
                ) : (
                  <label className="cursor-pointer flex flex-col items-center justify-center w-full h-full">
                    {isUploading ? (
                      <div className="w-6 h-6 border-2 border-[#FF6B00] border-t-transparent rounded-full animate-spin" />
                    ) : (
                      <>
                        <Upload className="w-8 h-8 text-slate-400 mb-2 group-hover:text-[#FF6B00] transition-colors" />
                        <span className="text-xs font-bold text-slate-500 group-hover:text-slate-900 dark:group-hover:text-white">Görsel Yükle</span>
                        <span className="text-[10px] text-slate-400 mt-1">PNG, JPG, WebP (Max 5MB)</span>
                      </>
                    )}
                    <input type="file" accept="image/*" onChange={handleImageUpload} className="hidden" />
                  </label>
                )}
              </div>
            </div>

            {/* Product Inputs */}
            <div className="md:col-span-2 space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                  Ürün Adı *
                </label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Örn: Adana Kebap veya Koop Süt 1L"
                  className={`w-full border rounded-xl p-3 text-sm font-semibold outline-none focus:border-[#FF6B00] ${
                    isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                  }`}
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                  Açıklama / İçerik
                </label>
                <textarea
                  rows={2}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Örn: Özel baharatlı zırh kıyması, sumaklı soğan ve lavas ile servis edilir."
                  className={`w-full border rounded-xl p-3 text-sm font-semibold outline-none resize-none focus:border-[#FF6B00] ${
                    isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                  }`}
                />
              </div>
            </div>
          </div>

          {/* Category, Unit & Barcode */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                Kategori
              </label>
              <select
                value={categoryId}
                onChange={(e) => setCategoryId(e.target.value)}
                className={`w-full border rounded-xl p-3 text-sm font-semibold outline-none focus:border-[#FF6B00] ${
                  isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                }`}
              >
                <option value="">Kategori Seçiniz</option>
                {categories.map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                Birim
              </label>
              <select
                value={unit}
                onChange={(e) => setUnit(e.target.value)}
                className={`w-full border rounded-xl p-3 text-sm font-semibold outline-none focus:border-[#FF6B00] ${
                  isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                }`}
              >
                <option value="ADET">ADET</option>
                <option value="KG">KG</option>
                <option value="GRAM">GRAM</option>
                <option value="LITRE">LİTRE</option>
                <option value="PAKET">PAKET</option>
                <option value="PORSIYON">PORSİYON</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                Barkod (Market / Bakkal için)
              </label>
              <input
                type="text"
                value={barcode}
                onChange={(e) => setBarcode(e.target.value)}
                placeholder="Örn: 8690000000000"
                className={`w-full border rounded-xl p-3 text-sm font-semibold outline-none focus:border-[#FF6B00] ${
                  isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                }`}
              />
            </div>
          </div>

          {/* Pricing Row */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2 border-t border-slate-200 dark:border-slate-800">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                Aktif Satış Fiyatı (₺) *
              </label>
              <input
                type="number"
                step="0.5"
                min="0"
                required
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder="0.00"
                className={`w-full border border-[#FF6B00] rounded-xl p-3 text-sm font-black text-[#FF6B00] outline-none ${
                  isDark ? 'bg-slate-950' : 'bg-white'
                }`}
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                Üstü Çizili Eski Fiyat (₺)
              </label>
              <input
                type="number"
                step="0.5"
                min="0"
                value={regularPrice}
                onChange={(e) => setRegularPrice(e.target.value)}
                placeholder="0.00"
                className={`w-full border rounded-xl p-3 text-sm font-semibold outline-none ${
                  isDark ? 'bg-slate-950 border-slate-800 text-slate-400' : 'bg-slate-50 border-slate-200 text-slate-600'
                }`}
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
                Marka
              </label>
              <input
                type="text"
                value={brand}
                onChange={(e) => setBrand(e.target.value)}
                placeholder="Örn: Koop, Ülker"
                className={`w-full border rounded-xl p-3 text-sm font-semibold outline-none ${
                  isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                }`}
              />
            </div>
          </div>

          {/* Stock Tracking Row */}
          <div className={`border rounded-2xl p-4 flex flex-col md:flex-row md:items-center justify-between gap-4 ${
            isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
          }`}>
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="trackStock"
                checked={trackStock}
                onChange={(e) => setTrackStock(e.target.checked)}
                className="w-5 h-5 rounded border-slate-300 text-[#FF6B00] focus:ring-0 cursor-pointer"
              />
              <label htmlFor="trackStock" className="cursor-pointer select-none">
                <span className="font-bold text-sm block">Stok Adedi Takibi Yapılsın</span>
                <span className="text-xs text-slate-400">İşaretlenmezse ürün sınırsız stokta kabul edilir.</span>
              </label>
            </div>

            {trackStock && (
              <div className="w-full md:w-36">
                <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Stok Adedi</label>
                <input
                  type="number"
                  min="0"
                  value={stockQuantity}
                  onChange={(e) => setStockQuantity(Number(e.target.value))}
                  className={`w-full border rounded-xl p-2.5 text-sm font-bold text-center outline-none ${
                    isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200 text-slate-900'
                  }`}
                />
              </div>
            )}
          </div>

          {/* Option Group Builder Button (For Food / Restoran) */}
          {isEdit && onOpenOptionBuilder && (
            <div className="pt-2">
              <button
                type="button"
                onClick={() => onOpenOptionBuilder(product)}
                className={`w-full py-3.5 px-4 rounded-2xl border hover:border-[#FF6B00] text-[#FF6B00] font-bold text-xs flex items-center justify-center gap-2 transition-all ${
                  isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                }`}
              >
                <Layers className="w-4 h-4 text-[#FF6B00]" />
                <span>Opsiyon Grupları & Ekstra Malzemeleri Düzenle (Soslar, Boyutlar vb.)</span>
              </button>
            </div>
          )}

          {/* Footer Actions */}
          <div className="pt-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-5 py-3 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 font-bold text-xs transition-colors"
            >
              Vazgeç
            </button>
            <button
              type="submit"
              disabled={isSaving}
              className="px-6 py-3 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-xs shadow-lg shadow-[#FF6B00]/25 flex items-center gap-2 transition-all disabled:opacity-50"
            >
              {isSaving ? (
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <Check className="w-4 h-4" />
                  <span>{isEdit ? 'Değişiklikleri Kaydet' : 'Ürünü Ekleyin'}</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
