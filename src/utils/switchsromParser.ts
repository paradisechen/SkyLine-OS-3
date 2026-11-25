import type { ApkpGameSummary } from '../types/skyline';

const SWITCHSROM_ORIGIN = 'https://app.switchsrom.com';

function stripTags(raw: string): string {
  return raw
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;|&rsquo;|&#8217;/g, "'")
    .replace(/&#8211;|&ndash;/g, '-')
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function cleanSwitchsromTitle(raw: string): string {
  return stripTags(raw)
    .replace(/^Download\s+/i, '')
    .replace(/\s*[-–|]?\s*(?:Switch\s+ROM(?:\s*\(?(?:NSP|XCI)(?:\/?\s*XCI)?\)?)?|NSP(?:\s*\/\s*XCI)?|XCI)(?:\s*Free)?(?:\s*Download)?$/i, '')
    .replace(/\s+(?:NSP|XCI|ROM)\s*$/i, '')
    .trim();
}

export function parseSwitchsromWpJson(
  posts: unknown,
  categoryMap: Record<number, string> = {}
): ApkpGameSummary[] {
  if (!Array.isArray(posts)) return [];
  const results: ApkpGameSummary[] = [];
  const seen = new Set<string>();

  for (const entry of posts) {
    if (!entry || typeof entry !== 'object') continue;
    const p = entry as Record<string, unknown>;
    const link = typeof p.link === 'string' ? p.link.trim() : '';
    const slug = typeof p.slug === 'string' ? p.slug.trim() : String(p.id ?? '');
    if (!slug || seen.has(slug)) continue;

    const titleObj = p.title as Record<string, unknown> | undefined;
    const rawTitle = typeof titleObj?.rendered === 'string' ? titleObj.rendered : '';
    const title = cleanSwitchsromTitle(rawTitle);
    if (!title || title.length < 2) continue;

    const excerptObj = p.excerpt as Record<string, unknown> | undefined;
    const cleanDesc =
      typeof excerptObj?.rendered === 'string'
        ? stripTags(excerptObj.rendered).slice(0, 280)
        : `${title} — Nintendo Switch ROM (NSP / XCI) from SwitchsROM.com.`;

    const yoast = p.yoast_head_json as Record<string, unknown> | undefined;
    const ogImgs = Array.isArray(yoast?.og_image)
      ? (yoast.og_image as Record<string, unknown>[])
      : [];
    let rawImg = typeof ogImgs[0]?.url === 'string' ? ogImgs[0].url : '';
    if (!rawImg && typeof p.yoast_head === 'string') {
      const m = p.yoast_head.match(/property=["']og:image["'][^>]+content=["']([^"']+)["']/i);
      if (m?.[1]) rawImg = m[1];
    }

    const catIds = Array.isArray(p.categories) ? p.categories : [];
    const cats = catIds
      .map((cid) => categoryMap[Number(cid)])
      .filter((name): name is string => Boolean(name));

    const pageUrl = link || `${SWITCHSROM_ORIGIN}/${slug}/`;
    const coverUrl = rawImg
      ? `/api/apkports/image?url=${encodeURIComponent(rawImg)}`
      : 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-mario-bros-wonder-switch/hero';

    seen.add(slug);
    results.push({
      id: `srom-${slug}`,
      slug: `srom-${slug}`,
      title,
      description: cleanDesc,
      rawImageUrl: rawImg,
      coverUrl,
      version: 'NSP / XCI',
      portType: 'official',
      categories: cats.length > 0 ? cats : ['Action', 'Adventure'],
      franchises: ['SwitchsROM', 'Nintendo Switch'],
      pageUrl,
      downloadUrl: pageUrl,
      sourceSite: 'switchsrom',
      system: 'Switch',
    });
  }

  return results;
}

export const SWITCHSROM_FALLBACK_CATALOG: ApkpGameSummary[] = [
  {
    id: 'srom-pokemon-legends-z-a',
    slug: 'srom-pokemon-legends-z-a',
    title: 'Pokemon Legends: Z-A',
    description:
      'Set in Lumiose City across a massive urban redevelopment project for Nintendo Switch (NSP/XCI).',
    rawImageUrl: 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/p/pokemon-legends-arceus-switch/hero',
    coverUrl: 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/p/pokemon-legends-arceus-switch/hero',
    version: 'NSP / XCI',
    portType: 'official',
    categories: ['RPG', 'Adventure'],
    franchises: ['SwitchsROM', 'Nintendo Switch'],
    pageUrl: 'https://app.switchsrom.com/roms/',
    downloadUrl: 'https://app.switchsrom.com/roms/',
    sourceSite: 'switchsrom',
    system: 'Switch',
  },
  {
    id: 'srom-mario-luigi-brothership',
    slug: 'srom-mario-and-luigi-brothership',
    title: 'Mario & Luigi: Brothership',
    description:
      'Set sail across Shipshape Island in this vibrant turn-based Mario & Luigi RPG adventure on Nintendo Switch.',
    rawImageUrl: 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/m/mario-and-luigi-brothership-switch/hero',
    coverUrl: 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/m/mario-and-luigi-brothership-switch/hero',
    version: 'NSP / XCI',
    portType: 'official',
    categories: ['RPG', 'Adventure'],
    franchises: ['SwitchsROM', 'Nintendo Switch'],
    pageUrl: 'https://app.switchsrom.com/roms/',
    downloadUrl: 'https://app.switchsrom.com/roms/',
    sourceSite: 'switchsrom',
    system: 'Switch',
  },
  {
    id: 'srom-zelda-echoes-of-wisdom',
    slug: 'srom-the-legend-of-zelda-echoes-of-wisdom',
    title: 'The Legend of Zelda: Echoes of Wisdom',
    description:
      'Save Hyrule using Princess Zelda and the Tri Rod to create echoes across puzzles and dungeons.',
    rawImageUrl: 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-echoes-of-wisdom-switch/hero',
    coverUrl: 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-echoes-of-wisdom-switch/hero',
    version: 'NSP / XCI',
    portType: 'official',
    categories: ['Adventure', 'Action'],
    franchises: ['SwitchsROM', 'Nintendo Switch'],
    pageUrl: 'https://app.switchsrom.com/roms/',
    downloadUrl: 'https://app.switchsrom.com/roms/',
    sourceSite: 'switchsrom',
    system: 'Switch',
  },
  {
    id: 'srom-super-smash-bros-ultimate',
    slug: 'srom-super-smash-bros-ultimate',
    title: 'Super Smash Bros. Ultimate',
    description:
      'Every fighter in series history collides across 100+ stages in Nintendo Switch NSP/XCI format.',
    rawImageUrl: 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-smash-bros-ultimate-switch/hero',
    coverUrl: 'https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-smash-bros-ultimate-switch/hero',
    version: 'NSP / XCI',
    portType: 'official',
    categories: ['Action', 'Sports'],
    franchises: ['SwitchsROM', 'Nintendo Switch'],
    pageUrl: 'https://app.switchsrom.com/roms/',
    downloadUrl: 'https://app.switchsrom.com/roms/',
    sourceSite: 'switchsrom',
    system: 'Switch',
  },
];
