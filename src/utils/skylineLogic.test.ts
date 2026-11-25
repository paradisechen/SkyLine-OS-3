import test from 'node:test';
import assert from 'node:assert/strict';
import {
  buildAdaptiveTheme,
  contrastRatio,
  deriveAdaptiveHudTextColor,
  extractPaletteFromPixels,
  HUD_THEME_SWATCHES,
  relativeLuminance,
  rgbToHex,
  UI_KIT_BORDER_PRESETS,
} from './artworkPalette';
import { computeSwitch2Layout, DEFAULT_SKYLINE_CONFIG, fit16By9Viewport } from './rp5Layout';
import { normalizeApkPortsImageUrl, parseApkPortsApiJson, parseApkPortsListHtml } from './apkportsParser';
import { cleanSwitchsromTitle, parseSwitchsromWpJson } from './switchsromParser';
import { parseVimmSystemHtml, VIMM_ALL_SECTIONS, VIMM_SYSTEMS } from './vimmParser';
import {
  ESHOP_ALPHABET_LETTERS,
  filterAndPaginateUnifiedCatalog,
  stepAlphabetLetter,
  unifyEshopCatalog,
} from './eshopHelpers';
import {
  extractArticleContentHtml,
  NSO_FALLBACK_ITEMS,
  parseRedditJsonPosts,
  parseRssOrAtomXml,
} from './rssFeedParser';
import {
  BROWSER_HOME_URL,
  DEFAULT_BROWSER_BOOKMARKS,
  extractYouTubeVideoId,
  isSafeExternalHttpUrl,
  normalizeBrowserInput,
  parseDuckDuckGoHtmlResults,
  rewriteCssForInAppProxy,
  rewriteHtmlForInAppFrame,
} from './browserHelper';
import {
  extractUnwrappedLaMovieEmbedUrl,
  filterAndPaginateLaMovieCatalog,
  rewriteLaMovieEmbedHtml,
} from './lamovieParser';

function hexToRgb(hex: string) {
  const clean = hex.replace('#', '');
  return {
    r: parseInt(clean.slice(0, 2), 16),
    g: parseInt(clean.slice(2, 4), 16),
    b: parseInt(clean.slice(4, 6), 16),
  };
}

test('extractPaletteFromPixels identifies dominant and vibrant accent colors', () => {
  const data = new Uint8ClampedArray(100 * 4);
  for (let i = 0; i < 100; i++) {
    const isGold = i < 20;
    data[i * 4] = isGold ? 245 : 70;
    data[i * 4 + 1] = isGold ? 185 : 18;
    data[i * 4 + 2] = isGold ? 35 : 22;
    data[i * 4 + 3] = 255;
  }
  const result = extractPaletteFromPixels(data, 100);
  assert.ok(result.dominant.r > result.dominant.b, 'dominant should lean crimson');
  assert.ok(result.accent.g > 120 && result.accent.r > 200, 'accent should capture bright gold');
});

