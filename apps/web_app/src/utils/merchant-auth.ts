export interface MerchantProfile {
  id: string;
  email: string;
  businessName: string;
  status: 'PENDING' | 'ACTIVE' | 'REVISION' | 'REJECTED' | 'ON_HOLD';
  role: string;
  district?: string;
  phone?: string;
  merchantType?: string;
}

const TOKEN_KEY = 'hoppa_merchant_token';
const REFRESH_TOKEN_KEY = 'hoppa_merchant_refresh_token';
const MERCHANT_KEY = 'hoppa_merchant_profile';
const SELECTED_SHOP_KEY = 'hoppa_merchant_selected_shop';

export const getMerchantToken = (): string | null => {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(TOKEN_KEY);
};

export const getMerchantRefreshToken = (): string | null => {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(REFRESH_TOKEN_KEY);
};

export const getMerchantProfile = (): MerchantProfile | null => {
  if (typeof window === 'undefined') return null;
  const raw = localStorage.getItem(MERCHANT_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
};

export const getSelectedShopId = (): string | null => {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(SELECTED_SHOP_KEY);
};

export const setSelectedShopId = (shopId: string | null) => {
  if (typeof window === 'undefined') return;
  if (shopId) {
    localStorage.setItem(SELECTED_SHOP_KEY, shopId);
  } else {
    localStorage.removeItem(SELECTED_SHOP_KEY);
  }
};

export const setMerchantAuth = (token: string, merchant: MerchantProfile, refreshToken?: string) => {
  if (typeof window === 'undefined') return;
  localStorage.setItem(TOKEN_KEY, token);
  if (refreshToken) {
    localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
  }
  localStorage.setItem(MERCHANT_KEY, JSON.stringify(merchant));
};

export const updateMerchantTokens = (token: string, refreshToken?: string) => {
  if (typeof window === 'undefined') return;
  localStorage.setItem(TOKEN_KEY, token);
  if (refreshToken) {
    localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
  }
};

export const clearMerchantAuth = () => {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
  localStorage.removeItem(MERCHANT_KEY);
  localStorage.removeItem(SELECTED_SHOP_KEY);
};

export const getApiBaseUrl = (): string => {
  let rawUrl = process.env.NEXT_PUBLIC_API_URL || 'https://hoppa-backend.onrender.com/api';
  rawUrl = rawUrl.trim().replace(/\/+$/, '');
  if (!rawUrl.endsWith('/api')) {
    rawUrl += '/api';
  }
  return rawUrl;
};

// Singleton promise to prevent multiple parallel refresh requests
let isRefreshing = false;
let refreshPromise: Promise<string | null> | null = null;

export const refreshMerchantToken = async (): Promise<string | null> => {
  if (typeof window === 'undefined') return null;
  const refreshToken = getMerchantRefreshToken();
  if (!refreshToken) return null;

  if (isRefreshing && refreshPromise) {
    return refreshPromise;
  }

  isRefreshing = true;
  refreshPromise = (async () => {
    try {
      const baseUrl = getApiBaseUrl();
      const res = await fetch(`${baseUrl}/merchant/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken }),
      });

      const json = await res.json();
      if (res.ok && !json.error && json.data?.token) {
        updateMerchantTokens(json.data.token, json.data.refreshToken);
        return json.data.token as string;
      } else {
        clearMerchantAuth();
        return null;
      }
    } catch (e) {
      return null;
    } finally {
      isRefreshing = false;
      refreshPromise = null;
    }
  })();

  return refreshPromise;
};

export const merchantApiFetch = async (endpoint: string, options: RequestInit = {}): Promise<any> => {
  if (typeof window === 'undefined') {
    return { error: true, message: 'Client-side execution required' };
  }

  let token = getMerchantToken();
  const selectedShopId = getSelectedShopId();
  const baseUrl = getApiBaseUrl();
  const url = `${baseUrl}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;

  const buildHeaders = (authToken: string | null) => {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> || {}),
    };

    if (authToken) {
      headers['Authorization'] = `Bearer ${authToken}`;
    }

    if (selectedShopId) {
      headers['x-business-id'] = selectedShopId;
    }
    return headers;
  };

  try {
    let response = await fetch(url, {
      ...options,
      headers: buildHeaders(token),
    });

    // 401 Hatası alındığında ve endpoint login/refresh değilse sessizce token yenilemeyi dene (Silent Refresh)
    const isAuthEndpoint = endpoint.includes('/merchant/auth/login') || endpoint.includes('/merchant/auth/refresh');
    if (response.status === 401 && !isAuthEndpoint) {
      const newToken = await refreshMerchantToken();
      if (newToken) {
        // Yeni token ile isteği tekrarla
        response = await fetch(url, {
          ...options,
          headers: buildHeaders(newToken),
        });
      }
    }

    const contentType = response.headers.get('content-type') || '';
    let data: any = {};

    if (contentType.includes('application/json')) {
      try {
        data = await response.json();
      } catch (_) {
        data = { message: 'Sunucudan geçersiz JSON yanıtı alındı.' };
      }
    } else {
      const text = await response.text();
      if (response.status === 404) {
        throw new Error(`API Uç Noktası Bulunamadı (404): ${endpoint}`);
      } else if (response.status >= 500) {
        throw new Error('Sunucu servis veremiyor (500/502). Lütfen az sonra tekrar deneyin.');
      } else {
        throw new Error(`Beklenmeyen yanıt alındı (${response.status}).`);
      }
    }

    if (!response.ok) {
      if (response.status === 401) {
        clearMerchantAuth();
        if (typeof window !== 'undefined' && window.location.pathname.startsWith('/merchant') && !window.location.pathname.includes('/login')) {
          window.location.href = '/merchant/login';
        }
      }
      throw new Error(data.message || 'API Hatası oluştu.');
    }

    return data;
  } catch (err: any) {
    if (err.name === 'TypeError' && err.message?.includes('fetch')) {
      throw new Error('Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.');
    }
    throw err;
  }
};
