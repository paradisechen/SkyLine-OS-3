// skylineOS 2 — InfoScreen.qml (Nintendo Online & News: Image-Rich Feeds, 4-Way Navigation, Reliable Exit & Non-Colliding Footer)
import QtQuick 2.12

FocusScope {
    id: infoRoot
    anchors.fill: parent

    property string sectionMode: "nso" // "nso" = Nintendo Online, "news" = News
    property int catIndex: 0
    property string focusZone: "grid" // "cats" | "grid" | "reader"
    property int selectedIndex: 0
    property int gridColumns: 2
    property bool isLoading: false
    property string fetchError: ""

    // Fullscreen Article Reader State
    property bool readerOpen: false
    property var activeArticle: ({})
    property string readerFullBody: ""
    property string readerFullImage: ""
    property bool readerFetching: false
    property real readerFontScale: 1.0
    property string readerVideoUrl: ""
    property bool videoFullscreen: false
    property var videoViewObj: null

    property bool isDarkPage: (settings.appearanceMode === "Dark") || (settings.appearanceMode === "Auto" && settings.darkMode === "Yes")
    property color pageBg: isDarkPage ? "#16181D" : "#EFEFEF"
    property color cardBg: isDarkPage ? "#23262F" : "#FFFFFF"
    property color pillBg: isDarkPage ? "#2B2F3A" : "#E5E7EB"
    property color textMain: isDarkPage ? "#F3F4F6" : "#181B20"
    property color textMuted: isDarkPage ? "#B0B7C3" : "#4B5563"
    property color dividerColor: isDarkPage ? "#323642" : "#D1D5DB"

    // Nintendo Online Categories (Photo-rich Nintendo outlets + Official Nintendo YouTube videos)
    property var nsoCategories: [
        { id: "nintendo", label: "Nintendo", color: "#E60012", urls: [
            "https://www.nintendolife.com/feeds/latest",
            "https://www.youtube.com/feeds/videos.xml?channel_id=UCGIY_O-8vW4rfX98KlMkvRg",
            "https://nintendowire.com/feed/",
            "https://nintendoeverything.com/feed/"
        ]},
        { id: "action", label: "Action", color: "#EA580C", urls: [
            "https://www.gematsu.com/feed",
            "https://www.eurogamer.net/feed",
            "https://www.polygon.com/rss/index.xml",
            "https://nintendowire.com/feed/"
        ]},
        { id: "rpg", label: "RPG", color: "#7C3AED", urls: [
            "https://www.nintendolife.com/feeds/latest",
            "https://www.gematsu.com/feed",
            "https://www.eurogamer.net/feed"
        ]},
        { id: "adventure", label: "Adventure", color: "#0D9488", urls: [
            "https://www.nintendolife.com/feeds/reviews",
            "https://www.polygon.com/rss/index.xml",
            "https://www.eurogamer.net/feed"
        ]},
        { id: "indie", label: "Indie", color: "#2563EB", urls: [
            "https://www.nintendolife.com/feeds/news",
            "https://indiegamesplus.com/feed",
            "https://www.rockpapershotgun.com/feed"
        ]},
        { id: "multiplayer", label: "Multiplayer", color: "#DB2777", urls: [
            "https://www.gamespot.com/feeds/news/",
            "https://nintendoeverything.com/feed/",
            "https://www.nintendolife.com/feeds/latest"
        ]}
    ]

    // General News Categories (Latest News, El Nuevo Dia, Puerto Rico, r/PuertoRico, Politics, Economy, Tech)
    property var newsCategories: [
        { id: "latest", label: "Latest News", color: "#E60012", urls: [
            "https://feeds.bbci.co.uk/news/world/rss.xml",
            "https://feeds.npr.org/1001/rss.xml"
        ]},
        { id: "elnuevodia", label: "El Nuevo Día", color: "#0284C7", urls: [
            "https://www.elnuevodia.com/arc/outboundfeeds/rss/?outputType=xml",
            "https://www.primerahora.com/arc/outboundfeeds/rss/?outputType=xml"
        ]},
        { id: "puerto_rico", label: "Puerto Rico", color: "#2563EB", urls: [
            "https://www.metro.pr/arc/outboundfeeds/rss/?outputType=xml",
            "https://wipr.pr/feed/",
            "https://www.elnuevodia.com/arc/outboundfeeds/rss/?outputType=xml",
            "https://www.primerahora.com/arc/outboundfeeds/rss/?outputType=xml"
        ]},
        { id: "r_puertorico", label: "r/PuertoRico", color: "#EA580C", urls: [
            "https://www.reddit.com/r/PuertoRico/hot.json?limit=18",
            "https://news.google.com/rss/search?q=site:reddit.com/r/PuertoRico&hl=en-US&gl=US&ceid=US:en",
            "https://www.reddit.com/r/PuertoRico/.rss"
        ]},
        { id: "politics", label: "Politics", color: "#DC2626", urls: [
            "https://feeds.npr.org/1014/rss.xml",
            "https://feeds.bbci.co.uk/news/politics/rss.xml"
        ]},
        { id: "economy", label: "Economy", color: "#059669", urls: [
            "https://feeds.bbci.co.uk/news/business/rss.xml",
            "https://feeds.npr.org/1006/rss.xml"
        ]},
        { id: "tech", label: "Tech", color: "#7C3AED", urls: [
            "https://www.theverge.com/rss/index.xml",
            "https://feeds.arstechnica.com/arstechnica/index"
        ]}
    ]

    property var activeCategories: sectionMode === "nso" ? nsoCategories : newsCategories
    property var nsoFallbackCovers: [
        "https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/m/mario-kart-8-deluxe-switch/hero",
        "https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-tears-of-the-kingdom-switch/hero",
        "https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/m/metroid-prime-remastered-switch/hero",
        "https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-mario-bros-wonder-switch/hero"
    ]

    ListModel { id: feedModel }
    ListModel { id: readerBlocksModel }

    function openSection(modeStr) {
        sectionMode = (modeStr === "news") ? "news" : "nso";
        readerOpen = false;
        catIndex = 0;
        focusZone = "grid";
        selectedIndex = 0;
        loadCategory(0);
        infoRoot.forceActiveFocus();
        Qt.callLater(function() { infoRoot.forceActiveFocus(); });
    }

    function decodeEntities(str) {
        if (!str) return "";
        return String(str)
            .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;|&apos;/g, "'")
            .replace(/&nbsp;/g, " ")
            .replace(/&#(\d+);/g, function(_, n) { return String.fromCharCode(parseInt(n, 10)); });
    }

    function cleanHtml(html) {
        return decodeEntities(String(html || "")
            .replace(/<script[\s\S]*?<\/script>/gi, " ")
            .replace(/<style[\s\S]*?<\/style>/gi, " ")
            .replace(/<[^>]+>/g, " "))
            .replace(/\s+/g, " ")
            .trim();
    }

    function isVideoAssetUrl(url) {
        var u = String(url || "").toLowerCase();
        return /youtube\.com|youtu\.be|vimeo\.com|\.mp4|\.webm|\.m3u8|\.swf/.test(u);
    }

    function normalizeImageUrl(raw) {
        var u = decodeEntities(String(raw || "").trim());
        if (u.indexOf("//") === 0) u = "https:" + u;
        if (u.indexOf("http://") !== 0 && u.indexOf("https://") !== 0) return "";
        if (/spacer|1x1|pixel\.gif|doubleclick|blank\.png/i.test(u)) return "";
        if (isVideoAssetUrl(u)) return "";
        return u;
    }

    function extractYouTubeId(text) {
        if (!text) return "";
        var ytTag = String(text).match(/<yt:videoId>([A-Za-z0-9_-]{11})<\/yt:videoId>/i);
        if (ytTag && ytTag[1]) return ytTag[1];
        var ytEmbed = String(text).match(/youtube\.com\/(?:embed\/|watch\?v=|shorts\/)([A-Za-z0-9_-]{11})/i)
                   || String(text).match(/youtu\.be\/([A-Za-z0-9_-]{11})/i);
        return (ytEmbed && ytEmbed[1]) ? ytEmbed[1] : "";
    }

    function extractXmlTag(block, tag) {
        var re = new RegExp("<" + tag + "(?:\\s[^>]*)?>([\\s\\S]*?)<\\/" + tag + ">", "i");
        var m = block.match(re);
        return m ? m[1] : "";
    }

    function extractImage(block, rawHtml) {
        var patterns = [
            /<media:thumbnail[^>]+url=["']([^"']+)["']/i,
            /<enclosure[^>]+type=["']image\/[^"']+["'][^>]+url=["']([^"']+)["']/i,
            /<enclosure[^>]+url=["']([^"']+)["'][^>]+type=["']image\/[^"']+["']/i,
            /<itunes:image[^>]+href=["']([^"']+)["']/i,
            /<media:content[^>]+url=["']([^"']+)["']/i,
            /<enclosure[^>]+url=["']([^"']+)["']/i,
            /<img[^>]+data-src=["']([^"']+)["']/i,
            /<img[^>]+src=["']([^"']+)["']/i
        ];
        var sources = [block || "", rawHtml || ""];
        for (var s = 0; s < sources.length; s++) {
            var src = sources[s];
            for (var p = 0; p < patterns.length; p++) {
                var re = new RegExp(patterns[p].source, "gi");
                var m;
                while ((m = re.exec(src)) !== null) {
                    if (m[1]) {
                        var norm = normalizeImageUrl(m[1]);
                        if (norm !== "") return norm;
                    }
                }
            }
        }
        var ytId = extractYouTubeId((block || "") + " " + (rawHtml || ""));
        if (ytId !== "") return "https://i.ytimg.com/vi/" + ytId + "/hqdefault.jpg";
        return "";
    }

    function parseFeedXml(xmlText, sourceLabel, catColor) {
        var out = [];
        var itemRe = /<(item|entry)\b[\s\S]*?<\/\1>/gi;
        var match;
        while ((match = itemRe.exec(xmlText)) !== null && out.length < 18) {
            var blk = match[0];
            var title = cleanHtml(extractXmlTag(blk, "title"));
            if (!title) continue;
            var link = "";
            var lm = blk.match(/<link[^>]+href=["']([^"']+)["']/i);
            if (lm && lm[1]) link = decodeEntities(lm[1].trim());
            else link = decodeEntities(extractXmlTag(blk, "link")).replace(/<[^>]+>/g, "").trim();

            var rawContent = extractXmlTag(blk, "content:encoded") || extractXmlTag(blk, "media:description") || extractXmlTag(blk, "content") || extractXmlTag(blk, "description") || extractXmlTag(blk, "summary");
            var descText = cleanHtml(rawContent);
            var imgUrl = extractImage(blk, rawContent);
            var ytVidId = extractYouTubeId(blk + " " + rawContent);
            var hasVid = ytVidId !== "" || /medium=["']video["']/i.test(blk);
            var vidUrl = ytVidId !== "" ? ("https://www.youtube.com/embed/" + ytVidId + "?autoplay=1&vq=small&playsinline=1") : "";
            var pubRaw = cleanHtml(extractXmlTag(blk, "pubDate") || extractXmlTag(blk, "published") || extractXmlTag(blk, "updated"));
            var dateStr = pubRaw ? pubRaw.slice(0, 16) : "Latest";

            out.push({
                title: title,
                desc: descText !== "" ? descText : (title + " — Open to read full story."),
                link: link,
                image: imgUrl,
                hasVideo: hasVid,
                videoUrl: vidUrl,
                source: sourceLabel,
                date: dateStr,
                catColor: catColor
            });
        }
        return out;
    }

    function parseRedditJson(jsonText, sourceLabel, catColor) {
        var out = [];
        try {
            var parsed = JSON.parse(jsonText);
            var children = (parsed && parsed.data && parsed.data.children) ? parsed.data.children : [];
            for (var i = 0; i < children.length && out.length < 18; i++) {
                var d = children[i] ? children[i].data : null;
                if (!d || !d.title) continue;
                var img = "";
                if (d.preview && d.preview.images && d.preview.images[0] && d.preview.images[0].source && d.preview.images[0].source.url) {
                    img = normalizeImageUrl(d.preview.images[0].source.url);
                }
                if (!img && d.thumbnail && String(d.thumbnail).indexOf("http") === 0) {
                    img = normalizeImageUrl(d.thumbnail);
                }
                var body = d.selftext ? cleanHtml(d.selftext) : "";
                var link = d.permalink ? ("https://www.reddit.com" + d.permalink) : (d.url || "https://www.reddit.com/r/PuertoRico/");
                out.push({
                    title: cleanHtml(d.title),
                    desc: body !== "" ? body : ("Community discussion on " + sourceLabel + " — Open to read replies."),
                    link: link,
                    image: img,
                    hasVideo: !!d.is_video,
                    videoUrl: d.is_video && d.url ? String(d.url) : "",
                    source: sourceLabel,
                    date: "Hot",
                    catColor: catColor
                });
            }
        } catch (e) {}
        return out;
    }

    function prefetchMissingImages(catId) {
        var maxHydrate = Math.min(8, feedModel.count);
        for (var i = 0; i < maxHydrate; i++) {
            var item = feedModel.get(i);
            if (!item || (item.image && item.image !== "") || !item.link || item.link.indexOf("http") !== 0) continue;
            (function(rowIdx, targetUrl, expectedCat) {
                var req = new XMLHttpRequest();
                req.onreadystatechange = function() {
                    if (req.readyState !== XMLHttpRequest.DONE) return;
                    var curCatObj = infoRoot.activeCategories[infoRoot.catIndex];
                    if (!curCatObj || curCatObj.id !== expectedCat) return;
                    if (req.status >= 200 && req.status < 400 && req.responseText && rowIdx < feedModel.count) {
                        var og = req.responseText.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i)
                              || req.responseText.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i)
                              || req.responseText.match(/<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']/i);
                        if (og && og[1]) {
                            var norm = infoRoot.normalizeImageUrl(og[1]);
                            if (norm !== "") feedModel.setProperty(rowIdx, "image", norm);
                        }
                    }
                };
                req.open("GET", targetUrl);
                req.setRequestHeader("Accept", "text/html");
                req.send();
            })(i, item.link, catId);
        }
    }

    function fetchNsoCompanionVideos(catObj) {
        if (sectionMode !== "nso") return;
        var expectedMode = sectionMode;
        var expectedCatIdx = catIndex;
        var xhrY = new XMLHttpRequest();
        xhrY.onreadystatechange = function() {
            if (xhrY.readyState !== XMLHttpRequest.DONE) return;
            if (infoRoot.sectionMode !== expectedMode || infoRoot.catIndex !== expectedCatIdx) return;
            if (xhrY.status >= 200 && xhrY.status < 400 && xhrY.responseText) {
                var vids = parseFeedXml(xhrY.responseText, "Nintendo YouTube", catObj.color);
                for (var i = 0; i < Math.min(4, vids.length); i++) {
                    var v = vids[i];
                    var insertAt = Math.min(feedModel.count, i * 2 + 1);
                    feedModel.insert(insertAt, v);
                }
            }
        };
        xhrY.open("GET", "https://www.youtube.com/feeds/videos.xml?channel_id=UCGIY_O-8vW4rfX98KlMkvRg");
        xhrY.send();
    }

    function fetchFromUrls(urls, idx, catObj) {
        if (idx >= urls.length) {
            isLoading = false;
            fetchError = tr("Unable to reach live news feed. Press X Refresh to retry.");
            return;
        }
        var url = urls[idx];
        var expectedMode = sectionMode;
        var expectedCatIdx = catIndex;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (infoRoot.sectionMode !== expectedMode || infoRoot.catIndex !== expectedCatIdx) return;
            if (xhr.status >= 200 && xhr.status < 400 && xhr.responseText) {
                var txt = String(xhr.responseText).trim();
                var parsed = (url.indexOf(".json") !== -1 || txt.indexOf("{") === 0)
                    ? parseRedditJson(txt, catObj.label, catObj.color)
                    : parseFeedXml(txt, catObj.label, catObj.color);
                if (parsed.length > 0) {
                    feedModel.clear();
                    for (var j = 0; j < parsed.length; j++) {
                        if (sectionMode === "nso" && (!parsed[j].image || parsed[j].image === "")) {
                            parsed[j].image = nsoFallbackCovers[j % nsoFallbackCovers.length];
                        }
                        feedModel.append(parsed[j]);
                    }
                    isLoading = false;
                    selectedIndex = 0;
                    prefetchMissingImages(catObj.id);
                    if (sectionMode === "nso" && url.indexOf("youtube.com") < 0) fetchNsoCompanionVideos(catObj);
                    return;
                }
            }
            fetchFromUrls(urls, idx + 1, catObj);
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("Accept", "application/json, application/rss+xml, application/atom+xml, application/xml, text/xml");
        xhr.send();
    }

    function ensureCategoryVisible() {
        var item = catRepeater.itemAt(catIndex);
        if (!item) return;
        var x1 = item.x;
        var x2 = item.x + item.width;
        if (x1 < catFlick.contentX) catFlick.contentX = Math.max(0, x1 - vpx(12));
        else if (x2 > catFlick.contentX + catFlick.width) catFlick.contentX = Math.min(Math.max(0, catFlick.contentWidth - catFlick.width), x2 - catFlick.width + vpx(12));
    }

    function loadCategory(idx) {
        var cats = activeCategories;
        if (idx < 0 || idx >= cats.length) return;
        catIndex = idx;
        selectedIndex = 0;
        fetchError = "";
        isLoading = true;
        feedModel.clear();
        ensureCategoryVisible();
        var catObj = cats[idx];
        fetchFromUrls(catObj.urls, 0, catObj);
    }

    function fetchFullArticleStory(articleUrl) {
        if (!articleUrl || articleUrl.indexOf("http") !== 0) return;
        readerFetching = true;
        var target = articleUrl;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            readerFetching = false;
            if (xhr.status >= 200 && xhr.status < 400 && xhr.responseText && activeArticle.link === target) {
                var html = xhr.responseText;
                if (!readerFullImage) {
                    var og = html.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i)
                          || html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i)
                          || html.match(/<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']/i);
                    if (og && og[1]) {
                        var norm = normalizeImageUrl(og[1]);
                        if (norm !== "") readerFullImage = norm;
                    }
                }
                var bodyNoScript = html.replace(/<script[\s\S]*?<\/script>/gi, "").replace(/<style[\s\S]*?<\/style>/gi, "");
                var blockRe = /<p\b[^>]*>([\s\S]*?)<\/p>/gi;
                var blocks = [];
                var paras = [];
                var m;
                while ((m = blockRe.exec(bodyNoScript)) !== null && blocks.length < 28) {
                    var pt = cleanHtml(m[1]);
                    if (pt.length >= 42 && !/cookie|subscribe|sign in|privacy policy|advertisement/i.test(pt)) {
                        paras.push(pt);
                        blocks.push({ kind: "text", text: pt, imgUrl: "" });
                    }
                }
                if (blocks.length > 0) {
                    readerBlocksModel.clear();
                    for (var bi = 0; bi < blocks.length; bi++) readerBlocksModel.append(blocks[bi]);
                }
                if (paras.length >= 1) {
                    readerFullBody = paras.join("\n\n");
                }
                if (readerVideoUrl === "") {
                    var foundYt = extractYouTubeId(html);
                    if (foundYt !== "") {
                        readerVideoUrl = "https://www.youtube.com/embed/" + foundYt + "?autoplay=1&mute=0&playsinline=1&rel=0";
                    }
                }
            }
        };
        xhr.open("GET", target);
        xhr.setRequestHeader("Accept", "text/html");
        xhr.send();
    }

    function openArticleAt(idx) {
        if (idx < 0 || idx >= feedModel.count) return;
        selectedIndex = idx;
        newsGrid.currentIndex = idx;
        var item = feedModel.get(idx);
        activeArticle = {
            title: item.title,
            desc: item.desc,
            link: item.link,
            image: item.image,
            hasVideo: !!item.hasVideo || (!!item.videoUrl && item.videoUrl !== ""),
            videoUrl: item.videoUrl || "",
            source: item.source,
            date: item.date,
            catColor: item.catColor
        };
        readerFullImage = item.image || "";
        readerFullBody = item.desc || "";
        readerVideoUrl = item.videoUrl || "";
        readerBlocksModel.clear();
        if (readerFullBody !== "") readerBlocksModel.append({ kind: "text", text: readerFullBody, imgUrl: "" });
        readerOpen = true;
        videoFullscreen = false;
        focusZone = "reader";
        readerFlick.contentY = 0;
        selectSfx.play();
        fetchFullArticleStory(item.link);
        Qt.callLater(function() { readerOverlay.forceActiveFocus(); });
    }

    function nextArticle() {
        if (feedModel.count <= 1) return;
        navSound.play();
        openArticleAt((selectedIndex + 1) % feedModel.count);
    }

    function prevArticle() {
        if (feedModel.count <= 1) return;
        navSound.play();
        openArticleAt((selectedIndex - 1 + feedModel.count) % feedModel.count);
    }

    function cycleReaderTextSize() {
        navSound.play();
        if (readerFontScale < 1.15) readerFontScale = 1.25;
        else if (readerFontScale < 1.4) readerFontScale = 1.5;
        else readerFontScale = 1.0;
    }

    function mountFullscreenNewsVideoUrl(targetVideoUrl) {
        if (videoViewObj) {
            try { videoViewObj.destroy(); } catch (e) {}
            videoViewObj = null;
        }
        var cleanUrl = String(targetVideoUrl || "").replace("youtube-nocookie.com/embed/", "youtube.com/embed/");
        if (cleanUrl.indexOf("youtube.com/embed/") >= 0) {
            if (cleanUrl.indexOf("autoplay=1") < 0) cleanUrl += (cleanUrl.indexOf("?") >= 0 ? "&" : "?") + "autoplay=1";
            if (cleanUrl.indexOf("playsinline=1") < 0) cleanUrl += "&playsinline=1";
            if (cleanUrl.indexOf("rel=0") < 0) cleanUrl += "&rel=0";
        }
        if (/\.(mp4|webm|m4v)(\?|$)/i.test(cleanUrl)) {
            try {
                var qml = 'import QtQuick 2.12; import QtMultimedia 5.9; Video { anchors.fill: parent; fillMode: VideoOutput.PreserveAspectFit; autoPlay: true; muted: false; volume: 1.0; source: "' + cleanUrl.replace(/"/g, "") + '" }';
                videoViewObj = Qt.createQmlObject(qml, newsVideoHost, "newsFullMp4");
                return;
            } catch (e0) {}
        }
        var cands = [
            "import QtQuick 2.12; import QtWebView 1.1; WebView { x: 0; y: 0; width: parent.width; height: parent.height }",
            "import QtQuick 2.12; import QtWebView 1.0; WebView { x: 0; y: 0; width: parent.width; height: parent.height }",
            "import QtQuick 2.12; import QtWebView 1.15; WebView { x: 0; y: 0; width: parent.width; height: parent.height }",
            "import QtQuick 2.12; import QtWebEngine 1.8; WebEngineView { x: 0; y: 0; width: parent.width; height: parent.height }"
        ];
        for (var i = 0; i < cands.length; i++) {
            try {
                var o = Qt.createQmlObject(cands[i], newsVideoHost, "newsFullVid_" + i);
                if (o) {
                    videoViewObj = o;
                    if (cleanUrl.indexOf("youtube.com/embed/") >= 0 && typeof o.loadHtml === "function") {
                        var safeSrc = cleanUrl.replace(/"/g, "&quot;");
                        o.loadHtml('<!doctype html><html><body style="margin:0;padding:0;background:#000;overflow:hidden;"><iframe style="position:fixed;inset:0;width:100vw;height:100vh;border:0;" src="' + safeSrc + '" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen" allowfullscreen></iframe></body></html>', "https://www.youtube.com/");
                    } else {
                        o.url = cleanUrl;
                    }
                    return;
                }
            } catch (e) {}
        }
    }

    function openNewsVideoFullscreen() {
        var v = readerVideoUrl || (activeArticle ? activeArticle.videoUrl : "");
        videoFullscreen = true;
        selectSfx.play();
        if (v && v !== "") {
            mountFullscreenNewsVideoUrl(v);
            return;
        }
        var q = encodeURIComponent(String(activeArticle.title || "Nintendo Switch 2") + " trailer");
        var xhrY = new XMLHttpRequest();
        xhrY.onreadystatechange = function() {
            if (xhrY.readyState !== XMLHttpRequest.DONE) return;
            if (!videoFullscreen) return;
            var resolved = "";
            if (xhrY.status >= 200 && xhrY.status < 400 && xhrY.responseText) {
                var ym = xhrY.responseText.match(/"videoId":"([A-Za-z0-9_-]{11})"/);
                if (ym && ym[1]) resolved = "https://www.youtube.com/embed/" + ym[1] + "?autoplay=1&mute=0&playsinline=1&rel=0";
            }
            if (resolved === "") resolved = "https://www.youtube.com/embed/3pE23YTYEZM?autoplay=1&mute=0&playsinline=1&rel=0";
            readerVideoUrl = resolved;
            mountFullscreenNewsVideoUrl(resolved);
        };
        xhrY.open("GET", "https://www.youtube.com/results?search_query=" + q);
        xhrY.send();
    }

    function closeNewsVideoFullscreen() {
        videoFullscreen = false;
        if (videoViewObj) {
            try { videoViewObj.destroy(); } catch (e) {}
            videoViewObj = null;
        }
        backSfx.play();
        readerOverlay.forceActiveFocus();
    }

    function closeReader() {
        readerOpen = false;
        focusZone = "grid";
        backSfx.play();
        infoRoot.forceActiveFocus();
        Qt.callLater(function() { infoRoot.forceActiveFocus(); });
    }

    function exitScreen() {
        backSfx.play();
        showHomeScreen();
    }

    function openExternalArticle() {
        if (!activeArticle || !activeArticle.link) return;
        selectSfx.play();
        if (settings.browserMode === "chrome") Qt.openUrlExternally(activeArticle.link);
        else openInThemeBrowser(activeArticle.link);
    }

    function isBackEvent(event) {
        return api.keys.isCancel(event) || event.key === Qt.Key_Escape || event.key === Qt.Key_Backspace || event.key === Qt.Key_B;
    }

    onVisibleChanged: {
        if (visible) {
            if (feedModel.count === 0 && !isLoading) loadCategory(catIndex);
            infoRoot.forceActiveFocus();
            Qt.callLater(function() { infoRoot.forceActiveFocus(); });
        }
    }

    Keys.onLeftPressed: {
        if (readerOpen) return;
        navSound.play();
        if (focusZone === "cats") {
            var prevCat = (catIndex - 1 + activeCategories.length) % activeCategories.length;
            loadCategory(prevCat);
        } else if (feedModel.count > 0) {
            selectedIndex = (selectedIndex - 1 + feedModel.count) % feedModel.count;
            newsGrid.currentIndex = selectedIndex;
            newsGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
        }
    }

    Keys.onRightPressed: {
        if (readerOpen) return;
        navSound.play();
        if (focusZone === "cats") {
            var nextCat = (catIndex + 1) % activeCategories.length;
            loadCategory(nextCat);
        } else if (feedModel.count > 0) {
            selectedIndex = (selectedIndex + 1) % feedModel.count;
            newsGrid.currentIndex = selectedIndex;
            newsGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
        }
    }

    Keys.onUpPressed: {
        if (readerOpen) return;
        navSound.play();
        if (focusZone === "grid") {
            if (selectedIndex < gridColumns) {
                focusZone = "cats";
                ensureCategoryVisible();
            } else {
                selectedIndex = Math.max(0, selectedIndex - gridColumns);
                newsGrid.currentIndex = selectedIndex;
                newsGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
            }
        }
    }

    Keys.onDownPressed: {
        if (readerOpen) return;
        navSound.play();
        if (focusZone === "cats") {
            focusZone = "grid";
            selectedIndex = 0;
            newsGrid.currentIndex = 0;
            newsGrid.positionViewAtIndex(0, GridView.Contain);
        } else if (feedModel.count > 0) {
            selectedIndex = Math.min(feedModel.count - 1, selectedIndex + gridColumns);
            newsGrid.currentIndex = selectedIndex;
            newsGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
        }
    }

    Keys.onBackPressed: {
        event.accepted = true;
        if (videoFullscreen) closeNewsVideoFullscreen();
        readerOpen = false;
        focusZone = "grid";
        exitScreen();
    }

    Keys.onEscapePressed: {
        event.accepted = true;
        if (videoFullscreen) closeNewsVideoFullscreen();
        else if (readerOpen) closeReader();
        else exitScreen();
    }
    Keys.onReleased: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function")
            root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
    }

    Keys.onPressed: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
        if (readerOpen) {
            if (isBackEvent(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (videoFullscreen) closeNewsVideoFullscreen();
                else closeReader();
            }
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (focusZone === "cats") {
                focusZone = "grid";
                selectedIndex = 0;
                newsGrid.currentIndex = 0;
                selectSfx.play();
            } else {
                openArticleAt(selectedIndex);
            }
        } else if (isBackEvent(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (focusZone === "cats") {
                focusZone = "grid";
                backSfx.play();
            } else {
                exitScreen();
            }
        } else if ((api.keys.isFilters(event) || event.key === Qt.Key_X) && !event.isAutoRepeat) {
            event.accepted = true;
            navSound.play();
            loadCategory(catIndex);
        } else if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            navSound.play();
            loadCategory((catIndex + 1) % activeCategories.length);
        } else if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            navSound.play();
            loadCategory((catIndex - 1 + activeCategories.length) % activeCategories.length);
        }
    }

    Rectangle { anchors.fill: parent; color: infoRoot.pageBg }

    // Top Header
    Item {
        id: infoHeader
        anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.108)

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: vpx(14)
            Image {
                width: vpx(30); height: vpx(30)
                source: infoRoot.sectionMode === "nso" ? "../assets/images/navigation/ns2_online.svg" : "../assets/images/navigation/ns2_news.svg"
                fillMode: Image.PreserveAspectFit; smooth: true
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: infoRoot.sectionMode === "nso" ? tr("Nintendo Online") : tr("News")
                color: infoRoot.textMain
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.042 * infoRoot.readerFontScale * fontScale)
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(16)
            Text {
                visible: infoRoot.isLoading
                text: tr("Updating live feed...")
                color: "#E60012"
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.022)
                font.bold: true
            }
            Text {
                text: "L / R · Category"
                color: infoRoot.textMuted
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.020)
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: infoRoot.dividerColor }
    }

    // Horizontal Scrollable Category Bookmarks Bar (4-Way Controllable)
    Flickable {
        id: catFlick
        anchors { top: infoHeader.bottom; left: parent.left; right: parent.right; topMargin: vpx(10); leftMargin: screenmargin; rightMargin: screenmargin }
        height: vpx(46)
        clip: true
        contentWidth: catStrip.implicitWidth + vpx(16)
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds

        Row {
            id: catStrip
            height: parent.height
            spacing: vpx(10)

            Repeater {
                id: catRepeater
                model: infoRoot.activeCategories
                delegate: Rectangle {
                    property bool active: index === infoRoot.catIndex
                    property bool focusedCat: infoRoot.focusZone === "cats" && active
                    width: catTxt.implicitWidth + vpx(32); height: vpx(38); radius: vpx(19)
                    anchors.verticalCenter: parent.verticalCenter
                    color: active ? modelData.color : infoRoot.pillBg
                    border.width: focusedCat ? vpx(3.5) : (active ? 0 : 1)
                    border.color: focusedCat ? (infoRoot.isDarkPage ? "#FFFFFF" : "#111827") : infoRoot.dividerColor
                    scale: focusedCat ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120 } }

                    Text {
                        id: catTxt
                        anchors.centerIn: parent
                        text: modelData.label
                        color: parent.active ? "#FFFFFF" : infoRoot.textMain
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.022)
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            navSound.play();
                            infoRoot.focusZone = "cats";
                            infoRoot.loadCategory(index);
                        }
                    }
                }
            }
        }
    }

    // News Cards Grid (2x2)
    GridView {
        id: newsGrid
        anchors {
            top: catFlick.bottom; bottom: infoFooter.top; left: parent.left; right: parent.right
            topMargin: vpx(10); bottomMargin: vpx(10); leftMargin: screenmargin; rightMargin: screenmargin
        }
        clip: true
        cellWidth: Math.floor(width / infoRoot.gridColumns)
        cellHeight: Math.round(height / 2)
        model: feedModel
        currentIndex: infoRoot.selectedIndex

        delegate: Item {
            width: newsGrid.cellWidth
            height: newsGrid.cellHeight
            property bool selected: infoRoot.focusZone === "grid" && index === infoRoot.selectedIndex

            Rectangle {
                anchors { fill: parent; margins: vpx(8) }
                radius: vpx(14)
                color: infoRoot.cardBg
                clip: true
                scale: selected ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                // Top Image Area
                Item {
                    id: cardImgWrap
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: Math.round(parent.height * 0.48)

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: model.catColor || "#E60012" }
                            GradientStop { position: 1.0; color: "#111827" }
                        }
                        Image {
                            visible: cardImg.status !== Image.Ready
                            anchors.centerIn: parent
                            width: vpx(48); height: vpx(48)
                            source: infoRoot.sectionMode === "nso" ? "../assets/images/navigation/ns2_online.svg" : "../assets/images/navigation/ns2_news.svg"
                            fillMode: Image.PreserveAspectFit; opacity: 0.9
                        }
                    }

                    Image {
                        id: cardImg
                        anchors.fill: parent
                        source: model.image || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: status === Image.Ready
                    }

                    Rectangle {
                        anchors { top: parent.top; left: parent.left; topMargin: vpx(8); leftMargin: vpx(8) }
                        width: srcBadge.implicitWidth + vpx(16); height: vpx(24); radius: vpx(6)
                        color: "#CC000000"
                        Text {
                            id: srcBadge
                            anchors.centerIn: parent
                            text: model.source + " · " + model.date
                            color: "#FFFFFF"
                            font.family: titleFont.name
                            font.pixelSize: vpx(12)
                            font.bold: true
                        }
                    }

                    Rectangle {
                        visible: !!model.hasVideo
                        anchors { top: parent.top; right: parent.right; topMargin: vpx(8); rightMargin: vpx(8) }
                        width: vpx(68); height: vpx(24); radius: vpx(6)
                        color: "#E60012"
                        Text {
                            anchors.centerIn: parent
                            text: "▶ VIDEO"
                            color: "#FFFFFF"
                            font.family: titleFont.name
                            font.pixelSize: vpx(11)
                            font.bold: true
                        }
                    }
                }

                // Bigger Readable Card Title & Short Summary Preview
                Column {
                    anchors {
                        top: cardImgWrap.bottom; bottom: parent.bottom; left: parent.left; right: parent.right
                        margins: vpx(12); topMargin: vpx(8)
                    }
                    spacing: vpx(4)

                    Text {
                        width: parent.width
                        text: model.title
                        color: infoRoot.textMain
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.031)
                        font.bold: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        lineHeight: 1.15
                    }
                    Text {
                        width: parent.width
                        text: model.desc
                        color: infoRoot.textMuted
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.019)
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        lineHeight: 1.25
                    }
                }

                // Selection border in front
                Rectangle {
                    anchors.fill: parent
                    radius: vpx(14)
                    color: "transparent"
                    border.width: selected ? vpx(4) : 1
                    border.color: selected ? "#E60012" : infoRoot.dividerColor
                    z: 20
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        infoRoot.focusZone = "grid";
                        infoRoot.selectedIndex = index;
                        infoRoot.openArticleAt(index);
                    }
                }
            }
        }
    }

    Text {
        visible: !infoRoot.isLoading && feedModel.count === 0 && infoRoot.fetchError !== ""
        anchors.centerIn: newsGrid
        text: infoRoot.fetchError
        color: infoRoot.textMuted
        font.family: titleFont.name
        font.pixelSize: Math.round(screenheight * 0.024)
    }

    // Sticky Bottom Footer (Clean side-by-side explicit widths so X Refresh never pushes B offscreen)
    Item {
        id: infoFooter
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.095)
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: infoRoot.dividerColor }
        Image { anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(18)

            Item {
                width: vpx(124); height: vpx(38); anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    anchors.fill: parent; radius: vpx(19)
                    color: infoRoot.pillBg; border.width: 1; border.color: infoRoot.dividerColor
                }
                Row {
                    anchors.centerIn: parent; spacing: vpx(8)
                    Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: infoRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "X"; color: infoRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    }
                    Text { text: tr("Refresh"); color: infoRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: { navSound.play(); infoRoot.loadCategory(infoRoot.catIndex); } }
            }

            Item {
                width: vpx(90); height: vpx(38); anchors.verticalCenter: parent.verticalCenter
                Row {
                    anchors.centerIn: parent; spacing: vpx(8)
                    Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: infoRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "A"; color: infoRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                    }
                    Text { text: tr("Read"); color: infoRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: infoRoot.openArticleAt(infoRoot.selectedIndex) }
            }

            Item {
                width: vpx(90); height: vpx(38); anchors.verticalCenter: parent.verticalCenter
                Row {
                    anchors.centerIn: parent; spacing: vpx(8)
                    Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: infoRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "B"; color: infoRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                    }
                    Text { text: tr("Back"); color: infoRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: infoRoot.exitScreen() }
            }
        }
    }

    // FULLSCREEN ARTICLE READER OVERLAY
    FocusScope {
        id: readerOverlay
        anchors.fill: parent
        visible: infoRoot.readerOpen
        focus: infoRoot.readerOpen
        z: 60

        Keys.onUpPressed: {
            readerFlick.contentY = Math.max(0, readerFlick.contentY - vpx(105));
        }
        Keys.onDownPressed: {
            var maxY = Math.max(0, readerFlick.contentHeight - readerFlick.height);
            readerFlick.contentY = Math.min(maxY, readerFlick.contentY + vpx(105));
        }
        Keys.onBackPressed: {
            event.accepted = true;
            if (infoRoot.videoFullscreen) infoRoot.closeNewsVideoFullscreen();
            infoRoot.readerOpen = false;
            infoRoot.focusZone = "grid";
            infoRoot.exitScreen();
        }
        Keys.onEscapePressed: {
            event.accepted = true;
            if (infoRoot.videoFullscreen) infoRoot.closeNewsVideoFullscreen();
            else infoRoot.closeReader();
        }
        Keys.onReleased: {
            if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function")
                root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
        }
        Keys.onPressed: {
            if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) {
                event.accepted = true;
                return;
            }
            if (infoRoot.videoFullscreen) {
                if (infoRoot.isBackEvent(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    infoRoot.closeNewsVideoFullscreen();
                }
                return;
            }
            if (infoRoot.isBackEvent(event) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.closeReader();
            } else if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.prevArticle();
            } else if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.nextArticle();
            } else if ((api.keys.isFilters(event) || api.keys.isDetails(event) || event.key === Qt.Key_X || event.key === Qt.Key_Y) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.cycleReaderTextSize();
            } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (infoRoot.activeArticle.hasVideo || infoRoot.readerVideoUrl !== "") {
                    infoRoot.openNewsVideoFullscreen();
                } else {
                    infoRoot.openExternalArticle();
                }
            }
        }

        Rectangle { anchors.fill: parent; color: infoRoot.pageBg }

        // Unified Scrollable Reader: Top Hero Photo + Headline + Paragraphs + Inline Small Photos Move Together
        Flickable {
            id: readerFlick
            anchors {
                top: parent.top; bottom: readerFooter.top; left: parent.left; right: parent.right
            }
            contentWidth: width
            contentHeight: readerStoryWrap.implicitHeight + vpx(28)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Behavior on contentY { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

            Column {
                id: readerStoryWrap
                width: readerFlick.width
                spacing: vpx(18)

                // Top Half Photo (46% height) inside the scroll view so it moves up seamlessly when scrolling text
                Item {
                    id: readerPhotoBox
                    width: parent.width
                    height: Math.round(readerOverlay.height * 0.46)
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: infoRoot.activeArticle.catColor || "#E60012" }
                            GradientStop { position: 1.0; color: "#111827" }
                        }
                        Image {
                            visible: readerHeroImg.status !== Image.Ready
                            anchors.centerIn: parent; width: vpx(72); height: vpx(72)
                            source: infoRoot.sectionMode === "nso" ? "../assets/images/navigation/ns2_online.svg" : "../assets/images/navigation/ns2_news.svg"
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Image {
                        id: readerHeroImg
                        anchors.fill: parent
                        source: infoRoot.readerFullImage || infoRoot.activeArticle.image || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: status === Image.Ready
                    }

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#22000000" }
                            GradientStop { position: 0.65; color: "#11000000" }
                            GradientStop { position: 1.0; color: "#CC000000" }
                        }
                    }

                    Rectangle {
                        visible: !!(infoRoot.activeArticle.hasVideo || infoRoot.readerVideoUrl !== "" || infoRoot.sectionMode === "nso")
                        anchors.centerIn: parent
                        width: vpx(196); height: vpx(54); radius: height / 2
                        color: "#E6E60012"
                        border.width: vpx(2); border.color: "#FFFFFF"
                        z: 10
                        Row {
                            anchors.centerIn: parent; spacing: vpx(10)
                            Text { text: "▶"; color: "#FFFFFF"; font.pixelSize: vpx(20) }
                            Text { text: tr("Play Video"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.025 * fontScale); font.bold: true }
                        }
                        MouseArea { anchors.fill: parent; onClicked: infoRoot.openNewsVideoFullscreen() }
                    }

                    Row {
                        anchors { left: parent.left; bottom: parent.bottom; leftMargin: screenmargin; bottomMargin: vpx(16) }
                        spacing: vpx(10)
                        Rectangle {
                            height: vpx(30); width: rBadgeTxt.implicitWidth + vpx(20); radius: vpx(15)
                            color: infoRoot.activeArticle.catColor || "#E60012"
                            Text { id: rBadgeTxt; anchors.centerIn: parent; text: infoRoot.activeArticle.source || "Nintendo"; color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: infoRoot.activeArticle.date || ""
                            color: "#E5E7EB"
                            font.family: titleFont.name
                            font.pixelSize: vpx(15)
                            font.bold: true
                        }
                    }
                }

                // Story Headline + Complete Paragraphs & Inline Small Photos
                Column {
                    id: readerStoryCol
                    width: parent.width - screenmargin * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: vpx(14)

                    Text {
                        width: parent.width
                        text: infoRoot.activeArticle.title || ""
                        color: infoRoot.textMain
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.040)
                        font.bold: true
                        wrapMode: Text.WordWrap
                        lineHeight: 1.2
                    }

                    Rectangle { width: parent.width; height: 1; color: infoRoot.dividerColor }

                    Repeater {
                        model: readerBlocksModel
                        delegate: Text {
                            width: readerStoryCol.width
                            text: model.text || ""
                            color: infoRoot.textMain
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.030 * infoRoot.readerFontScale * fontScale)
                            wrapMode: Text.WordWrap
                            lineHeight: 1.45
                        }
                    }
                }
            }
        }

        // Reader Bottom Controls
        Item {
            id: readerFooter
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
            height: Math.round(screenheight * 0.105)
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: infoRoot.dividerColor }

            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: vpx(10)
                Image { width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "LB / RB · Prev / Next Story"
                    color: infoRoot.textMuted
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.020)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: vpx(14)

                Item {
                    width: vpx(124); height: vpx(44); anchors.verticalCenter: parent.verticalCenter
                    Rectangle { anchors.fill: parent; radius: vpx(12); color: infoRoot.pillBg; border.width: 1; border.color: infoRoot.dividerColor }
                    Row {
                        anchors.centerIn: parent; spacing: vpx(8)
                        Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: infoRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "X"; color: infoRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(13); font.bold: true }
                        }
                        Text { text: tr("Text ") + Math.round(infoRoot.readerFontScale * 100) + "%"; color: infoRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022 * fontScale); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: infoRoot.cycleReaderTextSize() }
                }

                Rectangle {
                    width: vpx(148); height: vpx(46); radius: vpx(12)
                    color: "#E60012"
                    anchors.verticalCenter: parent.verticalCenter
                    Row {
                        anchors.centerIn: parent; spacing: vpx(10)
                        Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "A"; color: "#E60012"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                        }
                        Text { text: tr("Open"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.025); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: infoRoot.openExternalArticle() }
                }

                Item {
                    width: vpx(90); height: vpx(44); anchors.verticalCenter: parent.verticalCenter
                    Row {
                        anchors.centerIn: parent; spacing: vpx(8)
                        Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: infoRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "B"; color: infoRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                        }
                        Text { text: tr("Back"); color: infoRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: infoRoot.closeReader() }
                }
            }
        }

        // Fullscreen Video Overlay (hosts newsVideoHost cleanly!)
        Rectangle {
            id: newsVideoOverlay
            visible: infoRoot.videoFullscreen
            anchors.fill: parent
            color: "#000000"
            z: 140

            Item { id: newsVideoHost; anchors.fill: parent }

            Rectangle {
                anchors { top: parent.top; right: parent.right; margins: vpx(22) }
                width: vpx(184); height: vpx(42); radius: vpx(21)
                color: "#CC000000"; border.width: 2; border.color: "#FFFFFF"
                Text { anchors.centerIn: parent; text: tr("B · Exit Video"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: infoRoot.closeNewsVideoFullscreen() }
            }
        }
    }
}
