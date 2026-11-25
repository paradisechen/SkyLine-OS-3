import type { ArticleContentBlock, GeneralNewsCategoryId, NewsFeedItem, NsoCategoryId } from '../types/skyline';

function decodeEntities(text: string): string {
  return text
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/&#(\d+);/g, (_, dec) => String.fromCharCode(Number(dec)))
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&nbsp;/g, ' ');
}

function stripHtml(html: string): string {
  return decodeEntities(html)
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function extractTag(block: string, tag: string): string {
  const re = new RegExp(`<${tag}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/${tag}>`, 'i');
  const m = block.match(re);
  return m ? decodeEntities(m[1]).trim() : '';
}

function isLowQualityThumbUrl(url: string): boolean {
  const low = url.toLowerCase();
  return (
    low.includes('favicon') ||
    low.includes('avatar') ||
    low.includes('emoji') ||
    low.includes('1x1') ||
    low.includes('pixel.') ||
    low.includes('gravatar') ||
    low.includes('/icon') ||
    low.includes('badge') ||
    low.includes('logo')
  );
}

function normalizeHttpUrl(raw: string): string {
  let u = decodeEntities(raw).trim();
  if (u.startsWith('//')) u = `https:${u}`;
  return u;
}

function extractYouTubeId(text: string): string | undefined {
  const ytMatch =
    text.match(/<yt:videoId>([A-Za-z0-9_-]{6,})<\/yt:videoId>/i) ||
    text.match(/https?:\/\/(?:www\.)?youtube\.com\/embed\/([A-Za-z0-9_-]{6,})/i) ||
    text.match(/https?:\/\/(?:www\.)?youtube\.com\/v\/([A-Za-z0-9_-]{6,})/i) ||
    text.match(/https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([A-Za-z0-9_-]{6,})/i) ||
    text.match(/https?:\/\/youtu\.be\/([A-Za-z0-9_-]{6,})/i);
  return ytMatch?.[1];
}

function extractVideoFromBlock(block: string): string | undefined {
  const ytId = extractYouTubeId(block);
  if (ytId) {
    return `https://www.youtube.com/embed/${ytId}`;
  }
  const mp4Match = block.match(/https?:\/\/[^\s"'<>]+\.mp4(?:\?[^\s"'<>]*)?/i);
  if (mp4Match?.[0]) {
    return decodeEntities(mp4Match[0]);
  }
  return undefined;
}

function isVideoOrNonImageUrl(url: string): boolean {
  const low = url.toLowerCase();
  return (
    low.includes('youtube.com/') ||
    low.includes('youtu.be/') ||
    /\.(mp4|webm|m4v|swf|mp3|ogg|wav)(\?|$)/i.test(low)
  );
}

function extractImageFromBlock(block: string, fallbackImg: string): string {
  const candidates: string[] = [];
  const regexes = [
    /<media:thumbnail[^>]+url=["']([^"']+)["']/gi,
    /<enclosure[^>]+type=["']image\/[^"']+["'][^>]*url=["']([^"']+)["']/gi,
    /<enclosure[^>]+url=["']([^"']+)["'][^>]*type=["']image\//gi,
    /<media:content[^>]+medium=["']image["'][^>]*url=["']([^"']+)["']/gi,
    /<media:content[^>]+url=["']([^"']+)["'][^>]*medium=["']image["']/gi,
    /<media:content[^>]+url=["']([^"']+)["']/gi,
    /<img[^>]+data-lazy-src=["']([^"']+)["']/gi,
    /<img[^>]+data-original=["']([^"']+)["']/gi,
    /<img[^>]+data-src=["']([^"']+)["']/gi,
    /<img[^>]+src=["']([^"']+)["']/gi,
    /<img[^>]+srcset=["']([^"'\s,]+)/gi,
  ];
  for (const re of regexes) {
    let m: RegExpExecArray | null;
    while ((m = re.exec(block)) !== null) {
      const u = normalizeHttpUrl(m[1] || '');
      if (u && /^https?:\/\//i.test(u) && !isLowQualityThumbUrl(u) && !isVideoOrNonImageUrl(u)) {
        const upgraded = u.replace(/-\d{2,3}x\d{2,3}(\.(?:jpg|jpeg|png|webp))/i, '$1');
        candidates.push(upgraded);
      }
    }
  }
  if (candidates.length === 0) {
    const ytId = extractYouTubeId(block);
    if (ytId) {
      candidates.push(`https://i.ytimg.com/vi/${ytId}/hqdefault.jpg`);
    }
  }
  const chosen = candidates[0];
  if (chosen) {
    return `/api/feeds/image?url=${encodeURIComponent(chosen)}`;
  }
  return fallbackImg;
}

export function extractArticleContentHtml(
  html: string,
  fallbackUrl: string
): { paragraphs: string[]; blocks: ArticleContentBlock[]; heroImageUrl?: string; videoUrl?: string } {
  const rawOgImg =
    html.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i)?.[1] ||
    html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i)?.[1] ||
    html.match(/<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']/i)?.[1];

  const ogImg = rawOgImg ? normalizeHttpUrl(rawOgImg) : '';
  const heroImageUrl =
    ogImg && /^https?:\/\//i.test(ogImg) && !isLowQualityThumbUrl(ogImg)
      ? `/api/feeds/image?url=${encodeURIComponent(ogImg)}`
      : undefined;

  const videoUrl = extractVideoFromBlock(html) || extractVideoFromBlock(fallbackUrl);

  const cleanedHtml = html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<nav[\s\S]*?<\/nav>/gi, ' ')
    .replace(/<header[\s\S]*?<\/header>/gi, ' ')
    .replace(/<footer[\s\S]*?<\/footer>/gi, ' ');

  const articleScopeMatch = cleanedHtml.match(/<article\b[\s\S]*?<\/article>/i);
  const scopeHtml = articleScopeMatch ? articleScopeMatch[0] : cleanedHtml;

  const paragraphs: string[] = [];
  const blocks: ArticleContentBlock[] = [];
  const tokenRe = /<p\b[^>]*>([\s\S]*?)<\/p>/gi;
  let tm: RegExpExecArray | null;
  while ((tm = tokenRe.exec(scopeHtml)) !== null && blocks.length < 28) {
    const snippet = tm[0];
    const txt = stripHtml(snippet);
    if (
      txt.length >= 40 &&
      !/cookie|subscribe|sign up|privacy policy|all rights reserved|advertisement/i.test(txt)
    ) {
      paragraphs.push(txt);
      blocks.push({ type: 'text', content: txt });
    }
    if (paragraphs.length >= 16) break;
  }

  if (paragraphs.length === 0) {
    paragraphs.push(`Full coverage available at ${fallbackUrl}`);
    blocks.push({ type: 'text', content: paragraphs[0] });
  }

  return {
    paragraphs,
    blocks,
    heroImageUrl,
    videoUrl,
  };
}

const LOCAL_COVERS = [
  '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
  '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
  '/src/assets/images/cover_neon_velocity_1795374632434.jpg',
  '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
  '/src/assets/images/cover_amethyst_eclipse_1795374632693.jpg',
];

export function makeSvgBannerDataUrl(label: string, c1: string, c2: string): string {
  const safeLabel = label.replace(/[<>&"']/g, '').slice(0, 28);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 960 540"><defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stop-color="${c1}"/><stop offset="100%" stop-color="${c2}"/></linearGradient></defs><rect width="960" height="540" fill="url(#bg)"/><circle cx="810" cy="120" r="165" fill="#ffffff" opacity="0.08"/><circle cx="165" cy="450" r="210" fill="#ffffff" opacity="0.07"/><rect x="66" y="384" width="165" height="8" rx="4" fill="#ffffff" opacity="0.55"/><text x="66" y="348" fill="#ffffff" font-family="system-ui,sans-serif" font-size="44" font-weight="700" opacity="0.94">${safeLabel}</text></svg>`;
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
}

export function parseRssOrAtomXml(
  xml: string,
  sourceName: string,
  category: string,
  _fallbackColors: [string, string] = ['#1D4ED8', '#0EA5E9']
): NewsFeedItem[] {
  const items: NewsFeedItem[] = [];
  const itemMatches = xml.match(/<item\b[\s\S]*?<\/item>/gi) || [];
  const entryMatches = itemMatches.length > 0 ? [] : xml.match(/<entry\b[\s\S]*?<\/entry>/gi) || [];
  const blocks = [...itemMatches, ...entryMatches];

  blocks.forEach((block, idx) => {
    const rawTitle = extractTag(block, 'title');
    const title = stripHtml(rawTitle);
    if (!title) return;

    const linkTag = extractTag(block, 'link');
    const atomHref = block.match(/<link[^>]+href=["']([^"']+)["']/i)?.[1] ?? '';
    const url = /^https?:\/\//i.test(linkTag) ? linkTag : decodeEntities(atomHref) || 'https://www.nintendo.com';

    const rawDesc =
      extractTag(block, 'content:encoded') ||
      extractTag(block, 'content') ||
      extractTag(block, 'description') ||
      extractTag(block, 'summary');
    const cleanBody = stripHtml(rawDesc);
    const summary =
      cleanBody.length > 180 ? `${cleanBody.slice(0, 177).trim()}...` : cleanBody || title;

    const pubRaw =
      extractTag(block, 'pubDate') ||
      extractTag(block, 'published') ||
      extractTag(block, 'updated') ||
      '';
    const parsedDate = pubRaw ? new Date(pubRaw) : null;
    const publishedAt =
      parsedDate && !Number.isNaN(parsedDate.getTime())
        ? parsedDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
        : 'Latest';

    const fallbackImg = LOCAL_COVERS[idx % LOCAL_COVERS.length];
    const imageUrl = extractImageFromBlock(block, fallbackImg);
    const videoUrl = extractVideoFromBlock(block);

    items.push({
      id: `${category}-${sourceName.toLowerCase().replace(/\W+/g, '-')}-${idx}`,
      title,
      summary,
      content: cleanBody || summary,
      sourceName,
      publishedAt,
      imageUrl,
      url,
      category,
      videoUrl,
    });
  });

  return items;
}

export function parseRedditJsonPosts(
  json: unknown,
  sourceLabel: string,
  category: string
): NewsFeedItem[] {
  const root = json as {
    data?: {
      children?: Array<{
        data?: {
          id?: string;
          title?: string;
          selftext?: string;
          permalink?: string;
          url?: string;
          created_utc?: number;
          thumbnail?: string;
          preview?: { images?: Array<{ source?: { url?: string } }> };
          media?: { reddit_video?: { fallback_url?: string } };
        };
      }>;
    };
  };
  const children = root?.data?.children ?? [];
  const items: NewsFeedItem[] = [];

  for (const child of children) {
    const post = child?.data;
    if (!post?.title) continue;

    const previewUrl = post.preview?.images?.[0]?.source?.url ? normalizeHttpUrl(post.preview.images[0].source.url) : '';
    const thumb =
      previewUrl && /^https?:\/\//i.test(previewUrl)
        ? previewUrl
        : post.thumbnail && /^https?:\/\//i.test(post.thumbnail)
          ? normalizeHttpUrl(post.thumbnail)
          : '';

    const imageUrl = thumb
      ? `/api/feeds/image?url=${encodeURIComponent(thumb)}`
      : LOCAL_COVERS[items.length % LOCAL_COVERS.length];

    const bodyText = (post.selftext || '').replace(/\s+/g, ' ').trim();
    const summary = bodyText
      ? bodyText.length > 180
        ? `${bodyText.slice(0, 177)}...`
        : bodyText
      : `${sourceLabel} discussion on Android & handheld releases, frame times, and controller compatibility.`;

    const dateStr = post.created_utc
      ? new Date(post.created_utc * 1000).toLocaleDateString('en-US', {
          month: 'short',
          day: 'numeric',
          year: 'numeric',
        })
      : 'Trending';

    const videoUrl =
      post.media?.reddit_video?.fallback_url ||
      extractVideoFromBlock(post.url || '') ||
      undefined;

    items.push({
      id: `reddit-${post.id || items.length}`,
      title: decodeEntities(post.title),
      summary,
      content: bodyText || summary,
      sourceName: sourceLabel,
      publishedAt: dateStr,
      imageUrl,
      url: post.permalink ? `https://www.reddit.com${post.permalink}` : post.url || 'https://www.reddit.com',
      category,
      videoUrl,
    });
  }

  return items;
}

export const NEWS_FALLBACK_BY_CATEGORY: Record<NsoCategoryId, NewsFeedItem[]> = {
  nintendo: [
    {
      id: 'nin-fb-1',
      title: 'Nintendo Switch 2 Direct: Launch Lineup, 120Hz Display & GameChat Deep Dive',
      summary: 'Explore 120Hz handheld display modes, magnetic Joy-Con 2 rails, and seamless cross-generation upgrades.',
      content:
        'Nintendo showcased the next wave of Switch 2 software including Mario Kart World, updated Switch 2 Editions, and native GameChat voice rooms right from the HOME Menu.\n\nAlongside higher-bandwidth USB-C docked output and HDR support, Nintendo detailed faster Nintendo eShop navigation, instant GameShare invites for local handheld co-op, and locked higher frame rates for signature first-party titles.\n\nDevelopers also demonstrated mouse-sensor tabletop controls and improved Joy-Con 2 rumble precision built directly into new action and strategy releases.',
      sourceName: 'Nintendo.com',
      publishedAt: 'Featured',
      imageUrl: '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      url: 'https://www.nintendo.com/us/whatsnew/',
      category: 'nintendo',
      videoUrl: 'https://www.youtube.com/embed/3pE23YTYEZM',
    },
    {
      id: 'nin-fb-2',
      title: 'Nintendo Classics Expansion Pack Adds GameCube & N64 Enhancements',
      summary: 'Rewind support, crisp CRT scanline filters, and 4-player online lobbies arrive for Nintendo Online members.',
      content:
        'Members with Nintendo Switch Online + Expansion Pack can now jump into classic racing, RPG, and action favorites with per-game controller bindings and instant suspend points.\n\nThe latest update introduces customizable GameCube analog trigger curves, four-player friend lobbies with rollback networking, and widescreen toggles across iconic classics.',
      sourceName: 'Nintendo Life',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.nintendolife.com/',
      category: 'nintendo',
    },
    {
      id: 'nin-fb-3',
      title: 'Mario Kart World Adds Knockout Tour & 24-Player Intercontinental Grand Prix',
      summary: 'Seamless open-route tracks connect stages across continents with dynamic weather and GameChat parties.',
      content:
        'Race against 23 rivals online in continuous cross-country rallies or form private friend lobbies with instant GameChat invites.\n\nNew photo filters, rail-grind shortcuts, and seamless transitions between paved circuits and off-road biomes redefine series pacing.',
      sourceName: 'Nintendo.com',
      publishedAt: 'Latest',
      imageUrl: '/src/assets/images/cover_neon_velocity_1795374632434.jpg',
      url: 'https://www.nintendo.com/us/whatsnew/',
      category: 'nintendo',
    },
    {
      id: 'nin-fb-4',
      title: 'Zelda Notes & Switch 2 Edition Upgrades Deliver 60 FPS Hyrule Exploration',
      summary: 'Faster fast-travel loading, HDR skies, and QR Autobuild blueprint sharing arrive for Tears of the Kingdom.',
      content:
        'The Switch 2 Editions of Breath of the Wild and Tears of the Kingdom introduce virtually instant shrine transitions, 60 FPS camera smoothness, and cloud-synced community Autobuild schematics.\n\nPlayers can share blueprints directly with friends and explore Hyrule with sharper foliage draw distances.',
      sourceName: 'Nintendo Life',
      publishedAt: 'This Week',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.nintendolife.com/',
      category: 'nintendo',
    },
  ],
  action: [
    {
      id: 'act-fb-1',
      title: 'Metroid Prime 4: Beyond Showcases 120 FPS Performance Mode & Precision Aim',
      summary: 'Retro Studios confirms Quality 4K60 and 120 FPS performance presets alongside gyro and pointer aim.',
      content:
        'Samus Aran explores Planet Viewros with selectable Quality and 120 FPS Performance modes designed for ultra-responsive combat.\n\nPlayers can blend dual-analog movement with subtle gyro micro-adjustments or magnetic Joy-Con tabletop aiming without menu interruptions.',
      sourceName: 'Gematsu',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_amethyst_eclipse_1795374632693.jpg',
      url: 'https://www.gematsu.com/',
      category: 'action',
    },
    {
      id: 'act-fb-2',
      title: 'Donkey Kong Bananza Voxel Destruction Engine & Co-Op Breakdown',
      summary: 'Smashing cliffs and subterranean vaults dynamically reshapes platforming paths in real time.',
      content:
        'Every cliffside, golden deposit, and subterranean temple reacts physically to Donkey Kong’s punches and throws.\n\nLocal co-op lets a second player join with vocal shockwaves while uncovering hidden challenge gauntlets.',
      sourceName: 'VGC',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      url: 'https://www.videogameschronicle.com/',
      category: 'action',
    },
    {
      id: 'act-fb-3',
      title: 'Bayonetta & Ninja Action Ports Hold Locked 60 FPS on Handheld OLED Displays',
      summary: 'Updated shader pre-caching eliminates combo stutter during heavy particle boss encounters.',
      content:
        'Frame-time testing shows high-speed character action games benefit dramatically from asynchronous pipeline caching and tuned Adreno driver profiles.',
      sourceName: 'Nintendo Life',
      publishedAt: 'Latest',
      imageUrl: '/src/assets/images/cover_neon_velocity_1795374632434.jpg',
      url: 'https://www.nintendolife.com/',
      category: 'action',
    },
    {
      id: 'act-fb-4',
      title: 'Handheld Trigger Response & Parrying Benchmarks Across New Action Releases',
      summary: 'Low-latency digital microswitches make frame-tight dodge windows effortless on portable devices.',
      content:
        'Testing modern melee action combat proves microswitch shoulder buttons shave measurable input milliseconds off parry timings.',
      sourceName: 'Gematsu',
      publishedAt: 'This Week',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.gematsu.com/',
      category: 'action',
    },
  ],
  rpg: [
    {
      id: 'rpg-fb-1',
      title: 'Pokemon Legends: Z-A Showcases Real-Time Battle Positioning in Lumiose City',
      summary: 'Manual dodging, vertical rooftop exploration, and dynamic cooldowns transform trainer battles.',
      content:
        'Game Freak highlighted real-time positioning during wild encounters and trainer duels across redesigned Lumiose districts.\n\nMega Evolution gauges recharge through timed dodge maneuvers and elemental weaknesses.',
      sourceName: 'Nintendo.com',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.nintendo.com/',
      category: 'rpg',
    },
    {
      id: 'rpg-fb-2',
      title: 'Cyberpunk 2077 Portable Edition: Cross-Save Sync & Gyro Aiming Impressions',
      summary: 'Seamless cloud progression from PC to handheld paired with crisp 40 FPS VRR/Performance presets.',
      content:
        'CD Projekt Red demonstrated instant cross-save syncing from PC libraries alongside customizable gyro aiming and readable handheld HUD scaling throughout Night City and Dogtown.',
      sourceName: 'Nintendo Life',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_neon_velocity_1795374632434.jpg',
      url: 'https://www.nintendolife.com/',
      category: 'rpg',
    },
    {
      id: 'rpg-fb-3',
      title: 'Xenoblade Chronicles X Definitive Edition Highlights Skell Aerial Combat',
      summary: 'Overhauled party UI, faster field tracking, and extra epilogue story chapters shine in handheld mode.',
      content:
        'Mira’s massive seamless continents benefit from sharper resolution scaling, streamlined affinity missions, and crisp readable party status bars on 1080p handheld displays.',
      sourceName: 'Gematsu',
      publishedAt: 'Latest',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.gematsu.com/',
      category: 'rpg',
    },
    {
      id: 'rpg-fb-4',
      title: 'Dark Souls II & Classic Action RPG Ports Gain Widescreen 60 FPS Presets',
      summary: 'Community builds bundle full DualSense/Switch button glyphs and cloud save backups.',
      content:
        'Role-playing enthusiasts can enjoy marathon handheld sessions thanks to low-wattage performance profiles and clean save folder syncing.',
      sourceName: 'RPG Wire',
      publishedAt: 'This Week',
      imageUrl: '/src/assets/images/cover_amethyst_eclipse_1795374632693.jpg',
      url: 'https://www.gematsu.com/',
      category: 'rpg',
    },
  ],
  adventure: [
    {
      id: 'adv-fb-1',
      title: 'Windward Open-Sea Exploration Games Dominate Handheld Playtime Charts',
      summary: 'Seamless island hopping, glider physics, and environmental puzzles top weekend session stats.',
      content:
        'Players continue gravitating toward tactile exploration titles where horizon landmarks guide discovery without cluttered map icons.\n\nInstant sleep-resume ensures quick 20-minute bursts never interrupt long expeditions.',
      sourceName: 'Nintendo Life',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.nintendolife.com/',
      category: 'adventure',
    },
    {
      id: 'adv-fb-2',
      title: 'Professor Layton & Mystery Puzzle Adventures Return With Tactile Controls',
      summary: 'Refined analog pointer navigation pairs smoothly with handheld touchscreens and large dialog fonts.',
      content:
        'Classic narrative adventures now let players toggle seamlessly between touchscreen tapping and smooth analog cursor snapping.',
      sourceName: 'Gematsu',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_amethyst_eclipse_1795374632693.jpg',
      url: 'https://www.gematsu.com/',
      category: 'adventure',
    },
    {
      id: 'adv-fb-3',
      title: 'Okami Sequel & Stylized Brush-Art Adventures Celebrate Visual Direction',
      summary: 'Sumi-e ink shaders look extraordinarily vivid on modern high-contrast AMOLED panels.',
      content:
        'Handcrafted watercolor and ink rendering styles age effortlessly and deliver razor-sharp clarity at native 1080p handheld resolution.',
      sourceName: 'VGC',
      publishedAt: 'Latest',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.videogameschronicle.com/',
      category: 'adventure',
    },
    {
      id: 'adv-fb-4',
      title: 'Luigi’s Mansion & Co-Op Puzzle Dungeons Lead Family Couch Play',
      summary: 'Single-cartridge GameShare makes two-system cooperative puzzle solving effortless on road trips.',
      content:
        'Synchronized lantern and vacuum puzzles feel tailor-made for side-by-side handheld play.',
      sourceName: 'Nintendo.com',
      publishedAt: 'This Week',
      imageUrl: '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      url: 'https://www.nintendo.com/',
      category: 'adventure',
    },
  ],
  indie: [
    {
      id: 'ind-fb-1',
      title: 'Hollow Knight: Silksong & Hades II Deliver Locked 60 FPS on OLED Handhelds',
      summary: 'Hand-drawn animation and tight responsive movement shine with five-plus hours of battery endurance.',
      content:
        'Action roguelikes and hand-inked metroidvanias shine on 1080p AMOLED screens thanks to deep ink blacks and instant pixel response.\n\nBoth releases run whisper-quiet under modest power budgets while delivering razor-sharp combat readability.',
      sourceName: 'Nintendo Life',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_amethyst_eclipse_1795374632693.jpg',
      url: 'https://www.nintendolife.com/',
      category: 'indie',
    },
    {
      id: 'ind-fb-2',
      title: 'APKPorts Release Roundup: New Controller-Ready Indie Ports & Fan Games',
      summary: 'Balatro, Cuphead, Stardew Valley, and Deltarune mods add clean Switch-style button glyphs.',
      content:
        'Independent porters continue refining Android builds with native 16:9 HUD scaling, rumble hooks, and full gamepad menu navigation.',
      sourceName: 'Gematsu',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.apkports.com/games',
      category: 'indie',
    },
    {
      id: 'ind-fb-3',
      title: 'Balatro & Deckbuilder Roguelikes Add High-Contrast Handheld Text Presets',
      summary: 'Larger card descriptions make quick handheld runs legible outdoors or on flights.',
      content:
        'Deckbuilder studios are shipping dedicated portable typography updates so multiplier tooltips read effortlessly on 5.5-inch and 7.9-inch screens.',
      sourceName: 'Indie World',
      publishedAt: 'Latest',
      imageUrl: '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      url: 'https://www.nintendo.com/',
      category: 'indie',
    },
    {
      id: 'ind-fb-4',
      title: 'Deltarune Chapters 3 & 4 Launch Details & Save Transfer Guide',
      summary: 'Carry existing Chapter 1–2 choices straight into the newest soundtrack-packed chapters.',
      content:
        'Toby Fox confirmed seamless cross-generation save importing and instant controller customization for every minigame.',
      sourceName: 'Nintendo Life',
      publishedAt: 'This Week',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.nintendolife.com/',
      category: 'indie',
    },
  ],
  multiplayer: [
    {
      id: 'mul-fb-1',
      title: 'Splatoon 3 Seasonal Update Adds Fresh Weapon Kits & Urchin Underpass',
      summary: 'Higher-resolution ink reflections and snappy lobby matchmaking bring players back to Turf War.',
      content:
        'Players jumping back into Turf War and Salmon Run gain 30 new weapon kits alongside faster square-to-battle transitions and sharper UI badge rendering.',
      sourceName: 'Nintendo.com',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_neon_velocity_1795374632434.jpg',
      url: 'https://www.nintendo.com/',
      category: 'multiplayer',
    },
    {
      id: 'mul-fb-2',
      title: 'Kirby Air Riders Revealed: Sakurai Returns for High-Speed City Trial',
      summary: 'Boost-and-glide arena battles return with customizable Warp Stars and ranked online rooms.',
      content:
        'Masahiro Sakurai’s return to Dream Land’s cult-classic racer brings chaotic multi-stage City Trial stadiums, custom machine builds, and local wireless GameShare lobbies.',
      sourceName: 'VGC',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.videogameschronicle.com/',
      category: 'multiplayer',
    },
    {
      id: 'mul-fb-3',
      title: 'Street Fighter 6 Portable Roster & 60 FPS Local Versus Lobbies',
      summary: 'Rollback netcode, crossplay support, and tabletop Joy-Con Versus tournaments anywhere.',
      content:
        'Capcom’s portable build preserves full frame-data parity and crossplay matchmaking while enabling instant two-player local lobbies.',
      sourceName: 'Gematsu',
      publishedAt: 'Latest',
      imageUrl: '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      url: 'https://www.gematsu.com/',
      category: 'multiplayer',
    },
    {
      id: 'mul-fb-4',
      title: 'GameShare Co-Op Protocol Lets Friends Join Local Sessions With One Copy',
      summary: 'Stream low-latency split gameplay to nearby systems alongside real-time GameChat audio.',
      content:
        'One host system handles game logic while nearby handhelds render crisp low-latency video streams with zero extra downloads required.',
      sourceName: 'Nintendo.com',
      publishedAt: 'This Week',
      imageUrl: '/src/assets/images/cover_amethyst_eclipse_1795374632693.jpg',
      url: 'https://www.nintendo.com/',
      category: 'multiplayer',
    },
  ],
};

export const NSO_FALLBACK_ITEMS: NewsFeedItem[] = [
  ...NEWS_FALLBACK_BY_CATEGORY.nintendo,
  ...NEWS_FALLBACK_BY_CATEGORY.action.slice(0, 2),
  ...NEWS_FALLBACK_BY_CATEGORY.rpg.slice(0, 2),
  ...NEWS_FALLBACK_BY_CATEGORY.adventure.slice(0, 2),
  ...NEWS_FALLBACK_BY_CATEGORY.indie.slice(0, 2),
  ...NEWS_FALLBACK_BY_CATEGORY.multiplayer.slice(0, 2),
];

export const GENERAL_NEWS_FALLBACK_BY_CATEGORY: Record<GeneralNewsCategoryId, NewsFeedItem[]> = {
  latest: [
    {
      id: 'gen-lat-1',
      title: 'Puerto Rico Impulsa Nuevos Proyectos de Energía Renovable y Almacenamiento en la Isla',
      summary: 'Nuevas microrredes solares buscan fortalecer la estabilidad eléctrica en municipios costeros y áreas montañosas.',
      content:
        'Autoridades energéticas y consorcios locales detallaron un plan por fases para ampliar baterías a escala comercial y microrredes comunitarias alrededor de Puerto Rico.\n\nEl despliegue prioriza hospitales regionales, sistemas de bombeo de agua y centros urbanos de alta demanda antes de la temporada pico de verano.',
      sourceName: 'El Nuevo Día',
      publishedAt: 'Hoy',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.elnuevodia.com/',
      category: 'latest',
    },
    {
      id: 'gen-lat-2',
      title: 'Semiconductor & Next-Gen Mobile Chip Roadmaps Accelerate Efficiency Gains',
      summary: '3nm mobile silicon designs push cooler sustained frame rates and longer battery life across handheld devices.',
      content:
        'Chipmakers unveiled refreshed low-wattage architectures aimed at portable gaming systems, edge AI inference, and ultra-thin laptops.\n\nSustained thermal efficiency improvements allow compact handhelds to maintain stable 1080p performance with reduced fan noise.',
      sourceName: 'Tech Wire',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_neon_velocity_1795374632434.jpg',
      url: 'https://arstechnica.com/',
      category: 'latest',
    },
    {
      id: 'gen-lat-3',
      title: 'Mercados Globales Evalúan Reportes Trimestrales y Tasas de Interés',
      summary: 'Inversionistas siguen de cerca el sector tecnológico, manufactura avanzada y logística marítima regional.',
      content:
        'Los principales índices financieros operan con cautela tras publicarse datos recientes de inflación y actividad industrial.\n\nAnalistas destacan la resiliencia de exportaciones médicas y tecnológicas en el Caribe.',
      sourceName: 'Economy Desk',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.cnbc.com/world/',
      category: 'latest',
    },
    {
      id: 'gen-lat-4',
      title: 'San Juan y Santurce Registran Auge en Eventos Culturales, Arte Urbano y Gastronomía',
      summary: 'Galerías independientes y festivales de música dinamizan la economía creativa del área metropolitana.',
      content:
        'Comerciantes locales y colectivos culturales reportan alta asistencia en recorridos nocturnos de arte, mercados de diseño y conciertos al aire libre en Santurce y el Viejo San Juan.',
      sourceName: 'Puerto Rico',
      publishedAt: 'Latest',
      imageUrl: '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      url: 'https://www.elnuevodia.com/',
      category: 'latest',
    },
  ],
  elnuevodia: [
    {
      id: 'endi-1',
      title: 'El Nuevo Día: Actualización de Infraestructura Vial y Transporte Colectivo en el Área Metro',
      summary: 'Autoridades detallan mejoras en rutas de transporte público, señalización inteligente y corredores urbanos.',
      content:
        'El plan de movilidad integrada contempla sincronización de semáforos y extensión de rutas expreso entre San Juan, Bayamón, Carolina y Caguas para reducir tapones en horas pico.',
      sourceName: 'El Nuevo Día',
      publishedAt: 'Reciente',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.elnuevodia.com/noticias/',
      category: 'elnuevodia',
    },
    {
      id: 'endi-2',
      title: 'Sector Turístico de Puerto Rico Proyecta Récord en Cruceros y Estadías Cortas',
      summary: 'Nuevas conexiones aéreas desde Estados Unidos, Europa y Latinoamérica fortalecen la ocupación hotelera.',
      content:
        'Compañías aéreas anunciaron frecuencias adicionales hacia el Aeropuerto Internacional Luis Muñoz Marín, impulsando la llegada de visitantes durante todo el año.',
      sourceName: 'El Nuevo Día',
      publishedAt: 'Hoy',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.elnuevodia.com/negocios/',
      category: 'elnuevodia',
    },
    {
      id: 'endi-3',
      title: 'Iniciativas Universitarias en Mayagüez y Río Piedras Impulsan Tecnología Aeroespacial',
      summary: 'Estudiantes de ingeniería presentan nuevos prototipos de satélites y robótica ante socios internacionales.',
      content:
        'Laboratorios académicos locales continúan expandiendo alianzas con empresas tecnológicas para retener talento joven en la isla.',
      sourceName: 'El Nuevo Día',
      publishedAt: 'Hoy',
      imageUrl: '/src/assets/images/cover_neon_velocity_1795374632434.jpg',
      url: 'https://www.elnuevodia.com/ciencia-tecnologia/',
      category: 'elnuevodia',
    },
    {
      id: 'endi-4',
      title: 'Temporada Cultural Destaca Cine Puertorriqueño y Teatros Históricos en Santurce',
      summary: 'Directores independientes estrenan documentales y largometrajes con amplia acogida del público.',
      content:
        'Salas restauradas y festivales locales celebran el crecimiento de la industria audiovisual boricua y sus coproducciones internacionales.',
      sourceName: 'El Nuevo Día',
      publishedAt: 'Esta Semana',
      imageUrl: '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      url: 'https://www.elnuevodia.com/entretenimiento/',
      category: 'elnuevodia',
    },
  ],
  puerto_rico: [
    {
      id: 'pr-1',
      title: 'Puerto Rico Amplía Parques Tecnológicos y Manufactura de Dispositivos Médicos',
      summary: 'Nuevas inversiones farmacéuticas y de biotecnología generan empleos especializados en la zona norte y oeste.',
      content:
        'El ecosistema de manufactura avanzada de Puerto Rico suma líneas automatizadas en Barceloneta, Juncos y Aguadilla con énfasis en exportación y control de calidad.',
      sourceName: 'Puerto Rico',
      publishedAt: 'Hoy',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.elnuevodia.com/',
      category: 'puerto_rico',
    },
    {
      id: 'pr-2',
      title: 'Rescate y Conservación de Playas y Arrecifes Avanza en Culebra, Vieques y Cabo Rojo',
      summary: 'Organizaciones comunitarias y biólogos marinos siembran corales resistentes y restauran dunas costeras.',
      content:
        'Voluntarios locales trabajan junto a programas científicos para proteger ecosistemas marinos esenciales contra la erosión costera.',
      sourceName: 'Puerto Rico',
      publishedAt: 'Hoy',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.elnuevodia.com/',
      category: 'puerto_rico',
    },
    {
      id: 'pr-3',
      title: 'Agricultura Hidropónica y Fincas Locales Aumentan Suministro de Productos Frescos',
      summary: 'Cooperativas agrícolas del centro de la isla adoptan invernaderos resilientes y riego automatizado.',
      content:
        'Productores de Barranquitas, Orocovis y San Sebastián amplían cultivos para mercados locales y supermercados.',
      sourceName: 'Puerto Rico',
      publishedAt: 'Esta Semana',
      imageUrl: '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      url: 'https://www.elnuevodia.com/',
      category: 'puerto_rico',
    },
    {
      id: 'pr-4',
      title: 'Baloncesto Superior Nacional y Béisbol Invernal Registran Asistencia Histórica',
      summary: 'Estadios llenos alrededor de la isla reflejan el entusiasmo por las franquicias locales.',
      content:
        'La fanaticada apoya con fuerza los torneos nacionales y el desarrollo de jóvenes atletas boricuas en ligas internacionales.',
      sourceName: 'Puerto Rico',
      publishedAt: 'Reciente',
      imageUrl: '/src/assets/images/cover_amethyst_eclipse_1795374632693.jpg',
      url: 'https://www.elnuevodia.com/',
      category: 'puerto_rico',
    },
  ],
  r_puertorico: [
    {
      id: 'rpr-1',
      title: 'r/PuertoRico: Mejores Rutas de Chinchorreo, Miradores y Café de Altura en la Montaña',
      summary: 'La comunidad comparte recomendaciones actualizadas desde Jayuya, Adjuntas, Cayey y Maricao.',
      content:
        'Usuarios de r/PuertoRico recopilaron un mapa comunitario con haciendas cafetaleras, miradores panorámicos y restaurantes familiares ideales para pasar el fin de semana en la cordillera central.',
      sourceName: 'r/PuertoRico',
      publishedAt: 'Trending',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.reddit.com/r/PuertoRico/',
      category: 'r_puertorico',
    },
    {
      id: 'rpr-2',
      title: 'r/PuertoRico: Discusión sobre Fibra Óptica, Velocidades Residenciales y Placas Solares',
      summary: 'Vecinos comparan proveedores de internet simétrico y sistemas híbridos de respaldo eléctrico por municipio.',
      content:
        'Un hilo activo reúne experiencias reales de cobertura de fibra óptica y rendimiento de baterías residenciales en distintos pueblos de la isla.',
      sourceName: 'r/PuertoRico',
      publishedAt: 'Trending',
      imageUrl: '/src/assets/images/cover_neon_velocity_1795374632434.jpg',
      url: 'https://www.reddit.com/r/PuertoRico/',
      category: 'r_puertorico',
    },
    {
      id: 'rpr-3',
      title: 'r/PuertoRico: Escena Indie, Meetups Tech y Eventos Comunitarios en Santurce',
      summary: 'Desarrolladores, diseñadores y gamers locales organizan intercambios mensuales en el área metro.',
      content:
        'La comunidad destaca talleres gratuitos de programación, ferias de diseño local y noches de juegos de mesa y consolas portátiles.',
      sourceName: 'r/PuertoRico',
      publishedAt: 'Popular',
      imageUrl: '/src/assets/images/cover_amethyst_eclipse_1795374632693.jpg',
      url: 'https://www.reddit.com/r/PuertoRico/',
      category: 'r_puertorico',
    },
    {
      id: 'rpr-4',
      title: 'r/PuertoRico: Fotos Destacadas de Atardeceres en Rincón, Cabo Rojo y El Yunque',
      summary: 'Fotógrafos locales comparten capturas de paisajes naturales y arquitectura histórica de toda la isla.',
      content:
        'El resumen semanal de la comunidad celebra vistas desde el Faro Los Morrillos hasta las veredas de El Yunque.',
      sourceName: 'r/PuertoRico',
      publishedAt: 'Popular',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.reddit.com/r/PuertoRico/',
      category: 'r_puertorico',
    },
  ],
  politics: [
    {
      id: 'pol-1',
      title: 'Debate Legislativo Se Centra en Reformas Contributivas, Energía y Presupuesto Municipal',
      summary: 'Comisiones evalúan medidas para agilizar permisos, transparencia fiscal y fondos para municipios.',
      content:
        'Portavoces legislativos presentaron propuestas dirigidas a simplificar trámites digitales, auditar contratos de infraestructura y proteger servicios esenciales en pueblos rurales.',
      sourceName: 'Politics',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      url: 'https://www.npr.org/sections/politics/',
      category: 'politics',
    },
    {
      id: 'pol-2',
      title: 'Federal & Congressional Committees Review Energy Grid Modernization Grants',
      summary: 'Lawmakers examine grid resilience milestones, disaster recovery disbursements, and clean-tech incentives.',
      content:
        'Subcommittee hearings this week focused on accelerating federal infrastructure disbursements and strengthening oversight over regional utility contractors.',
      sourceName: 'NPR Politics',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.npr.org/sections/politics/',
      category: 'politics',
    },
    {
      id: 'pol-3',
      title: 'Alcaldes y Gobiernos Regionales Impulsan Consorcios para Servicios Compartidos',
      summary: 'Acuerdos intermunicipales buscan reducir costos en reciclaje, seguridad y mantenimiento vial.',
      content:
        'Varios municipios anunciaron alianzas operativas para compartir maquinaria y plataformas de compras públicas.',
      sourceName: 'El Nuevo Día',
      publishedAt: 'Latest',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.elnuevodia.com/',
      category: 'politics',
    },
    {
      id: 'pol-4',
      title: 'Global Diplomatic Summits Address Trade Corridors and AI Governance Standards',
      summary: 'International delegations coordinate cross-border digital privacy frameworks and tariff rules.',
      content:
        'Policy delegates agreed to harmonize technical safety evaluations while maintaining open academic and commercial exchanges.',
      sourceName: 'BBC World',
      publishedAt: 'This Week',
      imageUrl: '/src/assets/images/cover_amethyst_eclipse_1795374632693.jpg',
      url: 'https://www.bbc.com/news/world',
      category: 'politics',
    },
  ],
  economy: [
    {
      id: 'eco-1',
      title: 'Global Supply Chains Shift Toward Nearshoring & Regional Manufacturing Hubs',
      summary: 'Logistics investments and port automation boost Caribbean and Americas trade corridors.',
      content:
        'Trade analysts note continued capital inflow into pharmaceuticals, aerospace components, and automated distribution centers closer to North American consumer markets.',
      sourceName: 'Economy',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.cnbc.com/economy/',
      category: 'economy',
    },
    {
      id: 'eco-2',
      title: 'Crecen Exportaciones de Tecnología Médica y Servicios Profesionales desde Puerto Rico',
      summary: 'Empresas locales amplían contratación en ingeniería, finanzas y desarrollo de software remoto.',
      content:
        'Datos comerciales recientes reflejan crecimiento sostenido en servicios de alto valor añadido e incentivos a pequeñas y medianas empresas locales.',
      sourceName: 'El Nuevo Día',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://www.elnuevodia.com/negocios/',
      category: 'economy',
    },
    {
      id: 'eco-3',
      title: 'Central Banks Monitor Consumer Spending, Housing Supply & Wage Growth',
      summary: 'Measured inflation trends support steady credit conditions for small business expansion.',
      content:
        'Economic indicators show stable household consumption alongside gradual moderation in shelter and energy price pressures.',
      sourceName: 'BBC Business',
      publishedAt: 'Latest',
      imageUrl: '/src/assets/images/cover_neon_velocity_1795374632434.jpg',
      url: 'https://www.bbc.com/news/business',
      category: 'economy',
    },
    {
      id: 'eco-4',
      title: 'Retail & Digital Commerce Report Higher Mobile Adoption Across Latin America',
      summary: 'Instant payment rails and cross-border fintech apps accelerate digital checkout growth.',
      content:
        'Merchants increasingly rely on unified mobile wallets and transparent shipping tracking to retain repeat customers.',
      sourceName: 'Economy Desk',
      publishedAt: 'This Week',
      imageUrl: '/src/assets/images/cover_crimson_odyssey_1795374633248.jpg',
      url: 'https://www.cnbc.com/economy/',
      category: 'economy',
    },
  ],
  tech: [
    {
      id: 'tch-1',
      title: 'Open-Source Handheld Graphics Drivers & Vulkan Translation Hit New Performance Milestone',
      summary: 'Mesa Turnip and Vulkan shader compilers cut stutter and power draw across Snapdragon handhelds.',
      content:
        'Graphics driver maintainers rolled out new descriptor indexing optimizations and memory compression passes that improve 1% low frame times on Snapdragon 865/8 Gen 2/G3 handheld hardware.',
      sourceName: 'Ars Technica',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_neon_velocity_1795374632434.jpg',
      url: 'https://arstechnica.com/',
      category: 'tech',
    },
    {
      id: 'tch-2',
      title: 'Solid-State & High-Density Silicon-Carbon Batteries Come to Compact Portable Devices',
      summary: 'Higher energy density packs more runtime into slim 5.5-inch and 7-inch handheld chassis.',
      content:
        'Next-generation anode chemistry raises battery capacity by 18–25% without increasing thickness or weight.',
      sourceName: 'The Verge',
      publishedAt: 'Today',
      imageUrl: '/src/assets/images/cover_amethyst_eclipse_1795374632693.jpg',
      url: 'https://www.theverge.com/tech',
      category: 'tech',
    },
    {
      id: 'tch-3',
      title: 'Wi-Fi 7 & Ultra-Low-Latency Local Streaming Transform Handheld PC Game Streaming',
      summary: 'Sub-4ms local decode pipelines bring desktop GPUs seamlessly to handheld AMOLED screens.',
      content:
        'Updated AV1/HEVC hardware decoders and 6GHz spectrum channels eliminate macroblocking even in fast-paced racing and action titles.',
      sourceName: 'Tech Wire',
      publishedAt: 'Latest',
      imageUrl: '/src/assets/images/cover_azure_horizon_1795374632225.jpg',
      url: 'https://arstechnica.com/',
      category: 'tech',
    },
    {
      id: 'tch-4',
      title: 'Linux, Qt & Android Cross-Platform Frontends Embrace Hardware-Accelerated 120Hz UI',
      summary: 'Smooth GPU-composited interfaces bring console-grade polish to open handheld launchers.',
      content:
        'Frontend developers continue adopting lightweight vector icons, dynamic artwork theming, and responsive gamepad focus engines.',
      sourceName: 'The Verge',
      publishedAt: 'This Week',
      imageUrl: '/src/assets/images/cover_emerald_sanctum_1795374632127.jpg',
      url: 'https://www.theverge.com/tech',
      category: 'tech',
    },
  ],
};

export const GENERAL_NEWS_FALLBACK_ITEMS: NewsFeedItem[] = [
  ...GENERAL_NEWS_FALLBACK_BY_CATEGORY.latest.slice(0, 3),
  ...GENERAL_NEWS_FALLBACK_BY_CATEGORY.elnuevodia.slice(0, 2),
  ...GENERAL_NEWS_FALLBACK_BY_CATEGORY.puerto_rico.slice(0, 2),
  ...GENERAL_NEWS_FALLBACK_BY_CATEGORY.r_puertorico.slice(0, 2),
  ...GENERAL_NEWS_FALLBACK_BY_CATEGORY.politics.slice(0, 1),
  ...GENERAL_NEWS_FALLBACK_BY_CATEGORY.economy.slice(0, 1),
  ...GENERAL_NEWS_FALLBACK_BY_CATEGORY.tech.slice(0, 1),
];

