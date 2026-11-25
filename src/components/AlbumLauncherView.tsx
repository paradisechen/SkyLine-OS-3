import { useEffect, useRef, useState } from 'react';
import { ExternalLink, FolderOpen, Image as ImageIcon } from 'lucide-react';
import type { AdaptivePalette, AlbumPhotoItem } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { SwitchPdfIcon } from './SwitchPdfIcons';
import { UiKitAlbumIcon } from './UiKitIcons';
import { BottomControllerGlyph } from './BottomControllerGlyph';

interface AlbumLauncherViewProps {
  photos: AlbumPhotoItem[];
  folderLabel: string;
  palette: AdaptivePalette;
  metrics: Switch2LayoutMetrics;
  onAddPhotos: (newPhotos: AlbumPhotoItem[], folderLabel?: string) => void;
  onClose: () => void;
}

const LOCAL_FALLBACK_PHOTO = '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg';

/**
 * Album Section:
 * Renders photos loaded from Settings -> Photos Directory with full 2D D-Pad navigation
 */
export function AlbumLauncherView({
  photos,
  folderLabel,
  palette,
  metrics,
  onAddPhotos,
  onClose,
}: AlbumLauncherViewProps) {
  const [focusedIdx, setFocusedIdx] = useState(0);
  const [selectedIdx, setSelectedIdx] = useState<number | null>(null);
  const [intentNotice, setIntentNotice] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        if (selectedIdx !== null) setSelectedIdx(null);
        else onClose();
        return;
      }

      if (photos.length === 0) return;

      if (selectedIdx !== null) {
        if (e.key === 'ArrowRight') {
          e.preventDefault();
          e.stopPropagation();
          setSelectedIdx((i) => ((i ?? 0) + 1) % photos.length);
        } else if (e.key === 'ArrowLeft') {
          e.preventDefault();
          e.stopPropagation();
          setSelectedIdx((i) => ((i ?? 0) - 1 + photos.length) % photos.length);
        }
        return;
      }

      const cols = 4;
      if (e.key === 'ArrowRight') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((p) => (p + 1 < photos.length ? p + 1 : 0));
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((p) => (p > 0 ? p - 1 : photos.length - 1));
      } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((p) => (p + cols < photos.length ? p + cols : p));
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((p) => (p - cols >= 0 ? p - cols : p));
      } else if (e.key === 'Enter' && photos[focusedIdx]) {
        e.preventDefault();
        e.stopPropagation();
        setSelectedIdx(focusedIdx);
      }
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [focusedIdx, onClose, photos, selectedIdx]);

  const h = metrics.viewportHeight;
  const padX = Math.max(24, Math.round(metrics.screenMargin * 0.92));
  const isDark = palette.isDark;
  const bg = isDark ? '#1A1C21' : '#EFEFEF';
  const cardBg = isDark ? '#252830' : '#FFFFFF';
  const textMain = isDark ? '#F3F4F6' : '#1F2329';
  const textMuted = isDark ? '#9CA3AF' : '#5E6570';
  const divider = isDark ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.14)';

  const handleOpenAndroidPhotos = () => {
    setIntentNotice(true);
    const isAndroid = /android/i.test(navigator.userAgent);
    if (isAndroid) {
      window.location.href = 'intent:#Intent;action=android.intent.action.VIEW;type=image/*;end';
    } else {
      fileRef.current?.click();
    }
  };

  const handlePickFiles = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files ?? []);
    if (files.length === 0) return;
    const loaded: AlbumPhotoItem[] = files.map((file, idx) => ({
      id: `photo-${Date.now()}-${idx}`,
      name: file.name,
      url: URL.createObjectURL(file),
      addedAt: 'Just Added',
    }));
    onAddPhotos(loaded);
    e.target.value = '';
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Album"
      data-testid="album-view"
      className="animate-ns2-fade absolute inset-0 z-40 flex flex-col overflow-hidden select-none"
      style={{ backgroundColor: bg, color: textMain }}
    >
      {/* Top Header */}
      <div style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
        <div
          className="flex items-center justify-between gap-4"
          style={{ height: `${Math.max(46, Math.round(h * 0.105))}px` }}
        >
          <div className="flex items-center gap-3 min-w-0">
            <UiKitAlbumIcon size={28} />
            <div className="min-w-0">
              <h1
                className="font-ud-medium tracking-tight truncate"
                style={{ fontSize: `${Math.max(17, Math.round(h * 0.034))}px` }}
              >
                Album
              </h1>
              <div className="font-ud-regular text-[11px] truncate" style={{ color: textMuted }}>
                Photos Directory: {folderLabel}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2.5 shrink-0">
            <button
              type="button"
              data-testid="album-open-device-photos"
              onClick={handleOpenAndroidPhotos}
              className="flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-ud-medium text-white cursor-pointer"
              style={{ backgroundColor: '#215FE5' }}
            >
              <ExternalLink className="w-3.5 h-3.5" />
              <span>Open Device Photos App</span>
            </button>
            <button
              type="button"
              onClick={() => fileRef.current?.click()}
              className="flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-ud-regular cursor-pointer"
              style={{ backgroundColor: cardBg, color: textMain, border: `1px solid ${divider}` }}
            >
              <FolderOpen className="w-3.5 h-3.5" />
              <span>Browse Gallery</span>
            </button>
            <input
              ref={fileRef}
              type="file"
              accept="image/*,video/*"
              multiple
              onChange={handlePickFiles}
              className="hidden"
            />
          </div>
        </div>
        <div className="w-full h-px" style={{ backgroundColor: divider }} />
      </div>

      {/* Main Content */}
      <div
        data-scroll-container="true"
        className="flex-1 overflow-y-auto no-scrollbar flex flex-col justify-center"
        style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px`, paddingTop: '20px', paddingBottom: '20px' }}
      >
        {selectedIdx !== null && photos[selectedIdx] ? (
          <div className="w-full h-full flex flex-col items-center justify-center gap-3">
            <img
              src={photos[selectedIdx].url}
              alt={photos[selectedIdx].name}
              onError={(e) => {
                if (e.currentTarget.dataset.fb !== '1') {
                  e.currentTarget.dataset.fb = '1';
                  e.currentTarget.src = LOCAL_FALLBACK_PHOTO;
                }
              }}
              className="max-h-[82%] max-w-full rounded-xl object-contain"
              style={{ border: `1px solid ${divider}` }}
            />
            <span className="text-xs font-ud-regular" style={{ color: textMuted }}>
              {photos[selectedIdx].name}
            </span>
          </div>
        ) : photos.length > 0 ? (
          <div data-testid="album-photo-grid" className="grid grid-cols-4 gap-4 h-full content-start">
            {photos.map((p, idx) => {
              const focused = focusedIdx === idx;
              return (
                <button
                  key={p.id}
                  type="button"
                  data-testid={`album-photo-${idx}`}
                  onMouseEnter={() => setFocusedIdx(idx)}
                  onClick={() => setSelectedIdx(idx)}
                  className="relative aspect-video rounded-xl overflow-hidden cursor-pointer focus:outline-none hover:scale-[1.02] transition-transform"
                  style={{
                    backgroundColor: cardBg,
                    border: focused ? `3.5px solid #215FE5` : `1px solid ${divider}`,
                  }}
                >
                  <img
                    src={p.url}
                    alt={p.name}
                    onError={(e) => {
                      if (e.currentTarget.dataset.fb !== '1') {
                        e.currentTarget.dataset.fb = '1';
                        e.currentTarget.src = LOCAL_FALLBACK_PHOTO;
                      }
                    }}
                    className="w-full h-full object-cover block"
                  />
                  <span className="absolute bottom-0 inset-x-0 px-2 py-1 bg-black/55 text-white text-[10px] font-ud-regular truncate text-left">
                    {p.name}
                  </span>
                </button>
              );
            })}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center text-center gap-3 max-w-lg mx-auto">
            <div
              className="w-16 h-16 rounded-2xl flex items-center justify-center"
              style={{ backgroundColor: cardBg, border: `1px solid ${divider}` }}
            >
              <ImageIcon className="w-8 h-8" style={{ color: '#215FE5' }} />
            </div>
            <h2 className="font-ud-medium text-lg">Device Screenshots &amp; Photos</h2>
            <p className="font-ud-regular text-xs leading-relaxed" style={{ color: textMuted }}>
              Set your root folder in Settings → User Settings → Photos Directory or browse photos here to
              view images directly inside Album.
            </p>
            {intentNotice && (
              <p className="text-xs font-ud-medium" style={{ color: '#215FE5' }}>
                Opening device photo gallery...
              </p>
            )}
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
          <BottomControllerGlyph size={metrics.helpIconSize} color={textMain} />
          <button
            type="button"
            onClick={() => {
              if (selectedIdx !== null) setSelectedIdx(null);
              else onClose();
            }}
            className="flex items-center gap-2 cursor-pointer hover:opacity-75"
          >
            <SwitchPdfIcon
              button="B"
              size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
              fillColor={textMain}
              cutoutColor={bg}
            />
            <span
              className="font-ud-regular"
              style={{ fontSize: `${metrics.helpFontSize}px`, color: textMain }}
            >
              Back
            </span>
          </button>
        </div>
      </footer>
    </div>
  );
}