test('buildAdaptiveTheme produces darker rich tones on light art, bright crisp UI on dark art, and 8 HUD swatches', () => {
  assert.equal(HUD_THEME_SWATCHES.length, 8, 'HUD grid must contain strictly 8 circled colors (4x2)');

  const darkArt = buildAdaptiveTheme({ r: 22, g: 18, b: 20 }, { r: 242, g: 120, b: 40 }, 'auto', 0.04, true, 'prism');
  const lightRedArt = buildAdaptiveTheme({ r: 252, g: 205, b: 205 }, { r: 230, g: 24, b: 36 }, 'auto', 0.72, true, 'aqua');

  assert.equal(darkArt.isDark, true);
  assert.equal(lightRedArt.isDark, false);
  assert.equal(darkArt.iridescentGradient, UI_KIT_BORDER_PRESETS.prism.gradient);
  assert.equal(lightRedArt.iridescentGradient, UI_KIT_BORDER_PRESETS.aqua.gradient);

  // Solid UI-matched dock ring & adaptive heart color
  assert.match(darkArt.dockRingColor, /^#[0-9a-f]{6}$/i);
  assert.match(lightRedArt.favoriteHeartBg, /^#[0-9a-f]{6}$/i);

  // Light mode text must be noticeably darker than background luminance
  assert.ok(
    relativeLuminance(hexToRgb(lightRedArt.gameTitleColor)) <
      relativeLuminance(hexToRgb(lightRedArt.canvasBg)) * 0.4,
    'Light mode UI title must be a darker tone than background'
  );
  // Dark mode text must be bright and readable on dark NS2 grey
  assert.ok(
    relativeLuminance(hexToRgb(darkArt.gameTitleColor)) > 0.35,
    'Dark mode UI title must stay bright and readable'
  );

  assert.ok(
    contrastRatio(hexToRgb(darkArt.gameTitleColor), hexToRgb(darkArt.canvasBg)) >= 4.5,
    'Dark artwork title contrast >= 4.5'
  );
  assert.ok(
    contrastRatio(hexToRgb(lightRedArt.gameTitleColor), hexToRgb(lightRedArt.canvasBg)) >= 4.5,
    'Light artwork title contrast >= 4.5'
  );
  assert.ok(
    contrastRatio(hexToRgb(darkArt.helpBarText), hexToRgb(darkArt.canvasBg)) >= 4.5,
    'Dark artwork bottom bar contrast >= 4.5'
  );
  assert.ok(
    contrastRatio(hexToRgb(lightRedArt.helpBarText), hexToRgb(lightRedArt.canvasBg)) >= 4.5,
    'Light artwork bottom bar contrast >= 4.5'
  );
  assert.ok(rgbToHex({ r: 16, g: 174, b: 190 }) === '#10aebe');
});

test('computeSwitch2Layout enforces unobstructed concentric border, uniform spacing, and enlarged dock for RP5 1080p', () => {
  const rp5 = computeSwitch2Layout(1920, 1080, DEFAULT_SKYLINE_CONFIG);

  assert.equal(rp5.vpxScale, 1.5);
  assert.equal(rp5.borderInnerRadius, rp5.cardRadius + rp5.borderGap);
  assert.equal(rp5.borderOuterRadius, rp5.cardRadius + rp5.borderGap + rp5.borderStroke);
  assert.ok(rp5.borderStroke >= 8, 'Bold outer border on 1080p should be >= 8px');
  assert.ok(rp5.borderGap >= 8, 'Inner gap around cover art should be >= 8px');
  assert.ok(
    rp5.cardGap > (rp5.borderGap + rp5.borderStroke) * 2,
    'Horizontal spacing between covers must prevent border overlap'
  );
  assert.ok(rp5.dockHeight >= 125, `Enlarged dock height (${rp5.dockHeight}px) must exceed old 96px`);
  assert.ok(rp5.dockButtonSize >= 90, `Enlarged dock buttons (${rp5.dockButtonSize}px) must exceed old 84px`);
});

test('fit16By9Viewport locks exact 16:9 Retroid Pocket 5 aspect ratio inside desktop & mobile bounds', () => {
  const desktop = fit16By9Viewport(1440, 900);
  assert.equal(desktop.width, 1440);
  assert.equal(desktop.height, 810);

  const ultrawide = fit16By9Viewport(2560, 1080);
  assert.equal(ultrawide.width, 1920);
  assert.equal(ultrawide.height, 1080);
});

test('parseApkPortsListHtml decodes React Router stream and normalizes image URLs', () => {
  const flightArr = [
    { _1: 2 },
    'loaderData',
    { _3: 4 },
    'routes/games',
    { _5: 6, _16: 17, _18: 19 },
    'games',
    [7],
    { _8: 9, _10: 11, _12: 13, _14: 15 },
    'slug',
    'gta-v-test',
    'title',
    'Grand Theft Auto V',
    'main_image',
    '/uploads/thumbs/cover-480.webp',
    'version',
    '1.61',
    'totalCount',
    746,
    'totalPages',
    75,
  ];
  const fakeHtml = `<script>window.__reactRouterContext.streamController.enqueue(${JSON.stringify(
    JSON.stringify(flightArr)
  )});</script>`;
  const parsed = parseApkPortsListHtml(fakeHtml, 'games');
  assert.equal(parsed.totalCount, 746);
  assert.equal(parsed.games.length, 1);
  assert.equal(parsed.games[0].title, 'Grand Theft Auto V');
  assert.equal(parsed.games[0].version, '1.61');
  assert.equal(
    normalizeApkPortsImageUrl('/uploads/thumbs/cover-480.webp'),
    '/api/apkports/image?url=' + encodeURIComponent('https://www.apkports.com/uploads/thumbs/cover-480.webp')
  );
});

test('parseRssOrAtomXml and parseRedditJsonPosts extract news cards cleanly', () => {
  const sampleXml = `
    <rss><channel>
      <item>
        <title><![CDATA[Nintendo Switch 2 Launches Worldwide]]></title>
        <link>https://www.nintendo.com/news/switch-2</link>
        <description><![CDATA[<p>Read full launch hardware and Mario Kart World details.</p><img src="https://example.com/art.jpg" />]]></description>
        <pubDate>Mon, 18 May 2026 12:00:00 GMT</pubDate>
      </item>
    </channel></rss>
  `;
  const rssItems = parseRssOrAtomXml(sampleXml, 'Nintendo.com', 'nso');
  assert.equal(rssItems.length, 1);
  assert.equal(rssItems[0].title, 'Nintendo Switch 2 Launches Worldwide');
  assert.ok(rssItems[0].imageUrl.startsWith('/api/feeds/image?url='));

  const redditSample = {
    data: {
      children: [
        {
          data: {
            id: 'abc1',
            title: 'Balatro Android Port Runs 60fps on RP5',
            selftext: 'Works out of the box with analog sticks and triggers.',
            permalink: '/r/EmulationOnAndroid/comments/abc1',
            created_utc: 1760000000,
          },
        },
      ],
    },
  };
  const redditItems = parseRedditJsonPosts(redditSample, 'r/EmulationOnAndroid', 'android_ports');
  assert.equal(redditItems.length, 1);
  assert.equal(redditItems[0].title, 'Balatro Android Port Runs 60fps on RP5');
});

test('extractArticleContentHtml extracts full paragraphs, og:image, and video embed; NSO fallback exceeds 3 pages', () => {
  const html = `
    <html>
      <head>
        <meta property="og:image" content="https://example.com/hero-hd.jpg" />
      </head>
      <body>
        <p>Please accept our cookie and privacy policy to continue browsing.</p>
        <p>Nintendo revealed expanded Switch 2 hardware benchmarks and 120Hz handheld support across major first-party titles today.</p>
        <p>Retroid Pocket 5 and handheld community testing shows smooth frame pacing and adaptive UI border theming across the library.</p>
        <iframe src="https://www.youtube.com/watch?v=dQw4w9WgXcQ"></iframe>
      </body>
    </html>
  `;
  const extracted = extractArticleContentHtml(html, 'https://example.com/story');
  assert.equal(extracted.paragraphs.length, 2);
  assert.ok(extracted.paragraphs[0].includes('120Hz handheld support'));
  assert.equal(
    extracted.heroImageUrl,
    '/api/feeds/image?url=' + encodeURIComponent('https://example.com/hero-hd.jpg')
  );
  assert.equal(extracted.videoUrl, 'https://www.youtube.com/embed/dQw4w9WgXcQ');

  assert.ok(NSO_FALLBACK_ITEMS.length > 9, 'NSO catalog should span more than 3 pages (9+ items)');
  assert.equal(DEFAULT_SKYLINE_CONFIG.brightnessPct, 100);
  assert.equal(DEFAULT_SKYLINE_CONFIG.allSoftwareSizePct, 100);
  assert.equal(DEFAULT_SKYLINE_CONFIG.browserMode, 'in-app');
  assert.equal(DEFAULT_SKYLINE_CONFIG.borderPreset, 'adaptive');
});

test('pegasus theme zip contains Eden direct boot fix, patched Switch 2 QML, and dynamic config calibration', async () => {
  const fs = await import('node:fs');
  const path = await import('node:path');
  const JSZip = (await import('jszip')).default;
  const { buildCalibratedPegasusThemeZip } = await import('./pegasusThemeZip');
  const { buildSkylineConfigQueryString, parseSkylineConfigFromQuery } = await import(
    './skylineConfigQuery'
  );

  const zipPath = path.resolve(process.cwd(), 'public', 'skylineos2-pegasus-theme.zip');
  assert.ok(fs.existsSync(zipPath), 'public/skylineos2-pegasus-theme.zip must exist');
  const stats = fs.statSync(zipPath);
  assert.ok(stats.size > 5_000_000, 'Zip file must contain full upstream theme (approx 10MB+)');

  const rawZip = fs.readFileSync(zipPath);
  const loaded = await JSZip.loadAsync(rawZip);

  const themeQml = await loaded.file('skylineOS2/theme.qml')?.async('string');
  assert.ok(themeQml, 'theme.qml must exist inside ZIP');
  assert.doesNotMatch(
    themeQml,
    /function playSoftware\(\)[\s\S]{0,220}launchGame\(currentGame\)/,
    'playSoftware must not eagerly call launchGame(currentGame) before state transition'
  );
  assert.doesNotMatch(
    themeQml,
    /function playGame\(\)[\s\S]{0,220}launchGame\(currentGame\)/,
    'playGame must not fire duplicate launchGame before transition ScriptAction'
  );
  assert.match(themeQml, /settings\.darkMode === "Yes" \? themeDark : themeLight/);
  assert.match(themeQml, /handleGlobalSleepCombo/);
  assert.match(themeQml, /"Dark Mode"\) : "Yes"/);
  assert.match(themeQml, /"Appearance Polarity"\) : "Dark"/);
  assert.doesNotMatch(themeQml, /ControllersScreen/, 'theme.qml must not instantiate removed ControllersScreen');

  const highlightQml = await loaded.file('skylineOS2/global/HighlightBorder.qml')?.async('string');
  assert.ok(highlightQml, 'HighlightBorder.qml must exist inside ZIP');
  assert.match(highlightQml, /color:\s*"transparent"/);
  assert.doesNotMatch(highlightQml, /uiPalette/);

  const menuBtnQml = await loaded.file('skylineOS2/layer_home/MenuButton.qml')?.async('string');
  assert.ok(menuBtnQml, 'MenuButton.qml must exist inside ZIP');
  assert.doesNotMatch(menuBtnQml, /Animation\.Infinite/, 'MenuButton must not pulse infinitely');

  // Verify Switch 2 In-Theme eShop (+ NSWPedia), News 2x2 Feed, In-Theme Browser & Split Settings inside ZIP
  const storeQml = await loaded.file('skylineOS2/layer_buttons/StoreScreen.qml')?.async('string');
  assert.ok(storeQml, 'StoreScreen.qml (APKPorts & NSWPedia eShop) must exist inside ZIP');
  assert.match(storeQml, /apkports\.com/i);
  assert.match(storeQml, /nswpedia\.com/i);
  assert.match(storeQml, /NS SWITCH/);
  assert.match(storeQml, /#111111/);
  assert.match(storeQml, /Qt\.openUrlExternally/);
  assert.doesNotMatch(storeQml, /openInThemeBrowser/, 'eShop Download must open Chrome externally, never internal browser');
  assert.match(storeQml, /anchors\s*\{\s*top:\s*parent\.top;\s*bottom:\s*parent\.bottom;\s*left:\s*eshopSidebar\.right;\s*right:\s*parent\.right/);
  assert.match(storeQml, /archive\.org\/download\/ultimate-rom-collection\/Game%20cube\//i);
  assert.match(storeQml, /archive\.org\/download\/ultimate-rom-collection\/PSP\//i);
  assert.match(storeQml, /azBar/);
  assert.match(storeQml, /stepAlphabetLetter/);
  assert.match(storeQml, /wikipedia\.org\/api\/rest_v1\/page\/summary/i);
  assert.match(storeQml, /controls=0/);
  assert.doesNotMatch(storeQml, /width:\s*parent\.width\s*\*\s*0\.86/, 'eShop details must be in-section, not a floating modal');
  assert.doesNotMatch(storeQml, /\.findIndex\(/, 'StoreScreen must stay Qt 5.12 ES5-safe');
  assert.doesNotMatch(storeQml, /limit=1000/, 'StoreScreen must load lazily instead of limit=1000');
  assert.match(storeQml, /limit=25&page=/);
  assert.match(storeQml, /fetchNextStoreBatch/);

  const browserQml = await loaded.file('skylineOS2/layer_buttons/BrowserScreen.qml')?.async('string');
  assert.ok(browserQml, 'BrowserScreen.qml (Netflix Streaming Hub) must exist inside ZIP');
  assert.match(browserQml, /Qt\.createQmlObject/);
  assert.match(browserQml, /closeInThemeBrowser/);
  assert.match(browserQml, /NETFLIX/);
  assert.match(browserQml, /https:\/\/lamovie\.org/);
  assert.match(browserQml, /For Me/);
  assert.match(browserQml, /Favorites/);
  assert.match(browserQml, /Movies/);
  assert.match(browserQml, /Series/);
  assert.match(browserQml, /YouTube/);
  assert.match(browserQml, /Layout\.preferredWidth:\s*vpx\(38\)/);
  assert.match(browserQml, /youtube\.com\/results\?search_query=/);
  assert.match(browserQml, /toggleFavorite/);
  assert.match(browserQml, /BROWSER_FAVORITES/);
  assert.match(browserQml, /goHome/);
  assert.match(browserQml, /netflixAzBar/);
  assert.match(browserQml, /itemsPerPage:\s*20/);
  assert.match(browserQml, /togglePreviewPlayback/);
  assert.match(browserQml, /episodes\/list/);
  assert.doesNotMatch(browserQml, /^\s*import QtWebView/m, 'Must not statically import QtWebView');
  assert.doesNotMatch(browserQml, /^\s*import QtWebEngine/m, 'Must not statically import QtWebEngine');
  assert.doesNotMatch(browserQml, /\.find(Index)?\(/, 'BrowserScreen must stay Qt 5.12 ES5-safe');

  // Verify every QML/JS file in ZIP is Qt 5.15-compatible, balanced, and has zero TextInput/Qt.inputMethod
  const findBraceIssue = (code: string): string | null => {
    const stack: { c: string; line: number }[] = [];
    let line = 1;
    let state = 'code';
    let lastSig = '';
    for (let i = 0; i < code.length; i++) {
      const c = code[i];
      const next = code[i + 1];
      if (c === '\n') {
        line++;
        if (state === 'line_comment' || state === 'regex' || state === 'regex_class') state = 'code';
        continue;
      }
      if (state === 'line_comment') continue;
      if (state === 'block_comment') {
        if (c === '*' && next === '/') { state = 'code'; i++; }
        continue;
      }
      if (state === 'squote') {
        if (c === '\\') { i++; continue; }
        if (c === "'") { state = 'code'; lastSig = ')'; }
        continue;
      }
      if (state === 'dquote') {
        if (c === '\\') { i++; continue; }
        if (c === '"') { state = 'code'; lastSig = ')'; }
        continue;
      }
      if (state === 'regex_class') {
        if (c === '\\') { i++; continue; }
        if (c === ']') state = 'regex';
        continue;
      }
      if (state === 'regex') {
        if (c === '\\') { i++; continue; }
        if (c === '[') { state = 'regex_class'; continue; }
        if (c === '/') { state = 'code'; lastSig = ')'; }
        continue;
      }
      if (c === '/' && next === '/') { state = 'line_comment'; i++; continue; }
      if (c === '/' && next === '*') { state = 'block_comment'; i++; continue; }
      if (c === "'") { state = 'squote'; continue; }
      if (c === '"') { state = 'dquote'; continue; }
      if (c === '/' && ('=(:,;!&|?[{+*-~^%<>'.includes(lastSig) || lastSig === '')) {
        state = 'regex';
        continue;
      }
      if (c === '{' || c === '(' || c === '[') {
        stack.push({ c, line });
        lastSig = c;
      } else if (c === '}' || c === ')' || c === ']') {
        const want = c === '}' ? '{' : c === ')' ? '(' : '[';
        const top = stack.pop();
        if (!top || top.c !== want) return `Unmatched ${c} at line ${line}`;
        lastSig = c;
      } else if (!/\s/.test(c)) {
        lastSig = c;
      }
    }
    return stack.length ? `Unclosed ${stack.map((s) => `${s.c}@${s.line}`).join(', ')}` : null;
  };

  for (const [entryPath, fileObj] of Object.entries(loaded.files)) {
    if (!fileObj.dir && (entryPath.endsWith('.qml') || entryPath.endsWith('.js'))) {
      const txt = await fileObj.async('string');
      const braceIssue = findBraceIssue(txt);
      assert.equal(braceIssue, null, `${entryPath} has brace/paren error: ${braceIssue}`);
    }
    if (!fileObj.dir && entryPath.endsWith('.qml')) {
      const qmlTxt = await fileObj.async('string');
      assert.doesNotMatch(qmlTxt, /import QtQuick 2\.15/, `${entryPath} must not require QtQuick 2.15`);
      assert.doesNotMatch(qmlTxt, /import QtGraphicalEffects 1\.12/, `${entryPath} must use QtGraphicalEffects 1.0`);
      assert.doesNotMatch(qmlTxt, /\bTextInput\s*\{/, `${entryPath} must not instantiate TextInput (no blue box)`);
      assert.doesNotMatch(qmlTxt, /Qt\.inputMethod/, `${entryPath} must not call Qt.inputMethod`);
    }
  }
  assert.doesNotMatch(themeQml, /assets\/audio\/Icons\.wav/, 'theme.qml must not reference missing Icons.wav');
  const utilsJs = await loaded.file('skylineOS2/utils.js')?.async('string');
  assert.ok(utilsJs, 'utils.js must exist inside ZIP');
  assert.doesNotMatch(utilsJs, /\[\.\.\.set\.values\(\)\]/, 'utils.js must avoid ES6 Set spread syntax for Qt 5.15');
  assert.ok(loaded.file('skylineOS2/global/SwitchKeyboard.qml'), 'SwitchKeyboard.qml must exist inside ZIP');
  assert.match(storeQml, /app\.switchsrom\.com/i);
  assert.match(storeQml, /vimm\.net\/vault/i);
  assert.doesNotMatch(storeQml, /anchors\.right:\s*parent\.right;\s*top:\s*parent\.top/, 'StoreScreen must wrap top/bottom in anchors block');
  assert.match(themeQml, /root\.state\s*=\s*"homescreen";/, 'theme.qml Component.onCompleted must assign root.state');
  assert.match(themeQml, /"https:\/\/www\.nintendo\.com"/, 'theme.qml default browserLink must be nintendo.com');

  const infoQml = await loaded.file('skylineOS2/layer_buttons/InfoScreen.qml')?.async('string');
  assert.ok(infoQml, 'InfoScreen.qml (Nintendo Online & News 2x2 Feed) must exist inside ZIP');
  assert.match(infoQml, /Nintendo Online/);
  assert.match(infoQml, /News/);
  assert.match(infoQml, /r\/PuertoRico/);
  assert.match(infoQml, /elnuevodia\.com/);
  assert.doesNotMatch(infoQml, /text:\s*tr?\(["']Back to Grid["']/);
  assert.match(infoQml, /openInThemeBrowser/);
  assert.match(infoQml, /openNewsVideoFullscreen/);
  assert.match(infoQml, /newsVideoHost/);
  assert.match(infoQml, /readerBlocksModel/);
  assert.match(infoQml, /fetchNsoCompanionVideos/);

  const settingsQml = await loaded.file('skylineOS2/layer_settings/SettingsScreen.qml')?.async('string');
  assert.ok(settingsQml, 'SettingsScreen.qml must exist inside ZIP');
  assert.match(settingsQml, /Customize Home/);
  assert.match(settingsQml, /HUD & Colors/);
  assert.match(settingsQml, /User & Browser/);
  assert.match(settingsQml, /About SkyLine 3/);
  assert.match(settingsQml, /System Font Size/);
  assert.match(settingsQml, /width:\s*vpx\(64\);\s*height:\s*vpx\(64\);\s*radius:\s*width\s*\/\s*2/);
  assert.match(settingsQml, /refreshSettings\(\)/);
  assert.doesNotMatch(settingsQml, /sampleFriends/);
  assert.doesNotMatch(settingsQml, /Online: 3/);
  assert.match(settingsQml, /deleteSavedUser/);
  assert.match(settingsQml, /contentSubCol/);
  assert.match(settingsQml, /syncScrollToRow/);

  const gameDetailQml = await loaded.file('skylineOS2/layer_detail/GameDetailScreen.qml')?.async('string');
  assert.ok(gameDetailQml, 'GameDetailScreen.qml must exist inside ZIP');
  assert.match(gameDetailQml, /trailerDelayTimer/);
  assert.match(gameDetailQml, /fetchWikipediaSummary/);
  assert.match(gameDetailQml, /controls=0/);
  assert.match(gameDetailQml, /Edit Info/);
  assert.match(gameDetailQml, /View More Photos/);
  assert.match(gameDetailQml, /bgTrailerVideo\.hasVideo/);
  assert.match(
    gameDetailQml,
    /Behavior on source\s*\{\s*SequentialAnimation\s*\{[\s\S]{0,700}\}\s*\}\s*\}\s*Video\s*\{\s*id:\s*bgTrailerVideo/,
    'Behavior on source and AnimatedImage must close cleanly before Video'
  );
  assert.match(storeQml, /mute=0/);

  const softwareQml = await loaded.file('skylineOS2/layer_grid/SoftwareScreen.qml')?.async('string');
  assert.ok(softwareQml, 'SoftwareScreen.qml must exist inside ZIP');
  assert.match(softwareQml, /changeGridSize/);

  const albumQml = await loaded.file('skylineOS2/layer_buttons/AlbumScreen.qml')?.async('string');
  assert.ok(albumQml, 'AlbumScreen.qml must exist inside ZIP');
  assert.match(albumQml, /property var folderModelObj:\s*null/);

  const userOverlayQml = await loaded.file('skylineOS2/layer_home/UserSelectOverlay.qml')?.async('string');
  assert.ok(userOverlayQml, 'UserSelectOverlay.qml must exist inside ZIP');
  assert.match(userOverlayQml, /deleteUser/);
  assert.match(userOverlayQml, /deleteBadgeBtn/);

  const suspendQml = await loaded.file('skylineOS2/layer_buttons/SuspendScreen.qml')?.async('string');
  assert.ok(suspendQml, 'SuspendScreen.qml (Switchboard Lock Screen) must exist inside ZIP');
  assert.match(suspendQml, /Nintendo Switchboard/);
  assert.match(suspendQml, /HOME Menu/);
  assert.match(suspendQml, /requiredPresses:\s*3/);

  const homeScreenQml = await loaded.file('skylineOS2/layer_home/HomeScreen.qml')?.async('string');
  assert.ok(homeScreenQml, 'HomeScreen.qml must exist inside ZIP');
  assert.match(homeScreenQml, /showButtonScreen\("store"\)/);
  assert.match(homeScreenQml, /showButtonScreen\("browser"\)/);
  assert.match(homeScreenQml, /showButtonScreen\("gameshare"\)/);
  assert.match(homeScreenQml, /showButtonScreen\("chat"\)/);
  assert.doesNotMatch(homeScreenQml, /showButtonScreen\("controllers"\)/, 'Controllers dock button must be removed');
  assert.doesNotMatch(homeScreenQml, /controllersButton/, 'Controllers dock button must be removed');
  assert.match(homeScreenQml, /showButtonScreen\("album"\)/);
  assert.match(homeScreenQml, /openUserSelect\(/);
  assert.doesNotMatch(homeScreenQml, /cloudButton/, 'Cloud Drive must not be in Switch 2 dock');
  assert.doesNotMatch(homeScreenQml, /backlogButton/, 'Backlog legacy button must not be in Switch 2 dock');
  assert.match(homeScreenQml, /api\.memory\.has\("Feed Button Show"\) \? \(api\.memory\.get\("Feed Button Show"\) === "Yes"\) : true/);
  assert.match(homeScreenQml, /Netflix/);
  assert.match(homeScreenQml, /lastHomeSwitcherIndex/);
  assert.match(homeScreenQml, /hudColorSampler/);
  assert.match(homeScreenQml, /adaptiveHudTextColor/);
  assert.match(utilsJs, /function extractPrimaryHudColors/);
  assert.match(themeQml, /interval:\s*3500[\s\S]{0,60}root\.state === "playgame"/);
  assert.match(themeQml, /launchingNow/);
  assert.match(themeQml, /selectSleepTimer[\s\S]{0,80}interval:\s*3000/);

  // Verify ControllersScreen was removed and Switch 2 Overlays & Subscreens + Assets exist inside ZIP
  assert.equal(loaded.file('skylineOS2/layer_buttons/ControllersScreen.qml'), null, 'ControllersScreen.qml must be removed');
  for (const requiredQml of [
    'skylineOS2/layer_home/UserSelectOverlay.qml',
    'skylineOS2/layer_home/GameEditOverlay.qml',
    'skylineOS2/layer_buttons/GameShareScreen.qml',
    'skylineOS2/layer_buttons/ChatScreen.qml',
    'skylineOS2/layer_buttons/AlbumScreen.qml',
  ]) {
    const content = await loaded.file(requiredQml)?.async('string');
    assert.ok(content && content.length > 500, `${requiredQml} must exist and be non-empty in ZIP`);
  }

  for (const av of ['mario.png', 'luigi.png', 'peach.png', 'yoshi.png', 'dk.png', 'bowser.png']) {
    assert.ok(loaded.file(`skylineOS2/assets/images/avatars/${av}`), `Avatar ${av} must exist in ZIP`);
  }
  for (const svg of [
    'ns2_online.svg',
    'ns2_online_idle.svg',
    'ns2_gamechat.svg',
    'ns2_news.svg',
    'ns2_eshop.svg',
    'ns2_album.svg',
    'ns2_gameshare.svg',
    'ns2_browser.svg',
    'ns2_cards.svg',
    'ns2_settings.svg',
    'ns2_sleep.svg',
    'ns2_controller_glyph.svg',
  ]) {
    assert.ok(loaded.file(`skylineOS2/assets/images/navigation/${svg}`), `Nav icon ${svg} must exist in ZIP`);
  }

  for (const textContent of [storeQml, infoQml, settingsQml, homeScreenQml, themeQml]) {
    assert.doesNotMatch(textContent, /Nintendo of America/, 'About/QML must be unbranded (no Nintendo of America)');
  }
  assert.match(storeQml, /Nintendo eShop/);
  assert.match(storeQml, /Download/);
  assert.match(storeQml, /Wish List/);

  // Verify query serialization + calibrated ZIP generation
  const customConfig = {
    ...DEFAULT_SKYLINE_CONFIG,
    username: 'Luigi',
    appearanceMode: 'dark' as const,
    hudThemeId: 'mario' as const,
    cardSizePct: 40,
    backgroundBlurPct: 75,
    borderGapPx720: 8,
    borderThicknessPx720: 8,
    dockHeightPct: 14.2,
    timeFormat: '24hr' as const,
    showBatteryPercent: false,
    uiSoundsEnabled: false,
    browserMode: 'chrome' as const,
    systemFontScalePct: 115,
  };
  const qs = buildSkylineConfigQueryString(customConfig);
  const parsed = parseSkylineConfigFromQuery(Object.fromEntries(new URLSearchParams(qs)));
  assert.equal(parsed.appearanceMode, 'dark');
  assert.equal(parsed.hudThemeId, 'mario');
  assert.equal(parsed.cardSizePct, 40);
  assert.equal(parsed.backgroundBlurPct, 75);

  const calibratedBuf = await buildCalibratedPegasusThemeZip(zipPath, parsed);
  const calibratedZip = await JSZip.loadAsync(calibratedBuf);
  const calThemeQml = await calibratedZip.file('skylineOS2/theme.qml')?.async('string');
  assert.ok(calThemeQml);
  assert.match(calThemeQml, /"Home Card Size"\) : "40"/);
  assert.match(calThemeQml, /"Background Blur"\)\) : 75/);
  assert.match(calThemeQml, /"Dark Mode"\) : "Yes"/);
  assert.match(calThemeQml, /"Appearance Polarity"\) : "Dark"/);
  assert.match(calThemeQml, /"HUD Theme Accent"\) : "Mario Red"/);
  assert.match(calThemeQml, /"UI Sounds"\) : "No"/);
  assert.match(calThemeQml, /"Browser Mode"\) : "chrome"/);
  assert.match(calThemeQml, /"Border Gap"\)\) : 8/);
  assert.match(calThemeQml, /"Border Width"\)\) : 8/);
  assert.match(calThemeQml, /"Dock Size Pct"\)\) : 14\.2/);
  assert.match(calThemeQml, /"Time Format"\) : "24hr"/);
  assert.match(calThemeQml, /"Accent Light Mode"\) : "#E60012"/);
  assert.match(calThemeQml, /"System Font Scale"\)\) : 115/);
  assert.ok(calibratedZip.file('skylineOS2/RP5_PATCH_GUIDE.qml'));

  // Verify Netflix red ribbon N icon, Background Blur QML controls, and Qt 5.12/5.15 RP5 compatibility audit
  const browserSvg = await loaded.file('skylineOS2/assets/images/navigation/ns2_browser.svg')?.async('string');
  assert.ok(browserSvg);
  assert.match(browserSvg, /#E50914/);
  assert.doesNotMatch(browserSvg, /#0EA5E9/);

  assert.match(settingsQml, /Background Blur/);
  assert.match(settingsQml, /editingStepper/);
  assert.match(settingsQml, /"70"/);
  assert.match(settingsQml, /"25"/);
  assert.match(settingsQml, /PLAY_SEQ::/);
  assert.match(themeQml, /"Background Transparency"\) : "70"/);
  assert.match(themeQml, /"Background Blur"\)\) : 25/);
  assert.match(themeQml, /browserScreen\.goHome\(\)/);
  assert.match(themeQml, /restoreLastFocus/);
  assert.match(homeScreenQml, /FastBlur/);
  assert.match(homeScreenQml, /settings\.bgBlur/);
  assert.match(homeScreenQml, /restoreLastFocus/);
  assert.doesNotMatch(infoQml, /kind:\s*"image"/, 'News & NSO paragraphs must not inject inline photos');
  assert.equal(DEFAULT_SKYLINE_CONFIG.backgroundDimPct, 70);
  assert.equal(DEFAULT_SKYLINE_CONFIG.backgroundBlurPct, 25);

  const qmlEntries = Object.keys(loaded.files).filter((k) => /\.(qml|js)$/i.test(k));
  for (const entryName of qmlEntries) {
    const fileText = await loaded.file(entryName)?.async('string');
    if (!fileText) continue;
    assert.doesNotMatch(fileText, /function on[A-Z]/, `${entryName} must use Qt5 onSignal: syntax, not Qt5.15-only function slots`);
    assert.doesNotMatch(fileText, /\.includes\(/, `${entryName} must use ES5 indexOf >= 0 instead of .includes()`);
    assert.doesNotMatch(fileText, /for\s*\(\s*i\s*=\s*0\s*;\s*buttonModel\.length\s*;/, `${entryName} must check i < buttonModel.length`);
    assert.doesNotMatch(fileText, /QtWebView 1\.15[\s\S]{0,160}QtWebView 1\.1/, `${entryName} must try QtWebView 1.1 before 1.15`);
    if (entryName.endsWith('.qml')) {
      assert.doesNotMatch(
        fileText,
        /\b(?:anchors|font|border|sourceSize|padding|Layout)\s*\{[^}]*\}\s*;/,
        `${entryName} must not have a semicolon after a grouped QML property block`
      );
      assert.doesNotMatch(
        fileText,
        /\}\s*;\s*[a-zA-Z_]\w*\s*:/,
        `${entryName} must not have a semicolon before a QML property binding`
      );
    }
  }

  // Verify Eden direct boot intent command
  const edenIntent =
    'am start -n dev.eden.eden_emulator/org.yuzu.yuzu_emu.activities.EmulationActivity -a android.intent.action.VIEW -d "{file.uri}"';
  assert.match(edenIntent, /dev\.eden\.eden_emulator/);
  assert.match(edenIntent, /EmulationActivity/);
  assert.doesNotMatch(edenIntent, /MainActivity/, 'Direct boot must not target MainActivity');
});

