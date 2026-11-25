import { useCallback, useEffect, useRef, useState } from 'react';
import {
  ArrowLeft,
  ArrowDownAZ,
  BarChart2,
  ChevronLeft,
  ChevronRight,
  Download,
  Gamepad2,
  LayoutGrid,
  Lightbulb,
  Maximize2,
  Minimize2,
  Star,
} from 'lucide-react';
import type {
  AdaptivePalette,
  ApkpCategory,
  ApkpGameDetail,
  ApkpGameSummary,
  ApkpLibraryResponse,
  UserProfile,
} from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { APKP_FALLBACK_CATALOG } from '../utils/apkportsParser';
import { ARCHIVE_FALLBACK_CATALOG } from '../utils/archiveOrgParser';
import { NSWPEDIA_FALLBACK_CATALOG } from '../utils/nswpediaParser';
import { SWITCHSROM_FALLBACK_CATALOG } from '../utils/switchsromParser';
import { VIMM_FALLBACK_CATALOG } from '../utils/vimmParser';
import {
  ESHOP_ALPHABET_LETTERS,
  filterAndPaginateUnifiedCatalog,
  stepAlphabetLetter,
  unifyEshopCatalog,
} from '../utils/eshopHelpers';
import { UiKitAvatar } from './UiKitAvatar';
import { SwitchPdfIcon } from './SwitchPdfIcons';
import { BottomControllerGlyph } from './BottomControllerGlyph';

type EShopSectionId =
  | 'highlights'
  | 'forYou'
  | 'wishlist'
  | 'genres'
  | 'charts'
  | 'az';

interface EShopViewProps {
  metrics: Switch2LayoutMetrics;
  palette: AdaptivePalette;
  activeUser: UserProfile;
  wishlistIds: string[];
  installedSlugs: string[];
  fontScalePct?: number;
  onToggleWishlist: (id: string) => void;
  onInstallToHome: (game: ApkpGameSummary, detail?: ApkpGameDetail | null) => void;
  onOpenDownloadPage: (url: string) => void;
  onOpenUserSelect: () => void;
  onClose: () => void;
}

const SIDEBAR_ITEMS: {
  id: EShopSectionId;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
}[] = [
  { id: 'highlights', label: 'Highlights', icon: Star },
  { id: 'forYou', label: 'For You', icon: Lightbulb },
  { id: 'wishlist', label: 'Wish List', icon: Star },
  { id: 'genres', label: 'Genres', icon: Gamepad2 },
  { id: 'charts', label: 'Charts', icon: BarChart2 },
  { id: 'az', label: 'A > Z', icon: ArrowDownAZ },
];

const GENRE_FILTERS: ApkpCategory[] = [
  { name: 'Action', slug: 'action' },
  { name: 'RPG', slug: 'rpg' },
  { name: 'Adventure', slug: 'adventure' },
  { name: 'Shooter', slug: 'shooter' },
  { name: 'Platformer', slug: 'platformer' },
  { name: 'Racing', slug: 'racing' },
  { name: 'Simulation', slug: 'simulation' },
  { name: 'Sports', slug: 'sports' },
  { name: 'GBA (Retro)', slug: 'gba' },
  { name: 'DS (Retro)', slug: 'ds' },
  { name: 'N64 (Retro)', slug: 'n64' },
  { name: 'SNES (Retro)', slug: 'snes' },
  { name: 'GameCube', slug: 'gamecube' },
  { name: 'PS2 (Retro)', slug: 'ps2' },
  { name: 'PSP (Retro)', slug: 'psp' },
  { name: 'Wii (Retro)', slug: 'wii' },
  { name: 'PS1 (Retro)', slug: 'ps1' },
];

const COMBINED_FALLBACK = unifyEshopCatalog([
  APKP_FALLBACK_CATALOG,
  SWITCHSROM_FALLBACK_CATALOG,
  ARCHIVE_FALLBACK_CATALOG,
  VIMM_FALLBACK_CATALOG,
  NSWPEDIA_FALLBACK_CATALOG,
]);

function formatFastYouTubeEmbed(url?: string): string | undefined {
  if (!url) return undefined;
  if (url.includes('youtube') || url.includes('youtu.be')) {
    const m =
      url.match(/\/embed\/([A-Za-z0-9_-]{6,})/) ||
      url.match(/[?&]v=([A-Za-z0-9_-]{6,})/) ||
      url.match(/youtu\.be\/([A-Za-z0-9_-]{6,})/);
    if (m?.[1]) {
      return `https://www.youtube.com/embed/${m[1]}?autoplay=1&mute=0&controls=0&disablekb=1&fs=0&modestbranding=1&iv_load_policy=3&playsinline=1&rel=0&enablejsapi=1`;
    }
    return url.replace('www.youtube-nocookie.com/embed/', 'www.youtube.com/embed/');
  }
  return url;
}

