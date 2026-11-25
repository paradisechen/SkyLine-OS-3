import { useEffect, useState } from 'react';
import { Plus } from 'lucide-react';
import type { AdaptivePalette } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { SwitchPdfIcon } from './SwitchPdfIcons';
import { BottomControllerGlyph } from './BottomControllerGlyph';

interface ChatViewProps {
  palette: AdaptivePalette;
  metrics: Switch2LayoutMetrics;
  onAddFriend: (code: string) => void;
  onClose: () => void;
}

/**
 * GameChat / Nintendo Network Section:
 * Centered bold grey rounded "Nintendo Network" + lighter "Add (+) your friends to connect."
 */
export function ChatView({ palette, metrics, onAddFriend, onClose }: ChatViewProps) {
  const [adding, setAdding] = useState(false);
  const [friendCode, setFriendCode] = useState('');
  const [addedFriends, setAddedFriends] = useState<string[]>([]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        if (adding) setAdding(false);
        else onClose();
      }
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [adding, onClose]);

  const h = metrics.viewportHeight;
  const padX = Math.max(24, Math.round(metrics.screenMargin * 0.92));
  const isDark = palette.isDark;
  const bg = isDark ? '#1A1C21' : '#EFEFEF';
  const headingColor = isDark ? '#9CA3AF' : '#717680';
  const subColor = isDark ? '#CBD5E1' : '#858B94';
  const divider = isDark ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.14)';

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const cleaned = friendCode.trim();
    if (!cleaned) return;
    setAddedFriends((prev) => [...prev, cleaned]);
    onAddFriend(cleaned);
    setFriendCode('');
    setAdding(false);
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Nintendo Network"
      data-testid="chat-view"
      className="animate-ns2-fade absolute inset-0 z-40 flex flex-col justify-between overflow-hidden select-none"
      style={{ backgroundColor: bg, color: headingColor }}
    >
      <div />

      {/* Centered Nintendo Network Prompt */}
      <div className="flex flex-col items-center justify-center px-6 text-center gap-3">
        <h1
          className="font-ud-bold tracking-tight"
          style={{
            fontSize: `${Math.max(26, Math.round(h * 0.056))}px`,
            color: headingColor,
          }}
        >
          Nintendo Network
        </h1>

        <div
          className="flex items-center justify-center gap-1.5 font-ud-thin"
          style={{
            fontSize: `${Math.max(14, Math.round(h * 0.027))}px`,
            color: subColor,
          }}
        >
          <span>Add</span>
          <button
            type="button"
            data-testid="chat-add-friend-btn"
            onClick={() => setAdding(true)}
            aria-label="Add friend"
            className="inline-flex items-center justify-center w-6 h-6 rounded-full cursor-pointer transition-transform hover:scale-110"
            style={{ backgroundColor: '#EE8600', color: '#FFFFFF' }}
          >
            <Plus className="w-4 h-4" strokeWidth={3} />
          </button>
          <span>your friends to connect.</span>
        </div>

        {adding && (
          <form onSubmit={handleSubmit} className="flex items-center gap-2 mt-3">
            <input
              type="text"
              value={friendCode}
              onChange={(e) => setFriendCode(e.target.value)}
              onBlur={() => window.getSelection()?.removeAllRanges()}
              placeholder="SW-0000-0000-0000"
              autoFocus
              className="px-3.5 py-2 rounded-lg text-sm font-ud-regular focus:outline-none"
              style={{
                backgroundColor: isDark ? '#262932' : '#FFFFFF',
                color: isDark ? '#F3F4F6' : '#1F2329',
                border: '2px solid #EE8600',
              }}
            />
            <button
              type="submit"
              className="px-4 py-2 rounded-lg text-xs font-ud-bold text-white cursor-pointer"
              style={{ backgroundColor: '#EE8600' }}
            >
              Send Request
            </button>
          </form>
        )}

        {addedFriends.length > 0 && (
          <div className="flex flex-wrap gap-2 justify-center mt-2">
            {addedFriends.map((f, i) => (
              <span
                key={i}
                className="px-3 py-1 rounded-full text-xs font-ud-semibold"
                style={{
                  backgroundColor: isDark ? '#262932' : '#FFFFFF',
                  color: '#EE8600',
                }}
              >
                Invited {f}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Bottom Footer */}
      <footer style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
        <div className="w-full h-px" style={{ backgroundColor: divider }} />
        <div
          className="flex items-center justify-between"
          style={{ height: `${Math.max(40, Math.round(h * 0.085))}px` }}
        >
          <BottomControllerGlyph size={metrics.helpIconSize} color={headingColor} />
          <button
            type="button"
            onClick={onClose}
            className="flex items-center gap-2 cursor-pointer hover:opacity-75"
          >
            <SwitchPdfIcon
              button="B"
              size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
              fillColor={headingColor}
              cutoutColor={bg}
            />
            <span
              className="font-ud-semibold"
              style={{ fontSize: `${metrics.helpFontSize}px`, color: headingColor }}
            >
              Back
            </span>
          </button>
        </div>
      </footer>
    </div>
  );
}