test('browserHelper normalizes URLs, checks safety, extracts YouTube IDs, and rewrites HTML for in-app iframe', () => {
  assert.equal(BROWSER_HOME_URL, 'https://www.nintendo.com');
  assert.deepEqual(
    DEFAULT_BROWSER_BOOKMARKS.map((b) => b.label),
    ['Nintendo', 'Google', 'APKPorts', 'YouTube']
  );
  assert.equal(normalizeBrowserInput(''), 'https://www.nintendo.com');
  assert.equal(normalizeBrowserInput('nintendo.com'), 'https://nintendo.com');
  assert.equal(normalizeBrowserInput('mario kart world'), 'https://www.google.com/search?q=mario%20kart%20world');

  assert.equal(extractYouTubeVideoId('https://www.youtube.com/watch?v=3pE23YTYEZM'), '3pE23YTYEZM');
  assert.equal(extractYouTubeVideoId('https://youtu.be/mO2M8d_gX1A'), 'mO2M8d_gX1A');
  assert.equal(isSafeExternalHttpUrl('https://www.nintendo.com'), true);
  assert.equal(isSafeExternalHttpUrl('http://127.0.0.1:3000'), false);

  const rewritten = rewriteHtmlForInAppFrame(
    '<html><head><meta http-equiv="Content-Security-Policy" content="frame-ancestors none"><title>Nintendo</title></head><body><a href="/us/" target="_top">Go</a></body></html>',
    'https://www.nintendo.com/'
  );
  assert.equal(rewritten.title, 'Nintendo');
  assert.doesNotMatch(rewritten.rewrittenHtml, /frame-ancestors/i);
  assert.match(rewritten.rewrittenHtml, /skyline-browser-nav/);
  assert.match(rewritten.rewrittenHtml, /<base href="https:\/\/www\.nintendo\.com\/">/);

  const proxiedHtml = rewriteHtmlForInAppFrame(
    '<html><head><link rel="stylesheet" href="/css/app.css"><link rel="canonical" href="https://apkports.com/games"></head><body><img src="/uploads/cover.webp"></body></html>',
    'https://apkports.com/games',
    { proxyAssets: true }
  );
  assert.match(proxiedHtml.rewrittenHtml, /\/api\/browser\/asset\?url=https%3A%2F%2Fapkports\.com%2Fcss%2Fapp\.css/);
  assert.match(proxiedHtml.rewrittenHtml, /\/api\/browser\/asset\?url=https%3A%2F%2Fapkports\.com%2Fuploads%2Fcover\.webp/);
  assert.match(proxiedHtml.rewrittenHtml, /<link rel="canonical" href="https:\/\/apkports\.com\/games">/);

  const rewrittenCss = rewriteCssForInAppProxy(
    '@font-face{src:url(/fonts/fa-solid.woff2)}',
    'https://apkports.com/css/app.css'
  );
  assert.match(rewrittenCss, /\/api\/browser\/asset\?url=https%3A%2F%2Fapkports\.com%2Ffonts%2Ffa-solid\.woff2/);

  const ddg = parseDuckDuckGoHtmlResults(
    '<a class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fwww.nintendo.com%2F">Nintendo Official</a><a class="result__snippet">Consoles and games</a>'
  );
  assert.equal(ddg.length, 1);
  assert.equal(ddg[0].url, 'https://www.nintendo.com/');
  assert.match(rewritten.rewrittenHtml, /outline:\s*none\s*!important/);
});

