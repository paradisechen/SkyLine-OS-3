import { useEffect, useRef, useState } from 'react';
import {
  Check,
  Download,
  FolderOpen,
  Globe,
  HelpCircle,
  ImagePlus,
  Minus,
  Pencil,
  RotateCcw,
  Sun,
  Type,
  UserPlus,
  Users,
  Volume2,
} from 'lucide-react';
import type {
  AdaptivePalette,
  AlbumPhotoItem,
  GameItem,
  SkylineConfig,
  ThemeAppearanceMode,
  UserProfile,
} from '../types/skyline';
import { HUD_THEME_SWATCHES } from '../utils/artworkPalette';
import { buildSkylineConfigQueryString } from '../utils/skylineConfigQuery';
import { DEFAULT_SKYLINE_CONFIG, type Switch2LayoutMetrics } from '../utils/rp5Layout';
import { playUiSound } from '../utils/uiSounds';
import { SwitchPdfIcon } from './SwitchPdfIcons';
import { UiKitAvatar } from './UiKitAvatar';
import { BottomControllerGlyph } from './BottomControllerGlyph';

export type ProfileSettingsTab =
  | 'profile'
  | 'friends'
  | 'customize'
  | 'hud'
  | 'userSettings'
  | 'about';

interface ProfileSettingsViewProps {
  initialTab?: ProfileSettingsTab;
  activeUser: UserProfile;
  users: UserProfile[];
  games: GameItem[];
  config: SkylineConfig;
  palette: AdaptivePalette;
  metrics: Switch2LayoutMetrics;
  onUpdateConfig: (next: SkylineConfig) => void;
  onRenameUser: (userId: string, nextName: string) => void;
  onSelectUser: (userId: string) => void;
  onDeleteUser: (userId: string) => void;
  onLoadAlbumPhotos: (photos: AlbumPhotoItem[], folderLabel: string) => void;
  onApplyAlbumDirectory?: (dirPath: string) => void;
  onOpenUserSelect: () => void;
  onSelectGame: (idx: number) => void;
  onClose: () => void;
}

const TAB_ORDER: ProfileSettingsTab[] = [
  'profile',
  'friends',
  'customize',
  'hud',
  'userSettings',
  'about',
];

