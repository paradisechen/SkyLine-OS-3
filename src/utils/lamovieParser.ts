import type { LaMovieMediaItem } from '../types/skyline';

export const LAMOVIE_ORIGIN = 'https://lamovie.org';
export const LAMOVIE_API_BASE = 'https://lamovie.org/wp-api/v1';
export const LAMOVIE_IMAGE_BASE = 'https://lamovie.org/wp-content/uploads';

export const LAMOVIE_GENRE_MAP: Record<number, string> = {
  18: 'Acción',
  34: 'Aventura',
  130: 'Animación',
  131: 'Comedia',
  132: 'Crimen',
  133: 'Documental',
  134: 'Drama',
  135: 'Familia',
  136: 'Fantasía',
  137: 'Historia',
  138: 'Terror',
  139: 'Música',
  140: 'Misterio',
  141: 'Romance',
  142: 'Ciencia Ficción',
  143: 'Suspense',
  144: 'Bélica',
  398: 'Estrenos',
  520: 'Tendencias',
  703: 'Destacadas',
};

export interface RawLaMoviePost {
  _id?: number;
  title?: string;
  slug?: string;
  type?: string;
  overview?: string;
  rating?: string | number;
  runtime?: string | number;
  years?: number[];
  release_date?: string;
  genres?: number[];
  images?: {
    poster?: string;
    backdrop?: string;
    logo?: string;
  };
}

function buildLaMovieImgUrl(rel?: string): { raw: string; proxied: string } {
  const clean = String(rel || '').trim();
  if (!clean) return { raw: '', proxied: '' };
  const raw = clean.startsWith('http') ? clean : `${LAMOVIE_IMAGE_BASE}${clean.startsWith('/') ? '' : '/'}${clean}`;
  return {
    raw,
    proxied: `/api/feeds/image?url=${encodeURIComponent(raw)}`,
  };
}

export function parseLaMoviePosts(
  posts: RawLaMoviePost[],
  fallbackType: 'movies' | 'tvshows' = 'movies'
): LaMovieMediaItem[] {
  if (!Array.isArray(posts)) return [];
  const items: LaMovieMediaItem[] = [];
  for (const post of posts) {
    if (!post?._id || !post?.title || !post?.slug) continue;
    const mediaType: 'movies' | 'tvshows' = post.type === 'tvshows' || fallbackType === 'tvshows' ? 'tvshows' : 'movies';
    const poster = buildLaMovieImgUrl(post.images?.poster);
    const backdrop = buildLaMovieImgUrl(post.images?.backdrop || post.images?.poster);
    const yearMatch = post.release_date?.match(/\b(19|20)\d{2}\b/) || post.title.match(/\b(19|20)\d{2}\b/);
    const genreLabels = Array.isArray(post.genres)
      ? post.genres.map((id) => LAMOVIE_GENRE_MAP[id]).filter((x): x is string => Boolean(x))
      : [];
    const permalinkPath = mediaType === 'tvshows' ? 'series' : 'peliculas';
    items.push({
      id: `lamovie-${mediaType}-${post._id}`,
      postId: Number(post._id),
      slug: post.slug,
      title: String(post.title).trim(),
      mediaType,
      overview: String(post.overview || '').trim() || `${post.title} disponible en streaming HD vía LaMovie.`,
      posterUrl: poster.proxied || '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      backdropUrl: backdrop.proxied || poster.proxied || '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      rawPosterUrl: poster.raw,
      rawBackdropUrl: backdrop.raw,
      rating: post.rating ? String(post.rating) : undefined,
      runtime: post.runtime ? `${Math.round(Number(post.runtime))} min` : undefined,
      genres: genreLabels.length > 0 ? genreLabels : [mediaType === 'tvshows' ? 'Series' : 'Películas'],
      year: yearMatch?.[0],
      pageUrl: `${LAMOVIE_ORIGIN}/${permalinkPath}/${post.slug}/`,
    });
  }
  return items;
}

export const LAMOVIE_FALLBACK_ITEMS: LaMovieMediaItem[] = [
  {
    id: 'lamovie-movies-102971',
    postId: 102971,
    slug: 'la-familia-mitchell-vs-las-maquinas-2021',
    title: 'La familia Mitchell vs. las máquinas (2021)',
    mediaType: 'movies',
    overview:
      'El apocalipsis robot llegó y puso freno al viaje por carretera de los Mitchell, la familia más rara del mundo. Ahora depende de ellos salvar a la raza humana.',
    posterUrl: `/api/feeds/image?url=${encodeURIComponent(`${LAMOVIE_IMAGE_BASE}/thumbs/049d3d9696bc3de22323ffb9009edf55_hd.webp`)}`,
    backdropUrl: `/api/feeds/image?url=${encodeURIComponent(`${LAMOVIE_IMAGE_BASE}/backdrops/049d3d9696bc3de22323ffb9009edf55.webp`)}`,
    rawPosterUrl: `${LAMOVIE_IMAGE_BASE}/thumbs/049d3d9696bc3de22323ffb9009edf55_hd.webp`,
    rawBackdropUrl: `${LAMOVIE_IMAGE_BASE}/backdrops/049d3d9696bc3de22323ffb9009edf55.webp`,
    rating: '7.8',
    runtime: '110 min',
    genres: ['Animación', 'Aventura', 'Acción'],
    year: '2021',
    pageUrl: 'https://lamovie.org/peliculas/la-familia-mitchell-vs-las-maquinas-2021/',
  },
  {
    id: 'lamovie-tvshows-102631',
    postId: 102631,
    slug: 'csi-miami-2002',
    title: 'CSI: Miami (2002)',
    mediaType: 'tvshows',
    overview:
      'El equipo forense de Miami investiga casos complejos combinando ciencia avanzada y trabajo de campo en el sur de la Florida.',
    posterUrl: `/api/feeds/image?url=${encodeURIComponent(`${LAMOVIE_IMAGE_BASE}/thumbs/806beafe154032a5b818e97b4420ad98_hd.webp`)}`,
    backdropUrl: `/api/feeds/image?url=${encodeURIComponent(`${LAMOVIE_IMAGE_BASE}/backdrops/806beafe154032a5b818e97b4420ad98.webp`)}`,
    rawPosterUrl: `${LAMOVIE_IMAGE_BASE}/thumbs/806beafe154032a5b818e97b4420ad98_hd.webp`,
    rawBackdropUrl: `${LAMOVIE_IMAGE_BASE}/backdrops/806beafe154032a5b818e97b4420ad98.webp`,
    rating: '7.5',
    genres: ['Crimen', 'Drama', 'Misterio'],
    year: '2002',
    pageUrl: 'https://lamovie.org/series/csi-miami-2002/',
  },
];