test('SwitchsROM, Vimm Vault, and APKPorts JSON API parsers extract full catalogs with pageUrl', () => {
  assert.equal(cleanSwitchsromTitle('Metroid Dread &#8211; Switch ROM (NSP) Free Download'), 'Metroid Dread');

  const swrParsed = parseSwitchsromWpJson(
    [
      {
        id: 101,
        slug: 'metroid-dread-switch-rom',
        link: 'https://app.switchsrom.com/roms/metroid-dread-switch-rom/',
        title: { rendered: 'Metroid Dread NSP Download' },
        excerpt: { rendered: '<p>Action adventure on Planet ZDR.</p>' },
        categories: [12],
        yoast_head_json: { og_image: [{ url: 'https://app.switchsrom.com/wp-content/uploads/dread.jpg' }] },
      },
    ],
    { 12: 'Action' }
  );
  assert.equal(swrParsed.length, 1);
  assert.equal(swrParsed[0].title, 'Metroid Dread');
  assert.equal(swrParsed[0].sourceSite, 'switchsrom');
  assert.equal(swrParsed[0].pageUrl, 'https://app.switchsrom.com/roms/metroid-dread-switch-rom/');
  assert.ok(swrParsed[0].categories.includes('Action'));

  const vimmHtml = `
    <html><body><table class="rounded">
      <tr><td><a href="/vault/5432">Pokemon Emerald Version</a></td><td>USA</td><td>2005</td></tr>
      <tr><td><a href="/vault/1111">Golden Sun</a></td><td>USA</td><td>2001</td></tr>
    </table></body></html>
  `;
  const vimmSys = VIMM_SYSTEMS.find((s) => s.slug === 'GBA')!;
  const vimmParsed = parseVimmSystemHtml(vimmHtml, vimmSys.slug);
  assert.equal(vimmParsed.length, 2);
  assert.equal(vimmParsed[0].title, 'Pokemon Emerald Version');
  assert.equal(vimmParsed[0].system, 'GBA');
  assert.equal(vimmParsed[0].sourceSite, 'vimm');
  assert.equal(vimmParsed[0].pageUrl, 'https://vimm.net/vault/5432');
  assert.ok(vimmParsed[0].coverUrl.includes('image.php'));

  const apiParsed = parseApkPortsApiJson([
    {
      slug: 'balatro-android',
      title: 'Balatro',
      main_image: '/uploads/thumbs/balatro.webp',
      version: '1.0.2',
      port_type: 'unofficial',
      categories: ['Strategy'],
    },
  ]);
  assert.equal(apiParsed.length, 1);
  assert.equal(apiParsed[0].pageUrl, 'https://www.apkports.com/game/balatro-android');
  assert.equal(apiParsed[0].sourceSite, 'apkports');
  assert.equal(VIMM_ALL_SECTIONS.length, 27);
});

