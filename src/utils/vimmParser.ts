import type { ApkpGameSummary } from '../types/skyline';

const VIMM_ORIGIN = 'https://vimm.net';

export interface VimmSystemSpec {
  slug: string;
  label: string;
  fullName: string;
  defaultGenres: string[];
}

export const VIMM_SYSTEMS: VimmSystemSpec[] = [
  { slug: 'GBA', label: 'GBA', fullName: 'Game Boy Advance', defaultGenres: ['RPG', 'Adventure', 'Platformer'] },
  { slug: 'DS', label: 'DS', fullName: 'Nintendo DS', defaultGenres: ['RPG', 'Adventure', 'Platformer'] },
  { slug: 'N64', label: 'N64', fullName: 'Nintendo 64', defaultGenres: ['Action', 'Platformer', 'Racing'] },
  { slug: 'SNES', label: 'SNES', fullName: 'Super Nintendo', defaultGenres: ['RPG', 'Platformer', 'Action'] },
  { slug: 'GameCube', label: 'GameCube', fullName: 'Nintendo GameCube', defaultGenres: ['Action', 'Adventure', 'Racing'] },
  { slug: 'PS2', label: 'PS2', fullName: 'PlayStation 2', defaultGenres: ['Action', 'RPG', 'Racing'] },
  { slug: 'PSP', label: 'PSP', fullName: 'PlayStation Portable', defaultGenres: ['Action', 'RPG', 'Racing'] },
  { slug: 'Wii', label: 'Wii', fullName: 'Nintendo Wii', defaultGenres: ['Platformer', 'Sports', 'Action'] },
  { slug: 'PS1', label: 'PS1', fullName: 'PlayStation', defaultGenres: ['RPG', 'Action', 'Racing'] },
  { slug: 'GBC', label: 'GBC', fullName: 'Game Boy Color', defaultGenres: ['RPG', 'Adventure', 'Platformer'] },
  { slug: 'Genesis', label: 'Genesis', fullName: 'Sega Genesis', defaultGenres: ['Action', 'Platformer'] },
  { slug: 'NES', label: 'NES', fullName: 'Nintendo Entertainment System', defaultGenres: ['Platformer', 'Action'] },
];

