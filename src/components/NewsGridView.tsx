import { useCallback, useEffect, useRef, useState } from 'react';
import { ChevronLeft, ChevronRight, ExternalLink, Minimize2, Newspaper, Play, RefreshCw, Type } from 'lucide-react';
import type {
  AdaptivePalette,
  ArticleReaderPayload,
  BrowserOpenMode,
  GeneralNewsCategoryId,
  NewsCategoryId,
  NewsFeedItem,
  NewsFeedResponse,
  NsoCategoryId,
} from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import {
  GENERAL_NEWS_FALLBACK_BY_CATEGORY,
  NEWS_FALLBACK_BY_CATEGORY,
} from '../utils/rssFeedParser';
import { BottomControllerGlyph } from './BottomControllerGlyph';
import { SwitchPdfIcon } from './SwitchPdfIcons';
import { UiKitNewsIcon, UiKitNsoIcon } from './UiKitIcons';

interface NewsGridViewProps {
  mode: 'nso' | 'news';
  browserMode: BrowserOpenMode;
  palette: AdaptivePalette;
  metrics: Switch2LayoutMetrics;
  onOpenInBrowser: (url: string) => void;
  onClose: () => void;
}

const NSO_CATEGORIES: { id: NsoCategoryId; label: string }[] = [
  { id: 'nintendo', label: 'Nintendo' },
  { id: 'action', label: 'Action' },
  { id: 'rpg', label: 'RPG' },
  { id: 'adventure', label: 'Adventure' },
  { id: 'indie', label: 'Indie' },
  { id: 'multiplayer', label: 'Multiplayer' },
];

const GENERAL_NEWS_CATEGORIES: { id: GeneralNewsCategoryId; label: string }[] = [
  { id: 'latest', label: 'Latest News' },
  { id: 'elnuevodia', label: 'El Nuevo Día' },
  { id: 'puerto_rico', label: 'Puerto Rico' },
  { id: 'r_puertorico', label: 'r/PuertoRico' },
  { id: 'politics', label: 'Politics' },
  { id: 'economy', label: 'Economy' },
  { id: 'tech', label: 'Tech' },
];

const LOCAL_FALLBACK_ART = '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg';
const READER_TEXT_SCALES = [1, 1.25, 1.5] as const;