test('eshopHelpers unifies all sources, supports >10 pages, and steps A-Z letters cleanly', () => {
  assert.equal(ESHOP_ALPHABET_LETTERS.length, 28);
  assert.equal(stepAlphabetLetter('All', 1), '#');
  assert.equal(stepAlphabetLetter('#', 1), 'A');
  assert.equal(stepAlphabetLetter('All', -1), 'Z');

  const sourceA = Array.from({ length: 40 }, (_, i) => ({
    id: `a-${i}`,
    slug: `a-${i}`,
    title: `${String.fromCharCode(65 + (i % 26))} Game A${i}`,
    coverUrl: '',
    rawImageUrl: '',
    version: '1.0',
    portType: 'official' as const,
    categories: ['Action'],
    franchises: [],
    sourceSite: 'switchsrom' as const,
  }));
  const sourceB = Array.from({ length: 40 }, (_, i) => ({
    id: `b-${i}`,
    slug: `b-${i}`,
    title: `${String.fromCharCode(65 + ((i + 1) % 26))} Game B${i}`,
    coverUrl: '',
    rawImageUrl: '',
    version: 'GC',
    portType: 'unofficial' as const,
    categories: ['GameCube'],
    franchises: [],
    system: 'GameCube',
    sourceSite: 'archive' as const,
  }));

  const unified = unifyEshopCatalog([sourceA, sourceB]);
  assert.equal(unified.length, 80);

  const page11 = filterAndPaginateUnifiedCatalog(unified, { letter: 'All', page: 11, pageSize: 6 });
  assert.ok(page11.totalPages > 10, `Expected > 10 pages, got ${page11.totalPages}`);
  assert.equal(page11.page, 11);
  assert.equal(page11.games.length, 6);

  const onlyZ = filterAndPaginateUnifiedCatalog(unified, { letter: 'Z', page: 1, pageSize: 20 });
  assert.ok(onlyZ.games.length >= 2);
  assert.ok(onlyZ.games.every((g) => g.title.startsWith('Z')));
});

