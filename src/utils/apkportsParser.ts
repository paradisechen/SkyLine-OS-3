import type { ApkpCategory, ApkpGameDetail, ApkpGameSummary } from '../types/skyline';

const APKP_ORIGIN = 'https://www.apkports.com';

export function resolveRawApkPortsImageUrl(raw: string | undefined | null): string {
  if (!raw) return '';
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  if (raw.startsWith('/')) {
    return `${APKP_ORIGIN}${raw}`;
  }
  return `${APKP_ORIGIN}/${raw}`;
}

export function normalizeApkPortsImageUrl(raw: string | undefined | null): string {
  const absolute = resolveRawApkPortsImageUrl(raw);
  if (!absolute) return '';
  return `/api/apkports/image?url=${encodeURIComponent(absolute)}`;
}

function stripTags(raw: string): string {
  return raw
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&nbsp;/g, ' ')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function normalizeVideoUrl(raw: unknown): string | undefined {
  if (typeof raw !== 'string') return undefined;
  const s = raw.trim();
  if (!s) return undefined;
  const yt =
    s.match(/youtube\.com\/embed\/([A-Za-z0-9_-]{6,})/i) ||
    s.match(/youtube\.com\/watch\?v=([A-Za-z0-9_-]{6,})/i) ||
    s.match(/youtu\.be\/([A-Za-z0-9_-]{6,})/i);
  if (yt?.[1]) return `https://www.youtube.com/embed/${yt[1]}?autoplay=1&mute=1&playsinline=1&rel=0&vq=small`;
  if (/\.mp4(\?|$)/i.test(s) || /^https?:\/\//i.test(s)) return s;
  return undefined;
}

/**
 * Decodes React Router v7 / Turbo-Stream style `enqueue("...")` payloads
 * embedded in www.apkports.com SSR responses.
 */
export function decodeRouterFlightPayload(html: string): Record<string, unknown> | null {
  const matches = [...html.matchAll(/enqueue\(("[\s\S]*?")\);/g)];
  for (const m of matches) {
    try {
      const innerJson = JSON.parse(m[1]) as string;
      const rawArr = JSON.parse(innerJson) as unknown[];
      if (!Array.isArray(rawArr) || rawArr.length === 0) continue;

      const resolveNode = (idx: unknown, depth = 0): unknown => {
        if (depth > 10 || typeof idx !== 'number') return idx;
        if (idx === -5) return undefined;
        if (idx === -7) return null;
        if (idx < 0 || idx >= rawArr.length) return idx;
        const val = rawArr[idx];
        if (Array.isArray(val)) {
          return val.map((item) => resolveNode(item, depth + 1));
        }
        if (val && typeof val === 'object') {
          const out: Record<string, unknown> = {};
          for (const [k, vIdx] of Object.entries(val)) {
            const keyName =
              k.startsWith('_') && Number.isFinite(Number(k.slice(1)))
                ? String(rawArr[Number(k.slice(1))] ?? k)
                : k;
            out[keyName] = resolveNode(vIdx, depth + 1);
          }
          return out;
        }
        return val;
      };

      const root = resolveNode(0) as Record<string, unknown> | null;
      if (root && typeof root === 'object' && root.loaderData) {
        return root;
      }
    } catch {
      // Try next enqueue block
    }
  }
  return null;
}

export function mapRawGameToSummary(
  item: Record<string, unknown>,
  defaultPortType: 'official' | 'unofficial' | 'fan-game' = 'unofficial'
): ApkpGameSummary {
  const thumbs = (item.main_image_thumbs ?? {}) as Record<string, unknown>;
  const preferredThumb =
    (typeof thumbs['640'] === 'string' && thumbs['640']) ||
    (typeof thumbs['480'] === 'string' && thumbs['480']) ||
    (typeof thumbs['320'] === 'string' && thumbs['320']) ||
    (typeof item.main_image === 'string' && item.main_image) ||
    '';

  const portRaw = String(item.port_type ?? item.portType ?? defaultPortType).toLowerCase();
  const portType: 'official' | 'unofficial' | 'fan-game' =
    portRaw === 'official'
      ? 'official'
      : portRaw.includes('fan')
        ? 'fan-game'
        : 'unofficial';

  const slug = String(item.slug ?? '');
  const rawDesc = String(item.short_description ?? item.description ?? '').trim();
  const cleanDesc = rawDesc ? stripTags(rawDesc.replace(/^##+\s*/gm, '')).slice(0, 320) : undefined;
  const videoUrl =
    normalizeVideoUrl(item.trailer_url) ||
    normalizeVideoUrl(item.video_url) ||
    normalizeVideoUrl(item.youtube_url);
  const pageUrl = slug ? `${APKP_ORIGIN}/game/${encodeURIComponent(slug)}` : `${APKP_ORIGIN}/games`;
  const downloadUrl =
    (typeof item.download_url === 'string' && item.download_url) ||
    (typeof item.download_link === 'string' && item.download_link) ||
    pageUrl;

  const cats = Array.isArray(item.categories)
    ? item.categories.map(String)
    : typeof item.category === 'string' && item.category
      ? [item.category]
      : [];

  return {
    id: String(item.id ?? slug ?? Math.random()),
    slug,
    title: String(item.title ?? 'Untitled Port'),
    description: cleanDesc,
    rawImageUrl: resolveRawApkPortsImageUrl(preferredThumb),
    coverUrl: normalizeApkPortsImageUrl(preferredThumb),
    version: item.version ? String(item.version) : portType === 'official' ? 'Official' : 'Port',
    portType,
    categories: cats,
    franchises: Array.isArray(item.franchises) ? item.franchises.map(String) : [],
    videoUrl,
    pageUrl,
    downloadUrl: pageUrl,
    sourceSite: 'apkports',
    system: 'Android Port',
  };
}

export function parseApkPortsApiJson(raw: unknown, section: string = 'games'): ApkpGameSummary[] {
  const arr = Array.isArray(raw)
    ? raw
    : raw && typeof raw === 'object' && Array.isArray((raw as Record<string, unknown>).games)
      ? ((raw as Record<string, unknown>).games as unknown[])
      : [];
  const defaultPort = section === 'fan-games' ? 'fan-game' : 'unofficial';
  const out: ApkpGameSummary[] = [];
  for (const entry of arr) {
    if (!entry || typeof entry !== 'object') continue;
    const rec = entry as Record<string, unknown>;
    if (rec.is_hidden === true) continue;
    if (!rec.title) continue;
    const mapped = mapRawGameToSummary(rec, defaultPort);
    if (section === 'fan-games' && mapped.portType !== 'fan-game') continue;
    out.push(mapped);
  }
  return out;
}

export function parseApkPortsListHtml(
  html: string,
  section: string = 'games'
): {
  games: ApkpGameSummary[];
  totalCount: number;
  totalPages: number;
  page: number;
  categories: ApkpCategory[];
} {
  const root = decodeRouterFlightPayload(html);
  const loaderData = (root?.loaderData ?? {}) as Record<string, Record<string, unknown>>;

  const routeKey =
    Object.keys(loaderData).find((k) => k !== 'root' && loaderData[k]) ?? 'routes/games';
  const payload = loaderData[routeKey] ?? {};

  const rawGames = (
    Array.isArray(payload.games)
      ? payload.games
      : Array.isArray(payload.results)
        ? payload.results
        : []
  ) as Record<string, unknown>[];

  const defaultPort = section === 'fan-games' ? 'fan-game' : 'unofficial';
  const games = rawGames
    .filter((g) => g && typeof g === 'object' && g.title)
    .map((g) => mapRawGameToSummary(g, defaultPort));

  const rawCategories = Array.isArray(payload.categories) ? payload.categories : [];
  const categories: ApkpCategory[] = rawCategories
    .filter((c): c is Record<string, unknown> => Boolean(c && typeof c === 'object'))
    .map((c) => ({
      name: String(c.name ?? ''),
      slug: String(c.slug ?? ''),
    }))
    .filter((c) => c.name && c.slug);

  return {
    games,
    totalCount: Number(payload.totalCount ?? games.length) || games.length,
    totalPages: Number(payload.totalPages ?? 1) || 1,
    page: Number(payload.page ?? 1) || 1,
    categories,
  };
}

export function parseApkPortsDetailHtml(html: string, slug: string): ApkpGameDetail | null {
  const root = decodeRouterFlightPayload(html);
  const loaderData = (root?.loaderData ?? {}) as Record<string, Record<string, unknown>>;
  const routeKey = Object.keys(loaderData).find((k) => k !== 'root' && loaderData[k]?.game);
  const payload = routeKey ? loaderData[routeKey] : null;
  const g = payload?.game as Record<string, unknown> | undefined;
  if (!g) return null;

  const base = mapRawGameToSummary(g);
  const secondary = Array.isArray(g.secondary_images) ? g.secondary_images : [];
  const screenshots = secondary
    .map((entry) => {
      if (typeof entry === 'string') return normalizeApkPortsImageUrl(entry);
      if (entry && typeof entry === 'object') {
        const rec = entry as Record<string, unknown>;
        const mirrors = (rec.mirrors ?? {}) as Record<string, unknown>;
        const chosen =
          (typeof mirrors.local_backup === 'string' && mirrors.local_backup) ||
          (typeof rec.url === 'string' && rec.url) ||
          (typeof mirrors.pixhost === 'string' && mirrors.pixhost) ||
          '';
        return normalizeApkPortsImageUrl(chosen);
      }
      return '';
    })
    .filter(Boolean);

  const metaDesc =
    html.match(/<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']/i)?.[1] ||
    html.match(/<meta[^>]+property=["']og:description["'][^>]+content=["']([^"']+)["']/i)?.[1] ||
    '';

  const rawDesc = stripTags(
    String(g.description ?? g.long_description ?? g.short_description ?? metaDesc ?? '')
  );

  const videoFromHtml =
    html.match(/https?:\/\/[^\s"'<>]+\.mp4(?:\?[^\s"'<>]*)?/i)?.[0] ||
    html.match(/https?:\/\/(?:www\.)?youtube\.com\/embed\/([A-Za-z0-9_-]{6,})/i)?.[0];

  const sourceUrl = `${APKP_ORIGIN}/game/${encodeURIComponent(base.slug || slug)}`;
  const downloadUrl =
    (typeof g.download_url === 'string' && g.download_url) ||
    (typeof g.apk_url === 'string' && g.apk_url) ||
    `${sourceUrl}#download`;

  const resolvedVideo =
    base.videoUrl || normalizeVideoUrl(g.video_url) || normalizeVideoUrl(videoFromHtml);

  const fallbackMeta = APKP_FALLBACK_CATALOG.find((fb) => fb.slug === (base.slug || slug));

  return {
    ...base,
    slug: base.slug || slug,
    description:
      rawDesc ||
      fallbackMeta?.description ||
      `${base.title} brings full action-adventure gameplay and handheld controller support to Android.`,
    requirements: g.requirements ? String(g.requirements) : 'Android 10+ · Snapdragon 865 / Adreno GPU recommended',
    developer: g.developer ? String(g.developer) : base.franchises[0] || 'APKPorts Community',
    releaseDate: g.updated_at ? String(g.updated_at).slice(0, 10) : '2026',
    fileSize: g.file_size ? String(g.file_size) : undefined,
    screenshots: screenshots.length > 0 ? screenshots : [base.coverUrl],
    sourceUrl,
    downloadUrl,
    videoUrl: resolvedVideo || fallbackMeta?.videoUrl,
  };
}

/** Curated offline/fallback snapshot from www.apkports.com with real game descriptions & sample trailers */
export const APKP_FALLBACK_CATALOG: ApkpGameSummary[] = [
  {
    id: '0ed7d4fb-37bd-4f69-b0d0-16b9307c0c2e',
    slug: 'grand-theft-auto-v-0ed7d4',
    title: 'Grand Theft Auto V',
    description:
      'Switch seamlessly between Michael, Franklin, and Trevor across the sun-soaked metropolis of Los Santos and rugged Blaine County, featuring high-stakes heists, vehicle tuning, and expansive open-world freedom.',
    rawImageUrl:
      'https://www.apkports.com/uploads/thumbs/cover_0ed7d4fb-37bd-4f69-b0d0-16b9307c0c2e_e93b0cba2465-480.webp',
    coverUrl:
      '/api/apkports/image?url=' +
      encodeURIComponent(
        'https://www.apkports.com/uploads/thumbs/cover_0ed7d4fb-37bd-4f69-b0d0-16b9307c0c2e_e93b0cba2465-480.webp'
      ),
    version: '1.61',
    portType: 'unofficial',
    categories: ['Action', 'Adventure', 'Shooter'],
    franchises: ['GTA'],
    downloadUrl: 'https://www.apkports.com/game/grand-theft-auto-v-0ed7d4#download',
    videoUrl: 'https://www.youtube.com/embed/QkkoHAzjnUs?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: 'ed5e68a0-dfae-4cb5-a2c9-c6bb165eb08e',
    slug: 'dark-souls-ii-scholar-of-the-first-sin-ed5e68',
    title: 'DARK SOULS II: Scholar of the First Sin',
    description:
      'Journey through the fallen kingdom of Drangleic in this unforgiving dark fantasy action RPG. Master deliberate stamina-based swordplay, build devastating sorceries, and topple towering bosses.',
    rawImageUrl:
      'https://www.apkports.com/uploads/thumbs/cover_ed5e68a0-dfae-4cb5-a2c9-c6bb165eb08e_87d4e336025d-480.webp',
    coverUrl:
      '/api/apkports/image?url=' +
      encodeURIComponent(
        'https://www.apkports.com/uploads/thumbs/cover_ed5e68a0-dfae-4cb5-a2c9-c6bb165eb08e_87d4e336025d-480.webp'
      ),
    version: '0.1.4',
    portType: 'unofficial',
    categories: ['Action', 'RPG'],
    franchises: ['Dark Souls'],
    downloadUrl: 'https://www.apkports.com/game/dark-souls-ii-scholar-of-the-first-sin-ed5e68#download',
    videoUrl: 'https://www.youtube.com/embed/v6U0wQ3r8w4?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: 'dbcf6eb8-b3e3-4a5c-80d8-47d741829ddc',
    slug: 'left-4-dead-dbcf6e',
    title: 'Left 4 Dead',
    description:
      'Four immune survivors fight side by side through swarming infected hordes across cinematic urban campaigns. Coordinate firepower, rescue teammates from special infected, and sprint for the safehouse.',
    rawImageUrl:
      'https://www.apkports.com/uploads/thumbs/cover_dbcf6eb8-b3e3-4a5c-80d8-47d741829ddc_90c98f24d3bc-480.webp',
    coverUrl:
      '/api/apkports/image?url=' +
      encodeURIComponent(
        'https://www.apkports.com/uploads/thumbs/cover_dbcf6eb8-b3e3-4a5c-80d8-47d741829ddc_90c98f24d3bc-480.webp'
      ),
    version: '1.0.4',
    portType: 'unofficial',
    categories: ['Action', 'Shooter'],
    franchises: ['Left 4 Dead'],
    downloadUrl: 'https://www.apkports.com/game/left-4-dead-dbcf6e#download',
    videoUrl: 'https://www.youtube.com/embed/V_2x7-P1tCg?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: 'a4fae8b8-709c-4d09-82fc-0be90af8fd39',
    slug: 'assassins-creed-iv-black-flag-a4fae8',
    title: "Assassin's Creed IV Black Flag",
    description:
      'Captain the Jackdaw across the Golden Age of Piracy as brash corsair Edward Kenway. Plunder galleons, dive sunken shipwrecks, and explore seamless Caribbean islands from Havana to Nassau.',
    rawImageUrl:
      'https://www.apkports.com/uploads/thumbs/cover_a4fae8b8-709c-4d09-82fc-0be90af8fd39_6bc5a997bc60-320.webp',
    coverUrl:
      '/api/apkports/image?url=' +
      encodeURIComponent(
        'https://www.apkports.com/uploads/thumbs/cover_a4fae8b8-709c-4d09-82fc-0be90af8fd39_6bc5a997bc60-320.webp'
      ),
    version: '0.8.13-15',
    portType: 'unofficial',
    categories: ['Action', 'Adventure'],
    franchises: ["Assassin's Creed"],
    downloadUrl: 'https://www.apkports.com/game/assassins-creed-iv-black-flag-a4fae8#download',
    videoUrl: 'https://www.youtube.com/embed/OwVe4ZNeQZk?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: 'a3e0dc4b-3d2a-421f-a1be-018b3ce1160c',
    slug: 'tony-hawks-pro-skater-4-a3e0dc',
    title: "Tony Hawk's Pro Skater 4",
    description:
      'Drop into open-roam skateparks from Alcatraz to London with zero countdown timers. Chain manuals, spine transfers, and signature Pro tricks while chasing towering combo high scores.',
    rawImageUrl:
      'https://www.apkports.com/uploads/thumbs/cover_a3e0dc4b-3d2a-421f-a1be-018b3ce1160c_7be9b245e915-480.webp',
    coverUrl:
      '/api/apkports/image?url=' +
      encodeURIComponent(
        'https://www.apkports.com/uploads/thumbs/cover_a3e0dc4b-3d2a-421f-a1be-018b3ce1160c_7be9b245e915-480.webp'
      ),
    version: '1.0.3',
    portType: 'unofficial',
    categories: ['Sports', 'Platformer', 'Racing'],
    franchises: ['Tony Hawk'],
    downloadUrl: 'https://www.apkports.com/game/tony-hawks-pro-skater-4-a3e0dc#download',
    videoUrl: 'https://www.youtube.com/embed/4V9b2aM1x6s?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: '7af1d216-f993-423c-b90d-6db8b1b7bd83',
    slug: 'the-sims-2-7af1d2',
    title: 'The Sims 2',
    description:
      'Design vibrant neighborhoods, guide multi-generational families through careers and aspirations, and build dream homes down to the finest wallpaper and furniture detail.',
    rawImageUrl:
      'https://www.apkports.com/uploads/thumbs/cover_7af1d216-f993-423c-b90d-6db8b1b7bd83_a027a62a8609-480.webp',
    coverUrl:
      '/api/apkports/image?url=' +
      encodeURIComponent(
        'https://www.apkports.com/uploads/thumbs/cover_7af1d216-f993-423c-b90d-6db8b1b7bd83_a027a62a8609-480.webp'
      ),
    version: '0.1.1-dev',
    portType: 'unofficial',
    categories: ['Simulation'],
    franchises: ['The Sims'],
    downloadUrl: 'https://www.apkports.com/game/the-sims-2-7af1d2#download',
    videoUrl: 'https://www.youtube.com/embed/tR1H2xP3m4I?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: 'apkp-hollow-knight',
    slug: 'hollow-knight',
    title: 'Hollow Knight',
    description:
      'Forge your own path in Hallownest! An epic action adventure through a vast ruined kingdom of insects and heroes with responsive gamepad controls on Android.',
    rawImageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/367520/header.jpg',
    coverUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/367520/header.jpg',
    version: '1.5.78',
    portType: 'unofficial',
    categories: ['Action', 'Adventure', 'Platformer'],
    franchises: ['Hollow Knight'],
    downloadUrl: 'https://www.apkports.com/game/hollow-knight#download',
    videoUrl: 'https://www.youtube.com/embed/UAO2urG23S4?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: 'apkp-cuphead',
    slug: 'cuphead-android',
    title: 'Cuphead',
    description:
      'Classic run-and-gun action game heavily focused on boss battles, inspired by 1930s cartoons with watercolor backgrounds and big-band jazz.',
    rawImageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/268910/header.jpg',
    coverUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/268910/header.jpg',
    version: '1.3.4',
    portType: 'unofficial',
    categories: ['Action', 'Platformer', 'Shooter'],
    franchises: ['Cuphead'],
    downloadUrl: 'https://www.apkports.com/game/cuphead-android#download',
    videoUrl: 'https://www.youtube.com/embed/NN-9SQXoi50?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: 'apkp-sonic-mania',
    slug: 'sonic-mania-plus',
    title: 'Sonic Mania Plus',
    description:
      'Crisp 60fps widescreen RSDKv5 Android port featuring Encore Mode, classic remixed zones, and instant handheld controller support.',
    rawImageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/584400/header.jpg',
    coverUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/584400/header.jpg',
    version: '1.05',
    portType: 'unofficial',
    categories: ['Platformer', 'Action'],
    franchises: ['Sonic'],
    downloadUrl: 'https://www.apkports.com/game/sonic-mania-plus#download',
    videoUrl: 'https://www.youtube.com/embed/wyP83g56d7w?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: 'apkp-half-life-2',
    slug: 'half-life-2-android',
    title: 'Half-Life 2',
    description:
      'Pick up the crowbar as Gordon Freeman in Valve’s landmark sci-fi FPS, running natively on Android via the Source Engine port.',
    rawImageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/220/header.jpg',
    coverUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/220/header.jpg',
    version: '1.14',
    portType: 'unofficial',
    categories: ['Shooter', 'Action'],
    franchises: ['Half-Life'],
    downloadUrl: 'https://www.apkports.com/game/half-life-2-android#download',
    videoUrl: 'https://www.youtube.com/embed/UKA7JkV51Jw?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: 'apkp-stardew-valley',
    slug: 'stardew-valley',
    title: 'Stardew Valley',
    description:
      'Inherit your grandfather’s old farm plot in Stardew Valley. Raise animals, grow seasonal crops, and explore caves on Retroid Pocket 5.',
    rawImageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/413150/header.jpg',
    coverUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/413150/header.jpg',
    version: '1.6.14',
    portType: 'official',
    categories: ['Simulation', 'RPG'],
    franchises: ['Stardew Valley'],
    downloadUrl: 'https://www.apkports.com/game/stardew-valley#download',
    videoUrl: 'https://www.youtube.com/embed/ot7uXNQskhs?autoplay=1&mute=1&playsinline=1&rel=0&vq=small',
    sourceSite: 'apkports',
  },
  {
    id: 'apkp-horizon-chase',
    slug: 'horizon-chase',
    title: 'Horizon Chase Turbo',
    description:
      'Classic arcade racing inspired by 90s hits with vibrant low-poly visuals, synthwave soundtrack, and 60fps handheld controls.',
    rawImageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/389140/header.jpg',
    coverUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/389140/header.jpg',
    version: '2.6.0',
    portType: 'official',
    categories: ['Racing', 'Sports'],
    franchises: ['Horizon Chase'],
    downloadUrl: 'https://www.apkports.com/game/horizon-chase#download',
    sourceSite: 'apkports',
  },
];
