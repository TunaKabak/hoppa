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
const MERCHANT_KEY = 'hoppa_merchant_profile';
const SELECTED_SHOP_KEY = 'hoppa_merchant_selected_shop';

export const getMerchantToken = (): string | null => {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(TOKEN_KEY);
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

export const setMerchantAuth = (token: string, merchant: MerchantProfile) => {
  if (typeof window === 'undefined') return;
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(MERCHANT_KEY, JSON.stringify(merchant));
};

export const clearMerchantAuth = () => {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(MERCHANT_KEY);
  localStorage.removeItem(SELECTED_SHOP_KEY);
};

export const getApiBaseUrl = (): string => {
  if (process.env.NEXT_PUBLIC_API_URL) {
    return process.env.NEXT_PUBLIC_API_URL;
  }
  return 'https://hoppa-backend.onrender.com/api';
};

export const merchantApiFetch = async (endpoint: string, options: RequestInit = {}) => {
  if (typeof window === 'undefined') {
    return { error: true, message: 'Client-side execution required' };
  }

  const token = getMerchantToken();
  const selectedShopId = getSelectedShopId();
  const baseUrl = getApiBaseUrl();
  const url = `${baseUrl}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  if (selectedShopId) {
    headers['x-business-id'] = selectedShopId;
  }

  try {
    const response = await fetch(url, {
      ...options,
      headers,
    });

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