test('lamovieParser unwraps videoapp.zip frames and strips SANDBOX DETECTADO blockers', () => {
  const wrapperHtml = '<div id="app"><iframe id="frame" src="https://vimeos.net/embed-w57f6358kum1.html?cf=token123"></iframe></div>';
  assert.equal(
    extractUnwrappedLaMovieEmbedUrl(wrapperHtml),
    'https://vimeos.net/embed-w57f6358kum1.html'
  );

  const rawVimeos = `<html><head><script>(function(w,d){if(w.voeSandboxBlocked)return;console.log("SANDBOX DETECTADO");})();</script><script disable-devtool-auto src="https://cdn.jsdelivr.net/npm/disable-devtool"></script></head><body><script src="/player/jw8/jwplayer.js"></script><script src="/js/pop.js"></script><div id="vplayer"></div></body></html>`;
  const rewritten = rewriteLaMovieEmbedHtml(rawVimeos, 'https://vimeos.net/embed-w57f6358kum1.html');
  assert.doesNotMatch(rewritten, /voeSandboxBlocked|SANDBOX DETECTADO/);
  assert.doesNotMatch(rewritten, /disable-devtool/);
  assert.doesNotMatch(rewritten, /\/js\/pop\.js/);
  assert.match(rewritten, /<base href="https:\/\/vimeos\.net\/">/);
  assert.match(rewritten, /jwplayer\.js/);
  assert.match(rewritten, /skyline-browser-escape/);
});

