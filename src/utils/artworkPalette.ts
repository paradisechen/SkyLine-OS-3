import type {
  AdaptivePalette,
  HudColorThemeId,
  RgbColor,
  ThemeAppearanceMode,
  UiKitBorderPreset,
} from '../types/skyline';

/**
 * Exact iridescent border gradient presets sampled from Column 4 of UI_Kit_29e8735c.png
 */
export const UI_KIT_BORDER_PRESETS: Record<
  Exclude<UiKitBorderPreset, 'adaptive'>,
  { label: string; gradient: string; primaryHex: string; secondaryHex: string }
> = {
  prism: {
    label: 'UI Kit Prism',
    gradient:
      'linear-gradient(135deg, #6CF1FE 0%, #9B68FF 34%, #DDD6F0 52%, #FF69B9 76%, #716CFE 100%)',
    primaryHex: '#716CFE',
    secondaryHex: '#FF69B9',
  },
  aqua: {
    label: 'UI Kit Aqua',
    gradient:
      'linear-gradient(135deg, #67F2FF 0%, #9A67FF 42%, #D5DAF3 62%, #FC71BD 100%)',
    primaryHex: '#3ED8EE',
    secondaryHex: '#9A67FF',
  },
  violet: {
    label: 'UI Kit Violet',
    gradient:
      'linear-gradient(135deg, #6C67FF 0%, #67F2FF 38%, #D4D9F2 58%, #FC6FBC 84%, #9F70FE 100%)',
    primaryHex: '#6C67FF',
    secondaryHex: '#67F2FF',
  },
  magenta: {
    label: 'UI Kit Magenta',
    gradient:
      'linear-gradient(135deg, #FF67B8 0%, #6D68FF 42%, #DDD3EF 60%, #6FF2FE 100%)',
    primaryHex: '#FF67B8',
    secondaryHex: '#6D68FF',
  },
  frost: {
    label: 'UI Kit Frost',
    gradient:
      'linear-gradient(135deg, #9A68FF 0%, #FF68B8 38%, #DED4F0 56%, #6DF1FE 82%, #736EFE 100%)',
    primaryHex: '#9A68FF',
    secondaryHex: '#6DF1FE',
  },
};

/** 8 Circled Character & Nintendo HUD Theme Colors (4x2 grid in Settings -> HUD) */
export const HUD_THEME_SWATCHES: {
  id: HudColorThemeId;
  label: string;
  hex: string;
  rgb: RgbColor;
}[] = [
  { id: 'auto', label: 'Artwork Auto', hex: '#38BDF8', rgb: { r: 56, g: 189, b: 248 } },
  { id: 'mario', label: 'Mario Red', hex: '#E60012', rgb: { r: 230, g: 0, b: 18 } },
  { id: 'luigi', label: 'Luigi Green', hex: '#16A34A', rgb: { r: 22, g: 163, b: 74 } },
  { id: 'peach', label: 'Peach Rose', hex: '#EC4899', rgb: { r: 236, g: 72, b: 153 } },
  { id: 'yoshi', label: 'Yoshi Lime', hex: '#65A30D', rgb: { r: 101, g: 163, b: 13 } },
  { id: 'dk', label: 'DK Amber', hex: '#D97706', rgb: { r: 217, g: 119, b: 6 } },
  { id: 'bowser', label: 'Bowser Flame', hex: '#DC2626', rgb: { r: 220, g: 38, b: 38 } },
  { id: 'switchCyan', label: 'Switch Cyan', hex: '#0891B2', rgb: { r: 8, g: 145, b: 178 } },
];

function clampByte(v: number): number {
  return Math.max(0, Math.min(255, Math.round(v)));
}

export function rgbToHex(c: RgbColor): string {
  const toHex = (n: number) => clampByte(n).toString(16).padStart(2, '0');
  return `#${toHex(c.r)}${toHex(c.g)}${toHex(c.b)}`;
}

export function rgbToRgba(c: RgbColor, alpha: number): string {
  return `rgba(${clampByte(c.r)}, ${clampByte(c.g)}, ${clampByte(c.b)}, ${alpha.toFixed(3)})`;
}

export function mixRgb(a: RgbColor, b: RgbColor, t: number): RgbColor {
  const k = Math.max(0, Math.min(1, t));
  return {
    r: clampByte(a.r + (b.r - a.r) * k),
    g: clampByte(a.g + (b.g - a.g) * k),
    b: clampByte(a.b + (b.b - a.b) * k),
  };
}

