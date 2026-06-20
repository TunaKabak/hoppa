/**
 * Saved profile metadata stored safely in local storage.
 * Strictly no passwords or access tokens allowed.
 */
export interface SavedProfile {
  id: string;
  email: string;
  merchantName: string;
  avatarUrl?: string;
  lastLoginAt: string; // ISO String format
}

/**
 * standard credentials for account login.
 */
export interface LoginCredentials {
  email: string;
  password?: string; // Optional if session is still active
}

/**
 * Backend response representing the authenticated merchant user.
 */
export interface User {
  id: string;
  email: string;
  merchantName: string;
  avatarUrl?: string;
  role: 'merchant' | 'super_admin';
}

/**
 * Standard API response wrapper for authentication endpoints.
 */
export interface AuthResponse {
  success: boolean;
  message?: string;
  user?: User;
}

/**
 * Active authentication container views.
 */
export type AuthView = 'chooser' | 'login' | 'password_only';
