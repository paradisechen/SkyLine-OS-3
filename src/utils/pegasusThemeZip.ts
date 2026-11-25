import fs from 'node:fs/promises';
import JSZip from 'jszip';
import type { SkylineConfig } from '../types/skyline.ts';
import { HUD_THEME_SWATCHES } from './artworkPalette.ts';
import { generatePatchedQmlFiles } from './qmlGenerator.ts';
import { DEFAULT_SKYLINE_CONFIG } from './rp5Layout.ts';
export {
  buildSkylineConfigQueryString,
  parseSkylineConfigFromQuery,
} from './skylineConfigQuery.ts';

function clampNum(val: unknown, min: number, max: number, fallback: number): number {
  const n = Number(val);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(min, Math.min(max, n));
}

export async function buildCalibratedPegasusThemeZip(
  zipPath: string,
  partialConfig?: Partial<SkylineConfig>
): Promise<Buffer> {
  const rawZip = await fs.readFile(zipPath);
  const zip = await JSZip.loadAsync(rawZip);

  const config: SkylineConfig = {
    ...DEFAULT_SKYLINE_CONFIG,
    ...partialConfig,
  };

  const cardPct = Math.round(clampNum(config.cardSizePct, 25, 45, DEFAULT_SKYLINE_CONFIG.cardSizePct));
  const borderGap720 = Math.round(
    clampNum(config.borderGapPx720, 4, 15, DEFAULT_SKYLINE_CONFIG.borderGapPx720)
  );
  const borderThick720 = Math.round(
    clampNum(config.borderThicknessPx720, 4, 15, DEFAULT_SKYLINE_CONFIG.borderThicknessPx720)
  );
  const spacingRatio = clampNum(
    config.cardSpacingRatio,
    0.05,
    0.25,
    DEFAULT_SKYLINE_CONFIG.cardSpacingRatio
  ).toFixed(3);
  const dockPct = clampNum(config.dockHeightPct, 9, 20, DEFAULT_SKYLINE_CONFIG.dockHeightPct);
  const dockHeightRatio = (dockPct / 100).toFixed(4);
  const buttonSize720 = Math.round(720 * (dockPct / 100) * 0.72);
  const iconSize720 = Math.round(buttonSize720 * 0.5);
  const buttonGap720 = Math.max(16, Math.round(buttonSize720 * 0.34));
  const dockPad720 = Math.max(24, Math.round(720 * (dockPct / 100) * 0.34));

  const defaultDarkMode = config.appearanceMode === 'dark' ? 'Yes' : 'No';
  const defaultPolarity =
    config.appearanceMode === 'dark' ? 'Dark' : config.appearanceMode === 'light' ? 'Light' : 'Auto';
  const hudLabelMap: Record<string, string> = {
    auto: 'Auto',
    mario: 'Mario Red',
    luigi: 'Luigi Green',
    peach: 'Peach Pink',
    yoshi: 'Yoshi Green',
    dk: 'DK Amber',
    bowser: 'Bowser Gold',
    switchCyan: 'Switch Cyan',
  };
  const defaultHudLabel = hudLabelMap[config.hudThemeId] ?? 'Auto';
  const defaultUiSounds = config.uiSoundsEnabled ? 'Yes' : 'No';
  const defaultBrowserMode = config.browserMode === 'chrome' ? 'chrome' : 'in-app';
  const defaultBattery = config.showBatteryPercent ? 'Yes' : 'No';
  const defaultWifi = config.showWifi ? 'Yes' : 'No';
  const defaultGameBg = config.enableBackgroundArt ? 'Screenshot' : 'None';
  const defaultBgTrans = String(
    Math.round(clampNum(config.backgroundDimPct, 0, 100, DEFAULT_SKYLINE_CONFIG.backgroundDimPct))
  );
  const defaultBgBlur = Math.round(
    clampNum(config.backgroundBlurPct, 0, 100, DEFAULT_SKYLINE_CONFIG.backgroundBlurPct)
  );
  const safeUser = (config.username || '').replace(/["\\\r\n]/g, '').trim();
  const hudSwatch =
    config.hudThemeId !== 'auto'
      ? HUD_THEME_SWATCHES.find((s) => s.id === config.hudThemeId)
      : undefined;

  // 1. Calibrate skylineOS2/theme.qml defaults cleanly
  const themeEntry = zip.file('skylineOS2/theme.qml');
  if (themeEntry) {
    let themeQml = await themeEntry.async('string');
    themeQml = themeQml
      .replace(
        /api\.memory\.has\("Game Background"\) \? api\.memory\.get\("Game Background"\) : "Screenshot"/g,
        `api.memory.has("Game Background") ? api.memory.get("Game Background") : "${defaultGameBg}"`
      )
      .replace(
        /api\.memory\.has\("Time Format"\) \? api\.memory\.get\("Time Format"\) : "12hr"/g,
        `api.memory.has("Time Format") ? api.memory.get("Time Format") : "${config.timeFormat}"`
      )
      .replace(
        /api\.memory\.has\("Display Battery Percentage"\) \? api\.memory\.get\("Display Battery Percentage"\) : "No"/g,
        `api.memory.has("Display Battery Percentage") ? api.memory.get("Display Battery Percentage") : "${defaultBattery}"`
      )
      .replace(
        /api\.memory\.has\("Display Wifi Icon"\) \? api\.memory\.get\("Display Wifi Icon"\) : "(Yes|No)"/g,
        `api.memory.has("Display Wifi Icon") ? api.memory.get("Display Wifi Icon") : "${defaultWifi}"`
      )
      .replace(
        /api\.memory\.has\("Username"\) \? api\.memory\.get\("Username"\) : ""/g,
        `api.memory.has("Username") ? api.memory.get("Username") : "${safeUser}"`
      )
      .replace(
        /api\.memory\.has\("Dark Mode"\) \? api\.memory\.get\("Dark Mode"\) : "(?:Yes|No)"/g,
        `api.memory.has("Dark Mode") ? api.memory.get("Dark Mode") : "${defaultDarkMode}"`
      )
      .replace(
        /api\.memory\.has\("Home Card Size"\) \? api\.memory\.get\("Home Card Size"\) : "35"/g,
        `api.memory.has("Home Card Size") ? api.memory.get("Home Card Size") : "${cardPct}"`
      )
      .replace(
        /api\.memory\.has\("Background Transparency"\) \? api\.memory\.get\("Background Transparency"\) : "\d+"/g,
        `api.memory.has("Background Transparency") ? api.memory.get("Background Transparency") : "${defaultBgTrans}"`
      )
      .replace(
        /api\.memory\.has\("Background Blur"\) \? parseInt\(api\.memory\.get\("Background Blur"\)\) : \d+/g,
        `api.memory.has("Background Blur") ? parseInt(api.memory.get("Background Blur")) : ${defaultBgBlur}`
      )
      .replace(
        /api\.memory\.has\("UI Sounds"\) \? api\.memory\.get\("UI Sounds"\) : "Yes"/g,
        `api.memory.has("UI Sounds") ? api.memory.get("UI Sounds") : "${defaultUiSounds}"`
      )
      .replace(
        /api\.memory\.has\("Appearance Polarity"\) \? api\.memory\.get\("Appearance Polarity"\) : "(?:Auto|Dark|Light)"/g,
        `api.memory.has("Appearance Polarity") ? api.memory.get("Appearance Polarity") : "${defaultPolarity}"`
      )
      .replace(
        /api\.memory\.has\("HUD Theme Accent"\) \? api\.memory\.get\("HUD Theme Accent"\) : "Auto"/g,
        `api.memory.has("HUD Theme Accent") ? api.memory.get("HUD Theme Accent") : "${defaultHudLabel}"`
      )
      .replace(
        /api\.memory\.has\("Browser Mode"\) \? api\.memory\.get\("Browser Mode"\) : "in-app"/g,
        `api.memory.has("Browser Mode") ? api.memory.get("Browser Mode") : "${defaultBrowserMode}"`
      )
      .replace(
        /api\.memory\.has\("Border Gap"\) \? parseInt\(api\.memory\.get\("Border Gap"\)\) : 7/g,
        `api.memory.has("Border Gap") ? parseInt(api.memory.get("Border Gap")) : ${borderGap720}`
      )
      .replace(
        /api\.memory\.has\("Border Width"\) \? parseInt\(api\.memory\.get\("Border Width"\)\) : 6/g,
        `api.memory.has("Border Width") ? parseInt(api.memory.get("Border Width")) : ${borderThick720}`
      )
      .replace(
        /api\.memory\.has\("Cover Spacing"\) \? parseFloat\(api\.memory\.get\("Cover Spacing"\)\) : 0\.140/g,
        `api.memory.has("Cover Spacing") ? parseFloat(api.memory.get("Cover Spacing")) : ${spacingRatio}`
      )
      .replace(
        /api\.memory\.has\("Dock Size Pct"\) \? parseFloat\(api\.memory\.get\("Dock Size Pct"\)\) : 13\.3/g,
        `api.memory.has("Dock Size Pct") ? parseFloat(api.memory.get("Dock Size Pct")) : ${dockPct.toFixed(1)}`
      )
      .replace(
        /api\.memory\.has\("System Font Scale"\) \? parseInt\(api\.memory\.get\("System Font Scale"\)\) : 100/g,
        `api.memory.has("System Font Scale") ? parseInt(api.memory.get("System Font Scale")) : ${Math.round(clampNum(config.systemFontScalePct, 85, 135, 100))}`
      )
      .replace(
        /api\.memory\.has\("All Software Columns"\) \? parseInt\(api\.memory\.get\("All Software Columns"\)\) : 6/g,
        `api.memory.has("All Software Columns") ? parseInt(api.memory.get("All Software Columns")) : ${Math.max(3, Math.min(6, Math.round(6 - (clampNum(config.allSoftwareSizePct, 75, 135, 100) - 100) / 15)))}`
      )
      .replace(
        /api\.memory\.has\("Photos Directory"\) && api\.memory\.get\("Photos Directory"\) !== "" \? String\(api\.memory\.get\("Photos Directory"\)\) : "\/storage\/emulated\/0\/Pictures"/g,
        `api.memory.has("Photos Directory") && api.memory.get("Photos Directory") !== "" ? String(api.memory.get("Photos Directory")) : "${(config.albumFolderLabel || '/storage/emulated/0/Pictures').replace(/["\\\r\n]/g, '').trim()}"`
      );

    if (hudSwatch) {
      themeQml = themeQml
        .replace(
          'api.memory.has("Accent Light Mode") ? api.memory.get("Accent Light Mode") : "#10AEBE"',
          `api.memory.has("Accent Light Mode") ? api.memory.get("Accent Light Mode") : "${hudSwatch.hex}"`
        )
        .replace(
          'api.memory.has("Accent Dark Mode") ? api.memory.get("Accent Dark Mode") : "#1d9bf3"',
          `api.memory.has("Accent Dark Mode") ? api.memory.get("Accent Dark Mode") : "${hudSwatch.hex}"`
        );
    }

    zip.file('skylineOS2/theme.qml', themeQml);
  }

  // 2. Calibrate skylineOS2/global/HighlightBorder.qml
  const hlEntry = zip.file('skylineOS2/global/HighlightBorder.qml');
  if (hlEntry) {
    let hlQml = await hlEntry.async('string');
    hlQml = hlQml
      .replace(/property int borderGap: vpx\(\d+\)/, `property int borderGap: vpx(${borderGap720})`)
      .replace(
        /property int borderwidth: \(typeof idx !== "undefined" && idx == -3\) \? vpx\(\d+\) : vpx\(\d+\)/,
        `property int borderwidth: (typeof idx !== "undefined" && idx == -3) ? vpx(${borderThick720 + 1}) : vpx(${borderThick720})`
      );
    zip.file('skylineOS2/global/HighlightBorder.qml', hlQml);
  }

  // 3. Calibrate skylineOS2/layer_home/HomeBar.qml
  const hbEntry = zip.file('skylineOS2/layer_home/HomeBar.qml');
  if (hbEntry) {
    let hbQml = await hbEntry.async('string');
    hbQml = hbQml
      .replace(/property int borderGapPx: vpx\(settings\.borderGap720 \|\| \d+\)/, `property int borderGapPx: vpx(settings.borderGap720 || ${borderGap720})`)
      .replace(/property int borderStrokePx: vpx\(settings\.borderThick720 \|\| \d+\)/, `property int borderStrokePx: vpx(settings.borderThick720 || ${borderThick720})`)
      .replace(/property real spacingRatio: settings\.cardSpacingRatio \|\| [0-9.]+/, `property real spacingRatio: settings.cardSpacingRatio || ${spacingRatio}`);
    zip.file('skylineOS2/layer_home/HomeBar.qml', hbQml);
  }

  // 4. Calibrate skylineOS2/layer_home/MenuButton.qml
  const mbEntry = zip.file('skylineOS2/layer_home/MenuButton.qml');
  if (mbEntry) {
    let mbQml = await mbEntry.async('string');
    mbQml = mbQml
      .replace(/(\n\s*width: vpx\()\d+(\)\n\s*height: vpx\()\d+(\))/, `$1${buttonSize720}$2${buttonSize720}$3`)
      .replace(
        /(id: iconHolder[\s\S]*?width: vpx\()\d+(\)\s*height: vpx\()\d+(\))/,
        `$1${iconSize720}$2${iconSize720}$3`
      );
    zip.file('skylineOS2/layer_home/MenuButton.qml', mbQml);
  }

  // 5. Calibrate skylineOS2/layer_home/HomeScreen.qml
  const hsEntry = zip.file('skylineOS2/layer_home/HomeScreen.qml');
  if (hsEntry) {
    let hsQml = await hsEntry.async('string');
    hsQml = hsQml
      .replace(
        /width: buttonMenu\.width \+ vpx\(\d+\)\s*height: Math\.round\(screenheight \* \(\(settings\.dockHeightPct \|\| [0-9.]+\) \/ 100\.0\)\)/,
        `width: buttonMenu.width + vpx(${dockPad720 * 2})\n                height: Math.round(screenheight * ((settings.dockHeightPct || ${dockPct.toFixed(1)}) / 100.0))`
      )
      .replace(
        /(id: buttonMenu\s*spacing: vpx\()\d+(\))/,
        `$1${buttonGap720}$2`
      );
    zip.file('skylineOS2/layer_home/HomeScreen.qml', hsQml);
  }

  // 6. Include calibrated RP5_PATCH_GUIDE.qml reference excerpt
  const patchGuide = generatePatchedQmlFiles(config).find((f) => f.path === 'RP5_PATCH_GUIDE.qml');
  if (patchGuide) {
    zip.file('skylineOS2/RP5_PATCH_GUIDE.qml', patchGuide.content);
  }

  return await zip.generateAsync({
    type: 'nodebuffer',
    compression: 'DEFLATE',
    compressionOptions: { level: 6 },
  });
}
