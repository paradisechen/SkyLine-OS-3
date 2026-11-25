import { useEffect, useMemo, useRef, useState } from 'react';
import { Heart, LayoutGrid, Minus, Plus } from 'lucide-react';
import type { AdaptivePalette, GameItem } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { SwitchPdfIcon } from './SwitchPdfIcons';
import { BottomControllerGlyph } from './BottomControllerGlyph';

interface AllSoftwareGridViewProps {
  games: GameItem[];
  allSoftwareSizePct: number;
  palette: AdaptivePalette;
  metrics: Switch2LayoutMetrics;
  onChangeSizePct: (nextPct: number) => void;
  onLongPressEdit: (game: GameItem) => void;
  onSelectAndLaunch: (game: GameItem, index: number) => void;
  onOpenDetails: (game: GameItem) => void;
  onClose: () => void;
}

/**
 * Full-screen flat Switch 2 All Software grid with:
 * - L1 / R1 system filtering
 * - - / + buttons and keyboard keys to resize grid tiles / row quantity
 * - 500ms press-and-hold on any game to open GameEditOverlay
 * - Full 2D D-Pad navigation
 */
export function AllSoftwareGridView({
  games,
  allSoftwareSizePct,
  palette,
  metrics,
  onChangeSizePct,
  onLongPressEdit,
  onSelectAndLaunch,
  onOpenDetails,
  onClose,
}: AllSoftwareGridViewProps) {
  const [focusedIdx, setFocusedIdx] = useState(0);
  const [systemFilter, setSystemFilter] = useState<string>('All');
  const holdTimerRef = useRef<number | null>(null);
  const longPressFiredRef = useRef(false);

  const systemTabs = useMemo(() => {
    const seen = new Set<string>();
    const list = ['All'];
    for (const g of games) {
      const label = g.platform.trim();
      if (label && !seen.has(label)) {
        seen.add(label);
        list.push(label);
      }
    }
    return list;
  }, [games]);

  const filteredGames = useMemo(() => {
    const base = systemFilter === 'All' ? games : games.filter((g) => g.platform === systemFilter);
    return [...base].sort((a, b) => Number(Boolean(b.favorite)) - Number(Boolean(a.favorite)));
  }, [games, systemFilter]);

  // 75..130% maps to 6..3 columns dynamically
  const cols =
    allSoftwareSizePct <= 80
      ? 6
      : allSoftwareSizePct <= 95
        ? 5
        : allSoftwareSizePct <= 112
          ? 4
          : 3;

  const adjustSize = (delta: number) => {
    const next = Math.max(75, Math.min(130, allSoftwareSizePct + delta));
    onChangeSizePct(next);
  };

  useEffect(() => {
    setFocusedIdx((p) => (p >= filteredGames.length ? Math.max(0, filteredGames.length - 1) : p));
  }, [filteredGames.length]);

  useEffect(() => {
    return () => {
      if (holdTimerRef.current !== null) window.clearTimeout(holdTimerRef.current);
    };
  }, []);

  const clearHold = () => {
    if (holdTimerRef.current !== null) {
      window.clearTimeout(holdTimerRef.current);
      holdTimerRef.current = null;
    }
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const lower = e.key.toLowerCase();
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        onClose();
        return;
      }

      // - / + changes tile size & grid columns
      if (e.key === '-' || e.key === '_') {
        e.preventDefault();
        e.stopPropagation();
        adjustSize(-10);
        return;
      }
      if (e.key === '+' || e.key === '=') {
        e.preventDefault();
        e.stopPropagation();
        adjustSize(10);
        return;
      }

      // L1 / R1 cycles system tabs inside All Software
      if (lower === 'q' || e.key === '[') {
        e.preventDefault();
        e.stopPropagation();
        const curIdx = systemTabs.indexOf(systemFilter);
        const nextIdx = (curIdx - 1 + systemTabs.length) % systemTabs.length;
        setSystemFilter(systemTabs[nextIdx]);
        setFocusedIdx(0);
        return;
      }
      if (lower === 'e' || e.key === ']') {
        e.preventDefault();
        e.stopPropagation();
        const curIdx = systemTabs.indexOf(systemFilter);
        const nextIdx = (curIdx + 1) % systemTabs.length;
        setSystemFilter(systemTabs[nextIdx]);
        setFocusedIdx(0);
        return;
      }

      if (filteredGames.length === 0) return;

      if (e.key === 'ArrowRight') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((p) => (p + 1 < filteredGames.length ? p + 1 : 0));
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((p) => (p > 0 ? p - 1 : Math.max(0, filteredGames.length - 1)));
      } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((p) => (p + cols < filteredGames.length ? p + cols : p));
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((p) => (p - cols >= 0 ? p - cols : p));
      } else if (e.key === 'Enter' && filteredGames[focusedIdx]) {
        e.preventDefault();
        e.stopPropagation();
        const chosen = filteredGames[focusedIdx];
        const origIdx = games.findIndex((g) => g.id === chosen.id);
        onSelectAndLaunch(chosen, origIdx >= 0 ? origIdx : 0);
      } else if (lower === 'y' && filteredGames[focusedIdx]) {
        e.preventDefault();
        e.stopPropagation();
        onOpenDetails(filteredGames[focusedIdx]);
      }
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [allSoftwareSizePct, cols, filteredGames, focusedIdx, games, onChangeSizePct, onClose, onOpenDetails, onSelectAndLaunch, systemFilter, systemTabs]);

  const h = metrics.viewportHeight;
  const padX = Math.max(28, Math.round(metrics.screenMargin));
  const divider = palette.overlayDivider;

  const cycleSystem = (dir: -1 | 1) => {
    const curIdx = systemTabs.indexOf(systemFilter);
    const nextIdx = (curIdx + dir + systemTabs.length) % systemTabs.length;
    setSystemFilter(systemTabs[nextIdx]);
    setFocusedIdx(0);
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="All Software"
      data-testid="all-software-view"
      className="animate-ns2-fade absolute inset-0 z-40 flex flex-col overflow-hidden select-none"
      style={{ backgroundColor: palette.canvasBg, color: palette.topBarText }}
    >
      {/* Flat Top Header + L1/R1 System Filter Strip + -/+ Grid Size Controls */}
      <div style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
        <div
          className="flex items-center justify-between gap-4"
          style={{ height: `${Math.max(48, Math.round(h * 0.11))}px` }}
        >
          <div className="flex items-center gap-3 shrink-0">
            <LayoutGrid className="w-5 h-5" style={{ color: palette.borderPrimary }} />
            <h1
              className="font-ud-medium tracking-tight"
              style={{ fontSize: `${Math.max(18, Math.round(h * 0.036))}px` }}
            >
              All Software
            </h1>
          </div>

          <div
            data-testid="all-software-system-tabs"
            className="flex items-center gap-2 overflow-x-auto no-scrollbar py-1"
          >
            <button
              type="button"
              onClick={() => cycleSystem(-1)}
              aria-label="Previous system (L1)"
              className="p-1 cursor-pointer hover:opacity-75 shrink-0"
            >
              <SwitchPdfIcon
                button="L1"
                size={20}
                fillColor={palette.topBarText}
                cutoutColor={palette.canvasBg}
              />
            </button>
            {systemTabs.map((sys) => {
              const active = systemFilter === sys;
              return (
                <button
                  key={sys}
                  type="button"
                  data-testid={`allsoft-filter-${sys}`}
                  onClick={() => {
                    setSystemFilter(sys);
                    setFocusedIdx(0);
                  }}
                  className={`px-3 py-1 rounded-full text-xs whitespace-nowrap cursor-pointer ${
                    active ? 'font-ud-medium' : 'font-ud-regular'
                  }`}
                  style={{
                    backgroundColor: active ? palette.borderPrimary : palette.cardSurface,
                    color: active ? '#FFFFFF' : palette.topBarText,
                    border: `1px solid ${active ? palette.borderPrimary : divider}`,
                  }}
                >
                  {sys}
                </button>
              );
            })}
            <button
              type="button"
              onClick={() => cycleSystem(1)}
              aria-label="Next system (R1)"
              className="p-1 cursor-pointer hover:opacity-75 shrink-0"
            >
              <SwitchPdfIcon
                button="R1"
                size={20}
                fillColor={palette.topBarText}
                cutoutColor={palette.canvasBg}
              />
            </button>
          </div>

          {/* - / + Grid Tile Size & Column Controls */}
          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              data-testid="allsoft-size-minus"
              aria-label="Smaller grid tiles (-)"
              onClick={() => adjustSize(-10)}
              className="w-7 h-7 rounded-full flex items-center justify-center cursor-pointer hover:opacity-80"
              style={{ backgroundColor: palette.cardSurface, border: `1px solid ${divider}` }}
            >
              <Minus className="w-3.5 h-3.5" />
            </button>
            <span className="font-mono-tabular text-xs font-ud-semibold px-1">
              {cols}×
            </span>
            <button
              type="button"
              data-testid="allsoft-size-plus"
              aria-label="Larger grid tiles (+)"
              onClick={() => adjustSize(10)}
              className="w-7 h-7 rounded-full flex items-center justify-center cursor-pointer hover:opacity-80"
              style={{ backgroundColor: palette.cardSurface, border: `1px solid ${divider}` }}
            >
              <Plus className="w-3.5 h-3.5" />
            </button>
            <span
              className="font-ud-regular tabular-nums ml-2"
              style={{ fontSize: `${Math.max(12, Math.round(h * 0.022))}px`, color: palette.overlayMuted }}
            >
              {filteredGames.length} Titles
            </span>
          </div>
        </div>
        <div className="w-full h-px" style={{ backgroundColor: divider }} />
      </div>

      {/* Sliding Grid Scaled by allSoftwareSizePct */}
      <div
        data-scroll-container="true"
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{
          paddingLeft: `${padX}px`,
          paddingRight: `${padX}px`,
          paddingTop: `${Math.max(18, Math.round(h * 0.036))}px`,
          paddingBottom: `${Math.max(18, Math.round(h * 0.036))}px`,
        }}
      >
        <div
          data-testid="all-software-grid"
          data-cols={cols}
          className="grid gap-x-5 gap-y-6"
          style={{
            gridTemplateColumns: `repeat(${cols}, minmax(0, 1fr))`,
          }}
        >
          {filteredGames.map((game, idx) => {
            const isSelected = focusedIdx === idx;
            const origIdx = games.findIndex((g) => g.id === game.id);
            return (
              <div key={game.id} className="flex flex-col items-center gap-2">
                <button
                  type="button"
                  data-testid={`all-software-card-${idx}`}
                  onMouseEnter={() => setFocusedIdx(idx)}
                  onPointerDown={() => {
                    clearHold();
                    longPressFiredRef.current = false;
                    holdTimerRef.current = window.setTimeout(() => {
                      longPressFiredRef.current = true;
                      onLongPressEdit(game);
                    }, 520);
                  }}
                  onPointerUp={clearHold}
                  onPointerLeave={clearHold}
                  onPointerCancel={clearHold}
                  onContextMenu={(e) => {
                    e.preventDefault();
                    clearHold();
                    onLongPressEdit(game);
                  }}
                  onClick={() => {
                    if (longPressFiredRef.current) {
                      longPressFiredRef.current = false;
                      return;
                    }
                    onSelectAndLaunch(game, origIdx >= 0 ? origIdx : idx);
                  }}
                  className="relative w-full aspect-square overflow-hidden cursor-pointer focus:outline-none transition-transform duration-150 active:scale-[0.97]"
                  style={{
                    borderRadius: '14px',
                    backgroundColor: palette.cardSurface,
                    border: isSelected
                      ? `4px solid ${palette.dockRingColor}`
                      : `1px solid ${divider}`,
                    transform: isSelected ? 'scale(1.02)' : 'scale(1)',
                  }}
                >
                  <img
                    src={game.coverUrl}
                    alt={game.title}
                    referrerPolicy="no-referrer"
                    className={`w-full h-full object-cover block ${game.coverCropClass ?? ''}`}
                  />
                  {game.favorite && (
                    <span
                      className="absolute top-2 right-2 w-6 h-6 rounded-full flex items-center justify-center"
                      style={{ backgroundColor: palette.favoriteHeartBg }}
                    >
                      <Heart
                        className="w-3.5 h-3.5 fill-current"
                        style={{ color: palette.favoriteHeartIcon }}
                      />
                    </span>
                  )}
                </button>
                <span
                  className="w-full text-center font-ud-regular truncate px-1"
                  style={{
                    fontSize: `${Math.max(11, Math.round(h * 0.022))}px`,
                    color: isSelected ? palette.gameTitleColor : palette.topBarText,
                  }}
                >
                  {game.title}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Bottom Bar */}
      <footer style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
        <div className="w-full h-px" style={{ backgroundColor: divider }} />
        <div
          className="flex items-center justify-between"
          style={{ height: `${Math.max(40, Math.round(h * 0.088))}px` }}
        >
          <BottomControllerGlyph size={metrics.helpIconSize} color={palette.helpBarIcon} />
          <div className="flex items-center gap-6">
            <span className="text-xs font-ud-regular" style={{ color: palette.overlayMuted }}>
              − / + Tile Size · Hold to Edit
            </span>
            <button
              type="button"
              onClick={onClose}
              className="flex items-center gap-2 cursor-pointer hover:opacity-75"
            >
              <SwitchPdfIcon
                button="B"
                size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                fillColor={palette.helpBarText}
                cutoutColor={palette.canvasBg}
              />
              <span
                className="font-ud-regular"
                style={{ fontSize: `${metrics.helpFontSize}px`, color: palette.helpBarText }}
              >
                Back
              </span>
            </button>
            {filteredGames[focusedIdx] && (
              <>
                <button
                  type="button"
                  data-testid="allsoft-details-btn"
                  onClick={() => onOpenDetails(filteredGames[focusedIdx])}
                  className="flex items-center gap-2 cursor-pointer hover:opacity-75"
                >
                  <SwitchPdfIcon
                    button="Y"
                    size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                    fillColor={palette.helpBarText}
                    cutoutColor={palette.canvasBg}
                  />
                  <span
                    className="font-ud-regular"
                    style={{ fontSize: `${metrics.helpFontSize}px`, color: palette.helpBarText }}
                  >
                    Details
                  </span>
                </button>
                <button
                  type="button"
                  data-testid="allsoft-start-btn"
                  onClick={() => {
                    const chosen = filteredGames[focusedIdx];
                    const origIdx = games.findIndex((g) => g.id === chosen.id);
                    onSelectAndLaunch(chosen, origIdx >= 0 ? origIdx : focusedIdx);
                  }}
                  className="flex items-center gap-2 cursor-pointer hover:opacity-75"
                >
                  <SwitchPdfIcon
                    button="A"
                    size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                    fillColor={palette.helpBarText}
                    cutoutColor={palette.canvasBg}
                  />
                  <span
                    className="font-ud-regular"
                    style={{ fontSize: `${metrics.helpFontSize}px`, color: palette.helpBarText }}
                  >
                    Start
                  </span>
                </button>
              </>
            )}
          </div>
        </div>
      </footer>
    </div>
  );
}
