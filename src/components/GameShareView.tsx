import { useEffect, useState } from 'react';
import { Bookmark, Clock, Trophy } from 'lucide-react';
import type { AdaptivePalette, GameItem, UserProfile } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { SwitchPdfIcon } from './SwitchPdfIcons';
import { UiKitAvatar } from './UiKitAvatar';
import { UiKitGameShareIcon } from './UiKitIcons';
import { BottomControllerGlyph } from './BottomControllerGlyph';

interface GameShareViewProps {
  activeUser: UserProfile;
  users: UserProfile[];
  games: GameItem[];
  palette: AdaptivePalette;
  metrics: Switch2LayoutMetrics;
  fontScalePct?: number;
  onSelectGame: (idx: number) => void;
  onToggleBacklog: (gameId: string) => void;
  onClose: () => void;
}

type GameShareTab = 'screenTime' | 'mostPlayed' | 'backlog';

/**
 * Combined GameShare ("GameShark") & Backlog full-screen split NS2 view with larger readable fonts
 */
export function GameShareView({
  activeUser,
  users,
  games,
  palette,
  metrics,
  fontScalePct = 100,
  onSelectGame,
  onToggleBacklog,
  onClose,
}: GameShareViewProps) {
  const [tab, setTab] = useState<GameShareTab>('mostPlayed');

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        onClose();
      } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        e.stopPropagation();
        const order: GameShareTab[] = ['mostPlayed', 'screenTime', 'backlog'];
        setTab((cur) => order[(order.indexOf(cur) + 1) % order.length]);
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        e.stopPropagation();
        const order: GameShareTab[] = ['mostPlayed', 'screenTime', 'backlog'];
        setTab((cur) => order[(order.indexOf(cur) - 1 + order.length) % order.length]);
      }
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [onClose]);

  const isDark = palette.isDark;
  const pageBg = isDark ? '#1A1C21' : '#EFEFEF';
  const sidebarBg = isDark ? '#22252B' : '#EAEAEA';
  const textMain = isDark ? '#F3F4F6' : '#2C2C2C';
  const textMuted = isDark ? '#9CA3AF' : '#6B7280';
  const divider = isDark ? 'rgba(255,255,255,0.12)' : '#C8C8C8';
  const accentTeal = '#2CADBF';
  const focusCyanBorder = '#14D0E6';

  const h = metrics.viewportHeight;
  const fontScale = fontScalePct / 100;
  const padX = Math.max(24, Math.round(metrics.screenMargin * 0.9));

  const sortedByHours = [...games].sort((a, b) => b.playTimeHours - a.playTimeHours);
  const totalHours = games.reduce((sum, g) => sum + g.playTimeHours, 0);
  const backlogGames = games.filter((g) => g.inBacklog);

  const resolvePlayerStamps = (game: GameItem) => {
    if (game.playedByUsers && game.playedByUsers.length > 0) {
      return game.playedByUsers;
    }
    if (!game.lastPlayedByUser) {
      return [{ name: activeUser.name, characterId: activeUser.characterId }];
    }
    const found =
      users.find((u) => u.name.toLowerCase() === game.lastPlayedByUser?.toLowerCase()) ?? activeUser;
    return [{ name: found.name, characterId: found.characterId }];
  };

  const navItems: { id: GameShareTab; label: string; subtitle: string }[] = [
    { id: 'mostPlayed', label: 'Most Played', subtitle: `${sortedByHours[0]?.title ?? 'None'}` },
    { id: 'screenTime', label: 'Screen Time', subtitle: `${totalHours.toFixed(1)} hrs total` },
    { id: 'backlog', label: 'Play Backlog', subtitle: `${backlogGames.length} queued` },
  ];

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="GameShare"
      data-testid="gameshare-view"
      className="animate-ns2-fade absolute inset-0 z-40 flex flex-col overflow-hidden select-none"
      style={{ backgroundColor: pageBg, color: textMain }}
    >
      {/* Top Header */}
      <div style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
        <div
          className="flex items-center justify-between"
          style={{ height: `${Math.max(50, Math.round(h * 0.12))}px` }}
        >
          <div className="flex items-center gap-3.5">
            <UiKitGameShareIcon size={32} />
            <h1
              className="font-ud-bold tracking-tight"
              style={{ fontSize: `${Math.round(Math.max(20, h * 0.04) * fontScale)}px` }}
            >
              GameShare
            </h1>
          </div>
          <span
            className="font-ud-semibold"
            style={{ color: textMuted, fontSize: `${Math.round(Math.max(13, h * 0.024) * fontScale)}px` }}
          >
            {activeUser.name} · Retroid Pocket 5
          </span>
        </div>
        <div className="w-full h-px" style={{ backgroundColor: divider }} />
      </div>

      {/* Split Left Sidebar (no outer container border) + Right Content */}
      <div className="flex-1 flex min-h-0">
        <aside
          className="flex flex-col shrink-0 overflow-y-auto no-scrollbar"
          style={{
            width: '30%',
            backgroundColor: sidebarBg,
            paddingLeft: `${padX}px`,
            paddingRight: `${Math.max(16, Math.round(padX * 0.6))}px`,
            paddingTop: `${Math.max(14, Math.round(h * 0.03))}px`,
          }}
        >
          <div className="space-y-2">
            {navItems.map((item) => {
              const isSelected = tab === item.id;
              return (
                <button
                  key={item.id}
                  type="button"
                  data-testid={`gameshare-tab-${item.id}`}
                  onClick={() => setTab(item.id)}
                  className="relative w-full text-left px-4 py-3 cursor-pointer transition-colors focus:outline-none"
                  style={{
                    backgroundColor: isSelected
                      ? isDark
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
                      className="absolute left-1.5 top-2.5 bottom-2.5 w-[3.5px]"
                      style={{ backgroundColor: accentTeal }}
                    />
                  )}
                  <div
                    className={`pl-2 leading-snug ${isSelected ? 'font-ud-bold' : 'font-ud-semibold'}`}
                    style={{
                      fontSize: `${Math.round(Math.max(17, h * 0.033) * fontScale)}px`,
                      color: isSelected ? accentTeal : textMain,
                    }}
                  >
                    {item.label}
                  </div>
                  <div
                    className="pl-2 font-ud-regular truncate mt-0.5"
                    style={{
                      fontSize: `${Math.round(Math.max(13, h * 0.023) * fontScale)}px`,
                      color: textMuted,
                    }}
                  >
                    {item.subtitle}
                  </div>
                </button>
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
          {tab === 'mostPlayed' && (
            <div className="space-y-3">
              <div className="flex items-center gap-2.5 pb-1">
                <Trophy className="w-5 h-5" style={{ color: accentTeal }} />
                <h2
                  className="font-ud-bold"
                  style={{ fontSize: `${Math.round(Math.max(18, h * 0.032) * fontScale)}px` }}
                >
                  Most Played Titles
                </h2>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: divider }} />

              {sortedByHours.map((game) => {
                const players = resolvePlayerStamps(game);
                const gameIdx = games.findIndex((g) => g.id === game.id);
                return (
                  <div key={game.id}>
                    <button
                      type="button"
                      onClick={() => {
                        if (gameIdx >= 0) onSelectGame(gameIdx);
                        onClose();
                      }}
                      className="w-full flex items-center justify-between gap-4 py-3 text-left cursor-pointer hover:bg-black/5 transition-colors"
                    >
                      <div className="flex items-center gap-4 min-w-0">
                        <img
                          src={game.coverUrl}
                          alt={game.title}
                          referrerPolicy="no-referrer"
                          className="w-14 h-14 rounded-lg object-cover shrink-0"
                        />
                        <div className="min-w-0">
                          <div
                            className="font-ud-bold truncate"
                            style={{ fontSize: `${Math.round(Math.max(16, h * 0.028) * fontScale)}px` }}
                          >
                            {game.title}
                          </div>
                          <div
                            className="font-ud-semibold mt-0.5"
                            style={{
                              color: accentTeal,
                              fontSize: `${Math.round(Math.max(13, h * 0.023) * fontScale)}px`,
                            }}
                          >
                            {game.playTimeHours} hours played
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center gap-3 shrink-0 flex-wrap justify-end">
                        <div className="flex items-center gap-2">
                          {players.map((p) => (
                            <div
                              key={`${game.id}-${p.name}`}
                              className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full"
                              style={{ backgroundColor: sidebarBg }}
                            >
                              <UiKitAvatar
                                characterId={p.characterId}
                                size={24}
                                roundedClass="rounded-full"
                                alt={p.name}
                              />
                              <span
                                className="font-ud-semibold"
                                style={{ fontSize: `${Math.round(13 * fontScale)}px` }}
                              >
                                {p.name}
                              </span>
                            </div>
                          ))}
                        </div>
                        <span
                          className="font-ud-regular"
                          style={{
                            color: textMuted,
                            fontSize: `${Math.round(13 * fontScale)}px`,
                          }}
                        >
                          {game.lastPlayedAt || 'Recently'}
                        </span>
                      </div>
                    </button>
                    <div className="h-px w-full" style={{ backgroundColor: divider }} />
                  </div>
                );
              })}
            </div>
          )}

          {tab === 'screenTime' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between pb-1">
                <div className="flex items-center gap-2.5">
                  <Clock className="w-5 h-5" style={{ color: accentTeal }} />
                  <h2
                    className="font-ud-bold"
                    style={{ fontSize: `${Math.round(Math.max(18, h * 0.032) * fontScale)}px` }}
                  >
                    Weekly Screen Time
                  </h2>
                </div>
                <span
                  className="font-ud-bold tabular-nums"
                  style={{ color: accentTeal, fontSize: `${Math.round(16 * fontScale)}px` }}
                >
                  {totalHours.toFixed(1)} Total Hours
                </span>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: divider }} />

              <div className="space-y-3.5">
                {sortedByHours.slice(0, 6).map((game) => {
                  const pct = Math.min(100, Math.round((game.playTimeHours / Math.max(1, sortedByHours[0].playTimeHours)) * 100));
                  return (
                    <div key={game.id} className="space-y-2">
                      <div
                        className="flex items-center justify-between"
                        style={{ fontSize: `${Math.round(15 * fontScale)}px` }}
                      >
                        <span className="font-ud-bold truncate">{game.title}</span>
                        <span className="font-mono-tabular font-ud-semibold" style={{ color: textMuted }}>
                          {game.playTimeHours}h
                        </span>
                      </div>
                      <div
                        className="w-full h-3 rounded-full overflow-hidden"
                        style={{ backgroundColor: sidebarBg }}
                      >
                        <div
                          className="h-full rounded-full"
                          style={{ width: `${pct}%`, backgroundColor: accentTeal }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {tab === 'backlog' && (
            <div className="space-y-3">
              <div className="flex items-center gap-2.5 pb-1">
                <Bookmark className="w-5 h-5" style={{ color: accentTeal }} />
                <h2
                  className="font-ud-bold"
                  style={{ fontSize: `${Math.round(Math.max(18, h * 0.032) * fontScale)}px` }}
                >
                  Backlog Queue
                </h2>
              </div>
              <div className="h-px w-full" style={{ backgroundColor: divider }} />

              {backlogGames.length === 0 ? (
                <p
                  className="font-ud-regular py-6"
                  style={{ color: textMuted, fontSize: `${Math.round(15 * fontScale)}px` }}
                >
                  No titles queued in Backlog yet.
                </p>
              ) : (
                backlogGames.map((g) => (
                  <div key={g.id}>
                    <div className="flex items-center justify-between gap-4 py-3">
                      <div className="flex items-center gap-4 min-w-0">
                        <img
                          src={g.coverUrl}
                          alt={g.title}
                          referrerPolicy="no-referrer"
                          className="w-14 h-14 rounded-lg object-cover shrink-0"
                        />
                        <div className="min-w-0">
                          <div
                            className="font-ud-bold truncate"
                            style={{ fontSize: `${Math.round(16 * fontScale)}px` }}
                          >
                            {g.title}
                          </div>
                          <div
                            className="font-ud-regular"
                            style={{ color: textMuted, fontSize: `${Math.round(13 * fontScale)}px` }}
                          >
                            {g.platform} · {g.genre}
                          </div>
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={() => onToggleBacklog(g.id)}
                        className="px-4 py-1.5 rounded-lg text-sm font-ud-semibold cursor-pointer"
                        style={{ backgroundColor: sidebarBg, color: textMain }}
                      >
                        Remove
                      </button>
                    </div>
                    <div className="h-px w-full" style={{ backgroundColor: divider }} />
                  </div>
                ))
              )}
            </div>
          )}
        </section>
      </div>

      {/* Bottom Sticky Footer */}
      <footer style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
        <div className="w-full h-px" style={{ backgroundColor: divider }} />
        <div
          className="flex items-center justify-between"
          style={{ height: `${Math.max(40, Math.round(h * 0.088))}px` }}
        >
          <BottomControllerGlyph size={metrics.helpIconSize} color={textMain} />
          <button
            type="button"
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
              className="font-ud-semibold"
              style={{ fontSize: `${metrics.helpFontSize}px`, color: textMain }}
            >
              Back
            </span>
          </button>
        </div>
      </footer>
    </div>
  );
}