export function rgbToHsl(c: RgbColor): { h: number; s: number; l: number } {
  const r = c.r / 255;
  const g = c.g / 255;
  const b = c.b / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  let h = 0;
  let s = 0;

  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r:
        h = (g - b) / d + (g < b ? 6 : 0);
        break;
      case g:
        h = (b - r) / d + 2;
        break;
      case b:
        h = (r - g) / d + 4;
        break;
    }
    h /= 6;
  }

  return { h, s, l };
}

export function hslToRgb(h: number, s: number, l: number): RgbColor {
  const hue2rgb = (p: number, q: number, t: number) => {
    let tt = t;
    if (tt < 0) tt += 1;
    if (tt > 1) tt -= 1;
    if (tt < 1 / 6) return p + (q - p) * 6 * tt;
    if (tt < 1 / 2) return q;
    if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
    return p;
  };

  if (s === 0) {
    const v = clampByte(l * 255);
    return { r: v, g: v, b: v };
  }

  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  return {
    r: clampByte(hue2rgb(p, q, h + 1 / 3) * 255),
    g: clampByte(hue2rgb(p, q, h) * 255),
    b: clampByte(hue2rgb(p, q, h - 1 / 3) * 255),
  };
}

export function relativeLuminance(c: RgbColor): number {
  const linear = (channel: number) => {
    const s = channel / 255;
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  };
  return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b);
}

export function contrastRatio(a: RgbColor, b: RgbColor): number {
  const l1 = relativeLuminance(a);
  const l2 = relativeLuminance(b);
  const hi = Math.max(l1, l2);
  const lo = Math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

export function ensureContrast(fg: RgbColor, background: RgbColor, minRatio = 4.8): RgbColor {
  if (contrastRatio(fg, background) >= minRatio) {
    return fg;
  }

  const bgLum = relativeLuminance(background);
  const hsl = rgbToHsl(fg);
  const shouldLighten = bgLum < 0.35;

  let lo = shouldLighten ? hsl.l : 0.04;
  let hi = shouldLighten ? 0.98 : hsl.l;
  let best = shouldLighten ? { r: 248, g: 250, b: 252 } : { r: 18, g: 20, b: 24 };

  for (let i = 0; i < 18; i++) {
    const mid = (lo + hi) / 2;
    const candidate = hslToRgb(hsl.h, Math.min(hsl.s, 0.88), mid);
    const ratio = contrastRatio(candidate, background);
    if (ratio >= minRatio) {
      best = candidate;
      if (shouldLighten) hi = mid;
      else lo = mid;
    } else {
      if (shouldLighten) lo = mid;
      else hi = mid;
    }
  }

  if (contrastRatio(best, background) < minRatio) {
    return shouldLighten ? { r: 248, g: 250, b: 252 } : { r: 18, g: 20, b: 24 };
  }

  return best;
}

export interface ExtractedColors {
  dominant: RgbColor;
  accent: RgbColor;
  averageLuminance: number;
}

export function extractPaletteFromPixels(
  data: Uint8ClampedArray | number[],
  pixelCount?: number
): ExtractedColors {
  const totalPixels = pixelCount ?? Math.floor(data.length / 4);
  if (totalPixels <= 0) {
    return {
      dominant: { r: 34, g: 42, b: 56 },
      accent: { r: 16, g: 174, b: 190 },
      averageLuminance: 0.25,
    };
  }

  const bucketCounts = new Map<
    number,
    { count: number; rSum: number; gSum: number; bSum: number; satScore: number }
  >();
  let lumSum = 0;
  let validCount = 0;

  const step = Math.max(1, Math.floor(totalPixels / 2500));
  for (let idx = 0; idx < totalPixels; idx += step) {
    const offset = idx * 4;
    const r = data[offset];
    const g = data[offset + 1];
    const b = data[offset + 2];
    const a = data[offset + 3];
    if (a !== undefined && a < 128) continue;

    validCount++;
    const rgb = { r, g, b };
    lumSum += relativeLuminance(rgb);

    const key = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4);
    const { s, l } = rgbToHsl(rgb);
    const vibrancy = s * (1 - Math.abs(l - 0.52) * 1.4);

    const existing = bucketCounts.get(key);
    if (existing) {
      existing.count++;
      existing.rSum += r;
      existing.gSum += g;
      existing.bSum += b;
      existing.satScore += Math.max(0, vibrancy);
    } else {
      bucketCounts.set(key, {
        count: 1,
        rSum: r,
        gSum: g,
        bSum: b,
        satScore: Math.max(0, vibrancy),
      });
    }
  }

  if (validCount === 0 || bucketCounts.size === 0) {
    return {
      dominant: { r: 34, g: 42, b: 56 },
      accent: { r: 16, g: 174, b: 190 },
      averageLuminance: 0.25,
    };
  }

  let bestDominant = { r: 40, g: 46, b: 60 };
  let bestDomScore = -1;
  let bestAccent = { r: 16, g: 174, b: 190 };
  let bestAccentScore = -1;

  for (const bucket of bucketCounts.values()) {
    const avgRgb: RgbColor = {
      r: bucket.rSum / bucket.count,
      g: bucket.gSum / bucket.count,
      b: bucket.bSum / bucket.count,
    };
    const { s, l } = rgbToHsl(avgRgb);

    const midtoneWeight = l > 0.08 && l < 0.92 ? 1.25 : 0.65;
    const domScore = bucket.count * midtoneWeight * (1 + s * 0.45);
    if (domScore > bestDomScore) {
      bestDomScore = domScore;
      bestDominant = {
        r: clampByte(avgRgb.r),
        g: clampByte(avgRgb.g),
        b: clampByte(avgRgb.b),
      };
    }

    const presenceWeight = Math.min(1, bucket.count / Math.max(4, validCount * 0.015));
    const accentScore =
      (s * 2.4 + 0.1) * (1 - Math.abs(l - 0.54) * 1.1) * (0.4 + 0.6 * presenceWeight);
    if (accentScore > bestAccentScore) {
      bestAccentScore = accentScore;
      bestAccent = {
        r: clampByte(avgRgb.r),
        g: clampByte(avgRgb.g),
        b: clampByte(avgRgb.b),
      };
    }
  }

  return {
    dominant: bestDominant,
    accent: bestAccent,
    averageLuminance: lumSum / validCount,
  };
}

