import type { ApkpGameSummary } from '../types/skyline';

export const ESHOP_ALPHABET_LETTERS: string[] = [
  'All',
  '#',
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

export function normalizeAlphabetLetter(raw: string): string {
  const trimmed = String(raw || 'All').trim();
  if (trimmed === '#') return '#';
  if (/^[a-z]$/i.test(trimmed)) return trimmed.toUpperCase();
  return 'All';
}

export function matchesAlphabetLetter(title: string, letter: string): boolean {
  const normalized = normalizeAlphabetLetter(letter);
  if (normalized === 'All') return true;
  const cleanTitle = String(title || '').trim();
  const first = cleanTitle.charAt(0).toUpperCase();
  if (!first) return false;
  if (normalized === '#') return !/[A-Z]/.test(first);
  return first === normalized;
}

export function stepAlphabetLetter(currentLetter: string, delta: -1 | 1): string {
  const idx = ESHOP_ALPHABET_LETTERS.indexOf(normalizeAlphabetLetter(currentLetter));
  const safeIdx = idx >= 0 ? idx : 0;
  const nextIdx = (safeIdx + delta + ESHOP_ALPHABET_LETTERS.length) % ESHOP_ALPHABET_LETTERS.length;
  return ESHOP_ALPHABET_LETTERS[nextIdx];
}

/**
 * Combines all game sources (APKPorts, SwitchsROM, NSWPedia, Vimm's Vault, Archive.org)
 * into ONE unified interleaved list without truncating or dividing by source.
 */
export function unifyEshopCatalog(lists: ApkpGameSummary[][]): ApkpGameSummary[] {
  const merged: ApkpGameSummary[] = [];
  const seenIds = new Set<string>();
  const maxLen = lists.reduce((acc, arr) => Math.max(acc, arr.length), 0);

  for (let i = 0; i < maxLen; i++) {
    for (const arr of lists) {
      const item = arr[i];
      if (!item || seenIds.has(item.id)) continue;
      seenIds.add(item.id);
      merged.push(item);
    }
  }
  return merged;
}

export function filterAndPaginateUnifiedCatalog(
  catalog: ApkpGameSummary[],
  options: {
    letter?: string;
    category?: string;
    q?: string;
    portType?: string;
    section?: string;
    sort?: string;
    page?: number;
    pageSize?: number;
  }
): {
  games: ApkpGameSummary[];
  totalCount: number;
  totalPages: number;
  page: number;
} {
  const letter = normalizeAlphabetLetter(options.letter || 'All');
  const category = String(options.category || '').trim().toLowerCase();
  const q = String(options.q || '').trim().toLowerCase();
  const portType = String(options.portType || '').trim();
  const section = String(options.section || 'games').trim();
  const sort = String(options.sort || 'popular').trim();
  const pageSize = Math.max(1, Math.min(400, Number(options.pageSize ?? 20) || 20));

  let filtered = catalog.filter((g) => {
    if (!matchesAlphabetLetter(g.title, letter)) return false;
    if (q) {
      const inTitle = g.title.toLowerCase().includes(q);
      const inDesc = (g.description || '').toLowerCase().includes(q);
      const inSys = (g.system || '').toLowerCase().includes(q);
      if (!inTitle && !inDesc && !inSys) return false;
    }
    if (portType && g.portType !== portType) return false;
    if (section === 'fan-games' && g.portType !== 'fan-game') return false;
    if (category) {
      const hasCat = g.categories.some(
        (c) => c.toLowerCase() === category || c.toLowerCase().includes(category) || category.includes(c.toLowerCase())
      );
      const matchSys = (g.system || '').toLowerCase() === category;
      const inDesc = (g.description || '').toLowerCase().includes(category);
      if (!hasCat && !matchSys && !inDesc) return false;
    }
    return true;
  });

  if (letter !== 'All' || sort === 'title') {
    filtered = [...filtered].sort((a, b) => a.title.localeCompare(b.title));
  }

  const totalCount = filtered.length;
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const requestedPage = Math.max(1, Number(options.page ?? 1) || 1);
  const safePage = Math.min(requestedPage, totalPages);
  const start = (safePage - 1) * pageSize;

  return {
    games: filtered.slice(start, start + pageSize),
    totalCount,
    totalPages,
    page: safePage,
  };
}
