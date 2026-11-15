import React from 'react';
import { ChevronRight, Plus, Shield, UserCheck, X } from 'lucide-react';
import { SavedMerchantAccount } from '../../types/auth.types';
import { sanitizeAccountText } from '../../utils/saved-accounts';

interface AccountChooserProps {
  accounts: SavedMerchantAccount[];
  activeAccountId: string | null;
  verifyingAccountId: string | null;
  isDark: boolean;
  onSelectAccount: (account: SavedMerchantAccount) => void;
  onRemoveAccount: (accountId: string) => void;
  onUseAnotherAccount: () => void;
}

function getRoleBadgeLabel(role: string): string {
  if (role === 'super_admin' || role === 'admin') {
    return 'SÜPER ADMİN';
  }
  return 'SATICI';
}

function formatLastLogin(isoDate: string): string {
  try {
    const parsed = new Date(isoDate);
    if (Number.isNaN(parsed.getTime())) {
      return 'Kayıtlı profil';
    }
    return parsed.toLocaleDateString('tr-TR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  } catch {
    return 'Kayıtlı profil';
  }
}

export default function AccountChooser({
  accounts,
  activeAccountId,
  verifyingAccountId,
  isDark,
  onSelectAccount,
  onRemoveAccount,
  onUseAnotherAccount,
}: AccountChooserProps) {
  return (
    <div className="space-y-4">
      <div className="space-y-2.5 max-h-[340px] overflow-y-auto pr-1">
        {accounts.map((account) => {
          const safeBusiness = sanitizeAccountText(account.businessName, 'Hoppa Mağazası');
          const safeMerchantName = sanitizeAccountText(account.merchantName, safeBusiness);
          const safeEmail = sanitizeAccountText(account.email);
          const initial = safeBusiness.charAt(0).toUpperCase() || 'H';
          const isCurrentSession = activeAccountId === account.id;
          const isVerifying = verifyingAccountId === account.id;
          const isAdminRole = account.role === 'super_admin' || account.role === 'admin';

          return (
            <div
              key={account.id}
              className={`group relative flex items-center gap-3 p-3.5 rounded-2xl border transition-all ${
                isDark
                  ? 'bg-slate-950/70 border-slate-800 hover:border-[#FF6B00]/60'
                  : 'bg-slate-50/70 border-slate-200 hover:border-[#FF6B00]/60 hover:bg-orange-50/30'
              }`}
            >
              <button
                type="button"
                disabled={verifyingAccountId !== null}
                onClick={() => onSelectAccount(account)}
                className="flex-1 flex items-center gap-3 text-left min-w-0 disabled:opacity-60"
              >
                {account.avatarUrl ? (
                  <img
                    src={account.avatarUrl}
                    alt={safeBusiness}
                    className="w-11 h-11 rounded-xl object-cover shrink-0 border border-slate-200 dark:border-slate-700"
                  />
                ) : (
                  <div className="w-11 h-11 rounded-xl bg-gradient-to-tr from-[#E95D22] to-[#FF8C00] text-white font-black text-base flex items-center justify-center shrink-0">
                    {initial}
                  </div>
                )}

                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-1.5 flex-wrap">
                    <span className="text-sm font-black truncate">{safeBusiness}</span>
                    <span
                      className={`px-1.5 py-0.5 rounded text-[9px] font-black inline-flex items-center gap-0.5 ${
                        isAdminRole
                          ? 'bg-[#FF6B00]/15 text-[#FF6B00]'
                          : 'bg-slate-200/80 dark:bg-slate-800 text-slate-600 dark:text-slate-300'
                      }`}
                    >
                      {isAdminRole && <Shield className="w-2.5 h-2.5" />}
                      {getRoleBadgeLabel(account.role)}
                    </span>
                    {isCurrentSession && (
                      <span className="px-1.5 py-0.5 rounded text-[9px] font-black bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 inline-flex items-center gap-0.5">
                        <UserCheck className="w-2.5 h-2.5" />
                        Aktif Oturum
                      </span>
                    )}
                  </div>

                  <p className="text-xs font-semibold text-slate-400 truncate mt-0.5">
                    {safeEmail}
                  </p>
                  <p className="text-[10px] font-semibold text-slate-400/80 mt-0.5">
                    {safeMerchantName !== safeBusiness ? `${safeMerchantName} • ` : ''}
                    Son giriş: {formatLastLogin(account.lastLoginAt)}
                  </p>
                </div>

                {isVerifying ? (
                  <div className="w-4 h-4 border-2 border-[#FF6B00] border-t-transparent rounded-full animate-spin shrink-0" />
                ) : (
                  <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-[#FF6B00] shrink-0 transition-colors" />
                )}
              </button>

              <button
                type="button"
                disabled={verifyingAccountId !== null}
                onClick={(e) => {
                  e.stopPropagation();
                  onRemoveAccount(account.id);
                }}
                title="Profili Bu Cihazdan Kaldır"
                aria-label={`${safeBusiness} profilini kaldır`}
                className={`p-1.5 rounded-lg text-slate-400 hover:text-rose-500 transition-colors shrink-0 ${
                  isDark ? 'hover:bg-slate-800' : 'hover:bg-slate-200/70'
                }`}
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          );
        })}
      </div>

      <button
        type="button"
        disabled={verifyingAccountId !== null}
        onClick={onUseAnotherAccount}
        className={`w-full py-3.5 px-4 rounded-2xl border border-dashed text-xs font-black flex items-center justify-center gap-2 transition-colors ${
          isDark
            ? 'border-slate-700 text-slate-200 hover:border-[#FF6B00] hover:text-[#FF6B00] hover:bg-slate-950/60'
            : 'border-slate-300 text-slate-700 hover:border-[#FF6B00] hover:text-[#FF6B00] hover:bg-orange-50/40'
        }`}
      >
        <Plus className="w-4 h-4" />
        <span>Başka Bir Hesap Kullan</span>
      </button>
    </div>
  );
}
