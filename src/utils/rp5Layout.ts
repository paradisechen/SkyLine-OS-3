import type { SkylineConfig } from '../types/skyline';

export interface Switch2LayoutMetrics {
  viewportWidth: number;
  viewportHeight: number;
  vpxScale: number; // relative to 720p Pegasus baseline (1.5 on RP5 1080p)
  screenMargin: number;
  topBarTopMargin: number;
  topBarHeight: number;
  profileSize: number;
  statusPillHeight: number;
  statusPillPaddingX: number;
  statusFontSize: number;
  statusIconSize: number;
  cardSize: number;
  allSoftCardSize: number;
  cardRadius: number;
  cardGap: number; // horizontal gap between game covers (edge-to-edge)
  borderGap: number; // unobstructed gap between game art and selection border
  borderStroke: number; // bold outer selection border thickness
  borderInnerRadius: number; // concentric: cardRadius + borderGap
  borderOuterRadius: number; // concentric: cardRadius + borderGap + borderStroke
  gameTitleFontSize: number;
  gameTitleBottomOffset: number;
  dockHeight: number;
  dockPaddingX: number;
  dockButtonSize: number;
  dockIconSize: number;
  dockButtonGap: number;
  dockRingStroke: number;
  dockRingGap: number;
  dockLabelFontSize: number;
  helpBarHeight: number;
  helpFontSize: number;
  helpIconSize: number;
}

export const RETROID_POCKET_5_NATIVE = {
  width: 1920,
  height: 1080,
  aspectRatio: 16 / 9,
  screenInches: 5.5,
  panelType: 'AMOLED',
} as const;

export const DEFAULT_SKYLINE_CONFIG: SkylineConfig = {
  username: 'Mario',
  appearanceMode: 'dark',
  adaptiveColors: true,
  hudThemeId: 'auto',
  borderPreset: 'adaptive',
  uiSoundsEnabled: true,
  cardSizePct: 36,
  allSoftwareSizePct: 100,
  cardSpacingRatio: 0.125,
  borderGapPx720: 6,
  borderThicknessPx720: 6,
  dockHeightPct: 12.6,
  brightnessPct: 100,
  browserMode: 'in-app',
  albumFolderLabel: '/storage/emulated/0/Pictures/Screenshots',
  showBatteryPercent: true,
  showWifi: true,
  timeFormat: '12hr',
  enableBackgroundArt: true,
  backgroundDimPct: 70,
  backgroundBlurPct: 25,
  systemFontScalePct: 100,
  rp5FrameMode: 'fit-16-9',
};

/**
 * Computes exact pixel-scaled Switch 2 Home Screen proportions for a 16:9 viewport
 * (calibrated against the Retroid Pocket 5 1920x1080 display and Pegasus vpx = height / 720).
 */
export function computeSwitch2Layout(
  viewportWidth: number,
  viewportHeight: number,
  config: SkylineConfig = DEFAULT_SKYLINE_CONFIG
): Switch2LayoutMetrics {
  const safeW = Math.max(320, viewportWidth);
  const safeH = Math.max(240, viewportHeight);
  const vpxScale = safeH / 720;
  const vpx = (n: number) => Math.round(n * vpxScale);

  const cardSize = Math.round(safeH * (config.cardSizePct / 100));
  const allSoftCardSize = Math.round(cardSize * 0.78);
  const cardRadius = Math.max(10, Math.round(cardSize * 0.095));

  // Border geometry: concentric radii prevent corner pinching & ensure artwork never blocks border
  const borderGap = Math.max(4, vpx(config.borderGapPx720));
  const borderStroke = Math.max(4, vpx(config.borderThicknessPx720));
  const borderInnerRadius = cardRadius + borderGap;
  const borderOuterRadius = cardRadius + borderGap + borderStroke;

  // Card spacing must always exceed 2 * (borderGap + borderStroke) + 4px breathing room
  const minClearSpacing = (borderGap + borderStroke) * 2 + vpx(6);
  const cardGap = Math.max(minClearSpacing, Math.round(cardSize * config.cardSpacingRatio));

  // Enlarged Switch 2 bottom button bar (dock)
  const dockHeight = Math.round(safeH * (config.dockHeightPct / 100));
  const dockButtonSize = Math.round(dockHeight * 0.72);
  const dockIconSize = Math.round(dockButtonSize * 0.50);
  const dockButtonGap = Math.max(12, Math.round(dockButtonSize * 0.34));
  const dockPaddingX = Math.max(18, Math.round(dockHeight * 0.34));
  const dockRingGap = Math.max(3, vpx(4));
  const dockRingStroke = Math.max(3, vpx(4.5));
  const dockLabelFontSize = Math.max(11, Math.round(safeH * 0.025));

  const topBarTopMargin = Math.round(safeH * 0.042);
  const topBarHeight = Math.round(safeH * 0.235);
  const profileSize = Math.round(safeH * 0.082);
  const statusPillHeight = Math.round(safeH * 0.068);
  const statusPillPaddingX = Math.max(12, vpx(20));
  const statusIconSize = Math.max(16, Math.round(safeH * 0.038));
  const statusFontSize = Math.max(14, Math.round(statusIconSize * 0.96));

  const gameTitleFontSize = Math.max(14, Math.round(safeH * 0.036));
  const gameTitleBottomOffset = Math.max(10, Math.round(safeH * 0.026));

  const helpBarHeight = Math.round(safeH * 0.095);
  const helpFontSize = Math.max(11, Math.round(safeH * 0.024));
  const helpIconSize = Math.max(16, Math.round(safeH * 0.044));

  return {
    viewportWidth: safeW,
    viewportHeight: safeH,
    vpxScale,
    screenMargin: Math.max(20, Math.round(safeW * 0.042)),
    topBarTopMargin,
    topBarHeight,
    profileSize,
    statusPillHeight,
    statusPillPaddingX,
    statusFontSize,
    statusIconSize,
    cardSize,
    allSoftCardSize,
    cardRadius,
    cardGap,
    borderGap,
    borderStroke,
    borderInnerRadius,
    borderOuterRadius,
    gameTitleFontSize,
    gameTitleBottomOffset,
    dockHeight,
    dockPaddingX,
    dockButtonSize,
    dockIconSize,
    dockButtonGap,
    dockRingStroke,
    dockRingGap,
    dockLabelFontSize,
    helpBarHeight,
    helpFontSize,
    helpIconSize,
  };
}

/**
 * Fits a 16:9 Retroid Pocket 5 container inside any browser viewport without overflow.
 */
export function fit16By9Viewport(availWidth: number, availHeight: number): { width: number; height: number } {
  const targetRatio = 16 / 9;
  const currentRatio = availWidth / Math.max(1, availHeight);

  if (currentRatio > targetRatio) {
    const height = Math.floor(availHeight);
    const width = Math.floor(height * targetRatio);
    return { width, height };
  }
  const width = Math.floor(availWidth);
  const height = Math.floor(width / targetRatio);
  return { width, height };
}
