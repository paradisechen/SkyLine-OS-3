import type { AdaptivePalette, FocusZone } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import {
  UiKitAlbumIcon,
  UiKitBrowserIcon,
  UiKitEshopIcon,
  UiKitGameChatIcon,
  UiKitGameShareIcon,
  UiKitNewsIcon,
  UiKitNsoIcon,
  UiKitPowerIcon,
  UiKitSettingsIcon,
  UiKitVirtualCardIcon,
} from './UiKitIcons';

export interface DockButtonDef {
  id: string;
  label: string;
  action:
    | 'nso'
    | 'chat'
    | 'news'
    | 'store'
    | 'album'
    | 'gameshare'
    | 'browser'
    | 'software'
    | 'settings'
    | 'suspend';
  kitColor: string;
}

/** Switch 2 UI Kit Dock Icons + Nintendo-style Browser Earth icon (Controllers removed in SkyLine 3) */
export const DOCK_BUTTONS: DockButtonDef[] = [
  { id: 'nso', label: 'Nintendo Online', action: 'nso', kitColor: '#E60012' },
  { id: 'chat', label: 'GameChat', action: 'chat', kitColor: '#EE8600' },
  { id: 'news', label: 'News', action: 'news', kitColor: '#2BAB23' },
  { id: 'eshop', label: 'Nintendo eShop', action: 'store', kitColor: '#F11615' },
  { id: 'album', label: 'Album', action: 'album', kitColor: '#215FE5' },
  { id: 'gameshare', label: 'GameShare', action: 'gameshare', kitColor: '#2CADBF' },
  { id: 'browser', label: 'Netflix', action: 'browser', kitColor: '#E50914' },
  { id: 'cards', label: 'All Software', action: 'software', kitColor: '#767676' },
  { id: 'settings', label: 'System Settings', action: 'settings', kitColor: '#767676' },
  { id: 'sleep', label: 'Sleep Mode', action: 'suspend', kitColor: '#767676' },
];

interface BottomDockProps {
  metrics: Switch2LayoutMetrics;
  palette: AdaptivePalette;
  focusZone: FocusZone;
  focusedDockIndex: number;
  hoveredDockIndex: number | null;
  onHoverDock: (idx: number | null) => void;
  onClickDock: (idx: number, action: DockButtonDef['action']) => void;
}

export function BottomDock({
  metrics,
  palette,
  focusZone,
  focusedDockIndex,
  hoveredDockIndex,
  onHoverDock,
  onClickDock,
}: BottomDockProps) {
  const isDockActive = focusZone === 'dock';
  const activeIdx = isDockActive ? focusedDockIndex : hoveredDockIndex;

  const renderUiKitIcon = (btn: DockButtonDef, isHighlighted: boolean) => {
    const iconSize = Math.round(metrics.dockIconSize * 1.06);
    const neutralColor = isHighlighted ? palette.dockActiveIcon : palette.dockIcon;

    switch (btn.id) {
      case 'nso':
        return (
          <UiKitNsoIcon
            size={iconSize}
            highlighted={isHighlighted}
            mutedColor={palette.isDark ? '#CBD5E1' : '#9CA3AF'}
          />
        );
      case 'chat':
        return <UiKitGameChatIcon size={iconSize} />;
      case 'news':
        return <UiKitNewsIcon size={iconSize} />;
      case 'eshop':
        return (
          <UiKitEshopIcon
            size={iconSize}
            badgeBg={isHighlighted ? palette.dockActiveCircle : undefined}
          />
        );
      case 'album':
        return <UiKitAlbumIcon size={iconSize} />;
      case 'gameshare':
        return <UiKitGameShareIcon size={iconSize} />;
      case 'browser':
        return <UiKitBrowserIcon size={iconSize} />;
      case 'cards':
        return <UiKitVirtualCardIcon size={iconSize} color={neutralColor} />;
      case 'settings':
        return <UiKitSettingsIcon size={iconSize} color={neutralColor} />;
      case 'sleep':
        return <UiKitPowerIcon size={iconSize} color={neutralColor} />;
      default:
        return <UiKitSettingsIcon size={iconSize} color={neutralColor} />;
    }
  };

  return (
    <div
      className="relative z-20 flex flex-col items-center justify-center shrink-0"
      style={{
        paddingBottom: `${Math.max(24, Math.round(metrics.dockLabelFontSize * 1.85))}px`,
      }}
    >
      {/* Solid Borderless Flat Switch 2 Dock Bar (No Shadow) */}
      <nav
        aria-label="System Dock"
        data-testid="bottom-dock"
        className="relative flex items-center rounded-full transition-colors duration-200"
        style={{
          height: `${metrics.dockHeight}px`,
          paddingLeft: `${metrics.dockPaddingX}px`,
          paddingRight: `${metrics.dockPaddingX}px`,
          gap: `${Math.max(8, Math.round(metrics.dockButtonGap * 0.62))}px`,
          backgroundColor: palette.dockBg,
          border: 'none',
          boxShadow: 'none',
        }}
      >
        {DOCK_BUTTONS.map((btn, idx) => {
          const isHighlighted = activeIdx === idx;
          return (
            <div key={btn.id} className="relative flex flex-col items-center justify-center">
              <button
                type="button"
                data-testid={`dock-btn-${btn.id}`}
                aria-label={btn.label}
                onMouseEnter={() => onHoverDock(idx)}
                onMouseLeave={() => onHoverDock(null)}
                onClick={() => onClickDock(idx, btn.action)}
                className="relative rounded-full flex items-center justify-center cursor-pointer focus:outline-none transition-transform duration-150 active:scale-95"
                style={{
                  width: `${metrics.dockButtonSize}px`,
                  height: `${metrics.dockButtonSize}px`,
                  transform: isHighlighted ? 'scale(1.08)' : 'scale(1)',
                  backgroundColor:
                    isHighlighted && btn.id !== 'nso' ? palette.dockActiveCircle : 'transparent',
                }}
              >
                {/* Solid UI-Matched Outer Ring */}
                {isHighlighted && (
                  <span
                    aria-hidden="true"
                    data-testid="dock-selection-ring"
                    className="pointer-events-none absolute rounded-full"
                    style={{
                      inset: `-${metrics.dockRingGap + metrics.dockRingStroke}px`,
                      border: `${metrics.dockRingStroke}px solid ${palette.dockRingColor}`,
                    }}
                  />
                )}
                {renderUiKitIcon(btn, isHighlighted)}
              </button>

              <span
                aria-hidden={!isHighlighted}
                className={`absolute left-1/2 -translate-x-1/2 whitespace-nowrap font-ud-semibold pointer-events-none transition-all duration-150 ${
                  isHighlighted ? 'opacity-100 translate-y-0' : 'opacity-0 -translate-y-1'
                }`}
                style={{
                  top: `${metrics.dockButtonSize + Math.round(metrics.dockHeight * 0.24)}px`,
                  color: palette.dockLabel,
                  fontSize: `${metrics.dockLabelFontSize}px`,
                }}
              >
                {btn.label}
              </span>
            </div>
          );
        })}
      </nav>
    </div>
  );
}