export function ProfileSettingsView({
  initialTab = 'profile',
  activeUser,
  users,
  games,
  config,
  palette,
  metrics,
  onUpdateConfig,
  onRenameUser,
  onSelectUser,
  onDeleteUser,
  onLoadAlbumPhotos,
  onApplyAlbumDirectory,
  onOpenUserSelect,
  onSelectGame,
  onClose,
}: ProfileSettingsViewProps) {
  const [activeTab, setActiveTab] = useState<ProfileSettingsTab>(initialTab);
  const [focusZone, setFocusZone] = useState<'sidebar' | 'content'>('sidebar');
  const [contentRowIdx, setContentRowIdx] = useState(0);
  const [editingControl, setEditingControl] = useState(false);
  const [editingName, setEditingName] = useState(false);
  const [draftName, setDraftName] = useState(activeUser.name);
  const [albumDirDraft, setAlbumDirDraft] = useState(config.albumFolderLabel);
  const [showActivityHelp, setShowActivityHelp] = useState(false);
  const [downloadingTheme, setDownloadingTheme] = useState(false);
  const [downloadSuccess, setDownloadSuccess] = useState(false);
  const [downloadError, setDownloadError] = useState<string | null>(null);

  const albumFolderInputRef = useRef<HTMLInputElement>(null);
  const albumFilesInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    setActiveTab(initialTab);
    setContentRowIdx(0);
    setEditingControl(false);
  }, [initialTab]);

  useEffect(() => {
    setDraftName(activeUser.name);
  }, [activeUser.name]);

  useEffect(() => {
    setAlbumDirDraft(config.albumFolderLabel);
  }, [config.albumFolderLabel]);

  const activityCount = Math.min(5, games.length);

  // Scroll focused right-pane control into view cleanly
  useEffect(() => {
    if (focusZone !== 'content') return;
    const el = document.querySelector(`[data-settings-row="${activeTab}-${contentRowIdx}"]`) as HTMLElement | null;
    el?.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  }, [activeTab, contentRowIdx, focusZone]);

  // Complete 2D D-Pad Navigation inside Settings (Sidebar + All Right-Pane Controls)
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      if (target && target.tagName === 'INPUT' && (target as HTMLInputElement).type === 'text') {
        if (e.key === 'Escape') {
          e.preventDefault();
          target.blur();
        }
        return;
      }

      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        if (editingControl) {
          playUiSound('back', config.uiSoundsEnabled);
          setEditingControl(false);
        } else if (focusZone === 'content') {
          setFocusZone('sidebar');
        } else {
          onClose();
        }
        return;
      }

      if (focusZone === 'sidebar') {
        const curIdx = TAB_ORDER.indexOf(activeTab);
        if (e.key === 'ArrowDown') {
          e.preventDefault();
          e.stopPropagation();
          playUiSound('tick', config.uiSoundsEnabled);
          const next = TAB_ORDER[(curIdx + 1) % TAB_ORDER.length];
          setActiveTab(next);
          setContentRowIdx(0);
          setEditingControl(false);
        } else if (e.key === 'ArrowUp') {
          e.preventDefault();
          e.stopPropagation();
          playUiSound('tick', config.uiSoundsEnabled);
          const prev = TAB_ORDER[(curIdx - 1 + TAB_ORDER.length) % TAB_ORDER.length];
          setActiveTab(prev);
          setContentRowIdx(0);
          setEditingControl(false);
        } else if (e.key === 'ArrowRight' || e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          playUiSound('confirm', config.uiSoundsEnabled);
          setFocusZone('content');
          setContentRowIdx(0);
          setEditingControl(false);
        }
        return;
      }

      const isNumericSliderRow =
        (activeTab === 'customize' && contentRowIdx >= 3 && contentRowIdx <= 10) ||
        (activeTab === 'userSettings' && contentRowIdx === 0);

      if (editingControl && (e.key === 'ArrowUp' || e.key === 'ArrowDown')) {
        e.preventDefault();
        e.stopPropagation();
        return;
      }

      // Inside right pane content zone (all 6 tabs supported)
      const rowCounts: Record<ProfileSettingsTab, number> = {
        profile: 2 + activityCount, // 0: Edit Name, 1: Activity Help, 2..N: Play Activity games
        friends: 1, // 0: Friend Code Panel
        customize: 11, // 0: Reset, 1: UI Sounds, 2: Game Bg, 3..10: Sliders
        hud: 10, // 0..7: 4x2 swatches, 8: Artwork Color Sync, 9: Appearance Polarity
        userSettings: 10, // 0: Brightness, 1: Browser Mode, 2: Select Folder, 3: Pick Photos, 4: Set Root, 5: Switch User, 6: Battery, 7: Clock, 8: Aspect, 9: Download ZIP
        about: 2, // 0: GitHub link, 1: Download ZIP
      };
      const maxRows = rowCounts[activeTab] ?? 1;

      if (activeTab === 'hud' && contentRowIdx < 8) {
        if (e.key === 'ArrowDown') {
          e.preventDefault();
          e.stopPropagation();
          const next = contentRowIdx + 4 < 8 ? contentRowIdx + 4 : 8;
          setContentRowIdx(next);
          return;
        }
        if (e.key === 'ArrowUp') {
          e.preventDefault();
          e.stopPropagation();
          if (contentRowIdx >= 4) setContentRowIdx(contentRowIdx - 4);
          else setContentRowIdx(9);
          return;
        }
      }

      if (e.key === 'ArrowDown') {
        e.preventDefault();
        e.stopPropagation();
        playUiSound('tick', config.uiSoundsEnabled);
        setContentRowIdx((r) => (r + 1 < maxRows ? r + 1 : 0));
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        e.stopPropagation();
        playUiSound('tick', config.uiSoundsEnabled);
        setContentRowIdx((r) => (r - 1 >= 0 ? r - 1 : maxRows - 1));
      } else if (e.key === 'ArrowLeft' || e.key === 'ArrowRight' || e.key === 'Enter') {
        const dir = e.key === 'ArrowLeft' ? -1 : 1;

        if (activeTab === 'profile') {
          e.preventDefault();
          e.stopPropagation();
          if (e.key === 'ArrowLeft') {
            setFocusZone('sidebar');
          } else if (e.key === 'Enter') {
            if (contentRowIdx === 0) setEditingName(true);
            else if (contentRowIdx === 1) setShowActivityHelp((v) => !v);
            else {
              const sorted = [...games].sort((a, b) => (b.lastPlayedSeq ?? 0) - (a.lastPlayedSeq ?? 0));
              const picked = sorted[contentRowIdx - 2];
              const origIdx = picked ? games.findIndex((g) => g.id === picked.id) : -1;
              if (origIdx >= 0) {
                onSelectGame(origIdx);
                onClose();
              }
            }
          }
        } else if (activeTab === 'friends') {
          e.preventDefault();
          e.stopPropagation();
          if (e.key === 'ArrowLeft') setFocusZone('sidebar');
        } else if (activeTab === 'customize') {
          e.preventDefault();
          e.stopPropagation();
          if (isNumericSliderRow && e.key === 'Enter') {
            playUiSound('confirm', config.uiSoundsEnabled);
            setEditingControl((v) => !v);
            return;
          }
          if (isNumericSliderRow && !editingControl && e.key === 'ArrowLeft') {
            setFocusZone('sidebar');
            return;
          }
          const stepMul5 = (val: number, min: number, max: number) =>
            Math.max(min, Math.min(max, Math.round(val / 5) * 5 + dir * 5));

          if (contentRowIdx === 0) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else if (e.key === 'Enter') onUpdateConfig(DEFAULT_SKYLINE_CONFIG);
          } else if (contentRowIdx === 1) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else onUpdateConfig({ ...config, uiSoundsEnabled: !config.uiSoundsEnabled });
          } else if (contentRowIdx === 2) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else onUpdateConfig({ ...config, enableBackgroundArt: !config.enableBackgroundArt });
          } else if (contentRowIdx === 3) {
            onUpdateConfig({ ...config, backgroundDimPct: stepMul5(config.backgroundDimPct, 0, 100) });
          } else if (contentRowIdx === 4) {
            onUpdateConfig({ ...config, backgroundBlurPct: stepMul5(config.backgroundBlurPct ?? 25, 0, 100) });
          } else if (contentRowIdx === 5) {
            onUpdateConfig({ ...config, cardSizePct: stepMul5(config.cardSizePct, 25, 45) });
          } else if (contentRowIdx === 6) {
            onUpdateConfig({ ...config, allSoftwareSizePct: stepMul5(config.allSoftwareSizePct, 75, 130) });
          } else if (contentRowIdx === 7) {
            const pct = stepMul5(Math.round(config.cardSpacingRatio * 100), 5, 25);
            onUpdateConfig({ ...config, cardSpacingRatio: Number((pct / 100).toFixed(3)) });
          } else if (contentRowIdx === 8) {
            onUpdateConfig({ ...config, borderThicknessPx720: stepMul5(config.borderThicknessPx720, 5, 15) });
          } else if (contentRowIdx === 9) {
            onUpdateConfig({ ...config, dockHeightPct: stepMul5(config.dockHeightPct, 10, 20) });
          } else if (contentRowIdx === 10) {
            onUpdateConfig({ ...config, systemFontScalePct: stepMul5(config.systemFontScalePct || 100, 85, 135) });
          }
        } else if (activeTab === 'hud') {
          e.preventDefault();
          e.stopPropagation();
          if (contentRowIdx < 8) {
            if (e.key === 'ArrowLeft' && contentRowIdx % 4 === 0) {
              setFocusZone('sidebar');
              return;
            }
            const nextSwatchIdx = Math.max(0, Math.min(7, contentRowIdx + (e.key === 'Enter' ? 0 : dir)));
            setContentRowIdx(nextSwatchIdx);
            const sw = HUD_THEME_SWATCHES[nextSwatchIdx];
            if (sw) onUpdateConfig({ ...config, hudThemeId: sw.id });
          } else if (contentRowIdx === 8) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else onUpdateConfig({ ...config, adaptiveColors: !config.adaptiveColors });
          } else if (contentRowIdx === 9) {
            const modes: ThemeAppearanceMode[] = ['auto', 'light', 'dark'];
            const nextM = modes[(modes.indexOf(config.appearanceMode) + (dir === -1 ? 2 : 1)) % 3];
            onUpdateConfig({ ...config, appearanceMode: nextM });
          }
        } else if (activeTab === 'userSettings') {
          e.preventDefault();
          e.stopPropagation();
          if (contentRowIdx === 0) {
            if (e.key === 'Enter') {
              playUiSound('confirm', config.uiSoundsEnabled);
              setEditingControl((v) => !v);
            } else if (!editingControl && e.key === 'ArrowLeft') {
              setFocusZone('sidebar');
            } else {
              onUpdateConfig({
                ...config,
                brightnessPct: Math.max(35, Math.min(100, Math.round(config.brightnessPct / 5) * 5 + dir * 5)),
              });
            }
          } else if (contentRowIdx === 1) {
            onUpdateConfig({ ...config, browserMode: config.browserMode === 'in-app' ? 'chrome' : 'in-app' });
          } else if (contentRowIdx === 2) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else if (e.key === 'Enter') albumFolderInputRef.current?.click();
          } else if (contentRowIdx === 3) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else if (e.key === 'Enter') albumFilesInputRef.current?.click();
          } else if (contentRowIdx === 4) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else if (e.key === 'Enter') {
              (document.querySelector('[data-testid="settings-apply-album-dir"]') as HTMLElement | null)?.click();
            }
          } else if (contentRowIdx === 5) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else if (e.key === 'Enter') onOpenUserSelect();
          } else if (contentRowIdx === 6) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else onUpdateConfig({ ...config, showBatteryPercent: !config.showBatteryPercent });
          } else if (contentRowIdx === 7) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else onUpdateConfig({ ...config, timeFormat: config.timeFormat === '12hr' ? '24hr' : '12hr' });
          } else if (contentRowIdx === 8) {
            onUpdateConfig({ ...config, rp5FrameMode: config.rp5FrameMode === 'fit-16-9' ? 'fill' : 'fit-16-9' });
          } else if (contentRowIdx === 9) {
            if (e.key === 'ArrowLeft') setFocusZone('sidebar');
            else if (e.key === 'Enter') {
              (document.querySelector('[data-testid="btn-download-pegasus-theme"]') as HTMLElement | null)?.click();
            }
          }
        } else if (activeTab === 'about') {
          e.preventDefault();
          e.stopPropagation();
          if (e.key === 'ArrowLeft') {
            setFocusZone('sidebar');
          } else if (e.key === 'Enter') {
            if (contentRowIdx === 0) {
              window.open('https://github.com/RBertoCases/skylineOS', '_blank', 'noopener,noreferrer');
            } else {
              (document.querySelector('[data-testid="btn-about-download-pegasus"]') as HTMLElement | null)?.click();
            }
          }
        }
      }
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [activeTab, activityCount, config, contentRowIdx, editingControl, focusZone, games, onClose, onOpenUserSelect, onSelectGame, onUpdateConfig]);

  const isDarkPage =
    config.appearanceMode === 'dark' || (config.appearanceMode === 'auto' && palette.isDark);
  const selectedHudSwatch = HUD_THEME_SWATCHES.find((s) => s.id === config.hudThemeId);
  const accentColor =
    config.hudThemeId !== 'auto' && selectedHudSwatch
      ? selectedHudSwatch.hex
      : isDarkPage
        ? '#38BDF8'
        : '#0B6BE8';

  const pageBg = isDarkPage ? '#1A1C21' : '#EFEFEF';
  const sidebarBg = isDarkPage ? '#22252C' : '#EAEAEA';
  const textMain = isDarkPage ? '#F3F4F6' : '#2C2C2C';
  const textMuted = isDarkPage ? '#9CA3AF' : '#6B7280';
  const dividerColor = isDarkPage ? 'rgba(255,255,255,0.12)' : '#C8C8C8';
  const focusCyanBorder = accentColor;

  const h = metrics.viewportHeight;
  const fontScale = (config.systemFontScalePct || 100) / 100;
  const padX = Math.max(24, Math.round(metrics.screenMargin * 0.9));
  const sortedActivityGames = [...games].sort(
    (a, b) => (b.lastPlayedSeq ?? 0) - (a.lastPlayedSeq ?? 0)
  );
  const currentGame = sortedActivityGames[0] ?? games[0] ?? null;

  const formatPlayActivityLine = (g: GameItem) => {
    const totalMins = Math.max(5, Math.round((g.playTimeHours || 0) * 60));
    const hrs = Math.floor(totalMins / 60);
    const mins = totalMins % 60;
    const dur = hrs > 0 ? `${hrs}h ${mins}m` : `${mins}m`;
    return `${dur} played · ${g.lastPlayedAt || 'Recently played'}`;
  };

  const downloadHref = `/api/download/pegasus-theme.zip?${buildSkylineConfigQueryString(config)}`;

  const handleDownloadThemeZip = async (e: React.MouseEvent<HTMLAnchorElement>) => {
    e.preventDefault();
    if (downloadingTheme) return;
    setDownloadingTheme(true);
    setDownloadError(null);
    setDownloadSuccess(false);
    try {
      const freshUrl = `${downloadHref}&_t=${Date.now()}`;
      const response = await fetch(freshUrl, { cache: 'no-store' });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const contentType = response.headers.get('content-type') || '';
      if (!contentType.includes('zip') && !contentType.includes('octet-stream')) {
        throw new Error('Invalid theme archive response');
      }
      const blob = await response.blob();
      const blobUrl = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = blobUrl;
      link.download = 'skylineos2-pegasus-theme.zip';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      setTimeout(() => URL.revokeObjectURL(blobUrl), 2500);
      playUiSound('confirm', config.uiSoundsEnabled);
      setDownloadSuccess(true);
      setTimeout(() => setDownloadSuccess(false), 2600);
    } catch (err) {
      playUiSound('error', config.uiSoundsEnabled);
      setDownloadError(
        err instanceof Error ? `Download failed: ${err.message}` : 'Failed to download theme ZIP'
      );
    } finally {
      setDownloadingTheme(false);
    }
  };

  const handleAlbumFileChange = (e: React.ChangeEvent<HTMLInputElement>, isFolderPick: boolean) => {
    const files = Array.from(e.target.files ?? []).filter((f) =>
      f.type.startsWith('image/') || /\.(png|jpe?g|webp|gif|bmp)$/i.test(f.name)
    );
    if (files.length === 0) return;

    const loaded: AlbumPhotoItem[] = files.slice(0, 60).map((file, idx) => ({
      id: `local-${Date.now()}-${idx}`,
      name: file.name,
      url: URL.createObjectURL(file),
      addedAt: 'Synced from Folder',
    }));

    let nextLabel = config.albumFolderLabel;
    if (isFolderPick) {
      const rel = (files[0] as File & { webkitRelativePath?: string }).webkitRelativePath;
      const topDir = rel?.split('/')[0];
      if (topDir) nextLabel = `/storage/emulated/0/${topDir}`;
    } else {
      nextLabel = `${files.length} Local Photo${files.length === 1 ? '' : 's'} Selected`;
    }

    onLoadAlbumPhotos(loaded, nextLabel);
    e.target.value = '';
  };

  const navItems: {
    id: ProfileSettingsTab;
    label: string;
    subtitle?: string;
    dividerAfter?: boolean;
  }[] = [
    { id: 'profile', label: 'Profile', dividerAfter: true },
    { id: 'friends', label: 'Friend List' },
    { id: 'customize', label: 'Customize' },
    { id: 'hud', label: 'HUD', dividerAfter: true },
    { id: 'userSettings', label: 'User Settings' },
    { id: 'about', label: 'About' },
  ];

  // Larger Settings typography for handheld legibility on RP5
  const sidebarFontPx = Math.round(Math.max(24, h * 0.044) * fontScale);
  const optionFontPx = Math.round(Math.max(20, h * 0.036) * fontScale);
  const valueFontPx = Math.round(Math.max(17, h * 0.03) * fontScale);

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={`${activeUser.name}’s Settings`}
      data-testid="profile-settings-view"
      className="animate-ns2-fade absolute inset-0 z-40 flex flex-col overflow-hidden select-none"
      style={{ backgroundColor: pageBg, color: textMain }}
    >
      {/* Top Header Row */}
      <div style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
        <div
          className="flex items-center justify-between"
          style={{ height: `${Math.max(54, Math.round(h * 0.12))}px` }}
        >
          <div className="flex items-center gap-3.5">
            <UiKitAvatar
              characterId={activeUser.characterId}
              size={Math.max(36, Math.round(h * 0.072))}
              roundedClass="rounded-full"
              alt={activeUser.name}
            />
            <h1
              data-testid="settings-header-title"
              className="font-ud-medium tracking-tight"
              style={{ fontSize: `${Math.round(Math.max(24, h * 0.046) * fontScale)}px` }}
            >
              {activeUser.name}&rsquo;s Settings
            </h1>
          </div>
        </div>
        <div className="w-full h-px" style={{ backgroundColor: dividerColor }} />
      </div>

      {/* Main Split Section (Zero outer container border on sidebar) */}
      <div className="flex-1 flex min-h-0">
        <aside
          className="flex flex-col shrink-0 overflow-y-auto no-scrollbar"
          style={{
            width: '30.5%',
            backgroundColor: sidebarBg,
            paddingLeft: `${padX}px`,
            paddingRight: `${Math.max(16, Math.round(padX * 0.6))}px`,
            paddingTop: `${Math.max(14, Math.round(h * 0.03))}px`,
          }}
        >
          <div className="space-y-1.5">
            {navItems.map((item) => {
              const isSelected = activeTab === item.id;
              return (
                <div key={item.id}>
                  <button
                    type="button"
                    data-testid={`profile-tab-${item.id}`}
                    onClick={() => {
                      playUiSound('tick', config.uiSoundsEnabled);
                      setActiveTab(item.id);
                      setFocusZone('sidebar');
                      setContentRowIdx(0);
                    }}
                    className="relative w-full text-left px-4 py-2.5 cursor-pointer focus:outline-none transition-colors"
                    style={{
                      backgroundColor: isSelected
                        ? isDarkPage
                          ? '#2C303A'
                          : '#FFFFFF'
                        : 'transparent',
                      border: isSelected
                        ? `3px solid ${focusCyanBorder}`
                        : '3px solid transparent',
                    }}
                  >
                    {isSelected && (
                      <span
                        aria-hidden="true"
                        className="absolute left-1.5 top-2 bottom-2 w-[3.5px]"
                        style={{ backgroundColor: accentColor }}
                      />
                    )}
                    <div
                      className="pl-2 leading-snug font-ud-thin"
                      style={{
                        fontSize: `${sidebarFontPx}px`,
                        color: isSelected ? accentColor : textMain,
                      }}
                    >
                      {item.label}
                    </div>
                  </button>

                  {item.dividerAfter && (
                    <div
                      className="my-2 w-full h-px"
                      style={{ backgroundColor: dividerColor }}
                    />
                  )}
                </div>
              );
            })}
          </div>
        </aside>

        <section
          data-scroll-container="true"
          className="flex-1 overflow-y-auto no-scrollbar"
          style={{
            paddingLeft: `${Math.max(28, Math.round(padX * 1.15))}px`,
            paddingRight: `${Math.max(28, Math.round(padX * 1.15))}px`,
            paddingTop: `${Math.max(18, Math.round(h * 0.036))}px`,
            paddingBottom: `${Math.max(16, Math.round(h * 0.03))}px`,
          }}
        >
          {/* TAB 1: Profile */}
          {activeTab === 'profile' && (
            <div className="space-y-6">
              <div className="flex items-start gap-7">
                <div className="shrink-0 overflow-hidden">
                  <UiKitAvatar
                    characterId={activeUser.characterId}
                    size={Math.max(118, Math.round(h * 0.255))}
                    roundedClass="rounded-none"
                    alt={activeUser.name}
                  />
                </div>

                <div className="flex-1 min-w-0">
                  <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

                  <div className="flex items-center justify-between py-2.5 px-1">
                    {editingName ? (
                      <form
                        onSubmit={(e) => {
                          e.preventDefault();
                          const trimmed = draftName.trim();
                          if (trimmed) onRenameUser(activeUser.id, trimmed);
                          setEditingName(false);
                        }}
                        className="flex items-center gap-2"
                      >
                        <input
                          type="text"
                          value={draftName}
                          onChange={(e) => setDraftName(e.target.value)}
                          onBlur={() => window.getSelection()?.removeAllRanges()}
                          maxLength={14}
                          autoFocus
                          className="px-2 py-0.5 text-sm font-ud-regular rounded focus:outline-none select-text"
                          style={{
                            border: `2px solid ${focusCyanBorder}`,
                            backgroundColor: isDarkPage ? '#2C303A' : '#FFFFFF',
                            color: textMain,
                          }}
                        />
                        <button
                          type="submit"
                          className="px-2.5 py-1 rounded text-xs font-ud-medium text-white cursor-pointer"
                          style={{ backgroundColor: accentColor }}
                        >
                          Save
                        </button>
                      </form>
                    ) : (
                      <>
                        <span
                          className="font-ud-semibold"
                          style={{ fontSize: `${Math.round(Math.max(19, h * 0.04) * fontScale)}px` }}
                        >
                          {activeUser.name}
                        </span>
                        <button
                          type="button"
                          data-settings-row="profile-0"
                          aria-label="Edit user name"
                          onClick={() => setEditingName(true)}
                          className="p-1.5 rounded hover:bg-black/5 cursor-pointer focus:outline-none"
                          style={{
                            color: textMuted,
                            border:
                              focusZone === 'content' && contentRowIdx === 0
                                ? `2.5px solid ${accentColor}`
                                : '2.5px solid transparent',
                          }}
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                      </>
                    )}
                  </div>

                  <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

                  {currentGame && (
                    <div className="flex items-center gap-3.5 py-2.5 px-1">
                      <img
                        src={currentGame.coverUrl}
                        alt={currentGame.title}
                        referrerPolicy="no-referrer"
                        className="w-13 h-13 object-cover shrink-0 rounded-sm"
                      />
                      <div className="min-w-0">
                        <div className="flex items-center gap-1.5">
                          <span
                            className="inline-block w-2.5 h-2.5 rounded-xs"
                            style={{ backgroundColor: '#2ED573' }}
                          />
                          <span
                            className="font-ud-bold"
                            style={{
                              color: '#2ED573',
                              fontSize: `${Math.round(Math.max(13, h * 0.025) * fontScale)}px`,
                            }}
                          >
                            Online · Last Played
                          </span>
                        </div>
                        <div
                          className="font-ud-semibold truncate mt-0.5"
                          style={{ fontSize: `${Math.round(Math.max(15, h * 0.03) * fontScale)}px` }}
                        >
                          {currentGame.title}
                        </div>
                      </div>
                    </div>
                  )}

                  <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

                  <div
                    className="py-2.5 px-1 font-ud-regular"
                    style={{ fontSize: `${Math.round(Math.max(14, h * 0.027) * fontScale)}px` }}
                  >
                    <span style={{ color: textMuted }}>Friend Code: </span>
                    <span className="font-ud-semibold tabular-nums">
                      {activeUser.friendCode || 'SW-1234-5678-9012'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Play Activity */}
              <div>
                <div className="flex items-center justify-between pb-2">
                  <div className="flex items-center gap-2">
                    <span
                      className="w-1 h-4"
                      style={{ backgroundColor: isDarkPage ? '#94A3B8' : '#4A4E57' }}
                    />
                    <h2
                      className="font-ud-medium"
                      style={{ fontSize: `${optionFontPx}px` }}
                    >
                      Play Activity
                    </h2>
                  </div>
                  <button
                    type="button"
                    data-settings-row="profile-1"
                    aria-label="Play Activity Info"
                    onClick={() => setShowActivityHelp((v) => !v)}
                    className="p-1 rounded cursor-pointer hover:opacity-75 focus:outline-none"
                    style={{
                      color: textMuted,
                      border:
                        focusZone === 'content' && contentRowIdx === 1
                          ? `2.5px solid ${accentColor}`
                          : '2.5px solid transparent',
                    }}
                  >
                    <HelpCircle className="w-4 h-4" />
                  </button>
                </div>

                {showActivityHelp && (
                  <div
                    className="mb-2 px-3 py-1.5 text-xs font-ud-regular"
                    style={{ backgroundColor: sidebarBg, color: textMuted }}
                  >
                    Play hours track games launched through SkyLine 3 on this Retroid Pocket 5.
                  </div>
                )}

                <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

                <div data-testid="profile-play-activity">
                  {sortedActivityGames.slice(0, 5).map((g, idx) => {
                    const rowFocused = focusZone === 'content' && contentRowIdx === idx + 2;
                    const origIdx = games.findIndex((item) => item.id === g.id);
                    return (
                      <div key={g.id}>
                        <button
                          type="button"
                          data-settings-row={`profile-${idx + 2}`}
                          onClick={() => {
                            onSelectGame(origIdx >= 0 ? origIdx : idx);
                            onClose();
                          }}
                          className="w-full flex items-center gap-4 py-2.5 px-2 rounded text-left cursor-pointer hover:bg-black/5 transition-colors focus:outline-none"
                          style={{
                            border: rowFocused
                              ? `2.5px solid ${accentColor}`
                              : '2.5px solid transparent',
                          }}
                        >
                          <img
                            src={g.coverUrl}
                            alt={g.title}
                            referrerPolicy="no-referrer"
                            className="w-12 h-12 object-cover shrink-0 rounded-sm"
                          />
                          <div className="min-w-0">
                            <div
                              className="font-ud-medium truncate"
                              style={{ fontSize: `${optionFontPx}px` }}
                            >
                              {g.title}
                            </div>
                            <div
                              className="font-ud-regular mt-0.5"
                              style={{
                                fontSize: `${Math.round(Math.max(15, h * 0.025) * fontScale)}px`,
                                color: accentColor,
                              }}
                            >
                              {formatPlayActivityLine(g)}
                            </div>
                          </div>
                        </button>
                        <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: Friend List */}
          {activeTab === 'friends' && (
            <div className="space-y-4">
              <div className="flex items-center gap-2 pb-1">
                <span className="w-1 h-4" style={{ backgroundColor: accentColor }} />
                <h2 className="font-ud-semibold" style={{ fontSize: `${optionFontPx + 2}px` }}>Friend List</h2>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />
              <div
                data-settings-row="friends-0"
                className="py-12 px-6 flex flex-col items-center justify-center text-center gap-3 rounded-xl"
                style={{
                  backgroundColor: sidebarBg,
                  border:
                    focusZone === 'content' && contentRowIdx === 0
                      ? `2.5px solid ${accentColor}`
                      : `1px solid ${dividerColor}`,
                }}
              >
                <Users className="w-10 h-10 opacity-50" />
                <div className="font-ud-bold" style={{ fontSize: `${optionFontPx + 2}px` }}>No Friends Added Yet</div>
                <p
                  className="font-ud-regular max-w-md leading-relaxed"
                  style={{ color: textMuted, fontSize: `${Math.round(14 * fontScale)}px` }}
                >
                  Share your Friend Code ({activeUser.friendCode || 'SW-1234-5678-9012'}) or send requests from GameChat to see real friends here.
                </p>
              </div>
            </div>
          )}

          {/* TAB 3: Customize (Home, All Software Size, & System Font Size) */}
          {activeTab === 'customize' && (
            <div className="space-y-2">
              <div className="flex items-center justify-between pb-1.5">
                <div className="flex items-center gap-2">
                  <span className="w-1 h-4" style={{ backgroundColor: accentColor }} />
                  <h2 className="font-ud-semibold" style={{ fontSize: `${optionFontPx + 2}px` }}>
                    Customize Home &amp; All Software
                  </h2>
                </div>
                <button
                  type="button"
                  data-settings-row="customize-0"
                  onClick={() => onUpdateConfig(DEFAULT_SKYLINE_CONFIG)}
                  className="flex items-center gap-1.5 px-2.5 py-1 rounded text-sm font-ud-medium cursor-pointer hover:opacity-80 focus:outline-none"
                  style={{
                    color: accentColor,
                    border:
                      focusZone === 'content' && contentRowIdx === 0
                        ? `2.5px solid ${accentColor}`
                        : '2.5px solid transparent',
                  }}
                >
                  <RotateCcw className="w-4 h-4" />
                  <span>Reset</span>
                </button>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              {/* Row 1: UI Sounds */}
              <div
                data-settings-row="customize-1"
                className="flex items-center justify-between py-2.5 px-2 rounded"
                style={{
                  border: focusZone === 'content' && contentRowIdx === 1 ? `2.5px solid ${accentColor}` : '2.5px solid transparent',
                }}
              >
                <div className="flex items-center gap-2">
                  <Volume2 className="w-4 h-4 opacity-75" />
                  <span className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>UI Sounds</span>
                </div>
                <button
                  type="button"
                  data-testid="toggle-ui-sounds"
                  onClick={() => {
                    const next = !config.uiSoundsEnabled;
                    onUpdateConfig({ ...config, uiSoundsEnabled: next });
                    if (next) playUiSound('confirm', true);
                  }}
                  className="px-4 py-1.5 rounded-full text-sm font-ud-semibold cursor-pointer min-w-[82px]"
                  style={{
                    backgroundColor: config.uiSoundsEnabled ? accentColor : sidebarBg,
                    color: config.uiSoundsEnabled ? '#FFFFFF' : textMain,
                  }}
                >
                  {config.uiSoundsEnabled ? 'ON' : 'OFF'}
                </button>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              {/* Row 2: Game Background */}
              <div
                data-settings-row="customize-2"
                className="flex items-center justify-between py-2.5 px-2 rounded"
                style={{
                  border: focusZone === 'content' && contentRowIdx === 2 ? `2.5px solid ${accentColor}` : '2.5px solid transparent',
                }}
              >
                <span className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>Game Background</span>
                <button
                  type="button"
                  data-testid="toggle-game-bg"
                  onClick={() =>
                    onUpdateConfig({ ...config, enableBackgroundArt: !config.enableBackgroundArt })
                  }
                  className="px-4 py-1.5 rounded-full text-sm font-ud-semibold cursor-pointer min-w-[82px]"
                  style={{
                    backgroundColor: config.enableBackgroundArt ? accentColor : sidebarBg,
                    color: config.enableBackgroundArt ? '#FFFFFF' : textMain,
                  }}
                >
                  {config.enableBackgroundArt ? 'ON' : 'OFF'}
                </button>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              {/* Rows 3..10 Step-5 Controls (< > + Slider + A Edit Lock) */}
              {[
                {
                  id: 'bg-opacity',
                  rowIdx: 3,
                  label: 'Background Transparency',
                  value: `${config.backgroundDimPct}%`,
                  min: 0,
                  max: 100,
                  step: 5,
                  cur: config.backgroundDimPct,
                  disabled: !config.enableBackgroundArt,
                  onChange: (v: number) => onUpdateConfig({ ...config, backgroundDimPct: v }),
                },
                {
                  id: 'bg-blur',
                  rowIdx: 4,
                  label: 'Background Blur',
                  value: `${config.backgroundBlurPct ?? 25}%`,
                  min: 0,
                  max: 100,
                  step: 5,
                  cur: config.backgroundBlurPct ?? 25,
                  disabled: !config.enableBackgroundArt,
                  onChange: (v: number) => onUpdateConfig({ ...config, backgroundBlurPct: v }),
                },
                {
                  id: 'cover-size',
                  rowIdx: 5,
                  label: 'Home Cover Size',
                  value: `${config.cardSizePct}%`,
                  min: 25,
                  max: 45,
                  step: 5,
                  cur: config.cardSizePct,
                  disabled: false,
                  onChange: (v: number) => onUpdateConfig({ ...config, cardSizePct: v }),
                },
                {
                  id: 'allsoft-size',
                  rowIdx: 6,
                  label: 'All Software Size',
                  value: `${config.allSoftwareSizePct}%`,
                  min: 75,
                  max: 130,
                  step: 5,
                  cur: config.allSoftwareSizePct,
                  disabled: false,
                  onChange: (v: number) => onUpdateConfig({ ...config, allSoftwareSizePct: v }),
                },
                {
                  id: 'cover-spacing',
                  rowIdx: 7,
                  label: 'Cover Spacing',
                  value: `${Math.round(config.cardSpacingRatio * 100)}%`,
                  min: 5,
                  max: 25,
                  step: 5,
                  cur: Math.round(config.cardSpacingRatio * 100),
                  disabled: false,
                  onChange: (v: number) =>
                    onUpdateConfig({ ...config, cardSpacingRatio: Number((v / 100).toFixed(3)) }),
                },
                {
                  id: 'border-width',
                  rowIdx: 8,
                  label: 'Border Width',
                  value: `${config.borderThicknessPx720}px`,
                  min: 5,
                  max: 15,
                  step: 5,
                  cur: config.borderThicknessPx720,
                  disabled: false,
                  onChange: (v: number) => onUpdateConfig({ ...config, borderThicknessPx720: v }),
                },
                {
                  id: 'dock-scale',
                  rowIdx: 9,
                  label: 'Dock Size',
                  value: `${Math.round(config.dockHeightPct)}%`,
                  min: 10,
                  max: 20,
                  step: 5,
                  cur: Math.round(config.dockHeightPct),
                  disabled: false,
                  onChange: (v: number) => onUpdateConfig({ ...config, dockHeightPct: v }),
                },
                {
                  id: 'system-font',
                  rowIdx: 10,
                  label: 'System Font Size',
                  value: `${config.systemFontScalePct || 100}%`,
                  min: 85,
                  max: 135,
                  step: 5,
                  cur: config.systemFontScalePct || 100,
                  disabled: false,
                  onChange: (v: number) => onUpdateConfig({ ...config, systemFontScalePct: v }),
                },
              ].map((row) => {
                const isRowFocused = focusZone === 'content' && contentRowIdx === row.rowIdx;
                const isEditing = isRowFocused && editingControl;
                return (
                  <div key={row.id}>
                    <div
                      data-settings-row={`customize-${row.rowIdx}`}
                      data-editing={isEditing ? 'true' : 'false'}
                      className="flex items-center justify-between gap-4 py-3 px-2.5 rounded transition-colors"
                      style={{
                        backgroundColor: isEditing ? (isDarkPage ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)') : 'transparent',
                        border: isEditing
                          ? `3px solid ${accentColor}`
                          : isRowFocused
                            ? `2.5px solid ${accentColor}`
                            : '2.5px solid transparent',
                      }}
                    >
                      <span className="font-ud-semibold shrink-0 flex items-center gap-2" style={{ fontSize: `${optionFontPx}px` }}>
                        {row.id === 'system-font' && <Type className="w-5 h-5 opacity-75" />}
                        <span>{row.label}</span>
                        {isEditing && (
                          <span
                            data-testid="settings-editing-badge"
                            className="px-2 py-0.5 rounded text-xs font-ud-bold text-white"
                            style={{ backgroundColor: accentColor }}
                          >
                            Adjusting (◄ ► / A done)
                          </span>
                        )}
                      </span>
                      <div className="flex items-center gap-2.5 w-80 max-w-[54%]">
                        <button
                          type="button"
                          data-testid={`step-dec-${row.id}`}
                          aria-label={`Decrease ${row.label}`}
                          disabled={row.disabled}
                          onClick={() => {
                            const next = Math.max(row.min, Math.min(row.max, Math.round(row.cur / 5) * 5 - row.step));
                            row.onChange(next);
                          }}
                          className="w-8 h-8 rounded flex items-center justify-center font-ud-bold cursor-pointer disabled:opacity-40 shrink-0"
                          style={{
                            backgroundColor: isEditing ? accentColor : sidebarBg,
                            color: isEditing ? '#FFFFFF' : textMain,
                            border: `1px solid ${dividerColor}`,
                            fontSize: `${valueFontPx}px`,
                          }}
                        >
                          &lt;
                        </button>
                        <input
                          type="range"
                          aria-label={row.label}
                          data-testid={`slider-${row.id}`}
                          min={row.min}
                          max={row.max}
                          step={row.step}
                          disabled={row.disabled}
                          value={row.cur}
                          onChange={(e) => row.onChange(Number(e.target.value))}
                          className="flex-1 cursor-pointer disabled:opacity-40"
                          style={{ accentColor }}
                        />
                        <span
                          data-testid={`val-${row.id}`}
                          className="font-mono-tabular font-ud-bold w-16 text-center shrink-0"
                          style={{ color: accentColor, fontSize: `${valueFontPx}px` }}
                        >
                          {row.value}
                        </span>
                        <button
                          type="button"
                          data-testid={`step-inc-${row.id}`}
                          aria-label={`Increase ${row.label}`}
                          disabled={row.disabled}
                          onClick={() => {
                            const next = Math.max(row.min, Math.min(row.max, Math.round(row.cur / 5) * 5 + row.step));
                            row.onChange(next);
                          }}
                          className="w-8 h-8 rounded flex items-center justify-center font-ud-bold cursor-pointer disabled:opacity-40 shrink-0"
                          style={{
                            backgroundColor: isEditing ? accentColor : sidebarBg,
                            color: isEditing ? '#FFFFFF' : textMain,
                            border: `1px solid ${dividerColor}`,
                            fontSize: `${valueFontPx}px`,
                          }}
                        >
                          &gt;
                        </button>
                      </div>
                    </div>
                    <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />
                  </div>
                );
              })}
            </div>
          )}

          {/* TAB 4: HUD (Bigger strictly round circle swatches; White text in dark mode, Black text in light mode) */}
          {activeTab === 'hud' && (
            <div className="space-y-5">
              <div className="flex items-center gap-2 pb-1">
                <span className="w-1 h-4" style={{ backgroundColor: accentColor }} />
                <h2 className="font-ud-semibold" style={{ fontSize: `${optionFontPx + 2}px` }}>
                  HUD &amp; Sidebar Colors
                </h2>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              <div className="space-y-3">
                <div className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>
                  Theme Accent Color
                </div>
                <div
                  data-testid="hud-color-grid"
                  className="grid grid-cols-4 gap-x-6 gap-y-5 py-2"
                >
                  {HUD_THEME_SWATCHES.map((swatch, idx) => {
                    const selected = config.hudThemeId === swatch.id;
                    const focused = focusZone === 'content' && contentRowIdx === idx;
                    const swatchLabelColor = isDarkPage ? '#FFFFFF' : '#111111';
                    return (
                      <button
                        key={swatch.id}
                        type="button"
                        data-settings-row={`hud-${idx}`}
                        data-testid={`hud-swatch-${swatch.id}`}
                        onClick={() => {
                          playUiSound('tick', config.uiSoundsEnabled);
                          onUpdateConfig({ ...config, hudThemeId: swatch.id });
                        }}
                        className="flex flex-col items-center gap-2 p-1.5 rounded-lg cursor-pointer focus:outline-none"
                        style={{
                          border: focused ? `2.5px solid ${accentColor}` : '2.5px solid transparent',
                        }}
                      >
                        <span
                          className="w-16 h-16 aspect-square shrink-0 rounded-full flex items-center justify-center transition-transform duration-150 hover:scale-105"
                          style={{
                            backgroundColor: swatch.hex,
                            outline: selected ? `3.5px solid ${swatch.hex}` : 'none',
                            outlineOffset: '3.5px',
                          }}
                        >
                          {selected && <Check className="w-6 h-6 text-white" strokeWidth={3} />}
                        </span>
                        <span
                          className={`text-sm leading-tight ${selected ? 'font-ud-bold' : 'font-ud-semibold'}`}
                          style={{
                            color: swatchLabelColor,
                            fontSize: `${Math.round(Math.max(14, h * 0.023) * fontScale)}px`,
                          }}
                        >
                          {swatch.label}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              <div
                data-settings-row="hud-8"
                className="flex items-center justify-between py-2 px-2 rounded"
                style={{
                  border: focusZone === 'content' && contentRowIdx === 8 ? `2.5px solid ${accentColor}` : '2.5px solid transparent',
                }}
              >
                <span className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>Artwork Color Sync</span>
                <button
                  type="button"
                  onClick={() =>
                    onUpdateConfig({ ...config, adaptiveColors: !config.adaptiveColors })
                  }
                  className="px-4 py-1.5 rounded-full text-sm font-ud-medium cursor-pointer"
                  style={{
                    backgroundColor: config.adaptiveColors ? accentColor : sidebarBg,
                    color: config.adaptiveColors ? '#FFFFFF' : textMain,
                  }}
                >
                  {config.adaptiveColors ? 'Active' : 'Static'}
                </button>
              </div>

              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              <div
                data-settings-row="hud-9"
                className="flex items-center justify-between py-2 px-2 rounded"
                style={{
                  border: focusZone === 'content' && contentRowIdx === 9 ? `2.5px solid ${accentColor}` : '2.5px solid transparent',
                }}
              >
                <span className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>Appearance Polarity</span>
                <div className="flex gap-2">
                  {(['auto', 'light', 'dark'] as ThemeAppearanceMode[]).map((mode) => (
                    <button
                      key={mode}
                      type="button"
                      data-testid={`appearance-${mode}`}
                      onClick={() => onUpdateConfig({ ...config, appearanceMode: mode })}
                      className="px-4 py-1.5 rounded-full text-sm font-ud-medium capitalize cursor-pointer"
                      style={{
                        backgroundColor: config.appearanceMode === mode ? accentColor : sidebarBg,
                        color: config.appearanceMode === mode ? '#FFFFFF' : textMain,
                      }}
                    >
                      {mode}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* TAB 5: User Settings */}
          {activeTab === 'userSettings' && (
            <div className="space-y-2.5">
              <div className="flex items-center gap-2 pb-1">
                <span className="w-1 h-4" style={{ backgroundColor: accentColor }} />
                <h2 className="font-ud-semibold" style={{ fontSize: `${optionFontPx + 2}px` }}>
                  User &amp; System Settings
                </h2>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              <div
                data-settings-row="userSettings-0"
                data-editing={focusZone === 'content' && contentRowIdx === 0 && editingControl ? 'true' : 'false'}
                className="flex items-center justify-between gap-4 py-3 px-2.5 rounded"
                style={{
                  backgroundColor:
                    focusZone === 'content' && contentRowIdx === 0 && editingControl
                      ? isDarkPage
                        ? 'rgba(255,255,255,0.08)'
                        : 'rgba(0,0,0,0.05)'
                      : 'transparent',
                  border:
                    focusZone === 'content' && contentRowIdx === 0
                      ? `${editingControl ? '3px' : '2.5px'} solid ${accentColor}`
                      : '2.5px solid transparent',
                }}
              >
                <div className="flex items-center gap-2 shrink-0">
                  <Sun className="w-5 h-5 opacity-75" />
                  <span className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>Brightness</span>
                </div>
                <div className="flex items-center gap-2.5 w-80 max-w-[54%]">
                  <button
                    type="button"
                    data-testid="step-dec-brightness"
                    aria-label="Decrease Brightness"
                    onClick={() =>
                      onUpdateConfig({
                        ...config,
                        brightnessPct: Math.max(35, Math.min(100, Math.round(config.brightnessPct / 5) * 5 - 5)),
                      })
                    }
                    className="w-8 h-8 rounded flex items-center justify-center font-ud-bold cursor-pointer shrink-0"
                    style={{ backgroundColor: sidebarBg, color: textMain, border: `1px solid ${dividerColor}`, fontSize: `${valueFontPx}px` }}
                  >
                    &lt;
                  </button>
                  <input
                    type="range"
                    aria-label="Brightness"
                    data-testid="slider-brightness"
                    min={35}
                    max={100}
                    step={5}
                    value={config.brightnessPct}
                    onChange={(e) =>
                      onUpdateConfig({ ...config, brightnessPct: Number(e.target.value) })
                    }
                    className="flex-1 cursor-pointer"
                    style={{ accentColor }}
                  />
                  <span
                    data-testid="val-brightness"
                    className="font-mono-tabular font-ud-bold w-14 text-center shrink-0"
                    style={{ color: accentColor, fontSize: `${valueFontPx}px` }}
                  >
                    {config.brightnessPct}%
                  </span>
                  <button
                    type="button"
                    data-testid="step-inc-brightness"
                    aria-label="Increase Brightness"
                    onClick={() =>
                      onUpdateConfig({
                        ...config,
                        brightnessPct: Math.max(35, Math.min(100, Math.round(config.brightnessPct / 5) * 5 + 5)),
                      })
                    }
                    className="w-8 h-8 rounded flex items-center justify-center font-ud-bold cursor-pointer shrink-0"
                    style={{ backgroundColor: sidebarBg, color: textMain, border: `1px solid ${dividerColor}`, fontSize: `${valueFontPx}px` }}
                  >
                    &gt;
                  </button>
                </div>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              <div
                data-settings-row="userSettings-1"
                className="flex items-center justify-between py-2.5 px-2 rounded"
                style={{
                  border: focusZone === 'content' && contentRowIdx === 1 ? `2.5px solid ${accentColor}` : '2.5px solid transparent',
                }}
              >
                <div className="flex items-center gap-2">
                  <Globe className="w-4 h-4 opacity-75" />
                  <span className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>Internet Browser Mode</span>
                </div>
                <div className="flex gap-2">
                  <button
                    type="button"
                    data-testid="browser-mode-in-app"
                    onClick={() => onUpdateConfig({ ...config, browserMode: 'in-app' })}
                    className="px-4 py-1.5 rounded-lg text-sm font-ud-medium cursor-pointer"
                    style={{
                      backgroundColor: config.browserMode === 'in-app' ? accentColor : sidebarBg,
                      color: config.browserMode === 'in-app' ? '#FFFFFF' : textMain,
                    }}
                  >
                    In-App Browser
                  </button>
                  <button
                    type="button"
                    data-testid="browser-mode-chrome"
                    onClick={() => onUpdateConfig({ ...config, browserMode: 'chrome' })}
                    className="px-4 py-1.5 rounded-lg text-sm font-ud-medium cursor-pointer"
                    style={{
                      backgroundColor: config.browserMode === 'chrome' ? accentColor : sidebarBg,
                      color: config.browserMode === 'chrome' ? '#FFFFFF' : textMain,
                    }}
                  >
                    Open in Chrome
                  </button>
                </div>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              {/* Photos Directory */}
              <div className="space-y-2 py-2.5">
                <div className="flex items-center justify-between gap-4">
                  <div className="min-w-0">
                    <div className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>Photos Directory</div>
                    <div
                      data-testid="settings-album-location-label"
                      className="font-ud-regular text-sm truncate mt-0.5"
                      style={{ color: textMuted }}
                    >
                      {config.albumFolderLabel}
                    </div>
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      type="button"
                      data-settings-row="userSettings-2"
                      data-testid="settings-select-album-folder"
                      onClick={() => albumFolderInputRef.current?.click()}
                      className="flex items-center gap-1.5 px-3.5 py-2 rounded-lg text-sm font-ud-medium text-white cursor-pointer focus:outline-none"
                      style={{
                        backgroundColor: accentColor,
                        outline: focusZone === 'content' && contentRowIdx === 2 ? `2.5px solid #FFFFFF` : 'none',
                        outlineOffset: '2px',
                      }}
                    >
                      <FolderOpen className="w-4 h-4" />
                      <span>Select Folder</span>
                    </button>
                    <button
                      type="button"
                      data-settings-row="userSettings-3"
                      onClick={() => albumFilesInputRef.current?.click()}
                      className="flex items-center gap-1.5 px-3.5 py-2 rounded-lg text-sm font-ud-medium cursor-pointer focus:outline-none"
                      style={{
                        backgroundColor: sidebarBg,
                        color: textMain,
                        border: focusZone === 'content' && contentRowIdx === 3 ? `2.5px solid ${accentColor}` : `1px solid ${dividerColor}`,
                      }}
                    >
                      <ImagePlus className="w-4 h-4" />
                      <span>Pick Photos</span>
                    </button>
                    <input
                      ref={albumFolderInputRef}
                      type="file"
                      multiple
                      accept="image/*"
                      // @ts-expect-error non-standard folder selection supported by Chromium/Android
                      webkitdirectory=""
                      onChange={(e) => handleAlbumFileChange(e, true)}
                      className="hidden"
                    />
                    <input
                      ref={albumFilesInputRef}
                      type="file"
                      multiple
                      accept="image/*"
                      onChange={(e) => handleAlbumFileChange(e, false)}
                      className="hidden"
                    />
                  </div>
                </div>
                <form
                  onSubmit={(e) => {
                    e.preventDefault();
                    if (onApplyAlbumDirectory) {
                      onApplyAlbumDirectory(albumDirDraft);
                    } else {
                      onUpdateConfig({
                        ...config,
                        albumFolderLabel: albumDirDraft.trim() || '/storage/emulated/0/Pictures',
                      });
                    }
                    (document.activeElement as HTMLElement | null)?.blur?.();
                  }}
                  className="flex items-center gap-2"
                >
                  <input
                    type="text"
                    aria-label="Photos Directory Path"
                    data-testid="settings-album-dir-input"
                    value={albumDirDraft}
                    onChange={(e) => setAlbumDirDraft(e.target.value)}
                    onBlur={() => window.getSelection()?.removeAllRanges()}
                    placeholder="/storage/emulated/0/Pictures"
                    className="flex-1 px-3 py-1.5 rounded-lg text-sm font-mono-tabular focus:outline-none select-text"
                    style={{
                      backgroundColor: sidebarBg,
                      color: textMain,
                      border: `1px solid ${dividerColor}`,
                    }}
                  />
                  <button
                    type="submit"
                    data-settings-row="userSettings-4"
                    data-testid="settings-apply-album-dir"
                    className="px-3.5 py-1.5 rounded-lg text-sm font-ud-semibold text-white cursor-pointer focus:outline-none"
                    style={{
                      backgroundColor: accentColor,
                      outline: focusZone === 'content' && contentRowIdx === 4 ? `2.5px solid #FFFFFF` : 'none',
                      outlineOffset: '2px',
                    }}
                  >
                    Set Root
                  </button>
                </form>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              <div className="space-y-2.5 py-2.5">
                <div className="flex items-center justify-between">
                  <span className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>Users &amp; Profiles</span>
                  <button
                    type="button"
                    data-settings-row="userSettings-5"
                    onClick={onOpenUserSelect}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-ud-medium text-white cursor-pointer hover:opacity-90 focus:outline-none"
                    style={{
                      backgroundColor: accentColor,
                      outline: focusZone === 'content' && contentRowIdx === 5 ? `2.5px solid #FFFFFF` : 'none',
                      outlineOffset: '2px',
                    }}
                  >
                    <UserPlus className="w-4 h-4" />
                    <span>Switch or Add (+) User</span>
                  </button>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 pt-1">
                  {users.map((u) => {
                    const isCur = u.id === activeUser.id;
                    return (
                      <div
                        key={u.id}
                        className="flex items-center justify-between gap-2.5 p-2 rounded-lg"
                        style={{
                          backgroundColor: sidebarBg,
                          border: isCur ? `2px solid ${accentColor}` : `1px solid ${dividerColor}`,
                        }}
                      >
                        <button
                          type="button"
                          onClick={() => onSelectUser(u.id)}
                          className="flex items-center gap-2.5 min-w-0 flex-1 text-left cursor-pointer"
                        >
                          <UiKitAvatar characterId={u.characterId} size={36} roundedClass="rounded-md" alt={u.name} />
                          <div className="min-w-0">
                            <div className="font-ud-semibold text-sm truncate">{u.name}</div>
                            <div className="text-xs font-ud-regular" style={{ color: isCur ? accentColor : textMuted }}>
                              {isCur ? 'Active Profile' : 'Tap to Switch'}
                            </div>
                          </div>
                        </button>
                        {users.length > 1 && (
                          <button
                            type="button"
                            data-testid={`settings-delete-user-${u.id}`}
                            aria-label={`Delete user ${u.name}`}
                            onClick={() => onDeleteUser(u.id)}
                            className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-md text-xs font-ud-bold text-white cursor-pointer hover:opacity-90 shrink-0"
                            style={{ backgroundColor: '#E60012' }}
                          >
                            <Minus className="w-3.5 h-3.5" strokeWidth={3} />
                            <span>Delete</span>
                          </button>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              <div
                data-settings-row="userSettings-6"
                className="flex items-center justify-between py-2.5 px-2 rounded"
                style={{
                  border: focusZone === 'content' && contentRowIdx === 6 ? `2.5px solid ${accentColor}` : '2.5px solid transparent',
                }}
              >
                <span className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>Battery Percentage</span>
                <button
                  type="button"
                  onClick={() =>
                    onUpdateConfig({ ...config, showBatteryPercent: !config.showBatteryPercent })
                  }
                  className="px-4 py-2 rounded-lg text-sm font-ud-medium cursor-pointer min-w-[104px]"
                  style={{ backgroundColor: sidebarBg, border: `1px solid ${dividerColor}` }}
                >
                  {config.showBatteryPercent ? 'Shown' : 'Hidden'}
                </button>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              <div
                data-settings-row="userSettings-7"
                className="flex items-center justify-between py-2.5 px-2 rounded"
                style={{
                  border: focusZone === 'content' && contentRowIdx === 7 ? `2.5px solid ${accentColor}` : '2.5px solid transparent',
                }}
              >
                <span className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>Clock Format</span>
                <button
                  type="button"
                  onClick={() =>
                    onUpdateConfig({
                      ...config,
                      timeFormat: config.timeFormat === '12hr' ? '24hr' : '12hr',
                    })
                  }
                  className="px-4 py-2 rounded-lg text-sm font-ud-medium cursor-pointer min-w-[104px]"
                  style={{ backgroundColor: sidebarBg, border: `1px solid ${dividerColor}` }}
                >
                  {config.timeFormat.toUpperCase()}
                </button>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              <div
                data-settings-row="userSettings-8"
                className="flex items-center justify-between py-2.5 px-2 rounded"
                style={{
                  border: focusZone === 'content' && contentRowIdx === 8 ? `2.5px solid ${accentColor}` : '2.5px solid transparent',
                }}
              >
                <span className="font-ud-semibold" style={{ fontSize: `${optionFontPx}px` }}>Screen Aspect Ratio</span>
                <div className="flex gap-2">
                  {(['fit-16-9', 'fill'] as const).map((mode) => (
                    <button
                      key={mode}
                      type="button"
                      onClick={() => onUpdateConfig({ ...config, rp5FrameMode: mode })}
                      className="px-4 py-2 rounded-lg text-sm font-ud-medium cursor-pointer"
                      style={{
                        backgroundColor: config.rp5FrameMode === mode ? accentColor : sidebarBg,
                        color: config.rp5FrameMode === mode ? '#FFFFFF' : textMain,
                      }}
                    >
                      {mode === 'fit-16-9' ? 'RP5 16:9 Exact' : 'Fill Browser'}
                    </button>
                  ))}
                </div>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              {/* Pegasus Theme Package */}
              <div
                data-settings-row="userSettings-9"
                className="flex items-center justify-between gap-4 py-2.5 px-2 rounded"
                style={{
                  border: focusZone === 'content' && contentRowIdx === 9 ? `2.5px solid ${accentColor}` : '2.5px solid transparent',
                }}
              >
                <div className="min-w-0">
                  <span className="font-ud-semibold block" style={{ fontSize: `${optionFontPx}px` }}>
                    Pegasus Theme (SkyLine 3)
                  </span>
                  <span className="font-ud-regular text-sm block opacity-85" style={{ color: textMuted }}>
                    skylineos2-pegasus-theme.zip · Switch 2 layout + Direct Boot (Eden / PS2 / GC)
                  </span>
                  {downloadError && (
                    <span className="font-ud-medium text-sm block mt-1" style={{ color: '#EF4444' }}>
                      {downloadError}
                    </span>
                  )}
                </div>
                <a
                  href={downloadHref}
                  download="skylineos2-pegasus-theme.zip"
                  onClick={handleDownloadThemeZip}
                  data-testid="btn-download-pegasus-theme"
                  aria-busy={downloadingTheme}
                  className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-ud-semibold text-white shrink-0 cursor-pointer hover:opacity-90 shadow-sm"
                  style={{ backgroundColor: accentColor }}
                >
                  {downloadSuccess ? <Check className="w-4 h-4" /> : <Download className="w-4 h-4" />}
                  <span>
                    {downloadingTheme
                      ? 'Preparing ZIP...'
                      : downloadSuccess
                        ? 'Downloaded!'
                        : 'Download Theme (.zip)'}
                  </span>
                </a>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />
            </div>
          )}

          {/* TAB 6: About SkyLine 3 */}
          {activeTab === 'about' && (
            <div className="space-y-4" data-testid="settings-about-content">
              <div className="flex items-center gap-2 pb-1">
                <span className="w-1 h-4" style={{ backgroundColor: accentColor }} />
                <h2 className="font-ud-semibold" style={{ fontSize: `${optionFontPx + 2}px` }}>
                  About SkyLine 3
                </h2>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: dividerColor }} />

              <div
                className="space-y-3 py-2 font-ud-regular leading-relaxed"
                style={{ fontSize: `${optionFontPx}px` }}
              >
                <p className="font-ud-bold">SkyLine 3 — Perfected Switch 2 Edition</p>
                <p>Designed by Chen.Paradise 🇵🇷</p>
                <p>
                  Forked from{' '}
                  <a
                    data-settings-row="about-0"
                    href="https://github.com/RBertoCases/skylineOS"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="underline px-1.5 py-0.5 rounded inline-block"
                    style={{
                      color: accentColor,
                      border:
                        focusZone === 'content' && contentRowIdx === 0
                          ? `2.5px solid ${accentColor}`
                          : '2.5px solid transparent',
                    }}
                  >
                    https://github.com/RBertoCases/skylineOS
                  </a>
                </p>
                <p className="font-ud-thin" style={{ color: textMuted }}>
                  2026 For Education purposes Only.
                </p>
                <p>Hecho con ❤️🇵🇷 en Santurce, PR</p>

                <div className="pt-2 space-y-1.5">
                  <a
                    data-settings-row="about-1"
                    href={downloadHref}
                    download="skylineos2-pegasus-theme.zip"
                    onClick={handleDownloadThemeZip}
                    data-testid="btn-about-download-pegasus"
                    aria-busy={downloadingTheme}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-ud-medium text-white cursor-pointer hover:opacity-90 shadow-sm focus:outline-none"
                    style={{
                      backgroundColor: accentColor,
                      outline: focusZone === 'content' && contentRowIdx === 1 ? `2.5px solid #FFFFFF` : 'none',
                      outlineOffset: '2px',
                    }}
                  >
                    {downloadSuccess ? <Check className="w-4 h-4" /> : <Download className="w-4 h-4" />}
                    <span>
                      {downloadingTheme
                        ? 'Preparing ZIP...'
                        : downloadSuccess
                          ? 'Downloaded!'
                          : 'Download SkyLine 3 Pegasus Theme (.zip)'}
                    </span>
                  </a>
                  {downloadError && (
                    <p className="font-ud-medium text-xs" style={{ color: '#EF4444' }}>
                      {downloadError}
                    </p>
                  )}
                </div>
              </div>
            </div>
          )}
        </section>
      </div>

      {/* Bottom Sticky Footer Bar */}
      <footer style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
        <div className="w-full h-px" style={{ backgroundColor: dividerColor }} />
        <div
          className="flex items-center justify-between"
          style={{ height: `${Math.max(40, Math.round(h * 0.088))}px` }}
        >
          <BottomControllerGlyph size={metrics.helpIconSize} color={textMain} />

          <div className="flex items-center gap-6">
            <button
              type="button"
              data-testid="profile-back-button"
              onClick={onClose}
              className="flex items-center gap-2 cursor-pointer hover:opacity-75"
            >
              <SwitchPdfIcon
                button="B"
                size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                fillColor={textMain}
                cutoutColor={pageBg}
              />
              <span
                className="font-ud-regular"
                style={{ fontSize: `${metrics.helpFontSize}px`, color: textMain }}
              >
                Back
              </span>
            </button>

            <button
              type="button"
              onClick={() => setFocusZone((z) => (z === 'sidebar' ? 'content' : 'sidebar'))}
              className="flex items-center gap-2 cursor-pointer hover:opacity-75"
            >
              <SwitchPdfIcon
                button="A"
                size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                fillColor={textMain}
                cutoutColor={pageBg}
              />
              <span
                className="font-ud-regular"
                style={{ fontSize: `${metrics.helpFontSize}px`, color: textMain }}
              >
                OK
              </span>
            </button>
          </div>
        </div>
      </footer>
    </div>
  );
}
