import type { AdaptivePalette, GameItem } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { BottomControllerGlyph } from './BottomControllerGlyph';
import { SwitchPdfIcon, type SwitchPdfButtonKey } from './SwitchPdfIcons';

interface ControllerHelpBarProps {
  metrics: Switch2LayoutMetrics;
  palette: AdaptivePalette;
  activeGame: GameItem | null;
  onLaunch: () => void;
  onDetails: () => void;
  onToggleFavorite: () => void;
  onOpenGameSettings: () => void;
}

export function ControllerHelpBar({
  metrics,
  palette,
  activeGame,
  onLaunch,
  onDetails,
  onToggleFavorite,
  onOpenGameSettings,
}: ControllerHelpBarProps) {
  const badgeSize = Math.max(20, Math.round(metrics.helpIconSize * 0.68));

  const prompts: {
    button: SwitchPdfButtonKey;
    label: string;
    text: string;
    onClick: () => void;
  }[] = [
    { button: 'A', label: 'A', text: activeGame ? 'Start' : 'Open All', onClick: onLaunch },
    { button: 'Y', label: 'Y', text: 'Details', onClick: onDetails },
    {
      button: 'X',
      label: 'X',
      text: activeGame?.favorite ? 'Unfavorite' : 'Favorite',
      onClick: onToggleFavorite,
    },
    { button: 'PLUS', label: '+', text: 'Options', onClick: onOpenGameSettings },
  ];

  return (
    <footer
      data-testid="controller-help-bar"
      className="relative z-20 flex items-center justify-between w-full shrink-0"
      style={{
        height: `${metrics.helpBarHeight}px`,
        paddingLeft: `${metrics.screenMargin}px`,
        paddingRight: `${metrics.screenMargin}px`,
      }}
    >
      <div className="flex items-center gap-2.5 min-w-0">
        <BottomControllerGlyph
          size={metrics.helpIconSize}
          color={palette.helpBarIcon}
        />
        <span
          data-testid="helpbar-game-name"
          className="font-ud-regular tracking-tight truncate transition-colors duration-200"
          style={{
            color: palette.helpBarText,
            fontSize: `${metrics.helpFontSize}px`,
          }}
        >
          {activeGame ? activeGame.title : 'All Software'}
        </span>
      </div>

      <div
        className="flex items-center shrink-0"
        style={{
          gap: `${Math.max(14, Math.round(metrics.helpIconSize * 0.68))}px`,
        }}
      >
        {prompts.map((item) => (
          <button
            key={item.label}
            type="button"
            data-testid={`help-btn-${item.button.toLowerCase()}`}
            onClick={item.onClick}
            className="flex items-center gap-2 cursor-pointer rounded-lg px-1.5 py-1 transition-opacity duration-150 hover:opacity-80 active:scale-95 focus:outline-none focus-visible:ring-2"
          >
            <SwitchPdfIcon
              button={item.button}
              size={badgeSize}
              fillColor={palette.helpBarText}
              cutoutColor={palette.canvasBg}
            />
            <span
              className="font-ud-regular whitespace-nowrap transition-colors duration-200"
              style={{
                color: palette.helpBarText,
                fontSize: `${metrics.helpFontSize}px`,
              }}
            >
              {item.text}
            </span>
          </button>
        ))}
      </div>
    </footer>
  );
}
