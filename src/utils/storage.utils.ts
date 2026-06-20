import { SavedProfile } from '../types/auth.types';

const STORAGE_KEY = 'hoppa_merchant_saved_profiles';

/**
 * Escapes HTML characters to prevent XSS vulnerability when rendering strings.
 */
export function sanitizeString(str: string): string {
  if (!str) return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/\//g, '&#x2F;');
}

/**
 * Safe local storage utility wrapper with error handling & sanitization
 */
export const StorageUtils = {
  /**
   * Retrieves saved profiles from LocalStorage, sorted by lastLoginAt (descending)
   */
  getSavedProfiles(): SavedProfile[] {
    if (typeof window === 'undefined') return [];

    try {
      const data = localStorage.getItem(STORAGE_KEY);
      if (!data) return [];

      const parsed: unknown = JSON.parse(data);
      if (!Array.isArray(parsed)) {
        return [];
      }

      // Safe casting and schema filtering
      const profiles: SavedProfile[] = parsed
        .filter((item): item is SavedProfile => {
          return (
            typeof item === 'object' &&
            item !== null &&
            'id' in item &&
            'email' in item &&
            'merchantName' in item &&
            'lastLoginAt' in item
          );
        })
        .map(item => ({
          id: sanitizeString(item.id),
          email: sanitizeString(item.email),
          merchantName: sanitizeString(item.merchantName),
          avatarUrl: item.avatarUrl ? sanitizeString(item.avatarUrl) : undefined,
          lastLoginAt: sanitizeString(item.lastLoginAt),
        }));

      // Sort by last login date descending
      return profiles.sort(
        (a, b) => new Date(b.lastLoginAt).getTime() - new Date(a.lastLoginAt).getTime()
      );
    } catch (error) {
      console.error('[StorageUtils.getSavedProfiles] Failed to parse saved profiles:', error);
      // Attempt cleanup of corrupted key
      try {
        localStorage.removeItem(STORAGE_KEY);
      } catch (cleanError) {
        console.error('[StorageUtils] Failed to remove corrupted key:', cleanError);
      }
      return [];
    }
  },

  /**
   * Saves or updates a profile. Moves it to the top of the stack.
   * Gracefully handles QuotaExceededError.
   */
  saveProfile(profile: SavedProfile): boolean {
    if (typeof window === 'undefined') return false;

    try {
      const currentProfiles = this.getSavedProfiles();
      const filtered = currentProfiles.filter(p => p.email !== profile.email);
      
      const updatedProfile: SavedProfile = {
        ...profile,
        merchantName: sanitizeString(profile.merchantName),
        email: sanitizeString(profile.email),
        lastLoginAt: new Date().toISOString(),
      };

      const newProfiles = [updatedProfile, ...filtered];
      localStorage.setItem(STORAGE_KEY, JSON.stringify(newProfiles));
      return true;
    } catch (error) {
      console.error('[StorageUtils.saveProfile] Failed to save profile:', error);
      
      // Handle LocalStorage quota exceeded safely
      if (
        error instanceof DOMException &&
        (error.name === 'QuotaExceededError' ||
          error.name === 'NS_ERROR_DOM_QUOTA_REACHED')
      ) {
        console.warn('[StorageUtils.saveProfile] Quota exceeded. Evicting oldest profiles...');
        return this.evictAndSave(profile);
      }
      return false;
    }
  },

  /**
   * Removes a saved profile by its unique ID.
   */
  removeProfile(id: string): void {
    if (typeof window === 'undefined') return;

    try {
      const currentProfiles = this.getSavedProfiles();
      const filtered = currentProfiles.filter(p => p.id !== id);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(filtered));
    } catch (error) {
      console.error('[StorageUtils.removeProfile] Failed to remove profile:', error);
    }
  },

  /**
   * Internal helper to evict oldest profiles if LocalStorage is full.
   */
  evictAndSave(profile: SavedProfile): boolean {
    try {
      const currentProfiles = this.getSavedProfiles();
      if (currentProfiles.length <= 1) {
        // Only one item and still full, can't clear anything else
        return false;
      }
      
      // Remove oldest (last item in sorted array) and retry
      currentProfiles.pop();
      localStorage.setItem(STORAGE_KEY, JSON.stringify(currentProfiles));
      return this.saveProfile(profile);
    } catch (e) {
      console.error('[StorageUtils.evictAndSave] Final fallback failed:', e);
      return false;
    }
  }
};