export function EShopView({
  metrics,
  activeUser,
  wishlistIds,
  installedSlugs,
  fontScalePct = 100,
  onToggleWishlist,
  onInstallToHome,
  onOpenDownloadPage,
  onOpenUserSelect,
  onClose,
}: EShopViewProps) {
  const [section, setSection] = useState<EShopSectionId>('highlights');
  const [activeLetter, setActiveLetter] = useState<string>('All');
  const [focusArea, setFocusArea] = useState<'sidebar' | 'grid' | 'alphabet'>('grid');
  const [sidebarIdx, setSidebarIdx] = useState(0);
  const [selectedGenre, setSelectedGenre] = useState('action');
  const [page, setPage] = useState(1);

  const [games, setGames] = useState<ApkpGameSummary[]>(COMBINED_FALLBACK.slice(0, 6));
  const [totalCount, setTotalCount] = useState(COMBINED_FALLBACK.length);
  const [totalPages, setTotalPages] = useState(Math.max(1, Math.ceil(COMBINED_FALLBACK.length / 6)));
  const [hasMore, setHasMore] = useState(true);
  const [loading, setLoading] = useState(false);
  const [selectedCardIdx, setSelectedCardIdx] = useState(0);

  const [detailGame, setDetailGame] = useState<ApkpGameDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [wikiSummary, setWikiSummary] = useState<string>('');
  const [resolvedVideoUrl, setResolvedVideoUrl] = useState<string | undefined>(undefined);
  const [videoFullscreen, setVideoFullscreen] = useState(false);
  const [slideDir, setSlideDir] = useState<'none' | 'next' | 'prev'>('none');

  const savedCatalogRef = useRef<Record<string, ApkpGameSummary>>({});

  const fetchLibrary = useCallback(async () => {
    if (section === 'wishlist') {
      const baseItems = wishlistIds
        .map(
          (id) =>
            savedCatalogRef.current[id] ||
            COMBINED_FALLBACK.find((fb) => fb.id === id)
        )
        .filter((x): x is ApkpGameSummary => Boolean(x));
      const paged = filterAndPaginateUnifiedCatalog(baseItems, {
        letter: activeLetter,
        page,
        pageSize: 6,
      });
      setGames(paged.games);
      setTotalCount(paged.totalCount);
      setTotalPages(paged.totalPages);
      setHasMore(paged.page < paged.totalPages);
      setLoading(false);
      return;
    }

    setLoading(true);
    try {
      const sp = new URLSearchParams();
      sp.set('page', String(page));
      sp.set('limit', '6');
      sp.set('letter', activeLetter);

      if (section === 'genres') {
        sp.set('sort', 'popular');
        sp.set('category', selectedGenre);
      } else if (section === 'az') {
        sp.set('sort', 'title');
      } else if (section === 'charts' || section === 'highlights') {
        sp.set('sort', 'popular');
      } else if (section === 'forYou') {
        sp.set('sort', 'popular');
        sp.set('category', 'action');
      } else {
        sp.set('sort', 'popular');
      }

      const res = await fetch(`/api/apkports/games?${sp.toString()}`);
      const json = (await res.json()) as ApkpLibraryResponse;

      for (const g of json.games) {
        savedCatalogRef.current[g.id] = g;
      }

      setGames(json.games);
      setTotalCount(json.totalCount);
      setTotalPages(json.totalPages);
      setHasMore(Boolean(json.hasMore));
      setSelectedCardIdx((cur) => (cur >= Math.min(6, json.games.length) ? 0 : cur));
    } catch {
      const paged = filterAndPaginateUnifiedCatalog(COMBINED_FALLBACK, {
        letter: activeLetter,
        category: section === 'genres' ? selectedGenre : section === 'forYou' ? 'action' : '',
        sort: section === 'az' ? 'title' : 'popular',
        page,
        pageSize: 6,
      });
      setGames(paged.games);
      setTotalCount(paged.totalCount);
      setTotalPages(paged.totalPages);
      setHasMore(false);
    } finally {
      setLoading(false);
    }
  }, [activeLetter, page, section, selectedGenre, wishlistIds]);

  useEffect(() => {
    fetchLibrary();
  }, [fetchLibrary]);

  const openDetail = useCallback(async (item: ApkpGameSummary) => {
    setDetailLoading(true);
    setWikiSummary('');
    setVideoFullscreen(false);
    const initialFastVideo = formatFastYouTubeEmbed(item.videoUrl);
    setResolvedVideoUrl(initialFastVideo);

    const isNsw = item.sourceSite === 'nswpedia' || item.slug.startsWith('nsw-');
    const isSwitchsrom = item.sourceSite === 'switchsrom' || item.slug.startsWith('swr-');
    const isVimm = item.sourceSite === 'vimm' || item.slug.startsWith('vimm-');
    const isArchive = item.sourceSite === 'archive' || item.slug.startsWith('archive-');
    const baseSource =
      item.pageUrl ||
      item.downloadUrl ||
      (isSwitchsrom
        ? 'https://app.switchsrom.com/roms/'
        : isArchive
          ? 'https://archive.org/download/ultimate-rom-collection/'
          : isVimm
            ? 'https://vimm.net/vault'
            : isNsw
              ? 'https://nswpedia.com/'
              : `https://www.apkports.com/game/${encodeURIComponent(item.slug)}`);

    setDetailGame({
      ...item,
      description:
        item.description ||
        `${item.title} — Loading complete Wikipedia description and release details...`,
      screenshots: [item.coverUrl],
      sourceUrl: baseSource,
      pageUrl: item.pageUrl || baseSource,
      downloadUrl: item.downloadUrl || baseSource,
      videoUrl: initialFastVideo,
    });

    // Fetch Wikipedia description + official detail record in parallel
    let foundVideo = initialFastVideo;
    const [detailRes, wikiRes] = await Promise.allSettled([
      fetch(`/api/apkports/game/${encodeURIComponent(item.slug)}`).then((r) => (r.ok ? r.json() : null)),
      fetch(`/api/wikipedia/summary?title=${encodeURIComponent(item.title)}`).then((r) =>
        r.ok ? r.json() : null
      ),
    ]);

    if (wikiRes.status === 'fulfilled' && wikiRes.value?.extract) {
      setWikiSummary(String(wikiRes.value.extract));
    }

    if (detailRes.status === 'fulfilled' && detailRes.value) {
      const full = detailRes.value as ApkpGameDetail;
      const formatted = formatFastYouTubeEmbed(full.videoUrl);
      if (formatted) {
        foundVideo = formatted;
        setResolvedVideoUrl(formatted);
      }
      setDetailGame({ ...full, videoUrl: formatted || foundVideo });
    }
    setDetailLoading(false);

    // Automatically resolve YouTube gameplay trailer (zero controls preview) if missing
    if (!foundVideo) {
      try {
        const ytRes = await fetch(`/api/youtube/search?q=${encodeURIComponent(item.title)}`);
        if (ytRes.ok) {
          const ytJson = (await ytRes.json()) as { found?: boolean; embedUrl?: string; videoId?: string };
          const cleanEmbed = ytJson.videoId
            ? `https://www.youtube.com/embed/${ytJson.videoId}?autoplay=1&mute=0&controls=0&disablekb=1&fs=0&modestbranding=1&iv_load_policy=3&playsinline=1&rel=0&enablejsapi=1`
            : formatFastYouTubeEmbed(ytJson.embedUrl);
          if (cleanEmbed) {
            setResolvedVideoUrl(cleanEmbed);
            setDetailGame((cur) => (cur ? { ...cur, videoUrl: cleanEmbed } : cur));
          }
        }
      } catch {
        // Ignore lookup error
      }
    }
  }, []);

  const activateSection = useCallback((idx: number) => {
    const chosen = SIDEBAR_ITEMS[idx];
    if (!chosen) return;
    setSidebarIdx(idx);
    setDetailGame(null);
    setVideoFullscreen(false);
    setSection(chosen.id);
    setPage(1);
    setSelectedCardIdx(0);
  }, []);

  // Full controller navigation: 2D grid + continuous left scroll to prev page + L1/R1 paging
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      const lower = e.key.toLowerCase();
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        if (videoFullscreen) setVideoFullscreen(false);
        else if (detailGame) setDetailGame(null);
        else onClose();
        return;
      }

      if (detailGame) {
        if (lower === 'y' && resolvedVideoUrl) {
          e.preventDefault();
          e.stopPropagation();
          setVideoFullscreen((v) => !v);
        } else if (lower === 'x') {
          e.preventDefault();
          e.stopPropagation();
          onToggleWishlist(detailGame.id);
        }
        return;
      }

      // LB / RB (L1/R1, q/e, [/]) switch A-Z letter across ALL combined sources as one
      if (lower === 'q' || e.key === '[') {
        e.preventDefault();
        e.stopPropagation();
        setSlideDir('prev');
        setActiveLetter((cur) => stepAlphabetLetter(cur, -1));
        setPage(1);
        setSelectedCardIdx(0);
        return;
      }
      if (lower === 'e' || e.key === ']') {
        e.preventDefault();
        e.stopPropagation();
        setSlideDir('next');
        setActiveLetter((cur) => stepAlphabetLetter(cur, 1));
        setPage(1);
        setSelectedCardIdx(0);
        return;
      }

      if (focusArea === 'sidebar') {
        if (e.key === 'ArrowDown') {
          e.preventDefault();
          e.stopPropagation();
          const next = (sidebarIdx + 1) % SIDEBAR_ITEMS.length;
          activateSection(next);
        } else if (e.key === 'ArrowUp') {
          e.preventDefault();
          e.stopPropagation();
          const prev = (sidebarIdx - 1 + SIDEBAR_ITEMS.length) % SIDEBAR_ITEMS.length;
          activateSection(prev);
        } else if (e.key === 'ArrowRight') {
          e.preventDefault();
          e.stopPropagation();
          setFocusArea('grid');
          setSelectedCardIdx(0);
        } else if (e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          activateSection(sidebarIdx);
          setFocusArea('sidebar');
        }
        return;
      }

      if (focusArea === 'alphabet') {
        if (e.key === 'ArrowLeft') {
          e.preventDefault();
          e.stopPropagation();
          setActiveLetter((cur) => stepAlphabetLetter(cur, -1));
          setPage(1);
          setSelectedCardIdx(0);
        } else if (e.key === 'ArrowRight') {
          e.preventDefault();
          e.stopPropagation();
          setActiveLetter((cur) => stepAlphabetLetter(cur, 1));
          setPage(1);
          setSelectedCardIdx(0);
        } else if (e.key === 'ArrowUp' || e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          setFocusArea('grid');
        }
        return;
      }

      const visibleCount = Math.min(6, games.length);

      if (e.key === 'ArrowLeft') {
        e.preventDefault();
        e.stopPropagation();
        if (visibleCount === 0) {
          setFocusArea('sidebar');
        } else if (selectedCardIdx % 3 === 0) {
          if (page > 1) {
            setSlideDir('prev');
            setPage((p) => Math.max(1, p - 1));
            setSelectedCardIdx(Math.min(5, selectedCardIdx + 2));
          } else {
            setFocusArea('sidebar');
          }
        } else {
          setSelectedCardIdx((p) => p - 1);
        }
      } else if (e.key === 'ArrowRight' && visibleCount > 0) {
        e.preventDefault();
        e.stopPropagation();
        if (selectedCardIdx % 3 === 2 && (page < totalPages || hasMore)) {
          setSlideDir('next');
          setPage((p) => p + 1);
          setSelectedCardIdx(Math.max(0, selectedCardIdx - 2));
        } else if (selectedCardIdx + 1 < visibleCount) {
          setSelectedCardIdx((p) => p + 1);
        }
      } else if (e.key === 'ArrowDown' && visibleCount > 0) {
        e.preventDefault();
        e.stopPropagation();
        if (selectedCardIdx + 3 < visibleCount) {
          setSelectedCardIdx((p) => p + 3);
        } else {
          setFocusArea('alphabet');
        }
      } else if (e.key === 'ArrowUp' && visibleCount > 0) {
        e.preventDefault();
        e.stopPropagation();
        setSelectedCardIdx((p) => (p - 3 >= 0 ? p - 3 : p));
      } else if (lower === 'x' && games[selectedCardIdx]) {
        e.preventDefault();
        e.stopPropagation();
        onToggleWishlist(games[selectedCardIdx].id);
      } else if (e.key === 'Enter' && games[selectedCardIdx]) {
        e.preventDefault();
        e.stopPropagation();
        openDetail(games[selectedCardIdx]);
      } else if (e.key === 'PageUp' && page > 1) {
        e.preventDefault();
        e.stopPropagation();
        setSlideDir('prev');
        setPage((p) => Math.max(1, p - 1));
      } else if (e.key === 'PageDown' && (page < totalPages || hasMore)) {
        e.preventDefault();
        e.stopPropagation();
        setSlideDir('next');
        setPage((p) => p + 1);
      }
    };

    window.addEventListener('keydown', onKeyDown, true);
    return () => window.removeEventListener('keydown', onKeyDown, true);
  }, [
    activateSection,
    detailGame,
    focusArea,
    games,
    hasMore,
    onClose,
    onToggleWishlist,
    openDetail,
    page,
    resolvedVideoUrl,
    selectedCardIdx,
    sidebarIdx,
    totalPages,
    videoFullscreen,
  ]);

  const h = metrics.viewportHeight;
  const fontScale = fontScalePct / 100;
  const displayedGames = games.slice(0, 6);
  const selectedGame = displayedGames[selectedCardIdx] ?? null;
  const activeVideoUrl = resolvedVideoUrl || detailGame?.videoUrl;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Nintendo eShop"
      data-testid="eshop-view"
      className="animate-ns2-fade absolute inset-0 z-40 flex flex-col overflow-hidden select-none"
      style={{ backgroundColor: '#191A1D', color: '#F3F4F6' }}
    >
      <div className="flex-1 flex min-h-0">
        {/* Left Sidebar (No outer container border; Black bag logo on red header; Larger sidebar font) */}
        <aside
          className="flex flex-col shrink-0 h-full"
          style={{
            width: '25.5%',
            backgroundColor: '#232428',
          }}
        >
          {/* Nintendo Red Header with Black eShop Bag Logo */}
          <div
            className="flex items-center gap-2.5 px-4 shrink-0"
            style={{
              height: `${Math.max(48, Math.round(h * 0.105))}px`,
              backgroundColor: '#E60012',
              color: '#111111',
            }}
          >
            <svg
              width={Math.max(24, Math.round(h * 0.044))}
              height={Math.max(24, Math.round(h * 0.044))}
              viewBox="0 0 32 32"
              fill="none"
              aria-hidden="true"
              className="shrink-0"
            >
              <path
                d="M11.5 11V8.8a4.5 4.5 0 0 1 9 0V11"
                stroke="#111111"
                strokeWidth="2.6"
                strokeLinecap="round"
              />
              <path
                d="M6.6 11.5h18.8l1.2 13.3a2.2 2.2 0 0 1-2.2 2.4H7.6a2.2 2.2 0 0 1-2.2-2.4l1.2-13.3Z"
                stroke="#111111"
                strokeWidth="2.6"
                strokeLinejoin="round"
              />
              <path
                d="M12.2 15.2a3.8 3.8 0 0 0 7.6 0"
                stroke="#111111"
                strokeWidth="2.4"
                strokeLinecap="round"
              />
            </svg>
            <span
              className="font-ud-bold tracking-tight truncate"
              style={{ fontSize: `${Math.round(Math.max(16, h * 0.034) * fontScale)}px`, color: '#111111' }}
            >
              Nintendo eShop
            </span>
          </div>

          <nav aria-label="Nintendo eShop Categories" className="flex-1 overflow-y-auto py-2 no-scrollbar">
            {SIDEBAR_ITEMS.map((item, idx) => {
              const Icon = item.icon;
              const isActive = section === item.id;
              const isSidebarFocused = focusArea === 'sidebar' && sidebarIdx === idx;
              return (
                <div key={item.id}>
                  <button
                    type="button"
                    data-testid={`eshop-nav-${item.id}`}
                    onClick={() => {
                      activateSection(idx);
                      setFocusArea('sidebar');
                    }}
                    className="relative w-full flex items-center gap-3 px-4 py-3 text-left cursor-pointer transition-colors hover:bg-white/5 focus:outline-none"
                    style={{
                      color: isActive ? '#E60012' : '#E5E7EB',
                      backgroundColor: isSidebarFocused
                        ? 'rgba(230,0,18,0.18)'
                        : isActive
                          ? 'rgba(255,255,255,0.08)'
                          : 'transparent',
                      border: isSidebarFocused
                        ? '2.5px solid #E60012'
                        : '2.5px solid transparent',
                      fontSize: `${Math.round(Math.max(17, h * 0.032) * fontScale)}px`,
                    }}
                  >
                    {isActive && (
                      <span
                        aria-hidden="true"
                        className="absolute left-1.5 top-2 bottom-2 w-[3.5px] rounded-full"
                        style={{ backgroundColor: '#E60012' }}
                      />
                    )}
                    <Icon className="w-5 h-5 shrink-0 ml-1.5 opacity-95" />
                    <span className={isActive ? 'font-ud-bold' : 'font-ud-semibold'}>
                      {item.label}
                    </span>
                    {item.id === 'wishlist' && wishlistIds.length > 0 && (
                      <span className="ml-auto text-xs px-1.5 py-0.5 rounded bg-white/15 font-mono-tabular text-white">
                        {wishlistIds.length}
                      </span>
                    )}
                  </button>

                  {item.id === 'genres' && section === 'genres' && (
                    <div className="pl-9 pr-3 py-1.5 space-y-1 bg-black/20">
                      {GENRE_FILTERS.map((g) => {
                        const activeG = selectedGenre === g.slug;
                        return (
                          <button
                            key={g.slug}
                            type="button"
                            onClick={() => {
                              setSelectedGenre(g.slug);
                              setPage(1);
                              setFocusArea('sidebar');
                            }}
                            className={`w-full text-left px-2.5 py-1 rounded text-sm cursor-pointer focus:outline-none transition-colors ${
                              activeG ? 'font-ud-bold text-white' : 'font-ud-regular text-gray-300 hover:text-white'
                            }`}
                            style={{
                              backgroundColor: activeG ? '#E60012' : 'transparent',
                            }}
                          >
                            {g.name}
                          </button>
                        );
                      })}
                    </div>
                  )}
                </div>
              );
            })}
          </nav>
        </aside>

        {/* Right Content Pane */}
        <div
          data-scroll-container="true"
          className="flex-1 flex flex-col min-w-0 h-full px-6 pt-3 pb-2 overflow-hidden"
        >
          {detailGame ? (
            <div
              data-scroll-container="true"
              className="flex-1 flex flex-col min-h-0 overflow-y-auto no-scrollbar"
            >
              <div className="flex items-center justify-between pb-3 border-b border-white/10">
                <button
                  type="button"
                  onClick={() => {
                    setVideoFullscreen(false);
                    setDetailGame(null);
                  }}
                  className="flex items-center gap-2 text-sm font-ud-semibold text-gray-200 hover:text-white cursor-pointer"
                >
                  <ArrowLeft className="w-4 h-4" />
                  <span>Nintendo eShop</span>
                </button>
                <span className="text-xs text-gray-300 font-ud-semibold flex items-center gap-2">
                  {detailGame.sourceSite === 'switchsrom' ? (
                    <>
                      <span className="px-2 py-0.5 rounded bg-[#7C3AED] text-white font-ud-bold">SWITCHSROM</span>
                      <span>app.switchsrom.com</span>
                    </>
                  ) : detailGame.sourceSite === 'archive' ? (
                    <>
                      <span className="px-2 py-0.5 rounded bg-[#D97706] text-white font-ud-bold">
                        ARCHIVE · {detailGame.system || 'ROM'}
                      </span>
                      <span>archive.org/ultimate-rom-collection</span>
                    </>
                  ) : detailGame.sourceSite === 'vimm' ? (
                    <>
                      <span className="px-2 py-0.5 rounded bg-[#059669] text-white font-ud-bold">
                        VIMM · {detailGame.system || 'ROM'}
                      </span>
                      <span>vimm.net/vault</span>
                    </>
                  ) : detailGame.sourceSite === 'nswpedia' ? (
                    <>
                      <span className="px-2 py-0.5 rounded bg-[#E60012] text-white font-ud-bold">NS SWITCH</span>
                      <span>nswpedia.com</span>
                    </>
                  ) : (
                    <>
                      <span className="px-2 py-0.5 rounded bg-[#1C8AEB] text-white font-ud-bold">PORT</span>
                      <span>apkports.com · {detailGame.portType.toUpperCase()}</span>
                    </>
                  )}
                </span>
              </div>

              <div className="grid grid-cols-12 gap-6 py-4">
                <div className="col-span-5 space-y-3">
                  {/* Controls-Free Preview Window (click / Y opens Fullscreen) */}
                  <div
                    role={activeVideoUrl ? 'button' : undefined}
                    tabIndex={activeVideoUrl ? 0 : undefined}
                    onClick={() => {
                      if (activeVideoUrl) setVideoFullscreen(true);
                    }}
                    className={`relative aspect-video rounded-md overflow-hidden bg-black ${
                      activeVideoUrl ? 'cursor-pointer group' : ''
                    }`}
                    style={{ border: '2.5px solid #E60012' }}
                  >
                    {!videoFullscreen && activeVideoUrl ? (
                      activeVideoUrl.includes('youtube') ? (
                        <iframe
                          key={activeVideoUrl}
                          src={activeVideoUrl}
                          title={`${detailGame.title} Trailer`}
                          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen"
                          referrerPolicy="strict-origin-when-cross-origin"
                          allowFullScreen
                          className="w-full h-full border-0 pointer-events-none"
                        />
                      ) : (
                        <video
                          src={activeVideoUrl}
                          autoPlay
                          loop
                          playsInline
                          className="w-full h-full object-cover pointer-events-none"
                        />
                      )
                    ) : (
                      <img
                        src={detailGame.coverUrl}
                        alt={detailGame.title}
                        referrerPolicy="no-referrer"
                        className="w-full h-full object-cover"
                      />
                    )}
                    <div aria-hidden="true" className="absolute inset-0 z-10" />

                    {activeVideoUrl && (
                      <span className="relative z-20 absolute bottom-2 right-2 px-2.5 py-1 rounded bg-black/80 text-white text-[11px] font-ud-bold flex items-center gap-1.5">
                        <Maximize2 className="w-3.5 h-3.5" />
                        <span>Fullscreen (Y)</span>
                      </span>
                    )}
                  </div>

                  {detailGame.screenshots.length > 0 && (
                    <div className="grid grid-cols-3 gap-2">
                      {detailGame.screenshots.slice(0, 3).map((shot, idx) => (
                        <div key={idx} className="aspect-video rounded overflow-hidden bg-black/40">
                          <img
                            src={shot}
                            alt=""
                            referrerPolicy="no-referrer"
                            className="w-full h-full object-cover"
                          />
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                <div className="col-span-7 flex flex-col justify-between space-y-3">
                  <div className="space-y-2.5">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span
                        className="px-2.5 py-0.5 rounded text-[11px] font-ud-bold uppercase"
                        style={{
                          backgroundColor:
                            detailGame.sourceSite === 'switchsrom'
                              ? '#7C3AED'
                              : detailGame.sourceSite === 'archive'
                                ? '#D97706'
                                : detailGame.sourceSite === 'vimm'
                                  ? '#059669'
                                  : detailGame.sourceSite === 'nswpedia'
                                    ? '#E60012'
                                    : detailGame.portType === 'official'
                                      ? '#0891B2'
                                      : '#1C8AEB',
                          color: '#FFFFFF',
                        }}
                      >
                        {detailGame.sourceSite === 'switchsrom'
                          ? 'SwitchsROM (Switch)'
                          : detailGame.sourceSite === 'archive'
                            ? `Archive.org (${detailGame.system || 'ROM'})`
                            : detailGame.sourceSite === 'vimm'
                              ? `Vimm's Vault (${detailGame.system || 'ROM'})`
                              : detailGame.sourceSite === 'nswpedia'
                                ? 'Nintendo Switch (NS)'
                                : `${detailGame.portType} Port`}
                      </span>
                      <span className="px-2 py-0.5 rounded text-[11px] font-mono-tabular bg-white/10 text-gray-200">
                        v{detailGame.version.replace(/^v/i, '')}
                      </span>
                      {detailGame.categories.slice(0, 3).map((cat) => (
                        <span
                          key={cat}
                          className="px-2 py-0.5 rounded text-[11px] bg-white/5 text-gray-300"
                        >
                          {cat}
                        </span>
                      ))}
                    </div>

                    <h2
                      className="font-ud-bold tracking-tight"
                      style={{ fontSize: `${Math.round(Math.max(20, h * 0.044) * fontScale)}px` }}
                    >
                      {detailGame.title}
                    </h2>

                    <p
                      data-testid="eshop-detail-wiki"
                      className="font-ud-regular text-gray-200 leading-relaxed"
                      style={{ fontSize: `${Math.round(Math.max(13, h * 0.024) * fontScale)}px` }}
                    >
                      {wikiSummary ||
                        (detailLoading
                          ? 'Loading Wikipedia summary...'
                          : detailGame.description)}
                    </p>

                    {detailGame.requirements && (
                      <div className="p-2.5 rounded bg-white/5 text-xs text-gray-300">
                        <span className="font-ud-bold text-white">Compatibility: </span>
                        {detailGame.requirements}
                      </div>
                    )}
                  </div>

                  <div className="flex flex-wrap items-center gap-3 pt-2">
                    <button
                      type="button"
                      data-testid="eshop-download-page"
                      onClick={() =>
                        onOpenDownloadPage(
                          detailGame.pageUrl || detailGame.downloadUrl || detailGame.sourceUrl
                        )
                      }
                      className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-xs font-ud-bold text-white cursor-pointer hover:opacity-90"
                      style={{ backgroundColor: '#E60012' }}
                    >
                      <Download className="w-4 h-4" />
                      <span>Download (Open Website)</span>
                    </button>

                    <button
                      type="button"
                      data-testid="eshop-wishlist-btn"
                      onClick={() => onToggleWishlist(detailGame.id)}
                      className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-xs font-ud-semibold border border-white/25 hover:bg-white/10 cursor-pointer"
                    >
                      <Star
                        className={`w-4 h-4 ${
                          wishlistIds.includes(detailGame.id)
                            ? 'fill-amber-400 text-amber-400'
                            : 'text-gray-200'
                        }`}
                      />
                      <span>
                        {wishlistIds.includes(detailGame.id)
                          ? 'In Wish List'
                          : 'Add to Wish List'}
                      </span>
                    </button>

                    <button
                      type="button"
                      data-testid="eshop-install-home"
                      onClick={() => onInstallToHome(detailGame, detailGame)}
                      disabled={installedSlugs.includes(detailGame.slug)}
                      className="px-4 py-2.5 rounded-lg text-xs font-ud-semibold bg-white/10 hover:bg-white/15 text-gray-100 cursor-pointer disabled:opacity-50"
                    >
                      {installedSlugs.includes(detailGame.slug)
                        ? 'Added to Home'
                        : 'Pin to Home'}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <>
              <div className="flex items-center justify-between shrink-0 mb-2 gap-3">
                <div className="flex items-center gap-2.5 min-w-0">
                  <div
                    className="font-ud-semibold text-gray-100 truncate"
                    style={{ fontSize: `${Math.round(Math.max(13, h * 0.025) * fontScale)}px` }}
                  >
                    {SIDEBAR_ITEMS.find((s) => s.id === section)?.label}
                    {section === 'genres' ? ` · ${GENRE_FILTERS.find((g) => g.slug === selectedGenre)?.name}` : ''}
                    {activeLetter !== 'All' ? ` · Letter "${activeLetter}"` : ''}
                  </div>
                  <span className="px-2 py-0.5 rounded bg-white/10 text-[11px] font-mono-tabular text-gray-300 shrink-0">
                    {totalCount} Titles (All Sources Unified)
                  </span>
                </div>

                <button
                  type="button"
                  onClick={onOpenUserSelect}
                  aria-label={`Active user ${activeUser.name}`}
                  className="rounded-full overflow-hidden shrink-0 cursor-pointer hover:scale-105 transition-transform"
                >
                  <UiKitAvatar
                    characterId={activeUser.characterId}
                    size={Math.max(32, Math.round(h * 0.056))}
                    roundedClass="rounded-full"
                    alt={activeUser.name}
                  />
                </button>
              </div>

              <div className="flex-1 min-h-0 flex items-center justify-center">
                {loading && games.length === 0 ? (
                  <div className="grid grid-cols-3 gap-3.5 w-full">
                    {Array.from({ length: 6 }).map((_, i) => (
                      <div
                        key={i}
                        className="rounded overflow-hidden bg-[#26282E]/80"
                        style={{ height: `${Math.round(h * 0.245)}px` }}
                      />
                    ))}
                  </div>
                ) : displayedGames.length === 0 ? (
                  <div className="text-center space-y-2 text-gray-400 text-sm">
                    <LayoutGrid className="w-8 h-8 mx-auto opacity-50" />
                    <div>
                      {section === 'wishlist'
                        ? 'Your Wish List is empty. Press (X) on any game to star it.'
                        : `No matching games found${activeLetter !== 'All' ? ` under "${activeLetter}"` : ''}.`}
                    </div>
                  </div>
                ) : (
                  <div
                    key={`${section}-${page}-${selectedGenre}-${activeLetter}`}
                    data-testid="eshop-grid"
                    className={`grid grid-cols-3 gap-3.5 w-full ${
                      slideDir === 'next'
                        ? 'animate-eshop-next'
                        : slideDir === 'prev'
                          ? 'animate-eshop-prev'
                          : ''
                    }`}
                  >
                    {displayedGames.map((item, idx) => {
                      const isFocused = focusArea === 'grid' && selectedCardIdx === idx;
                      const isWished = wishlistIds.includes(item.id);
                      const isInstalled = installedSlugs.includes(item.slug);
                      const isNsw = item.sourceSite === 'nswpedia' || item.slug.startsWith('nsw-');
                      const isSwitchsrom = item.sourceSite === 'switchsrom' || item.slug.startsWith('swr-');
                      const isVimm = item.sourceSite === 'vimm' || item.slug.startsWith('vimm-');
                      const isArchive = item.sourceSite === 'archive' || item.slug.startsWith('archive-');
                      const sourceBadgeBg = isSwitchsrom
                        ? '#7C3AED'
                        : isArchive
                          ? '#D97706'
                          : isVimm
                            ? '#059669'
                            : isNsw
                              ? '#E60012'
                              : '#1C8AEB';
                      const sourceBadgeLabel = isSwitchsrom
                        ? 'SWITCHSROM'
                        : isArchive
                          ? `ARCHIVE · ${item.system || 'ROM'}`
                          : isVimm
                            ? `VIMM · ${item.system || 'ROM'}`
                            : isNsw
                              ? 'NS SWITCH'
                              : 'PORT';
                      const pillRightText = isSwitchsrom
                        ? 'NS'
                        : isArchive || isVimm
                          ? item.system || 'ROM'
                          : isNsw
                            ? 'NS'
                            : `v${item.version.replace(/^v/i, '')}`;
                      return (
                        <button
                          key={item.id}
                          type="button"
                          data-testid={`eshop-card-${idx}`}
                          onMouseEnter={() => {
                            setFocusArea('grid');
                            setSelectedCardIdx(idx);
                          }}
                          onClick={() => openDetail(item)}
                          className="relative flex flex-col overflow-hidden text-left cursor-pointer focus:outline-none transition-transform duration-150"
                          style={{
                            borderRadius: '6px',
                            backgroundColor: '#26282E',
                          }}
                        >
                          {isFocused && (
                            <span
                              aria-hidden="true"
                              data-testid={`eshop-focus-ring-${idx}`}
                              className="pointer-events-none absolute inset-0 z-30"
                              style={{
                                borderRadius: '6px',
                                border: '4px solid #E60012',
                              }}
                            />
                          )}

                          <div className="relative w-full aspect-video overflow-hidden bg-black/50 z-10">
                            <img
                              src={item.coverUrl}
                              alt={item.title}
                              referrerPolicy="no-referrer"
                              className="w-full h-full object-cover block"
                            />

                            {/* Source Site Badge */}
                            <span
                              className="absolute top-1.5 right-1.5 px-1.5 py-0.5 text-[9px] font-ud-bold uppercase rounded-xs flex items-center gap-1"
                              style={{
                                backgroundColor: sourceBadgeBg,
                                color: '#FFFFFF',
                              }}
                            >
                              {sourceBadgeLabel}
                            </span>

                            <span className="absolute bottom-1.5 right-1.5 px-1.5 py-0.5 text-[9px] font-ud-regular rounded-xs bg-black/75 text-gray-100">
                              {isInstalled ? 'Home' : item.categories[0] || item.system || 'Game'}
                            </span>

                            {isWished && (
                              <span className="absolute top-1.5 left-1.5 rounded-full p-1 bg-black/70">
                                <Star className="w-3.5 h-3.5 text-amber-400 fill-amber-400" />
                              </span>
                            )}
                          </div>

                          <div className="px-2.5 py-1.5 bg-[#202227] flex items-center justify-between gap-2 z-10">
                            <div className="text-xs font-ud-semibold text-gray-100 truncate">
                              {item.title}
                            </div>
                            <span
                              className="px-1.5 py-0.5 text-[10px] font-ud-bold rounded-xs tabular-nums shrink-0"
                              style={{ backgroundColor: sourceBadgeBg, color: '#FFFFFF' }}
                            >
                              {pillRightText}
                            </span>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>

              {/* A-Z Alphabet Bar BELOW Games (LB / RB switches letter across all combined sources) */}
              <div
                data-testid="eshop-alphabet-bar"
                className="shrink-0 mt-1.5 pt-1.5 pb-0.5 flex items-center gap-1.5"
                style={{
                  borderTop: '1px solid rgba(255,255,255,0.08)',
                  outline: focusArea === 'alphabet' ? '2px solid #E60012' : 'none',
                  borderRadius: '8px',
                }}
              >
                <button
                  type="button"
                  onClick={() => {
                    setActiveLetter((cur) => stepAlphabetLetter(cur, -1));
                    setPage(1);
                    setSelectedCardIdx(0);
                  }}
                  title="Previous Letter (LB)"
                  className="flex items-center gap-1 px-1.5 py-1 rounded bg-white/10 hover:bg-white/20 text-[10px] font-ud-bold text-gray-200 cursor-pointer shrink-0"
                >
                  <SwitchPdfIcon button="L1" size={16} fillColor="#FFFFFF" cutoutColor="#191A1D" />
                </button>

                <div className="flex-1 flex items-center justify-between gap-0.5 overflow-x-auto no-scrollbar">
                  {ESHOP_ALPHABET_LETTERS.map((ltr) => {
                    const isSel = activeLetter === ltr;
                    return (
                      <button
                        key={ltr}
                        type="button"
                        data-testid={`eshop-letter-${ltr}`}
                        onClick={() => {
                          setActiveLetter(ltr);
                          setPage(1);
                          setSelectedCardIdx(0);
                        }}
                        className="px-1.5 py-0.5 rounded text-[11px] font-ud-bold cursor-pointer focus:outline-none transition-colors shrink-0"
                        style={{
                          backgroundColor: isSel ? '#E60012' : 'transparent',
                          color: isSel ? '#FFFFFF' : '#9CA3AF',
                        }}
                      >
                        {ltr}
                      </button>
                    );
                  })}
                </div>

                <button
                  type="button"
                  onClick={() => {
                    setActiveLetter((cur) => stepAlphabetLetter(cur, 1));
                    setPage(1);
                    setSelectedCardIdx(0);
                  }}
                  title="Next Letter (RB)"
                  className="flex items-center gap-1 px-1.5 py-1 rounded bg-white/10 hover:bg-white/20 text-[10px] font-ud-bold text-gray-200 cursor-pointer shrink-0"
                >
                  <SwitchPdfIcon button="R1" size={16} fillColor="#FFFFFF" cutoutColor="#191A1D" />
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Bottom Controller Help Bar */}
      <footer
        className="flex items-center justify-between px-6 shrink-0"
        style={{
          height: `${Math.max(40, Math.round(h * 0.085))}px`,
          backgroundColor: '#191A1D',
          borderTop: '1px solid rgba(255,255,255,0.08)',
        }}
      >
        <div className="flex items-center gap-4">
          <BottomControllerGlyph size={metrics.helpIconSize} color="#E5E7EB" />
          {!detailGame && (
            <div className="flex items-center gap-2 text-xs text-gray-200 font-ud-semibold">
              <button
                type="button"
                data-testid="eshop-prev-page"
                disabled={page <= 1}
                onClick={() => {
                  setSlideDir('prev');
                  setPage((p) => Math.max(1, p - 1));
                }}
                aria-label="Previous page"
                className="flex items-center gap-1 px-2 py-1 rounded bg-white/5 hover:bg-white/15 disabled:opacity-35 cursor-pointer"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
                <span>Prev</span>
              </button>
              <span data-testid="eshop-page-indicator" className="font-mono-tabular text-gray-300 px-1">
                Page {page} / {totalPages}
                {hasMore && page >= totalPages ? '+' : ''}
              </span>
              <button
                type="button"
                data-testid="eshop-next-page"
                disabled={page >= totalPages && !hasMore}
                onClick={() => {
                  setSlideDir('next');
                  setPage((p) => p + 1);
                }}
                aria-label="Next page"
                className="flex items-center gap-1 px-2 py-1 rounded bg-white/5 hover:bg-white/15 disabled:opacity-35 cursor-pointer"
              >
                <span>Next</span>
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          )}
        </div>

        <div className="flex items-center gap-5 text-xs font-ud-semibold text-gray-100">
          {selectedGame && !detailGame && (
            <button
              type="button"
              onClick={() => onToggleWishlist(selectedGame.id)}
              className="flex items-center gap-1.5 cursor-pointer hover:opacity-80"
            >
              <SwitchPdfIcon button="X" size={18} fillColor="#FFFFFF" cutoutColor="#191A1D" />
              <Star className="w-3.5 h-3.5 text-amber-400 fill-amber-400" />
              <span>Wish List</span>
            </button>
          )}
          <button
            type="button"
            onClick={() => {
              if (videoFullscreen) setVideoFullscreen(false);
              else if (detailGame) setDetailGame(null);
              else onClose();
            }}
            className="flex items-center gap-1.5 cursor-pointer hover:opacity-80"
          >
            <SwitchPdfIcon button="B" size={18} fillColor="#FFFFFF" cutoutColor="#191A1D" />
            <span>Back</span>
          </button>
          {selectedGame && !detailGame && (
            <button
              type="button"
              onClick={() => openDetail(selectedGame)}
              className="flex items-center gap-1.5 cursor-pointer hover:opacity-80"
            >
              <SwitchPdfIcon button="A" size={18} fillColor="#FFFFFF" cutoutColor="#191A1D" />
              <span>Open</span>
            </button>
          )}
        </div>
      </footer>

      {/* Fullscreen Video Overlay */}
      {videoFullscreen && detailGame && activeVideoUrl && (
        <div
          data-testid="eshop-video-fullscreen"
          className="absolute inset-0 z-50 bg-black flex flex-col"
        >
          <div className="flex items-center justify-between px-5 py-3 bg-black/80 text-white">
            <span className="font-ud-bold text-sm">{detailGame.title}</span>
            <button
              type="button"
              onClick={() => setVideoFullscreen(false)}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded bg-white/15 hover:bg-white/25 text-xs font-ud-semibold cursor-pointer"
            >
              <Minimize2 className="w-3.5 h-3.5" />
              <span>Exit Fullscreen (B)</span>
            </button>
          </div>
          <div className="flex-1 min-h-0">
            {activeVideoUrl.includes('youtube') ? (
              <iframe
                src={activeVideoUrl.replace('controls=0', 'controls=1').replace('disablekb=1', 'disablekb=0')}
                title={detailGame.title}
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen"
                referrerPolicy="strict-origin-when-cross-origin"
                allowFullScreen
                className="w-full h-full border-0"
              />
            ) : (
              <video
                src={activeVideoUrl}
                controls
                autoPlay
                className="w-full h-full object-contain bg-black"
              />
            )}
          </div>
        </div>
      )}
    </div>
  );
}
