/**
 * Güvenli çoklu hesap girişi (Account Chooser) için istemci tarafı tip tanımları.
 * KRİTİK GÜVENLİK: Bu tiplerde ASLA şifre, Access Token veya Refresh Token tutulmaz.
 */

export interface SavedMerchantAccount {
  id: string;
  email: string;
  merchantName: string;
  businessName: string;
  role: string;
  avatarUrl?: string;
  lastLoginAt: string;
}

export type LoginViewMode = 'chooser' | 'password_only' | 'login';

export interface LoginCredentials {
  email: string;
  password: string;
  rememberOnDevice: boolean;
}

export interface LoginFormErrors {
  email?: string;
  password?: string;
}
