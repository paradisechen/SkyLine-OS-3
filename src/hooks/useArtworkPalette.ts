import { useEffect, useState } from 'react';
import type {
  AdaptivePalette,
  GameItem,
  HudColorThemeId,
  RgbColor,
  ThemeAppearanceMode,
  UiKitBorderPreset,
} from '../types/skyline';
import { buildAdaptiveTheme, extractPaletteFromPixels } from '../utils/artworkPalette';

interface CachedColors {
  dominant: RgbColor;
  accent: RgbColor;
  averageLuminance: number;
}

const colorCache = new Map<string, CachedColors>();

export function useArtworkPalette(
  game: GameItem | null,
  appearanceMode: ThemeAppearanceMode,
  adaptiveEnabled: boolean,
  borderPreset: UiKitBorderPreset = 'prism',
  hudThemeId: HudColorThemeId = 'auto',
  hudBackdropOpacity = 0
): AdaptivePalette {
  const sampleSrc = game ? (game.backgroundUrl || game.coverUrl) : '';
  const [extracted, setExtracted] = useState<CachedColors | null>(() => {
    if (!sampleSrc) return null;
    return colorCache.get(sampleSrc) ?? null;
  });

  useEffect(() => {
    if (!game || !sampleSrc) {
      setExtracted(null);
      return;
    }

    const cached = colorCache.get(sampleSrc);
    if (cached) {
      setExtracted(cached);
      return;
    }

    let cancelled = false;
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      if (cancelled) return;
      try {
        const canvas = document.createElement('canvas');
        const sampleSize = 48;
        canvas.width = sampleSize;
        canvas.height = sampleSize;
        const ctx = canvas.getContext('2d', { willReadFrequently: true });
        if (!ctx) return;

        const sr = !game.backgroundUrl || game.backgroundUrl === game.coverUrl ? game.sampleRegion : undefined;
        if (sr) {
          const sx = Math.round(img.naturalWidth * sr.x);
          const sy = Math.round(img.naturalHeight * sr.y);
          const sw = Math.max(1, Math.round(img.naturalWidth * sr.w));
          const sh = Math.max(1, Math.round(img.naturalHeight * sr.h));
          ctx.drawImage(img, sx, sy, sw, sh, 0, 0, sampleSize, sampleSize);
        } else {
          ctx.drawImage(img, 0, 0, sampleSize, sampleSize);
        }
        const rgba = ctx.getImageData(0, 0, sampleSize, sampleSize).data;
        const colors = extractPaletteFromPixels(rgba, sampleSize * sampleSize);
        colorCache.set(sampleSrc, colors);
        setExtracted(colors);
      } catch {
        // Fallback colors used automatically
      }
    };
    img.src = sampleSrc;

    return () => {
      cancelled = true;
    };
  }, [game, sampleSrc]);

  const dominant = extracted?.dominant ?? game?.fallbackDominant ?? { r: 34, g: 42, b: 56 };
  const accent = extracted?.accent ?? game?.fallbackAccent ?? { r: 16, g: 174, b: 190 };

  return buildAdaptiveTheme(
    dominant,
    accent,
    appearanceMode,
    extracted?.averageLuminance,
    adaptiveEnabled,
    borderPreset,
    hudThemeId,
    hudBackdropOpacity
  );
}