test('deriveAdaptiveHudTextColor adapts top HUD text for white, light blue, and dark artworks', () => {
  const whiteBackdrop = { r: 255, g: 255, b: 255 };
  const whiteResult = deriveAdaptiveHudTextColor(whiteBackdrop, whiteBackdrop);
  assert.ok(
    whiteResult.text.r < 45 && whiteResult.text.g < 45 && whiteResult.text.b < 45 && relativeLuminance(whiteResult.text) < 0.03,
    `Expected black ink on white, got ${rgbToHex(whiteResult.text)}`
  );

  const lightBlueBackdrop = { r: 175, g: 226, b: 244 };
  const lightBlueResult = deriveAdaptiveHudTextColor(lightBlueBackdrop, lightBlueBackdrop);
  assert.ok(
    lightBlueResult.text.b > lightBlueResult.text.r && lightBlueResult.text.b > lightBlueResult.text.g,
    `Expected dark blue ink on light blue, got ${rgbToHex(lightBlueResult.text)}`
  );
  assert.ok(
    contrastRatio(lightBlueBackdrop, lightBlueResult.text) >= 5.0,
    `Expected contrast >= 5.0 on light blue, got ${contrastRatio(lightBlueBackdrop, lightBlueResult.text)}`
  );

  const darkCrimson = { r: 42, g: 14, b: 18 };
  const darkCrimsonResult = deriveAdaptiveHudTextColor(darkCrimson, darkCrimson);
  assert.ok(
    relativeLuminance(darkCrimsonResult.text) > 0.55 && contrastRatio(darkCrimson, darkCrimsonResult.text) >= 6.0,
    `Expected bright readable text on dark crimson, got ${rgbToHex(darkCrimsonResult.text)}`
  );
});

