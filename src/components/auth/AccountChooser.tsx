import React from 'react';
import { SavedProfile } from '../../types/auth.types';
import { Trash2, UserPlus, ChevronRight } from 'lucide-react';

interface AccountChooserProps {
  profiles: SavedProfile[];
  onSelectProfile: (profile: SavedProfile) => void;
  onRemoveProfile: (id: string, e: React.MouseEvent) => void;
  onAddAccount: () => void;
}

/**
 * Renders a list of cached local merchant profiles for quick-login/chooser flow.
 */
export const AccountChooser: React.FC<AccountChooserProps> = ({
  profiles,
  onSelectProfile,
  onRemoveProfile,
  onAddAccount,
}) => {
  // Generates unique beautiful HSL background based on merchant name
  const getAvatarGradient = (name: string) => {
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    const h = Math.abs(hash % 360);
    return `linear-gradient(135deg, hsl(${h}, 70%, 65%) 0%, hsl(${(h + 40) % 360}, 75%, 55%) 100%)`;
  };

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .slice(0, 2)
      .map(part => part[0])
      .join('')
      .toUpperCase();
  };

  const formatDate = (isoString: string) => {
    try {
      const date = new Date(isoString);
      return new Intl.DateTimeFormat('tr-TR', {
        dateStyle: 'medium',
        timeStyle: 'short',
      }).format(date);
    } catch {
      return 'Bilinmiyor';
    }
  };

  return (
    <div className="w-full space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Bir Hesap Seçin
        </h2>
        <p className="text-sm text-slate-500 dark:text-slate-400">
          Devam etmek istediğiniz işletme profilini seçiniz.
        </p>
      </div>

      {/* Profiles list */}
      <div className="space-y-3 max-h-[340px] overflow-y-auto pr-1 scrollbar-thin scrollbar-thumb-slate-200 scrollbar-track-transparent">
        {profiles.map((profile) => (
          <div
            key={profile.id}
            onClick={() => onSelectProfile(profile)}
            className="group relative flex items-center justify-between p-4 bg-white/70 dark:bg-slate-800/70 backdrop-blur-md rounded-2xl border border-slate-100 dark:border-slate-700/60 shadow-sm hover:shadow-md hover:border-emerald-500/30 dark:hover:border-emerald-500/20 cursor-pointer transition-all duration-300 transform hover:-translate-y-0.5"
          >
            <div className="flex items-center space-x-4 min-w-0">
              {/* Profile Avatar */}
              <div className="relative flex-shrink-0">
                {profile.avatarUrl ? (
                  <img
                    src={profile.avatarUrl}
                    alt={profile.merchantName}
                    className="w-12 h-12 rounded-xl object-cover shadow-inner border border-slate-100 dark:border-slate-700"
                    onError={(e) => {
                      // Fallback to initials if image loading fails
                      (e.target as HTMLImageElement).style.display = 'none';
                    }}
                  />
                ) : (
                  <div
                    style={{ background: getAvatarGradient(profile.merchantName) }}
                    className="w-12 h-12 rounded-xl flex items-center justify-center text-white font-bold text-lg shadow-md"
                  >
                    {getInitials(profile.merchantName)}
                  </div>
                )}
                {/* Active Indicator dot */}
                <span className="absolute -bottom-1 -right-1 w-3.5 h-3.5 bg-emerald-500 border-2 border-white dark:border-slate-800 rounded-full" />
              </div>

              {/* Profile Details */}
              <div className="min-w-0">
                <h3 className="text-sm font-semibold text-slate-800 dark:text-slate-100 truncate group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors">
                  {profile.merchantName}
                </h3>
                <p className="text-xs text-slate-500 dark:text-slate-400 truncate mt-0.5">
                  {profile.email}
                </p>
                <p className="text-[10px] text-slate-400 dark:text-slate-500 mt-1">
                  Son giriş: {formatDate(profile.lastLoginAt)}
                </p>
              </div>
            </div>

            {/* Action buttons */}
            <div className="flex items-center space-x-1 pl-3 z-10">
              {/* Delete profile button */}
              <button
                type="button"
                onClick={(e) => onRemoveProfile(profile.id, e)}
                title="Profili Cihazdan Kaldır"
                className="p-2 hover:bg-red-50 dark:hover:bg-red-950/30 text-slate-400 hover:text-red-500 dark:hover:text-red-400 rounded-xl transition-all duration-200 opacity-0 group-hover:opacity-100 focus:opacity-100"
              >
                <Trash2 className="w-4 h-4" />
              </button>

              {/* Action indicator */}
              <ChevronRight className="w-5 h-5 text-slate-300 dark:text-slate-600 group-hover:text-emerald-500 dark:group-hover:text-emerald-400 group-hover:translate-x-0.5 transition-all duration-200" />
            </div>
          </div>
        ))}
      </div>

      {/* Footer / Add Account button */}
      <button
        type="button"
        onClick={onAddAccount}
        className="w-full flex items-center justify-center space-x-2 py-4 px-6 border-2 border-dashed border-slate-200 dark:border-slate-700/80 hover:border-emerald-500/40 text-slate-600 dark:text-slate-300 hover:text-emerald-600 dark:hover:text-emerald-400 rounded-2xl transition-all duration-200 hover:bg-slate-50/50 dark:hover:bg-slate-800/30 font-medium text-sm group"
      >
        <UserPlus className="w-4 h-4 group-hover:scale-110 transition-transform" />
        <span>Başka Bir Hesap Ekle</span>
      </button>
    </div>
  );
};
