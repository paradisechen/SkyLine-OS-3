import { useEffect, useRef } from 'react';
import { Heart, LayoutGrid } from 'lucide-react';
import type { AdaptivePalette, FocusZone, GameItem } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { UiKitGameCardBadgeIcon } from './UiKitIcons';

interface HomeCarouselProps {
  games: GameItem[];
  selectedIndex: number;
  focusZone: FocusZone;
  metrics: Switch2LayoutMetrics;
  palette: AdaptivePalette;
  onSelectIndex: (index: number) => void;
  onActivateItem: (index: number) => void;
  onLongPressEdit: (game: GameItem, index: number) => void;
}

export function HomeCarousel({
  games,
  selectedIndex,
  focusZone,
  metrics,
  palette,
  onSelectIndex,
  onActivateItem,
  onLongPressEdit,
}: HomeCarouselProps) {
  const scrollerRef = useRef<HTMLDivElement>(null);
  const itemRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const holdTimerRef = useRef<number | null>(null);
  const longPressFiredRef = useRef(false);

  const isGamesFocused = focusZone === 'games';
  const totalCount = games.length + 1;

  useEffect(() => {
    const el = itemRefs.current[selectedIndex];
    if (el) {
      el.scrollIntoView({
        behavior: 'smooth',
        inline: 'center',
        block: 'nearest',
      });
    }
  }, [selectedIndex]);

  useEffect(() => {
    return () => {
      if (holdTimerRef.current !== null) {
        window.clearTimeout(holdTimerRef.current);
      }
    };
  }, []);

  const clearHold = () => {
    if (holdTimerRef.current !== null) {
      window.clearTimeout(holdTimerRef.current);
      holdTimerRef.current = null;
    }
  };

  const borderOverhang = metrics.borderGap + metrics.borderStroke;
  const titleHeadroom =
    metrics.gameTitleFontSize + metrics.gameTitleBottomOffset + borderOverhang + 10;

  return (
    <section
      aria-label="Game Library Carousel"
      className="relative z-20 flex-1 flex flex-col justify-center w-full min-h-0"
    >
      <div
        ref={scrollerRef}
        data-testid="game-carousel"
        className="flex items-center overflow-x-auto no-scrollbar w-full"
        style={{
          paddingLeft: `${metrics.screenMargin + borderOverhang}px`,
          paddingRight: `${metrics.screenMargin + borderOverhang}px`,
          paddingTop: `${titleHeadroom}px`,
          paddingBottom: `${borderOverhang + 16}px`,
          gap: `${metrics.cardGap}px`,
        }}
      >
        {games.map((game, index) => {
          const isSelected = selectedIndex === index;
          const isFocused = isSelected && isGamesFocused;

          return (
            <div
              key={game.id}
              className="relative shrink-0 flex items-center justify-center"
              style={{
                width: `${metrics.cardSize}px`,
                height: `${metrics.cardSize}px`,
              }}
            >
              {/* Selected Game Name + UI Kit Game Card Icon Above Cover */}
              <div
                aria-hidden={!isSelected}
                data-testid={isSelected ? 'selected-game-title' : undefined}
                className={`absolute left-1/2 -translate-x-1/2 pointer-events-none flex items-center gap-2 font-ud-regular tracking-tight whitespace-nowrap transition-all duration-150 ${
                  isSelected ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-1'
                }`}
                style={{
                  bottom: `${metrics.cardSize + borderOverhang + metrics.gameTitleBottomOffset}px`,
                  color: palette.gameTitleColor,
                  fontSize: `${metrics.gameTitleFontSize}px`,
                  maxWidth: `${Math.round(metrics.cardSize * 2.1)}px`,
                }}
              >
                <UiKitGameCardBadgeIcon
                  size={Math.max(16, Math.round(metrics.gameTitleFontSize * 0.88))}
                  color={palette.gameTitleColor}
                />
                <span className="truncate">{game.title}</span>
              </div>

              {/* Bold Iridescent UI Kit Selection Border */}
              {isSelected && (
                <div
                  aria-hidden="true"
                  data-testid="selection-border"
                  className="pointer-events-none absolute z-30 transition-opacity duration-150"
                  style={{
                    inset: `-${borderOverhang}px`,
                    borderRadius: `${metrics.borderOuterRadius}px`,
                    padding: `${metrics.borderStroke}px`,
                    background: palette.iridescentGradient,
                    WebkitMask: 'linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)',
                    WebkitMaskComposite: 'xor',
                    maskComposite: 'exclude',
                    opacity: isFocused ? 1 : 0.72,
                  }}
                />
              )}

              {/* Cover Tile — hold press opens GameEditOverlay */}
              <button
                ref={(el) => {
                  itemRefs.current[index] = el;
                }}
                type="button"
                data-testid={`game-card-${index}`}
                aria-label={`${game.title}${isSelected ? ' (Selected)' : ''}`}
                aria-pressed={isSelected}
                onPointerDown={() => {
                  clearHold();
                  longPressFiredRef.current = false;
                  holdTimerRef.current = window.setTimeout(() => {
                    longPressFiredRef.current = true;
                    onLongPressEdit(game, index);
                  }, 520);
                }}
                onPointerUp={clearHold}
                onPointerLeave={clearHold}
                onPointerCancel={clearHold}
                onContextMenu={(e) => {
                  e.preventDefault();
                  clearHold();
                  onLongPressEdit(game, index);
                }}
                onClick={() => {
                  if (longPressFiredRef.current) {
                    longPressFiredRef.current = false;
                    return;
                  }
                  if (isSelected) {
                    onActivateItem(index);
                  } else {
                    onSelectIndex(index);
                  }
                }}
                className="relative z-10 w-full h-full overflow-hidden cursor-pointer focus:outline-none transition-transform duration-150 active:scale-[0.97]"
                style={{
                  borderRadius: `${metrics.cardRadius}px`,
                  backgroundColor: palette.cardSurface,
                  boxShadow: 'none',
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
                    aria-label="Favorited"
                    data-testid={`game-fav-heart-${index}`}
                    className="absolute top-2.5 right-2.5 rounded-full flex items-center justify-center transition-colors duration-200"
                    style={{
                      width: `${Math.max(24, Math.round(metrics.cardSize * 0.105))}px`,
                      height: `${Math.max(24, Math.round(metrics.cardSize * 0.105))}px`,
                      backgroundColor: palette.favoriteHeartBg,
                    }}
                  >
                    <Heart
                      className="fill-current"
                      style={{
                        width: `${Math.max(13, Math.round(metrics.cardSize * 0.055))}px`,
                        height: `${Math.max(13, Math.round(metrics.cardSize * 0.055))}px`,
                        color: palette.favoriteHeartIcon,
                      }}
                    />
                  </span>
                )}
              </button>
            </div>
          );
        })}

        {/* All Software Tile */}
        {(() => {
          const allIndex = totalCount - 1;
          const isSelected = selectedIndex === allIndex;
          const isFocused = isSelected && isGamesFocused;
          const allSize = metrics.allSoftCardSize;
          const allRadius = Math.max(12, Math.round(allSize * 0.12));

          return (
            <div
              className="relative shrink-0 flex items-center justify-center"
              style={{
                width: `${allSize}px`,
                height: `${allSize}px`,
              }}
            >
              <div
                aria-hidden={!isSelected}
                className={`absolute left-1/2 -translate-x-1/2 pointer-events-none text-center font-ud-bold tracking-tight whitespace-nowrap transition-all duration-150 ${
                  isSelected ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-1'
                }`}
                style={{
                  bottom: `${allSize + borderOverhang + metrics.gameTitleBottomOffset}px`,
                  color: palette.gameTitleColor,
                  fontSize: `${metrics.gameTitleFontSize}px`,
                }}
              >
                All Software
              </div>

              {isSelected && (
                <div
                  aria-hidden="true"
                  className="pointer-events-none absolute z-30 transition-opacity duration-150"
                  style={{
                    inset: `-${borderOverhang}px`,
                    borderRadius: `${allRadius + borderOverhang}px`,
                    padding: `${metrics.borderStroke}px`,
                    background: palette.iridescentGradient,
                    WebkitMask: 'linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)',
                    WebkitMaskComposite: 'xor',
                    maskComposite: 'exclude',
                    opacity: isFocused ? 1 : 0.72,
                  }}
                />
              )}

              <button
                ref={(el) => {
                  itemRefs.current[allIndex] = el;
                }}
                type="button"
                data-testid="all-software-tile"
                aria-label="All Software"
                onClick={() => {
                  if (isSelected) {
                    onActivateItem(allIndex);
                  } else {
                    onSelectIndex(allIndex);
                  }
                }}
                className="relative z-10 w-full h-full flex items-center justify-center overflow-hidden cursor-pointer focus:outline-none transition-transform duration-150 active:scale-[0.97]"
                style={{
                  borderRadius: `${allRadius}px`,
                  backgroundColor: palette.statusPillBg,
                  boxShadow: 'none',
                }}
              >
                <LayoutGrid
                  style={{
                    width: `${Math.round(allSize * 0.42)}px`,
                    height: `${Math.round(allSize * 0.42)}px`,
                    color: palette.topBarIcon,
                  }}
                  strokeWidth={2}
                />
              </button>
            </div>
          );
        })()}
      </div>
    </section>
  );
}
