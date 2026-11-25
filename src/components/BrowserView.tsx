import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ChevronLeft,
  ChevronRight,
  ExternalLink,
  Film,
  Flame,
  Loader2,
  Minimize2,
  Pause,
  Play,
  Search,
  Sparkles,
  Star,
  Tv,
  Youtube,
} from 'lucide-react';
import type { AdaptivePalette, LaMovieMediaItem } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { ESHOP_ALPHABET_LETTERS, stepAlphabetLetter } from '../utils/eshopHelpers';
import { filterAndPaginateLaMovieCatalog, LAMOVIE_FALLBACK_ITEMS } from '../utils/lamovieParser';
import { BottomControllerGlyph } from './BottomControllerGlyph';
import { SwitchPdfIcon } from './SwitchPdfIcons';

interface BrowserViewProps {
  initialUrl?: string;
  palette: AdaptivePalette;
  metrics: Switch2LayoutMetrics;
  onClose: () => void;
}

type NetflixTab = 'forMe' | 'favorites' | 'movies' | 'series' | 'categories' | 'youtube' | 'search';
type DetailFocusZone = 'preview' | 'fullscreen' | 'favorite' | 'back';

const FAVORITES_STORAGE_KEY = 'skyline2_netflix_favorites_v2';
const PAGE_SIZE = 20;

const GENRE_FILTERS = [
  { id: 'all', label: 'Todo' },
  { id: 'acción', label: 'Acción' },
  { id: 'aventura', label: 'Aventura' },
  { id: 'animación', label: 'Animación' },
  { id: 'comedia', label: 'Comedia' },
  { id: 'drama', label: 'Drama' },
  { id: 'terror', label: 'Terror' },
  { id: 'ciencia ficción', label: 'Sci-Fi' },
  { id: 'romance', label: 'Romance' },
  { id: 'suspense', label: 'Suspense' },
];

const NETFLIX_TABS: { id: NetflixTab; label: string }[] = [
  { id: 'forMe', label: 'For Me' },
  { id: 'favorites', label: 'Favorites' },
  { id: 'movies', label: 'Movies' },
  { id: 'series', label: 'Series' },
  { id: 'categories', label: 'Categories' },
  { id: 'youtube', label: 'YouTube' },
];

interface EpisodeItem {
  _id: number;
  title: string;
  overview?: string;
}

interface EmbedSource {
  url: string;
  server?: string;
  quality?: string;
  language?: string;
}