export interface AdaptiveHudColors {
  text: RgbColor;
  icon: RgbColor;
}

/**
 * Derives high-contrast top HUD text & icon colors (nickname, time, battery, Wi-Fi)
 * directly from the album/game artwork primary color and the effective backdrop behind the bar.
 * - White / bright neutral background -> crisp black (#111827)
 * - Light saturated background (e.g. light blue) -> deep darkened same hue (e.g. dark blue)
 * - Dark background -> crisp white or bright pastel tint of the artwork primary color
 */
export function deriveAdaptiveHudTextColor(
  artworkPrimary: RgbColor,
  effectiveBackdropBg: RgbColor
): AdaptiveHudColors {
  const bgLum = relativeLuminance(effectiveBackdropBg);
  const pHsl = rgbToHsl(artworkPrimary);
  const isLightBackdrop = bgLum >= 0.25;
  const isNeutralPrimary = pHsl.s < 0.2;

  if (isLightBackdrop) {
    if (isNeutralPrimary) {
      const darkInk = ensureContrast({ r: 17, g: 24, b: 39 }, effectiveBackdropBg, 5.5);
      return { text: darkInk, icon: darkInk };
    }
    const baseDarkHue = hslToRgb(
      pHsl.h,
      Math.min(0.94, Math.max(0.72, pHsl.s)),
      0.18
    );
    const text = ensureContrast(baseDarkHue, effectiveBackdropBg, 5.4);
    const icon = ensureContrast(
      hslToRgb(pHsl.h, Math.min(0.94, Math.max(0.72, pHsl.s)), 0.20),
      effectiveBackdropBg,
      5.2
    );
    return { text, icon };
  }

  if (isNeutralPrimary) {
    const brightWhite = ensureContrast({ r: 248, g: 250, b: 252 }, effectiveBackdropBg, 6.0);
    return { text: brightWhite, icon: brightWhite };
  }

  const baseBrightTint = hslToRgb(
    pHsl.h,
    Math.min(0.86, Math.max(0.42, pHsl.s * 0.85)),
    0.85
  );
  const text = ensureContrast(baseBrightTint, effectiveBackdropBg, 5.8);
  const icon = ensureContrast(
    hslToRgb(pHsl.h, Math.min(0.88, Math.max(0.46, pHsl.s * 0.9)), 0.82),
    effectiveBackdropBg,
    5.5
  );
  return { text, icon };
}

