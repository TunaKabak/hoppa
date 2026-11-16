import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { 
  ShieldCheck, ArrowRight, ExternalLink
} from 'lucide-react';
import { useMerchantTheme } from '../../context/MerchantThemeContext';
import { merchantApiFetch } from '../../utils/merchant-auth';
import StoreReadinessModal, { StoreReadinessData } from './StoreReadinessModal';

export default function StoreReadinessWidget() {
  const router = useRouter();
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [readinessData, setReadinessData] = useState<StoreReadinessData | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);

  const fetchReadiness = async () => {
    setIsLoading(true);
    try {
      const res = await merchantApiFetch('/merchant/shop/readiness');
      if (res.data) {
        setReadinessData(res.data);
      }
    } catch (err) {
      console.error("Mağaza hazırlık durumu alınamadı:", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchReadiness();
  }, []);

  if (isLoading) {
    return (
      <div className={`p-5 rounded-2xl border flex items-center justify-between animate-pulse ${
        isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'
      }`}>
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-slate-200 dark:bg-slate-800" />
          <div className="space-y-2">
            <div className="w-36 h-4 bg-slate-200 dark:bg-slate-800 rounded" />
            <div className="w-64 h-3 bg-slate-200 dark:bg-slate-800 rounded" />
          </div>
        </div>
      </div>
    );
  }

  if (!readinessData) return null;

  const { score, isReadyToOpen, missingSteps, completedStepsCount, totalSteps } = readinessData;

  // Fully ready view
  if (isReadyToOpen) {
    return (
      <>
        <div
          className={`p-4 rounded-2xl border flex flex-col sm:flex-row sm:items-center justify-between gap-4 transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
          }`}
        >
          <div className="flex items-center gap-3">
            <span className="w-2 h-2 rounded-full bg-[#00A651] shrink-0" aria-hidden="true" />
            <div>
              <h4 className="text-sm font-extrabold tracking-tight">Mağaza Kurulumu Tamamlandı</h4>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                Tüm operasyon adımları, çalışma saatleri ve ürün kataloğunuz doğrulandı.
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setIsModalOpen(true)}
            className={`px-3.5 py-2 rounded-xl border text-xs font-bold flex items-center gap-1.5 shrink-0 transition-colors ${
              isDark
                ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
                : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
            }`}
          >
            <span>Detayları İncele</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </button>
        </div>

        <StoreReadinessModal
          isOpen={isModalOpen}
          onClose={() => setIsModalOpen(false)}
          readinessData={readinessData}
        />
      </>
    );
  }

  // Pending readiness view with missing steps
  const firstMissingStep = missingSteps[0];

  return (
    <>
      <div
        className={`p-5 rounded-2xl border transition-all ${
          isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
        }`}
      >
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-4">
          <div className="flex items-center gap-3">
            <div
              className={`w-10 h-10 rounded-xl border flex items-center justify-center shrink-0 ${
                isDark
                  ? 'bg-slate-950 border-slate-800 text-slate-200'
                  : 'bg-slate-50 border-slate-200 text-slate-700'
              }`}
            >
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-extrabold tracking-tight">
                Mağaza Hazırlık Kontrol Listesi
              </h4>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                Sipariş kabulü için kalan {missingSteps.length} adımı tamamlayın.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3 shrink-0">
            <span className="text-xs font-bold text-slate-500 dark:text-slate-400 tabular-nums">
              {completedStepsCount}/{totalSteps} adım · %{score}
            </span>
            <button
              type="button"
              onClick={() => setIsModalOpen(true)}
              className={`px-3.5 py-2 rounded-xl border text-xs font-bold flex items-center gap-1.5 transition-colors ${
                isDark
                  ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
                  : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
              }`}
            >
              <span>Tüm Liste</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* Progress Bar */}
        <div className="w-full h-1.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden mb-4">
          <div
            className="h-full bg-[#FF6B00] transition-all duration-500 rounded-full"
            style={{ width: `${score}%` }}
          />
        </div>

        {/* Highlighted Next Action */}
        {firstMissingStep && (
          <div
            className={`p-3.5 rounded-xl border flex items-center justify-between gap-3 ${
              isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-slate-50 border-slate-200/80'
            }`}
          >
            <div className="min-w-0">
              <span className="text-xs font-bold text-slate-900 dark:text-slate-100 block truncate">
                Sıradaki Adım: {firstMissingStep.title}
              </span>
              <span className="text-[11px] text-slate-500 dark:text-slate-400 block truncate mt-0.5">
                {firstMissingStep.description}
              </span>
            </div>
            <button
              type="button"
              onClick={() => router.push(firstMissingStep.actionUrl)}
              className="px-3.5 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-extrabold shrink-0 flex items-center gap-1.5 transition-colors"
            >
              <span>{firstMissingStep.actionText}</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        )}
      </div>

      <StoreReadinessModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        readinessData={readinessData}
      />
    </>
  );
}