function decodeHtmlEntities(raw: string): string {
  return raw
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function inferVimmGenres(title: string, systemSpec: VimmSystemSpec): string[] {
  const t = title.toLowerCase();
  const genres = new Set<string>([systemSpec.label]);
  if (/(pokemon|final fantasy|golden sun|chrono|fire emblem|persona|tactics|dragon quest|mario & luigi|kingdom hearts|earthbound)/i.test(t)) {
    genres.add('RPG');
  }
  if (/(kart|f-zero|gran turismo|burnout|need for speed|ridge racer|wipeout|diddy kong racing)/i.test(t)) {
    genres.add('Racing');
  }
  if (/(mario|sonic|kirby|donkey kong|metroid|yoshi|banjo|crash|spyro|mega man|castlevania)/i.test(t)) {
    genres.add('Platformer');
    genres.add('Action');
  }
  if (/(zelda|ocarina|majora|wind waker|twilight|shadow of the colossus|okami|harvest moon)/i.test(t)) {
    genres.add('Adventure');
  }
  if (/(metal gear|god of war|resident evil|devil may cry|star fox|007|goldeneye|perfect dark|halo|doom|contra)/i.test(t)) {
    genres.add('Shooter');
    genres.add('Action');
  }
  if (/(sports|tennis|golf|strikers|tony hawk|fifa|nba|nfl|ssx|wii sports)/i.test(t)) {
    genres.add('Sports');
  }
  if (genres.size === 1) {
    for (const g of systemSpec.defaultGenres) genres.add(g);
  }
  return Array.from(genres);
}

export const VIMM_ALL_SECTIONS: string[] = [
  'number', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
  'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

export function getVimmSectionUrl(systemSlug: string, section: string): string {
  const sec = section === '#' ? 'number' : section.length === 1 ? section.toUpperCase() : section;
  return `${VIMM_ORIGIN}/vault/?p=list&system=${encodeURIComponent(systemSlug)}&section=${encodeURIComponent(sec)}`;
}

export function parseVimmSystemHtml(html: string, systemSlug: string): ApkpGameSummary[] {
  if (!html || html.length < 200) return [];
  const spec = VIMM_SYSTEMS.find((s) => s.slug.toLowerCase() === systemSlug.toLowerCase()) ?? {
    slug: systemSlug,
    label: systemSlug,
    fullName: systemSlug,
    defaultGenres: ['Action', 'Adventure'],
  };

  const results: ApkpGameSummary[] = [];
  const seen = new Set<string>();
  const linkRe = /<a[^>]+href=["']\/vault\/(\d+)["'][^>]*>([\s\S]*?)<\/a>/gi;
  let m: RegExpExecArray | null;
  while ((m = linkRe.exec(html)) !== null) {
    const vaultId = m[1];
    if (!vaultId || seen.has(vaultId)) continue;
    const title = decodeHtmlEntities(m[2]);
    if (!title || title.length < 2) continue;

    seen.add(vaultId);
    const pageUrl = `${VIMM_ORIGIN}/vault/${vaultId}`;
    const rawImg = `${VIMM_ORIGIN}/image.php?type=box&id=${vaultId}`;
    results.push({
      id: `vimm-${spec.slug.toLowerCase()}-${vaultId}`,
      slug: `vimm-${spec.slug.toLowerCase()}-${vaultId}`,
      title,
      description: `${title} (${spec.fullName}) — Classic emulator ROM listing preserved on Vimm's Lair Vault.`,
      rawImageUrl: rawImg,
      coverUrl: `/api/apkports/image?url=${encodeURIComponent(rawImg)}`,
      version: `${spec.label} ROM`,
      portType: 'official',
      categories: inferVimmGenres(title, spec),
      franchises: ["Vimm's Vault", spec.fullName],
      pageUrl,
      downloadUrl: pageUrl,
      sourceSite: 'vimm',
      system: spec.label,
    });
  }
  return results;
}

export const VIMM_FALLBACK_CATALOG: ApkpGameSummary[] = [
  {
    id: 'vimm-gba-5627',
    slug: 'vimm-gba-5627',
    title: 'Pokemon Emerald Version',
    description: 'Pokemon Emerald Version (Game Boy Advance) — Explore Hoenn and challenge the Battle Frontier via Vimm’s Lair Vault.',
    rawImageUrl: 'https://vimm.net/image.php?type=box&id=5627',
    coverUrl: `/api/apkports/image?url=${encodeURIComponent('https://vimm.net/image.php?type=box&id=5627')}`,
    version: 'GBA ROM',
    portType: 'official',
    categories: ['GBA', 'RPG', 'Adventure'],
    franchises: ["Vimm's Vault", 'Game Boy Advance'],
    pageUrl: 'https://vimm.net/vault/5627',
    downloadUrl: 'https://vimm.net/vault/5627',
    sourceSite: 'vimm',
    system: 'GBA',
  },
  {
    id: 'vimm-gba-5381',
    slug: 'vimm-gba-5381',
    title: 'Harvest Moon: Friends of Mineral Town',
    description: 'Harvest Moon: Friends of Mineral Town (Game Boy Advance) — Classic handheld farming RPG via Vimm’s Lair Vault.',
    rawImageUrl: 'https://vimm.net/image.php?type=box&id=5381',
    coverUrl: `/api/apkports/image?url=${encodeURIComponent('https://vimm.net/image.php?type=box&id=5381')}`,
    version: 'GBA ROM',
    portType: 'official',
    categories: ['GBA', 'Simulation', 'RPG'],
    franchises: ["Vimm's Vault", 'Game Boy Advance'],
    pageUrl: 'https://vimm.net/vault/5381',
    downloadUrl: 'https://vimm.net/vault/5381',
    sourceSite: 'vimm',
    system: 'GBA',
  },
  {
    id: 'vimm-gba-5499',
    slug: 'vimm-gba-5499',
    title: 'The Legend of Zelda: The Minish Cap',
    description: 'The Legend of Zelda: The Minish Cap (Game Boy Advance) — Shrink to Picori size across Hyrule via Vimm’s Lair Vault.',
    rawImageUrl: 'https://vimm.net/image.php?type=box&id=5499',
    coverUrl: `/api/apkports/image?url=${encodeURIComponent('https://vimm.net/image.php?type=box&id=5499')}`,
    version: 'GBA ROM',
    portType: 'official',
    categories: ['GBA', 'Adventure', 'Action'],
    franchises: ["Vimm's Vault", 'Game Boy Advance'],
    pageUrl: 'https://vimm.net/vault/5499',
    downloadUrl: 'https://vimm.net/vault/5499',
    sourceSite: 'vimm',
    system: 'GBA',
  },
  {
    id: 'vimm-ds-19225',
    slug: 'vimm-ds-19225',
    title: 'Mario Kart DS',
    description: 'Mario Kart DS (Nintendo DS) — Classic handheld kart racing with Mission Mode via Vimm’s Lair Vault.',
    rawImageUrl: 'https://vimm.net/image.php?type=box&id=19225',
    coverUrl: `/api/apkports/image?url=${encodeURIComponent('https://vimm.net/image.php?type=box&id=19225')}`,
    version: 'DS ROM',
    portType: 'official',
    categories: ['DS', 'Racing', 'Sports'],
    franchises: ["Vimm's Vault", 'Nintendo DS'],
    pageUrl: 'https://vimm.net/vault/19225',
    downloadUrl: 'https://vimm.net/vault/19225',
    sourceSite: 'vimm',
    system: 'DS',
  },
  {
    id: 'vimm-n64-2697',
    slug: 'vimm-n64-2697',
    title: 'The Legend of Zelda: Ocarina of Time',
    description: 'The Legend of Zelda: Ocarina of Time (Nintendo 64) — Iconic 3D Hyrule adventure preserved on Vimm’s Lair Vault.',
    rawImageUrl: 'https://vimm.net/image.php?type=box&id=2697',
    coverUrl: `/api/apkports/image?url=${encodeURIComponent('https://vimm.net/image.php?type=box&id=2697')}`,
    version: 'N64 ROM',
    portType: 'official',
    categories: ['N64', 'Adventure', 'Action'],
    franchises: ["Vimm's Vault", 'Nintendo 64'],
    pageUrl: 'https://vimm.net/vault/2697',
    downloadUrl: 'https://vimm.net/vault/2697',
    sourceSite: 'vimm',
    system: 'N64',
  },
  {
    id: 'vimm-snes-1228',
    slug: 'vimm-snes-1228',
    title: 'Chrono Trigger',
    description: 'Chrono Trigger (Super Nintendo) — Timeless SNES RPG classic preserved on Vimm’s Lair Vault.',
    rawImageUrl: 'https://vimm.net/image.php?type=box&id=1228',
    coverUrl: `/api/apkports/image?url=${encodeURIComponent('https://vimm.net/image.php?type=box&id=1228')}`,
    version: 'SNES ROM',
    portType: 'official',
    categories: ['SNES', 'RPG', 'Adventure'],
    franchises: ["Vimm's Vault", 'Super Nintendo'],
    pageUrl: 'https://vimm.net/vault/1228',
    downloadUrl: 'https://vimm.net/vault/1228',
    sourceSite: 'vimm',
    system: 'SNES',
  },
  {
    id: 'vimm-gc-7483',
    slug: 'vimm-gc-7483',
    title: 'The Legend of Zelda: The Wind Waker',
    description: 'The Legend of Zelda: The Wind Waker (Nintendo GameCube) — Cel-shaded Great Sea adventure via Vimm’s Lair Vault.',
    rawImageUrl: 'https://vimm.net/image.php?type=box&id=7483',
    coverUrl: `/api/apkports/image?url=${encodeURIComponent('https://vimm.net/image.php?type=box&id=7483')}`,
    version: 'GameCube ROM',
    portType: 'official',
    categories: ['GameCube', 'Adventure', 'Action'],
    franchises: ["Vimm's Vault", 'Nintendo GameCube'],
    pageUrl: 'https://vimm.net/vault/7483',
    downloadUrl: 'https://vimm.net/vault/7483',
    sourceSite: 'vimm',
    system: 'GameCube',
  },
  {
    id: 'vimm-ps2-8462',
    slug: 'vimm-ps2-8462',
    title: 'Shadow of the Colossus',
    description: 'Shadow of the Colossus (PlayStation 2) — Scale towering colossi across forbidden lands via Vimm’s Lair Vault.',
    rawImageUrl: 'https://vimm.net/image.php?type=box&id=8462',
    coverUrl: `/api/apkports/image?url=${encodeURIComponent('https://vimm.net/image.php?type=box&id=8462')}`,
    version: 'PS2 ROM',
    portType: 'official',
    categories: ['PS2', 'Adventure', 'Action'],
    franchises: ["Vimm's Vault", 'PlayStation 2'],
    pageUrl: 'https://vimm.net/vault/8462',
    downloadUrl: 'https://vimm.net/vault/8462',
    sourceSite: 'vimm',
    system: 'PS2',
  },
  {
    id: 'vimm-psp-23770',
    slug: 'vimm-psp-23770',
    title: 'God of War: Chains of Olympus',
    description: 'God of War: Chains of Olympus (PlayStation Portable) — Handheld hack-and-slash action via Vimm’s Lair Vault.',
    rawImageUrl: 'https://vimm.net/image.php?type=box&id=23770',
    coverUrl: `/api/apkports/image?url=${encodeURIComponent('https://vimm.net/image.php?type=box&id=23770')}`,
    version: 'PSP ROM',
    portType: 'official',
    categories: ['PSP', 'Action', 'Adventure'],
    franchises: ["Vimm's Vault", 'PlayStation Portable'],
    pageUrl: 'https://vimm.net/vault/23770',
    downloadUrl: 'https://vimm.net/vault/23770',
    sourceSite: 'vimm',
    system: 'PSP',
  },
];
