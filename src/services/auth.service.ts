import { LoginCredentials, AuthResponse, User, SavedProfile } from '../types/auth.types';
import { StorageUtils } from '../utils/storage.utils';

// Simulate backend database
const MOCK_MERCHANTS: Record<string, { name: string; role: 'merchant' | 'super_admin'; password: string; avatarUrl?: string }> = {
  'admin@hoppa.com': {
    name: 'Hoppa Global Admin',
    role: 'super_admin',
    password: '1234',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&h=150&q=80',
  },
  'info@sinerji.com': {
    name: 'Sinerji Market',
    role: 'merchant',
    password: '1234',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&h=150&q=80',
  },
  'tuna@hoppa.com': {
    name: 'Tuna Bakery',
    role: 'merchant',
    password: '1234',
    avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=150&h=150&q=80',
  }
};

const SESSION_COOKIE_KEY = 'hoppa_active_session_email';

/**
 * Authentication service handling mock requests, session validation (cookie simulation),
 * and local storage profile storage.
 */
export const AuthService = {
  /**
   * Simulates network latency.
   */
  delay(ms = 800): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  },

  /**
   * Simulates standard email/password login endpoint.
   * If login is successful, adds/updates the profile in SavedProfiles.
   */
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    await this.delay(1000);
    const email = credentials.email.trim().toLowerCase();
    const password = credentials.password;

    if (!email) {
      return { success: false, message: 'Lütfen geçerli bir e-posta adresi giriniz.' };
    }

    if (!password) {
      return { success: false, message: 'Lütfen şifrenizi giriniz.' };
    }

    const matchedUser = MOCK_MERCHANTS[email];

    // If matches mock records or password meets basic length (for other test emails)
    if (matchedUser) {
      if (matchedUser.password !== password) {
        return { success: false, message: 'Girdiğiniz şifre hatalı. Lütfen tekrar deneyiniz.' };
      }
      
      const user: User = {
        id: Math.random().toString(36).substring(2, 11),
        email,
        merchantName: matchedUser.name,
        avatarUrl: matchedUser.avatarUrl,
        role: matchedUser.role,
      };

      // Simulate HttpOnly Cookie placement by writing to sessionStorage (secure container)
      if (typeof window !== 'undefined') {
        sessionStorage.setItem(SESSION_COOKIE_KEY, email);
      }

      // Add/update to device's saved profiles list
      const savedProfile: SavedProfile = {
        id: user.id,
        email: user.email,
        merchantName: user.merchantName,
        avatarUrl: user.avatarUrl,
        lastLoginAt: new Date().toISOString(),
      };
      StorageUtils.saveProfile(savedProfile);

      return { success: true, user };
    }

    // Dynamic merchant signup on the fly (for testing flexibility)
    if (password.length >= 4) {
      const generatedName = email.split('@')[0].toUpperCase() + ' Store';
      const user: User = {
        id: Math.random().toString(36).substring(2, 11),
        email,
        merchantName: generatedName,
        role: 'merchant',
      };

      if (typeof window !== 'undefined') {
        sessionStorage.setItem(SESSION_COOKIE_KEY, email);
      }

      const savedProfile: SavedProfile = {
        id: user.id,
        email: user.email,
        merchantName: user.merchantName,
        lastLoginAt: new Date().toISOString(),
      };
      StorageUtils.saveProfile(savedProfile);

      return { success: true, user };
    }

    return { success: false, message: 'Bu e-posta ile kayıtlı bir hesap bulunamadı (Test için şifre en az 4 karakter olmalıdır).' };
  },

  /**
   * Simulates checking active backend session cookie.
   * If cookie (sessionStorage item) exists for the given email, log them in instantly.
   */
  async checkSession(email: string): Promise<AuthResponse> {
    await this.delay(600);
    if (typeof window === 'undefined') return { success: false };

    const activeSessionEmail = sessionStorage.getItem(SESSION_COOKIE_KEY);

    if (activeSessionEmail && activeSessionEmail.toLowerCase() === email.toLowerCase()) {
      const matchedUser = MOCK_MERCHANTS[activeSessionEmail];
      const name = matchedUser ? matchedUser.name : activeSessionEmail.split('@')[0].toUpperCase() + ' Store';
      const role = matchedUser ? matchedUser.role : 'merchant';
      const avatarUrl = matchedUser ? matchedUser.avatarUrl : undefined;

      const user: User = {
        id: Math.random().toString(36).substring(2, 11),
        email: activeSessionEmail,
        merchantName: name,
        avatarUrl,
        role,
      };

      // Refresh last login date in local storage
      const savedProfile: SavedProfile = {
        id: user.id,
        email: user.email,
        merchantName: user.merchantName,
        avatarUrl: user.avatarUrl,
        lastLoginAt: new Date().toISOString(),
      };
      StorageUtils.saveProfile(savedProfile);

      return { success: true, user };
    }

    return { success: false, message: 'Oturum süresi dolmuş veya geçersiz.' };
  },

  /**
   * Simulates logging out, clearing cookie.
   */
  async logout(): Promise<AuthResponse> {
    await this.delay(400);
    if (typeof window !== 'undefined') {
      sessionStorage.removeItem(SESSION_COOKIE_KEY);
    }
    return { success: true };
  }
};
