import { SavedMerchantAccount } from '../types/auth.types';

const SAVED_ACCOUNTS_STORAGE_KEY = 'hoppa_merchant_saved_accounts';
const MAX_SAVED_ACCOUNTS = 8;

/**
 * XSS ve kontrol karakteri risklerine karşı görüntülenen metinleri temizler.
 */
export function sanitizeAccountText(rawValue: string | undefined | null, fallback = ''): string {
  if (!rawValue || typeof rawValue !== 'string') {
    return fallback;
  }
  return rawValue
    .replace(/[\u0000-\u001F\u007F]/g, '')
    .replace(/[<>]/g, '')
    .trim()
    .slice(0, 120);
}

function isValidSavedProfile(candidate: unknown): candidate is SavedMerchantAccount {
  if (!candidate || typeof candidate !== 'object') {
    return false;
  }
  const item = candidate as Record<string, unknown>;
  return (
    typeof item.id === 'string' &&
    item.id.length > 0 &&
    typeof item.email === 'string' &&
    item.email.includes('@') &&
    typeof item.businessName === 'string' &&
    typeof item.role === 'string' &&
    typeof item.lastLoginAt === 'string'
  );
}

/**
 * Cihazdaki kayıtlı satıcı profillerini (tokensız ve şifresiz) güvenli şekilde okur.
 */
export function getSavedMerchantAccounts(): SavedMerchantAccount[] {
  if (typeof window === 'undefined') {
    return [];
  }

  try {
    const raw = window.localStorage.getItem(SAVED_ACCOUNTS_STORAGE_KEY);
    if (!raw) {
      return [];
    }

    const parsed: unknown = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      return [];
    }

    return parsed
      .filter(isValidSavedProfile)
      .map((profile) => ({
        id: profile.id,
        email: sanitizeAccountText(profile.email).toLowerCase(),
        merchantName: sanitizeAccountText(profile.merchantName, profile.businessName),
        businessName: sanitizeAccountText(profile.businessName, 'Hoppa Mağazası'),
        role: sanitizeAccountText(profile.role, 'merchant'),
        avatarUrl: typeof profile.avatarUrl === 'string' ? profile.avatarUrl.trim() : undefined,
        lastLoginAt: profile.lastLoginAt,
      }))
      .sort((a, b) => new Date(b.lastLoginAt).getTime() - new Date(a.lastLoginAt).getTime());
  } catch (err: unknown) {
    console.error('[saved-accounts.getSavedMerchantAccounts] Okuma/JSON hatası:', err);
    return [];
  }
}

function persistAccounts(accounts: SavedMerchantAccount[]): boolean {
  if (typeof window === 'undefined') {
    return false;
  }

  try {
    window.localStorage.setItem(SAVED_ACCOUNTS_STORAGE_KEY, JSON.stringify(accounts));
    return true;
  } catch (err: unknown) {
    console.error('[saved-accounts.persistAccounts] LocalStorage yazma hatası:', err);
    // QuotaExceededError durumunda en eski kayıtları budayarak tekrar dene
    if (accounts.length > 1) {
      try {
        window.localStorage.setItem(
          SAVED_ACCOUNTS_STORAGE_KEY,
          JSON.stringify(accounts.slice(0, 3))
        );
        return true;
      } catch (retryErr: unknown) {
        console.error('[saved-accounts.persistAccounts] Tekrar deneme başarısız:', retryErr);
      }
    }
    return false;
  }
}

/**
 * Başarılı giriş sonrası yalnızca güvenli profil özetini kaydeder veya günceller.
 */
export function upsertSavedMerchantAccount(account: SavedMerchantAccount): SavedMerchantAccount[] {
  const sanitized: SavedMerchantAccount = {
    id: account.id,
    email: sanitizeAccountText(account.email).toLowerCase(),
    merchantName: sanitizeAccountText(account.merchantName, account.businessName),
    businessName: sanitizeAccountText(account.businessName, 'Hoppa Mağazası'),
    role: sanitizeAccountText(account.role, 'merchant'),
    avatarUrl: account.avatarUrl ? account.avatarUrl.trim() : undefined,
    lastLoginAt: account.lastLoginAt || new Date().toISOString(),
  };

  const current = getSavedMerchantAccounts().filter(
    (item) => item.id !== sanitized.id && item.email !== sanitized.email
  );
  const next = [sanitized, ...current].slice(0, MAX_SAVED_ACCOUNTS);
  persistAccounts(next);
  return next;
}

/**
 * Seçilen profili cihaz hafızasından kaldırır.
 */
export function removeSavedMerchantAccount(accountId: string): SavedMerchantAccount[] {
  const next = getSavedMerchantAccounts().filter((item) => item.id !== accountId);
  persistAccounts(next);
  return next;
}
