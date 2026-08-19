import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { 
  ShieldCheck, AlertTriangle, CheckCircle2, ArrowRight, 
  Sparkles, ExternalLink, RefreshCw 
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
        <div className={`p-4 rounded-2xl border flex flex-col sm:flex-row items-center justify-between gap-4 transition-all ${
          isDark ? 'bg-emerald-500/10 border-emerald-500/30' : 'bg-emerald-50 border-emerald-200'
        }`}>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-emerald-500 text-white flex items-center justify-center font-bold shrink-0">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h4 className="text-sm font-black text-emerald-900 dark:text-emerald-300">Mağazanız Tam Kapasite Yayına Hazır! 🎉</h4>
                <span className="text-[10px] font-black px-2 py-0.5 rounded-md bg-emerald-500 text-white">
                  %100 Tamamlandı
                </span>
              </div>
              <p className="text-xs text-emerald-700 dark:text-emerald-400 mt-0.5">
                Tüm prosedür adımları, çalışma saatleri ve ürün kataloğunuz eksiksiz.
              </p>
            </div>
          </div>

          <button
            onClick={() => setIsModalOpen(true)}
            className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-black flex items-center gap-1.5 shrink-0 transition-all active:scale-95"
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
      <div className={`p-5 rounded-2xl border transition-all ${
        isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
      }`}>
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#FF6B00]/15 text-[#FF6B00] flex items-center justify-center font-bold shrink-0">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h4 className="text-sm font-black tracking-tight">Mağaza Hazırlık Prosedürü</h4>
                <span className="text-[10px] font-black px-2 py-0.5 rounded-md bg-[#FF6B00]/10 text-[#FF6B00]">
                  %{score} Tamamlandı
                </span>
              </div>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                Canlıya alınıp sipariş kabul etmek için kalan {missingSteps.length} adımı tamamlayınız.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <button
              onClick={() => setIsModalOpen(true)}
              className="px-4 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-700 dark:text-slate-200 text-xs font-black flex items-center gap-1.5 transition-all"
            >
              <span>Tüm Prosedür ({completedStepsCount}/{totalSteps})</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* Progress Bar */}
        <div className="w-full h-2.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden mb-4">
          <div 
            className="h-full bg-gradient-to-r from-[#E95D22] to-[#FF6B00] transition-all duration-500 rounded-full"
            style={{ width: `${score}%` }}
          />
        </div>

        {/* Highlighted Next Action */}
        {firstMissingStep && (
          <div className={`p-3.5 rounded-xl border flex items-center justify-between gap-3 ${
            isDark ? 'bg-slate-800/60 border-slate-700' : 'bg-orange-50/60 border-orange-100'
          }`}>
            <div className="flex items-center gap-2.5 min-w-0">
              <AlertTriangle className="w-4 h-4 text-[#FF6B00] shrink-0" />
              <div className="min-w-0">
                <span className="text-xs font-black text-[#FF6B00] block truncate">Sıradaki Adım: {firstMissingStep.title}</span>
                <span className="text-[11px] text-slate-500 dark:text-slate-400 block truncate">{firstMissingStep.description}</span>
              </div>
            </div>
            <button
              onClick={() => router.push(firstMissingStep.actionUrl)}
              className="px-3.5 py-1.5 rounded-lg bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-extrabold shrink-0 flex items-center gap-1 transition-all active:scale-95"
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
