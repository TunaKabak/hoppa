import React from 'react';
import { ChevronRight, Plus, X } from 'lucide-react';
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

const GENERIC_OWNER_PLACEHOLDERS = new Set([
  'super admin',
  'super_admin',
  'süper admin',
  'admin',
  'sistem yönetimi',
  'merchant',
  'satıcı',
]);

function resolveAccountMetaLabel(
  account: SavedMerchantAccount,
  safeBusiness: string,
  safeMerchantName: string
): string {
  const normalizedOwner = safeMerchantName.trim().toLowerCase();
  const hasDistinctOwner =
    normalizedOwner.length > 0 &&
    normalizedOwner !== safeBusiness.trim().toLowerCase() &&
    !GENERIC_OWNER_PLACEHOLDERS.has(normalizedOwner);

  if (account.role === 'super_admin') {
    return hasDistinctOwner
      ? `${safeMerchantName} · Hoppa Merkez Yönetimi`
      : 'Hoppa Merkez Yönetimi';
  }
  if (account.role === 'admin') {
    return hasDistinctOwner
      ? `${safeMerchantName} · Operasyon Yönetimi`
      : 'Operasyon Yönetimi';
  }
  return hasDistinctOwner ? safeMerchantName : 'Mağaza Yönetimi';
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
          const metaLabel = resolveAccountMetaLabel(account, safeBusiness, safeMerchantName);

          return (
            <div
              key={account.id}
              className={`group relative flex items-center gap-3 p-3.5 rounded-2xl border transition-all ${
                isDark
                  ? `bg-slate-950/70 ${isCurrentSession ? 'border-slate-700' : 'border-slate-800'} hover:border-slate-700`
                  : `bg-white ${isCurrentSession ? 'border-slate-300' : 'border-slate-200/90'} hover:border-slate-300 shadow-2xs`
              }`}
            >
              <button
                type="button"
                disabled={verifyingAccountId !== null}
                onClick={() => onSelectAccount(account)}
                className="flex-1 flex items-center gap-3 text-left min-w-0 disabled:opacity-60"
              >
                <div className="relative shrink-0">
                  {account.avatarUrl ? (
                    <img
                      src={account.avatarUrl}
                      alt={safeBusiness}
                      className="w-11 h-11 rounded-xl object-cover border border-slate-200 dark:border-slate-700"
                    />
                  ) : isAdminRole ? (
                    <img
                      src="/logo-square-orange.png"
                      alt="Hoppa"
                      className="w-11 h-11 rounded-xl object-cover shadow-2xs ring-1 ring-black/5"
                    />
                  ) : (
                    <div
                      className={`w-11 h-11 rounded-xl font-extrabold text-sm flex items-center justify-center border ${
                        isDark
                          ? 'bg-slate-900 border-slate-700 text-slate-100'
                          : 'bg-slate-900 border-slate-800 text-white'
                      }`}
                    >
                      {initial}
                    </div>
                  )}
                  {isCurrentSession && (
                    <span
                      title="Bu cihazda oturum açık"
                      className={`absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full bg-[#00A651] ring-2 ${
                        isDark ? 'ring-slate-900' : 'ring-white'
                      }`}
                    />
                  )}
                </div>

                <div className="min-w-0 flex-1">
                  <p className="text-sm font-extrabold tracking-tight truncate">{safeBusiness}</p>

                  <p
                    className={`text-xs font-medium truncate mt-0.5 ${
                      isDark ? 'text-slate-400' : 'text-slate-500'
                    }`}
                  >
                    {safeEmail}
                  </p>
                  <p
                    className={`text-[11px] font-medium tabular-nums truncate mt-1 flex items-center gap-1.5 ${
                      isDark ? 'text-slate-500' : 'text-slate-400'
                    }`}
                  >
                    <span
                      className={
                        isDark ? 'text-slate-300 font-semibold' : 'text-slate-600 font-semibold'
                      }
                    >
                      {metaLabel}
                    </span>
                    <span aria-hidden="true">·</span>
                    {isCurrentSession ? (
                      <span className="text-[#00A651] dark:text-emerald-400 font-semibold">
                        Oturum açık
                      </span>
                    ) : (
                      <span>Son giriş {formatLastLogin(account.lastLoginAt)}</span>
                    )}
                  </p>
                </div>

                {isVerifying ? (
                  <div className="w-4 h-4 border-2 border-[#FF6B00] border-t-transparent rounded-full animate-spin shrink-0" />
                ) : (
                  <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-[#FF6B00] shrink-0 transition-colors" />
                )}
              </button>

              <div
                className={`pl-2 ml-0.5 border-l shrink-0 ${
                  isDark ? 'border-slate-800' : 'border-slate-200/70'
                }`}
              >
                <button
                  type="button"
                  disabled={verifyingAccountId !== null}
                  onClick={(e) => {
                    e.stopPropagation();
                    onRemoveAccount(account.id);
                  }}
                  title="Profili Bu Cihazdan Kaldır"
                  aria-label={`${safeBusiness} profilini kaldır`}
                  className={`p-1.5 rounded-lg text-slate-400 hover:text-rose-500 transition-colors ${
                    isDark ? 'hover:bg-slate-800' : 'hover:bg-slate-100'
                  }`}
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
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
