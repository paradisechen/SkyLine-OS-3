import type { ApkpGameSummary } from '../types/skyline';

export const ARCHIVE_GAMECUBE_URL = 'https://archive.org/download/ultimate-rom-collection/Game%20cube/';
export const ARCHIVE_PSP_URL = 'https://archive.org/download/ultimate-rom-collection/PSP/';

const ROM_EXT_RE = /\.(rvz|iso|cso|chd|gcz|wbfs|zip|7z)$/i;

export function cleanArchiveRomTitle(rawName: string): string {
  let decoded = rawName;
  try {
    decoded = decodeURIComponent(rawName);
  } catch {
    decoded = rawName;
  }
  return decoded
    .replace(ROM_EXT_RE, '')
    .replace(/\s*\[[^\]]*\]/g, '')
    .replace(/\s*\((?:USA|Europe|Japan|World|En|Fr|De|Es|It|Rev\s*\d+|v[\d.]+|Proto|Beta)[^)]*\)/gi, '')
    .replace(/\s*\((?:Disc\s*\d+)\)/gi, (m) => ` ${m.trim()}`)
    .replace(/\s+/g, ' ')
    .trim();
}

function inferArchiveGenres(title: string, systemLabel: string): string[] {
  const t = title.toLowerCase();
  const genres = new Set<string>([systemLabel]);
  if (/(pokemon|tales|final fantasy|persona|baten|kingdom hearts|skies|jeanne|crisis core|paper mario|dragon)/i.test(t)) {
    genres.add('RPG');
  }
  if (/(kart|f-zero|ridge racer|wipeout|burnout|gran turismo|need for speed|auto modellista|kirby air ride)/i.test(t)) {
    genres.add('Racing');
  }
  if (/(mario|sonic|luigi|monkey ball|ape escape|daxter|locoroco|patapon|chibi-robo|billy hatcher|donkey)/i.test(t)) {
    genres.add('Platformer');
    genres.add('Action');
  }
  if (/(zelda|metroid|star fox|okami|tomb raider|metal gear|silent hill|resident evil|god of war|prince of persia)/i.test(t)) {
    genres.add('Adventure');
    genres.add('Action');
  }
  if (/(strike|007|time splitters|socom|syphon filter|killzone|medal of honor|gun)/i.test(t)) {
    genres.add('Shooter');
  }
  if (/(strikers|tennis|golf|baseball|fifa|nba|ssx|tony hawk|hot shots|wave race|1080)/i.test(t)) {
    genres.add('Sports');
  }
  if (genres.size === 1) {
    genres.add('Action');
    genres.add('Adventure');
  }
  return Array.from(genres);
}

