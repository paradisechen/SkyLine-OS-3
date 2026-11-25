// skylineOS 2 — StoreScreen.qml (Nintendo eShop — Bigger Controller-Navigable Sidebar, Front Red Border, Real Descriptions, Star Wishlist, Download & Autoplay Video)
import QtQuick 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

FocusScope {
    id: storeRoot
    anchors.fill: parent

    // Sidebar entries (unified catalog across APKPorts, NSWPedia, SwitchsROM, Vimm's Vault & Archive.org)
    property var sidebarEntries: [
        { id: "highlights",label: "Highlights",      kind: "section",  cat: "" },
        { id: "foryou",    label: "For You",         kind: "section",  cat: "" },
        { id: "wishlist",  label: "Wish List",       kind: "section",  cat: "" },
        { id: "genre_hdr", label: "Genres",          kind: "header",   cat: "" },
        { id: "g_action",  label: "Action",          kind: "genre",    cat: "Action" },
        { id: "g_rpg",     label: "RPG",             kind: "genre",    cat: "RPG" },
        { id: "g_adv",     label: "Adventure",       kind: "genre",    cat: "Adventure" },
        { id: "g_shoot",   label: "Shooter",         kind: "genre",    cat: "Shooter" },
        { id: "g_plat",    label: "Platformer",      kind: "genre",    cat: "Platformer" },
        { id: "g_race",    label: "Racing",          kind: "genre",    cat: "Racing" },
        { id: "g_sim",     label: "Simulation",      kind: "genre",    cat: "Simulation" },
        { id: "g_sports",  label: "Sports",          kind: "genre",    cat: "Sports" },
        { id: "g_indie",   label: "Indie",           kind: "genre",    cat: "Indie" },
        { id: "g_puzzle",  label: "Puzzle",          kind: "genre",    cat: "Puzzle" },
        { id: "g_gba",     label: "GBA ROMs",        kind: "genre",    cat: "GBA" },
        { id: "g_ds",      label: "Nintendo DS",     kind: "genre",    cat: "DS" },
        { id: "g_n64",     label: "Nintendo 64",     kind: "genre",    cat: "N64" },
        { id: "g_snes",    label: "SNES ROMs",       kind: "genre",    cat: "SNES" },
        { id: "g_gc",      label: "GameCube",        kind: "genre",    cat: "GameCube" },
        { id: "g_ps2",     label: "PS2 Vault",       kind: "genre",    cat: "PS2" },
        { id: "g_psp",     label: "PSP Vault",       kind: "genre",    cat: "PSP" },
        { id: "charts",    label: "Charts",          kind: "section",  cat: "" },
        { id: "az",        label: "A > Z",           kind: "sort",     cat: "" }
    ]

    property var alphabetLetters: ["All", "#", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    property string activeLetter: "All"
    property string activeSection: "highlights"
    property string selectedCategory: ""
    property string sortMode: "featured" // "featured" | "title" | "charts"
    property int selectedIndex: 0
    property int sidebarFocusIdx: 0
    property string focusZone: "grid" // "sidebar" | "grid" | "detail" | "fullscreenVideo"
    property int currentPage: 0
    property int itemsPerPage: 6
    property bool isLoading: false
    property bool detailOpen: false
    property var detailGame: ({})
    property string detailDesc: ""
    property string detailDownloadUrl: ""
    property string detailVideoUrl: ""
    property bool detailFetching: false
    property bool fullscreenVideo: false
    property int detailFocusBtn: 0 // 0=Download, 1=Wishlist, 2=Video Preview
    property var videoPlayerObj: null
    property var fullVideoPlayerObj: null
    property var fullWebObj: null
    property var detailWebObj: null
    property string detailYoutubeEmbed: ""
    property var vimmPendingQueue: []
    property bool vimmQueueRunning: false

    property int apkpApiPage: 1
    property int nswApiPage: 1
    property int swrApiPage: 1
    property int vimmSysCursor: 0
    property int vimmSecCursor: 0
    property bool hasMoreApkp: true
    property bool hasMoreNsw: true
    property bool hasMoreSwr: true
    property bool hasMoreVimm: true
    property bool archiveLoaded: false
    property bool storeBatchBusy: false
    property var switchsromCatMap: ({})

    property var allGamesCache: []
    property var wishlistSlugs: api.memory.has("ESHOP_WISHLIST") ? api.memory.get("ESHOP_WISHLIST") : []

    property bool isDarkPage: (settings.appearanceMode === "Dark") || (settings.appearanceMode === "Auto" && settings.darkMode === "Yes")
    property color pageBg: isDarkPage ? "#18191D" : "#FFFFFF"
    property color sidebarBg: isDarkPage ? "#20222A" : "#F3F4F6"
    property color cardBg: isDarkPage ? "#252832" : "#FFFFFF"
    property color textMain: isDarkPage ? "#F9FAFB" : "#111827"
    property color textMuted: isDarkPage ? "#9CA3AF" : "#4B5563"
    property color dividerColor: isDarkPage ? "#323642" : "#E5E7EB"
    property color eshopRed: "#E60012"

    property var fallbackCatalog: [
        { slug: "hollow-knight", title: "Hollow Knight", version: "1.5.78", portType: "unofficial", sourceSite: "apkports", category: "Action", dev: "Team Cherry / Port", desc: "Forge your own path in Hollow Knight! An epic action adventure through a vast ruined kingdom of insects and heroes beneath the fading town of Dirtmouth.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/367520/header.jpg", video: "https://cdn.cloudflare.steamstatic.com/steam/apps/256705184/movie480.mp4" },
        { slug: "celeste-android", title: "Celeste", version: "1.4.0", portType: "unofficial", sourceSite: "apkports", category: "Platformer", dev: "Maddy Makes Games / Port", desc: "Help Madeline survive her inner demons on her journey to the top of Celeste Mountain, in this super-tight handcrafted platformer with 700+ screens.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/504230/header.jpg", video: "https://cdn.cloudflare.steamstatic.com/steam/apps/256706725/movie480.mp4" },
        { slug: "cuphead-android", title: "Cuphead", version: "1.3.4", portType: "unofficial", sourceSite: "apkports", category: "Action", dev: "Studio MDHR / Port", desc: "Classic run-and-gun action game heavily focused on boss battles. Inspired by 1930s cartoons with hand-drawn cel animation, watercolor backgrounds, and jazz recordings.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/268910/header.jpg", video: "https://cdn.cloudflare.steamstatic.com/steam/apps/256696350/movie480.mp4" },
        { slug: "sonic-mania-plus", title: "Sonic Mania Plus", version: "1.05", portType: "unofficial", sourceSite: "apkports", category: "Platformer", dev: "RSDKv5 Decompilation", desc: "A celebration of classic 2D Sonic built at crisp 60fps widescreen with Encore Mode, Mighty and Ray playable characters, and remixed iconic zones.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/584400/header.jpg", video: "https://cdn.cloudflare.steamstatic.com/steam/apps/256692748/movie480.mp4" },
        { slug: "ship-of-harkinian", title: "Ship of Harkinian (OoT)", version: "8.0.6", portType: "unofficial", sourceSite: "apkports", category: "Adventure", dev: "Harbour Masters", desc: "Experience The Legend of Zelda: Ocarina of Time natively at 60fps+ with widescreen aspect ratio, free right-stick camera, gyro aiming, and HD texture support.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-skyward-sword-hd-switch/hero", video: "" },
        { slug: "undertale-android", title: "Undertale", version: "1.08", portType: "unofficial", sourceSite: "apkports", category: "RPG", dev: "Toby Fox / Community", desc: "Welcome to UNDERTALE. In this RPG, you control a human who falls underground into the world of monsters. Now you must find your way out—or stay trapped forever.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/391540/header.jpg", video: "https://cdn.cloudflare.steamstatic.com/steam/apps/2040377/movie480.mp4" },
        { slug: "half-life-2-android", title: "Half-Life 2", version: "1.14", portType: "unofficial", sourceSite: "apkports", category: "Shooter", dev: "nillerusr / Source Engine", desc: "Pick up the crowbar once more as Gordon Freeman in Valve's landmark sci-fi first-person shooter, running natively on Android via the Source Engine port.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/220/header.jpg", video: "" },
        { slug: "portal-android", title: "Portal", version: "1.14", portType: "unofficial", sourceSite: "apkports", category: "Adventure", dev: "nillerusr / Source Engine", desc: "Use the Aperture Science Handheld Portal Device to solve mind-bending spatial physics chambers and outwit GLaDOS natively on handheld Android.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/400/header.jpg", video: "" },
        { slug: "tmnt-shredders-revenge", title: "TMNT: Shredder's Revenge", version: "1.2.12", portType: "official", sourceSite: "apkports", category: "Action", dev: "Tribute Games", desc: "Leonardo, Raphael, Donatello, Michelangelo and Splinter reunite in a rad 80s arcade beat-em-up with gorgeous full-color pixel art and co-op action.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/1361510/header.jpg", video: "https://cdn.cloudflare.steamstatic.com/steam/apps/256891322/movie480.mp4" },
        { slug: "stardew-valley", title: "Stardew Valley", version: "1.6.14", portType: "official", sourceSite: "apkports", category: "Simulation", dev: "ConcernedApe", desc: "Inherit your grandfather's old farm plot in Stardew Valley. Raise animals, grow seasonal crops, explore mysterious caves, and build a new life.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/413150/header.jpg", video: "https://cdn.cloudflare.steamstatic.com/steam/apps/256660296/movie480.mp4" },
        { slug: "horizon-chase", title: "Horizon Chase Turbo", version: "2.6.0", portType: "official", sourceSite: "apkports", category: "Racing", dev: "Aquiris", desc: "Classic arcade racing inspired by 90s hits like OutRun and Top Gear with vibrant low-poly visuals, synthwave beats, and split-screen action.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/389140/header.jpg", video: "https://cdn.cloudflare.steamstatic.com/steam/apps/256716885/movie480.mp4" },
        { slug: "rocket-league-sideswipe", title: "Rocket League Sideswipe", version: "1.9", portType: "official", sourceSite: "apkports", category: "Sports", dev: "Psyonix", desc: "Fast-paced 2D car soccer action designed for quick competitive matches with aerial boosts, flips, and crisp controller support.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/252950/header.jpg", video: "" },
        { slug: "nsw-zelda-totk", title: "Zelda: Tears of the Kingdom", version: "1.2.1", portType: "switch", sourceSite: "nswpedia", category: "Adventure", dev: "Nintendo / NSWPedia", desc: "Explore the vast land and skies of Hyrule in The Legend of Zelda: Tears of the Kingdom Switch release.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-tears-of-the-kingdom-switch/hero", video: "" },
        { slug: "nsw-super-mario-wonder", title: "Super Mario Bros. Wonder", version: "1.0.1", portType: "switch", sourceSite: "nswpedia", category: "Platformer", dev: "Nintendo / NSWPedia", desc: "Expect the unexpected in Super Mario Bros. Wonder as Wonder Flowers transform every course across the Flower Kingdom.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/s/super-mario-bros-wonder-switch/hero", video: "" },
        { slug: "nsw-mario-kart-8-deluxe", title: "Mario Kart 8 Deluxe", version: "3.0.3", portType: "switch", sourceSite: "nswpedia", category: "Racing", dev: "Nintendo / NSWPedia", desc: "Hit the road with the definitive version of Mario Kart 8 featuring 96 tracks including Booster Course Pass.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/m/mario-kart-8-deluxe-switch/hero", video: "" },
        { slug: "nsw-metroid-dread", title: "Metroid Dread", version: "2.1.0", portType: "switch", sourceSite: "nswpedia", category: "Action", dev: "MercurySteam / NSWPedia", desc: "Join bounty hunter Samus Aran on Planet ZDR in a tense side-scrolling action-adventure escaping relentless E.M.M.I. robots.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/m/metroid-dread-switch/hero", video: "" },
        { slug: "nsw-bayonetta-3", title: "Bayonetta 3", version: "1.2.0", portType: "switch", sourceSite: "nswpedia", category: "Action", dev: "PlatinumGames / NSWPedia", desc: "Wield wicked weaves and Demon Masquerade abilities across stylized action set pieces.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/b/bayonetta-3-switch/hero", video: "" },
        { slug: "nsw-balatro-switch", title: "Balatro", version: "1.0.4", portType: "switch", sourceSite: "nswpedia", category: "Puzzle", dev: "LocalThunk / NSWPedia", desc: "The hypnotic poker roguelike deckbuilder combining illegal poker hands with game-changing Jokers.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/2379780/header.jpg", video: "", pageUrl: "https://nswpedia.com/" },
        { slug: "nsw-hades-switch", title: "Hades", version: "1.0.3", portType: "switch", sourceSite: "nswpedia", category: "Indie", dev: "Supergiant / NSWPedia", desc: "Defy the god of the dead as you hack and slash out of the Underworld in this award-winning rogue-like dungeon crawler.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/1145360/header.jpg", video: "", pageUrl: "https://nswpedia.com/" },
        { slug: "sr-xenoblade-x-de", title: "Xenoblade Chronicles X: DE", version: "Switch ROM", portType: "switch", sourceSite: "switchsrom", category: "RPG", dev: "SwitchsROM.com", desc: "SwitchsROM NSP/XCI Switch release. Click Download to open the SwitchsROM game page.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/x/xenoblade-chronicles-3-switch/hero", video: "", pageUrl: "https://app.switchsrom.com/roms/" },
        { slug: "sr-donkey-kong-returns-hd", title: "Donkey Kong Country Returns HD", version: "Switch ROM", portType: "switch", sourceSite: "switchsrom", category: "Platformer", dev: "SwitchsROM.com", desc: "SwitchsROM NSP/XCI Switch release. Click Download to open the SwitchsROM game page.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/d/donkey-kong-country-returns-hd-switch/hero", video: "", pageUrl: "https://app.switchsrom.com/roms/" },
        { slug: "vimm-gba-pokemon-emerald", title: "Pokemon Emerald (GBA)", version: "GBA ROM", portType: "rom", sourceSite: "vimm", category: "GBA / RPG", dev: "Vimm's Lair Vault", desc: "GBA Vault verified ROM on Vimm's Lair. Click Download to open the Vimm's Lair game page.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/p/pokemon-scarlet-switch/hero", video: "", pageUrl: "https://vimm.net/vault/?p=list&system=GBA" },
        { slug: "vimm-ds-mario-kart-ds", title: "Mario Kart DS (DS)", version: "DS ROM", portType: "rom", sourceSite: "vimm", category: "DS / Racing", dev: "Vimm's Lair Vault", desc: "Nintendo DS Vault verified ROM on Vimm's Lair. Click Download to open the Vimm's Lair game page.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/m/mario-kart-8-deluxe-switch/hero", video: "", pageUrl: "https://vimm.net/vault/?p=list&system=DS" },
        { slug: "vimm-n64-zelda-oot", title: "Zelda: Ocarina of Time (N64)", version: "N64 ROM", portType: "rom", sourceSite: "vimm", category: "N64 / Adventure", dev: "Vimm's Lair Vault", desc: "Nintendo 64 Vault verified ROM on Vimm's Lair. Click Download to open the Vimm's Lair game page.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-tears-of-the-kingdom-switch/hero", video: "", pageUrl: "https://vimm.net/vault/?p=list&system=N64" },
        { slug: "vimm-snes-super-metroid", title: "Super Metroid (SNES)", version: "SNES ROM", portType: "rom", sourceSite: "vimm", category: "SNES / Action", dev: "Vimm's Lair Vault", desc: "Super Nintendo Vault verified ROM on Vimm's Lair. Click Download to open the Vimm's Lair game page.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/m/metroid-prime-remastered-switch/hero", video: "", pageUrl: "https://vimm.net/vault/?p=list&system=SNES" },
        { slug: "vimm-gc-melee", title: "Super Smash Bros. Melee (GameCube)", version: "GC ROM", portType: "rom", sourceSite: "vimm", category: "GameCube / Action", dev: "Vimm's Lair Vault", desc: "GameCube Vault verified ROM on Vimm's Lair. Click Download to open the Vimm's Lair game page.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/s/super-smash-bros-ultimate-switch/hero", video: "", pageUrl: "https://vimm.net/vault/?p=list&system=GC" },
        { slug: "vimm-ps2-kingdom-hearts-2", title: "Kingdom Hearts II (PS2)", version: "PS2 ISO", portType: "rom", sourceSite: "vimm", category: "PS2 / RPG", dev: "Vimm's Lair Vault", desc: "PlayStation 2 Vault verified ROM on Vimm's Lair. Click Download to open the Vimm's Lair game page.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/2552430/header.jpg", video: "", pageUrl: "https://vimm.net/vault/?p=list&system=PS2" },
        { slug: "vimm-psp-god-of-war", title: "God of War: Chains of Olympus (PSP)", version: "PSP ISO", portType: "rom", sourceSite: "vimm", category: "PSP / Action", dev: "Vimm's Lair Vault", desc: "PSP Vault verified ROM on Vimm's Lair. Click Download to open the Vimm's Lair game page.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/1593500/header.jpg", video: "", pageUrl: "https://vimm.net/vault/?p=list&system=PSP" },
        { slug: "archive-gc-wind-waker", title: "The Legend of Zelda: The Wind Waker (GameCube)", version: "Archive GC", portType: "rom", sourceSite: "archiveorg", category: "GameCube / Adventure", dev: "Internet Archive", desc: "GameCube archive release from Internet Archive Ultimate ROM Collection.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-tears-of-the-kingdom-switch/hero", video: "", pageUrl: "https://archive.org/download/ultimate-rom-collection/Game%20cube/" },
        { slug: "archive-gc-metroid-prime", title: "Metroid Prime (GameCube)", version: "Archive GC", portType: "rom", sourceSite: "archiveorg", category: "GameCube / Shooter", dev: "Internet Archive", desc: "GameCube archive release from Internet Archive Ultimate ROM Collection.", cover: "https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_800/ncom/en_US/games/switch/m/metroid-prime-remastered-switch/hero", video: "", pageUrl: "https://archive.org/download/ultimate-rom-collection/Game%20cube/" },
        { slug: "archive-psp-persona-3-portable", title: "Persona 3 Portable (PSP)", version: "Archive PSP", portType: "rom", sourceSite: "archiveorg", category: "PSP / RPG", dev: "Internet Archive", desc: "PSP archive release from Internet Archive Ultimate ROM Collection.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/1809700/header.jpg", video: "", pageUrl: "https://archive.org/download/ultimate-rom-collection/PSP/" },
        { slug: "archive-psp-crisis-core", title: "Crisis Core: Final Fantasy VII (PSP)", version: "Archive PSP", portType: "rom", sourceSite: "archiveorg", category: "PSP / RPG", dev: "Internet Archive", desc: "PSP archive release from Internet Archive Ultimate ROM Collection.", cover: "https://cdn.cloudflare.steamstatic.com/steam/apps/1608070/header.jpg", video: "", pageUrl: "https://archive.org/download/ultimate-rom-collection/PSP/" }
    ]

    ListModel { id: filteredModel }
    ListModel { id: pageGridModel }

    function isWishlisted(slug) {
        for (var i = 0; i < wishlistSlugs.length; i++) {
            if (wishlistSlugs[i] === slug) return true;
        }
        return false;
    }

    function toggleWishlist(slug) {
        if (!slug || slug === "") return;
        var next = wishlistSlugs.slice(0);
        var foundAt = -1;
        for (var i = 0; i < next.length; i++) {
            if (next[i] === slug) { foundAt = i; break; }
        }
        if (foundAt >= 0) { next.splice(foundAt, 1); turnOffSfx.play(); }
        else { next.push(slug); turnOnSfx.play(); }
        wishlistSlugs = next;
        api.memory.set("ESHOP_WISHLIST", next);
        if (activeSection === "wishlist") rebuildGrid();
    }

    function totalPages() {
        return Math.max(1, Math.ceil(filteredModel.count / itemsPerPage));
    }

    function rebuildPageSlice() {
        pageGridModel.clear();
        var tp = totalPages();
        if (currentPage >= tp) currentPage = tp - 1;
        if (currentPage < 0) currentPage = 0;
        var start = currentPage * itemsPerPage;
        var end = Math.min(filteredModel.count, start + itemsPerPage);
        for (var i = start; i < end; i++) {
            pageGridModel.append(filteredModel.get(i));
        }
        if (selectedIndex >= pageGridModel.count) selectedIndex = Math.max(0, pageGridModel.count - 1);
    }

    function matchesLetter(title, letter) {
        if (!letter || letter === "All") return true;
        var clean = String(title || "").trim();
        if (clean === "") return letter === "#";
        var first = clean.charAt(0).toUpperCase();
        if (letter === "#") return !/^[A-Z]$/.test(first);
        return first === String(letter).toUpperCase();
    }

    function hasMoreSources() {
        return hasMoreApkp || hasMoreNsw || hasMoreSwr || hasMoreVimm || !archiveLoaded;
    }

    function stepAlphabetLetter(dir) {
        var idx = alphabetLetters.indexOf(activeLetter);
        if (idx < 0) idx = 0;
        var nextIdx = (idx + dir + alphabetLetters.length) % alphabetLetters.length;
        activeLetter = alphabetLetters[nextIdx];
        navSound.play();
        rebuildGrid();
        if (filteredModel.count < itemsPerPage && hasMoreSources()) fetchNextStoreBatch();
    }

    function selectAlphabetLetter(letter) {
        activeLetter = letter;
        navSound.play();
        rebuildGrid();
        if (filteredModel.count < itemsPerPage && hasMoreSources()) fetchNextStoreBatch();
    }

    function unifyCatalogGames(items) {
        var buckets = {};
        var order = ["apkports", "nswpedia", "switchsrom", "vimm", "archiveorg", "other"];
        var i;
        for (i = 0; i < order.length; i++) buckets[order[i]] = [];
        for (i = 0; i < items.length; i++) {
            var it = items[i];
            if (!it) continue;
            var s = String(it.sourceSite || (it.portType === "switch" ? "nswpedia" : "apkports"));
            if (!buckets[s]) s = "other";
            buckets[s].push(it);
        }
        var out = [];
        var added = true;
        var idx = 0;
        while (added) {
            added = false;
            for (i = 0; i < order.length; i++) {
                var b = buckets[order[i]];
                if (idx < b.length) {
                    out.push(b[idx]);
                    added = true;
                }
            }
            idx++;
        }
        return out;
    }

    function rebuildGrid() {
        filteredModel.clear();
        var rawBase = allGamesCache.length > 0 ? allGamesCache : fallbackCatalog;
        var base = unifyCatalogGames(rawBase);
        var catLower = String(selectedCategory || "").trim().toLowerCase();
        var arr = [];

        for (var i = 0; i < base.length; i++) {
            var g = base[i];
            if (activeSection === "wishlist" && !isWishlisted(g.slug)) continue;
            if (activeSection === "foryou" && g.portType === "official" && i % 2 === 1) continue;
            if (!matchesLetter(g.title, activeLetter)) continue;
            if (catLower !== "") {
                var c = String(g.category || "APK Port").toLowerCase();
                var d = String(g.desc || "").toLowerCase();
                var t = String(g.title || "").toLowerCase();
                var matchedCat = (c.indexOf(catLower) >= 0 || d.indexOf(catLower) >= 0 || t.indexOf(catLower) >= 0);
                if (!matchedCat && catLower === "gamecube" && (c.indexOf("gc") >= 0 || t.indexOf("(gc)") >= 0 || t.indexOf("game cube") >= 0)) matchedCat = true;
                if (!matchedCat) continue;
            }
            arr.push(g);
        }

        if (sortMode === "title") {
            arr.sort(function(a, b) {
                var ta = String(a.title || "").toLowerCase();
                var tb = String(b.title || "").toLowerCase();
                return ta < tb ? -1 : (ta > tb ? 1 : 0);
            });
        } else if (sortMode === "charts") {
            arr = arr.slice(0).reverse();
        }

        for (var j = 0; j < arr.length; j++) {
            var it = arr[j];
            filteredModel.append({
                slug: String(it.slug || ""),
                title: String(it.title || ""),
                version: String(it.version || "Latest"),
                portType: String(it.portType || "unofficial"),
                sourceSite: String(it.sourceSite || (it.portType === "switch" ? "nswpedia" : "apkports")),
                category: String(it.category || "Action"),
                dev: String(it.dev || "APKPorts.com"),
                desc: String(it.desc || ""),
                cover: String(it.cover || ""),
                video: String(it.video || ""),
                pageUrl: String(it.pageUrl || "")
            });
        }
        currentPage = 0;
        selectedIndex = 0;
        rebuildPageSlice();
    }

    function activateSidebarEntry(idx) {
        if (idx < 0 || idx >= sidebarEntries.length) return;
        var entry = sidebarEntries[idx];
        if (entry.kind === "header") return;
        sidebarFocusIdx = idx;
        selectSfx.play();
        if (entry.kind === "genre") {
            activeSection = "genres";
            selectedCategory = entry.cat;
            sortMode = "featured";
        } else if (entry.kind === "sort") {
            activeSection = "az";
            selectedCategory = "";
            sortMode = "title";
        } else {
            activeSection = entry.id;
            selectedCategory = "";
            sortMode = (entry.id === "charts") ? "charts" : "featured";
        }
        rebuildGrid();
        if ((selectedCategory === "GameCube" || selectedCategory === "PSP") && !archiveLoaded) {
            fetchLiveArchiveOrg();
        }
    }

    function moveSidebar(dir) {
        var next = sidebarFocusIdx;
        for (var s = 0; s < sidebarEntries.length; s++) {
            next = (next + dir + sidebarEntries.length) % sidebarEntries.length;
            if (sidebarEntries[next].kind !== "header") break;
        }
        sidebarFocusIdx = next;
        sidebarList.positionViewAtIndex(sidebarFocusIdx, ListView.Contain);
    }

    function decodeEntities(str) {
        return String(str || "")
            .replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"").replace(/&#39;|&apos;/g, "'").replace(/&nbsp;/g, " ");
    }

    function cleanHtml(s) {
        return decodeEntities(String(s || ""))
            .replace(/<script[\s\S]*?<\/script>/gi, " ")
            .replace(/<style[\s\S]*?<\/style>/gi, " ")
            .replace(/<[^>]+>/g, " ")
            .replace(/\s+/g, " ")
            .trim();
    }

    function parseApkPortsHtml(html) {
        var results = [];
        var seen = {};
        if (!html || html.length < 40) return results;
        var cardRe = /<a[^>]+href=["'](?:https?:\/\/www\.apkports\.com)?\/game\/([^"'?#\/]+)["'][^>]*>([\s\S]*?)<\/a>/gi;
        var m;
        while ((m = cardRe.exec(html)) !== null && results.length < 60) {
            var slug = m[1].trim();
            if (!slug || seen[slug]) continue;
            var block = m[2];
            var imgM = block.match(/<img[^>]+(?:data-src|src)=["']([^"']+)["']/i);
            var hM = block.match(/<(?:h2|h3|h4|span|div)[^>]*>([^<]{2,64})<\/(?:h2|h3|h4|span|div)>/i);
            var title = hM ? hM[1].replace(/\s+/g, " ").trim() : slug.replace(/-/g, " ");
            if (title.length < 2) continue;
            var verM = block.match(/v?(\d+\.\d+(?:\.\d+)?)/i);
            var cover = imgM ? decodeEntities(imgM[1].trim()) : "";
            if (cover.indexOf("/") === 0) cover = "https://www.apkports.com" + cover;
            seen[slug] = true;
            // Match fallback description if known slug
            var fbDesc = "";
            var fbVid = "";
            var fbCat = "Action";
            for (var f = 0; f < fallbackCatalog.length; f++) {
                if (fallbackCatalog[f].slug === slug || fallbackCatalog[f].title.toLowerCase() === title.toLowerCase()) {
                    fbDesc = fallbackCatalog[f].desc;
                    fbVid = fallbackCatalog[f].video || "";
                    fbCat = fallbackCatalog[f].category;
                    break;
                }
            }
            results.push({
                slug: slug,
                title: title,
                version: verM ? verM[1] : "Latest",
                portType: /official/i.test(block) ? "official" : "unofficial",
                category: fbCat,
                dev: "APKPorts.com",
                desc: fbDesc !== "" ? fbDesc : (title + " Android game port. Select to inspect game synopsis & download directly from APKPorts."),
                cover: cover,
                video: fbVid
            });
        }
        return results;
    }

    function mergeStoreGames(added) {
        if (!added || added.length === 0) return;
        var merged = allGamesCache.slice(0);
        var bySlug = {};
        for (var j = 0; j < merged.length; j++) bySlug[merged[j].slug] = true;
        for (var i = 0; i < added.length; i++) {
            if (!bySlug[added[i].slug]) {
                bySlug[added[i].slug] = true;
                merged.push(added[i]);
            }
        }
        allGamesCache = merged;
        rebuildGrid();
    }

    function fetchLiveNswPedia(pageNum) {
        var pg = pageNum || 1;
        var xhrN = new XMLHttpRequest();
        xhrN.onreadystatechange = function() {
            if (xhrN.readyState !== XMLHttpRequest.DONE) return;
            var addedJson = [];
            if (xhrN.status >= 200 && xhrN.status < 400 && xhrN.responseText) {
                try {
                    var posts = JSON.parse(xhrN.responseText);
                    if (Array.isArray(posts) && posts.length > 0) {
                        for (var i = 0; i < posts.length; i++) {
                            var p = posts[i];
                            if (!p || !p.title || !p.title.rendered) continue;
                            var t = cleanHtml(p.title.rendered).replace(/NSP\s*\/?\s*XCI.*$/i, "").trim();
                            var slug = "nsw-" + (p.slug || t.toLowerCase().replace(/[^a-z0-9]+/g, "-"));
                            var excerpt = p.excerpt && p.excerpt.rendered ? cleanHtml(p.excerpt.rendered) : "";
                            var imgM = p.content && p.content.rendered ? p.content.rendered.match(/<img[^>]+(?:data-src|src)=["']([^"']+)["']/i) : null;
                            addedJson.push({
                                slug: slug,
                                title: t,
                                version: "NSP/XCI",
                                portType: "switch",
                                sourceSite: "nswpedia",
                                category: "Action",
                                dev: "NSWPedia.com",
                                desc: excerpt || (t + " Nintendo Switch release from NSWPedia.com."),
                                cover: (p.yoast_head_json && p.yoast_head_json.og_image && p.yoast_head_json.og_image[0]) ? p.yoast_head_json.og_image[0].url : (imgM ? decodeEntities(imgM[1]) : ""),
                                video: "",
                                pageUrl: String(p.link || "https://nswpedia.com/")
                            });
                        }
                        mergeStoreGames(addedJson);
                    }
                } catch (e) {}
            }
            if (addedJson.length < 20 || pg >= 15) hasMoreNsw = false;
        };
        xhrN.open("GET", "https://nswpedia.com/wp-json/wp/v2/posts?per_page=20&page=" + pg);
        xhrN.send();
    }

    function fetchSwitchsRomPosts(pageNum) {
        var pg = pageNum || 1;
        var xhrP = new XMLHttpRequest();
        xhrP.onreadystatechange = function() {
            if (xhrP.readyState !== XMLHttpRequest.DONE) return;
            var added = [];
            if (xhrP.status >= 200 && xhrP.status < 400 && xhrP.responseText) {
                try {
                    var posts = JSON.parse(xhrP.responseText);
                    if (Array.isArray(posts)) {
                        for (var i = 0; i < posts.length; i++) {
                            var p = posts[i];
                            if (!p || !p.title || !p.title.rendered) continue;
                            var t = cleanHtml(p.title.rendered);
                            var genre = "Switch ROM";
                            if (Array.isArray(p.categories)) {
                                for (var ci = 0; ci < p.categories.length; ci++) {
                                    var cn = switchsromCatMap[p.categories[ci]];
                                    if (cn && !/nintendo|switch|rom|uncategorized/i.test(cn)) {
                                        genre = cn;
                                        break;
                                    }
                                }
                            }
                            var imgM = p.content && p.content.rendered ? p.content.rendered.match(/<img[^>]+(?:data-src|src)=["']([^"']+)["']/i) : null;
                            added.push({
                                slug: "sr-" + (p.slug || (pg + "-" + i)),
                                title: t,
                                version: "Switch ROM",
                                portType: "switch",
                                sourceSite: "switchsrom",
                                category: genre,
                                dev: "SwitchsROM.com",
                                desc: (p.excerpt && p.excerpt.rendered) ? cleanHtml(p.excerpt.rendered) : (t + " ROM release on app.switchsrom.com."),
                                cover: imgM ? decodeEntities(imgM[1]) : "",
                                video: "",
                                pageUrl: String(p.link || "https://app.switchsrom.com/roms/")
                            });
                        }
                        mergeStoreGames(added);
                    }
                } catch (e2) {}
            }
            if (added.length < 20 || pg >= 15) hasMoreSwr = false;
        };
        xhrP.open("GET", "https://app.switchsrom.com/wp-json/wp/v2/posts?per_page=20&page=" + pg);
        xhrP.send();
    }

    function fetchLiveSwitchsRom(pageNum) {
        var pg = pageNum || 1;
        if (Object.keys(switchsromCatMap).length > 0) {
            fetchSwitchsRomPosts(pg);
            return;
        }
        var xhrC = new XMLHttpRequest();
        xhrC.onreadystatechange = function() {
            if (xhrC.readyState !== XMLHttpRequest.DONE) return;
            if (xhrC.status >= 200 && xhrC.status < 400 && xhrC.responseText) {
                try {
                    var cats = JSON.parse(xhrC.responseText);
                    if (Array.isArray(cats)) {
                        for (var c = 0; c < cats.length; c++) {
                            if (cats[c] && cats[c].id) switchsromCatMap[cats[c].id] = cleanHtml(cats[c].name || "");
                        }
                    }
                } catch (e) {}
            }
            fetchSwitchsRomPosts(pg);
        };
        xhrC.open("GET", "https://app.switchsrom.com/wp-json/wp/v2/categories?per_page=100");
        xhrC.send();
    }

    function inferRomGenre(title) {
        var s = String(title || "").toLowerCase();
        if (/zelda|tales|adventure|metroid|castlevania|okami/.test(s)) return "Adventure";
        if (/pokemon|final fantasy|dragon quest|chrono|fire emblem|golden sun|persona|kingdom hearts|earthbound|rpg/.test(s)) return "RPG";
        if (/mario kart|f-zero|gran turismo|need for speed|burnout|ridge racer|racing/.test(s)) return "Racing";
        if (/mario|sonic|kirby|donkey kong|yoshi|mega man|crash|spyro|banjo|rayman/.test(s)) return "Platformer";
        if (/tetris|puyo|professor layton|puzzle|brain/.test(s)) return "Puzzle";
        if (/tony hawk|fifa|nba|wii sports|golf|tennis|punch-out/.test(s)) return "Sports";
        if (/contra|star fox|doom|halo|metal slug|goldeneye|perfect dark/.test(s)) return "Shooter";
        return "Action";
    }

    function fetchVimmSectionHtml(sysCode, sysLabel, sectionCode, onDone) {
        var url = "https://vimm.net/vault/?p=list&system=" + encodeURIComponent(sysCode) + "&section=" + encodeURIComponent(sectionCode);
        var xhrV = new XMLHttpRequest();
        xhrV.onreadystatechange = function() {
            if (xhrV.readyState !== XMLHttpRequest.DONE) return;
            if (xhrV.status >= 200 && xhrV.status < 400 && xhrV.responseText) {
                var html = xhrV.responseText;
                var rowRe = /<a[^>]+href=["']\/vault\/(\d+)["'][^>]*>([^<]{2,110})<\/a>/gi;
                var m;
                var added = [];
                var seenV = {};
                while ((m = rowRe.exec(html)) !== null) {
                    var vid = m[1];
                    var title = cleanHtml(m[2]);
                    if (!vid || !title || seenV[vid]) continue;
                    seenV[vid] = true;
                    var genre = inferRomGenre(title);
                    added.push({
                        slug: "vimm-" + sysCode.toLowerCase() + "-" + vid,
                        title: title + " (" + sysLabel + ")",
                        version: sysLabel + " ROM",
                        portType: "rom",
                        sourceSite: "vimm",
                        category: sysLabel + " / " + genre,
                        dev: "Vimm's Lair Vault",
                        desc: sysLabel + " ROM on Vimm's Lair Vault (#" + vid + "). Click Download to open Vimm's game page.",
                        cover: "https://vimm.net/image.php?type=box&id=" + vid,
                        video: "",
                        pageUrl: "https://vimm.net/vault/" + vid
                    });
                }
                mergeStoreGames(added);
            }
            if (typeof onDone === "function") onDone();
        };
        xhrV.open("GET", url);
        xhrV.send();
    }

    function drainVimmQueue() {
        if (vimmQueueRunning || vimmPendingQueue.length === 0) return;
        vimmQueueRunning = true;
        var batch = vimmPendingQueue.splice(0, 3);
        var remaining = batch.length;
        for (var i = 0; i < batch.length; i++) {
            (function(job) {
                fetchVimmSectionHtml(job.code, job.label, job.sec, function() {
                    remaining--;
                    if (remaining <= 0) {
                        vimmQueueRunning = false;
                        drainVimmQueue();
                    }
                });
            })(batch[i]);
        }
    }

    function fetchLiveVimmBatch() {
        var systems = [
            { code: "GBA", label: "GBA" },
            { code: "DS", label: "DS" },
            { code: "N64", label: "N64" },
            { code: "SNES", label: "SNES" },
            { code: "GC", label: "GameCube" },
            { code: "PS2", label: "PS2" },
            { code: "PSP", label: "PSP" }
        ];
        var sections = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "number"];
        var targetSec = (activeLetter && activeLetter !== "All")
            ? (activeLetter === "#" ? "number" : activeLetter.toUpperCase())
            : sections[vimmSecCursor % sections.length];
        var queue = [];
        for (var k = 0; k < 2; k++) {
            var sys = systems[vimmSysCursor % systems.length];
            queue.push({ code: sys.code, label: sys.label, sec: targetSec });
            vimmSysCursor++;
            if (vimmSysCursor % systems.length === 0) vimmSecCursor++;
        }
        if (vimmSecCursor >= sections.length) hasMoreVimm = false;
        vimmPendingQueue = queue;
        drainVimmQueue();
    }

    function fetchLiveArchiveDir(dirUrl, sysLabel) {
        var xhrA = new XMLHttpRequest();
        xhrA.onreadystatechange = function() {
            if (xhrA.readyState !== XMLHttpRequest.DONE) return;
            if (xhrA.status >= 200 && xhrA.status < 400 && xhrA.responseText) {
                var html = xhrA.responseText;
                var linkRe = /<a[^>]+href=["']([^"'?#]+\.(?:rvz|iso|cso|chd|gcz|zip|7z))["'][^>]*>([\s\S]*?)<\/a>/gi;
                var m;
                var added = [];
                var seenA = {};
                while ((m = linkRe.exec(html)) !== null) {
                    var href = m[1];
                    if (href.indexOf("..") >= 0 || href.indexOf("/") === 0) continue;
                    var rawName = decodeURIComponent(href.replace(/\.[a-z0-9]{2,4}$/i, ""));
                    var title = rawName.replace(/_/g, " ").replace(/\s*\([^)]*\)/g, "").replace(/\s+/g, " ").trim();
                    if (!title || title.length < 2) continue;
                    var slug = "arch-" + sysLabel.toLowerCase() + "-" + title.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 48);
                    if (seenA[slug]) continue;
                    seenA[slug] = true;
                    var dlUrl = dirUrl + href;
                    added.push({
                        slug: slug,
                        title: title + " (" + sysLabel + ")",
                        version: "Archive " + sysLabel,
                        portType: "rom",
                        sourceSite: "archiveorg",
                        category: sysLabel + " / " + inferRomGenre(title),
                        dev: "Internet Archive",
                        desc: sysLabel + " ROM from Internet Archive Ultimate ROM Collection. Click Download for direct ROM link.",
                        cover: "",
                        video: "",
                        pageUrl: dlUrl
                    });
                }
                mergeStoreGames(added);
            }
        };
        xhrA.open("GET", dirUrl);
        xhrA.send();
    }

    function fetchLiveArchiveOrg() {
        if (archiveLoaded) return;
        archiveLoaded = true;
        fetchLiveArchiveDir("https://archive.org/download/ultimate-rom-collection/Game%20cube/", "GameCube");
        fetchLiveArchiveDir("https://archive.org/download/ultimate-rom-collection/PSP/", "PSP");
    }

    function fetchWikiDescription(gameTitle) {
        var cleanT = String(gameTitle || "").replace(/\s*\([^)]*\)\s*$/g, "").trim();
        if (!cleanT) return;
        var expected = gameTitle;
        var xhrW = new XMLHttpRequest();
        xhrW.onreadystatechange = function() {
            if (xhrW.readyState !== XMLHttpRequest.DONE) return;
            if (!detailOpen || detailGame.title !== expected) return;
            if (xhrW.status >= 200 && xhrW.status < 400 && xhrW.responseText) {
                try {
                    var d = JSON.parse(xhrW.responseText);
                    var hit = (d && d.query && d.query.search && d.query.search[0]) ? d.query.search[0].title : "";
                    if (hit !== "") {
                        var xhrS = new XMLHttpRequest();
                        xhrS.onreadystatechange = function() {
                            if (xhrS.readyState !== XMLHttpRequest.DONE) return;
                            if (!detailOpen || detailGame.title !== expected) return;
                            if (xhrS.status >= 200 && xhrS.status < 400 && xhrS.responseText) {
                                try {
                                    var sd = JSON.parse(xhrS.responseText);
                                    if (sd && sd.extract && String(sd.extract).length > 35) {
                                        detailDesc = String(sd.extract);
                                    }
                                } catch (e2) {}
                            }
                        };
                        xhrS.open("GET", "https://en.wikipedia.org/api/rest_v1/page/summary/" + encodeURIComponent(hit));
                        xhrS.send();
                    }
                } catch (e) {}
            }
        };
        xhrW.open("GET", "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=" + encodeURIComponent(cleanT + " video game") + "&srlimit=1&format=json");
        xhrW.send();
    }

    function searchYouTubeTrailer(gameTitle) {
        if (!gameTitle) return;
        var expectedTitle = gameTitle;
        var cleanTitle = String(gameTitle).replace(/\([^)]*\)/g, " ").replace(/\[[^\]]*\]/g, " ").replace(/[^A-Za-z0-9\s]/g, " ").toLowerCase().trim();
        var words = cleanTitle.split(/\s+/);
        var significant = [];
        for (var w = 0; w < words.length; w++) {
            if (words[w] && words[w].length >= 3 && words[w] !== "the" && words[w] !== "and") significant.push(words[w]);
        }
        var xhrY = new XMLHttpRequest();
        xhrY.onreadystatechange = function() {
            if (xhrY.readyState !== XMLHttpRequest.DONE) return;
            if (!detailOpen || detailGame.title !== expectedTitle) return;
            if (xhrY.status >= 200 && xhrY.status < 400 && xhrY.responseText) {
                var ym = xhrY.responseText.match(/"videoId":"([A-Za-z0-9_-]{11})"/);
                if (ym && ym[1]) {
                    var vidId = ym[1];
                    var xhrO = new XMLHttpRequest();
                    xhrO.onreadystatechange = function() {
                        if (xhrO.readyState !== XMLHttpRequest.DONE) return;
                        if (!detailOpen || detailGame.title !== expectedTitle) return;
                        if (xhrO.status >= 200 && xhrO.status < 400 && xhrO.responseText) {
                            try {
                                var oj = JSON.parse(xhrO.responseText);
                                var ytTitle = String((oj && oj.title) || "").toLowerCase();
                                var matched = (significant.length === 0);
                                for (var k = 0; k < significant.length; k++) {
                                    if (ytTitle.indexOf(significant[k]) >= 0) { matched = true; break; }
                                }
                                if (matched) {
                                    var embedUrl = "https://www.youtube.com/embed/" + vidId + "?autoplay=1&mute=0&controls=0&disablekb=1&fs=0&modestbranding=1&iv_load_policy=3&playsinline=1&rel=0";
                                    detailYoutubeEmbed = embedUrl;
                                    if (detailVideoUrl === "") detailVideoUrl = embedUrl;
                                    tryStartDetailWebVideo(embedUrl);
                                }
                            } catch (e2) {}
                        }
                    };
                    xhrO.open("GET", "https://www.youtube.com/oembed?url=" + encodeURIComponent("https://www.youtube.com/watch?v=" + vidId) + "&format=json");
                    xhrO.send();
                }
            }
        };
        xhrY.open("GET", "https://www.youtube.com/results?search_query=" + encodeURIComponent(gameTitle + " gameplay trailer"));
        xhrY.send();
    }

    function mountStoreYouTubeOrUrl(o, targetUrl) {
        var cleanUrl = String(targetUrl || "").replace("youtube-nocookie.com/embed/", "youtube.com/embed/");
        if (cleanUrl.indexOf("youtube.com/embed/") >= 0 && typeof o.loadHtml === "function") {
            var safeSrc = cleanUrl.replace(/"/g, "&quot;");
            o.loadHtml('<!doctype html><html><body style="margin:0;padding:0;background:#000;overflow:hidden;"><iframe style="position:fixed;inset:0;width:100vw;height:100vh;border:0;" src="' + safeSrc + '" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen" allowfullscreen></iframe></body></html>', "https://www.youtube.com/");
        } else {
            o.url = cleanUrl;
        }
    }

    function tryStartDetailWebVideo(embedUrl) {
        if (!embedUrl || detailWebObj) return;
        var previewUrl = String(embedUrl).indexOf("controls=0") >= 0
            ? String(embedUrl)
            : (String(embedUrl) + (String(embedUrl).indexOf("?") >= 0 ? "&" : "?") + "controls=0&disablekb=1&fs=0&modestbranding=1&iv_load_policy=3");
        var cands = [
            "import QtQuick 2.12; import QtWebView 1.1; WebView { x: 0; y: 0; width: parent.width; height: parent.height; enabled: false }",
            "import QtQuick 2.12; import QtWebView 1.0; WebView { x: 0; y: 0; width: parent.width; height: parent.height; enabled: false }",
            "import QtQuick 2.12; import QtWebView 1.15; WebView { x: 0; y: 0; width: parent.width; height: parent.height; enabled: false }",
            "import QtQuick 2.12; import QtWebEngine 1.8; WebEngineView { x: 0; y: 0; width: parent.width; height: parent.height; enabled: false }"
        ];
        for (var i = 0; i < cands.length; i++) {
            try {
                var o = Qt.createQmlObject(cands[i], videoInlineHost, "eshopYtWeb_" + i);
                if (o) {
                    detailWebObj = o;
                    mountStoreYouTubeOrUrl(o, previewUrl);
                    return;
                }
            } catch (e) {}
        }
    }

    function fetchLiveApkPortsBatch(pageNum) {
        var pg = pageNum || 1;
        isLoading = true;
        var xhrApi = new XMLHttpRequest();
        xhrApi.onreadystatechange = function() {
            if (xhrApi.readyState !== XMLHttpRequest.DONE) return;
            if (xhrApi.status >= 200 && xhrApi.status < 400 && xhrApi.responseText) {
                try {
                    var jsonList = JSON.parse(xhrApi.responseText);
                    var rawArr = Array.isArray(jsonList) ? jsonList : (jsonList && Array.isArray(jsonList.games) ? jsonList.games : []);
                    if (rawArr.length > 0) {
                        var mapped = [];
                        for (var i = 0; i < rawArr.length; i++) {
                            var row = rawArr[i];
                            if (!row || !row.slug) continue;
                            var img = String(row.thumbnailUrl || row.heroImageUrl || row.iconUrl || "");
                            if (img.indexOf("/") === 0) img = "https://www.apkports.com" + img;
                            mapped.push({
                                slug: String(row.slug),
                                title: String(row.title || row.slug),
                                version: String(row.version || "Latest"),
                                portType: String(row.portType || "unofficial"),
                                sourceSite: "apkports",
                                category: String(row.genre || row.category || "Action"),
                                dev: String(row.developer || "APKPorts.com"),
                                desc: String(row.shortDescription || row.description || (String(row.title || row.slug) + " on APKPorts.")),
                                cover: img,
                                video: String(row.trailerUrl || ""),
                                pageUrl: "https://www.apkports.com/game/" + encodeURIComponent(String(row.slug))
                            });
                        }
                        if (rawArr.length < 25 || pg >= 15) hasMoreApkp = false;
                        isLoading = false;
                        mergeStoreGames(mapped);
                        return;
                    } else {
                        hasMoreApkp = false;
                    }
                } catch (e) {}
            } else if (pg > 1) {
                hasMoreApkp = false;
            }
            if (pg === 1) {
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function() {
                    if (xhr.readyState !== XMLHttpRequest.DONE) return;
                    isLoading = false;
                    if (xhr.status >= 200 && xhr.status < 400 && xhr.responseText) {
                        var parsed = parseApkPortsHtml(xhr.responseText);
                        if (parsed.length > 0) {
                            mergeStoreGames(parsed);
                            return;
                        }
                    }
                    if (allGamesCache.length === 0) {
                        allGamesCache = fallbackCatalog.slice(0);
                        rebuildGrid();
                    }
                };
                xhr.open("GET", "https://www.apkports.com/games?sort=newest");
                xhr.send();
            } else {
                isLoading = false;
            }
        };
        xhrApi.open("GET", "https://www.apkports.com/api/games?limit=25&page=" + pg);
        xhrApi.send();
    }

    function fetchLiveApkPorts() {
        apkpApiPage = 1;
        nswApiPage = 1;
        swrApiPage = 1;
        vimmSysCursor = 0;
        vimmSecCursor = 0;
        hasMoreApkp = true;
        hasMoreNsw = true;
        hasMoreSwr = true;
        hasMoreVimm = true;
        archiveLoaded = false;
        fetchLiveApkPortsBatch(1);
        fetchLiveNswPedia(1);
        fetchLiveSwitchsRom(1);
        fetchLiveVimmBatch();
    }

    function fetchNextStoreBatch() {
        if (storeBatchBusy || !hasMoreSources()) return;
        storeBatchBusy = true;
        if (hasMoreApkp) { apkpApiPage += 1; fetchLiveApkPortsBatch(apkpApiPage); }
        if (hasMoreNsw) { nswApiPage += 1; fetchLiveNswPedia(nswApiPage); }
        if (hasMoreSwr) { swrApiPage += 1; fetchLiveSwitchsRom(swrApiPage); }
        if (hasMoreVimm) { fetchLiveVimmBatch(); }
        if (!archiveLoaded) { fetchLiveArchiveOrg(); }
        storeBatchBusy = false;
    }

    function stopInlineOnly() {
        if (detailWebObj) {
            try { detailWebObj.destroy(); } catch (e) {}
            detailWebObj = null;
        }
        if (videoPlayerObj) {
            try { videoPlayerObj.stop(); videoPlayerObj.destroy(); } catch (e) {}
            videoPlayerObj = null;
        }
    }

    function destroyDetailVideo() {
        stopInlineOnly();
        detailYoutubeEmbed = "";
        if (fullWebObj) {
            try { fullWebObj.destroy(); } catch (e) {}
            fullWebObj = null;
        }
        if (fullVideoPlayerObj) {
            try { fullVideoPlayerObj.stop(); fullVideoPlayerObj.destroy(); } catch (e) {}
            fullVideoPlayerObj = null;
        }
    }

    function tryStartDetailVideo(url) {
        destroyDetailVideo();
        if (!url) return;
        if (/\.(mp4|webm|m4v)(\?|$)/i.test(url)) {
            try {
                var qml = 'import QtQuick 2.12; import QtMultimedia 5.9; Video { anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop; autoPlay: true; loops: MediaPlayer.Infinite; muted: false; volume: 1.0; source: "' + url.replace(/"/g, "") + '" }';
                videoPlayerObj = Qt.createQmlObject(qml, videoInlineHost, "eshopInlineVideo");
            } catch (e) {
                videoPlayerObj = null;
            }
        } else if (url.indexOf("youtube") >= 0 || url.indexOf("youtu.be") >= 0) {
            var soundUrl = url.replace("mute=1", "mute=0");
            detailYoutubeEmbed = soundUrl;
            tryStartDetailWebVideo(soundUrl);
        }
    }

    function openFullscreenVideo() {
        var targetUrl = detailVideoUrl || detailYoutubeEmbed;
        if (!targetUrl) return;
        stopInlineOnly();
        fullscreenVideo = true;
        focusZone = "fullscreenVideo";
        selectSfx.play();
        if (fullWebObj) {
            try { fullWebObj.destroy(); } catch (e) {}
            fullWebObj = null;
        }
        if (fullVideoPlayerObj) {
            try { fullVideoPlayerObj.stop(); fullVideoPlayerObj.destroy(); } catch (e) {}
            fullVideoPlayerObj = null;
        }
        if (/\.(mp4|webm|m4v)(\?|$)/i.test(targetUrl)) {
            try {
                var qml = 'import QtQuick 2.12; import QtMultimedia 5.9; Video { anchors.fill: parent; fillMode: VideoOutput.PreserveAspectFit; autoPlay: true; loops: MediaPlayer.Infinite; muted: false; volume: 1.0; source: "' + targetUrl.replace(/"/g, "") + '" }';
                fullVideoPlayerObj = Qt.createQmlObject(qml, fullscreenVideoHost, "eshopFullVideo");
            } catch (e) {
                fullVideoPlayerObj = null;
            }
        } else {
            var fsUrl = targetUrl.replace("mute=1", "mute=0");
            var cands = [
                "import QtQuick 2.12; import QtWebView 1.1; WebView { x: 0; y: 0; width: parent.width; height: parent.height }",
                "import QtQuick 2.12; import QtWebView 1.0; WebView { x: 0; y: 0; width: parent.width; height: parent.height }",
                "import QtQuick 2.12; import QtWebView 1.15; WebView { x: 0; y: 0; width: parent.width; height: parent.height }",
                "import QtQuick 2.12; import QtWebEngine 1.8; WebEngineView { x: 0; y: 0; width: parent.width; height: parent.height }"
            ];
            for (var i = 0; i < cands.length; i++) {
                try {
                    var o = Qt.createQmlObject(cands[i], fullscreenVideoHost, "eshopFullYt_" + i);
                    if (o) { fullWebObj = o; mountStoreYouTubeOrUrl(o, fsUrl); break; }
                } catch (e) {}
            }
        }
    }

    function closeFullscreenVideo() {
        fullscreenVideo = false;
        focusZone = "detail";
        if (fullWebObj) {
            try { fullWebObj.destroy(); } catch (e) {}
            fullWebObj = null;
        }
        if (fullVideoPlayerObj) {
            try { fullVideoPlayerObj.stop(); fullVideoPlayerObj.destroy(); } catch (e) {}
            fullVideoPlayerObj = null;
        }
        if (detailVideoUrl !== "") {
            tryStartDetailVideo(detailVideoUrl);
        } else if (detailYoutubeEmbed !== "") {
            tryStartDetailWebVideo(detailYoutubeEmbed);
        }
        backSfx.play();
    }

    function fetchLiveGameDetail(slug) {
        if (!slug) return;
        detailFetching = true;
        var pageUrl = "https://www.apkports.com/game/" + encodeURIComponent(String(slug));
        detailDownloadUrl = pageUrl + "#download";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            detailFetching = false;
            if (xhr.status >= 200 && xhr.status < 400 && xhr.responseText) {
                var html = xhr.responseText;
                // Real description: check <meta name="description"> + meaningful <p> paragraphs
                var paras = [];
                var pRe = /<p\b[^>]*>([\s\S]*?)<\/p>/gi;
                var m;
                while ((m = pRe.exec(html)) !== null && paras.length < 4) {
                    var pt = cleanHtml(m[1]);
                    if (pt.length >= 40 && !/apkports|cookie|telegram|discord|privacy/i.test(pt)) {
                        paras.push(pt);
                    }
                }
                if (paras.length > 0) {
                    detailDesc = paras.join("\n\n");
                } else {
                    var md = html.match(/<meta[^>]+(?:name=["']description["']|property=["']og:description["'])[^>]+content=["']([^"']+)["']/i);
                    if (md && md[1]) detailDesc = cleanHtml(md[1]);
                }

                // Extract video if present
                var vidM = html.match(/<(?:video|source)[^>]+src=["']([^"']+\.(?:mp4|webm)[^"']*)["']/i);
                if (vidM && vidM[1]) {
                    detailVideoUrl = decodeEntities(vidM[1]);
                    if (detailVideoUrl.indexOf("/") === 0) detailVideoUrl = "https://www.apkports.com" + detailVideoUrl;
                    tryStartDetailVideo(detailVideoUrl);
                }

                // Extract direct download section or APK link if present
                var dlM = html.match(/<a[^>]+href=["']([^"']*(?:download|\.apk|mediafire|mega\.nz|drive\.google)[^"']*)["']/i);
                if (dlM && dlM[1]) {
                    var dl = decodeEntities(dlM[1].trim());
                    if (dl.indexOf("#") === 0) detailDownloadUrl = pageUrl + dl;
                    else if (dl.indexOf("/") === 0) detailDownloadUrl = "https://www.apkports.com" + dl;
                    else if (dl.indexOf("http") === 0) detailDownloadUrl = dl;
                }
            }
        };
        xhr.open("GET", pageUrl);
        xhr.send();
    }

    function openItemDetail(idx) {
        if (idx < 0 || idx >= pageGridModel.count) return;
        var g = pageGridModel.get(idx);
        var defaultUrl = g.pageUrl && g.pageUrl !== "" ? g.pageUrl
            : (g.sourceSite === "switchsrom" ? "https://app.switchsrom.com/roms/"
            : (g.sourceSite === "vimm" ? "https://vimm.net/vault/"
            : (g.sourceSite === "archiveorg" ? "https://archive.org/download/ultimate-rom-collection/"
            : (g.sourceSite === "nswpedia" ? "https://nswpedia.com/"
            : ("https://www.apkports.com/game/" + encodeURIComponent(String(g.slug || "")) + "#download")))));
        detailGame = {
            slug: g.slug, title: g.title, version: g.version, portType: g.portType,
            sourceSite: g.sourceSite || "apkports", pageUrl: defaultUrl,
            category: g.category, dev: g.dev, desc: g.desc, cover: g.cover, video: g.video
        };
        detailDesc = g.desc || "";
        detailDownloadUrl = defaultUrl;
        detailVideoUrl = g.video || "";
        detailOpen = true;
        fullscreenVideo = false;
        detailFocusBtn = 0;
        focusZone = "detail";
        selectSfx.play();
        if (detailVideoUrl !== "") { tryStartDetailVideo(detailVideoUrl); }
        else { searchYouTubeTrailer(g.title); }
        fetchWikiDescription(g.title);
        if (detailGame.sourceSite === "apkports") fetchLiveGameDetail(g.slug);
    }

    function openDownloadPage() {
        var u = detailDownloadUrl !== "" ? detailDownloadUrl : (detailGame.pageUrl || ("https://www.apkports.com/game/" + encodeURIComponent(String(detailGame.slug || "")) + "#download"));
        selectSfx.play();
        destroyDetailVideo();
        Qt.openUrlExternally(u);
    }

    function nextPage() {
        var tp = totalPages();
        if (currentPage + 1 < tp) {
            navSound.play();
            currentPage++;
            selectedIndex = 0;
            rebuildPageSlice();
            if (currentPage + 1 >= tp - 1 && hasMoreSources()) fetchNextStoreBatch();
        } else if (hasMoreSources()) {
            navSound.play();
            fetchNextStoreBatch();
        }
    }
    function prevPage() {
        if (currentPage > 0) { navSound.play(); currentPage--; selectedIndex = 0; rebuildPageSlice(); }
    }

    Component.onCompleted: {
        allGamesCache = fallbackCatalog.slice(0);
        rebuildGrid();
    }

    onVisibleChanged: {
        if (visible) {
            detailOpen = false;
            fullscreenVideo = false;
            destroyDetailVideo();
            focusZone = "grid";
            if (allGamesCache.length <= fallbackCatalog.length) fetchLiveApkPorts();
            storeRoot.forceActiveFocus();
        } else {
            destroyDetailVideo();
        }
    }

    Keys.onLeftPressed: {
        if (fullscreenVideo) return;
        if (detailOpen) {
            navSound.play();
            detailFocusBtn = (detailFocusBtn + 2) % 3;
            if (detailFocusBtn === 2 && detailVideoUrl === "") detailFocusBtn = 1;
            return;
        }
        navSound.play();
        if (focusZone === "grid") {
            if (selectedIndex % 3 === 0) {
                if (currentPage > 0) {
                    var targetRow = Math.floor(selectedIndex / 3);
                    prevPage();
                    selectedIndex = Math.max(0, Math.min(pageGridModel.count - 1, targetRow * 3 + 2));
                } else {
                    focusZone = "sidebar";
                }
            } else {
                selectedIndex = Math.max(0, selectedIndex - 1);
            }
        }
    }

    Keys.onRightPressed: {
        if (fullscreenVideo) return;
        if (detailOpen) {
            navSound.play();
            detailFocusBtn = (detailFocusBtn + 1) % 3;
            if (detailFocusBtn === 2 && detailVideoUrl === "") detailFocusBtn = 0;
            return;
        }
        navSound.play();
        if (focusZone === "sidebar") {
            activateSidebarEntry(sidebarFocusIdx);
            focusZone = "grid";
        } else if (pageGridModel.count > 0) {
            if (selectedIndex % 3 === 2 && (currentPage + 1 < totalPages() || hasMoreSources())) {
                var rRow = Math.floor(selectedIndex / 3);
                nextPage();
                selectedIndex = Math.max(0, Math.min(pageGridModel.count - 1, rRow * 3));
            } else {
                selectedIndex = Math.min(pageGridModel.count - 1, selectedIndex + 1);
            }
        }
    }

    Keys.onUpPressed: {
        if (fullscreenVideo) return;
        if (detailOpen) {
            if (detailVideoUrl !== "") { navSound.play(); detailFocusBtn = 2; }
            return;
        }
        navSound.play();
        if (focusZone === "sidebar") {
            moveSidebar(-1);
        } else if (selectedIndex >= 3) {
            selectedIndex -= 3;
        }
    }

    Keys.onDownPressed: {
        if (fullscreenVideo) return;
        if (detailOpen) {
            if (detailFocusBtn === 2) { navSound.play(); detailFocusBtn = 0; }
            return;
        }
        navSound.play();
        if (focusZone === "sidebar") {
            moveSidebar(1);
        } else if (pageGridModel.count > 0) {
            selectedIndex = Math.min(pageGridModel.count - 1, selectedIndex + 3);
        }
    }

    Keys.onBackPressed: {
        event.accepted = true;
        fullscreenVideo = false;
        detailOpen = false;
        destroyDetailVideo();
        focusZone = "grid";
        backSfx.play();
        showHomeScreen();
    }
    Keys.onEscapePressed: {
        event.accepted = true;
        if (fullscreenVideo) closeFullscreenVideo();
        else if (detailOpen) { detailOpen = false; destroyDetailVideo(); focusZone = "grid"; backSfx.play(); }
        else if (focusZone === "sidebar") { focusZone = "grid"; backSfx.play(); }
        else { backSfx.play(); showHomeScreen(); }
    }
    Keys.onReleased: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function")
            root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
    }

    Keys.onPressed: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
        var isB = api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace;
        if (fullscreenVideo) {
            if ((isB || api.keys.isAccept(event)) && !event.isAutoRepeat) {
                event.accepted = true;
                closeFullscreenVideo();
            }
            return;
        }
        if (detailOpen) {
            if (isB && !event.isAutoRepeat) {
                event.accepted = true;
                detailOpen = false;
                destroyDetailVideo();
                focusZone = "grid";
                backSfx.play();
            } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (detailFocusBtn === 2 && detailVideoUrl !== "") openFullscreenVideo();
                else if (detailFocusBtn === 1) toggleWishlist(detailGame.slug);
                else openDownloadPage();
            } else if (api.keys.isDetails(event) && !event.isAutoRepeat) {
                event.accepted = true;
                toggleWishlist(detailGame.slug);
            }
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (focusZone === "sidebar") {
                activateSidebarEntry(sidebarFocusIdx);
            } else {
                openItemDetail(selectedIndex);
            }
        } else if (isB && !event.isAutoRepeat) {
            event.accepted = true;
            if (focusZone === "sidebar") {
                focusZone = "grid";
                backSfx.play();
            } else {
                backSfx.play();
                showHomeScreen();
            }
        } else if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (selectedIndex >= 0 && selectedIndex < pageGridModel.count) {
                toggleWishlist(pageGridModel.get(selectedIndex).slug);
            }
        } else if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            stepAlphabetLetter(1);
        } else if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            stepAlphabetLetter(-1);
        }
    }

    Rectangle { anchors.fill: parent; color: storeRoot.pageBg }

    // Top Nintendo eShop Header
    Item {
        id: storeHeader
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Math.round(screenheight * 0.115)

        Rectangle { anchors.fill: parent; color: storeRoot.eshopRed }

        Row {
            anchors { left: parent.left; leftMargin: screenmargin; verticalCenter: parent.verticalCenter }
            spacing: vpx(14)
            Item {
                width: vpx(32); height: vpx(32); anchors.verticalCenter: parent.verticalCenter
                Image { id: eshopBagLogo; anchors.fill: parent; source: "../assets/images/navigation/ns2_eshop.svg"; fillMode: Image.PreserveAspectFit; smooth: true; visible: false }
                ColorOverlay { anchors.fill: eshopBagLogo; source: eshopBagLogo; color: "#111111"; antialiasing: true }
            }
            Text { text: tr("Nintendo eShop"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.038); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: storeRoot.selectedCategory !== "" ? ("· " + storeRoot.selectedCategory) : (storeRoot.activeSection === "wishlist" ? "· ★ Wish List" : "")
                color: "#FEE2E2"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.025); font.bold: true; anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Item {
        anchors { top: storeHeader.bottom; bottom: storeFooter.top; left: parent.left; right: parent.right }

        // Left Controller-Navigable Sidebar with Bigger Fonts
        Rectangle {
            id: eshopSidebar
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            width: Math.round(parent.width * 0.24)
            color: storeRoot.sidebarBg
            border.width: 0

            ListView {
                id: sidebarList
                anchors { fill: parent; margins: vpx(14) }
                clip: true
                spacing: vpx(4)
                model: storeRoot.sidebarEntries
                currentIndex: storeRoot.sidebarFocusIdx

                delegate: Item {
                    width: sidebarList.width
                    height: modelData.kind === "header" ? vpx(40) : vpx(50)
                    property bool isActiveItem: (modelData.kind === "genre" && storeRoot.activeSection === "genres" && storeRoot.selectedCategory === modelData.cat)
                                             || (modelData.kind === "sort" && storeRoot.activeSection === "az")
                                             || (modelData.kind === "section" && storeRoot.activeSection === modelData.id)
                    property bool isKbFocused: storeRoot.focusZone === "sidebar" && index === storeRoot.sidebarFocusIdx

                    Rectangle {
                        visible: modelData.kind !== "header"
                        anchors.fill: parent
                        radius: vpx(8)
                        color: isActiveItem ? storeRoot.eshopRed : (isKbFocused ? storeRoot.cardBg : "transparent")
                        border.width: isKbFocused ? vpx(3) : 0
                        border.color: storeRoot.eshopRed
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: modelData.kind === "genre" ? vpx(24) : vpx(12)
                            verticalCenter: parent.verticalCenter
                        }
                        text: modelData.id === "wishlist" ? ("★ " + modelData.label) : modelData.label
                        color: modelData.kind === "header" ? storeRoot.eshopRed
                             : (isActiveItem ? "#FFFFFF" : storeRoot.textMain)
                        font.family: titleFont.name
                        font.pixelSize: modelData.kind === "genre" ? Math.round(screenheight * 0.027 * fontScale) : Math.round(screenheight * 0.031 * fontScale)
                        font.bold: isActiveItem || modelData.kind === "header" || isKbFocused
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: modelData.kind !== "header"
                        onClicked: {
                            storeRoot.focusZone = "sidebar";
                            storeRoot.activateSidebarEntry(index);
                        }
                    }
                }
            }
        }

        // Right Section: Unified Games Grid + A-Z Bottom Alphabet Bar OR Full In-Section Detail Page (No Floating Modal)
        Item {
            id: eshopRightSection
            anchors { top: parent.top; bottom: parent.bottom; left: eshopSidebar.right; right: parent.right }

            Item {
                visible: !storeRoot.detailOpen
                anchors { fill: parent; margins: vpx(20) }

                Text {
                    visible: pageGridModel.count === 0
                    anchors.centerIn: eshopGrid
                    text: storeRoot.activeSection === "wishlist" ? tr("Your Wish List is empty. Press Y / ☆ to add titles.") : tr("No Nintendo eShop titles matched.")
                    color: storeRoot.textMuted
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.025)
                }

                GridView {
                    id: eshopGrid
                    anchors { top: parent.top; left: parent.left; right: parent.right; bottom: azBar.top; bottomMargin: vpx(10) }
                    clip: true
                    cellWidth: Math.floor(width / 3)
                    cellHeight: Math.floor(height / 2)
                    model: pageGridModel

                    delegate: Item {
                        width: eshopGrid.cellWidth
                        height: eshopGrid.cellHeight
                        property bool selected: storeRoot.focusZone === "grid" && index === storeRoot.selectedIndex
                        property bool wish: storeRoot.isWishlisted(model.slug)

                        Rectangle {
                            anchors { fill: parent; margins: vpx(8) }
                            radius: vpx(12)
                            color: storeRoot.cardBg
                            clip: true

                            // Clipped Artwork Container (z: 5)
                            Item {
                                id: artFrame
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: Math.round(parent.height * 0.56)
                                z: 5
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: model.cover
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }

                                Rectangle {
                                    anchors { top: parent.top; left: parent.left; topMargin: vpx(8); leftMargin: vpx(8) }
                                    height: vpx(24); width: srcBadgeLbl.implicitWidth + vpx(16); radius: vpx(6)
                                    color: model.sourceSite === "switchsrom" ? "#7C3AED"
                                         : (model.sourceSite === "vimm" ? "#0D9488"
                                         : (model.sourceSite === "archiveorg" ? "#D97706"
                                         : ((model.sourceSite === "nswpedia" || model.portType === "switch") ? "#E60012" : "#2563EB")))
                                    Text {
                                        id: srcBadgeLbl
                                        anchors.centerIn: parent
                                        text: model.sourceSite === "switchsrom" ? "SWITCHROM"
                                            : (model.sourceSite === "vimm" ? "VIMM VAULT"
                                            : (model.sourceSite === "archiveorg" ? "ARCHIVE"
                                            : ((model.sourceSite === "nswpedia" || model.portType === "switch") ? "NS SWITCH" : "PORT")))
                                        color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true
                                    }
                                }

                                Rectangle {
                                    visible: wish
                                    anchors { top: parent.top; right: parent.right; topMargin: vpx(8); rightMargin: vpx(8) }
                                    width: vpx(30); height: vpx(30); radius: vpx(15)
                                    color: "#E60012"
                                    Text { anchors.centerIn: parent; text: "★"; color: "#FDE047"; font.pixelSize: vpx(16) }
                                }
                            }

                            // Metadata Text Area (z: 10)
                            Column {
                                anchors { top: artFrame.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; margins: vpx(10) }
                                spacing: vpx(4)
                                z: 10
                                Text {
                                    width: parent.width; text: model.title; color: storeRoot.textMain
                                    font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width; text: model.category + " · " + model.version
                                    color: storeRoot.eshopRed; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.018); font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width; text: model.desc
                                    color: storeRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.017)
                                    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                                }
                            }

                            // RED SELECTION BORDER RENDERED IN FRONT OF ARTWORK (z: 25)
                            Rectangle {
                                anchors.fill: parent
                                radius: vpx(12)
                                color: "transparent"
                                border.width: selected ? vpx(5) : 1
                                border.color: selected ? storeRoot.eshopRed : storeRoot.dividerColor
                                z: 25
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    storeRoot.focusZone = "grid";
                                    storeRoot.selectedIndex = index;
                                    storeRoot.openItemDetail(index);
                                }
                            }
                        }
                    }
                }

                // Bottom A-Z Alphabet Filter Bar (LB / RB across all unified sources)
                Rectangle {
                    id: azBar
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: vpx(42)
                    radius: vpx(10)
                    color: storeRoot.sidebarBg
                    border.width: 1
                    border.color: storeRoot.dividerColor

                    Row {
                        anchors { fill: parent; leftMargin: vpx(8); rightMargin: vpx(8) }
                        spacing: vpx(3)

                        Text {
                            text: "LB"
                            color: storeRoot.eshopRed
                            font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Flickable {
                            width: parent.width - vpx(54)
                            height: parent.height
                            contentWidth: azRow.implicitWidth
                            clip: true
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                id: azRow
                                height: parent.height
                                spacing: vpx(4)
                                Repeater {
                                    model: storeRoot.alphabetLetters
                                    delegate: Rectangle {
                                        property bool cur: storeRoot.activeLetter === modelData
                                        width: modelData === "All" ? vpx(36) : vpx(26)
                                        height: vpx(28)
                                        radius: vpx(6)
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: cur ? storeRoot.eshopRed : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: cur ? "#FFFFFF" : storeRoot.textMain
                                            font.family: titleFont.name; font.pixelSize: vpx(13); font.bold: true
                                        }
                                        MouseArea { anchors.fill: parent; onClicked: storeRoot.selectAlphabetLetter(modelData) }
                                    }
                                }
                            }
                        }

                        Text {
                            text: "RB"
                            color: storeRoot.eshopRed
                            font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // IN-SECTION FULL GAME DETAIL PAGE (No Floating Modal Card)
            Rectangle {
                visible: storeRoot.detailOpen
                anchors.fill: parent
                color: storeRoot.pageBg
                z: 40

                RowLayout {
                    anchors { fill: parent; margins: vpx(24) }
                    spacing: vpx(24)

                    // Left: Control-free Preview Window (Click / Press A for Fullscreen)
                    Rectangle {
                        Layout.preferredWidth: Math.round(parent.width * 0.46)
                        Layout.fillHeight: true
                        radius: vpx(14)
                        color: "#090A0D"
                        clip: true
                        border.width: storeRoot.detailFocusBtn === 2 ? vpx(4) : 1
                        border.color: storeRoot.detailFocusBtn === 2 ? storeRoot.eshopRed : storeRoot.dividerColor

                        Image {
                            anchors.fill: parent
                            source: storeRoot.detailGame.cover || ""
                            fillMode: Image.PreserveAspectCrop
                        }

                        Item {
                            id: videoInlineHost
                            anchors.fill: parent
                            visible: storeRoot.detailVideoUrl !== ""
                            enabled: false
                        }

                        Rectangle {
                            visible: storeRoot.detailVideoUrl !== ""
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: vpx(38)
                            color: "#AA000000"
                            Row {
                                anchors.centerIn: parent; spacing: vpx(8)
                                Text { text: "▶"; color: "#FFFFFF"; font.pixelSize: vpx(15) }
                                Text {
                                    text: storeRoot.detailFocusBtn === 2 ? tr("Press A / Click for Fullscreen") : tr("Preview · Tap for Fullscreen")
                                    color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: storeRoot.detailVideoUrl !== ""
                            onClicked: storeRoot.openFullscreenVideo()
                        }
                    }

                    // Right: Title, Wikipedia Description, Download & Star Wish List
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: vpx(12)

                        Text {
                            Layout.fillWidth: true
                            text: storeRoot.detailGame.title || ""
                            color: storeRoot.textMain
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.036)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: (storeRoot.detailGame.category || "Action") + " · " + (storeRoot.detailGame.version || "1.0") + " · " + (storeRoot.detailGame.dev || "eShop")
                            color: storeRoot.eshopRed
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.022)
                            font.bold: true
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: detailDescText.implicitHeight + vpx(12)
                            clip: true

                            Text {
                                id: detailDescText
                                width: parent.width
                                text: storeRoot.detailDesc || storeRoot.detailGame.desc || ""
                                color: storeRoot.textMain
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.024)
                                wrapMode: Text.WordWrap
                                lineHeight: 1.4
                            }
                        }

                        Row {
                            Layout.fillWidth: true
                            spacing: vpx(12)

                            Rectangle {
                                width: vpx(180); height: vpx(48); radius: vpx(12)
                                color: storeRoot.eshopRed
                                border.width: storeRoot.detailFocusBtn === 0 ? vpx(3) : 0
                                border.color: "#FFFFFF"
                                Text {
                                    anchors.centerIn: parent
                                    text: tr("Download")
                                    color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.025); font.bold: true
                                }
                                MouseArea { anchors.fill: parent; onClicked: storeRoot.openDownloadPage() }
                            }

                            Rectangle {
                                width: vpx(210); height: vpx(48); radius: vpx(12)
                                color: storeRoot.isWishlisted(storeRoot.detailGame.slug) ? storeRoot.eshopRed : storeRoot.sidebarBg
                                border.width: storeRoot.detailFocusBtn === 1 ? vpx(3) : 1
                                border.color: storeRoot.detailFocusBtn === 1 ? storeRoot.eshopRed : storeRoot.dividerColor
                                Text {
                                    anchors.centerIn: parent
                                    text: storeRoot.isWishlisted(storeRoot.detailGame.slug) ? tr("★ Wishlisted") : tr("☆ Add to Wish List")
                                    color: storeRoot.isWishlisted(storeRoot.detailGame.slug) ? "#FFFFFF" : storeRoot.textMain
                                    font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); font.bold: true
                                }
                                MouseArea { anchors.fill: parent; onClicked: storeRoot.toggleWishlist(storeRoot.detailGame.slug) }
                            }

                            Rectangle {
                                width: vpx(110); height: vpx(48); radius: vpx(12)
                                color: storeRoot.sidebarBg
                                border.width: 1; border.color: storeRoot.dividerColor
                                Text { anchors.centerIn: parent; text: tr("B · Back"); color: storeRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.021); font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: { storeRoot.detailOpen = false; storeRoot.destroyDetailVideo(); storeRoot.focusZone = "grid"; backSfx.play(); } }
                            }
                        }
                    }
                }
            }
        }
    }

    // Bottom Nintendo eShop Footer
    Item {
        id: storeFooter
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.088)
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: storeRoot.dividerColor }
        Image { anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(16)
            Row {
                spacing: vpx(6); anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: vpx(28); height: vpx(26); radius: vpx(6); color: storeRoot.sidebarBg; border.width: 1; border.color: storeRoot.dividerColor
                    Text { anchors.centerIn: parent; text: "<"; color: storeRoot.textMain; font.pixelSize: vpx(13); font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: storeRoot.prevPage() }
                }
                Text { text: "Page " + (storeRoot.currentPage + 1) + "/" + storeRoot.totalPages() + (storeRoot.hasMoreSources() ? "+" : "") + " · Letter " + storeRoot.activeLetter + " (LB/RB)"; color: storeRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.019); anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    width: vpx(28); height: vpx(26); radius: vpx(6); color: storeRoot.sidebarBg; border.width: 1; border.color: storeRoot.dividerColor
                    Text { anchors.centerIn: parent; text: ">"; color: storeRoot.textMain; font.pixelSize: vpx(13); font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: storeRoot.nextPage() }
                }
            }
            Row { spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: storeRoot.eshopRed; Text { anchors.centerIn: parent; text: "Y"; color: "#FFFFFF"; font.pixelSize: vpx(13); font.bold: true } }
                Text { text: tr("★ Wish List"); color: storeRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.021) }
            }
            Row { spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: storeRoot.textMain; Text { anchors.centerIn: parent; text: "A"; color: storeRoot.pageBg; font.pixelSize: vpx(13); font.bold: true } }
                Text { text: tr("Details"); color: storeRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.021) }
            }
            Row { spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: storeRoot.textMain; Text { anchors.centerIn: parent; text: "B"; color: storeRoot.pageBg; font.pixelSize: vpx(13); font.bold: true } }
                Text { text: tr("Back"); color: storeRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.021) }
                MouseArea { anchors.fill: parent; onClicked: { backSfx.play(); showHomeScreen(); } }
            }
        }
    }

    // FULLSCREEN VIDEO PLAYER OVERLAY
    Rectangle {
        visible: storeRoot.fullscreenVideo
        anchors.fill: parent
        color: "#000000"
        z: 120

        Image {
            anchors.fill: parent
            source: storeRoot.detailGame.cover || ""
            fillMode: Image.PreserveAspectFit
            opacity: 0.4
        }

        Item {
            id: fullscreenVideoHost
            anchors.fill: parent
        }

        Rectangle {
            anchors { top: parent.top; right: parent.right; margins: vpx(24) }
            width: vpx(190); height: vpx(44); radius: vpx(22)
            color: "#CC000000"; border.width: 2; border.color: "#FFFFFF"
            Text { anchors.centerIn: parent; text: tr("B · Exit Fullscreen"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(15); font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: storeRoot.closeFullscreenVideo() }
        }
    }
}
