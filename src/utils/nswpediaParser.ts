import type { ApkpGameSummary } from '../types/skyline';

const NSWPEDIA_ORIGIN = 'https://nswpedia.com';

function stripTags(raw: string): string {
  return raw
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;|&rsquo;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function resolveNswImageUrl(raw: string | undefined | null): string {
  if (!raw) return '';
  const s = raw.trim();
  if (!s) return '';
  const abs = s.startsWith('http://') || s.startsWith('https://')
    ? s
    : s.startsWith('//')
      ? `https:${s}`
      : s.startsWith('/')
        ? `${NSWPEDIA_ORIGIN}${s}`
        : `${NSWPEDIA_ORIGIN}/${s}`;
  return `/api/apkports/image?url=${encodeURIComponent(abs)}`;
}

/**
 * Parses Nintendo Switch game listings from nswpedia.com WordPress/catalog HTML.
 */
export function parseNswpediaListHtml(html: string): ApkpGameSummary[] {
  if (!html || html.length < 100) return [];
  const results: ApkpGameSummary[] = [];
  const seen = new Set<string>();

  const articleRe = /<article\b[^>]*>([\s\S]*?)<\/article>/gi;
  let m: RegExpExecArray | null;
  while ((m = articleRe.exec(html)) !== null && results.length < 40) {
    const block = m[1];
    const linkM =
      block.match(/<a[^>]+href=["'](https?:\/\/(?:www\.)?nswpedia\.com\/[^"']+)["'][^>]*>/i) ||
      block.match(/<a[^>]+href=["'](\/[^"']+)["'][^>]*>/i);
    if (!linkM) continue;
    const rawHref = linkM[1];
    const url = rawHref.startsWith('http') ? rawHref : `${NSWPEDIA_ORIGIN}${rawHref}`;
    const slugMatch = url.replace(/\/+$/, '').split('/').pop() || '';
    if (!slugMatch || seen.has(slugMatch)) continue;

    const titleM =
      block.match(/<h[1-4][^>]*>([\s\S]*?)<\/h[1-4]>/i) ||
      block.match(/title=["']([^"']+)["']/i);
    const title = titleM ? stripTags(titleM[1]).replace(/\s+(?:NSP|XCI|NSZ|Switch ROM).*$/i, '') : '';
    if (!title || title.length < 2) continue;

    const imgM = block.match(/<img[^>]+(?:data-lazy-src|data-src|src)=["']([^"']+)["']/i);
    const rawImg = imgM?.[1] || '';
    const descM = block.match(/<p[^>]*>([\s\S]*?)<\/p>/i);
    const catMatches = [...block.matchAll(/rel=["']category[^"']*["'][^>]*>([^<]+)</gi)].map((c) =>
      stripTags(c[1])
    );

    seen.add(slugMatch);
    results.push({
      id: `nsw-${slugMatch}`,
      slug: `nsw-${slugMatch}`,
      title,
      description: descM
        ? stripTags(descM[1])
        : `${title} for Nintendo Switch (NS). Available on NSWPedia.com in NSP/XCI format.`,
      rawImageUrl: rawImg,
      coverUrl: rawImg ? resolveNswImageUrl(rawImg) : 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-mario-bros-wonder-switch/hero',
      version: 'NS ROM',
      portType: 'official',
      categories: catMatches.length > 0 ? catMatches : ['Action', 'Adventure'],
      franchises: ['Nintendo Switch'],
      pageUrl: url,
      downloadUrl: url,
      sourceSite: 'nswpedia',
      system: 'Switch',
    });
  }

  return results;
}

export function parseNswpediaWpJson(posts: unknown, categoryMap: Record<number, string> = {}): ApkpGameSummary[] {
  if (!Array.isArray(posts)) return [];
  const results: ApkpGameSummary[] = [];
  const seen = new Set<string>();
  for (const entry of posts) {
    if (!entry || typeof entry !== 'object') continue;
    const p = entry as Record<string, unknown>;
    const link = typeof p.link === 'string' ? p.link : '';
    const slug = typeof p.slug === 'string' ? p.slug : String(p.id ?? '');
    if (!slug || seen.has(slug)) continue;

    const titleObj = p.title as Record<string, unknown> | undefined;
    const rawTitle = typeof titleObj?.rendered === 'string' ? stripTags(titleObj.rendered) : '';
    const title = rawTitle.replace(/\s+(?:NSP|XCI|NSZ|Switch ROM).*$/i, '').trim();
    if (!title) continue;

    const excerptObj = p.excerpt as Record<string, unknown> | undefined;
    const cleanDesc = typeof excerptObj?.rendered === 'string'
      ? stripTags(excerptObj.rendered).slice(0, 280)
      : `${title} for Nintendo Switch via NSWPedia.com.`;

    const yoast = p.yoast_head_json as Record<string, unknown> | undefined;
    const ogImgs = Array.isArray(yoast?.og_image) ? (yoast.og_image as Record<string, unknown>[]) : [];
    const rawImg = typeof ogImgs[0]?.url === 'string' ? ogImgs[0].url : '';

    const catIds = Array.isArray(p.categories) ? p.categories : [];
    const cats = catIds
      .map((cid) => categoryMap[Number(cid)])
      .filter((name): name is string => Boolean(name));

    seen.add(slug);
    results.push({
      id: `nsw-${slug}`,
      slug: `nsw-${slug}`,
      title,
      description: cleanDesc,
      rawImageUrl: rawImg,
      coverUrl: rawImg
        ? resolveNswImageUrl(rawImg)
        : 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-mario-bros-wonder-switch/hero',
      version: 'NS ROM',
      portType: 'official',
      categories: cats.length > 0 ? cats : ['Action', 'Adventure'],
      franchises: ['Nintendo Switch'],
      pageUrl: link || `${NSWPEDIA_ORIGIN}/${slug}`,
      downloadUrl: link || `${NSWPEDIA_ORIGIN}/${slug}`,
      sourceSite: 'nswpedia',
      system: 'Switch',
    });
  }
  return results;
}

export const NSWPEDIA_FALLBACK_CATALOG: ApkpGameSummary[] = [
  {
    id: 'nsw-zelda-totk',
    slug: 'nsw-the-legend-of-zelda-tears-of-the-kingdom',
    title: 'The Legend of Zelda: Tears of the Kingdom',
    description:
      'Explore the vast lands and skies of Hyrule using Ultrahand, Fuse, and Recall across floating islands and deep chasms on Nintendo Switch.',
    rawImageUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-tears-of-the-kingdom-switch/hero',
    coverUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-tears-of-the-kingdom-switch/hero',
    version: 'v1.2.1 · NSP',
    portType: 'official',
    categories: ['Adventure', 'Action', 'RPG'],
    franchises: ['Nintendo Switch'],
    downloadUrl: 'http://nswpedia.com/nintendo-switch-roms/the-legend-of-zelda-tears-of-the-kingdom',
    videoUrl: 'https://www.youtube.com/embed/uHGShqcAHlQ?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'nswpedia',
  },
  {
    id: 'nsw-mario-kart-8-deluxe',
    slug: 'nsw-mario-kart-8-deluxe',
    title: 'Mario Kart 8 Deluxe',
    description:
      'Hit the road with the definitive Mario Kart 8 edition including Booster Course Pass tracks, Battle Mode, and 60fps Switch gameplay.',
    rawImageUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/m/mario-kart-8-deluxe-switch/hero',
    coverUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/m/mario-kart-8-deluxe-switch/hero',
    version: 'v3.0.3 · NSP',
    portType: 'official',
    categories: ['Racing', 'Sports'],
    franchises: ['Nintendo Switch'],
    downloadUrl: 'http://nswpedia.com/nintendo-switch-roms/mario-kart-8-deluxe',
    videoUrl: 'https://www.youtube.com/embed/tKlRN2YpxRE?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'nswpedia',
  },
  {
    id: 'nsw-super-mario-wonder',
    slug: 'nsw-super-mario-bros-wonder',
    title: 'Super Mario Bros. Wonder',
    description:
      'Classic side-scrolling Mario gameplay turned upside down by Wonder Flowers across the Flower Kingdom on Nintendo Switch.',
    rawImageUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-mario-bros-wonder-switch/hero',
    coverUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-mario-bros-wonder-switch/hero',
    version: 'v1.0.1 · NSP',
    portType: 'official',
    categories: ['Platformer', 'Action'],
    franchises: ['Nintendo Switch'],
    downloadUrl: 'http://nswpedia.com/nintendo-switch-roms/super-mario-bros-wonder',
    videoUrl: 'https://www.youtube.com/embed/JStAYvbeSHc?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'nswpedia',
  },
  {
    id: 'nsw-metroid-prime-remastered',
    slug: 'nsw-metroid-prime-remastered',
    title: 'Metroid Prime Remastered',
    description:
      'Samus Aran returns in a revamped first-person adventure on Tallon IV with dual-stick controls and overhauled HD visuals.',
    rawImageUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/m/metroid-prime-remastered-switch/hero',
    coverUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/m/metroid-prime-remastered-switch/hero',
    version: 'v1.0.0 · XCI',
    portType: 'official',
    categories: ['Shooter', 'Adventure', 'Action'],
    franchises: ['Nintendo Switch'],
    downloadUrl: 'http://nswpedia.com/nintendo-switch-roms/metroid-prime-remastered',
    videoUrl: 'https://www.youtube.com/embed/e9OQO3g5b5c?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'nswpedia',
  },
  {
    id: 'nsw-xenoblade-3',
    slug: 'nsw-xenoblade-chronicles-3',
    title: 'Xenoblade Chronicles 3',
    description:
      'Six soldiers from rival nations unite across the vast world of Aionios in an unforgettable Nintendo Switch action RPG.',
    rawImageUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/x/xenoblade-chronicles-3-switch/hero',
    coverUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/x/xenoblade-chronicles-3-switch/hero',
    version: 'v2.2.0 · NSP',
    portType: 'official',
    categories: ['RPG', 'Adventure'],
    franchises: ['Nintendo Switch'],
    downloadUrl: 'http://nswpedia.com/nintendo-switch-roms/xenoblade-chronicles-3',
    videoUrl: 'https://www.youtube.com/embed/t-iNpDKuYb8?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'nswpedia',
  },
  {
    id: 'nsw-animal-crossing',
    slug: 'nsw-animal-crossing-new-horizons',
    title: 'Animal Crossing: New Horizons',
    description:
      'Build your deserted island paradise from scratch with crafting, terraforming, and seasonal villagers on Nintendo Switch.',
    rawImageUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/a/animal-crossing-new-horizons-switch/hero',
    coverUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/a/animal-crossing-new-horizons-switch/hero',
    version: 'v2.0.6 · NSP',
    portType: 'official',
    categories: ['Simulation', 'Adventure'],
    franchises: ['Nintendo Switch'],
    downloadUrl: 'http://nswpedia.com/nintendo-switch-roms/animal-crossing-new-horizons',
    videoUrl: 'https://www.youtube.com/embed/_3YNL0OWio0?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'nswpedia',
  },
  {
    id: 'nsw-jamboree',
    slug: 'nsw-super-mario-party-jamboree',
    title: 'Super Mario Party Jamboree',
    description:
      'Over 110 minigames across seven vibrant boards on Nintendo Switch, tuned for Joy-Con and controller party sessions.',
    rawImageUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-mario-party-jamboree-switch/hero',
    coverUrl:
      'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-mario-party-jamboree-switch/hero',
    version: 'v1.1.0 · NSP',
    portType: 'official',
    categories: ['Sports', 'Platformer'],
    franchises: ['Nintendo Switch'],
    downloadUrl: 'http://nswpedia.com/nintendo-switch-roms/super-mario-party-jamboree',
    videoUrl: 'https://www.youtube.com/embed/X_w2kY6j8jY?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'nswpedia',
  },
];
