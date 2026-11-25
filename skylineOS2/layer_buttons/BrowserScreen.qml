// skylineOS 2 — BrowserScreen.qml (Netflix Streaming Hub: LaMovie Movies & Series + YouTube, A-Z Bar, 20/Page Lazy Loading, Preview Pause/Play, Real Stream Fullscreen)
import QtQuick 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

FocusScope {
    id: browserRoot
    anchors.fill: parent

    property string homeUrl: "https://lamovie.org"
    property string currentUrl: homeUrl
    property string pageTitle: "Netflix"
    property string searchQuery: ""
    property string inputUrl: searchQuery !== "" ? searchQuery : currentUrl
    property bool isLoading: false
    property bool editingUrl: false
    property string activeTab: "forme" // "forme" | "favorites" | "movies" | "series" | "youtube" | "genre" | "external"
    property string selectedGenre: ""
    property int sidebarFocusIdx: 0
    property int gridIndex: 0
    property string focusZone: "grid" // "sidebar" | "grid" | "detail" | "fullscreenVideo"

    // A-Z Alphabet + 20/page Lazy Pagination
    property var alphabetLetters: ["All", "#", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    property string activeLetter: "All"
    property int itemsPerPage: 20
    property int currentPage: 0
    property int moviesApiPage: 1
    property int seriesApiPage: 1
    property bool hasMoreMovies: true
    property bool hasMoreSeries: true
    property bool feedBusy: false

    // Detail + Preview Pause/Play + Real Fullscreen Stream
    property bool detailOpen: false
    property var detailItem: ({})
    property string detailSynopsis: ""
    property string detailPreviewUrl: ""
    property string detailPlayUrl: ""
    property string detailBackdrop: ""
    property bool previewPaused: false
    property bool streamsLoading: false
    property bool fullscreenPending: false
    property bool fullscreenVideo: false
    property int detailBtnIdx: 1 // 0=Preview Pause/Play, 1=Play Fullscreen, 2=Favorite, 3=Open External

    property var inlineWebView: null
    property var fullWebView: null
    property var nativeWebView: null
    property bool usingNativeWebView: false

    property var savedFavorites: []
    property var allStreamItems: []
    ListModel { id: filteredStreamModel }
    ListModel { id: pageStreamModel }
    ListModel { id: episodesModel }
    ListModel { id: playerSourcesModel }
    property int selectedEpisodeIdx: 0
    property int selectedPlayerIdx: 0

    property var sidebarItems: [
        { id: "forme",     label: "For Me",      kind: "tab", genre: "" },
        { id: "favorites", label: "★ Favorites", kind: "tab", genre: "" },
        { id: "movies",    label: "Movies",      kind: "tab", genre: "" },
        { id: "series",    label: "Series",      kind: "tab", genre: "" },
        { id: "youtube",   label: "YouTube",     kind: "tab", genre: "" },
        { id: "hdr_cat",   label: "Categories",  kind: "header", genre: "" },
        { id: "g_action",  label: "Action",      kind: "genre", genre: "Action" },
        { id: "g_anime",   label: "Anime",       kind: "genre", genre: "Anime" },
        { id: "g_comedy",  label: "Comedy",      kind: "genre", genre: "Comedy" },
        { id: "g_drama",   label: "Drama",       kind: "genre", genre: "Drama" },
        { id: "g_scifi",   label: "Sci-Fi",      kind: "genre", genre: "Sci-Fi" },
        { id: "g_horror",  label: "Horror",      kind: "genre", genre: "Horror" },
        { id: "g_gaming",  label: "Gaming",      kind: "genre", genre: "Gaming" }
    ]

    property var fallbackCatalog: [
        { id: "yt-nintendo-direct", slug: "yt-nintendo-direct", mediaType: "youtube", source: "YouTube", title: "Nintendo Switch 2 Official First Look", year: "2026", rating: "4K", genre: "Gaming", thumb: "https://i.ytimg.com/vi/itpcsQQvgAQ/hqdefault.jpg", backdrop: "https://i.ytimg.com/vi/itpcsQQvgAQ/hqdefault.jpg", overview: "Official Nintendo Switch 2 reveal presentation showcasing next-gen handheld dock performance and new flagship adventures.", trailerId: "itpcsQQvgAQ", pageUrl: "https://www.youtube.com/watch?v=itpcsQQvgAQ" },
        { id: "yt-mario-kart-world", slug: "yt-mario-kart-world", mediaType: "youtube", source: "YouTube", title: "Mario Kart World — Gameplay Trailer", year: "2026", rating: "HD", genre: "Gaming", thumb: "https://i.ytimg.com/vi/3pE23YTYEZM/hqdefault.jpg", backdrop: "https://i.ytimg.com/vi/3pE23YTYEZM/hqdefault.jpg", overview: "Extended race showcase featuring dynamic weather tracks and open-route grand prix circuits.", trailerId: "3pE23YTYEZM", pageUrl: "https://www.youtube.com/watch?v=3pE23YTYEZM" },
        { id: "lm-dune-prophecy", slug: "lm-dune-prophecy", mediaType: "series", source: "LaMovie", title: "Dune: Prophecy", year: "2025", rating: "8.4", genre: "Sci-Fi / Drama", thumb: "https://images.tmdb.org/t/p/w500/bS9G4Q9zA96vG3nQ65h8d9l5E8c.jpg", backdrop: "https://images.tmdb.org/t/p/w780/bS9G4Q9zA96vG3nQ65h8d9l5E8c.jpg", overview: "Set 10,000 years before the ascension of Paul Atreides, following two Harkonnen sisters as they establish the fabled Bene Gesserit sect.", trailerId: "EE6T_cO4aP8", pageUrl: "https://lamovie.org" },
        { id: "lm-arcane-s2", slug: "lm-arcane-s2", mediaType: "series", source: "LaMovie", title: "Arcane", year: "2024", rating: "9.0", genre: "Anime / Action", thumb: "https://i.ytimg.com/vi/ysqiEC6bLUI/hqdefault.jpg", backdrop: "https://i.ytimg.com/vi/ysqiEC6bLUI/hqdefault.jpg", overview: "Amidst the escalating conflict between utopian Piltover and the oppressed underground of Zaun, two sisters fight on rival sides.", trailerId: "ysqiEC6bLUI", pageUrl: "https://lamovie.org" },
        { id: "lm-spiderverse", slug: "lm-spiderverse", mediaType: "movie", source: "LaMovie", title: "Spider-Man: Across the Spider-Verse", year: "2023", rating: "8.6", genre: "Action / Anime", thumb: "https://i.ytimg.com/vi/cqGjhVJWtEg/hqdefault.jpg", backdrop: "https://i.ytimg.com/vi/cqGjhVJWtEg/hqdefault.jpg", overview: "Miles Morales catapults across the Multiverse, encountering a team of Spider-People charged with protecting its very existence.", trailerId: "cqGjhVJWtEg", pageUrl: "https://lamovie.org" },
        { id: "lm-mario-movie", slug: "lm-mario-movie", mediaType: "movie", source: "LaMovie", title: "The Super Mario Bros. Movie", year: "2023", rating: "7.8", genre: "Comedy / Adventure", thumb: "https://i.ytimg.com/vi/TnGl01FkMMo/hqdefault.jpg", backdrop: "https://i.ytimg.com/vi/TnGl01FkMMo/hqdefault.jpg", overview: "A plumber named Mario travels through an underground labyrinth with his brother Luigi, trying to save a captured princess.", trailerId: "TnGl01FkMMo", pageUrl: "https://lamovie.org" }
    ]

    function decodeEntities(str) {
        return String(str || "")
            .replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"").replace(/&#39;|&apos;/g, "'").replace(/&nbsp;/g, " ");
    }

    function loadSavedFavorites() {
        var raw = api.memory.has("BROWSER_FAVORITES") ? String(api.memory.get("BROWSER_FAVORITES")) : "[]";
        var arr = [];
        try {
            var parsed = JSON.parse(raw);
            if (Array.isArray(parsed)) arr = parsed;
        } catch (e) { arr = []; }
        savedFavorites = arr;
    }

    function isFavoriteItem(slugOrUrl) {
        for (var i = 0; i < savedFavorites.length; i++) {
            var it = savedFavorites[i];
            if (it && (it.slug === slugOrUrl || it.url === slugOrUrl)) return true;
        }
        return false;
    }

    function toggleFavorite() {
        var target = detailOpen ? detailItem : (pageStreamModel.count > 0 && gridIndex < pageStreamModel.count ? pageStreamModel.get(gridIndex) : null);
        if (!target) return;
        var key = String(target.slug || target.pageUrl || target.title || "");
        if (key === "") return;
        var next = [];
        var found = false;
        for (var i = 0; i < savedFavorites.length; i++) {
            var f = savedFavorites[i];
            if (!f) continue;
            if (f.slug === key || f.url === key) { found = true; }
            else { next.push(f); }
        }
        if (!found) {
            next.unshift({
                id: String(target.id || ""),
                slug: String(target.slug || key),
                url: String(target.pageUrl || key),
                label: String(target.title || key),
                title: String(target.title || key),
                mediaType: String(target.mediaType || "movie"),
                source: String(target.source || "LaMovie"),
                year: String(target.year || ""),
                rating: String(target.rating || ""),
                genre: String(target.genre || ""),
                thumb: String(target.thumb || ""),
                backdrop: String(target.backdrop || target.thumb || ""),
                overview: String(target.overview || ""),
                trailerId: String(target.trailerId || "")
            });
            turnOnSfx.play();
        } else {
            turnOffSfx.play();
        }
        savedFavorites = next;
        api.memory.set("BROWSER_FAVORITES", JSON.stringify(next));
        if (activeTab === "favorites") rebuildFilteredStream();
    }

    function normalizeTmdbImage(rawPath, wide) {
        var p = String(rawPath || "").trim();
        if (p === "") return "";
        if (p.indexOf("http://") === 0 || p.indexOf("https://") === 0) return p;
        if (p.indexOf("/") === 0) return "https://image.tmdb.org/t/p/" + (wide ? "w780" : "w500") + p;
        return "https://image.tmdb.org/t/p/" + (wide ? "w780" : "w500") + "/" + p;
    }

    function parseLaMovieList(jsonText, mediaType) {
        var out = [];
        try {
            var parsed = JSON.parse(jsonText);
            var posts = (parsed && parsed.data && Array.isArray(parsed.data.posts)) ? parsed.data.posts
                      : (parsed && Array.isArray(parsed.posts) ? parsed.posts
                      : (Array.isArray(parsed) ? parsed : []));
            for (var i = 0; i < posts.length; i++) {
                var p = posts[i];
                if (!p) continue;
                var pid = String(p._id || p.id || p.slug || i);
                var title = decodeEntities(p.title || p.name || "");
                if (title === "") continue;
                var imgs = p.images || {};
                var poster = normalizeTmdbImage(imgs.poster || p.poster || p.image || "", false);
                var back = normalizeTmdbImage(imgs.backdrop || p.backdrop || imgs.poster || p.poster || "", true);
                var yr = p.release_date ? String(p.release_date).slice(0, 4) : (p.year ? String(p.year) : "");
                var rate = p.vote_average ? Number(p.vote_average).toFixed(1) : "";
                var genreStr = mediaType === "series" ? "Series" : "Movies";
                if (Array.isArray(p.genres) && p.genres.length > 0) {
                    var gnames = [];
                    for (var g = 0; g < Math.min(2, p.genres.length); g++) {
                        gnames.push(typeof p.genres[g] === "string" ? p.genres[g] : String(p.genres[g].name || ""));
                    }
                    if (gnames.length > 0) genreStr = gnames.join(" / ");
                }
                out.push({
                    id: pid,
                    slug: "lm-" + mediaType + "-" + pid,
                    mediaType: mediaType,
                    source: "LaMovie",
                    title: title,
                    year: yr,
                    rating: rate,
                    genre: genreStr,
                    thumb: poster || back,
                    backdrop: back || poster,
                    overview: decodeEntities(p.overview || p.description || (title + " streaming on LaMovie.")),
                    trailerId: String(p.trailer || p.youtube_id || ""),
                    pageUrl: "https://lamovie.org/" + (mediaType === "series" ? "series/" : "peliculas/") + (p.slug || pid)
                });
            }
        } catch (e) {}
        return out;
    }

    function mergeStreamItems(added) {
        if (!added || added.length === 0) return;
        var merged = allStreamItems.slice(0);
        var bySlug = {};
        for (var i = 0; i < merged.length; i++) bySlug[merged[i].slug] = true;
        for (var j = 0; j < added.length; j++) {
            if (!bySlug[added[j].slug]) {
                bySlug[added[j].slug] = true;
                merged.push(added[j]);
            }
        }
        allStreamItems = merged;
        rebuildFilteredStream();
    }

    function fetchLaMovieFeed(endpoint, mediaType, onDone) {
        isLoading = true;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            isLoading = false;
            var addedCount = 0;
            if (xhr.status >= 200 && xhr.status < 400 && xhr.responseText) {
                var parsed = parseLaMovieList(xhr.responseText, mediaType);
                addedCount = parsed.length;
                if (parsed.length > 0) mergeStreamItems(parsed);
            }
            if (typeof onDone === "function") onDone(addedCount);
        };
        xhr.open("GET", "https://lamovie.org/wp-api/v1/" + endpoint);
        xhr.setRequestHeader("Accept", "application/json");
        xhr.send();
    }

    function loadMoreStreamingFeeds() {
        if (feedBusy) return;
        var wantMovies = (activeTab === "movies" || activeTab === "forme" || activeTab === "genre") && hasMoreMovies;
        var wantSeries = (activeTab === "series" || activeTab === "forme" || activeTab === "genre") && hasMoreSeries;
        if (!wantMovies && !wantSeries) return;
        feedBusy = true;
        var pending = (wantMovies ? 1 : 0) + (wantSeries ? 1 : 0);
        if (wantMovies) {
            moviesApiPage += 1;
            fetchLaMovieFeed("listing/movies?page=" + moviesApiPage + "&postsPerPage=20&postType=movies&orderBy=latest&order=desc", "movie", function(cnt) {
                if (cnt === 0 || moviesApiPage >= 25) hasMoreMovies = false;
                pending--;
                if (pending <= 0) feedBusy = false;
            });
        }
        if (wantSeries) {
            seriesApiPage += 1;
            fetchLaMovieFeed("listing/tvshows?page=" + seriesApiPage + "&postsPerPage=20&postType=tvshows&orderBy=latest&order=desc", "series", function(cnt) {
                if (cnt === 0 || seriesApiPage >= 25) hasMoreSeries = false;
                pending--;
                if (pending <= 0) feedBusy = false;
            });
        }
    }

    function fetchYouTubeSearch(queryStr) {
        var q = String(queryStr || "").trim();
        if (q === "") q = "Nintendo Switch 2 gameplay trailer";
        isLoading = true;
        var xhrY = new XMLHttpRequest();
        xhrY.onreadystatechange = function() {
            if (xhrY.readyState !== XMLHttpRequest.DONE) return;
            isLoading = false;
            if (xhrY.status >= 200 && xhrY.status < 400 && xhrY.responseText) {
                var ytRe = /"videoId":"([A-Za-z0-9_-]{11})"[\s\S]{0,450}?"title":\{"runs":\[\{"text":"([^"\\]*(?:\\.[^"\\]*)*)"\}\]/g;
                var ym;
                var seen = {};
                var out = [];
                while ((ym = ytRe.exec(xhrY.responseText)) !== null && out.length < 24) {
                    var vid = ym[1];
                    if (seen[vid]) continue;
                    seen[vid] = true;
                    var t = decodeEntities(ym[2].replace(/\\"/g, "\"").replace(/\\u0026/g, "&"));
                    out.push({
                        id: vid,
                        slug: "yt-" + vid,
                        mediaType: "youtube",
                        source: "YouTube",
                        title: t,
                        year: "YouTube",
                        rating: "HD",
                        genre: "YouTube Video",
                        thumb: "https://i.ytimg.com/vi/" + vid + "/hqdefault.jpg",
                        backdrop: "https://i.ytimg.com/vi/" + vid + "/hqdefault.jpg",
                        overview: t + " — Select preview window to watch fullscreen.",
                        trailerId: vid,
                        pageUrl: "https://www.youtube.com/watch?v=" + vid
                    });
                }
                if (out.length > 0) mergeStreamItems(out);
            }
        };
        xhrY.open("GET", "https://www.youtube.com/results?search_query=" + encodeURIComponent(q));
        xhrY.send();
    }

    function fetchLaMovieSearch(q) {
        if (!q || q === "") return;
        isLoading = true;
        var xhrS = new XMLHttpRequest();
        xhrS.onreadystatechange = function() {
            if (xhrS.readyState !== XMLHttpRequest.DONE) return;
            isLoading = false;
            if (xhrS.status >= 200 && xhrS.status < 400 && xhrS.responseText) {
                var parsed = parseLaMovieList(xhrS.responseText, "movie");
                if (parsed.length > 0) mergeStreamItems(parsed);
            }
        };
        xhrS.open("GET", "https://lamovie.org/wp-api/v1/search?q=" + encodeURIComponent(q) + "&postType=any&postsPerPage=30");
        xhrS.send();
    }

    function matchesLetter(title, letter) {
        if (!letter || letter === "All") return true;
        var clean = String(title || "").trim();
        if (clean === "") return letter === "#";
        var first = clean.charAt(0).toUpperCase();
        if (letter === "#") return !/^[A-Z]$/.test(first);
        return first === String(letter).toUpperCase();
    }

    function stepAlphabetLetter(dir) {
        var idx = alphabetLetters.indexOf(activeLetter);
        if (idx < 0) idx = 0;
        var nextIdx = (idx + dir + alphabetLetters.length) % alphabetLetters.length;
        activeLetter = alphabetLetters[nextIdx];
        currentPage = 0;
        navSound.play();
        rebuildFilteredStream();
        if (filteredStreamModel.count < 8 && (hasMoreMovies || hasMoreSeries)) loadMoreStreamingFeeds();
    }

    function selectAlphabetLetter(letter) {
        activeLetter = letter;
        currentPage = 0;
        navSound.play();
        rebuildFilteredStream();
        if (filteredStreamModel.count < 8 && (hasMoreMovies || hasMoreSeries)) loadMoreStreamingFeeds();
    }

    function totalPages() {
        return Math.max(1, Math.ceil(filteredStreamModel.count / itemsPerPage));
    }

    function rebuildPageSlice() {
        pageStreamModel.clear();
        var tp = totalPages();
        if (currentPage >= tp) currentPage = tp - 1;
        if (currentPage < 0) currentPage = 0;
        var start = currentPage * itemsPerPage;
        var end = Math.min(filteredStreamModel.count, start + itemsPerPage);
        for (var i = start; i < end; i++) {
            pageStreamModel.append(filteredStreamModel.get(i));
        }
        if (gridIndex >= pageStreamModel.count) gridIndex = Math.max(0, pageStreamModel.count - 1);
    }

    function nextPage() {
        var tp = totalPages();
        if (currentPage + 1 < tp) {
            navSound.play();
            currentPage += 1;
            gridIndex = 0;
            rebuildPageSlice();
            if (currentPage + 1 >= tp - 1 && (hasMoreMovies || hasMoreSeries)) {
                loadMoreStreamingFeeds();
            }
        } else if (hasMoreMovies || hasMoreSeries) {
            navSound.play();
            loadMoreStreamingFeeds();
        }
    }

    function prevPage() {
        if (currentPage > 0) {
            navSound.play();
            currentPage -= 1;
            gridIndex = 0;
            rebuildPageSlice();
        }
    }

    function rebuildFilteredStream() {
        filteredStreamModel.clear();
        var src = [];
        var i;
        if (activeTab === "favorites") {
            for (i = 0; i < savedFavorites.length; i++) {
                var fav = savedFavorites[i];
                if (!fav) continue;
                if (!matchesLetter(fav.title || fav.label || "", activeLetter)) continue;
                src.push({
                    id: fav.id || fav.slug || String(i),
                    slug: fav.slug || fav.url || String(i),
                    mediaType: fav.mediaType || "movie",
                    source: fav.source || "Favorite",
                    title: fav.title || fav.label || "Favorite",
                    year: fav.year || "",
                    rating: fav.rating || "",
                    genre: fav.genre || "Favorite",
                    thumb: fav.thumb || fav.backdrop || "",
                    backdrop: fav.backdrop || fav.thumb || "",
                    overview: fav.overview || "",
                    trailerId: fav.trailerId || "",
                    pageUrl: fav.url || "https://lamovie.org"
                });
            }
        } else {
            var base = allStreamItems.length > 0 ? allStreamItems : fallbackCatalog;
            var qLower = String(searchQuery || "").trim().toLowerCase();
            var gLower = String(selectedGenre || "").trim().toLowerCase();
            for (i = 0; i < base.length; i++) {
                var it = base[i];
                if (activeTab === "movies" && it.mediaType !== "movie") continue;
                if (activeTab === "series" && it.mediaType !== "series") continue;
                if (activeTab === "youtube" && it.mediaType !== "youtube") continue;
                if (!matchesLetter(it.title, activeLetter)) continue;
                if (activeTab === "genre" && gLower !== "") {
                    var blob = (String(it.genre || "") + " " + String(it.title || "") + " " + String(it.overview || "")).toLowerCase();
                    if (blob.indexOf(gLower) < 0) continue;
                }
                if (qLower !== "") {
                    var qBlob = (String(it.title || "") + " " + String(it.genre || "") + " " + String(it.overview || "")).toLowerCase();
                    if (qBlob.indexOf(qLower) < 0) continue;
                }
                src.push(it);
            }
        }
        if (activeLetter !== "All") {
            src.sort(function(a, b) {
                var ta = String(a.title || "").toLowerCase();
                var tb = String(b.title || "").toLowerCase();
                return ta < tb ? -1 : (ta > tb ? 1 : 0);
            });
        }
        for (i = 0; i < src.length; i++) {
            filteredStreamModel.append(src[i]);
        }
        rebuildPageSlice();
    }

    function destroyPreviewPlayer() {
        if (inlineWebView) {
            try { inlineWebView.destroy(); } catch (e) {}
            inlineWebView = null;
        }
    }

    function destroyFullscreenPlayer() {
        if (fullWebView) {
            try { fullWebView.destroy(); } catch (e) {}
            fullWebView = null;
        }
    }

    function mountWebInto(hostItem, targetUrl, disableInput, assignProp) {
        if (!targetUrl || !hostItem) return;
        var extra = disableInput ? "; enabled: false" : "";
        var candidates = [
            "import QtQuick 2.12; import QtWebView 1.1; WebView { x: 0; y: 0; width: parent.width; height: parent.height" + extra + " }",
            "import QtQuick 2.12; import QtWebView 1.0; WebView { x: 0; y: 0; width: parent.width; height: parent.height" + extra + " }",
            "import QtQuick 2.12; import QtWebView 1.15; WebView { x: 0; y: 0; width: parent.width; height: parent.height" + extra + " }",
            "import QtQuick 2.12; import QtWebEngine 1.8; WebEngineView { x: 0; y: 0; width: parent.width; height: parent.height" + extra + " }"
        ];
        for (var i = 0; i < candidates.length; i++) {
            try {
                var o = Qt.createQmlObject(candidates[i], hostItem, "netflixWeb_" + assignProp + "_" + i);
                if (o) {
                    var cleanUrl = String(targetUrl).replace("youtube-nocookie.com/embed/", "youtube.com/embed/");
                    if (cleanUrl.indexOf("youtube.com/embed/") >= 0 && typeof o.loadHtml === "function") {
                        var safeSrc = cleanUrl.replace(/"/g, "&quot;");
                        o.loadHtml('<!doctype html><html><body style="margin:0;padding:0;background:#000;overflow:hidden;"><iframe style="position:fixed;inset:0;width:100vw;height:100vh;border:0;" src="' + safeSrc + '" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen" allowfullscreen></iframe></body></html>', "https://www.youtube.com/");
                    } else {
                        o.url = cleanUrl;
                    }
                    if (assignProp === "inline") inlineWebView = o;
                    else if (assignProp === "full") fullWebView = o;
                    else if (assignProp === "external") nativeWebView = o;
                    return;
                }
            } catch (e) {}
        }
    }

    function startPreviewPlayback(embedUrl) {
        destroyPreviewPlayer();
        if (!embedUrl || previewPaused || fullscreenVideo) return;
        mountWebInto(previewVideoHost, embedUrl, true, "inline");
    }

    function togglePreviewPlayback() {
        previewPaused = !previewPaused;
        if (previewPaused) {
            turnOffSfx.play();
            destroyPreviewPlayer();
        } else {
            turnOnSfx.play();
            if (detailPreviewUrl !== "") startPreviewPlayback(detailPreviewUrl);
        }
    }

    function resolvePreviewTrailerForTitle(itemTitle, ytIdHint, isYouTubeItem) {
        if (ytIdHint && ytIdHint !== "") {
            var pUrl = "https://www.youtube.com/embed/" + ytIdHint + "?autoplay=1&mute=0&controls=0&disablekb=1&fs=0&modestbranding=1&iv_load_policy=3&playsinline=1&rel=0";
            var fUrl = "https://www.youtube.com/embed/" + ytIdHint + "?autoplay=1&mute=0&playsinline=1&rel=0";
            detailPreviewUrl = pUrl;
            if (isYouTubeItem) detailPlayUrl = fUrl;
            if (!previewPaused) startPreviewPlayback(pUrl);
            return;
        }
        var expected = itemTitle;
        var xhrT = new XMLHttpRequest();
        xhrT.onreadystatechange = function() {
            if (xhrT.readyState !== XMLHttpRequest.DONE) return;
            if (!detailOpen || detailItem.title !== expected) return;
            if (xhrT.status >= 200 && xhrT.status < 400 && xhrT.responseText) {
                var ym = xhrT.responseText.match(/"videoId":"([A-Za-z0-9_-]{11})"/);
                if (ym && ym[1]) {
                    var pv = "https://www.youtube.com/embed/" + ym[1] + "?autoplay=1&mute=0&controls=0&disablekb=1&fs=0&modestbranding=1&iv_load_policy=3&playsinline=1&rel=0";
                    detailPreviewUrl = pv;
                    if (!previewPaused) startPreviewPlayback(pv);
                }
            }
        };
        xhrT.open("GET", "https://www.youtube.com/results?search_query=" + encodeURIComponent(itemTitle + " official trailer"));
        xhrT.send();
    }

    function loadPlayerSourcesByPostId(targetId, expectedTitle, andAutoLaunch) {
        playerSourcesModel.clear();
        selectedPlayerIdx = 0;
        var u = "https://lamovie.org/wp-api/v1/player?postId=" + encodeURIComponent(targetId) + "&demo=0";
        var xhrP = new XMLHttpRequest();
        xhrP.onreadystatechange = function() {
            if (xhrP.readyState !== XMLHttpRequest.DONE) return;
            if (!detailOpen || detailItem.title !== expectedTitle) return;
            streamsLoading = false;
            var preferredUrl = "";
            if (xhrP.status >= 200 && xhrP.status < 400 && xhrP.responseText) {
                try {
                    var res = JSON.parse(xhrP.responseText);
                    var embeds = (res && res.data && Array.isArray(res.data.embeds)) ? res.data.embeds
                               : (res && Array.isArray(res.embeds) ? res.embeds : []);
                    for (var i = 0; i < embeds.length; i++) {
                        var emb = embeds[i];
                        var srcUrl = String(emb.url || emb.src || "").trim();
                        if (srcUrl.indexOf("//") === 0) srcUrl = "https:" + srcUrl;
                        if (srcUrl !== "") {
                            var lbl = String(emb.server || emb.lang || emb.language || ("Server " + (i + 1)));
                            playerSourcesModel.append({ label: lbl, url: srcUrl });
                            if (preferredUrl === "" || (srcUrl.indexOf("vimeos.net") >= 0 && preferredUrl.indexOf("vimeos.net") < 0)) {
                                preferredUrl = srcUrl;
                            }
                        }
                    }
                } catch (e) {}
            }
            if (preferredUrl !== "") {
                detailPlayUrl = preferredUrl;
            } else if (detailPlayUrl === "" && detailItem && detailItem.pageUrl) {
                detailPlayUrl = detailItem.pageUrl;
            }
            if ((andAutoLaunch || fullscreenPending) && fullscreenVideo) {
                fullscreenPending = false;
                mountFullscreenTarget(detailPlayUrl !== "" ? detailPlayUrl : detailItem.pageUrl);
            }
        };
        xhrP.open("GET", u);
        xhrP.setRequestHeader("Accept", "application/json");
        xhrP.send();
    }

    function fetchLaMoviePlayers(postId, mediaType, expectedTitle) {
        playerSourcesModel.clear();
        episodesModel.clear();
        if (!postId) { streamsLoading = false; return; }
        streamsLoading = true;

        if (mediaType === "series") {
            var epUrl = "https://lamovie.org/wp-api/v1/single/episodes/list?_id=" + encodeURIComponent(postId) + "&season=1&page=1&postsPerPage=24";
            var xhrEp = new XMLHttpRequest();
            xhrEp.onreadystatechange = function() {
                if (xhrEp.readyState !== XMLHttpRequest.DONE) return;
                if (!detailOpen || detailItem.title !== expectedTitle) return;
                var firstEpId = "";
                if (xhrEp.status >= 200 && xhrEp.status < 400 && xhrEp.responseText) {
                    try {
                        var epJson = JSON.parse(xhrEp.responseText);
                        var epPosts = (epJson && epJson.data && Array.isArray(epJson.data.posts)) ? epJson.data.posts : [];
                        for (var i = 0; i < Math.min(12, epPosts.length); i++) {
                            var ep = epPosts[i];
                            if (!ep || !ep._id) continue;
                            episodesModel.append({ eid: String(ep._id), title: decodeEntities(ep.title || ("Episode " + (i + 1))) });
                            if (firstEpId === "") firstEpId = String(ep._id);
                        }
                    } catch (e) {}
                }
                selectedEpisodeIdx = 0;
                loadPlayerSourcesByPostId(firstEpId !== "" ? firstEpId : postId, expectedTitle, false);
            };
            xhrEp.open("GET", epUrl);
            xhrEp.setRequestHeader("Accept", "application/json");
            xhrEp.send();
        } else {
            loadPlayerSourcesByPostId(postId, expectedTitle, false);
        }
    }

    function openItemDetail(idx) {
        if (idx < 0 || idx >= pageStreamModel.count) return;
        var item = pageStreamModel.get(idx);
        detailItem = {
            id: item.id, slug: item.slug, mediaType: item.mediaType, source: item.source,
            title: item.title, year: item.year, rating: item.rating, genre: item.genre,
            thumb: item.thumb, backdrop: item.backdrop, overview: item.overview,
            trailerId: item.trailerId, pageUrl: item.pageUrl
        };
        detailSynopsis = item.overview || "";
        detailBackdrop = item.backdrop || item.thumb || "";
        detailPreviewUrl = "";
        detailPlayUrl = "";
        previewPaused = false;
        streamsLoading = (item.source === "LaMovie" || item.mediaType !== "youtube");
        fullscreenPending = false;
        detailBtnIdx = 1; // Default on Play Fullscreen button; press Up to select Preview Window to pause/play
        selectedEpisodeIdx = 0;
        selectedPlayerIdx = 0;
        episodesModel.clear();
        playerSourcesModel.clear();
        detailOpen = true;
        fullscreenVideo = false;
        focusZone = "detail";
        selectSfx.play();
        resolvePreviewTrailerForTitle(item.title, item.trailerId, item.mediaType === "youtube");
        if (item.source === "LaMovie" || item.mediaType !== "youtube") {
            fetchLaMoviePlayers(item.id, item.mediaType, item.title);
        } else {
            streamsLoading = false;
        }
    }

    function mountFullscreenTarget(playTarget) {
        if (!playTarget || playTarget === "") return;
        destroyFullscreenPlayer();
        if (playTarget.indexOf("videoapp.zip") >= 0) {
            var expectedTarget = playTarget;
            var xhrU = new XMLHttpRequest();
            xhrU.onreadystatechange = function() {
                if (xhrU.readyState !== XMLHttpRequest.DONE) return;
                if (!fullscreenVideo) return;
                var resolved = expectedTarget;
                if (xhrU.status >= 200 && xhrU.status < 400 && xhrU.responseText) {
                    var fm = xhrU.responseText.match(/<iframe[^>]+id=["']frame["'][^>]+src=["']([^"']+)["']/i)
                          || xhrU.responseText.match(/<iframe[^>]+src=["']((?:https?:)?\/\/vimeos\.net\/embed-[^"']+)["']/i)
                          || xhrU.responseText.match(/<iframe[^>]+src=["']((?:https?:)?\/\/[^"']+)["']/i)
                          || xhrU.responseText.match(/window\.location(?:\.href)?\s*=\s*["']((?:https?:)?\/\/[^"']+)["']/i);
                    if (fm && fm[1]) {
                        resolved = fm[1];
                        if (resolved.indexOf("//") === 0) resolved = "https:" + resolved;
                        if (resolved.indexOf("vimeos.net/embed-") >= 0) resolved = resolved.split("?")[0];
                    }
                }
                mountWebInto(fullscreenHost, resolved, false, "full");
            };
            xhrU.open("GET", playTarget);
            xhrU.send();
            return;
        }
        mountWebInto(fullscreenHost, playTarget.replace("controls=0", "controls=1").replace("disablekb=1", "disablekb=0"), false, "full");
    }

    function openFullscreenPlayback() {
        previewPaused = true;
        destroyPreviewPlayer();
        destroyFullscreenPlayer();
        fullscreenVideo = true;
        focusZone = "fullscreenVideo";
        selectSfx.play();

        if (detailPlayUrl !== "") {
            fullscreenPending = false;
            mountFullscreenTarget(detailPlayUrl);
        } else if (streamsLoading && detailItem && detailItem.mediaType !== "youtube") {
            fullscreenPending = true;
        } else {
            var fallbackTarget = (detailItem && detailItem.mediaType === "youtube" && detailPreviewUrl !== "")
                ? detailPreviewUrl
                : (detailItem && detailItem.pageUrl ? detailItem.pageUrl : detailPreviewUrl);
            fullscreenPending = false;
            mountFullscreenTarget(fallbackTarget);
        }
    }

    function closeFullscreenPlayback() {
        fullscreenVideo = false;
        fullscreenPending = false;
        focusZone = "detail";
        destroyFullscreenPlayer();
        backSfx.play();
        if (detailPreviewUrl !== "" && !previewPaused) startPreviewPlayback(detailPreviewUrl);
    }

    function openSearchKeyboard() {
        browserRoot.editingUrl = true;
        openSwitchKeyboard(tr("Search Netflix (LaMovie & YouTube)"), browserRoot.searchQuery, false, 120, function(val) {
            browserRoot.editingUrl = false;
            var q = String(val || "").trim();
            browserRoot.searchQuery = q;
            browserRoot.currentPage = 0;
            if (q !== "") {
                fetchYouTubeSearch(q);
                fetchLaMovieSearch(q);
            }
            rebuildFilteredStream();
            browserRoot.forceActiveFocus();
        }, function() {
            browserRoot.editingUrl = false;
            browserRoot.forceActiveFocus();
        });
    }

    function activateSidebar(idx) {
        if (idx < 0 || idx >= sidebarItems.length) return;
        var entry = sidebarItems[idx];
        if (entry.kind === "header") return;
        sidebarFocusIdx = idx;
        detailOpen = false;
        fullscreenVideo = false;
        destroyPreviewPlayer();
        destroyFullscreenPlayer();
        selectSfx.play();
        if (entry.kind === "genre") {
            activeTab = "genre";
            selectedGenre = entry.genre;
        } else {
            activeTab = entry.id;
            selectedGenre = "";
        }
        currentPage = 0;
        gridIndex = 0;
        rebuildFilteredStream();
    }

    function moveSidebar(dir) {
        var next = sidebarFocusIdx;
        for (var i = 0; i < sidebarItems.length; i++) {
            next = (next + dir + sidebarItems.length) % sidebarItems.length;
            if (sidebarItems[next].kind !== "header") break;
        }
        sidebarFocusIdx = next;
    }

    function goHome() {
        navSound.play();
        detailOpen = false;
        fullscreenVideo = false;
        destroyPreviewPlayer();
        destroyFullscreenPlayer();
        searchQuery = "";
        activeTab = "forme";
        activeLetter = "All";
        selectedGenre = "";
        sidebarFocusIdx = 0;
        currentPage = 0;
        focusZone = "grid";
        rebuildFilteredStream();
    }

    function navigate(rawTarget) {
        var t = String(rawTarget || "").trim();
        if (t === "" || t === "https://lamovie.org" || t === "netflix://") {
            goHome();
            return;
        }
        currentUrl = t;
        activeTab = "external";
        detailOpen = false;
        fullscreenVideo = false;
        destroyPreviewPlayer();
        if (nativeWebView) {
            try { nativeWebView.destroy(); } catch (e) {}
            nativeWebView = null;
        }
        mountWebInto(externalWebHost, t, false, "external");
    }

    function goBack() {
        if (fullscreenVideo) {
            closeFullscreenPlayback();
        } else if (detailOpen) {
            detailOpen = false;
            previewPaused = false;
            destroyPreviewPlayer();
            focusZone = "grid";
            backSfx.play();
        } else if (activeTab === "external") {
            goHome();
        } else {
            backSfx.play();
            closeInThemeBrowser();
        }
    }

    function loadAllStreamingFeeds() {
        moviesApiPage = 1;
        seriesApiPage = 1;
        hasMoreMovies = true;
        hasMoreSeries = true;
        fetchLaMovieFeed("listing/movies?page=1&postsPerPage=20&postType=movies&orderBy=latest&order=desc", "movie", function(cnt) {
            if (cnt === 0) hasMoreMovies = false;
        });
        fetchLaMovieFeed("listing/tvshows?page=1&postsPerPage=20&postType=tvshows&orderBy=latest&order=desc", "series", function(cnt) {
            if (cnt === 0) hasMoreSeries = false;
        });
        fetchYouTubeSearch("Nintendo Switch 2 gameplay trailer");
    }

    Component.onCompleted: {
        loadSavedFavorites();
        allStreamItems = fallbackCatalog.slice(0);
        rebuildFilteredStream();
    }

    onVisibleChanged: {
        if (visible) {
            loadSavedFavorites();
            if (allStreamItems.length <= fallbackCatalog.length) loadAllStreamingFeeds();
            browserRoot.forceActiveFocus();
        } else {
            destroyPreviewPlayer();
            destroyFullscreenPlayer();
        }
    }

    Keys.onLeftPressed: {
        if (editingUrl || fullscreenVideo) return;
        navSound.play();
        if (detailOpen) {
            if (detailBtnIdx === 0) detailBtnIdx = 3;
            else if (detailBtnIdx === 1) detailBtnIdx = 0;
            else detailBtnIdx -= 1;
            return;
        }
        if (focusZone === "grid") {
            if (gridIndex % 4 === 0) {
                if (currentPage > 0) prevPage();
                else focusZone = "sidebar";
            } else {
                gridIndex = Math.max(0, gridIndex - 1);
            }
        }
    }
    Keys.onRightPressed: {
        if (editingUrl || fullscreenVideo) return;
        navSound.play();
        if (detailOpen) {
            detailBtnIdx = (detailBtnIdx + 1) % 4;
            return;
        }
        if (focusZone === "sidebar") {
            activateSidebar(sidebarFocusIdx);
            focusZone = "grid";
        } else if (pageStreamModel.count > 0) {
            if (gridIndex % 4 === 3 && (currentPage + 1 < totalPages() || hasMoreMovies || hasMoreSeries)) {
                nextPage();
            } else {
                gridIndex = Math.min(pageStreamModel.count - 1, gridIndex + 1);
            }
        }
    }
    Keys.onUpPressed: {
        if (editingUrl || fullscreenVideo) return;
        navSound.play();
        if (detailOpen) {
            detailBtnIdx = 0; // Up focuses Preview Window to toggle Play/Pause with A
            return;
        }
        if (focusZone === "sidebar") moveSidebar(-1);
        else gridIndex = Math.max(0, gridIndex - 4);
    }
    Keys.onDownPressed: {
        if (editingUrl || fullscreenVideo) return;
        navSound.play();
        if (detailOpen) {
            if (detailBtnIdx === 0) detailBtnIdx = 1; // Down returns from Preview Window to Watch Fullscreen
            return;
        }
        if (focusZone === "sidebar") moveSidebar(1);
        else if (pageStreamModel.count > 0) gridIndex = Math.min(pageStreamModel.count - 1, gridIndex + 4);
    }
    Keys.onBackPressed: {
        event.accepted = true;
        fullscreenVideo = false;
        fullscreenPending = false;
        detailOpen = false;
        destroyPreviewPlayer();
        destroyFullscreenPlayer();
        backSfx.play();
        closeInThemeBrowser();
    }
    Keys.onEscapePressed: {
        event.accepted = true;
        goBack();
    }
    Keys.onReleased: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function")
            root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
    }
    Keys.onPressed: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
        var isB = api.keys.isCancel(event) || event.key === Qt.Key_Escape || event.key === Qt.Key_B || event.key === Qt.Key_Backspace;
        if (fullscreenVideo) {
            if (isB && !event.isAutoRepeat) {
                event.accepted = true;
                closeFullscreenPlayback();
            }
            return;
        }
        if (detailOpen) {
            if (isB && !event.isAutoRepeat) { event.accepted = true; goBack(); }
            else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (detailBtnIdx === 0) togglePreviewPlayback();
                else if (detailBtnIdx === 2) toggleFavorite();
                else if (detailBtnIdx === 3) Qt.openUrlExternally(detailPlayUrl !== "" ? detailPlayUrl : (detailItem.pageUrl || "https://lamovie.org"));
                else openFullscreenPlayback();
            } else if (api.keys.isDetails(event) && !event.isAutoRepeat) {
                event.accepted = true;
                toggleFavorite();
            }
            return;
        }
        if (isB && !event.isAutoRepeat) {
            event.accepted = true;
            goBack();
        } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (focusZone === "sidebar") {
                activateSidebar(sidebarFocusIdx);
                focusZone = "grid";
            } else {
                openItemDetail(gridIndex);
            }
        } else if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            openSearchKeyboard();
        } else if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            toggleFavorite();
        } else if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            stepAlphabetLetter(1);
        } else if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            stepAlphabetLetter(-1);
        }
    }

    Rectangle { anchors.fill: parent; color: "#0B0B0F" }

    // Top Netflix Header Bar (Zero TextInput -> Zero Blue Box!)
    Rectangle {
        id: browserTopBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(64)
        color: "#111116"
        z: 30

        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#27272A" }

        RowLayout {
            anchors { fill: parent; leftMargin: vpx(16); rightMargin: vpx(16) }
            spacing: vpx(10)

            // Back (<)
            Rectangle {
                Layout.preferredWidth: vpx(38); Layout.preferredHeight: vpx(40)
                width: vpx(38); height: vpx(40); radius: vpx(10); color: "#1C1C22"
                Text { anchors.centerIn: parent; text: "<"; color: "#FFFFFF"; font.family: titleFont.name; font.bold: true; font.pixelSize: vpx(18) }
                MouseArea { anchors.fill: parent; onClicked: browserRoot.goBack() }
            }

            // Netflix Brand Wordmark
            Text {
                text: "NETFLIX"
                color: "#E50914"
                font.family: titleFont.name
                font.pixelSize: vpx(26)
                font.bold: true
                font.letterSpacing: 1.5
            }

            // For Me / Home Quick Button
            Rectangle {
                Layout.preferredWidth: vpx(84); Layout.preferredHeight: vpx(40)
                radius: vpx(10); color: browserRoot.activeTab === "forme" ? "#E50914" : "#1C1C22"
                Text { anchors.centerIn: parent; text: tr("For Me"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: browserRoot.goHome() }
            }

            // Dedicated Pure-QML Search Bar (No TextInput -> Zero Android Blue Focus Box)
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: vpx(40); radius: vpx(10)
                color: "#18181D"
                border.color: browserRoot.editingUrl ? "#E50914" : "#3F3F46"
                border.width: browserRoot.editingUrl ? vpx(2) : vpx(1)

                Text {
                    anchors { fill: parent; leftMargin: vpx(14); rightMargin: vpx(14) }
                    verticalAlignment: Text.AlignVCenter
                    text: browserRoot.searchQuery !== "" ? ("Search: " + browserRoot.searchQuery) : tr("Search movies, series, or YouTube (X)...")
                    color: browserRoot.searchQuery !== "" ? "#FFFFFF" : "#A1A1AA"
                    font.family: titleFont.name; font.pixelSize: vpx(14); elide: Text.ElideRight
                }
                MouseArea { anchors.fill: parent; onClicked: browserRoot.openSearchKeyboard() }
            }

            // Clear Search
            Rectangle {
                visible: browserRoot.searchQuery !== ""
                Layout.preferredWidth: vpx(66); Layout.preferredHeight: vpx(40); radius: vpx(10); color: "#27272A"
                Text { anchors.centerIn: parent; text: tr("Clear"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(13); font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: { browserRoot.searchQuery = ""; browserRoot.currentPage = 0; browserRoot.rebuildFilteredStream(); } }
            }

            // Refresh Feeds
            Rectangle {
                Layout.preferredWidth: vpx(74); Layout.preferredHeight: vpx(40); radius: vpx(10); color: "#1C1C22"
                Text { anchors.centerIn: parent; text: browserRoot.isLoading ? "..." : tr("Sync"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(13); font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: browserRoot.loadAllStreamingFeeds() }
            }

            // Close
            Rectangle {
                Layout.preferredWidth: vpx(84); Layout.preferredHeight: vpx(40); radius: vpx(10); color: "#E50914"
                Text { anchors.centerIn: parent; text: tr("B  Close"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: { backSfx.play(); closeInThemeBrowser(); } }
            }
        }
    }

    // Main eShop-Style Netflix Body (Left Category Sidebar + Right Content Pane)
    Item {
        anchors { top: browserTopBar.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }

        // Left Sidebar (Categories / For Me / Favorites / Movies / Series / YouTube)
        Rectangle {
            id: netflixSidebar
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            width: Math.round(parent.width * 0.21)
            color: "#111116"
            visible: browserRoot.activeTab !== "external"

            ListView {
                anchors { fill: parent; margins: vpx(12) }
                clip: true; spacing: vpx(4)
                model: browserRoot.sidebarItems
                delegate: Item {
                    width: parent ? parent.width : vpx(180)
                    height: modelData.kind === "header" ? vpx(32) : vpx(44)
                    property bool isActive: (modelData.kind === "genre" && browserRoot.activeTab === "genre" && browserRoot.selectedGenre === modelData.genre)
                                         || (modelData.kind === "tab" && browserRoot.activeTab === modelData.id)
                    property bool isKb: browserRoot.focusZone === "sidebar" && index === browserRoot.sidebarFocusIdx

                    Rectangle {
                        visible: modelData.kind !== "header"
                        anchors.fill: parent; radius: vpx(8)
                        color: isActive ? "#E50914" : (isKb ? "#23232D" : "transparent")
                        border.width: isKb ? vpx(2.5) : 0; border.color: "#E50914"
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: modelData.kind === "genre" ? vpx(20) : vpx(12); verticalCenter: parent.verticalCenter }
                        text: modelData.label
                        color: modelData.kind === "header" ? "#E50914" : "#FFFFFF"
                        font.family: titleFont.name; font.pixelSize: modelData.kind === "header" ? vpx(13) : vpx(16)
                        font.bold: isActive || isKb || modelData.kind === "header"
                    }
                    MouseArea {
                        anchors.fill: parent; enabled: modelData.kind !== "header"
                        onClicked: { browserRoot.focusZone = "sidebar"; browserRoot.activateSidebar(index); browserRoot.focusZone = "grid"; }
                    }
                }
            }
        }

        // Right Content Pane
        Item {
            anchors { top: parent.top; bottom: parent.bottom; left: browserRoot.activeTab === "external" ? parent.left : netflixSidebar.right; right: parent.right }

            // External link view (only when opened via download/github links)
            Item {
                visible: browserRoot.activeTab === "external"
                anchors.fill: parent
                Item { id: externalWebHost; anchors { top: parent.top; bottom: extBar.top; left: parent.left; right: parent.right } }
                Rectangle {
                    id: extBar
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: vpx(46)
                    color: "#14141A"
                    Row {
                        anchors.centerIn: parent; spacing: vpx(16)
                        Text { text: browserRoot.currentUrl; color: "#D4D4D8"; font.pixelSize: vpx(13); elide: Text.ElideRight; width: vpx(420) }
                        Rectangle {
                            width: vpx(130); height: vpx(32); radius: vpx(6); color: "#2563EB"
                            Text { anchors.centerIn: parent; text: tr("Open Chrome"); color: "#FFFFFF"; font.pixelSize: vpx(13); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: Qt.openUrlExternally(browserRoot.currentUrl) }
                        }
                        Rectangle {
                            width: vpx(130); height: vpx(32); radius: vpx(6); color: "#E50914"
                            Text { anchors.centerIn: parent; text: tr("Back to Netflix"); color: "#FFFFFF"; font.pixelSize: vpx(13); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: browserRoot.goHome() }
                        }
                    }
                }
            }

            // Streaming Cards Grid (20/Page) + Bottom A-Z Bar & Prev/Next Pagination
            Item {
                visible: browserRoot.activeTab !== "external" && !browserRoot.detailOpen
                anchors { fill: parent; margins: vpx(14) }

                Text {
                    visible: pageStreamModel.count === 0
                    anchors.centerIn: streamGrid
                    text: browserRoot.activeTab === "favorites"
                          ? tr("No Favorites matched. Press Y on any movie, series, or video.")
                          : (browserRoot.isLoading ? tr("Loading streaming catalog...") : tr("No titles matched. Press Next Page or pick another letter."))
                    color: "#9CA3AF"; font.family: titleFont.name; font.pixelSize: vpx(17)
                }

                GridView {
                    id: streamGrid
                    anchors { top: parent.top; left: parent.left; right: parent.right; bottom: netflixAzBar.top; bottomMargin: vpx(8) }
                    clip: true
                    cellWidth: Math.floor(width / 4)
                    cellHeight: vpx(178)
                    model: pageStreamModel
                    currentIndex: browserRoot.gridIndex

                    delegate: Item {
                        width: streamGrid.cellWidth; height: streamGrid.cellHeight
                        property bool selected: browserRoot.focusZone === "grid" && index === browserRoot.gridIndex
                        property bool isFav: browserRoot.isFavoriteItem(model.slug)

                        Rectangle {
                            anchors { fill: parent; margins: vpx(6) }
                            radius: vpx(10); color: "#18181F"; clip: true

                            Item {
                                id: mediaThumbWrap
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: Math.round(parent.height * 0.62); clip: true
                                Image { anchors.fill: parent; source: model.backdrop || model.thumb; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true }
                                Rectangle {
                                    anchors { top: parent.top; left: parent.left; margins: vpx(6) }
                                    height: vpx(20); width: srcTxt.implicitWidth + vpx(12); radius: vpx(5)
                                    color: model.mediaType === "youtube" ? "#DC2626" : (model.mediaType === "series" ? "#7C3AED" : "#E50914")
                                    Text { id: srcTxt; anchors.centerIn: parent; text: model.mediaType === "youtube" ? "YOUTUBE" : (model.mediaType === "series" ? "SERIES" : "MOVIE"); color: "#FFFFFF"; font.pixelSize: vpx(10); font.bold: true }
                                }
                                Rectangle {
                                    visible: isFav
                                    anchors { top: parent.top; right: parent.right; margins: vpx(6) }
                                    width: vpx(24); height: vpx(24); radius: vpx(12); color: "#E50914"
                                    Text { anchors.centerIn: parent; text: "★"; color: "#FDE047"; font.pixelSize: vpx(13) }
                                }
                            }

                            Column {
                                anchors { top: mediaThumbWrap.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; margins: vpx(8) }
                                spacing: vpx(2)
                                Text { width: parent.width; text: model.title; color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true; elide: Text.ElideRight }
                                Text { width: parent.width; text: (model.source || "LaMovie") + " · " + (model.genre || ""); color: "#E50914"; font.family: titleFont.name; font.pixelSize: vpx(11); font.bold: true; elide: Text.ElideRight }
                            }

                            Rectangle {
                                anchors.fill: parent; radius: vpx(10); color: "transparent"
                                border.width: selected ? vpx(4) : 1
                                border.color: selected ? "#E50914" : "#27272A"
                                z: 20
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { browserRoot.focusZone = "grid"; browserRoot.gridIndex = index; browserRoot.openItemDetail(index); }
                            }
                        }
                    }
                }

                // Bottom A-Z Alphabet Filter Bar (LB / RB across all cached & live items)
                Rectangle {
                    id: netflixAzBar
                    anchors { left: parent.left; right: parent.right; bottom: netflixPagerBar.top; bottomMargin: vpx(6) }
                    height: vpx(38)
                    radius: vpx(8)
                    color: "#15151C"
                    border.width: 1
                    border.color: "#27272A"

                    Row {
                        anchors { fill: parent; leftMargin: vpx(8); rightMargin: vpx(8) }
                        spacing: vpx(4)

                        Text {
                            text: "LB"
                            color: "#E50914"
                            font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Flickable {
                            width: parent.width - vpx(54)
                            height: parent.height
                            contentWidth: netflixAzRow.implicitWidth
                            clip: true
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                id: netflixAzRow
                                height: parent.height
                                spacing: vpx(4)
                                Repeater {
                                    model: browserRoot.alphabetLetters
                                    delegate: Rectangle {
                                        property bool cur: browserRoot.activeLetter === modelData
                                        width: modelData === "All" ? vpx(36) : vpx(26)
                                        height: vpx(26)
                                        radius: vpx(6)
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: cur ? "#E50914" : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: cur ? "#FFFFFF" : "#D4D4D8"
                                            font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true
                                        }
                                        MouseArea { anchors.fill: parent; onClicked: browserRoot.selectAlphabetLetter(modelData) }
                                    }
                                }
                            }
                        }

                        Text {
                            text: "RB"
                            color: "#E50914"
                            font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Bottom Paging Bar (Up to 20 items per page; Next loads more from LaMovie)
                Rectangle {
                    id: netflixPagerBar
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: vpx(38)
                    radius: vpx(8)
                    color: "#111116"
                    border.width: 1
                    border.color: "#27272A"

                    Row {
                        anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter }
                        spacing: vpx(8)
                        Rectangle {
                            width: vpx(82); height: vpx(26); radius: vpx(6)
                            color: browserRoot.currentPage > 0 ? "#27272A" : "#18181D"
                            Text { anchors.centerIn: parent; text: "< Prev"; color: browserRoot.currentPage > 0 ? "#FFFFFF" : "#71717A"; font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true }
                            MouseArea { anchors.fill: parent; enabled: browserRoot.currentPage > 0; onClicked: browserRoot.prevPage() }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Page " + (browserRoot.currentPage + 1) + "/" + browserRoot.totalPages() + (browserRoot.hasMoreMovies || browserRoot.hasMoreSeries ? "+" : "") + " (" + filteredStreamModel.count + " titles · Letter: " + browserRoot.activeLetter + ")"
                            color: "#D4D4D8"
                            font.family: titleFont.name; font.pixelSize: vpx(12)
                        }
                        Rectangle {
                            property bool canNext: (browserRoot.currentPage + 1 < browserRoot.totalPages()) || browserRoot.hasMoreMovies || browserRoot.hasMoreSeries
                            width: vpx(96); height: vpx(26); radius: vpx(6)
                            color: canNext ? "#E50914" : "#18181D"
                            Text { anchors.centerIn: parent; text: browserRoot.feedBusy ? "Loading..." : "Next Page >"; color: canNext ? "#FFFFFF" : "#71717A"; font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true }
                            MouseArea { anchors.fill: parent; enabled: parent.canNext; onClicked: browserRoot.nextPage() }
                        }
                    }
                }
            }

            // In-Section Streaming Detail Page (Select Preview + A to Pause/Play; Watch Fullscreen stops preview & plays real movie/series)
            Rectangle {
                visible: browserRoot.activeTab !== "external" && browserRoot.detailOpen
                anchors.fill: parent; color: "#0B0B0F"; z: 35

                RowLayout {
                    anchors { fill: parent; margins: vpx(22) }
                    spacing: vpx(22)

                    // Left: Control-free Preview Window (Highlight border when detailBtnIdx === 0 -> Click or Press A to Pause/Play!)
                    Rectangle {
                        Layout.preferredWidth: Math.round(parent.width * 0.50); Layout.fillHeight: true
                        radius: vpx(14); color: "#050507"; clip: true
                        border.width: browserRoot.detailBtnIdx === 0 ? vpx(4) : 1
                        border.color: browserRoot.detailBtnIdx === 0 ? "#FFFFFF" : "#E50914"

                        Image { anchors.fill: parent; source: browserRoot.detailBackdrop; fillMode: Image.PreserveAspectCrop }
                        Item { id: previewVideoHost; anchors.fill: parent; visible: !browserRoot.previewPaused; enabled: false }
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: vpx(42); color: "#CC000000"
                            Row {
                                anchors.centerIn: parent; spacing: vpx(8)
                                Text { text: browserRoot.previewPaused ? "▶" : "❚❚"; color: "#E50914"; font.pixelSize: vpx(15) }
                                Text {
                                    text: browserRoot.previewPaused
                                          ? tr("Preview Paused · Press A / Tap to Play")
                                          : tr("Preview Playing · Press A / Tap to Pause")
                                    color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(13); font.bold: true
                                }
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { browserRoot.detailBtnIdx = 0; browserRoot.togglePreviewPlayback(); } }
                    }

                    // Right: Title, Synopsis, Episodes / Servers & Actions
                    ColumnLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true; spacing: vpx(10)
                        Text {
                            Layout.fillWidth: true; text: browserRoot.detailItem.title || ""; color: "#FFFFFF"
                            font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.034); font.bold: true; wrapMode: Text.WordWrap
                        }
                        Text {
                            text: (browserRoot.detailItem.source || "LaMovie") + " · " + (browserRoot.detailItem.genre || "") + (browserRoot.detailItem.year ? (" · " + browserRoot.detailItem.year) : "")
                            color: "#E50914"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true
                        }
                        Flickable {
                            Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: width; contentHeight: detailRightCol.implicitHeight + vpx(12); clip: true
                            Column {
                                id: detailRightCol
                                width: parent.width
                                spacing: vpx(10)
                                Text {
                                    width: parent.width; text: browserRoot.detailSynopsis; color: "#E4E4E7"
                                    font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); wrapMode: Text.WordWrap; lineHeight: 1.38
                                }
                                // Stream Servers selector if multiple servers exist
                                Flow {
                                    visible: playerSourcesModel.count > 1
                                    width: parent.width
                                    spacing: vpx(6)
                                    Repeater {
                                        model: playerSourcesModel
                                        delegate: Rectangle {
                                            width: srvLbl.implicitWidth + vpx(18); height: vpx(28); radius: vpx(6)
                                            color: browserRoot.selectedPlayerIdx === index ? "#E50914" : "#1C1C22"
                                            Text { id: srvLbl; anchors.centerIn: parent; text: model.label; color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true }
                                            MouseArea { anchors.fill: parent; onClicked: { browserRoot.selectedPlayerIdx = index; browserRoot.detailPlayUrl = model.url; } }
                                        }
                                    }
                                }
                                // Series Episodes list if tvshows
                                Flow {
                                    visible: episodesModel.count > 0
                                    width: parent.width
                                    spacing: vpx(6)
                                    Repeater {
                                        model: episodesModel
                                        delegate: Rectangle {
                                            width: Math.min(detailRightCol.width, epLbl.implicitWidth + vpx(18)); height: vpx(30); radius: vpx(6)
                                            color: browserRoot.selectedEpisodeIdx === index ? "#E50914" : "#1C1C22"
                                            Text { id: epLbl; anchors.centerIn: parent; width: parent.width - vpx(12); horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: (index + 1) + ". " + model.title; color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true }
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    browserRoot.selectedEpisodeIdx = index;
                                                    browserRoot.streamsLoading = true;
                                                    browserRoot.loadPlayerSourcesByPostId(model.eid, browserRoot.detailItem.title, true);
                                                    browserRoot.openFullscreenPlayback();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Row {
                            Layout.fillWidth: true; spacing: vpx(10)
                            Rectangle {
                                width: vpx(174); height: vpx(44); radius: vpx(10); color: "#E50914"
                                border.width: browserRoot.detailBtnIdx === 1 ? vpx(3) : 0; border.color: "#FFFFFF"
                                Text { anchors.centerIn: parent; text: tr("▶ Play Fullscreen"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: { browserRoot.detailBtnIdx = 1; browserRoot.openFullscreenPlayback(); } }
                            }
                            Rectangle {
                                width: vpx(154); height: vpx(44); radius: vpx(10)
                                color: browserRoot.isFavoriteItem(browserRoot.detailItem.slug) ? "#F59E0B" : "#1C1C22"
                                border.width: browserRoot.detailBtnIdx === 2 ? vpx(3) : 1; border.color: browserRoot.detailBtnIdx === 2 ? "#FFFFFF" : "#3F3F46"
                                Text { anchors.centerIn: parent; text: browserRoot.isFavoriteItem(browserRoot.detailItem.slug) ? tr("★ Favorited") : tr("☆ Favorite"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: { browserRoot.detailBtnIdx = 2; browserRoot.toggleFavorite(); } }
                            }
                            Rectangle {
                                width: vpx(122); height: vpx(44); radius: vpx(10); color: "#1C1C22"
                                border.width: browserRoot.detailBtnIdx === 3 ? vpx(3) : 1; border.color: browserRoot.detailBtnIdx === 3 ? "#E50914" : "#3F3F46"
                                Text { anchors.centerIn: parent; text: tr("LaMovie / Ext"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(13); font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: Qt.openUrlExternally(browserRoot.detailPlayUrl !== "" ? browserRoot.detailPlayUrl : (browserRoot.detailItem.pageUrl || "https://lamovie.org")) }
                            }
                        }
                    }
                }
            }
        }
    }

    // Fullscreen Streaming Overlay
    Rectangle {
        visible: browserRoot.fullscreenVideo
        anchors.fill: parent
        color: "#000000"
        z: 120
        Image { anchors.fill: parent; source: browserRoot.detailBackdrop; fillMode: Image.PreserveAspectFit; opacity: 0.35 }
        Item { id: fullscreenHost; anchors.fill: parent }
        Text {
            visible: browserRoot.fullscreenPending
            anchors.centerIn: parent
            text: tr("Loading LaMovie stream...")
            color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(20); font.bold: true
        }
        Rectangle {
            anchors { top: parent.top; right: parent.right; margins: vpx(20) }
            width: vpx(190); height: vpx(42); radius: vpx(21); color: "#CC000000"; border.width: 2; border.color: "#FFFFFF"
            Text { anchors.centerIn: parent; text: tr("B · Exit Fullscreen"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: browserRoot.closeFullscreenPlayback() }
        }
    }
}
