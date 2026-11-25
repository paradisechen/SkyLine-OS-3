import { useEffect, useRef, useState } from 'react';
import { Plus, X } from 'lucide-react';
import { UI_KIT_AVATARS } from '../data/profiles';
import type { AdaptivePalette, UiKitCharacterId, UserProfile } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { UiKitAvatar } from './UiKitAvatar';
import { SwitchPdfIcon } from './SwitchPdfIcons';
import { BottomControllerGlyph } from './BottomControllerGlyph';

interface UserSelectOverlayProps {
  isOpen: boolean;
  title?: string;
  users: UserProfile[];
  activeUserId: string;
  palette: AdaptivePalette;
  metrics: Switch2LayoutMetrics;
  onSelectUser: (userId: string) => void;
  onAddUser: (name: string, characterId: UiKitCharacterId) => void;
  onDeleteUser: (userId: string) => void;
  onClose: () => void;
}

export function UserSelectOverlay({
  isOpen,
  title = '¿Quién está jugando?',
  users,
  activeUserId,
  palette,
  metrics,
  onSelectUser,
  onAddUser,
  onDeleteUser,
  onClose,
}: UserSelectOverlayProps) {
  const [rendered, setRendered] = useState(isOpen);
  const [visible, setVisible] = useState(false);
  const [creating, setCreating] = useState(false);
  const [showDeleteX, setShowDeleteX] = useState(false);
  const [focusedIdx, setFocusedIdx] = useState(() => {
    const idx = users.findIndex((u) => u.id === activeUserId);
    return idx >= 0 ? idx : 0;
  });

  const [newName, setNewName] = useState('');
  const [newCharId, setNewCharId] = useState<UiKitCharacterId>('luigi');
  const holdTimerRef = useRef<number | null>(null);
  const heldLongRef = useRef(false);

  const clearHoldTimer = () => {
    if (holdTimerRef.current !== null) {
      window.clearTimeout(holdTimerRef.current);
      holdTimerRef.current = null;
    }
  };

  // Fast Switch 2 bottom-sheet show/hide animation matching Overlay.png
  useEffect(() => {
    if (isOpen) {
      setRendered(true);
      setCreating(false);
      setShowDeleteX(false);
      const idx = users.findIndex((u) => u.id === activeUserId);
      setFocusedIdx(idx >= 0 ? idx : 0);
      const raf = requestAnimationFrame(() => {
        requestAnimationFrame(() => setVisible(true));
      });
      return () => cancelAnimationFrame(raf);
    } else {
      clearHoldTimer();
      setShowDeleteX(false);
      setCreating(false);
      setVisible(false);
      if (document.activeElement instanceof HTMLElement) {
        document.activeElement.blur();
      }
      window.getSelection()?.removeAllRanges();
      const stage = document.querySelector<HTMLElement>('[data-testid="rp5-stage"]');
      stage?.focus({ preventScroll: true });
      const timer = window.setTimeout(() => setRendered(false), 160);
      return () => window.clearTimeout(timer);
    }
  }, [isOpen, activeUserId, users]);

  // Keyboard support inside User Select overlay
  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        if (creating) setCreating(false);
        else if (showDeleteX) setShowDeleteX(false);
        else onClose();
        return;
      }
      if (creating) return;

      if (e.key === 'ArrowLeft') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((prev) => (prev > 0 ? prev - 1 : users.length));
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((prev) => (prev < users.length ? prev + 1 : 0));
      } else if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        e.stopPropagation();
        if (focusedIdx === users.length) {
          setCreating(true);
        } else if (users[focusedIdx]) {
          if (showDeleteX && users.length > 1) {
            onDeleteUser(users[focusedIdx].id);
          } else {
            onSelectUser(users[focusedIdx].id);
          }
        }
      } else if (
        (e.key === 'Delete' || e.key === '-' || e.key.toLowerCase() === 'x') &&
        users.length > 1
      ) {
        e.preventDefault();
        e.stopPropagation();
        setShowDeleteX((prev) => !prev);
      }
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [isOpen, creating, showDeleteX, focusedIdx, users, onSelectUser, onDeleteUser, onClose]);

  if (!rendered) return null;

  const h = metrics.viewportHeight;
  const cardWidth = Math.max(88, Math.round(h * 0.165));
  const plusSize = Math.max(40, Math.round(h * 0.068));
  const sheetPadX = Math.max(24, Math.round(metrics.screenMargin * 0.95));

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = newName.trim() || UI_KIT_AVATARS.find((a) => a.id === newCharId)?.label || 'Player';
    onAddUser(trimmed, newCharId);
    setNewName('');
    setCreating(false);
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={title}
      data-testid="user-select-overlay"
      className="absolute inset-0 z-50 flex flex-col justify-end overflow-hidden"
    >
      {/* Dimmed top backdrop matching Overlay.png */}
      <div
        onClick={onClose}
        className="absolute inset-0 bg-black/40 transition-opacity duration-150 ease-out"
        style={{ opacity: visible ? 1 : 0 }}
      />

      {/* Fast Sliding Flat Bottom Sheet */}
      <div
        className="relative z-10 w-full flex flex-col justify-between transition-transform duration-150"
        style={{
          height: '49%',
          backgroundColor: palette.overlaySheetBg,
          color: palette.overlayText,
          transform: visible ? 'translateY(0%)' : 'translateY(100%)',
          transitionTimingFunction: 'cubic-bezier(0.16, 1, 0.3, 1)',
          borderTop: `1px solid ${palette.overlayDivider}`,
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top Row: title + hairline divider */}
        <div style={{ paddingLeft: `${sheetPadX}px`, paddingRight: `${sheetPadX}px` }}>
          <div
            className="flex items-center justify-between"
            style={{
              paddingTop: `${Math.max(12, Math.round(h * 0.022))}px`,
              paddingBottom: `${Math.max(10, Math.round(h * 0.018))}px`,
            }}
          >
            <h2
              data-testid="user-select-title"
              className="font-ud-thin tracking-tight"
              style={{ fontSize: `${Math.max(16, Math.round(h * 0.032))}px` }}
            >
              {creating ? 'Create a new user.' : title}
            </h2>
            {creating && (
              <button
                type="button"
                onClick={() => setCreating(false)}
                className="font-ud-regular text-xs cursor-pointer hover:opacity-80"
                style={{ color: palette.overlayMuted }}
              >
                Cancel
              </button>
            )}
          </div>
          <div className="w-full h-px" style={{ backgroundColor: palette.overlayDivider }} />
        </div>

        {/* Middle Content: Flat User Cards + (+) Button OR New User Picker */}
        <div
          className="flex-1 flex items-center justify-center min-h-0"
          style={{ paddingLeft: `${sheetPadX}px`, paddingRight: `${sheetPadX}px` }}
        >
          {!creating ? (
            <div className="flex items-center justify-center gap-6">
              {users.map((user, idx) => {
                const isSelected = focusedIdx === idx;
                const isActive = user.id === activeUserId;
                return (
                  <div
                    key={user.id}
                    className="relative"
                    onMouseEnter={() => setFocusedIdx(idx)}
                  >
                    <button
                      type="button"
                      data-testid={`user-card-${user.id}`}
                      aria-label={`Select user ${user.name}${isActive ? ' (Active)' : ''}`}
                      onPointerDown={() => {
                        heldLongRef.current = false;
                        clearHoldTimer();
                        if (users.length > 1) {
                          holdTimerRef.current = window.setTimeout(() => {
                            heldLongRef.current = true;
                            setShowDeleteX(true);
                          }, 420);
                        }
                      }}
                      onPointerUp={() => clearHoldTimer()}
                      onPointerCancel={() => clearHoldTimer()}
                      onPointerLeave={() => clearHoldTimer()}
                      onClick={() => {
                        if (heldLongRef.current) {
                          heldLongRef.current = false;
                          return;
                        }
                        if (showDeleteX) {
                          setShowDeleteX(false);
                          return;
                        }
                        onSelectUser(user.id);
                      }}
                      className="relative flex flex-col overflow-hidden cursor-pointer focus:outline-none transition-transform duration-150 active:scale-95"
                      style={{
                        width: `${cardWidth}px`,
                        backgroundColor: palette.overlayCardBg,
                        borderRadius: '4px',
                        border: isSelected
                          ? `4px solid ${palette.borderPrimary}`
                          : `1px solid ${palette.overlayDivider}`,
                        transform: isSelected ? 'scale(1.03)' : 'scale(1)',
                      }}
                    >
                      <UiKitAvatar
                        characterId={user.characterId}
                        size={cardWidth}
                        roundedClass="rounded-none"
                        alt={user.name}
                      />
                      <div
                        className="w-full py-1.5 px-2 text-center truncate font-ud-regular"
                        style={{
                          fontSize: `${Math.max(12, Math.round(h * 0.023))}px`,
                          color: palette.overlayText,
                        }}
                      >
                        {user.name}
                      </div>
                    </button>

                    {/* Red (X) Remove User Button — revealed when user presses & holds */}
                    {showDeleteX && users.length > 1 && (
                      <button
                        type="button"
                        data-testid={`delete-user-${user.id}`}
                        aria-label={`Delete user ${user.name}`}
                        title={`Delete ${user.name}`}
                        onClick={(e) => {
                          e.stopPropagation();
                          onDeleteUser(user.id);
                        }}
                        className="absolute -top-2.5 -right-2.5 z-20 w-7 h-7 rounded-full flex items-center justify-center text-white shadow-md cursor-pointer hover:scale-110 active:scale-95 transition-transform"
                        style={{
                          backgroundColor: '#E60012',
                          border: '2px solid #FFFFFF',
                        }}
                      >
                        <X className="w-4 h-4" strokeWidth={3} />
                      </button>
                    )}
                  </div>
                );
              })}

              {/* Add (+) User Circle Button */}
              <button
                type="button"
                data-testid="add-user-button"
                aria-label="Add new user"
                onMouseEnter={() => setFocusedIdx(users.length)}
                onClick={() => setCreating(true)}
                className="flex items-center justify-center rounded-full cursor-pointer transition-all duration-150 hover:scale-105 active:scale-95 focus:outline-none"
                style={{
                  width: `${plusSize}px`,
                  height: `${plusSize}px`,
                  backgroundColor:
                    focusedIdx === users.length ? palette.overlayCardBg : 'transparent',
                  border: `2px solid ${
                    focusedIdx === users.length ? palette.borderPrimary : palette.overlayMuted
                  }`,
                  color:
                    focusedIdx === users.length ? palette.borderPrimary : palette.overlayMuted,
                }}
              >
                <Plus
                  style={{
                    width: `${Math.round(plusSize * 0.52)}px`,
                    height: `${Math.round(plusSize * 0.52)}px`,
                  }}
                  strokeWidth={2.5}
                />
              </button>
            </div>
          ) : (
            <form
              onSubmit={handleCreateSubmit}
              className="flex flex-col sm:flex-row items-center gap-5 max-w-4xl w-full justify-center"
            >
              {/* 6 Character Portraits */}
              <div className="flex items-center gap-2.5 flex-nowrap justify-center shrink-0">
                {UI_KIT_AVATARS.map((av) => {
                  const chosen = newCharId === av.id;
                  return (
                    <button
                      key={av.id}
                      type="button"
                      aria-label={`Choose ${av.label}`}
                      onClick={() => setNewCharId(av.id)}
                      className="rounded-lg overflow-hidden cursor-pointer transition-transform duration-150 focus:outline-none shrink-0"
                      style={{
                        transform: chosen ? 'scale(1.08)' : 'scale(1)',
                        border: chosen
                          ? `3px solid ${palette.borderPrimary}`
                          : `1px solid ${palette.overlayDivider}`,
                      }}
                    >
                      <UiKitAvatar
                        characterId={av.id}
                        size={Math.max(42, Math.round(h * 0.072))}
                        roundedClass="rounded-lg"
                      />
                    </button>
                  );
                })}
              </div>

              <div className="flex items-center gap-2.5">
                <input
                  type="text"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  onBlur={() => window.getSelection()?.removeAllRanges()}
                  placeholder="Enter user name..."
                  maxLength={14}
                  autoFocus
                  className="px-3.5 py-2 rounded-lg text-sm font-ud-regular focus:outline-none select-text"
                  style={{
                    backgroundColor: palette.overlayCardBg,
                    color: palette.overlayText,
                    border: `2px solid ${palette.borderPrimary}`,
                    width: '170px',
                  }}
                />
                <button
                  type="submit"
                  className="px-4 py-2 rounded-lg text-sm font-ud-medium text-white cursor-pointer"
                  style={{ backgroundColor: palette.borderPrimary }}
                >
                  Save
                </button>
              </div>
            </form>
          )}
        </div>

        {/* Bottom Footer Row */}
        <div style={{ paddingLeft: `${sheetPadX}px`, paddingRight: `${sheetPadX}px` }}>
          <div className="w-full h-px" style={{ backgroundColor: palette.overlayDivider }} />
          <div
            className="flex items-center justify-between"
            style={{
              height: `${Math.max(40, Math.round(h * 0.085))}px`,
            }}
          >
            <BottomControllerGlyph size={metrics.helpIconSize} color={palette.overlayText} />

            <div className="flex items-center gap-6">
              <button
                type="button"
                onClick={() => {
                  if (creating) setCreating(false);
                  else onClose();
                }}
                className="flex items-center gap-2 cursor-pointer hover:opacity-75"
              >
                <SwitchPdfIcon
                  button="B"
                  size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                  fillColor={palette.overlayText}
                  cutoutColor={palette.overlaySheetBg}
                />
                <span
                  className="font-ud-regular"
                  style={{ fontSize: `${metrics.helpFontSize}px`, color: palette.overlayText }}
                >
                  Back
                </span>
              </button>

              {!creating && (
                <button
                  type="button"
                  onClick={() => {
                    if (focusedIdx === users.length) {
                      setCreating(true);
                    } else if (users[focusedIdx]) {
                      onSelectUser(users[focusedIdx].id);
                    }
                  }}
                  className="flex items-center gap-2 cursor-pointer hover:opacity-75"
                >
                  <SwitchPdfIcon
                    button="A"
                    size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                    fillColor={palette.overlayText}
                    cutoutColor={palette.overlaySheetBg}
                  />
                  <span
                    className="font-ud-regular"
                    style={{ fontSize: `${metrics.helpFontSize}px`, color: palette.overlayText }}
                  >
                    OK
                  </span>
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