function loadSavedMediaFavorites(): LaMovieMediaItem[] {
  try {
    const raw = localStorage.getItem(FAVORITES_STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter((x) => x && typeof x.id === 'string' && typeof x.title === 'string');
  } catch {
    return [];
  }
}

export function BrowserView({
  initialUrl,
  metrics,
  onClose,
}: BrowserViewProps) {
  const [activeTab, setActiveTab] = useState<NetflixTab>('forMe');
  const [activeGenre, setActiveGenre] = useState<string>('all');
  const [activeLetter, setActiveLetter] = useState<string>('All');
  const [searchDraft, setSearchDraft] = useState<string>('');
  const [committedQuery, setCommittedQuery] = useState<string>('');
  const [items, setItems] = useState<LaMovieMediaItem[]>(LAMOVIE_FALLBACK_ITEMS);
  const [loading, setLoading] = useState<boolean>(true);
  const [page, setPage] = useState<number>(1);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [totalCount, setTotalCount] = useState<number>(LAMOVIE_FALLBACK_ITEMS.length);
  const [hasMore, setHasMore] = useState<boolean>(true);
  const [focusZone, setFocusZone] = useState<'tabs' | 'genres' | 'grid' | 'alphabet'>('grid');
  const [focusedIdx, setFocusedIdx] = useState<number>(0);

  const [favorites, setFavorites] = useState<LaMovieMediaItem[]>(loadSavedMediaFavorites);
  const [selectedItem, setSelectedItem] = useState<LaMovieMediaItem | null>(null);
  const [previewEmbedUrl, setPreviewEmbedUrl] = useState<string>('');
  const [previewPlaying, setPreviewPlaying] = useState<boolean>(true);
  const [playEmbedUrl, setPlayEmbedUrl] = useState<string>('');
  const [episodes, setEpisodes] = useState<EpisodeItem[]>([]);
  const [activeEpisodeId, setActiveEpisodeId] = useState<number | null>(null);
  const [embeds, setEmbeds] = useState<EmbedSource[]>([]);
  const [selectedEmbedIdx, setSelectedEmbedIdx] = useState<number>(0);
  const [detailLoading, setDetailLoading] = useState<boolean>(false);
  const [detailFocusZone, setDetailFocusZone] = useState<DetailFocusZone>('fullscreen');
  const [fullscreenPlayerOpen, setFullscreenPlayerOpen] = useState<boolean>(false);

  const searchInputRef = useRef<HTMLInputElement>(null);
  const reqIdRef = useRef(0);
  const detailReqIdRef = useRef(0);

  const hasExternalBanner = useMemo(() => {
    if (!initialUrl) return false;
    const lower = initialUrl.toLowerCase();
    return lower.startsWith('http') && !lower.includes('nintendo.com') && !lower.includes('lamovie.org');
  }, [initialUrl]);

  const fetchCatalog = useCallback(
    async (tab: NetflixTab, genre: string, letter: string, q: string, pageNum: number) => {
      const reqId = ++reqIdRef.current;
      if (tab === 'favorites') {
        const pagedFavs = filterAndPaginateLaMovieCatalog(favorites, {
          letter,
          q,
          page: pageNum,
          pageSize: PAGE_SIZE,
        });
        setItems(pagedFavs.items);
        setTotalPages(pagedFavs.totalPages);
        setTotalCount(pagedFavs.totalCount);
        setHasMore(pagedFavs.page < pagedFavs.totalPages);
        setLoading(false);
        setFocusedIdx(0);
        return;
      }

      setLoading(true);
      try {
        if (tab === 'youtube') {
          const ytQuery = q.trim() || 'Nintendo Switch 2 gameplay trailers movies';
          const res = await fetch(`/api/youtube/feed?q=${encodeURIComponent(ytQuery)}`);
          const json = (await res.json()) as { items?: LaMovieMediaItem[] };
          if (reqId !== reqIdRef.current) return;
          const rawYt = Array.isArray(json.items) ? json.items : [];
          const pagedYt = filterAndPaginateLaMovieCatalog(rawYt, {
            letter,
            page: pageNum,
            pageSize: PAGE_SIZE,
          });
          setItems(pagedYt.items);
          setTotalPages(pagedYt.totalPages);
          setTotalCount(pagedYt.totalCount);
          setHasMore(pagedYt.page < pagedYt.totalPages);
        } else if (tab === 'search' && q.trim()) {
          const [lmRes, ytRes] = await Promise.all([
            fetch(
              `/api/lamovie/catalog?section=search&q=${encodeURIComponent(q.trim())}&letter=${encodeURIComponent(letter)}&limit=${PAGE_SIZE}&page=${pageNum}`
            )
              .then((r) => r.json())
              .catch(() => ({ items: [] })),
            fetch(`/api/youtube/feed?q=${encodeURIComponent(q.trim())}`)
              .then((r) => r.json())
              .catch(() => ({ items: [] })),
          ]);
          if (reqId !== reqIdRef.current) return;
          const lmItems = Array.isArray(lmRes.items) ? (lmRes.items as LaMovieMediaItem[]) : [];
          const ytItems = Array.isArray(ytRes.items) ? (ytRes.items as LaMovieMediaItem[]) : [];
          const combined = [...lmItems, ...ytItems];
          const pagedSearch = filterAndPaginateLaMovieCatalog(combined, {
            letter,
            page: pageNum,
            pageSize: PAGE_SIZE,
          });
          setItems(pagedSearch.items);
          setTotalPages(pagedSearch.totalPages);
          setTotalCount(pagedSearch.totalCount);
          setHasMore(pagedSearch.page < pagedSearch.totalPages);
        } else {
          const sp = new URLSearchParams();
          sp.set('section', tab === 'categories' ? 'forMe' : tab);
          sp.set('page', String(pageNum));
          sp.set('limit', String(PAGE_SIZE));
          sp.set('letter', letter);
          if (genre && genre !== 'all') sp.set('genre', genre);
          const res = await fetch(`/api/lamovie/catalog?${sp.toString()}`);
          const json = (await res.json()) as {
            items?: LaMovieMediaItem[];
            totalPages?: number;
            totalCount?: number;
            hasMore?: boolean;
          };
          if (reqId !== reqIdRef.current) return;
          const nextItems = Array.isArray(json.items) ? json.items : [];
          setItems(nextItems);
          setTotalPages(Math.max(1, Number(json.totalPages || 1)));
          setTotalCount(Number(json.totalCount ?? nextItems.length));
          setHasMore(Boolean(json.hasMore));
        }
      } catch {
        if (reqId === reqIdRef.current) {
          const fb = filterAndPaginateLaMovieCatalog(LAMOVIE_FALLBACK_ITEMS, {
            letter,
            genre,
            page: pageNum,
            pageSize: PAGE_SIZE,
          });
          setItems(fb.items);
          setTotalPages(fb.totalPages);
          setTotalCount(fb.totalCount);
          setHasMore(false);
        }
      } finally {
        if (reqId === reqIdRef.current) {
          setLoading(false);
          setFocusedIdx(0);
        }
      }
    },
    [favorites]
  );

  useEffect(() => {
    fetchCatalog(activeTab, activeGenre, activeLetter, committedQuery, page);
  }, [activeTab, activeGenre, activeLetter, committedQuery, page, fetchCatalog]);

  const persistFavorites = useCallback((next: LaMovieMediaItem[]) => {
    setFavorites(next);
    try {
      localStorage.setItem(FAVORITES_STORAGE_KEY, JSON.stringify(next));
    } catch {
      // Ignore quota issues
    }
  }, []);

  const isFavoriteItem = useCallback(
    (item: LaMovieMediaItem) => favorites.some((f) => f.id === item.id),
    [favorites]
  );

  const toggleFavorite = useCallback(
    (item: LaMovieMediaItem) => {
      const exists = favorites.some((f) => f.id === item.id);
      const next = exists ? favorites.filter((f) => f.id !== item.id) : [item, ...favorites];
      persistFavorites(next);
    },
    [favorites, persistFavorites]
  );

  const enterFullscreen = useCallback(() => {
    setPreviewPlaying(false);
    setFullscreenPlayerOpen(true);
  }, []);

  const togglePreviewPlayback = useCallback(() => {
    setPreviewPlaying((p) => !p);
  }, []);

  const openPreview = useCallback(async (item: LaMovieMediaItem) => {
    const reqId = ++detailReqIdRef.current;
    setSelectedItem(item);
    setFullscreenPlayerOpen(false);
    setPreviewPlaying(true);
    setDetailFocusZone('fullscreen');
    setEpisodes([]);
    setActiveEpisodeId(null);
    setEmbeds([]);
    setSelectedEmbedIdx(0);

    if (item.mediaType === 'youtube') {
      const baseId = item.slug;
      const previewUrl =
        item.previewEmbedUrl ||
        `https://www.youtube.com/embed/${baseId}?autoplay=1&mute=0&controls=0&disablekb=1&fs=0&modestbranding=1&iv_load_policy=3&playsinline=1&rel=0`;
      const fullUrl =
        item.embedUrl ||
        `https://www.youtube.com/embed/${baseId}?autoplay=1&mute=0&playsinline=1&rel=0`;
      setPreviewEmbedUrl(previewUrl);
      setPlayEmbedUrl(fullUrl);
      setDetailLoading(false);
      return;
    }

    setPreviewEmbedUrl('');
    setPlayEmbedUrl('');
    setDetailLoading(true);

    const ytPromise = fetch(`/api/youtube/search?q=${encodeURIComponent(`${item.title} official trailer`)}`)
      .then((r) => (r.ok ? r.json() : null))
      .catch(() => null) as Promise<{ videoId?: string } | null>;

    const detailPromise = fetch(
      `/api/lamovie/detail?id=${encodeURIComponent(String(item.postId))}&slug=${encodeURIComponent(item.slug)}&type=${item.mediaType}`
    )
      .then((r) => (r.ok ? r.json() : null))
      .catch(() => null) as Promise<{
      overview?: string;
      trailer?: string;
      embeds?: EmbedSource[];
      episodes?: EpisodeItem[];
      embedUrl?: string;
    } | null>;

    const [ytData, lmData] = await Promise.all([ytPromise, detailPromise]);
    if (reqId !== detailReqIdRef.current) return;

    setSelectedItem((cur) => {
      if (!cur || cur.id !== item.id) return cur;
      return {
        ...cur,
        overview: lmData?.overview || cur.overview,
      };
    });

    if (lmData?.episodes && lmData.episodes.length > 0) {
      setEpisodes(lmData.episodes);
      setActiveEpisodeId(lmData.episodes[0]._id);
    }

    const hasRealEmbeds = Boolean((lmData?.embeds && lmData.embeds.length > 0) || lmData?.embedUrl);
    if (lmData?.embeds && lmData.embeds.length > 0) {
      setEmbeds(lmData.embeds);
      setPlayEmbedUrl(lmData.embeds[0].url);
    } else if (lmData?.embedUrl) {
      setPlayEmbedUrl(lmData.embedUrl);
    }

    const ytFromTrailer = lmData?.trailer?.match(/[?&]v=([A-Za-z0-9_-]{11})/)?.[1] || ytData?.videoId;
    if (ytFromTrailer) {
      setPreviewEmbedUrl(
        `https://www.youtube.com/embed/${ytFromTrailer}?autoplay=1&mute=0&controls=0&disablekb=1&fs=0&modestbranding=1&iv_load_policy=3&playsinline=1&rel=0`
      );
      if (!hasRealEmbeds) {
        setPlayEmbedUrl(item.pageUrl || `https://www.youtube.com/embed/${ytFromTrailer}?autoplay=1&mute=0&playsinline=1&rel=0`);
      }
    } else if (!hasRealEmbeds) {
      setPlayEmbedUrl(item.pageUrl);
    }

    setDetailLoading(false);
  }, []);

  const loadEpisodePlayer = useCallback(async (epId: number, andLaunchFullscreen = false) => {
    setActiveEpisodeId(epId);
    setDetailLoading(true);
    try {
      const res = await fetch(`/api/lamovie/detail?id=${epId}&type=movies`);
      if (res.ok) {
        const data = (await res.json()) as { embeds?: EmbedSource[]; embedUrl?: string };
        if (data.embeds && data.embeds.length > 0) {
          setEmbeds(data.embeds);
          setSelectedEmbedIdx(0);
          setPlayEmbedUrl(data.embeds[0].url);
        } else if (data.embedUrl) {
          setPlayEmbedUrl(data.embedUrl);
        }
      }
      if (andLaunchFullscreen) {
        setPreviewPlaying(false);
        setFullscreenPlayerOpen(true);
      }
    } catch {
      // keep existing
    } finally {
      setDetailLoading(false);
    }
  }, []);

  const submitSearch = useCallback(
    (e?: React.FormEvent) => {
      if (e) e.preventDefault();
      const q = searchDraft.trim();
      if (!q) return;
      setCommittedQuery(q);
      setActiveTab('search');
      setSelectedItem(null);
      setFullscreenPlayerOpen(false);
      setPage(1);
      setFocusZone('grid');
      searchInputRef.current?.blur();
    },
    [searchDraft]
  );

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      if (target && target.tagName === 'INPUT') {
        if (e.key === 'Escape') {
          e.preventDefault();
          target.blur();
        }
        return;
      }

      const lower = e.key.toLowerCase();
      if (e.key === 'Escape' || e.key === 'Backspace') {
        e.preventDefault();
        e.stopPropagation();
        if (fullscreenPlayerOpen) setFullscreenPlayerOpen(false);
        else if (selectedItem) {
          setSelectedItem(null);
          setPreviewPlaying(false);
        } else onClose();
        return;
      }

      if (lower === 'f') {
        e.preventDefault();
        e.stopPropagation();
        searchInputRef.current?.focus();
        return;
      }

      if (selectedItem) {
        if (fullscreenPlayerOpen) {
          return;
        }
        if (lower === 'x') {
          e.preventDefault();
          e.stopPropagation();
          toggleFavorite(selectedItem);
          return;
        }
        if (lower === 'p') {
          e.preventDefault();
          e.stopPropagation();
          togglePreviewPlayback();
          return;
        }
        if (e.key === 'ArrowUp') {
          e.preventDefault();
          e.stopPropagation();
          setDetailFocusZone('preview');
          return;
        }
        if (e.key === 'ArrowDown') {
          e.preventDefault();
          e.stopPropagation();
          if (detailFocusZone === 'preview') setDetailFocusZone('fullscreen');
          return;
        }
        if (e.key === 'ArrowLeft') {
          e.preventDefault();
          e.stopPropagation();
          const btnOrder: DetailFocusZone[] = ['fullscreen', 'favorite', 'back'];
          const idx = btnOrder.indexOf(detailFocusZone);
          if (idx > 0) setDetailFocusZone(btnOrder[idx - 1]);
          else setDetailFocusZone('preview');
          return;
        }
        if (e.key === 'ArrowRight') {
          e.preventDefault();
          e.stopPropagation();
          const btnOrder: DetailFocusZone[] = ['preview', 'fullscreen', 'favorite', 'back'];
          const idx = btnOrder.indexOf(detailFocusZone);
          setDetailFocusZone(btnOrder[(idx + 1) % btnOrder.length]);
          return;
        }
        if (e.key === 'Enter' || lower === 'a') {
          e.preventDefault();
          e.stopPropagation();
          if (detailFocusZone === 'preview') {
            togglePreviewPlayback();
          } else if (detailFocusZone === 'favorite') {
            toggleFavorite(selectedItem);
          } else if (detailFocusZone === 'back') {
            setSelectedItem(null);
            setPreviewPlaying(false);
          } else {
            enterFullscreen();
          }
          return;
        }
        return;
      }

      if (lower === 'q' || e.key === '[') {
        e.preventDefault();
        e.stopPropagation();
        setActiveLetter((cur) => stepAlphabetLetter(cur, -1));
        setPage(1);
        setFocusedIdx(0);
        return;
      }
      if (lower === 'e' || e.key === ']') {
        e.preventDefault();
        e.stopPropagation();
        setActiveLetter((cur) => stepAlphabetLetter(cur, 1));
        setPage(1);
        setFocusedIdx(0);
        return;
      }

      if (e.key === 'PageUp' && page > 1) {
        e.preventDefault();
        e.stopPropagation();
        setPage((p) => Math.max(1, p - 1));
        return;
      }
      if (e.key === 'PageDown' && (page < totalPages || hasMore)) {
        e.preventDefault();
        e.stopPropagation();
        setPage((p) => p + 1);
        return;
      }

      const cols = 4;
      if (focusZone === 'tabs') {
        if (e.key === 'ArrowRight') {
          e.preventDefault();
          e.stopPropagation();
          const idx = NETFLIX_TABS.findIndex((t) => t.id === activeTab);
          const next = NETFLIX_TABS[(Math.max(0, idx) + 1) % NETFLIX_TABS.length];
          setActiveTab(next.id);
          setPage(1);
        } else if (e.key === 'ArrowLeft') {
          e.preventDefault();
          e.stopPropagation();
          const idx = NETFLIX_TABS.findIndex((t) => t.id === activeTab);
          const prev = NETFLIX_TABS[(Math.max(0, idx) - 1 + NETFLIX_TABS.length) % NETFLIX_TABS.length];
          setActiveTab(prev.id);
          setPage(1);
        } else if (e.key === 'ArrowDown' || e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          setFocusZone(activeTab === 'categories' ? 'genres' : 'grid');
        }
        return;
      }

      if (focusZone === 'genres') {
        const gIdx = GENRE_FILTERS.findIndex((g) => g.id === activeGenre);
        if (e.key === 'ArrowRight') {
          e.preventDefault();
          e.stopPropagation();
          setActiveGenre(GENRE_FILTERS[(Math.max(0, gIdx) + 1) % GENRE_FILTERS.length].id);
          setPage(1);
        } else if (e.key === 'ArrowLeft') {
          e.preventDefault();
          e.stopPropagation();
          setActiveGenre(
            GENRE_FILTERS[(Math.max(0, gIdx) - 1 + GENRE_FILTERS.length) % GENRE_FILTERS.length].id
          );
          setPage(1);
        } else if (e.key === 'ArrowUp') {
          e.preventDefault();
          e.stopPropagation();
          setFocusZone('tabs');
        } else if (e.key === 'ArrowDown' || e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          setFocusZone('grid');
        }
        return;
      }

      if (focusZone === 'alphabet') {
        if (e.key === 'ArrowLeft') {
          e.preventDefault();
          e.stopPropagation();
          setActiveLetter((cur) => stepAlphabetLetter(cur, -1));
          setPage(1);
          setFocusedIdx(0);
        } else if (e.key === 'ArrowRight') {
          e.preventDefault();
          e.stopPropagation();
          setActiveLetter((cur) => stepAlphabetLetter(cur, 1));
          setPage(1);
          setFocusedIdx(0);
        } else if (e.key === 'ArrowUp' || e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          setFocusZone('grid');
        }
        return;
      }

      if (e.key === 'ArrowRight' && items.length > 0) {
        e.preventDefault();
        e.stopPropagation();
        if (focusedIdx % cols === cols - 1 && (page < totalPages || hasMore)) {
          setPage((p) => p + 1);
          setFocusedIdx(Math.max(0, focusedIdx - (cols - 1)));
        } else {
          setFocusedIdx((p) => (p + 1 < items.length ? p + 1 : 0));
        }
      } else if (e.key === 'ArrowLeft' && items.length > 0) {
        e.preventDefault();
        e.stopPropagation();
        if (focusedIdx % cols === 0 && page > 1) {
          setPage((p) => Math.max(1, p - 1));
          setFocusedIdx(Math.min(items.length - 1, focusedIdx + (cols - 1)));
        } else {
          setFocusedIdx((p) => (p - 1 >= 0 ? p - 1 : items.length - 1));
        }
      } else if (e.key === 'ArrowDown' && items.length > 0) {
        e.preventDefault();
        e.stopPropagation();
        if (focusedIdx + cols < items.length) {
          setFocusedIdx((p) => p + cols);
        } else {
          setFocusZone('alphabet');
        }
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        e.stopPropagation();
        if (focusedIdx - cols >= 0) {
          setFocusedIdx((p) => p - cols);
        } else {
          setFocusZone(activeTab === 'categories' ? 'genres' : 'tabs');
        }
      } else if (e.key === 'Enter' && items[focusedIdx]) {
        e.preventDefault();
        e.stopPropagation();
        openPreview(items[focusedIdx]);
      }
    };

    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [
    activeGenre,
    activeTab,
    detailFocusZone,
    enterFullscreen,
    focusZone,
    focusedIdx,
    fullscreenPlayerOpen,
    hasMore,
    items,
    onClose,
    openPreview,
    page,
    selectedItem,
    toggleFavorite,
    togglePreviewPlayback,
    totalPages,
  ]);

  useEffect(() => {
    const onFrameMessage = (ev: MessageEvent) => {
      if (ev.data && typeof ev.data === 'object' && ev.data.type === 'skyline-browser-escape') {
        setFullscreenPlayerOpen(false);
      }
    };
    window.addEventListener('message', onFrameMessage);
    return () => window.removeEventListener('message', onFrameMessage);
  }, []);

  const h = metrics.viewportHeight;
  const padX = Math.max(24, Math.round(metrics.screenMargin * 0.9));
  const bg = '#141414';
  const cardBg = '#1F1F24';
  const netflixRed = '#E50914';

  const activeFullscreenUrl = useMemo(() => {
    if (!playEmbedUrl) return '';
    if (/youtube(?:-nocookie)?\.com\/embed|youtu\.be/i.test(playEmbedUrl)) {
      return playEmbedUrl;
    }
    if (/^https?:\/\//i.test(playEmbedUrl)) {
      return `/api/lamovie/embed?url=${encodeURIComponent(playEmbedUrl)}`;
    }
    return playEmbedUrl;
  }, [playEmbedUrl]);

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Netflix Streaming Hub"
      data-testid="browser-view"
      className="animate-ns2-fade absolute inset-0 z-50 flex flex-col overflow-hidden select-none text-white"
      style={{ backgroundColor: bg }}
    >
      {/* Top Netflix Navigation + Search Bar */}
      <header
        className="shrink-0 flex items-center justify-between gap-3 border-b border-white/10"
        style={{
          paddingLeft: `${padX}px`,
          paddingRight: `${padX}px`,
          height: `${Math.max(54, Math.round(h * 0.11))}px`,
          background: 'linear-gradient(180deg, rgba(12,12,15,0.98) 0%, rgba(20,20,24,0.95) 100%)',
        }}
      >
        <div className="flex items-center gap-4 min-w-0">
          <span
            data-testid="netflix-brand-title"
            className="font-ud-bold tracking-wider uppercase shrink-0"
            style={{
              color: netflixRed,
              fontSize: `${Math.max(20, Math.round(h * 0.042))}px`,
              letterSpacing: '0.08em',
            }}
          >
            NETFLIX
          </span>

          <nav className="flex items-center gap-1.5 overflow-x-auto no-scrollbar py-1">
            {NETFLIX_TABS.map((tab) => {
              const active = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  type="button"
                  data-testid={`netflix-tab-${tab.id}`}
                  onClick={() => {
                    setActiveTab(tab.id);
                    setSelectedItem(null);
                    setFullscreenPlayerOpen(false);
                    setPage(1);
                    setFocusZone('grid');
                  }}
                  className="px-3 py-1 rounded-md text-xs font-ud-semibold whitespace-nowrap cursor-pointer focus:outline-none transition-colors flex items-center gap-1.5"
                  style={{
                    backgroundColor: active ? netflixRed : 'rgba(255,255,255,0.08)',
                    color: '#FFFFFF',
                    border:
                      focusZone === 'tabs' && active
                        ? '2px solid #FFFFFF'
                        : '2px solid transparent',
                  }}
                >
                  {tab.id === 'forMe' && <Flame className="w-3.5 h-3.5" />}
                  {tab.id === 'favorites' && <Star className="w-3.5 h-3.5 fill-current" />}
                  {tab.id === 'movies' && <Film className="w-3.5 h-3.5" />}
                  {tab.id === 'series' && <Tv className="w-3.5 h-3.5" />}
                  {tab.id === 'categories' && <Sparkles className="w-3.5 h-3.5" />}
                  {tab.id === 'youtube' && <Youtube className="w-3.5 h-3.5" />}
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </nav>
        </div>

        <form onSubmit={submitSearch} className="flex items-center gap-2 shrink-0">
          <div className="relative flex items-center">
            <Search className="w-3.5 h-3.5 text-white/60 absolute left-3 pointer-events-none" />
            <input
              ref={searchInputRef}
              type="text"
              data-testid="netflix-search-input"
              value={searchDraft}
              onChange={(e) => setSearchDraft(e.target.value)}
              placeholder="Search LaMovie & YouTube..."
              className="pl-8 pr-3 py-1.5 rounded-md text-xs bg-white/10 text-white placeholder-white/50 border border-white/15 focus:border-[#E50914] focus:outline-none ring-0 focus:ring-0 select-text"
              style={{
                width: '205px',
                outline: 'none',
                boxShadow: 'none',
              }}
            />
          </div>
          <button
            type="submit"
            data-testid="netflix-search-submit"
            className="px-3 py-1.5 rounded-md text-xs font-ud-bold text-white cursor-pointer focus:outline-none hover:opacity-90"
            style={{ backgroundColor: netflixRed }}
          >
            Search
          </button>
        </form>
      </header>

      {/* Optional External Link Shortcut Banner (if launched from eShop Download) */}
      {hasExternalBanner && initialUrl && (
        <div
          className="shrink-0 flex items-center justify-between px-6 py-1.5 text-xs border-b border-white/10"
          style={{ backgroundColor: '#1B1D24' }}
        >
          <span className="truncate text-white/80">Requested Link: {initialUrl}</span>
          <a
            href={initialUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 px-2.5 py-1 rounded bg-white/15 hover:bg-white/25 text-white font-ud-semibold shrink-0"
          >
            <span>Open External</span>
            <ExternalLink className="w-3 h-3" />
          </a>
        </div>
      )}

      {/* Categories Filter Ribbon when Categories tab is active */}
      {activeTab === 'categories' && !selectedItem && (
        <div
          data-testid="netflix-genre-bar"
          className="shrink-0 flex items-center gap-2 overflow-x-auto no-scrollbar py-2 border-b border-white/10"
          style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px`, backgroundColor: '#19191E' }}
        >
          {GENRE_FILTERS.map((g) => {
            const active = activeGenre === g.id;
            return (
              <button
                key={g.id}
                type="button"
                onClick={() => {
                  setActiveGenre(g.id);
                  setPage(1);
                }}
                className="px-3 py-1 rounded text-xs font-ud-semibold whitespace-nowrap cursor-pointer focus:outline-none"
                style={{
                  backgroundColor: active ? netflixRed : 'rgba(255,255,255,0.08)',
                  color: '#FFFFFF',
                  border: focusZone === 'genres' && active ? '2px solid #FFFFFF' : '2px solid transparent',
                }}
              >
                {g.label}
              </button>
            );
          })}
        </div>
      )}

      {/* Main Content: Either Media Grid (20/page) OR Game-Style In-Section Preview Window */}
      <div
        className="flex-1 min-h-0 overflow-y-auto no-scrollbar relative"
        style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px`, paddingTop: '12px', paddingBottom: '12px' }}
      >
        {selectedItem ? (
          <div data-testid="netflix-preview-page" className="flex flex-col md:flex-row gap-6 h-full">
            {/* Left / Top Preview Window (Click / A when selected -> Play/Pause Preview; Watch Fullscreen -> Stop Preview & Play Full Movie) */}
            <div className="md:w-[54%] flex flex-col gap-3 shrink-0">
              <div
                role="button"
                tabIndex={0}
                data-testid="netflix-preview-window"
                onClick={() => {
                  setDetailFocusZone('preview');
                  togglePreviewPlayback();
                }}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    setDetailFocusZone('preview');
                    togglePreviewPlayback();
                  }
                }}
                className="relative w-full aspect-video rounded-xl overflow-hidden bg-black cursor-pointer group focus:outline-none transition-all"
                style={{
                  border: detailFocusZone === 'preview' ? '3px solid #FFFFFF' : `2px solid ${netflixRed}`,
                  boxShadow:
                    detailFocusZone === 'preview' ? '0 0 0 2px rgba(229,9,20,0.9)' : 'none',
                }}
              >
                {previewEmbedUrl && previewPlaying && !fullscreenPlayerOpen ? (
                  <iframe
                    src={previewEmbedUrl}
                    title={selectedItem.title}
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen"
                    referrerPolicy="strict-origin-when-cross-origin"
                    className="w-full h-full border-0 pointer-events-none"
                  />
                ) : (
                  <img
                    src={selectedItem.backdropUrl || selectedItem.posterUrl}
                    alt={selectedItem.title}
                    referrerPolicy="no-referrer"
                    className="w-full h-full object-cover"
                  />
                )}
                <div
                  className="absolute inset-0 flex items-end justify-between p-3 pointer-events-none"
                  style={{ background: 'linear-gradient(180deg, rgba(0,0,0,0) 45%, rgba(0,0,0,0.82) 100%)' }}
                >
                  <span className="text-xs font-ud-semibold text-white/95">
                    {previewPlaying
                      ? 'Preview Playing · Click window or press A (when focused) to Pause'
                      : 'Preview Paused · Click window or press A (when focused) to Play'}
                  </span>
                  <span
                    data-testid="netflix-preview-toggle"
                    className="inline-flex items-center gap-1.5 px-3 py-1 rounded-md text-xs font-ud-bold text-white"
                    style={{ backgroundColor: previewPlaying ? netflixRed : 'rgba(255,255,255,0.22)' }}
                  >
                    {previewPlaying ? <Pause className="w-3.5 h-3.5" /> : <Play className="w-3.5 h-3.5 fill-current" />}
                    <span>{previewPlaying ? 'Pause' : 'Play'}</span>
                  </span>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-wrap items-center gap-2.5">
                <button
                  type="button"
                  data-testid="netflix-watch-fullscreen"
                  onClick={enterFullscreen}
                  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-ud-bold text-white cursor-pointer focus:outline-none hover:opacity-90"
                  style={{
                    backgroundColor: netflixRed,
                    border: detailFocusZone === 'fullscreen' ? '2px solid #FFFFFF' : '2px solid transparent',
                  }}
                >
                  <Play className="w-4 h-4 fill-current" />
                  <span>Watch Fullscreen</span>
                </button>

                <button
                  type="button"
                  data-testid="netflix-toggle-favorite"
                  onClick={() => toggleFavorite(selectedItem)}
                  className="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-lg text-xs font-ud-semibold bg-white/10 hover:bg-white/20 text-white cursor-pointer focus:outline-none"
                  style={{
                    border: detailFocusZone === 'favorite' ? '2px solid #FFFFFF' : '2px solid transparent',
                  }}
                >
                  <Star
                    className={`w-4 h-4 ${isFavoriteItem(selectedItem) ? 'fill-amber-400 text-amber-400' : ''}`}
                  />
                  <span>{isFavoriteItem(selectedItem) ? 'Saved in Favorites' : 'Add to Favorites'}</span>
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setSelectedItem(null);
                    setPreviewPlaying(false);
                  }}
                  className="px-4 py-2.5 rounded-lg text-xs font-ud-semibold bg-white/10 hover:bg-white/20 text-white cursor-pointer focus:outline-none"
                  style={{
                    border: detailFocusZone === 'back' ? '2px solid #FFFFFF' : '2px solid transparent',
                  }}
                >
                  Back to Catalog
                </button>
              </div>
            </div>

            {/* Right Metadata, Synopsis, Servers & Series Episodes */}
            <div className="flex-1 min-w-0 flex flex-col gap-3 overflow-y-auto no-scrollbar pr-1">
              <div className="flex items-center gap-2 flex-wrap">
                <span
                  className="px-2.5 py-0.5 rounded text-[11px] font-ud-bold uppercase"
                  style={{ backgroundColor: netflixRed }}
                >
                  {selectedItem.mediaType === 'youtube'
                    ? 'YouTube'
                    : selectedItem.mediaType === 'tvshows'
                      ? 'Series · LaMovie'
                      : 'Movie · LaMovie'}
                </span>
                {selectedItem.year && (
                  <span className="text-xs text-white/75 font-ud-semibold">{selectedItem.year}</span>
                )}
                {selectedItem.rating && (
                  <span className="text-xs font-ud-bold text-amber-400">★ {selectedItem.rating}</span>
                )}
                {selectedItem.runtime && (
                  <span className="text-xs text-white/75">{selectedItem.runtime}</span>
                )}
              </div>

              <h2
                className="font-ud-bold leading-tight"
                style={{ fontSize: `${Math.max(20, Math.round(h * 0.04))}px` }}
              >
                {selectedItem.title}
              </h2>

              <div className="flex flex-wrap gap-1.5">
                {selectedItem.genres.map((g) => (
                  <span
                    key={g}
                    className="px-2.5 py-0.5 rounded text-[11px] bg-white/10 text-white/85"
                  >
                    {g}
                  </span>
                ))}
              </div>

              <p className="text-sm text-white/85 leading-relaxed">
                {detailLoading ? 'Loading LaMovie streams & synopsis...' : selectedItem.overview}
              </p>

              {embeds.length > 1 && (
                <div className="space-y-1.5 pt-1">
                  <div className="text-xs font-ud-bold text-white/70 uppercase tracking-wider">
                    Stream Servers
                  </div>
                  <div className="flex flex-wrap gap-1.5">
                    {embeds.slice(0, 6).map((emb, idx) => (
                      <button
                        key={`${emb.url}-${idx}`}
                        type="button"
                        onClick={() => {
                          setSelectedEmbedIdx(idx);
                          setPlayEmbedUrl(emb.url);
                        }}
                        className="px-3 py-1 rounded text-xs font-ud-semibold cursor-pointer focus:outline-none"
                        style={{
                          backgroundColor:
                            selectedEmbedIdx === idx ? netflixRed : 'rgba(255,255,255,0.1)',
                        }}
                      >
                        {emb.server || `Server ${idx + 1}`}
                        {emb.language ? ` · ${emb.language}` : ''}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {episodes.length > 0 && (
                <div className="space-y-1.5 pt-1">
                  <div className="text-xs font-ud-bold text-white/70 uppercase tracking-wider">
                    Episodes (Season 1)
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5">
                    {episodes.map((ep, idx) => {
                      const activeEp = activeEpisodeId === ep._id;
                      return (
                        <button
                          key={ep._id}
                          type="button"
                          onClick={() => loadEpisodePlayer(ep._id, true)}
                          className="text-left px-3 py-2 rounded-lg text-xs font-ud-medium truncate cursor-pointer focus:outline-none transition-colors"
                          style={{
                            backgroundColor: activeEp ? netflixRed : 'rgba(255,255,255,0.1)',
                          }}
                        >
                          {idx + 1}. {ep.title}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          </div>
        ) : loading ? (
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5">
            {Array.from({ length: 8 }).map((_, i) => (
              <div
                key={i}
                className="aspect-[16/10] rounded-lg bg-white/10 animate-pulse"
              />
            ))}
          </div>
        ) : items.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full gap-2 text-white/65">
            <Film className="w-9 h-9" />
            <p className="text-sm font-ud-semibold">
              {activeTab === 'favorites'
                ? `No favorites matched${activeLetter !== 'All' ? ` under "${activeLetter}"` : ''}.`
                : `No titles found${activeLetter !== 'All' ? ` under "${activeLetter}"` : ''}. Try another letter or category.`}
            </p>
          </div>
        ) : (
          <div data-testid="netflix-media-grid" className="grid grid-cols-2 sm:grid-cols-4 gap-3.5">
            {items.slice(0, PAGE_SIZE).map((item, idx) => {
              const isFocused = focusZone === 'grid' && focusedIdx === idx;
              const isFav = isFavoriteItem(item);
              return (
                <button
                  key={item.id}
                  type="button"
                  data-testid={`netflix-card-${idx}`}
                  onMouseEnter={() => {
                    setFocusZone('grid');
                    setFocusedIdx(idx);
                  }}
                  onClick={() => openPreview(item)}
                  className="relative flex flex-col overflow-hidden rounded-lg text-left cursor-pointer focus:outline-none transition-transform duration-150"
                  style={{
                    backgroundColor: cardBg,
                    border: isFocused ? `3px solid ${netflixRed}` : '3px solid rgba(255,255,255,0.08)',
                  }}
                >
                  <div className="relative w-full aspect-video bg-black overflow-hidden">
                    <img
                      src={item.backdropUrl || item.posterUrl}
                      alt={item.title}
                      referrerPolicy="no-referrer"
                      className="w-full h-full object-cover"
                    />
                    <span
                      className="absolute top-1.5 left-1.5 px-2 py-0.5 rounded text-[10px] font-ud-bold text-white uppercase"
                      style={{
                        backgroundColor:
                          item.mediaType === 'youtube' ? '#FF0033' : 'rgba(229,9,20,0.9)',
                      }}
                    >
                      {item.mediaType === 'youtube'
                        ? 'YouTube'
                        : item.mediaType === 'tvshows'
                          ? 'Series'
                          : 'Movie'}
                    </span>
                    {isFav && (
                      <span className="absolute top-1.5 right-1.5 p-1 rounded-full bg-black/75 text-amber-400">
                        <Star className="w-3 h-3 fill-current" />
                      </span>
                    )}
                  </div>
                  <div className="p-2.5 flex flex-col gap-0.5">
                    <div className="text-xs font-ud-bold text-white line-clamp-1">{item.title}</div>
                    <div className="text-[11px] text-white/60 truncate">
                      {item.mediaType === 'youtube'
                        ? item.channel || 'YouTube'
                        : [item.year, item.genres[0]].filter(Boolean).join(' · ') || 'LaMovie'}
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* A-Z Alphabet Filter Bar BELOW Grid (Matching eShop, LB/RB or Clickable) */}
      {!selectedItem && (
        <div
          data-testid="netflix-alphabet-bar"
          className="shrink-0 py-1.5 flex items-center gap-1.5 border-t border-white/10"
          style={{
            paddingLeft: `${padX}px`,
            paddingRight: `${padX}px`,
            backgroundColor: '#151519',
            outline: focusZone === 'alphabet' ? `2px solid ${netflixRed}` : 'none',
          }}
        >
          <button
            type="button"
            data-testid="netflix-alphabet-prev"
            onClick={() => {
              setActiveLetter((cur) => stepAlphabetLetter(cur, -1));
              setPage(1);
              setFocusedIdx(0);
            }}
            title="Previous Letter (LB)"
            className="flex items-center gap-1 px-1.5 py-1 rounded bg-white/10 hover:bg-white/20 text-[10px] font-ud-bold text-gray-200 cursor-pointer shrink-0"
          >
            <SwitchPdfIcon button="L1" size={16} fillColor="#FFFFFF" cutoutColor="#151519" />
          </button>

          <div className="flex-1 flex items-center justify-between gap-0.5 overflow-x-auto no-scrollbar">
            {ESHOP_ALPHABET_LETTERS.map((ltr) => {
              const isSel = activeLetter === ltr;
              return (
                <button
                  key={ltr}
                  type="button"
                  data-testid={`netflix-letter-${ltr}`}
                  onClick={() => {
                    setActiveLetter(ltr);
                    setPage(1);
                    setFocusedIdx(0);
                  }}
                  className="px-1.5 py-0.5 rounded text-[11px] font-ud-bold cursor-pointer focus:outline-none transition-colors shrink-0"
                  style={{
                    backgroundColor: isSel ? netflixRed : 'transparent',
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
            data-testid="netflix-alphabet-next"
            onClick={() => {
              setActiveLetter((cur) => stepAlphabetLetter(cur, 1));
              setPage(1);
              setFocusedIdx(0);
            }}
            title="Next Letter (RB)"
            className="flex items-center gap-1 px-1.5 py-1 rounded bg-white/10 hover:bg-white/20 text-[10px] font-ud-bold text-gray-200 cursor-pointer shrink-0"
          >
            <SwitchPdfIcon button="R1" size={16} fillColor="#FFFFFF" cutoutColor="#151519" />
          </button>
        </div>
      )}

      {/* Bottom Controller Help & Paging */}
      <footer
        className="shrink-0 border-t border-white/10"
        style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px`, backgroundColor: '#101013' }}
      >
        <div
          className="flex items-center justify-between"
          style={{ height: `${Math.max(40, Math.round(h * 0.082))}px` }}
        >
          <div className="flex items-center gap-3">
            <BottomControllerGlyph size={metrics.helpIconSize} color="#FFFFFF" />
            {!selectedItem && (
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  data-testid="netflix-prev-page"
                  disabled={page <= 1}
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  className="flex items-center gap-0.5 px-2 py-1 rounded bg-white/10 hover:bg-white/20 disabled:opacity-35 text-xs font-ud-semibold cursor-pointer focus:outline-none"
                  aria-label="Previous page"
                >
                  <ChevronLeft className="w-3.5 h-3.5" />
                  <span>Prev</span>
                </button>
                <span
                  data-testid="netflix-page-indicator"
                  className="text-xs font-mono-tabular text-white/80 px-1.5"
                >
                  Page {page} / {totalPages}
                  {hasMore && page >= totalPages ? '+' : ''} · {totalCount}
                </span>
                <button
                  type="button"
                  data-testid="netflix-next-page"
                  disabled={page >= totalPages && !hasMore}
                  onClick={() => setPage((p) => p + 1)}
                  className="flex items-center gap-0.5 px-2 py-1 rounded bg-white/10 hover:bg-white/20 disabled:opacity-35 text-xs font-ud-semibold cursor-pointer focus:outline-none"
                  aria-label="Next page"
                >
                  <span>Next</span>
                  <ChevronRight className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
          </div>

          <div className="flex items-center gap-5">
            {selectedItem && (
              <button
                type="button"
                onClick={() => toggleFavorite(selectedItem)}
                className="flex items-center gap-1.5 cursor-pointer hover:opacity-80 focus:outline-none"
              >
                <SwitchPdfIcon
                  button="X"
                  size={Math.max(18, Math.round(metrics.helpIconSize * 0.62))}
                  fillColor="#FFFFFF"
                  cutoutColor="#101013"
                />
                <span className="text-xs font-ud-semibold">Favorite</span>
              </button>
            )}

            <button
              type="button"
              data-testid="browser-back-button"
              onClick={() => {
                if (fullscreenPlayerOpen) setFullscreenPlayerOpen(false);
                else if (selectedItem) {
                  setSelectedItem(null);
                  setPreviewPlaying(false);
                } else onClose();
              }}
              className="flex items-center gap-1.5 cursor-pointer hover:opacity-80 focus:outline-none"
            >
              <SwitchPdfIcon
                button="B"
                size={Math.max(18, Math.round(metrics.helpIconSize * 0.62))}
                fillColor="#FFFFFF"
                cutoutColor="#101013"
              />
              <span className="text-xs font-ud-semibold">Back</span>
            </button>

            <button
              type="button"
              onClick={() => {
                if (selectedItem) {
                  if (detailFocusZone === 'preview') togglePreviewPlayback();
                  else enterFullscreen();
                } else if (items[focusedIdx]) {
                  openPreview(items[focusedIdx]);
                }
              }}
              className="flex items-center gap-1.5 cursor-pointer hover:opacity-80 focus:outline-none"
            >
              <SwitchPdfIcon
                button="A"
                size={Math.max(18, Math.round(metrics.helpIconSize * 0.62))}
                fillColor="#FFFFFF"
                cutoutColor="#101013"
              />
              <span className="text-xs font-ud-semibold">
                {selectedItem
                  ? detailFocusZone === 'preview'
                    ? previewPlaying
                      ? 'Pause Preview'
                      : 'Play Preview'
                    : 'Watch Fullscreen'
                  : 'Preview'}
              </span>
            </button>
          </div>
        </div>
      </footer>

      {/* Dedicated Fullscreen Streaming Overlay (Preview stopped; plays real LaMovie stream/episode) */}
      {fullscreenPlayerOpen && selectedItem && (
        <div
          data-testid="streaming-fullscreen-player"
          className="absolute inset-0 z-50 bg-black flex flex-col"
        >
          <div className="flex items-center justify-between px-5 py-2.5 bg-black/90 border-b border-white/10 shrink-0">
            <div className="flex items-center gap-2.5 min-w-0">
              <span
                className="font-ud-bold text-xs uppercase px-2 py-0.5 rounded"
                style={{ backgroundColor: netflixRed }}
              >
                NETFLIX
              </span>
              <span className="font-ud-bold text-sm truncate">{selectedItem.title}</span>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              {(playEmbedUrl || activeFullscreenUrl) && (
                <a
                  href={playEmbedUrl || activeFullscreenUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1 px-3 py-1.5 rounded bg-white/10 hover:bg-white/20 text-xs font-ud-semibold"
                >
                  <ExternalLink className="w-3.5 h-3.5" />
                  <span>External</span>
                </a>
              )}
              <button
                type="button"
                data-testid="streaming-exit-fullscreen"
                onClick={() => setFullscreenPlayerOpen(false)}
                className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded bg-white/15 hover:bg-white/25 text-xs font-ud-bold cursor-pointer focus:outline-none"
              >
                <Minimize2 className="w-3.5 h-3.5" />
                <span>Exit Fullscreen (B)</span>
              </button>
            </div>
          </div>
          <div className="flex-1 min-h-0 flex items-center justify-center">
            {detailLoading && !activeFullscreenUrl ? (
              <div className="flex flex-col items-center gap-3 text-white/80">
                <Loader2 className="w-8 h-8 animate-spin text-[#E50914]" />
                <span className="text-sm font-ud-semibold">Loading LaMovie stream...</span>
              </div>
            ) : activeFullscreenUrl ? (
              <iframe
                src={activeFullscreenUrl}
                title={`${selectedItem.title} Fullscreen Player`}
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen"
                referrerPolicy="strict-origin-when-cross-origin"
                allowFullScreen
                className="w-full h-full border-0 bg-black"
              />
            ) : (
              <div className="text-sm text-white/70">No stream URL found for this title.</div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
