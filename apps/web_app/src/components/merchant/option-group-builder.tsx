import React, { useState } from 'react';
import { X, Plus, Trash2, Check, Layers, AlertCircle } from 'lucide-react';
import { merchantApiFetch } from '../../utils/merchant-auth';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

interface OptionGroupBuilderProps {
  product: any;
  onClose: () => void;
  onSuccess: () => void;
}

export default function OptionGroupBuilder({ product, onClose, onSuccess }: OptionGroupBuilderProps) {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [optionGroups, setOptionGroups] = useState<any[]>(
    (product?.optionGroups || []).map((g: any) => ({
      id: g.id,
      name: g.name || '',
      description: g.description || '',
      type: g.type || 'EXTRA',
      selectionType: g.selectionType || 'CHECKBOX',
      minSelections: g.minSelections !== undefined ? g.minSelections : 0,
      maxSelections: g.maxSelections !== undefined ? g.maxSelections : 1,
      freeSelectionsCount: g.freeSelectionsCount !== undefined ? g.freeSelectionsCount : 0,
      options: (g.options || []).map((o: any) => ({
        id: o.id,
        name: o.name || '',
        price: o.price !== undefined ? Number(o.price) : 0,
        isDefault: o.isDefault || false,
        isRemovable: o.isRemovable || false,
        maxQuantity: o.maxQuantity || 1,
        isActive: o.isActive !== false,
      })),
    }))
  );

  const [isSaving, setIsSaving] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleAddGroup = () => {
    setOptionGroups([
      ...optionGroups,
      {
        name: 'Yeni Opsiyon Grubu (Örn: Sos Seçimi)',
        description: '',
        type: 'EXTRA',
        selectionType: 'CHECKBOX',
        minSelections: 0,
        maxSelections: 1,
        freeSelectionsCount: 0,
        options: [
          { name: 'Seçenek 1', price: 0, isDefault: false, isRemovable: false, maxQuantity: 1, isActive: true },
        ],
      },
    ]);
  };

  const handleRemoveGroup = (groupIndex: number) => {
    const updated = [...optionGroups];
    updated.splice(groupIndex, 1);
    setOptionGroups(updated);
  };

  const handleGroupChange = (groupIndex: number, field: string, value: any) => {
    const updated = [...optionGroups];
    updated[groupIndex][field] = value;
    setOptionGroups(updated);
  };

  const handleAddOption = (groupIndex: number) => {
    const updated = [...optionGroups];
    updated[groupIndex].options.push({
      name: '',
      price: 0,
      isDefault: false,
      isRemovable: false,
      maxQuantity: 1,
      isActive: true,
    });
    setOptionGroups(updated);
  };

  const handleRemoveOption = (groupIndex: number, optionIndex: number) => {
    const updated = [...optionGroups];
    updated[groupIndex].options.splice(optionIndex, 1);
    setOptionGroups(updated);
  };

  const handleOptionChange = (groupIndex: number, optionIndex: number, field: string, value: any) => {
    const updated = [...optionGroups];
    updated[groupIndex].options[optionIndex][field] = value;
    setOptionGroups(updated);
  };

  const handleSave = async () => {
    setIsSaving(true);
    setErrorMsg(null);

    try {
      await merchantApiFetch(`/merchant/products/${product.id}/option-groups`, {
        method: 'POST',
        body: JSON.stringify({ optionGroups }),
      });
      onSuccess();
    } catch (err: any) {
      setErrorMsg(err.message || 'Opsiyon grupları kaydedilemedi.');
    } finally {
      setIsSaving(false);
    }
  };

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
            <div className="w-10 h-10 rounded-2xl bg-[#FF6B00] text-white flex items-center justify-center font-bold">
              <Layers className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold">
                Opsiyon Grupları & Ekstra Malzeme Kurucusu
              </h2>
              <p className="text-xs text-[#FF6B00] font-bold">{product?.name}</p>
            </div>
          </div>
          <button onClick={onClose} className="p-2 rounded-xl text-slate-400 hover:text-slate-700 dark:hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 space-y-6 max-h-[75vh] overflow-y-auto">
          {errorMsg && (
            <div className="p-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-500 text-xs font-bold flex items-center gap-2">
              <AlertCircle className="w-5 h-5 text-rose-500 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {optionGroups.length === 0 ? (
            <div className={`text-center py-12 border-2 border-dashed rounded-3xl ${
              isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
            }`}>
              <Layers className="w-12 h-12 text-slate-400 mx-auto mb-3" />
              <h3 className="font-bold text-slate-700 dark:text-slate-300">Henüz hiçbir opsiyon grubu eklenmedi</h3>
              <p className="text-xs text-slate-500 mt-1 max-w-md mx-auto">
                Restoran ürününüz için porsiyon boyutu, sos seçimi, malzeme çıkarma veya ilave ekstra malzemeler ekleyin.
              </p>
              <button
                type="button"
                onClick={handleAddGroup}
                className="mt-4 px-5 py-2.5 rounded-xl bg-[#FF6B00] text-white font-bold text-xs shadow-md hover:bg-[#E56000] transition-all inline-flex items-center gap-2"
              >
                <Plus className="w-4 h-4" />
                <span>İlk Opsiyon Grubunu Ekle</span>
              </button>
            </div>
          ) : (
            <div className="space-y-6">
              {optionGroups.map((group, gIdx) => (
                <div key={gIdx} className={`border rounded-3xl p-5 relative space-y-4 ${
                  isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                }`}>
                  {/* Group Header Controls */}
                  <div className="flex items-center justify-between gap-4 pb-3 border-b border-slate-200 dark:border-slate-800">
                    <div className="flex-1 grid grid-cols-1 md:grid-cols-2 gap-3">
                      <div>
                        <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">
                          Opsiyon Grubu Adı *
                        </label>
                        <input
                          type="text"
                          value={group.name}
                          onChange={(e) => handleGroupChange(gIdx, 'name', e.target.value)}
                          placeholder="Örn: Sos Seçimi veya Pizza Boyutu"
                          className={`w-full border rounded-xl p-2.5 text-sm font-bold outline-none focus:border-[#FF6B00] ${
                            isDark ? 'bg-slate-900 border-slate-700 text-white' : 'bg-white border-slate-200 text-slate-900'
                          }`}
                        />
                      </div>
                      <div>
                        <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">
                          Müşteri Açıklaması / İpucu
                        </label>
                        <input
                          type="text"
                          value={group.description}
                          onChange={(e) => handleGroupChange(gIdx, 'description', e.target.value)}
                          placeholder="Örn: En fazla 2 adet sos seçebilirsiniz"
                          className={`w-full border rounded-xl p-2.5 text-xs outline-none ${
                            isDark ? 'bg-slate-900 border-slate-700 text-slate-300' : 'bg-white border-slate-200 text-slate-700'
                          }`}
                        />
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={() => handleRemoveGroup(gIdx)}
                      className="p-2 rounded-xl text-rose-500 hover:bg-rose-500/10 transition-colors"
                      title="Opsiyon Grubunu Sil"
                    >
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>

                  {/* Group Rules & Bounds */}
                  <div className={`grid grid-cols-2 md:grid-cols-4 gap-3 p-3 rounded-2xl border ${
                    isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'
                  }`}>
                    <div>
                      <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">
                        Seçim Tipi
                      </label>
                      <select
                        value={group.selectionType}
                        onChange={(e) => handleGroupChange(gIdx, 'selectionType', e.target.value)}
                        className={`w-full border rounded-lg p-2 text-xs font-semibold outline-none ${
                          isDark ? 'bg-slate-950 border-slate-700 text-white' : 'bg-slate-50 border-slate-200 text-slate-800'
                        }`}
                      >
                        <option value="RADIO">Tekli Seçim (Radio)</option>
                        <option value="CHECKBOX">Çoklu Seçim (Checkbox)</option>
                        <option value="COUNTER">Adetli Seçim (Counter)</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">
                        Min Seçim (0 = Opsiyonel)
                      </label>
                      <input
                        type="number"
                        min="0"
                        value={group.minSelections}
                        onChange={(e) => handleGroupChange(gIdx, 'minSelections', Number(e.target.value))}
                        className={`w-full border rounded-lg p-2 text-xs font-bold outline-none ${
                          isDark ? 'bg-slate-950 border-slate-700 text-white' : 'bg-slate-50 border-slate-200 text-slate-800'
                        }`}
                      />
                    </div>

                    <div>
                      <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">
                        Max Seçim Sınırı
                      </label>
                      <input
                        type="number"
                        min="1"
                        value={group.maxSelections}
                        onChange={(e) => handleGroupChange(gIdx, 'maxSelections', Number(e.target.value))}
                        className={`w-full border rounded-lg p-2 text-xs font-bold outline-none ${
                          isDark ? 'bg-slate-950 border-slate-700 text-white' : 'bg-slate-50 border-slate-200 text-slate-800'
                        }`}
                      />
                    </div>

                    <div>
                      <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">
                        Ücretsiz Seçim Adedi
                      </label>
                      <input
                        type="number"
                        min="0"
                        value={group.freeSelectionsCount}
                        onChange={(e) => handleGroupChange(gIdx, 'freeSelectionsCount', Number(e.target.value))}
                        className={`w-full border rounded-lg p-2 text-xs font-bold outline-none ${
                          isDark ? 'bg-slate-950 border-slate-700 text-white' : 'bg-slate-50 border-slate-200 text-slate-800'
                        }`}
                      />
                    </div>
                  </div>

                  {/* Options Sub-List */}
                  <div className="space-y-2 pt-2">
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-400">
                      Seçenek Kalemleri ({group.options.length})
                    </label>

                    {group.options.map((opt: any, oIdx: number) => (
                      <div key={oIdx} className={`flex items-center gap-3 p-2.5 rounded-xl border ${
                        isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'
                      }`}>
                        <input
                          type="text"
                          value={opt.name}
                          onChange={(e) => handleOptionChange(gIdx, oIdx, 'name', e.target.value)}
                          placeholder="Seçenek Adı (Örn: Ketçap)"
                          className={`flex-1 border rounded-lg p-2 text-xs font-semibold outline-none focus:border-[#FF6B00] ${
                            isDark ? 'bg-slate-950 border-slate-700 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                          }`}
                        />

                        <div className="w-28 flex items-center gap-1">
                          <span className="text-xs text-slate-400 font-bold">₺</span>
                          <input
                            type="number"
                            step="0.5"
                            min="0"
                            value={opt.price}
                            onChange={(e) => handleOptionChange(gIdx, oIdx, 'price', Number(e.target.value))}
                            placeholder="0.00"
                            className={`w-full border border-[#FF6B00] rounded-lg p-2 text-xs font-bold text-[#FF6B00] outline-none ${
                              isDark ? 'bg-slate-950' : 'bg-white'
                            }`}
                          />
                        </div>

                        <label className="flex items-center gap-1 text-[11px] font-semibold text-slate-500 cursor-pointer select-none">
                          <input
                            type="checkbox"
                            checked={opt.isDefault}
                            onChange={(e) => handleOptionChange(gIdx, oIdx, 'isDefault', e.target.checked)}
                            className="rounded border-slate-300 text-[#FF6B00] focus:ring-0"
                          />
                          <span>Varsayılan Seçili</span>
                        </label>

                        <button
                          type="button"
                          onClick={() => handleRemoveOption(gIdx, oIdx)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-rose-500 hover:bg-rose-500/10 transition-colors"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    ))}

                    <button
                      type="button"
                      onClick={() => handleAddOption(gIdx)}
                      className="mt-2 px-3 py-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 text-xs font-bold inline-flex items-center gap-1.5 transition-colors"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      <span>Seçenek Ekle</span>
                    </button>
                  </div>
                </div>
              ))}

              <button
                type="button"
                onClick={handleAddGroup}
                className={`w-full py-3.5 rounded-2xl border-2 border-dashed text-[#FF6B00] font-bold text-xs flex items-center justify-center gap-2 transition-all ${
                  isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                }`}
              >
                <Plus className="w-4 h-4" />
                <span>Yeni Opsiyon Grubu Ekle</span>
              </button>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className={`px-6 py-4 border-t flex items-center justify-end gap-3 transition-colors ${
          isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
        }`}>
          <button
            type="button"
            onClick={onClose}
            className="px-5 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 font-bold text-xs transition-colors"
          >
            İptal
          </button>
          <button
            type="button"
            onClick={handleSave}
            disabled={isSaving}
            className="px-6 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-xs flex items-center gap-2 transition-all disabled:opacity-50 transform active:scale-95"
          >
            {isSaving ? (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : (
              <>
                <Check className="w-4 h-4" />
                <span>Opsiyon Gruplarını Kaydet</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
