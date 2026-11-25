export interface RgbColor {
  r: number;
  g: number;
  b: number;
}

export type UiKitBorderPreset = 'adaptive' | 'prism' | 'aqua' | 'violet' | 'magenta' | 'frost';

export type HudColorThemeId =
  | 'auto'
  | 'mario'
  | 'luigi'
  | 'peach'
  | 'yoshi'
  | 'dk'
  | 'bowser'
  | 'switchCyan';

export interface AdaptivePalette {
  isDark: boolean;
  dominantHex: string;
  accentHex: string;
  accentGlowHex: string;
  iridescentGradient: string;
  canvasBg: string;
  backdropWash: string;
  gameTitleColor: string;
  topBarText: string;
  topBarIcon: string;
  statusPillBg: string;
  borderPrimary: string;
  borderPulse: string;
  cardSurface: string;
  dockBg: string; // Solid color without border
  dockIcon: string;
  dockActiveCircle: string;
  dockActiveIcon: string;
  dockRingColor: string; // Solid UI-matched focus ring (no rainbow)
  dockLabel: string;
  helpBarText: string;
  helpBarIcon: string;
  favoriteHeartBg: string;
  favoriteHeartIcon: string;
  overlaySheetBg: string;
  overlayCardBg: string;
  overlayDivider: string;
  overlayText: string;
  overlayMuted: string;
}

export type UiKitCharacterId = 'mario' | 'luigi' | 'peach' | 'yoshi' | 'dk' | 'bowser';

export interface UserProfile {
  id: string;
  name: string;
  characterId: UiKitCharacterId;
  friendCode?: string;
}

export interface GamePlayerStamp {
  name: string;
  characterId: UiKitCharacterId;
}

export interface GameItem {
  id: string;
  title: string;
  platform: string;
  platformShort: string;
  romPath?: string;
  developer: string;
  releaseYear: string;
  genre: string;
  playTimeHours: number;
  lastPlayedByUser?: string;
  playedByUsers?: GamePlayerStamp[];
  lastPlayedAt?: string;
  lastPlayedSeq?: number;
  favorite: boolean;
  inBacklog?: boolean;
  coverUrl: string;
  backgroundUrl?: string;
  coverCropClass?: string;
  sampleRegion?: { x: number; y: number; w: number; h: number };
  summary: string;
  fallbackDominant: RgbColor;
  fallbackAccent: RgbColor;
  apkportsSlug?: string;
  version?: string;
  youtubeVideoId?: string;
  screenshots?: string[];
}

export type ThemeAppearanceMode = 'auto' | 'light' | 'dark';

export type BrowserOpenMode = 'in-app' | 'chrome';

export interface AlbumPhotoItem {
  id: string;
  name: string;
  url: string;
  addedAt?: string;
}

export interface SkylineConfig {
  username: string;
  appearanceMode: ThemeAppearanceMode;
  adaptiveColors: boolean;
  hudThemeId: HudColorThemeId;
  borderPreset: UiKitBorderPreset;
  uiSoundsEnabled: boolean;
  cardSizePct: number;
  allSoftwareSizePct: number;
  cardSpacingRatio: number;
  borderGapPx720: number;
  borderThicknessPx720: number;
  dockHeightPct: number;
  brightnessPct: number;
  browserMode: BrowserOpenMode;
  albumFolderLabel: string;
  showBatteryPercent: boolean;
  showWifi: boolean;
  timeFormat: '12hr' | '24hr';
  enableBackgroundArt: boolean;
  backgroundDimPct: number; // Controls Game Background opacity (0-100%)
  backgroundBlurPct: number; // Controls Game Background blur intensity (0-100%)
  systemFontScalePct: number; // System UI font size scale (85 - 135%)
  rp5FrameMode: 'fit-16-9' | 'fill';
}

export type FocusZone = 'profile' | 'games' | 'dock';
export type ActiveModal =
  | null
  | 'userSelect'
  | 'gameEdit'
  | 'gamePage'
  | 'browser'
  | 'settings'
  | 'store'
  | 'software'
  | 'nso'
  | 'chat'
  | 'news'
  | 'album'
  | 'gameshare'
  | 'suspend';

export interface ApkpCategory {
  name: string;
  slug: string;
}

export interface ApkpGameSummary {
  id: string;
  slug: string;
  title: string;
  description?: string;
  coverUrl: string;
  rawImageUrl: string;
  version: string;
  portType: 'official' | 'unofficial' | 'fan-game';
  categories: string[];
  franchises: string[];
  videoUrl?: string;
  pageUrl?: string;
  downloadUrl?: string;
  sourceSite?: 'apkports' | 'nswpedia' | 'switchsrom' | 'vimm' | 'archive';
  system?: string;
}

export interface ApkpGameDetail extends ApkpGameSummary {
  description: string;
  requirements?: string;
  developer?: string;
  releaseDate?: string;
  fileSize?: string;
  screenshots: string[];
  sourceUrl: string;
  pageUrl?: string;
  downloadUrl?: string;
  videoUrl?: string;
}

export interface ApkpLibraryResponse {
  games: ApkpGameSummary[];
  totalCount: number;
  totalPages: number;
  page: number;
  hasMore?: boolean;
  categories: ApkpCategory[];
  source: 'live' | 'cache' | 'fallback';
}

export type NsoCategoryId =
  | 'nintendo'
  | 'action'
  | 'rpg'
  | 'adventure'
  | 'indie'
  | 'multiplayer';

export type GeneralNewsCategoryId =
  | 'latest'
  | 'elnuevodia'
  | 'puerto_rico'
  | 'r_puertorico'
  | 'politics'
  | 'economy'
  | 'tech';

export type NewsCategoryId = NsoCategoryId | GeneralNewsCategoryId;

export interface NewsFeedItem {
  id: string;
  title: string;
  summary: string;
  content: string;
  sourceName: string;
  publishedAt: string;
  imageUrl: string;
  url: string;
  category: string;
  videoUrl?: string;
}

export interface NewsFeedResponse {
  items: NewsFeedItem[];
  source: 'live' | 'cache' | 'fallback';
  page?: number;
  hasMore?: boolean;
}

export interface ArticleContentBlock {
  type: 'text' | 'image';
  content: string;
  alt?: string;
}

export interface ArticleReaderPayload {
  url: string;
  title?: string;
  paragraphs: string[];
  blocks?: ArticleContentBlock[];
  heroImageUrl?: string;
  videoUrl?: string;
}

export interface LaMovieMediaItem {
  id: string;
  postId: number;
  slug: string;
  title: string;
  mediaType: 'movies' | 'tvshows' | 'youtube';
  overview: string;
  posterUrl: string;
  backdropUrl: string;
  rawPosterUrl: string;
  rawBackdropUrl: string;
  rating?: string;
  runtime?: string;
  genres: string[];
  year?: string;
  embedUrl?: string;
  previewEmbedUrl?: string;
  pageUrl: string;
  channel?: string;
}