/**
 * Contrast-verified NS2 AdaptivePalette:
 * - Light artwork/mode: darker rich tone of the artwork color for all UI text & icons
 * - Dark artwork/mode: NS2 flat dark grey background with bright vivid artwork or crisp white text
 * - Steady non-rainbow UI-matched dock focus ring
 */
export function buildAdaptiveTheme(
  dominant: RgbColor,
  accent: RgbColor,
  mode: ThemeAppearanceMode = 'auto',
  artworkLuminance?: number,
  adaptiveEnabled = true,
  borderPreset: UiKitBorderPreset = 'prism',
  hudThemeId: HudColorThemeId = 'auto',
  hudBackdropOpacity = 0
): AdaptivePalette {
  const hudSwatch =
    hudThemeId !== 'auto' ? HUD_THEME_SWATCHES.find((s) => s.id === hudThemeId) : undefined;
  const effectiveAccent = hudSwatch ? hudSwatch.rgb : accent;
  const effectiveDominant = hudSwatch ? mixRgb(dominant, hudSwatch.rgb, 0.45) : dominant;
  const chosenPreset = borderPreset !== 'adaptive' ? UI_KIT_BORDER_PRESETS[borderPreset] : null;
  const clampedArtMix = Math.max(0, Math.min(1, hudBackdropOpacity));

  if (!adaptiveEnabled) {
    const dark = mode === 'dark';
    const baseHueRgb = hudSwatch ? hudSwatch.rgb : { r: 29, g: 155, b: 243 };
    const accentHex = rgbToHex(baseHueRgb);
    const baseCanvas = dark ? { r: 22, g: 23, b: 27 } : { r: 235, g: 235, b: 235 };
    const effectiveHudBg = mixRgb(baseCanvas, dominant, clampedArtMix);
    const hudFg = deriveAdaptiveHudTextColor(dominant, effectiveHudBg);
    return dark
      ? {
          isDark: true,
          dominantHex: rgbToHex(dominant),
          accentHex,
          accentGlowHex: '#93D5FF',
          iridescentGradient: chosenPreset?.gradient ?? UI_KIT_BORDER_PRESETS.prism.gradient,
          canvasBg: '#16171B',
          backdropWash: 'rgba(255, 255, 255, 0.04)',
          gameTitleColor: '#F3F4F6',
          topBarText: clampedArtMix > 0 ? rgbToHex(hudFg.text) : '#F8FAFC',
          topBarIcon: clampedArtMix > 0 ? rgbToHex(hudFg.icon) : '#E2E8F0',
          statusPillBg: '#25272D',
          borderPrimary: accentHex,
          borderPulse: '#93D5FF',
          cardSurface: '#2A2C33',
          dockBg: '#25272D',
          dockIcon: '#CBD5E1',
          dockActiveCircle: '#1D1F25',
          dockActiveIcon: accentHex,
          dockRingColor: accentHex,
          dockLabel: '#F1F5F9',
          helpBarText: '#F1F5F9',
          helpBarIcon: '#E2E8F0',
          favoriteHeartBg: accentHex,
          favoriteHeartIcon: '#FFFFFF',
          overlaySheetBg: '#22242A',
          overlayCardBg: '#2D3038',
          overlayDivider: 'rgba(255, 255, 255, 0.14)',
          overlayText: '#F1F5F9',
          overlayMuted: '#9CA3AF',
        }
      : {
          isDark: false,
          dominantHex: rgbToHex(dominant),
          accentHex,
          accentGlowHex: '#3FE0F0',
          iridescentGradient: chosenPreset?.gradient ?? UI_KIT_BORDER_PRESETS.prism.gradient,
          canvasBg: '#EBEBEB',
          backdropWash: 'rgba(16, 174, 190, 0.08)',
          gameTitleColor: '#1E3A8A',
          topBarText: clampedArtMix > 0 ? rgbToHex(hudFg.text) : '#1F2329',
          topBarIcon: clampedArtMix > 0 ? rgbToHex(hudFg.icon) : '#1F2329',
          statusPillBg: '#FFFFFF',
          borderPrimary: accentHex,
          borderPulse: '#6CF2FF',
          cardSurface: '#FFFFFF',
          dockBg: '#FFFFFF',
          dockIcon: '#5C626E',
          dockActiveCircle: '#FFFFFF',
          dockActiveIcon: accentHex,
          dockRingColor: accentHex,
          dockLabel: '#1E3A8A',
          helpBarText: '#1F2329',
          helpBarIcon: '#1F2329',
          favoriteHeartBg: accentHex,
          favoriteHeartIcon: '#FFFFFF',
          overlaySheetBg: '#EDEDED',
          overlayCardBg: '#FFFFFF',
          overlayDivider: '#BDBDBD',
          overlayText: '#2C2C2C',
          overlayMuted: '#666666',
        };
  }

  const domLum = artworkLuminance ?? relativeLuminance(effectiveDominant);
  const isDark = mode === 'dark' ? true : mode === 'light' ? false : domLum < 0.42;

  const domHsl = rgbToHsl(effectiveDominant);
  const accHsl = rgbToHsl(effectiveAccent);

  // If artwork is nearly black/monochrome neutral in dark mode, make UI crisp bright white/vivid sky
  const isAchromatic = accHsl.s < 0.14 && domHsl.s < 0.14;
  const activeHue = isAchromatic ? 0.54 : accHsl.h;
  const activeSat = isAchromatic ? 0.65 : Math.max(0.55, Math.min(0.92, accHsl.s * 1.1));

  // Light mode canvas: softly tinted by artwork; Dark mode canvas: deep flat NS2 charcoal grey/black
  const canvasRgb = isDark
    ? hslToRgb(domHsl.h, Math.min(0.24, domHsl.s * 0.48), 0.085)
    : hslToRgb(domHsl.h, Math.min(0.30, domHsl.s * 0.55), 0.90);

  // Solid opaque surfaces (no border, NS2 flat style)
  const pillRgb = isDark
    ? mixRgb(canvasRgb, { r: 39, g: 41, b: 48 }, 0.78)
    : mixRgb(canvasRgb, { r: 255, g: 255, b: 255 }, 0.84);

  const dockRgb = isDark
    ? mixRgb(canvasRgb, { r: 37, g: 39, b: 46 }, 0.82)
    : mixRgb(canvasRgb, { r: 255, g: 255, b: 255 }, 0.90);

  // Light mode: noticeably DARKER shade of the artwork color (e.g. red art -> deep dark crimson)
  // Dark mode: BRIGHT vivid artwork-tinted color or crisp white for maximum readability
  const darkenedUiFg = hslToRgb(activeHue, Math.max(0.58, activeSat), 0.24);
  const vividDarkModeFg = isAchromatic
    ? { r: 245, g: 247, b: 250 }
    : hslToRgb(activeHue, Math.min(0.88, Math.max(0.45, activeSat)), 0.78);

  const gameTitleRgb = ensureContrast(
    isDark ? vividDarkModeFg : darkenedUiFg,
    canvasRgb,
    5.0
  );

  const effectiveHudBg = mixRgb(canvasRgb, dominant, clampedArtMix);
  const hudFg = deriveAdaptiveHudTextColor(effectiveDominant, effectiveHudBg);
  const topBarTextRgb = hudFg.text;
  const topBarIconRgb = hudFg.icon;

  const helpBarTextRgb = ensureContrast(
    isDark
      ? mixRgb({ r: 242, g: 245, b: 250 }, vividDarkModeFg, 0.32)
      : hslToRgb(activeHue, Math.min(0.70, activeSat * 0.88), 0.22),
    canvasRgb,
    5.2
  );

  const helpBarIconRgb = ensureContrast(
    isDark
      ? mixRgb({ r: 235, g: 240, b: 248 }, vividDarkModeFg, 0.42)
      : hslToRgb(activeHue, Math.min(0.78, activeSat), 0.26),
    canvasRgb,
    5.0
  );

  const dockIconRgb = ensureContrast(
    isDark ? { r: 214, g: 222, b: 234 } : hslToRgb(activeHue, 0.22, 0.34),
    dockRgb,
    4.5
  );

  const dockActiveCircleRgb = isDark
    ? mixRgb(dockRgb, { r: 58, g: 62, b: 74 }, 0.65)
    : { r: 255, g: 255, b: 255 };

  const dockActiveIconRgb = ensureContrast(
    isDark ? vividDarkModeFg : darkenedUiFg,
    dockActiveCircleRgb,
    4.0
  );

  // Non-rainbow UI-matched dock ring
  const dockRingRgb = ensureContrast(
    isDark
      ? hslToRgb(activeHue, Math.max(0.55, activeSat), 0.66)
      : hslToRgb(activeHue, Math.max(0.65, activeSat), 0.36),
    dockRgb,
    3.2
  );

  const dockLabelRgb = ensureContrast(
    isDark ? vividDarkModeFg : darkenedUiFg,
    canvasRgb,
    4.8
  );

  const borderPrimaryRgb = ensureContrast(
    isDark
      ? hslToRgb(activeHue, Math.max(0.58, activeSat), 0.62)
      : hslToRgb(activeHue, Math.max(0.66, activeSat), 0.36),
    canvasRgb,
    3.2
  );
  const borderPulseRgb = mixRgb(borderPrimaryRgb, { r: 255, g: 255, b: 255 }, isDark ? 0.4 : 0.5);

  const favHeartBgRgb = ensureContrast(
    isDark
      ? hslToRgb(activeHue, Math.max(0.62, activeSat), 0.54)
      : hslToRgb(activeHue, Math.max(0.68, activeSat), 0.34),
    { r: 255, g: 255, b: 255 },
    3.2
  );

  const overlaySheetRgb = isDark
    ? mixRgb(canvasRgb, { r: 34, g: 37, b: 44 }, 0.85)
    : mixRgb(canvasRgb, { r: 238, g: 238, b: 240 }, 0.86);
  const overlayCardRgb = isDark
    ? mixRgb(overlaySheetRgb, { r: 52, g: 56, b: 66 }, 0.85)
    : { r: 255, g: 255, b: 255 };
  const overlayTextRgb = ensureContrast(
    isDark ? { r: 246, g: 248, b: 252 } : { r: 32, g: 36, b: 42 },
    overlaySheetRgb,
    7.0
  );
  const overlayMutedRgb = ensureContrast(
    isDark ? { r: 170, g: 180, b: 196 } : { r: 90, g: 96, b: 106 },
    overlaySheetRgb,
    4.5
  );

  const stop2 = hslToRgb((activeHue + 0.16) % 1, 0.84, isDark ? 0.68 : 0.58);
  const stop3 = hslToRgb((activeHue + 0.58) % 1, 0.82, isDark ? 0.7 : 0.6);

  return {
    isDark,
    dominantHex: rgbToHex(effectiveDominant),
    accentHex: rgbToHex(dockRingRgb),
    accentGlowHex: rgbToHex(borderPulseRgb),
    iridescentGradient:
      chosenPreset?.gradient ??
      `linear-gradient(135deg, ${rgbToHex(borderPrimaryRgb)} 0%, ${rgbToHex(stop2)} 40%, ${rgbToHex(stop3)} 75%, ${rgbToHex(borderPulseRgb)} 100%)`,
    canvasBg: rgbToHex(canvasRgb),
    backdropWash: rgbToRgba(effectiveAccent, isDark ? 0.24 : 0.16),
    gameTitleColor: rgbToHex(gameTitleRgb),
    topBarText: rgbToHex(topBarTextRgb),
    topBarIcon: rgbToHex(topBarIconRgb),
    statusPillBg: rgbToHex(pillRgb),
    borderPrimary: rgbToHex(borderPrimaryRgb),
    borderPulse: rgbToHex(borderPulseRgb),
    cardSurface: isDark ? '#26282F' : '#FFFFFF',
    dockBg: rgbToHex(dockRgb),
    dockIcon: rgbToHex(dockIconRgb),
    dockActiveCircle: rgbToHex(dockActiveCircleRgb),
    dockActiveIcon: rgbToHex(dockActiveIconRgb),
    dockRingColor: rgbToHex(dockRingRgb),
    dockLabel: rgbToHex(dockLabelRgb),
    helpBarText: rgbToHex(helpBarTextRgb),
    helpBarIcon: rgbToHex(helpBarIconRgb),
    favoriteHeartBg: rgbToHex(favHeartBgRgb),
    favoriteHeartIcon: '#FFFFFF',
    overlaySheetBg: rgbToHex(overlaySheetRgb),
    overlayCardBg: rgbToHex(overlayCardRgb),
    overlayDivider: isDark ? 'rgba(255, 255, 255, 0.15)' : 'rgba(0, 0, 0, 0.20)',
    overlayText: rgbToHex(overlayTextRgb),
    overlayMuted: rgbToHex(overlayMutedRgb),
  };
}
