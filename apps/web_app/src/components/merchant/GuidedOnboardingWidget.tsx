import React from 'react';
import { useRouter } from 'next/router';
import { ArrowRight, Clock, AlertTriangle, Tag } from 'lucide-react';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

interface GuidedOnboardingWidgetProps {
  pendingOrdersCount?: number;
  hasWorkingHours?: boolean;
  hasCampaigns?: boolean;
  hasProducts?: boolean;
}

export default function GuidedOnboardingWidget({
  pendingOrdersCount = 0,
  hasWorkingHours = true,
  hasCampaigns = true,
  hasProducts = true,
}: GuidedOnboardingWidgetProps) {
  const router = useRouter();
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  // Guided Action Items
  const actions = [];

  if (pendingOrdersCount > 0) {
    actions.push({
      id: 'pending_orders',
      type: 'URGENT',
      icon: AlertTriangle,
      title: `${pendingOrdersCount} Sipariş Onay Bekliyor!`,
      description: 'Müşterilerinizi bekletmemek için hemen sipariş akışını inceleyin.',
      buttonText: 'Siparişlere Git',
      href: '/merchant/orders',
      color: 'bg-amber-500 text-white',
    });
  }

  if (!hasWorkingHours) {
    actions.push({
      id: 'working_hours',
      type: 'SETUP',
      icon: Clock,
      title: 'Çalışma Saatlerinizi Belirleyin',
      description: 'Haftalık açılış ve kapanış saatlerinizi ayarlayarak mağazanızı otomatik açın.',
      buttonText: 'Saatleri Ayarla',
      href: '/merchant/settings',
      color: 'bg-[#FF6B00] text-white',
    });
  }

  if (!hasCampaigns) {
    actions.push({
      id: 'campaigns',
      type: 'GROWTH',
      icon: Tag,
      title: 'İlk İndirim Kuponunuzu Tanımlayın',
      description: 'Yeni müşteriler çekmek için %10 hoş geldin indirimi kuponu oluşturun.',
      buttonText: 'Kupon Oluştur',
      href: '/merchant/campaigns',
      color: 'bg-[#00A651] text-white',
    });
  }

  if (actions.length === 0) {
    return null;
  }

  return (
    <div className="space-y-3">
      {actions.map((action) => {
        const Icon = action.icon;
        return (
          <div
            key={action.id}
            className={`p-4 rounded-2xl border flex flex-col md:flex-row md:items-center justify-between gap-4 transition-colors ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
            }`}
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-200 flex items-center justify-center shrink-0">
                <Icon className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-sm font-extrabold tracking-tight">{action.title}</h4>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                  {action.description}
                </p>
              </div>
            </div>

            <button
              type="button"
              onClick={() => router.push(action.href)}
              className="px-4 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-extrabold text-xs flex items-center justify-center gap-2 transition-colors shrink-0"
            >
              <span>{action.buttonText}</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        );
      })}
    </div>
  );
}
