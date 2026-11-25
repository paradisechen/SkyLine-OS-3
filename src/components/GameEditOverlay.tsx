import { useEffect, useRef, useState } from 'react';
import { Heart, ImagePlus, Pencil, Wallpaper } from 'lucide-react';
import type { AdaptivePalette, GameItem } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { SwitchPdfIcon } from './SwitchPdfIcons';
import { BottomControllerGlyph } from './BottomControllerGlyph';

interface GameEditOverlayProps {
  isOpen: boolean;
  game: GameItem | null;
  palette: AdaptivePalette;
  metrics: Switch2LayoutMetrics;
  onSaveGame: (
    gameId: string,
    updates: { title: string; coverUrl?: string; backgroundUrl?: string }
  ) => void;
  onToggleFavorite: (gameId: string) => void;
  onClose: () => void;
}

/**
 * Switch 2 bottom-sheet overlay (matching UserSelectOverlay) letting the user
 * instantly customize Main Photo (Cover), Game Background, and Game Name.
 */
export function GameEditOverlay({
  isOpen,
  game,
  palette,
  metrics,
  onSaveGame,
  onToggleFavorite,
  onClose,
}: GameEditOverlayProps) {
  const [rendered, setRendered] = useState(isOpen);
  const [visible, setVisible] = useState(false);
  const [draftTitle, setDraftTitle] = useState(game?.title ?? '');
  const [draftCover, setDraftCover] = useState<string | undefined>(undefined);
  const [draftBg, setDraftBg] = useState<string | undefined>(undefined);
  const [editingTitle, setEditingTitle] = useState(false);
  const coverInputRef = useRef<HTMLInputElement>(null);
  const bgInputRef = useRef<HTMLInputElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isOpen && game) {
      setRendered(true);
      setDraftTitle(game.title);
      setDraftCover(game.coverUrl);
      setDraftBg(game.backgroundUrl || game.coverUrl);
      setEditingTitle(false);
      const raf = requestAnimationFrame(() => {
        requestAnimationFrame(() => setVisible(true));
      });
      return () => cancelAnimationFrame(raf);
    }
    setVisible(false);
    const timer = window.setTimeout(() => setRendered(false), 160);
    return () => window.clearTimeout(timer);
  }, [isOpen, game?.id]);

  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        if (editingTitle) setEditingTitle(false);
        else onClose();
      }
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [isOpen, editingTitle, onClose]);

  if (!rendered || !game) return null;

  const h = metrics.viewportHeight;
  const artSize = Math.max(96, Math.round(h * 0.2));
  const sheetPadX = Math.max(24, Math.round(metrics.screenMargin * 0.95));
  const displayCover = draftCover || game.coverUrl;
  const displayBg = draftBg || game.backgroundUrl || game.coverUrl;

  const applyInstant = (nextTitle: string, nextCover?: string, nextBg?: string) => {
    onSaveGame(game.id, {
      title: nextTitle.trim() || game.title,
      coverUrl: nextCover ?? displayCover,
      backgroundUrl: nextBg ?? displayBg,
    });
  };

  const handleCoverUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result === 'string') {
        setDraftCover(reader.result);
        applyInstant(draftTitle, reader.result, displayBg);
      }
    };
    reader.readAsDataURL(file);
  };

  const handleBgUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result === 'string') {
        setDraftBg(reader.result);
        applyInstant(draftTitle, displayCover, reader.result);
      }
    };
    reader.readAsDataURL(file);
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Edit Software"
      data-testid="game-edit-overlay"
      className="absolute inset-0 z-50 flex flex-col justify-end overflow-hidden"
    >
      <div
        onClick={onClose}
        className="absolute inset-0 bg-black/45 transition-opacity duration-150 ease-out"
        style={{ opacity: visible ? 1 : 0 }}
      />

      <div
        className="relative z-10 w-full flex flex-col justify-between transition-transform duration-150"
        style={{
          height: '66%',
          backgroundColor: palette.overlaySheetBg,
          color: palette.overlayText,
          transform: visible ? 'translateY(0%)' : 'translateY(100%)',
          transitionTimingFunction: 'cubic-bezier(0.16, 1, 0.3, 1)',
          borderTop: `1px solid ${palette.overlayDivider}`,
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top Header */}
        <div style={{ paddingLeft: `${sheetPadX}px`, paddingRight: `${sheetPadX}px` }}>
          <div
            className="flex items-center justify-between"
            style={{
              paddingTop: `${Math.max(12, Math.round(h * 0.022))}px`,
              paddingBottom: `${Math.max(10, Math.round(h * 0.018))}px`,
            }}
          >
            <h2
              className="font-ud-semibold tracking-tight"
              style={{ fontSize: `${Math.max(16, Math.round(h * 0.032))}px` }}
            >
              Edit Game Artwork &amp; Name
            </h2>
            <span
              className="font-ud-regular text-xs"
              style={{ color: palette.overlayMuted }}
            >
              {game.platform} · Instant Update
            </span>
          </div>
          <div className="w-full h-px" style={{ backgroundColor: palette.overlayDivider }} />
        </div>

        {/* Centered Main Photo + Game Background Side-by-Side Above Instant Title Input */}
        <div
          className="flex-1 flex flex-col items-center justify-center gap-4 min-h-0"
          style={{ paddingLeft: `${sheetPadX}px`, paddingRight: `${sheetPadX}px` }}
        >
          <div className="flex items-center justify-center gap-6">
            {/* Main Photo (Cover) */}
            <div className="flex flex-col items-center gap-1.5">
              <button
                type="button"
                data-testid="game-edit-cover-btn"
                onClick={() => coverInputRef.current?.click()}
                aria-label="Change main photo"
                className="relative overflow-hidden cursor-pointer focus:outline-none transition-transform duration-150 hover:scale-[1.03]"
                style={{
                  width: `${artSize}px`,
                  height: `${artSize}px`,
                  borderRadius: '10px',
                  border: `3px solid ${palette.borderPrimary}`,
                  backgroundColor: palette.overlayCardBg,
                }}
              >
                <img
                  src={displayCover}
                  alt={draftTitle || game.title}
                  referrerPolicy="no-referrer"
                  className="w-full h-full object-cover block"
                />
                <span className="absolute bottom-1.5 right-1.5 px-2 py-0.5 rounded-full bg-black/75 text-white flex items-center gap-1 text-[10px] font-ud-semibold">
                  <ImagePlus className="w-3 h-3" />
                  <span>Main Photo</span>
                </span>
              </button>
              <input
                ref={coverInputRef}
                type="file"
                accept="image/*"
                onChange={handleCoverUpload}
                className="hidden"
              />
            </div>

            {/* Game Background */}
            <div className="flex flex-col items-center gap-1.5">
              <button
                type="button"
                data-testid="game-edit-bg-btn"
                onClick={() => bgInputRef.current?.click()}
                aria-label="Change game background"
                className="relative overflow-hidden cursor-pointer focus:outline-none transition-transform duration-150 hover:scale-[1.03]"
                style={{
                  width: `${Math.round(artSize * 1.65)}px`,
                  height: `${artSize}px`,
                  borderRadius: '10px',
                  border: `3px solid ${palette.dockRingColor}`,
                  backgroundColor: palette.overlayCardBg,
                }}
              >
                <img
                  src={displayBg}
                  alt="Game Background"
                  referrerPolicy="no-referrer"
                  className="w-full h-full object-cover block"
                />
                <span className="absolute bottom-1.5 right-1.5 px-2 py-0.5 rounded-full bg-black/75 text-white flex items-center gap-1 text-[10px] font-ud-semibold">
                  <Wallpaper className="w-3 h-3" />
                  <span>Game Background</span>
                </span>
              </button>
              <input
                ref={bgInputRef}
                type="file"
                accept="image/*"
                onChange={handleBgUpload}
                className="hidden"
              />
            </div>
          </div>

          {/* Instant Game Name Editor + Quick Actions */}
          <div className="flex flex-col items-center gap-2.5 w-full max-w-lg">
            {editingTitle ? (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  setEditingTitle(false);
                }}
                className="flex items-center gap-2 w-full justify-center"
              >
                <input
                  ref={inputRef}
                  type="text"
                  data-testid="game-edit-title-input"
                  value={draftTitle}
                  onChange={(e) => {
                    const v = e.target.value;
                    setDraftTitle(v);
                    applyInstant(v, displayCover, displayBg);
                  }}
                  onBlur={() => window.getSelection()?.removeAllRanges()}
                  maxLength={52}
                  autoFocus
                  className="px-3.5 py-2 rounded-lg text-sm font-ud-semibold text-center focus:outline-none flex-1"
                  style={{
                    backgroundColor: palette.overlayCardBg,
                    color: palette.overlayText,
                    border: `2px solid ${palette.borderPrimary}`,
                  }}
                />
                <button
                  type="submit"
                  className="px-3.5 py-2 rounded-lg text-xs font-ud-bold text-white cursor-pointer"
                  style={{ backgroundColor: palette.borderPrimary }}
                >
                  Done
                </button>
              </form>
            ) : (
              <button
                type="button"
                data-testid="game-edit-open-keyboard"
                onClick={() => {
                  setEditingTitle(true);
                  window.setTimeout(() => inputRef.current?.focus(), 30);
                }}
                className="flex items-center justify-center gap-2.5 px-5 py-2 rounded-lg cursor-pointer transition-colors hover:opacity-85"
                style={{
                  backgroundColor: palette.overlayCardBg,
                  color: palette.overlayText,
                  border: `1px solid ${palette.overlayDivider}`,
                }}
              >
                <span
                  className="font-ud-semibold truncate max-w-sm"
                  style={{ fontSize: `${Math.max(15, Math.round(h * 0.028))}px` }}
                >
                  {draftTitle || game.title}
                </span>
                <Pencil className="w-3.5 h-3.5 shrink-0 opacity-75" />
              </button>
            )}

            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={() => onToggleFavorite(game.id)}
                className="flex items-center gap-2 px-4 py-1.5 rounded-lg text-xs font-ud-semibold cursor-pointer"
                style={{
                  backgroundColor: palette.overlayCardBg,
                  color: palette.overlayText,
                  border: `1px solid ${palette.overlayDivider}`,
                }}
              >
                <Heart
                  className={`w-3.5 h-3.5 ${game.favorite ? 'fill-current' : ''}`}
                  style={{ color: game.favorite ? palette.favoriteHeartBg : palette.overlayMuted }}
                />
                <span>{game.favorite ? 'Favorited' : 'Favorite'}</span>
              </button>

              <button
                type="button"
                data-testid="game-edit-save"
                onClick={onClose}
                className="px-5 py-1.5 rounded-lg text-xs font-ud-bold text-white cursor-pointer"
                style={{ backgroundColor: palette.borderPrimary }}
              >
                Done
              </button>
            </div>
          </div>
        </div>

        {/* Bottom Footer Row */}
        <div style={{ paddingLeft: `${sheetPadX}px`, paddingRight: `${sheetPadX}px` }}>
          <div className="w-full h-px" style={{ backgroundColor: palette.overlayDivider }} />
          <div
            className="flex items-center justify-between"
            style={{ height: `${Math.max(40, Math.round(h * 0.085))}px` }}
          >
            <BottomControllerGlyph size={metrics.helpIconSize} color={palette.overlayText} />

            <div className="flex items-center gap-6">
              <button
                type="button"
                onClick={onClose}
                className="flex items-center gap-2 cursor-pointer hover:opacity-75"
              >
                <SwitchPdfIcon
                  button="B"
                  size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                  fillColor={palette.overlayText}
                  cutoutColor={palette.overlaySheetBg}
                />
                <span
                  className="font-ud-semibold"
                  style={{ fontSize: `${metrics.helpFontSize}px`, color: palette.overlayText }}
                >
                  Close
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