export function extractUnwrappedLaMovieEmbedUrl(html: string): string | null {
  const frameMatch =
    html.match(/<iframe[^>]+id=["']frame["'][^>]+src=["']([^"']+)["']/i) ||
    html.match(/<iframe[^>]+src=["']((?:https?:)?\/\/vimeos\.net\/embed-[^"']+)["']/i) ||
    html.match(/<iframe[^>]+src=["']((?:https?:)?\/\/[^"']+)["']/i) ||
    html.match(/window\.location(?:\.href)?\s*=\s*["']((?:https?:)?\/\/[^"']+)["']/i);
  let raw = frameMatch?.[1]?.trim();
  if (!raw) return null;
  if (raw.startsWith('//')) raw = `https:${raw}`;
  if (!/^https?:\/\//i.test(raw)) return null;
  if (/vimeos\.net\/embed-/i.test(raw)) {
    return raw.split('?')[0];
  }
  return raw;
}

export function rewriteLaMovieEmbedHtml(html: string, sourceUrl: string): string {
  let origin = 'https://vimeos.net';
  try {
    origin = new URL(sourceUrl).origin;
  } catch {
    origin = 'https://vimeos.net';
  }

  let cleaned = html
    // Remove anti-sandbox blocker scripts ("SANDBOX DETECTADO")
    .replace(/<script\b[^>]*>[\s\S]*?(?:voeSandboxBlocked|SANDBOX DETECTADO)[\s\S]*?<\/script>/gi, '')
    // Remove devtools-blocking scripts & popunder ad script
    .replace(/<script\b[^>]*disable-devtool[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<script\b[^>]*src=["'][^"']*\/js\/pop\.js[^"']*["'][^>]*>[\s\S]*?<\/script>/gi, '')
    // Strip meta CSP frame-ancestors if present
    .replace(/<meta[^>]+http-equiv=["']?Content-Security-Policy["']?[^>]*>/gi, '');

  const headInject =
    `<base href="${origin}/">` +
    `<style>html,body{margin:0!important;padding:0!important;width:100%!important;height:100%!important;background:#000!important;overflow:hidden!important;}body>div:first-of-type,#vplayer{width:100%!important;height:100%!important;}</style>` +
    `<script>window.addEventListener('keydown',function(e){if(e.key==='Escape'||e.key==='BrowserBack'){try{window.parent.postMessage({type:'skyline-browser-escape'},'*');}catch(_){}}},true);</script>`;

  if (/<head[^>]*>/i.test(cleaned)) {
    cleaned = cleaned.replace(/<head([^>]*)>/i, `<head$1>${headInject}`);
  } else {
    cleaned = `<!doctype html><html><head>${headInject}</head><body>${cleaned}</body></html>`;
  }
  return cleaned;
}

export function filterAndPaginateLaMovieCatalog(
  items: LaMovieMediaItem[],
  options: {
    letter?: string;
    genre?: string;
    q?: string;
    page?: number;
    pageSize?: number;
  }
): {
  items: LaMovieMediaItem[];
  totalCount: number;
  totalPages: number;
  page: number;
} {
  const rawLetter = String(options.letter || 'All').trim();
  const letter = rawLetter === '#' ? '#' : /^[a-z]$/i.test(rawLetter) ? rawLetter.toUpperCase() : 'All';
  const genre = String(options.genre || '').trim().toLowerCase();
  const q = String(options.q || '').trim().toLowerCase();
  const pageSize = Math.max(1, Math.min(100, Number(options.pageSize ?? 20) || 20));

  let filtered = items.filter((item) => {
    if (letter !== 'All') {
      const first = String(item.title || '').trim().charAt(0).toUpperCase();
      if (!first) return false;
      if (letter === '#') {
        if (/[A-Z]/.test(first)) return false;
      } else if (first !== letter) {
        return false;
      }
    }
    if (genre && genre !== 'all') {
      const hasGenre = item.genres.some((g) => g.toLowerCase().includes(genre));
      if (!hasGenre) return false;
    }
    if (q) {
      const inTitle = item.title.toLowerCase().includes(q);
      const inOverview = (item.overview || '').toLowerCase().includes(q);
      if (!inTitle && !inOverview) return false;
    }
    return true;
  });

  if (letter !== 'All') {
    filtered = [...filtered].sort((a, b) => a.title.localeCompare(b.title));
  }

  const totalCount = filtered.length;
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const requestedPage = Math.max(1, Number(options.page ?? 1) || 1);
  const safePage = Math.min(requestedPage, totalPages);
  const start = (safePage - 1) * pageSize;

  return {
    items: filtered.slice(start, start + pageSize),
    totalCount,
    totalPages,
    page: safePage,
  };
}

