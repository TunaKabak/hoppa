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

export const setMerchantAuth = (token: string, merchant: MerchantProfile) => {
  if (typeof window === 'undefined') return;
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(MERCHANT_KEY, JSON.stringify(merchant));
};

export const clearMerchantAuth = () => {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(MERCHANT_KEY);
};

export const getApiBaseUrl = (): string => {
  return process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';
};

export const merchantApiFetch = async (endpoint: string, options: RequestInit = {}) => {
  if (typeof window === 'undefined') {
    return { error: true, message: 'Client-side execution required' };
  }

  const token = getMerchantToken();
  const baseUrl = getApiBaseUrl();
  const url = `${baseUrl}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(url, {
    ...options,
    headers,
  });

  const data = await response.json();

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
};
