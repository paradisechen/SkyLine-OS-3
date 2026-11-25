import type { HudColorThemeId, SkylineConfig, ThemeAppearanceMode } from '../types/skyline';
import { HUD_THEME_SWATCHES } from './artworkPalette';
import { DEFAULT_SKYLINE_CONFIG } from './rp5Layout';

function clampNum(val: unknown, min: number, max: number, fallback: number): number {
  const n = Number(val);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(min, Math.min(max, n));
}

function parseBool(val: unknown, fallback: boolean): boolean {
  if (typeof val === 'boolean') return val;
  if (typeof val === 'string') {
    if (val === '1' || val.toLowerCase() === 'true' || val.toLowerCase() === 'yes') return true;
    if (val === '0' || val.toLowerCase() === 'false' || val.toLowerCase() === 'no') return false;
  }
  return fallback;
}

export function parseSkylineConfigFromQuery(query: Record<string, unknown>): SkylineConfig {
  const rawMode = String(query.appearanceMode ?? DEFAULT_SKYLINE_CONFIG.appearanceMode);
  const appearanceMode: ThemeAppearanceMode =
    rawMode === 'light' || rawMode === 'dark' || rawMode === 'auto'
      ? rawMode
      : DEFAULT_SKYLINE_CONFIG.appearanceMode;

  const rawHud = String(query.hudThemeId ?? DEFAULT_SKYLINE_CONFIG.hudThemeId);
  const hudThemeId: HudColorThemeId = HUD_THEME_SWATCHES.some((s) => s.id === rawHud)
    ? (rawHud as HudColorThemeId)
    : DEFAULT_SKYLINE_CONFIG.hudThemeId;

  const rawTime = String(query.timeFormat ?? DEFAULT_SKYLINE_CONFIG.timeFormat);
  const timeFormat: '12hr' | '24hr' = rawTime === '24hr' ? '24hr' : '12hr';
  const rawBrowser = String(query.browserMode ?? DEFAULT_SKYLINE_CONFIG.browserMode);
  const browserMode: 'in-app' | 'chrome' = rawBrowser === 'chrome' ? 'chrome' : 'in-app';

  const rawUser = String(query.username ?? DEFAULT_SKYLINE_CONFIG.username)
    .replace(/["\\\r\n]/g, '')
    .trim()
    .slice(0, 24);

  return {
    ...DEFAULT_SKYLINE_CONFIG,
    username: rawUser || DEFAULT_SKYLINE_CONFIG.username,
    appearanceMode,
    hudThemeId,
    cardSizePct: Math.round(clampNum(query.cardSizePct, 25, 45, DEFAULT_SKYLINE_CONFIG.cardSizePct)),
    allSoftwareSizePct: Math.round(
      clampNum(query.allSoftwareSizePct, 75, 130, DEFAULT_SKYLINE_CONFIG.allSoftwareSizePct)
    ),
    cardSpacingRatio: clampNum(
      query.cardSpacingRatio,
      0.05,
      0.25,
      DEFAULT_SKYLINE_CONFIG.cardSpacingRatio
    ),
    borderGapPx720: Math.round(
      clampNum(query.borderGapPx720, 4, 15, DEFAULT_SKYLINE_CONFIG.borderGapPx720)
    ),
    borderThicknessPx720: Math.round(
      clampNum(query.borderThicknessPx720, 4, 15, DEFAULT_SKYLINE_CONFIG.borderThicknessPx720)
    ),
    dockHeightPct: clampNum(query.dockHeightPct, 9, 20, DEFAULT_SKYLINE_CONFIG.dockHeightPct),
    enableBackgroundArt: parseBool(
      query.enableBackgroundArt,
      DEFAULT_SKYLINE_CONFIG.enableBackgroundArt
    ),
    backgroundDimPct: Math.round(
      clampNum(query.backgroundDimPct, 0, 100, DEFAULT_SKYLINE_CONFIG.backgroundDimPct)
    ),
    backgroundBlurPct: Math.round(
      clampNum(query.backgroundBlurPct, 0, 100, DEFAULT_SKYLINE_CONFIG.backgroundBlurPct)
    ),
    showBatteryPercent: parseBool(
      query.showBatteryPercent,
      DEFAULT_SKYLINE_CONFIG.showBatteryPercent
    ),
    showWifi: parseBool(query.showWifi, DEFAULT_SKYLINE_CONFIG.showWifi),
    timeFormat,
    browserMode,
    albumFolderLabel:
      typeof query.albumFolderLabel === 'string' && query.albumFolderLabel.trim()
        ? query.albumFolderLabel.replace(/["\\\r\n]/g, '').trim().slice(0, 180)
        : DEFAULT_SKYLINE_CONFIG.albumFolderLabel,
    systemFontScalePct: Math.round(
      clampNum(query.systemFontScalePct, 85, 135, DEFAULT_SKYLINE_CONFIG.systemFontScalePct)
    ),
    uiSoundsEnabled: parseBool(query.uiSoundsEnabled, DEFAULT_SKYLINE_CONFIG.uiSoundsEnabled),
  };
}

export function buildSkylineConfigQueryString(config: SkylineConfig): string {
  const params = new URLSearchParams({
    username: config.username,
    appearanceMode: config.appearanceMode,
    hudThemeId: config.hudThemeId,
    cardSizePct: String(config.cardSizePct),
    allSoftwareSizePct: String(config.allSoftwareSizePct),
    cardSpacingRatio: config.cardSpacingRatio.toFixed(3),
    borderGapPx720: String(config.borderGapPx720),
    borderThicknessPx720: String(config.borderThicknessPx720),
    dockHeightPct: config.dockHeightPct.toFixed(1),
    enableBackgroundArt: config.enableBackgroundArt ? '1' : '0',
    backgroundDimPct: String(config.backgroundDimPct),
    backgroundBlurPct: String(config.backgroundBlurPct ?? DEFAULT_SKYLINE_CONFIG.backgroundBlurPct),
    showBatteryPercent: config.showBatteryPercent ? '1' : '0',
    showWifi: config.showWifi ? '1' : '0',
    timeFormat: config.timeFormat,
    browserMode: config.browserMode,
    albumFolderLabel: config.albumFolderLabel,
    systemFontScalePct: String(config.systemFontScalePct ?? 100),
    uiSoundsEnabled: config.uiSoundsEnabled ? '1' : '0',
  });
  return params.toString();
}