export function NewsGridView({
  mode,
  browserMode,
  palette,
  metrics,
  onOpenInBrowser,
  onClose,
}: NewsGridViewProps) {
  const activeCategories = mode === 'nso' ? NSO_CATEGORIES : GENERAL_NEWS_CATEGORIES;
  const [category, setCategory] = useState<NewsCategoryId>(
    mode === 'nso' ? 'nintendo' : 'latest'
  );
  const [focusZone, setFocusZone] = useState<'cats' | 'grid'>('grid');
  const [focusedCatIdx, setFocusedCatIdx] = useState(0);

  const [items, setItems] = useState<NewsFeedItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [hasMoreFromServer, setHasMoreFromServer] = useState(true);
  const [serverBatchPage, setServerBatchPage] = useState(1);
  const [pageIdx, setPageIdx] = useState(0);
  const [focusedIdx, setFocusedIdx] = useState(0);

  const [activeArticle, setActiveArticle] = useState<NewsFeedItem | null>(null);
  const [articleDetails, setArticleDetails] = useState<ArticleReaderPayload | null>(null);
  const [fallbackVideoUrl, setFallbackVideoUrl] = useState<string>('');
  const [articleLoading, setArticleLoading] = useState(false);
  const [playingVideoFullscreen, setPlayingVideoFullscreen] = useState(false);
  const [readerTextScaleIdx, setReaderTextScaleIdx] = useState(1); // default 1.25x for comfort

  const latestReqIdRef = useRef(0);
  const storyScrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setCategory(mode === 'nso' ? 'nintendo' : 'latest');
    setFocusedCatIdx(0);
    setActiveArticle(null);
    setPlayingVideoFullscreen(false);
    setFocusZone('grid');
  }, [mode]);

  const fetchFeed = useCallback(
    async (forceRefresh = false, nextBatchPage = 1, append = false) => {
      const reqId = ++latestReqIdRef.current;
      const validCat =
        mode === 'nso'
          ? (category in NEWS_FALLBACK_BY_CATEGORY ? (category as NsoCategoryId) : 'nintendo')
          : (category in GENERAL_NEWS_FALLBACK_BY_CATEGORY
              ? (category as GeneralNewsCategoryId)
              : 'latest');

      if (!append) {
        setItems([]);
        setPageIdx(0);
        setFocusedIdx(0);
        setServerBatchPage(1);
      }
      if (forceRefresh) setRefreshing(true);
      else setLoading(true);

      try {
        const sp = new URLSearchParams();
        sp.set('page', String(nextBatchPage));
        sp.set('category', validCat);
        if (forceRefresh) sp.set('refresh', '1');

        const endpoint =
          mode === 'nso'
            ? `/api/feeds/nso?${sp.toString()}`
            : `/api/feeds/news?${sp.toString()}`;
        const res = await fetch(endpoint);
        const json = (await res.json()) as NewsFeedResponse;
        if (reqId !== latestReqIdRef.current) return;

        if (Array.isArray(json.items) && json.items.length > 0) {
          if (append) {
            setItems((prev) => {
              const seen = new Set(prev.map((x) => x.id));
              const extra = json.items.filter((x) => !seen.has(x.id));
              return [...prev, ...extra];
            });
          } else {
            setItems(json.items);
          }
          setHasMoreFromServer(Boolean(json.hasMore));
          setServerBatchPage(nextBatchPage);
        } else if (!append) {
          const offlineFallback =
            mode === 'nso'
              ? NEWS_FALLBACK_BY_CATEGORY[validCat as NsoCategoryId]
              : GENERAL_NEWS_FALLBACK_BY_CATEGORY[validCat as GeneralNewsCategoryId];
          setItems(offlineFallback);
          setHasMoreFromServer(false);
        }
      } catch {
        if (!append && reqId === latestReqIdRef.current) {
          const offlineFallback =
            mode === 'nso'
              ? NEWS_FALLBACK_BY_CATEGORY[validCat as NsoCategoryId]
              : GENERAL_NEWS_FALLBACK_BY_CATEGORY[validCat as GeneralNewsCategoryId];
          setItems(offlineFallback);
        }
      } finally {
        if (reqId === latestReqIdRef.current) {
          setLoading(false);
          setRefreshing(false);
        }
      }
    },
    [mode, category]
  );

  useEffect(() => {
    fetchFeed(false, 1, false);
  }, [fetchFeed]);

  const openStoryReader = useCallback(async (item: NewsFeedItem) => {
    setActiveArticle(item);
    setPlayingVideoFullscreen(false);
    setArticleDetails(null);
    setFallbackVideoUrl('');
    setArticleLoading(true);
    storyScrollRef.current?.scrollTo({ top: 0 });
    try {
      const res = await fetch(
        `/api/feeds/article?url=${encodeURIComponent(item.url)}&title=${encodeURIComponent(item.title)}`
      );
      let hasVid = Boolean(item.videoUrl);
      if (res.ok) {
        const payload = (await res.json()) as ArticleReaderPayload;
        setArticleDetails(payload);
        if (payload.videoUrl) hasVid = true;
      }
      if (!hasVid) {
        const ytRes = await fetch(`/api/youtube/search?q=${encodeURIComponent(item.title)}`);
        if (ytRes.ok) {
          const ytJson = (await ytRes.json()) as { videoId?: string };
          if (ytJson.videoId) {
            setFallbackVideoUrl(
              `https://www.youtube.com/embed/${ytJson.videoId}?autoplay=1&mute=0&playsinline=1&rel=0&enablejsapi=1`
            );
          }
        }
      }
    } catch {
      // Keep item fallback text
    } finally {
      setArticleLoading(false);
    }
  }, []);

  const launchVideoFullscreen = useCallback(async () => {
    if (!activeArticle) return;
    setPlayingVideoFullscreen(true);
    const currentVideo = articleDetails?.videoUrl || activeArticle.videoUrl || fallbackVideoUrl;
    if (currentVideo) {
      return;
    }
    try {
      const ytRes = await fetch(`/api/youtube/search?q=${encodeURIComponent(activeArticle.title)}`);
      if (ytRes.ok) {
        const ytJson = (await ytRes.json()) as { videoId?: string };
        const vidId = ytJson.videoId || '3pE23YTYEZM';
        setFallbackVideoUrl(
          `https://www.youtube.com/embed/${vidId}?autoplay=1&mute=0&playsinline=1&rel=0&enablejsapi=1`
        );
      } else {
        setFallbackVideoUrl(
          'https://www.youtube.com/embed/3pE23YTYEZM?autoplay=1&mute=0&playsinline=1&rel=0&enablejsapi=1'
        );
      }
    } catch {
      setFallbackVideoUrl(
        'https://www.youtube.com/embed/3pE23YTYEZM?autoplay=1&mute=0&playsinline=1&rel=0&enablejsapi=1'
      );
    }
  }, [activeArticle, articleDetails?.videoUrl, fallbackVideoUrl]);

  const switchArticleByDelta = useCallback(
    (delta: -1 | 1) => {
      if (!activeArticle || items.length === 0) return;
      const curIdx = items.findIndex((x) => x.id === activeArticle.id);
      const safeCur = curIdx >= 0 ? curIdx : 0;
      const nextIdx = (safeCur + delta + items.length) % items.length;
      setPageIdx(Math.floor(nextIdx / 4));
      setFocusedIdx(nextIdx % 4);
      openStoryReader(items[nextIdx]);
    },
    [activeArticle, items, openStoryReader]
  );

  const cycleTextSize = useCallback(() => {
    setReaderTextScaleIdx((i) => (i + 1) % READER_TEXT_SCALES.length);
  }, []);

  const totalPages = Math.max(1, Math.ceil(items.length / 4));
  const pageItems = items.slice(pageIdx * 4, pageIdx * 4 + 4);

  const goNextPage = useCallback(() => {
    if (pageIdx + 1 < totalPages) {
      setPageIdx((p) => p + 1);
      setFocusedIdx(0);
    } else if (hasMoreFromServer && !loading) {
      fetchFeed(false, serverBatchPage + 1, true).then(() => {
        setPageIdx((p) => p + 1);
        setFocusedIdx(0);
      });
    }
  }, [fetchFeed, hasMoreFromServer, loading, pageIdx, serverBatchPage, totalPages]);

  const handleOpenExternalUrl = useCallback(
    (targetUrl: string) => {
      if (browserMode === 'in-app') {
        onOpenInBrowser(targetUrl);
      } else {
        const isAndroid = /android/i.test(navigator.userAgent);
        if (isAndroid) {
          window.location.href = `googlechrome://navigate?url=${encodeURIComponent(targetUrl)}`;
        } else {
          const link = document.createElement('a');
          link.href = targetUrl;
          link.target = '_blank';
          link.rel = 'noopener noreferrer';
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
        }
      }
    },
    [browserMode, onOpenInBrowser]
  );

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const lower = e.key.toLowerCase();
      if (e.key === 'Escape' || e.key === 'Backspace') {
        e.preventDefault();
        e.stopPropagation();
        if (playingVideoFullscreen) setPlayingVideoFullscreen(false);
        else if (activeArticle) setActiveArticle(null);
        else onClose();
        return;
      }

      if (activeArticle) {
        if (playingVideoFullscreen) {
          return;
        }
        // LB / RB switch Prev / Next News Story in Reader
        if (lower === 'q' || e.key === '[') {
          e.preventDefault();
          e.stopPropagation();
          switchArticleByDelta(-1);
          return;
        }
        if (lower === 'e' || e.key === ']') {
          e.preventDefault();
          e.stopPropagation();
          switchArticleByDelta(1);
          return;
        }
        // X or Y cycles text size in Reader
        if (lower === 'x' || lower === 'y') {
          e.preventDefault();
          e.stopPropagation();
          cycleTextSize();
          return;
        }
        if (e.key === 'ArrowDown' || e.key === 'PageDown') {
          e.preventDefault();
          e.stopPropagation();
          storyScrollRef.current?.scrollBy({ top: e.key === 'PageDown' ? 220 : 120, behavior: 'smooth' });
        } else if (e.key === 'ArrowUp' || e.key === 'PageUp') {
          e.preventDefault();
          e.stopPropagation();
          storyScrollRef.current?.scrollBy({ top: e.key === 'PageUp' ? -220 : -120, behavior: 'smooth' });
        } else if (e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          launchVideoFullscreen();
        }
        return;
      }

      // Grid LB / RB switches Prev / Next Page
      if (lower === 'q' || e.key === '[') {
        e.preventDefault();
        e.stopPropagation();
        if (pageIdx > 0) {
          setPageIdx((p) => Math.max(0, p - 1));
          setFocusedIdx(0);
        }
        return;
      }
      if (lower === 'e' || e.key === ']') {
        e.preventDefault();
        e.stopPropagation();
        goNextPage();
        return;
      }

      if (lower === 'x') {
        e.preventDefault();
        e.stopPropagation();
        fetchFeed(true, 1, false);
        return;
      }

      if (focusZone === 'cats') {
        if (e.key === 'ArrowRight') {
          e.preventDefault();
          e.stopPropagation();
          const next = (focusedCatIdx + 1) % activeCategories.length;
          setFocusedCatIdx(next);
          setCategory(activeCategories[next].id);
        } else if (e.key === 'ArrowLeft') {
          e.preventDefault();
          e.stopPropagation();
          const prev = (focusedCatIdx - 1 + activeCategories.length) % activeCategories.length;
          setFocusedCatIdx(prev);
          setCategory(activeCategories[prev].id);
        } else if (e.key === 'ArrowDown' || e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          setFocusZone('grid');
          setFocusedIdx(0);
        }
        return;
      }

      if (e.key === 'ArrowRight') {
        e.preventDefault();
        e.stopPropagation();
        if (focusedIdx + 1 < pageItems.length) {
          setFocusedIdx((p) => p + 1);
        } else {
          goNextPage();
        }
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        e.stopPropagation();
        if (focusedIdx > 0) {
          setFocusedIdx((p) => p - 1);
        } else if (pageIdx > 0) {
          setPageIdx((p) => p - 1);
          setFocusedIdx(3);
        }
      } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        e.stopPropagation();
        setFocusedIdx((p) => (p + 2 < pageItems.length ? p + 2 : p));
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        e.stopPropagation();
        if (focusedIdx - 2 >= 0) {
          setFocusedIdx((p) => p - 2);
        } else {
          setFocusZone('cats');
        }
      } else if (e.key === 'Enter' && pageItems[focusedIdx]) {
        e.preventDefault();
        e.stopPropagation();
        // Always open the in-app story reader, never jump straight to external browser
        openStoryReader(pageItems[focusedIdx]);
      }
    };

    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [
    activeCategories,
    activeArticle,
    articleDetails,
    cycleTextSize,
    fetchFeed,
    focusZone,
    focusedCatIdx,
    focusedIdx,
    goNextPage,
    handleOpenExternalUrl,
    onClose,
    openStoryReader,
    pageIdx,
    pageItems,
    playingVideoFullscreen,
    switchArticleByDelta,
  ]);

  const h = metrics.viewportHeight;
  const padX = Math.max(24, Math.round(metrics.screenMargin * 0.92));
  const isDark = palette.isDark;
  const bg = isDark ? '#16181D' : '#EFEFEF';
  const cardBg = isDark ? '#23262F' : '#FFFFFF';
  const textMain = isDark ? '#F3F4F6' : '#181B20';
  const textMuted = isDark ? '#B0B7C3' : '#4B5563';
  const divider = isDark ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.14)';
  const accentColor = mode === 'nso' ? '#E60012' : '#2BAB23';
  const readerTextScale = READER_TEXT_SCALES[readerTextScaleIdx] ?? 1.25;

  const resolvedHeroImage =
    (activeArticle && articleDetails?.heroImageUrl) || activeArticle?.imageUrl || LOCAL_FALLBACK_ART;
  const resolvedVideoUrl =
    (activeArticle && articleDetails?.videoUrl) || activeArticle?.videoUrl || fallbackVideoUrl;
  const storyParagraphs =
    activeArticle && articleDetails?.paragraphs && articleDetails.paragraphs.length > 0
      ? articleDetails.paragraphs
      : activeArticle?.content
          .split(/\n+/)
          .map((p) => p.trim())
          .filter(Boolean) ?? [];
  const storyBlocks = (
    activeArticle && articleDetails?.blocks && articleDetails.blocks.length > 0
      ? articleDetails.blocks.filter((blk) => blk.type !== 'image')
      : storyParagraphs.map((p) => ({ type: 'text' as const, content: p }))
  );

  const normalizeNewsVideoEmbed = (rawUrl?: string): string | undefined => {
    if (!rawUrl) return undefined;
    if (/\.(mp4|webm|m4v)(\?|$)/i.test(rawUrl)) return rawUrl;
    const ytMatch =
      rawUrl.match(/\/embed\/([A-Za-z0-9_-]{6,})/) ||
      rawUrl.match(/[?&]v=([A-Za-z0-9_-]{6,})/) ||
      rawUrl.match(/youtu\.be\/([A-Za-z0-9_-]{6,})/);
    if (ytMatch?.[1]) {
      return `https://www.youtube.com/embed/${ytMatch[1]}?autoplay=1&mute=0&playsinline=1&rel=0&enablejsapi=1`;
    }
    return rawUrl.includes('?') ? `${rawUrl}&autoplay=1&playsinline=1` : `${rawUrl}?autoplay=1&playsinline=1`;
  };
  const embedVideoSrc = normalizeNewsVideoEmbed(resolvedVideoUrl);

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={mode === 'nso' ? 'Nintendo Online' : 'News'}
      data-testid={mode === 'nso' ? 'nso-view' : 'news-view'}
      className="animate-ns2-fade absolute inset-0 z-40 flex flex-col overflow-hidden select-none"
      style={{ backgroundColor: bg, color: textMain }}
    >
      {/* Top Header + Controller-Selectable Genre Bookmarks */}
      <div style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
        <div
          className="flex items-center justify-between gap-4"
          style={{ height: `${Math.max(50, Math.round(h * 0.11))}px` }}
        >
          <div className="flex items-center gap-3 shrink-0">
            {mode === 'nso' ? (
              <UiKitNsoIcon size={30} highlighted={true} />
            ) : (
              <UiKitNewsIcon size={30} />
            )}
            <h1
              className="font-ud-bold tracking-tight"
              style={{ fontSize: `${Math.max(19, Math.round(h * 0.038))}px` }}
            >
              {mode === 'nso' ? 'Nintendo Online' : 'News'}
            </h1>
          </div>

          <nav
            aria-label="Categories"
            data-testid="news-category-bar"
            className="flex items-center gap-2 overflow-x-auto no-scrollbar py-1"
          >
            {activeCategories.map((cat, idx) => {
              const active = category === cat.id;
              const isCatFocused = focusZone === 'cats' && focusedCatIdx === idx;
              return (
                <button
                  key={cat.id}
                  type="button"
                  data-testid={`news-cat-${cat.id}`}
                  onClick={() => {
                    setCategory(cat.id);
                    setFocusedCatIdx(idx);
                    setFocusZone('grid');
                  }}
                  className={`px-3.5 py-1.5 rounded-full whitespace-nowrap cursor-pointer focus:outline-none transition-all ${
                    active ? 'font-ud-bold' : 'font-ud-semibold'
                  }`}
                  style={{
                    fontSize: `${Math.max(12, Math.round(h * 0.021))}px`,
                    backgroundColor: active ? accentColor : cardBg,
                    color: active ? '#FFFFFF' : textMain,
                    border: isCatFocused
                      ? `2.5px solid ${palette.dockRingColor}`
                      : active
                        ? `2px solid ${accentColor}`
                        : `1px solid ${divider}`,
                  }}
                >
                  {cat.label}
                </button>
              );
            })}
          </nav>
        </div>
        <div className="w-full h-px" style={{ backgroundColor: divider }} />
      </div>

      {/* Main 2x2 Squared Cards Grid */}
      <div
        className="flex-1 flex flex-col justify-center min-h-0"
        style={{
          paddingLeft: `${padX}px`,
          paddingRight: `${padX}px`,
          paddingTop: `${Math.max(12, Math.round(h * 0.022))}px`,
          paddingBottom: `${Math.max(10, Math.round(h * 0.02))}px`,
        }}
      >
        {loading && pageItems.length === 0 ? (
          <div className="grid grid-cols-2 grid-rows-2 gap-4 h-full">
            {Array.from({ length: 4 }).map((_, i) => (
              <div
                key={i}
                className="rounded-xl"
                style={{ backgroundColor: cardBg, opacity: 0.75 }}
              />
            ))}
          </div>
        ) : pageItems.length === 0 ? (
          <div className="flex flex-col items-center justify-center gap-2 text-sm opacity-70">
            <Newspaper className="w-8 h-8" />
            <span>No articles available in this feed right now.</span>
          </div>
        ) : (
          <div
            data-testid="news-2x2-grid"
            className="grid grid-cols-2 grid-rows-2 gap-4 h-full min-h-0"
          >
            {pageItems.map((item, idx) => {
              const isSelected = focusZone === 'grid' && focusedIdx === idx;
              return (
                <button
                  key={item.id}
                  type="button"
                  data-testid={`news-card-${idx}`}
                  onMouseEnter={() => {
                    setFocusZone('grid');
                    setFocusedIdx(idx);
                  }}
                  onClick={() => openStoryReader(item)}
                  className="relative flex flex-col overflow-hidden text-left cursor-pointer focus:outline-none transition-transform duration-150"
                  style={{
                    backgroundColor: cardBg,
                    borderRadius: '10px',
                    boxShadow: 'none',
                  }}
                >
                  {isSelected && (
                    <span
                      aria-hidden="true"
                      className="pointer-events-none absolute inset-0 z-30"
                      style={{
                        borderRadius: '10px',
                        border: `3.5px solid #E60012`,
                      }}
                    />
                  )}

                  <div className="w-full h-1/2 overflow-hidden bg-black/25 shrink-0 relative">
                    <img
                      src={item.imageUrl || LOCAL_FALLBACK_ART}
                      alt={item.title}
                      referrerPolicy="no-referrer"
                      onError={(e) => {
                        const img = e.currentTarget;
                        if (img.dataset.fbApplied !== '1') {
                          img.dataset.fbApplied = '1';
                          img.src = LOCAL_FALLBACK_ART;
                        }
                      }}
                      className="w-full h-full object-cover block"
                    />
                    <span
                      className="absolute top-2 left-2 px-2.5 py-0.5 rounded text-[11px] font-ud-bold text-white"
                      style={{ backgroundColor: 'rgba(0,0,0,0.72)' }}
                    >
                      {item.sourceName}
                    </span>
                    {item.videoUrl && (
                      <span
                        className="absolute top-2 right-2 px-2 py-0.5 rounded text-[11px] font-ud-bold text-white flex items-center gap-1"
                        style={{ backgroundColor: accentColor }}
                      >
                        <Play className="w-2.5 h-2.5 fill-current" />
                        <span>Video</span>
                      </span>
                    )}
                  </div>

                  <div className="w-full h-1/2 px-4 py-2 flex flex-col justify-center gap-1 min-h-0">
                    <h3
                      className="font-ud-bold leading-snug line-clamp-2 tracking-tight"
                      style={{
                        fontSize: `${Math.max(18, Math.round(h * 0.036))}px`,
                        color: textMain,
                      }}
                    >
                      {item.title}
                    </h3>
                    <p
                      className="font-ud-regular leading-snug line-clamp-2"
                      style={{
                        fontSize: `${Math.max(12, Math.round(h * 0.021))}px`,
                        color: textMuted,
                      }}
                    >
                      {item.summary}
                    </p>
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* Bottom Controller Bar */}
      <footer style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
        <div className="w-full h-px" style={{ backgroundColor: divider }} />
        <div
          className="flex items-center justify-between"
          style={{ height: `${Math.max(42, Math.round(h * 0.088))}px` }}
        >
          <div className="flex items-center gap-4">
            <BottomControllerGlyph size={metrics.helpIconSize} color={textMain} />

            <div className="flex items-center gap-2">
              <button
                type="button"
                data-testid="news-prev-page"
                disabled={pageIdx <= 0}
                onClick={() => {
                  setPageIdx((p) => Math.max(0, p - 1));
                  setFocusedIdx(0);
                }}
                aria-label="Previous news page (L1)"
                className="flex items-center gap-1.5 px-2 py-1 rounded cursor-pointer disabled:opacity-35 hover:bg-black/5"
              >
                <SwitchPdfIcon
                  button="L1"
                  size={20}
                  fillColor={textMain}
                  cutoutColor={bg}
                />
                <span className="text-xs font-ud-semibold">Prev</span>
              </button>
              <span
                data-testid="news-page-indicator"
                className="text-xs font-mono-tabular"
                style={{ color: textMuted }}
              >
                {pageIdx + 1} / {totalPages}
                {hasMoreFromServer ? '+' : ''}
              </span>
              <button
                type="button"
                data-testid="news-next-page"
                disabled={pageIdx + 1 >= totalPages && !hasMoreFromServer}
                onClick={goNextPage}
                aria-label="Next news page (R1)"
                className="flex items-center gap-1.5 px-2 py-1 rounded cursor-pointer disabled:opacity-35 hover:bg-black/5"
              >
                <SwitchPdfIcon
                  button="R1"
                  size={20}
                  fillColor={textMain}
                  cutoutColor={bg}
                />
                <span className="text-xs font-ud-semibold">
                  {pageIdx + 1 >= totalPages && hasMoreFromServer ? 'Load More' : 'Next'}
                </span>
              </button>
            </div>
          </div>

          <div className="flex items-center gap-6">
            <button
              type="button"
              data-testid="news-refresh-btn"
              onClick={() => fetchFeed(true, 1, false)}
              className="flex items-center gap-2 cursor-pointer hover:opacity-75"
            >
              <SwitchPdfIcon
                button="X"
                size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                fillColor={textMain}
                cutoutColor={bg}
              />
              <span
                className="font-ud-semibold flex items-center gap-1"
                style={{ fontSize: `${metrics.helpFontSize}px`, color: textMain }}
              >
                <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? 'animate-spin' : ''}`} />
                <span>Refresh</span>
              </span>
            </button>

            <button
              type="button"
              onClick={onClose}
              className="flex items-center gap-2 cursor-pointer hover:opacity-75"
            >
              <SwitchPdfIcon
                button="B"
                size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                fillColor={textMain}
                cutoutColor={bg}
              />
              <span
                className="font-ud-semibold"
                style={{ fontSize: `${metrics.helpFontSize}px`, color: textMain }}
              >
                Back
              </span>
            </button>

            {pageItems[focusedIdx] && (
              <button
                type="button"
                onClick={() => openStoryReader(pageItems[focusedIdx])}
                className="flex items-center gap-2 cursor-pointer hover:opacity-75"
              >
                <SwitchPdfIcon
                  button="A"
                  size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                  fillColor={textMain}
                  cutoutColor={bg}
                />
                <span
                  className="font-ud-semibold"
                  style={{ fontSize: `${metrics.helpFontSize}px`, color: textMain }}
                >
                  Open
                </span>
              </button>
            )}
          </div>
        </div>
      </footer>

      {/* FULLSCREEN News Reader: L/R prev/next story, X/Y text size, Simple Fullscreen Play Video */}
      {activeArticle && (
        <article
          data-testid="news-full-reader"
          className="absolute inset-0 z-50 flex flex-col overflow-hidden"
          style={{ backgroundColor: bg, color: textMain }}
        >
          {/* Unified Scroll Container: Hero Photo + Headline + Paragraphs + Inline Small Photos all scroll together */}
          <div
            ref={storyScrollRef}
            data-scroll-container="true"
            className="flex-1 min-h-0 overflow-y-auto no-scrollbar"
          >
            {/* Top Photo Banner inside scroll container so scrolling moves photo + text smoothly */}
            <div
              data-testid="news-reader-hero"
              className="relative w-full bg-black overflow-hidden shrink-0"
              style={{ height: `${Math.max(185, Math.round(h * 0.42))}px` }}
            >
              <img
                src={resolvedHeroImage}
                alt={activeArticle.title}
                referrerPolicy="no-referrer"
                onError={(e) => {
                  const img = e.currentTarget;
                  if (img.dataset.fbApplied !== '1') {
                    img.dataset.fbApplied = '1';
                    img.src = LOCAL_FALLBACK_ART;
                  }
                }}
                className="w-full h-full object-cover block"
              />

              <div
                aria-hidden="true"
                className="absolute inset-x-0 bottom-0 h-24 pointer-events-none"
                style={{
                  background: 'linear-gradient(180deg, rgba(0,0,0,0) 0%, rgba(0,0,0,0.72) 100%)',
                }}
              />

              <div className="absolute top-3.5 left-5 flex items-center gap-2.5">
                <span
                  className="px-3 py-1 rounded-full text-xs font-ud-bold text-white"
                  style={{ backgroundColor: '#E60012' }}
                >
                  {activeArticle.sourceName}
                </span>
                <span className="px-3 py-1 rounded-full text-xs font-ud-semibold bg-black/70 text-white">
                  {activeArticle.publishedAt}
                </span>
              </div>

              <button
                type="button"
                data-testid="news-play-video-fullscreen"
                onClick={launchVideoFullscreen}
                className="absolute bottom-4 right-5 inline-flex items-center gap-2 px-5 py-2.5 rounded-full font-ud-bold text-white cursor-pointer hover:scale-105 transition-transform shadow-lg focus:outline-none"
                style={{ backgroundColor: '#E60012', fontSize: `${Math.max(13, Math.round(h * 0.024))}px` }}
              >
                <Play className="w-4 h-4 fill-current" />
                <span>Play Video</span>
              </button>
            </div>

            {/* Complete Story Body + Inline Paragraph Photos */}
            <div
              style={{
                paddingLeft: `${padX * 1.15}px`,
                paddingRight: `${padX * 1.15}px`,
                paddingTop: '18px',
                paddingBottom: '22px',
              }}
            >
              <h2
                className="font-ud-bold leading-tight tracking-tight mb-3.5"
                style={{ fontSize: `${Math.round(Math.max(24, h * 0.048) * Math.min(1.25, readerTextScale))}px` }}
              >
                {activeArticle.title}
              </h2>

              {articleLoading && (
                <p className="text-xs font-ud-semibold mb-2.5" style={{ color: accentColor }}>
                  Loading complete story...
                </p>
              )}

              <div data-testid="news-story-paragraphs" className="space-y-3.5 pb-4">
                {storyBlocks.map((blk, i) => (
                  <p
                    key={`p-${i}`}
                    className="font-ud-regular leading-relaxed"
                    style={{
                      fontSize: `${Math.round(Math.max(15, h * 0.027) * readerTextScale)}px`,
                      color: isDark ? '#E5E7EB' : '#23272F',
                    }}
                  >
                    {blk.content}
                  </p>
                ))}
              </div>
            </div>
          </div>

          {/* Reader Bottom Bar: Prev/Next Story (LB/RB), Text Size (X/Y), Play Video / Open, Back (B) */}
          <footer style={{ paddingLeft: `${padX}px`, paddingRight: `${padX}px` }}>
            <div className="w-full h-px" style={{ backgroundColor: divider }} />
            <div
              className="flex items-center justify-between gap-4"
              style={{ height: `${Math.max(52, Math.round(h * 0.1))}px` }}
            >
              <div className="flex items-center gap-2.5">
                <button
                  type="button"
                  data-testid="news-open-browser"
                  onClick={() => handleOpenExternalUrl(activeArticle.url)}
                  className="inline-flex items-center gap-2 px-5 py-2 rounded-xl font-ud-bold text-white cursor-pointer hover:opacity-90"
                  style={{
                    backgroundColor: '#E60012',
                    fontSize: `${Math.max(13, Math.round(h * 0.024))}px`,
                  }}
                >
                  <span>Open</span>
                  <ExternalLink className="w-4 h-4" />
                </button>

                <button
                  type="button"
                  data-testid="news-play-video-in-app"
                  onClick={launchVideoFullscreen}
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-ud-bold text-white cursor-pointer focus:outline-none hover:opacity-90"
                  style={{ backgroundColor: '#0EA5E9' }}
                >
                  <Play className="w-3.5 h-3.5 fill-current" />
                  <span>Play Video</span>
                </button>

                <button
                  type="button"
                  data-testid="news-reader-prev"
                  onClick={() => switchArticleByDelta(-1)}
                  className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-ud-semibold cursor-pointer hover:opacity-80"
                  style={{ backgroundColor: cardBg, border: `1px solid ${divider}` }}
                >
                  <SwitchPdfIcon button="L1" size={16} fillColor={textMain} cutoutColor={cardBg} />
                  <ChevronLeft className="w-3.5 h-3.5" />
                  <span>Prev</span>
                </button>

                <button
                  type="button"
                  data-testid="news-reader-next"
                  onClick={() => switchArticleByDelta(1)}
                  className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-ud-semibold cursor-pointer hover:opacity-80"
                  style={{ backgroundColor: cardBg, border: `1px solid ${divider}` }}
                >
                  <span>Next</span>
                  <ChevronRight className="w-3.5 h-3.5" />
                  <SwitchPdfIcon button="R1" size={16} fillColor={textMain} cutoutColor={cardBg} />
                </button>
              </div>

              <div className="flex items-center gap-4">
                <button
                  type="button"
                  data-testid="news-reader-text-size"
                  onClick={cycleTextSize}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-ud-semibold cursor-pointer hover:opacity-80"
                  style={{ backgroundColor: cardBg, border: `1px solid ${divider}` }}
                >
                  <SwitchPdfIcon button="X" size={16} fillColor={textMain} cutoutColor={cardBg} />
                  <Type className="w-3.5 h-3.5" />
                  <span>{Math.round(readerTextScale * 100)}%</span>
                </button>

                <button
                  type="button"
                  onClick={() => setActiveArticle(null)}
                  className="flex items-center gap-2 cursor-pointer hover:opacity-75"
                >
                  <SwitchPdfIcon
                    button="B"
                    size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                    fillColor={textMain}
                    cutoutColor={bg}
                  />
                  <span
                    className="font-ud-semibold"
                    style={{ fontSize: `${metrics.helpFontSize}px`, color: textMain }}
                  >
                    Back
                  </span>
                </button>
              </div>
            </div>
          </footer>

          {/* Simple Fullscreen Video Overlay */}
          {playingVideoFullscreen && (
            <div
              data-testid="news-video-fullscreen"
              className="absolute inset-0 z-50 bg-black flex flex-col"
            >
              <div className="flex items-center justify-between px-5 py-3 bg-black/85 text-white shrink-0">
                <span className="font-ud-bold text-sm truncate pr-4">{activeArticle.title}</span>
                <button
                  type="button"
                  onClick={() => setPlayingVideoFullscreen(false)}
                  className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full bg-white/15 hover:bg-white/25 text-xs font-ud-bold cursor-pointer shrink-0"
                >
                  <Minimize2 className="w-3.5 h-3.5" />
                  <span>Exit Video (B)</span>
                </button>
              </div>
              <div className="flex-1 min-h-0 flex items-center justify-center">
                {!embedVideoSrc ? (
                  <div className="flex items-center gap-2 text-sm text-white/80 font-ud-semibold">
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    <span>Loading video stream...</span>
                  </div>
                ) : /\.(mp4|webm|m4v)(\?|$)/i.test(resolvedVideoUrl || '') ? (
                  <video
                    src={resolvedVideoUrl}
                    controls
                    autoPlay
                    playsInline
                    className="w-full h-full object-contain bg-black"
                  />
                ) : (
                  <iframe
                    src={embedVideoSrc}
                    title={activeArticle.title}
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen"
                    referrerPolicy="strict-origin-when-cross-origin"
                    allowFullScreen
                    className="w-full h-full border-0 bg-black"
                  />
                )}
              </div>
            </div>
          )}
        </article>
      )}
    </div>
  );
}