function makeArchiveCoverSvg(title: string, systemLabel: string): string {
  const safeTitle = title.replace(/[<>&"']/g, '').slice(0, 32);
  const c1 = systemLabel === 'GameCube' ? '#4C1D95' : '#0F172A';
  const c2 = systemLabel === 'GameCube' ? '#7C3AED' : '#0284C7';
  const badge = systemLabel === 'GameCube' ? 'GAMECUBE · RVZ' : 'PSP · ISO';
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 360"><defs><linearGradient id="ag" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stop-color="${c1}"/><stop offset="100%" stop-color="${c2}"/></linearGradient></defs><rect width="640" height="360" fill="url(#ag)"/><circle cx="530" cy="80" r="110" fill="#ffffff" opacity="0.08"/><rect x="36" y="42" width="170" height="30" rx="8" fill="#000000" opacity="0.45"/><text x="48" y="63" fill="#ffffff" font-family="system-ui,sans-serif" font-size="15" font-weight="700">${badge}</text><text x="36" y="290" fill="#ffffff" font-family="system-ui,sans-serif" font-size="28" font-weight="700">${safeTitle}</text><text x="36" y="324" fill="#E2E8F0" font-family="system-ui,sans-serif" font-size="14">Internet Archive Ultimate ROM Collection</text></svg>`;
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
}

export function parseArchiveOrgDirectoryHtml(
  html: string,
  baseUrl: string,
  systemLabel: 'GameCube' | 'PSP'
): ApkpGameSummary[] {
  if (!html || html.length < 100) return [];
  const results: ApkpGameSummary[] = [];
  const seen = new Set<string>();
  const linkRe = /<a[^>]+href=["']([^"']+\.(?:rvz|iso|cso|chd|gcz|zip|7z))["'][^>]*>([\s\S]*?)<\/a>/gi;
  let m: RegExpExecArray | null;
  while ((m = linkRe.exec(html)) !== null) {
    const rawHref = (m[1] || '').trim();
    if (!rawHref || rawHref.startsWith('?') || rawHref.startsWith('/')) continue;
    const labelText = (m[2] || '').replace(/<[^>]+>/g, ' ').trim();
    const title = cleanArchiveRomTitle(labelText || rawHref);
    if (!title || title.length < 2) continue;

    const slugSafe = title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '')
      .slice(0, 48);
    const id = `archive-${systemLabel.toLowerCase()}-${slugSafe}`;
    if (seen.has(id)) continue;
    seen.add(id);

    const downloadUrl = rawHref.startsWith('http') ? rawHref : `${baseUrl.replace(/\/$/, '')}/${rawHref}`;
    const coverSvg = makeArchiveCoverSvg(title, systemLabel);
    results.push({
      id,
      slug: id,
      title,
      description: `${title} (${systemLabel}) — Verified ROM hosted in the Internet Archive Ultimate ROM Collection.`,
      coverUrl: coverSvg,
      rawImageUrl: coverSvg,
      version: systemLabel === 'GameCube' ? 'GC RVZ' : 'PSP ISO',
      portType: 'official',
      categories: inferArchiveGenres(title, systemLabel),
      franchises: ['Internet Archive', systemLabel],
      pageUrl: downloadUrl,
      downloadUrl,
      sourceSite: 'archive',
      system: systemLabel,
    });
  }
  return results;
}

export const ARCHIVE_FALLBACK_CATALOG: ApkpGameSummary[] = [
  {
    id: 'archive-gamecube-animal-crossing',
    slug: 'archive-gamecube-animal-crossing',
    title: 'Animal Crossing',
    description: 'Animal Crossing (GameCube) — Verified RVZ release in the Internet Archive Ultimate ROM Collection.',
    coverUrl: makeArchiveCoverSvg('Animal Crossing', 'GameCube'),
    rawImageUrl: makeArchiveCoverSvg('Animal Crossing', 'GameCube'),
    version: 'GC RVZ',
    portType: 'official',
    categories: ['GameCube', 'Simulation', 'Adventure'],
    franchises: ['Internet Archive', 'GameCube'],
    pageUrl: `${ARCHIVE_GAMECUBE_URL}Animal%20Crossing%20%28USA%29.rvz`,
    downloadUrl: `${ARCHIVE_GAMECUBE_URL}Animal%20Crossing%20%28USA%29.rvz`,
    sourceSite: 'archive',
    system: 'GameCube',
  },
  {
    id: 'archive-gamecube-luigi-s-mansion',
    slug: 'archive-gamecube-luigi-s-mansion',
    title: "Luigi's Mansion",
    description: "Luigi's Mansion (GameCube) — Verified RVZ release in the Internet Archive Ultimate ROM Collection.",
    coverUrl: makeArchiveCoverSvg("Luigi's Mansion", 'GameCube'),
    rawImageUrl: makeArchiveCoverSvg("Luigi's Mansion", 'GameCube'),
    version: 'GC RVZ',
    portType: 'official',
    categories: ['GameCube', 'Action', 'Adventure'],
    franchises: ['Internet Archive', 'GameCube'],
    pageUrl: ARCHIVE_GAMECUBE_URL,
    downloadUrl: ARCHIVE_GAMECUBE_URL,
    sourceSite: 'archive',
    system: 'GameCube',
  },
  {
    id: 'archive-gamecube-metroid-prime',
    slug: 'archive-gamecube-metroid-prime',
    title: 'Metroid Prime',
    description: 'Metroid Prime (GameCube) — Verified RVZ release in the Internet Archive Ultimate ROM Collection.',
    coverUrl: makeArchiveCoverSvg('Metroid Prime', 'GameCube'),
    rawImageUrl: makeArchiveCoverSvg('Metroid Prime', 'GameCube'),
    version: 'GC RVZ',
    portType: 'official',
    categories: ['GameCube', 'Action', 'Adventure'],
    franchises: ['Internet Archive', 'GameCube'],
    pageUrl: ARCHIVE_GAMECUBE_URL,
    downloadUrl: ARCHIVE_GAMECUBE_URL,
    sourceSite: 'archive',
    system: 'GameCube',
  },
  {
    id: 'archive-psp-ape-escape-on-the-loose',
    slug: 'archive-psp-ape-escape-on-the-loose',
    title: 'Ape Escape - On the Loose',
    description: 'Ape Escape - On the Loose (PSP) — Verified ISO release in the Internet Archive Ultimate ROM Collection.',
    coverUrl: makeArchiveCoverSvg('Ape Escape - On the Loose', 'PSP'),
    rawImageUrl: makeArchiveCoverSvg('Ape Escape - On the Loose', 'PSP'),
    version: 'PSP ISO',
    portType: 'official',
    categories: ['PSP', 'Platformer', 'Action'],
    franchises: ['Internet Archive', 'PSP'],
    pageUrl: `${ARCHIVE_PSP_URL}Ape%20Escape%20-%20On%20the%20Loose%20%28USA%29.iso`,
    downloadUrl: `${ARCHIVE_PSP_URL}Ape%20Escape%20-%20On%20the%20Loose%20%28USA%29.iso`,
    sourceSite: 'archive',
    system: 'PSP',
  },
  {
    id: 'archive-psp-crisis-core-final-fantasy-vii',
    slug: 'archive-psp-crisis-core-final-fantasy-vii',
    title: 'Crisis Core: Final Fantasy VII',
    description: 'Crisis Core: Final Fantasy VII (PSP) — Verified ISO release in the Internet Archive Ultimate ROM Collection.',
    coverUrl: makeArchiveCoverSvg('Crisis Core: Final Fantasy VII', 'PSP'),
    rawImageUrl: makeArchiveCoverSvg('Crisis Core: Final Fantasy VII', 'PSP'),
    version: 'PSP ISO',
    portType: 'official',
    categories: ['PSP', 'RPG', 'Action'],
    franchises: ['Internet Archive', 'PSP'],
    pageUrl: ARCHIVE_PSP_URL,
    downloadUrl: ARCHIVE_PSP_URL,
    sourceSite: 'archive',
    system: 'PSP',
  },
];
