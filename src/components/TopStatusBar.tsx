import { useEffect, useState } from 'react';
import { Wifi, BatteryFull, BatteryMedium, BatteryLow } from 'lucide-react';
import type { AdaptivePalette, FocusZone, GameItem, SkylineConfig, UserProfile } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { UiKitAvatar } from './UiKitAvatar';

interface TopStatusBarProps {
  metrics: Switch2LayoutMetrics;
  palette: AdaptivePalette;
  config: SkylineConfig;
  activeUser: UserProfile;
  activeGame: GameItem | null;
  focusZone: FocusZone;
  onProfileClick: () => void;
  onStatusClick: () => void;
}

function formatClock(date: Date, format: '12hr' | '24hr'): string {
  const hours = date.getHours();
  const minutes = date.getMinutes().toString().padStart(2, '0');
  if (format === '24hr') {
    return `${hours.toString().padStart(2, '0')}:${minutes}`;
  }
  const period = hours >= 12 ? 'PM' : 'AM';
  const h12 = hours % 12 === 0 ? 12 : hours % 12;
  return `${h12}:${minutes} ${period}`;
}

export function TopStatusBar({
  metrics,
  palette,
  config,
  activeUser,
  focusZone,
  onProfileClick,
  onStatusClick,
}: TopStatusBarProps) {
  const [clockText, setClockText] = useState(() => formatClock(new Date(), config.timeFormat));
  const [batteryPct] = useState(86);

  useEffect(() => {
    setClockText(formatClock(new Date(), config.timeFormat));
    const timer = window.setInterval(() => {
      setClockText(formatClock(new Date(), config.timeFormat));
    }, 15000);
    return () => window.clearInterval(timer);
  }, [config.timeFormat]);

  const isProfileFocused = focusZone === 'profile';
  const BatteryGlyph =
    batteryPct >= 75 ? BatteryFull : batteryPct >= 35 ? BatteryMedium : BatteryLow;

  const fontScale = (config.systemFontScalePct || 100) / 100;
  // Match top bar nickname, clock, and battery percentage height to the battery/Wi-Fi icon height
  const iconH = Math.round(metrics.statusIconSize * 1.12);
  const statusTextSize = Math.round(iconH * fontScale);

  return (
    <header
      className="relative z-30 flex items-center justify-between w-full shrink-0"
      style={{
        paddingLeft: `${metrics.screenMargin}px`,
        paddingRight: `${metrics.screenMargin}px`,
        paddingTop: `${metrics.topBarTopMargin}px`,
      }}
    >
      {/* Left: UI Kit Character Avatar & Enlarged Nickname matching status icon height */}
      <div className="flex items-center gap-3.5 min-w-0">
        <button
          type="button"
          data-testid="profile-button"
          onClick={onProfileClick}
          aria-label={`Switch user (${activeUser.name})`}
          className="relative rounded-full shrink-0 cursor-pointer focus:outline-none transition-transform duration-150 active:scale-95"
          style={{
            width: `${metrics.profileSize}px`,
            height: `${metrics.profileSize}px`,
          }}
        >
          <span
            aria-hidden="true"
            className={`absolute inset-0 rounded-full pointer-events-none transition-opacity duration-150 ${
              isProfileFocused ? 'opacity-100' : 'opacity-0'
            }`}
            style={{
              margin: `-${Math.max(4, Math.round(metrics.borderStroke * 0.65))}px`,
              border: `${Math.max(3, Math.round(metrics.borderStroke * 0.55))}px solid ${palette.dockRingColor}`,
            }}
          />
          <span
            className="block w-full h-full rounded-full overflow-hidden"
            style={{ backgroundColor: palette.cardSurface }}
          >
            <UiKitAvatar
              characterId={activeUser.characterId}
              size={metrics.profileSize}
              roundedClass="rounded-full"
              alt={activeUser.name}
            />
          </span>
        </button>

        <span
          data-testid="active-username"
          className="font-ud-regular leading-none truncate transition-colors duration-200"
          style={{
            color: palette.topBarText,
            fontSize: `${statusTextSize}px`,
          }}
        >
          {activeUser.name}
        </span>
      </div>

      {/* Right: Bare Flat Status Elements matching Wi-Fi / Battery Icon Height */}
      <button
        type="button"
        onClick={onStatusClick}
        aria-label="Open SkyLine 3 Theme Settings"
        data-testid="status-pill"
        className="flex items-center transition-opacity duration-150 cursor-pointer hover:opacity-80 active:scale-[0.98] focus:outline-none focus-visible:ring-2"
        style={{
          height: `${metrics.statusPillHeight}px`,
          padding: 0,
          gap: `${Math.max(14, Math.round(metrics.statusPillPaddingX * 0.78))}px`,
          backgroundColor: 'transparent',
          border: 'none',
          boxShadow: 'none',
        }}
      >
        <span
          data-testid="status-time"
          className="font-ud-regular tabular-nums leading-none tracking-tight whitespace-nowrap transition-colors duration-200"
          style={{
            color: palette.topBarText,
            fontSize: `${statusTextSize}px`,
          }}
        >
          {clockText}
        </span>

        <span
          className="flex items-center gap-1.5 whitespace-nowrap"
          data-testid="status-battery"
        >
          {config.showBatteryPercent && (
            <span
              className="font-ud-regular tabular-nums leading-none transition-colors duration-200"
              style={{
                color: palette.topBarText,
                fontSize: `${statusTextSize}px`,
              }}
            >
              {batteryPct}%
            </span>
          )}
          <BatteryGlyph
            aria-hidden="true"
            className="transition-colors duration-200"
            style={{
              width: `${Math.round(iconH * 1.1)}px`,
              height: `${iconH}px`,
              color: palette.topBarIcon,
            }}
            strokeWidth={2}
          />
        </span>

        {config.showWifi && (
          <Wifi
            data-testid="status-wifi"
            aria-label="Wi-Fi Connected"
            className="transition-colors duration-200"
            style={{
              width: `${iconH}px`,
              height: `${iconH}px`,
              color: palette.topBarIcon,
            }}
            strokeWidth={2}
          />
        )}
      </button>
    </header>
  );
}