test('filterAndPaginateLaMovieCatalog paginates 20 items per page and filters A-Z + #', () => {
  const sample = Array.from({ length: 45 }, (_, i) => ({
    id: `lm-${i}`,
    postId: i + 1,
    slug: `title-${i}`,
    title: i < 5 ? `${i + 1}st Movie` : `${String.fromCharCode(65 + ((i - 5) % 26))} Film ${i}`,
    mediaType: (i % 2 === 0 ? 'movies' : 'tvshows') as 'movies' | 'tvshows',
    overview: 'Sample movie overview',
    posterUrl: '',
    backdropUrl: '',
    rawPosterUrl: '',
    rawBackdropUrl: '',
    genres: ['Acción'],
    pageUrl: 'https://lamovie.org',
  }));

  const p1 = filterAndPaginateLaMovieCatalog(sample, { letter: 'All', page: 1, pageSize: 20 });
  assert.equal(p1.totalCount, 45);
  assert.equal(p1.totalPages, 3);
  assert.equal(p1.items.length, 20);

  const p3 = filterAndPaginateLaMovieCatalog(sample, { letter: 'All', page: 3, pageSize: 20 });
  assert.equal(p3.page, 3);
  assert.equal(p3.items.length, 5);

  const numOnly = filterAndPaginateLaMovieCatalog(sample, { letter: '#', page: 1, pageSize: 20 });
  assert.equal(numOnly.totalCount, 5);

  const aOnly = filterAndPaginateLaMovieCatalog(sample, { letter: 'A', page: 1, pageSize: 20 });
  assert.ok(aOnly.items.length >= 1 && aOnly.items.every((x) => x.title.startsWith('A')));
});
