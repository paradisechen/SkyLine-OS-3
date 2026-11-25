import QtQuick 2.12
import QtQuick.Layouts 1.3
import SortFilterProxyModel 0.2
import QtMultimedia 5.9
import QtGraphicalEffects 1.0
import "qrc:/qmlutils" as PegasusUtils
import "../utils.js" as Utils
import "../layer_home"

FocusScope {
    id: root
    property var currentGame
    property alias radius: bg.radius
    property string scrapedBackground: ""
    readonly property bool usingScraped: !!(currentGame && currentGame.assets && scrapedBackground !== "" && !(currentGame.assets.background || currentGame.assets.screenshots[0]))
    property bool showDescription: false
    property string focusedButton: "play"   // "back" | "play" | "options" | "desc"
    property bool showOptionsPanel: false
    property bool showSgdbInput: false
    property string sgdbInputValue: ""
    property string sgdbDisplayId: ""
    property var optionsMenuItems: [
        { id: "edit", label: tr("Edit Info") },
        { id: "photos", label: tr("View More Photos") }
    ]
    property int optionsFocusedIdx: 0
    property bool showMorePhotosModal: false
    property var morePhotosList: []
    property int morePhotoIdx: 0
    property bool trailerActive: false
    property string trailerVideoUrl: ""
    property var trailerWebObj: null
    property string wikiSummary: ""

    property string raDisplayId: ""
    property bool showRaInput: false
    property string raInputValue: ""

    property int raProgress: 0
    property bool raProgressLoading: false
    property bool raProgressFetchedForCurrentGame: false
    readonly property int displayProgress: (currentGame && currentGame.extra && currentGame.extra.progress) ? currentGame.extra.progress[0] : raProgress
    property bool showAchievements: false
    property bool raAchievementsLoading: false
    property bool raAchievementsNotFound: false
    ListModel {
        id: raAchievementsModelDetail
    }

    property bool anyOverlayOpen: showSgdbInput || showAchievements || showRaInput || showMorePhotosModal

    property bool showHltbInline: false
    property bool hltbLoading: false
    property var hltbData: null
    property bool hltbFetchedForCurrentGame: false
    readonly property bool hasRatingOrPeriod: !!(currentGame && ((currentGame.rating > 0) || (currentGame.extra && (currentGame.extra.startdate || currentGame.extra.enddate))))    
    readonly property string displayDeveloper: (currentGame && currentGame.developer !== "") ? currentGame.developer : (hltbData && hltbData.developers && hltbData.developers.length > 0 ? hltbData.developers.join(", ") : "")

    readonly property var displayGenreList: (currentGame && currentGame.genreList && currentGame.genreList.length > 0) ? currentGame.genreList : (hltbData && hltbData.genres ? hltbData.genres : [])

    readonly property string displayRelease: (currentGame && currentGame.release && new Date(currentGame.release).getFullYear() > 1970) ? currentGame.release : (hltbData && hltbData.released ? hltbData.released : "")

    property var bgPalette: ["#3B82F6", "#8B5CF6", "#F5A623"]
    property var _paletteCache: ({})

    clip: true

    onVisibleChanged: {
        stopTrailer();
        if (visible) {
            showMorePhotosModal = false;
            showOptionsPanel = false;
            focusedButton = "play";
            refreshSgdbDisplayId();
            refreshRaDisplayId();
            if (currentGame) fetchWikipediaSummary(getGameTitle(currentGame));
            startDelayedTrailer();
        }
        maybeScrapeBackground();
    }

    onCurrentGameChanged: {
        showHltbInline = false;
        hltbData = null;
        hltbLoading = false;
        hltbFetchedForCurrentGame = false;
        wikiSummary = "";
        bgPalette = ["#3B82F6", "#8B5CF6", "#F5A623"];

        raProgress = 0;
        raProgressLoading = false;
        raProgressFetchedForCurrentGame = false;

        if (currentGame) fetchWikipediaSummary(getGameTitle(currentGame));

        if (metadataNeedsRawgFallback())
            fetchRawgIfNeeded();

        fetchRaProgressIfNeeded();
        if (visible) {
            stopTrailer();
            startDelayedTrailer();
        }
    }

    function fetchWikipediaSummary(gameTitle) {
        var clean = String(gameTitle || "")
            .replace(/\([^)]*\)/g, " ")
            .replace(/\[[^\]]*\]/g, " ")
            .replace(/\s+/g, " ")
            .trim();
        if (clean === "") return;
        var reqTitle = currentGame ? currentGame.title : "";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (!currentGame || currentGame.title !== reqTitle) return;
            if (xhr.status >= 200 && xhr.status < 400 && xhr.responseText) {
                try {
                    var parsed = JSON.parse(xhr.responseText);
                    var hitTitle = (parsed && parsed[1] && parsed[1][0]) ? String(parsed[1][0]) : clean;
                    var sumXhr = new XMLHttpRequest();
                    sumXhr.onreadystatechange = function() {
                        if (sumXhr.readyState !== XMLHttpRequest.DONE) return;
                        if (!currentGame || currentGame.title !== reqTitle) return;
                        if (sumXhr.status >= 200 && sumXhr.status < 400 && sumXhr.responseText) {
                            try {
                                var sj = JSON.parse(sumXhr.responseText);
                                if (sj && sj.extract) root.wikiSummary = String(sj.extract);
                            } catch (e2) {}
                        }
                    };
                    sumXhr.open("GET", "https://en.wikipedia.org/api/rest_v1/page/summary/" + encodeURIComponent(hitTitle.replace(/\s+/g, "_")));
                    sumXhr.setRequestHeader("Accept", "application/json");
                    sumXhr.send();
                } catch (e) {}
            }
        };
        xhr.open("GET", "https://en.wikipedia.org/w/api.php?action=opensearch&search=" + encodeURIComponent(clean + " video game") + "&limit=1&namespace=0&format=json");
        xhr.setRequestHeader("Accept", "application/json");
        xhr.send();
    }

    function fetchRawgIfNeeded() {
        if (!currentGame || hltbFetchedForCurrentGame)
            return;

        hltbFetchedForCurrentGame = true;
        hltbLoading = true;
        var requestedGame = currentGame;
        Utils.fetchRawgData(currentGame.title, function (result) {
            if (currentGame !== requestedGame)
                return;
            hltbLoading = false;
            hltbData = result;
        });
    }

    function fetchRaProgressIfNeeded() {
        if (!currentGame || raProgressFetchedForCurrentGame)
            return;
        if (currentGame.extra && currentGame.extra.progress)
            return;

        refreshRaDisplayId();
        if (!raDisplayId)
            return;

        raProgressFetchedForCurrentGame = true;
        raProgressLoading = true;
        var requestedGame = currentGame;
        Utils.fetchRaProgress(raDisplayId, function (percent) {
            if (currentGame !== requestedGame)
                return;
            raProgressLoading = false;
            raProgress = percent;
        });
    }

    function metadataNeedsRawgFallback() {
        if (!currentGame)
            return false;
        if (!currentGame.developer || currentGame.developer === "")
            return true;
        if (!currentGame.genreList || currentGame.genreList.length === 0)
            return true;
        if (!currentGame.players || currentGame.players <= 0)
            return true;
        if (!currentGame.release || new Date(currentGame.release).getFullYear() <= 1970)
            return true;
        return false;
    }

    function collectGamePhotos() {
        var list = [];
        if (!currentGame) return list;
        var seen = {};
        function addP(u, lbl) {
            var s = String(u || "").trim();
            if (s !== "" && !seen[s]) { seen[s] = true; list.push({ url: s, label: lbl }); }
        }
        addP(getGameCover(currentGame), "Cover");
        addP(getGameBg(currentGame) || scrapedBackground, "Background");
        if (currentGame.assets) {
            addP(currentGame.assets.banner, "Banner");
            var shots = currentGame.assets.screenshots || [];
            for (var i = 0; i < shots.length; i++) addP(shots[i], "Screenshot " + (i + 1));
        }
        return list;
    }

    function openMorePhotos() {
        showOptionsPanel = false;
        morePhotosList = collectGamePhotos();
        morePhotoIdx = 0;
        showMorePhotosModal = true;
    }

    function stopTrailer() {
        trailerDelayTimer.stop();
        trailerActive = false;
        trailerVideoUrl = "";
        if (trailerWebObj) {
            try { trailerWebObj.destroy(); } catch (e) {}
            trailerWebObj = null;
        }
        try { bgTrailerVideo.stop(); } catch (e) {}
    }

    function startYouTubePreviewTrailer(gameTitle) {
        var reqTitle = currentGame ? currentGame.title : "";
        var cleanTitle = String(gameTitle || "").replace(/\([^)]*\)/g, " ").replace(/\[[^\]]*\]/g, " ").replace(/[^A-Za-z0-9\s]/g, " ").toLowerCase().trim();
        var words = cleanTitle.split(/\s+/);
        var significant = [];
        for (var w = 0; w < words.length; w++) {
            if (words[w] && words[w].length >= 3 && words[w] !== "the" && words[w] !== "and") significant.push(words[w]);
        }
        var q = encodeURIComponent(String(gameTitle || "") + " gameplay trailer");
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (!root.visible || !currentGame || currentGame.title !== reqTitle) return;
            if (xhr.status >= 200 && xhr.status < 400 && xhr.responseText) {
                var m = String(xhr.responseText).match(/"videoId":"([A-Za-z0-9_-]{11})"/);
                if (m && m[1]) {
                    var vidId = m[1];
                    var xhrO = new XMLHttpRequest();
                    xhrO.onreadystatechange = function() {
                        if (xhrO.readyState !== XMLHttpRequest.DONE) return;
                        if (!root.visible || !currentGame || currentGame.title !== reqTitle) return;
                        if (xhrO.status >= 200 && xhrO.status < 400 && xhrO.responseText) {
                            try {
                                var oj = JSON.parse(xhrO.responseText);
                                var ytTitle = String((oj && oj.title) || "").toLowerCase();
                                var matched = (significant.length === 0);
                                for (var k = 0; k < significant.length; k++) {
                                    if (ytTitle.indexOf(significant[k]) >= 0) { matched = true; break; }
                                }
                                if (!matched) return;
                                var embedUrl = "https://www.youtube.com/embed/" + vidId + "?autoplay=1&mute=0&controls=0&disablekb=1&fs=0&modestbranding=1&iv_load_policy=3&playsinline=1&rel=0";
                                if (trailerWebObj) {
                                    try { trailerWebObj.destroy(); } catch (e) {}
                                    trailerWebObj = null;
                                }
                                var cands = [
                                    "import QtQuick 2.12; import QtWebView 1.1; WebView { x: 0; y: 0; width: parent.width; height: parent.height }",
                                    "import QtQuick 2.12; import QtWebView 1.0; WebView { x: 0; y: 0; width: parent.width; height: parent.height }",
                                    "import QtQuick 2.12; import QtWebView 1.15; WebView { x: 0; y: 0; width: parent.width; height: parent.height }",
                                    "import QtQuick 2.12; import QtWebEngine 1.8; WebEngineView { x: 0; y: 0; width: parent.width; height: parent.height }"
                                ];
                                for (var i = 0; i < cands.length; i++) {
                                    try {
                                        var o = Qt.createQmlObject(cands[i], trailerWebHost, "detailYtVid_" + i);
                                        if (o) {
                                            trailerWebObj = o;
                                            if (typeof o.loadHtml === "function") {
                                                var safeSrc = embedUrl.replace(/"/g, "&quot;");
                                                o.loadHtml('<!doctype html><html><body style="margin:0;padding:0;background:#000;overflow:hidden;"><iframe style="position:fixed;inset:0;width:100vw;height:100vh;border:0;" src="' + safeSrc + '" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen" allowfullscreen></iframe></body></html>', "https://www.youtube.com/");
                                            } else {
                                                o.url = embedUrl;
                                            }
                                            trailerActive = true;
                                            return;
                                        }
                                    } catch (e2) {}
                                }
                            } catch (e3) {}
                        }
                    };
                    xhrO.open("GET", "https://www.youtube.com/oembed?url=" + encodeURIComponent("https://www.youtube.com/watch?v=" + vidId) + "&format=json");
                    xhrO.send();
                }
            }
        };
        xhr.open("GET", "https://www.youtube.com/results?search_query=" + q);
        xhr.send();
    }

    function startDelayedTrailer() {
        if (!visible || !currentGame) return;
        var localVid = "";
        if (currentGame.assets) {
            if (currentGame.assets.videos && currentGame.assets.videos.length > 0)
                localVid = String(currentGame.assets.videos[0] || "");
            else if (currentGame.assets.video)
                localVid = String(currentGame.assets.video || "");
        }
        if (localVid === "" && currentGame.extra && currentGame.extra.video)
            localVid = String(currentGame.extra.video || "");
        if (localVid !== "") {
            trailerVideoUrl = localVid;
            trailerActive = true;
            try { bgTrailerVideo.play(); } catch (e) {}
        } else {
            trailerVideoUrl = "";
            trailerActive = false;
            startYouTubePreviewTrailer(getGameTitle(currentGame));
        }
    }

    Timer {
        id: trailerDelayTimer
        interval: 10
        repeat: false
        onTriggered: root.startDelayedTrailer()
    }

    function activateFocusedButton() {
        if (focusedButton === "back") {
            goBack();
        } else if (focusedButton === "play") {
            root.focusedButton = "play";
            requestProfile(function () {
                launchGame(currentGame);
            });
            anim.start();
            navSound.play();
        } else if (focusedButton === "options") {
            showOptionsPanel = !showOptionsPanel;
        } else if (focusedButton === "stats") {
            if (showHltbInline)
                closeHltbInline();
            else
                openHltbInline();
        } else if (focusedButton === "desc") {
            showDescription = !showDescription;
        }
    }

    function goBack() {
        if (showMorePhotosModal) { showMorePhotosModal = false; return; }
        showHltbInline = false;
        if (showRaInput) {
            showRaInput = false;
        } else if (showAchievements) {
            showAchievements = false;
        } else if (showSgdbInput) {
            showSgdbInput = false;
        } else if (showOptionsPanel) {
            showOptionsPanel = false;
        } else if (showDescription) {
            showDescription = false;
        } else { stopTrailer(); closeGameDetail(); }
    }

    function maybeScrapeBackground() {
        scrapedBackground = "";
        if (!currentGame)
            return;
        if (currentGame.assets.background || currentGame.assets.screenshots[0])
            return;

        var manualKey = sgdbIdKey();
        var manualId = (manualKey && api.memory.has(manualKey)) ? api.memory.get(manualKey) : "";

        if (manualId) {
            var requestedGame = currentGame;
            Utils.sgdbGetHero(manualId, function (url) {
                if (currentGame && currentGame === requestedGame)
                    root.scrapedBackground = url;
            });
            return;
        }

        var requestedTitle = currentGame.title;
        Utils.fetchScrapedBackground(requestedTitle, function (url) {
            if (currentGame && currentGame.title === requestedTitle)
                root.scrapedBackground = url;
        });
    }

    function sgdbIdKey() {
        return currentGame ? ("SGDB_ID::" + currentGame.title) : "";
    }

    function refreshSgdbDisplayId() {
        var key = sgdbIdKey();
        sgdbDisplayId = (key && api.memory.has(key)) ? api.memory.get(key) : "";
    }

    function openSgdbInput() {
        showOptionsPanel = false;
        openSwitchKeyboard(tr("SteamGridDB ID"), sgdbDisplayId, false, 24, function(val) {
            sgdbInputValue = val;
            saveSgdbInput();
            root.forceActiveFocus();
        }, function() {
            cancelSgdbInput();
            root.forceActiveFocus();
        });
    }

    function saveSgdbInput() {
        var key = sgdbIdKey();
        if (key)
            api.memory.set(key, sgdbInputValue);
        showSgdbInput = false;
        refreshSgdbDisplayId();
        maybeScrapeBackground();
    }

    function cancelSgdbInput() {
        showSgdbInput = false;
    }

    function raIdKey() {
        return currentGame ? ("RA_ID::" + currentGame.title) : "";
    }

    function refreshRaDisplayId() {
        var key = raIdKey();
        raDisplayId = (key && api.memory.has(key)) ? api.memory.get(key) : "";
    }

    function openRaInput() {
        showAchievements = false;
        openSwitchKeyboard(tr("RetroAchievements ID"), raDisplayId, false, 24, function(val) {
            raInputValue = val;
            saveRaInput();
        }, function() {
            cancelRaInput();
        });
    }

    function saveRaInput() {
        var key = raIdKey();
        if (key)
            api.memory.set(key, raInputValue);
        showRaInput = false;
        refreshRaDisplayId();
        raProgressFetchedForCurrentGame = false;
        fetchRaProgressIfNeeded();
        openAchievementsPanel();
    }

    function cancelRaInput() {
        showRaInput = false;
        showAchievements = true;
        achievementsPanel.forceActiveFocus();
    }

    function openAchievementsPanel() {
        showOptionsPanel = false;
        var raId = raDisplayId;
        var exophaseFlag = currentGame && currentGame.extra ? currentGame.extra.exophase : "";
        var useExophase = (exophaseFlag === "1" || exophaseFlag === 1);

        if (raId && !useExophase) {
            raAchievementsNotFound = false;
            raAchievementsLoading = true;
            showAchievements = true;
            achievementsPanel.forceActiveFocus();
            var requestedGame = currentGame;
            Utils.loadGameAchievements(raId, raAchievementsModelDetail, function (success) {
                if (currentGame !== requestedGame)
                    return;
                raAchievementsLoading = false;
                if (success) {
                    raAchievementsNotFound = false;
                    return;
                }
                tryExophaseFallback();
            });
            return;
        }

        tryExophaseFallback();
    }

    function tryExophaseFallback() {
        var exophasePlayerId = api.memory.has("Exophase User ID") ? api.memory.get("Exophase User ID") : "";

        if (!exophasePlayerId || !currentGame) {
            raAchievementsNotFound = true;
            raAchievementsModelDetail.clear();
            showAchievements = true;
            achievementsPanel.forceActiveFocus();
            return;
        }

        raAchievementsNotFound = false;
        raAchievementsLoading = true;
        showAchievements = true;
        achievementsPanel.forceActiveFocus();

        var requestedGame = currentGame;
        var test = Utils.fetchExophaseAchievements(currentGame.title, exophasePlayerId, function (result) {
            if (currentGame !== requestedGame)
                return;
            raAchievementsLoading = false;
            raAchievementsNotFound = !result; // per ora sempre true, finché fetchExophaseAchievements è un placeholder
        });
    }

    function openHltbInline() {
        showOptionsPanel = false;
        showHltbInline = true;
        fetchRawgIfNeeded();
    }
    function closeHltbInline() {
        showHltbInline = false;
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: vpx(24)
        color: theme.button
        clip: true

        AnimatedImage {
            id: bgImage
            anchors.fill: parent
            playing: true
            cache: !root.usingScraped
            source: (gameOverrideVersion >= 0 && currentGame) ? (getGameBg(currentGame) || scrapedBackground || "") : ""
            visible: source !== ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            onStatusChanged: {
                if (bgImage.status === Image.Ready) {
                    var key = bgImage.source.toString();
                    if (root._paletteCache[key])
                        root.bgPalette = root._paletteCache[key];
                    else
                        colorSampler.requestPaint();
                }
            }

            Behavior on source {
                SequentialAnimation {
                    NumberAnimation {
                        target: bgImage
                        property: "opacity"
                        to: 0
                        duration: 150
                    }
                    PropertyAction {}
                    NumberAnimation {
                        target: bgImage
                        property: "opacity"
                        to: 1
                        duration: 200
                    }
                }
            }
        }

        Video {
            id: bgTrailerVideo
            anchors.fill: parent
            source: root.trailerVideoUrl
            fillMode: VideoOutput.PreserveAspectCrop
            autoPlay: true
            loops: MediaPlayer.Infinite
            muted: false
            volume: 0.9
            visible: root.trailerActive && root.trailerVideoUrl !== "" && bgTrailerVideo.hasVideo
        }

        Item {
            id: trailerWebHost
            anchors.fill: parent
            enabled: false
            visible: root.trailerActive && root.trailerVideoUrl === "" && root.trailerWebObj !== null
        }

        Canvas {
            id: colorSampler
            width: 32
            height: 32
            opacity: 0
            renderStrategy: Canvas.Immediate

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (bgImage.status !== Image.Ready)
                    return;
                ctx.drawImage(bgImage, 0, 0, width, height);
                try {
                    var imageData = ctx.getImageData(0, 0, width, height);
                    var colors = Utils.extractDominantColors(imageData, 3);
                    if (colors && colors.length === 3) {
                        root.bgPalette = colors;
                        if (bgImage.source)
                            root._paletteCache[bgImage.source.toString()] = colors;
                    }
                } catch (e) {
                    console.log("Palette extraction error:", e);
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: "#B8000000"
                }
                GradientStop {
                    position: 0.28
                    color: "#28000000"
                }
                GradientStop {
                    position: 0.48
                    color: "#00000000"
                }
                GradientStop {
                    position: 1.0
                    color: "#00000000"
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#00000000"
                }
                GradientStop {
                    position: 0.72
                    color: "#00000000"
                }
                GradientStop {
                    position: 1.0
                    color: "#99000000"
                }
            }
        }

        // === TOP STATUS BAR (ora, profilo, batteria, wifi) ===
        Item {
            id: topStatusBar
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: vpx(28)
                leftMargin: vpx(48)
                rightMargin: vpx(48)
            }
            height: vpx(48)
            z: 5

            Row {
                spacing: vpx(10)
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                Item {
                    id: profileIconClipDetail
                    width: vpx(36)
                    height: vpx(36)
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: profileIconDetail
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                        asynchronous: true
                        source: api.memory.get("RA_LoggedIn") === "Yes" ? "https://media.retroachievements.org/UserPic/" + api.memory.get("RA_Username") + ".png" : "../assets/images/profile_icon.png"
                    }
                    Rectangle {
                        id: profileMaskDetail
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                    }
                    OpacityMask {
                        anchors.fill: parent
                        source: profileIconDetail
                        maskSource: profileMaskDetail
                    }
                }

                Text {
                    text: {
                        if (api.memory.get("RA_LoggedIn") === "Yes")
                            return api.memory.get("RA_Username") || "";
                        if (api.memory.has("Username") && api.memory.get("Username") !== "")
                            return api.memory.get("Username");
                        return "";
                    }
                    visible: text !== ""
                    color: "white"
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.022)
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item {
                id: statusPill
                height: Math.round(screenheight * 0.0611)
                width: statusRow.width + vpx(12)
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Row {
                    id: statusRow
                    spacing: vpx(14)
                    anchors.centerIn: parent

                    Text {
                        text: Qt.formatTime(new Date(), settings.timeFormat === "12hr" ? "h:mm AP" : "hh:mm")
                        color: "white"
                        font.family: titleFont.name
                        font.weight: Font.Normal
                        font.pixelSize: Math.round(screenheight * 0.025)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: isNaN(api.device.batteryPercent) ? "" : parseInt(api.device.batteryPercent * 100) + "%"
                        visible: showPercent && !isNaN(api.device.batteryPercent)
                        color: "white"
                        font.family: titleFont.name
                        font.weight: Font.Normal
                        font.pixelSize: Math.round(screenheight * 0.024)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    BatteryIcon {
                        width: Math.round(screenheight * 0.04)
                        height: width / 1.5
                        level: isNaN(api.device.batteryPercent) ? 0 : parseInt(api.device.batteryPercent * 100)
                        visible: !isNaN(api.device.batteryPercent)
                        anchors.verticalCenter: parent.verticalCenter
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: "white"
                        }
                    }

                    Image {
                        width: Math.round(screenheight * 0.04)
                        height: width
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/images/navigation/wifi.svg"
                        visible: settings.showWifi === "Yes"
                        anchors.verticalCenter: parent.verticalCenter
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: "white"
                        }
                    }
                }
            }
        }

        Column {
            id: infoColumn
            spacing: vpx(14)
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: vpx(48)
                rightMargin: vpx(48)
                bottom: actionRow.top
                bottomMargin: vpx(28)
            }

            // Contenitore cover + badge piattaforma (necessario per un anchoring valido tra i due)
            Item {
                id: coverContainer
                width: coverFrame.width
                height: coverFrame.height

                Rectangle {
                    id: coverFrame
                    width: vpx(180)
                    height: vpx(180)
                    radius: vpx(28)
                    color: theme.button
                    clip: true
                    antialiasing: true

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: vpx(6)
                        radius: 16
                        samples: 32
                        color: "#60000000"
                    }

                    Rectangle {
                        id: coverMask
                        anchors.fill: parent
                        radius: vpx(28)
                        visible: false
                        antialiasing: true
                    }

                    AnimatedImage {
                        id: coverImage
                        anchors.fill: parent
                        playing: true
                        asynchronous: true
                        smooth: true
                        fillMode: Image.PreserveAspectCrop
                        source: (gameOverrideVersion >= 0 && currentGame) ? getGameCover(currentGame) : ""
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: coverImage
                        source: coverImage
                        maskSource: coverMask
                        visible: coverImage.source !== "" && coverImage.status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: coverImage.source === "" || coverImage.status !== Image.Ready
                        text: currentGame ? currentGame.title.charAt(0) : "?"
                        color: theme.icon
                        font.family: titleFont.name
                        font.bold: true
                        font.pixelSize: Math.round(screenheight * 0.06)
                    }
                }

                // Badge platform
                Rectangle {
                    id: platformBadge
                    height: vpx(32)
                    width: platformBadgeRow.width + vpx(20)
                    radius: vpx(10)
                    color: theme.button
                    border.width: vpx(2)
                    border.color: theme.main
                    visible: !!(currentGame && currentGame.collections && currentGame.collections.count > 0)
                    anchors {
                        left: coverFrame.right
                        bottom: coverFrame.bottom
                        leftMargin: vpx(8)
                    }
                    z: 6

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: vpx(2)
                        radius: 6
                        samples: 16
                        color: "#60000000"
                    }

                    Row {
                        id: platformBadgeRow
                        anchors.centerIn: parent
                        spacing: vpx(6)

                        Image {
                            width: vpx(16)
                            height: vpx(16)
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            source: {
                                if (!currentGame || !currentGame.collections || currentGame.collections.count === 0)
                                    return "";
                                var p = currentGame.collections.get(0).shortName;
                                return p ? "../assets/images/platforms/" + p + ".svg" : "";
                            }
                            visible: source !== ""
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: theme.icon
                            }
                        }

                        Text {
                            text: (currentGame && currentGame.collections && currentGame.collections.count > 0) ? currentGame.collections.get(0).name : ""
                            color: theme.icon
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.016)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Text {
                text: (gameOverrideVersion >= 0 && currentGame) ? getGameTitle(currentGame) : ""
                color: "white"
                font.family: titleFont.name
                font.bold: true
                font.pixelSize: Math.round(screenheight * 0.055)
                width: Math.min(implicitWidth, screenwidth * 0.55)
                wrapMode: Text.WordWrap
            }

            Text {
                text: (root.wikiSummary !== "") ? root.wikiSummary : (currentGame ? (currentGame.summary || "") : "")
                visible: text !== ""
                color: "white"
                opacity: 0.86
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.02)
                width: Math.min(implicitWidth, screenwidth * 0.50)
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 3
            }
        }

        // === ACTION ROW (Back + Play + stats) ===
        Item {
            id: actionRow
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: vpx(48)
                rightMargin: vpx(48)
                bottomMargin: vpx(32)
            }
            height: vpx(72)

            Row {
                id: playRow
                spacing: vpx(12)
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    id: backButton
                    width: vpx(72)
                    height: vpx(72)
                    radius: width / 2
                    color: "#33FFFFFF"
                    border.width: root.focusedButton === "back" ? vpx(3) : 0
                    border.color: theme.accent
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: vpx(26)
                        height: vpx(26)
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/images/navigation/back.svg"
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: "white"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.focusedButton = "back";
                            root.goBack();
                        }
                    }
                }

                Rectangle {
                    id: playButton
                    width: playLabel.width + vpx(74)
                    height: vpx(72)
                    radius: height / 2
                    color: "white"
                    border.width: root.focusedButton === "play" ? vpx(3) : 0
                    border.color: theme.accent

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Row {
                        id: playLabel
                        anchors.centerIn: parent
                        spacing: vpx(10)

                        Image {
                            source: "../assets/images/navigation/play.svg"
                            width: vpx(24)
                            height: vpx(24)
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: "black"
                            }
                        }
                        Text {
                            text: tr("Play")
                            color: "black"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.026 * fontScale)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.focusedButton = "play";
                            launchSfx.play();
                            requestProfile(function () {
                                launchGame(currentGame);
                            });
                            anim.start();
                        }
                    }
                }

                Rectangle {
                    id: optionsButton
                    width: vpx(72)
                    height: vpx(72)
                    radius: width / 2
                    color: root.showOptionsPanel ? theme.accent : "#33FFFFFF"
                    border.width: root.focusedButton === "options" ? vpx(3) : 0
                    border.color: theme.accent

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\u22EF"
                        color: "white"
                        font.pixelSize: Math.round(screenheight * 0.036)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.focusedButton = "options";
                            root.showOptionsPanel = !root.showOptionsPanel;
                        }
                    }
                }
            }

            Rectangle {
                id: optionsPanel

                width: vpx(220)
                height: optionsColumn.height + vpx(16)
                radius: vpx(16)
                color: "#EE1A1A1A"

                visible: root.showOptionsPanel

                x: playRow.x + optionsButton.x + (optionsButton.width - width) / 2 + vpx(20)

                y: playRow.y + optionsButton.y - height - vpx(30)

                z: 10

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: vpx(4)
                    radius: 16
                    samples: 32
                    color: "#80000000"
                }

                Column {
                    id: optionsColumn
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: vpx(8)
                    }

                    Repeater {
                        model: root.optionsMenuItems
                        Rectangle {
                            width: parent.width
                            height: vpx(50)
                            radius: vpx(10)
                            color: (root.optionsFocusedIdx === index) ? theme.accent : "transparent"

                            Column {
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: vpx(14)
                                }
                                spacing: vpx(2)

                                Text {
                                    text: modelData.label
                                    color: "white"
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.017)
                                }

                                Text {
                                    visible: modelData.id === "sgdb"
                                    text: root.sgdbDisplayId !== "" ? ("ID: " + root.sgdbDisplayId) : tr("Not set — tap to add")
                                    color: "white"
                                    opacity: 0.5
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.013)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.optionsFocusedIdx = index;
                                    if (modelData.id === "edit") {
                                        root.showOptionsPanel = false;
                                        if (currentGame) openGameEdit(currentGame);
                                    } else if (modelData.id === "photos") {
                                        root.openMorePhotos();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // progress + playtime
            Row {
                spacing: vpx(10)
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    height: vpx(36)
                    width: progRow.width + vpx(20)
                    radius: height / 2
                    color: "#33000000"
                    visible: root.displayProgress > 0

                    Row {
                        id: progRow
                        anchors.centerIn: parent
                        spacing: vpx(6)
                        Image {
                            source: "../assets/images/navigation/trophy.svg"
                            width: vpx(16)
                            height: vpx(16)
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: "white"
                            }
                        }
                        Text {
                            text: root.displayProgress > 0 ? root.displayProgress + "%" : ""
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.018)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Rectangle {
                    height: vpx(36)
                    width: timeRow.width + vpx(20)
                    radius: height / 2
                    color: "#33000000"
                    visible: {
                        if (!currentGame)
                            return false;
                        var pt = currentGame ? currentGame.playTime : 0;
                        var manual = currentGame.extra.playtime ? currentGame.extra.playtime : 0;
                        var stackTime = parseInt(api.memory.get(currentGame.title) || "0");
                        return pt > 0 || manual > 0 || stackTime > 0;
                    }

                    Row {
                        id: timeRow
                        anchors.centerIn: parent
                        spacing: vpx(6)
                        Image {
                            source: "../assets/images/navigation/clock.svg"
                            width: vpx(14)
                            height: vpx(14)
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: "white"
                            }
                        }
                        Text {
                            text: {
                                if (!currentGame)
                                    return "00:00";
                                var totalSeconds = 0;

                                if (currentGame.extra.playtime) {
                                    totalSeconds = currentGame.extra.playtime;
                                    // Free memory
                                    if (api.memory.has(currentGame.title))
                                        api.memory.unset(currentGame.title);
                                } else if (api.memory.has(currentGame.title))
                                    totalSeconds = api.memory.get(currentGame.title);
                                else if (currentGame.playTime > 0)
                                    totalSeconds = currentGame.playTime;

                                if (totalSeconds <= 0)
                                    return "00:00";

                                var h = Math.floor(totalSeconds / 3600);
                                var m = Math.floor((totalSeconds % 3600) / 60);

                                return h + ":" + (m < 10 ? "0" + m : m);
                            }
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.018)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Rectangle {
                    height: vpx(36)
                    width: playersRow.width + vpx(20)
                    radius: height / 2
                    color: "#33000000"
                    visible: !!(currentGame && currentGame.players > 0)
                    Row {
                        id: playersRow
                        anchors.centerIn: parent
                        spacing: vpx(6)
                        Image {
                            source: "../assets/images/navigation/player.svg"
                            width: vpx(16)
                            height: vpx(16)
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: "white"
                            }
                        }
                        Text {
                            text: currentGame ? currentGame.players : ""
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.018)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // === CENTRO BASSO: rating + periodo di gioco ===
        Item {
            id: statsSwitcher
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: vpx(32)
            }
            width: Math.max(defaultStatsRow.width, hltbStatsRow.width)
            height: vpx(56)
            clip: true

            Row {
                id: defaultStatsRow
                spacing: vpx(14)
                anchors.verticalCenter: parent.verticalCenter
                x: root.showHltbInline ? -width - vpx(60) : (parent.width - width) / 2

                Behavior on x {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    id: ratingBadge
                    width: vpx(56)
                    height: vpx(56)
                    radius: vpx(14)
                    visible: !!(currentGame && currentGame.rating > 0)
                    color: {
                        if (!currentGame)
                            return "#33000000";
                        var r = currentGame.rating * 10;
                        if (r >= 8)
                            return "#1DB954";
                        if (r >= 5)
                            return "#F5A623";
                        return "#E63946";
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: vpx(1)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: currentGame ? (currentGame.rating * 10).toFixed(1) : ""
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.022)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tr("RATING")
                            color: "white"
                            opacity: 0.85
                            font.family: titleFont.name
                            font.bold: true
                            font.letterSpacing: 1
                            font.pixelSize: Math.round(screenheight * 0.009)
                        }
                    }
                }

                Rectangle {
                    id: playPeriodPill
                    height: vpx(56)
                    width: playPeriodColumn.width + vpx(28)
                    radius: vpx(14)
                    color: "#33000000"
                    visible: !!(currentGame && currentGame.extra && (currentGame.extra.startdate || currentGame.extra.enddate))

                    Column {
                        id: playPeriodColumn
                        anchors.centerIn: parent
                        spacing: vpx(2)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (currentGame && currentGame.extra && currentGame.extra.enddate) ? tr("PLAY PERIOD") : tr("STARTED")
                            color: "white"
                            opacity: 0.5
                            font.family: titleFont.name
                            font.bold: true
                            font.letterSpacing: 1
                            font.pixelSize: Math.round(screenheight * 0.011)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (!currentGame || !currentGame.extra)
                                    return "";
                                var start = currentGame.extra.startdate || "";
                                var end = currentGame.extra.enddate || "";
                                if (start && end)
                                    return Utils.formatDateItalian(start) + "  →  " + Utils.formatDateItalian(end);
                                return start ? Utils.formatDateItalian(start) : "";
                            }
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.016)
                        }
                    }
                }

                Rectangle {
                    id: statsToggleButton
                    width: vpx(56)
                    height: vpx(56)
                    radius: vpx(14)
                    color: "#33000000"
                    visible: currentGame !== null
                    border.width: (root.focusedButton === "stats" && !root.showHltbInline) ? vpx(3) : 0
                    border.color: theme.accent

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: vpx(18)
                        height: vpx(18)
                        fillMode: Image.PreserveAspectFit
                        source: root.hasRatingOrPeriod ? "../assets/images/navigation/right.svg" : "../assets/images/navigation/howlongtobeat.svg"
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: "white"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.focusedButton = "stats";
                            root.openHltbInline();
                        }
                    }
                }
            }

            // ===== Riga HLTB: pulsante indietro + quadratini con i tempi =====
            Row {
                id: hltbStatsRow
                spacing: vpx(14)
                anchors.verticalCenter: parent.verticalCenter
                x: root.showHltbInline ? (parent.width - width) / 2 : parent.width + vpx(60)

                Behavior on x {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    id: hltbBackButton
                    width: vpx(56)
                    height: vpx(56)
                    radius: vpx(14)
                    color: "#33000000"
                    border.width: (root.focusedButton === "stats" && root.showHltbInline) ? vpx(3) : 0
                    border.color: theme.accent

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: vpx(18)
                        height: vpx(18)
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/images/navigation/left.svg"
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: "white"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.focusedButton = "stats";
                            root.closeHltbInline();
                        }
                    }
                }

                Rectangle {
                    width: vpx(160)
                    height: vpx(56)
                    radius: vpx(14)
                    color: "#33000000"
                    visible: root.hltbLoading

                    Text {
                        anchors.centerIn: parent
                        text: tr("Loading...")
                        color: "white"
                        opacity: 0.7
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.016)
                    }
                }

                Rectangle {
                    width: vpx(220)
                    height: vpx(56)
                    radius: vpx(14)
                    color: '#33414296'
                    visible: !root.hltbLoading && (!root.hltbData || (root.hltbData.playtime === 0 && root.hltbData.added === 0 && root.hltbData.achievementsCount === 0))

                    Text {
                        anchors.centerIn: parent
                        text: tr("No playtime data")
                        color: "white"
                        opacity: 0.6
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.015)
                    }
                }

                Rectangle {
                    width: vpx(90)
                    height: vpx(56)
                    radius: vpx(14)
                    color: Utils.colorWithAlpha(root.bgPalette[0], "4D")
                    visible: !root.hltbLoading && root.hltbData && root.hltbData.playtime > 0

                    Column {
                        anchors.centerIn: parent
                        spacing: vpx(1)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.hltbData ? root.hltbData.playtime + "h" : ""
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.02)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tr("AVG PLAYTIME")
                            color: "white"
                            opacity: 0.7
                            font.family: titleFont.name
                            font.bold: true
                            font.letterSpacing: 1
                            font.pixelSize: Math.round(screenheight * 0.008)
                        }
                    }
                }

                Rectangle {
                    width: vpx(80)
                    height: vpx(56)
                    radius: vpx(14)
                    color: Utils.colorWithAlpha(root.bgPalette[1], "4D")
                    visible: !root.hltbLoading && root.hltbData && root.hltbData.added > 0

                    Column {
                        anchors.centerIn: parent
                        spacing: vpx(1)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.hltbData ? Utils.formatCompactNumber(root.hltbData.added) : ""
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.02)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tr("PLAYERS")
                            color: "white"
                            opacity: 0.7
                            font.family: titleFont.name
                            font.bold: true
                            font.letterSpacing: 1
                            font.pixelSize: Math.round(screenheight * 0.008)
                        }
                    }
                }

                Rectangle {
                    width: vpx(80)
                    height: vpx(56)
                    radius: vpx(14)
                    color: Utils.colorWithAlpha(root.bgPalette[2], "4D")
                    visible: !root.hltbLoading && root.hltbData && root.hltbData.achievementsCount > 0

                    Column {
                        anchors.centerIn: parent
                        spacing: vpx(1)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.hltbData ? root.hltbData.achievementsCount : ""
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.02)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tr("TROPHIES")
                            color: "white"
                            opacity: 0.7
                            font.family: titleFont.name
                            font.bold: true
                            font.letterSpacing: 1
                            font.pixelSize: Math.round(screenheight * 0.008)
                        }
                    }
                }
            }
        }

        Rectangle {
            id: descToggleButton
            width: vpx(56)
            height: vpx(56)
            radius: width / 2
            color: root.showDescription ? theme.accent : "#33FFFFFF"
            border.width: root.focusedButton === "desc" ? vpx(3) : 0
            border.color: "white"
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: vpx(32)
            }
            z: 6

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            Behavior on border.width {
                NumberAnimation {
                    duration: 120
                }
            }

            Image {
                anchors.centerIn: parent
                width: vpx(22)
                height: vpx(22)
                fillMode: Image.PreserveAspectFit
                source: "../assets/images/navigation/desc.svg"
                layer.enabled: true
                layer.effect: ColorOverlay {
                    color: "white"
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.focusedButton = "desc";
                    root.showDescription = !root.showDescription;
                }
            }
        }

        Rectangle {
            id: descriptionPanel
            width: Math.round(screenwidth * 0.40)
            height: Math.round(bg.height * 0.7)
            radius: vpx(20)
            color: "#DD1A1A1A"
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: vpx(56)
            }
            x: root.showDescription ? bg.width - width - vpx(56) : bg.width
            opacity: root.showDescription ? 1 : 0
            visible: opacity > 0
            z: 5
            clip: true

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: vpx(4)
                radius: 20
                samples: 32
                color: "#80000000"
            }

            Flickable {
                id: descFlick
                anchors {
                    fill: parent
                    margins: vpx(28)
                }
                contentWidth: width
                contentHeight: descContent.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: descContent
                    width: descFlick.width
                    spacing: vpx(18)

                    Text {
                        id: descText
                        width: parent.width
                        text: (currentGame && currentGame.description) ? currentGame.description : ""
                        color: "white"
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.019)
                        wrapMode: Text.WordWrap
                        lineHeight: 1.35
                    }

                    // Tag — sotto la descrizione, dentro lo stesso pannello scrollabile
                    Column {
                        width: parent.width
                        spacing: vpx(8)
                        visible: !!(currentGame && currentGame.tagList && currentGame.tagList.length > 0)

                        Text {
                            text: tr("TAGS")
                            color: "white"
                            opacity: 0.5
                            font.family: titleFont.name
                            font.bold: true
                            font.letterSpacing: 1.5
                            font.pixelSize: Math.round(screenheight * 0.013)
                        }

                        Flow {
                            width: parent.width
                            spacing: vpx(8)

                            property var pillColors: ["#3B82F6", "#8B5CF6", "#10B981", "#F59E0B", "#EF4444"]

                            Repeater {
                                model: currentGame ? currentGame.tagList : []
                                Rectangle {
                                    height: vpx(26)
                                    width: tagText.width + vpx(16)
                                    radius: height / 2
                                    color: parent.parent.pillColors[index % parent.parent.pillColors.length]
                                    opacity: 0.85

                                    Text {
                                        id: tagText
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "white"
                                        font.family: titleFont.name
                                        font.pixelSize: Math.round(screenheight * 0.016)
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    // Box info
                    Rectangle {
                        id: infoBox
                        width: parent.width
                        radius: vpx(14)
                        color: "#22FFFFFF"
                        height: infoBoxColumn.height + vpx(24)
                        visible: root.displayDeveloper !== "" || root.displayGenreList.length > 0 || (root.displayRelease && new Date(root.displayRelease).getFullYear() > 1950)

                        Column {
                            id: infoBoxColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: vpx(16)
                            }
                            spacing: vpx(10)

                            Row {
                                width: parent.width
                                spacing: vpx(8)
                                visible: root.displayDeveloper !== ""

                                Text {
                                    text: tr("Developer")
                                    color: "white"
                                    opacity: 0.5
                                    font.family: titleFont.name
                                    font.bold: true
                                    font.pixelSize: Math.round(screenheight * 0.013)
                                    width: vpx(90)
                                }
                                Text {
                                    text: root.displayDeveloper
                                    color: "white"
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.016)
                                    width: parent.width - vpx(98)
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: vpx(8)
                                visible: root.displayGenreList.length > 0

                                Text {
                                    text: tr("Genre")
                                    color: "white"
                                    opacity: 0.5
                                    font.family: titleFont.name
                                    font.bold: true
                                    font.pixelSize: Math.round(screenheight * 0.013)
                                    width: vpx(90)
                                }
                                Text {
                                    text: root.displayGenreList.join(", ")
                                    color: "white"
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.016)
                                    width: parent.width - vpx(98)
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: vpx(8)
                                visible: root.displayRelease && new Date(root.displayRelease).getFullYear() > 1950

                                Text {
                                    text: tr("Released")
                                    color: "white"
                                    opacity: 0.5
                                    font.family: titleFont.name
                                    font.bold: true
                                    font.pixelSize: Math.round(screenheight * 0.013)
                                    width: vpx(90)
                                }
                                Text {
                                    text: Utils.formatDateItalian(root.displayRelease)
                                    color: "white"
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.016)
                                    width: parent.width - vpx(98)
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: morePhotosModal
            visible: root.showMorePhotosModal
            anchors.fill: parent
            color: "#EB0B0D12"
            z: 110

            Text {
                anchors { top: parent.top; left: parent.left; margins: vpx(28) }
                text: (currentGame ? getGameTitle(currentGame) : "") + " · Photos (" + (root.morePhotosList.length > 0 ? (root.morePhotoIdx + 1) + "/" + root.morePhotosList.length : "0") + ")"
                color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.028 * fontScale); font.bold: true
            }

            Image {
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left; right: parent.right; topMargin: vpx(78); bottomMargin: vpx(82); leftMargin: vpx(60); rightMargin: vpx(60) }
                source: (root.morePhotosList.length > 0 && root.morePhotoIdx >= 0 && root.morePhotoIdx < root.morePhotosList.length) ? root.morePhotosList[root.morePhotoIdx].url : ""
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            }

            Rectangle {
                anchors { top: parent.top; right: parent.right; margins: vpx(24) }
                width: vpx(136); height: vpx(46); radius: height / 2
                color: "#33FFFFFF"; border.width: 1; border.color: "#88FFFFFF"
                Text { anchors.centerIn: parent; text: tr("B · Close"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(16); font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: root.showMorePhotosModal = false }
            }

            Text {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: vpx(26) }
                text: root.morePhotosList.length > 1 ? "Left / Right · Switch Photo   •   B · Close" : "B · Close"
                color: "#CBD5E1"; font.family: titleFont.name; font.pixelSize: vpx(18)
            }
        }

        Rectangle {
            id: achievementsPanel
            visible: root.showAchievements
            anchors.centerIn: parent
            width: Math.round(screenwidth * 0.5)
            height: Math.round(bg.height * 0.75)
            radius: vpx(20)
            color: theme.button
            z: 100
            clip: true

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: vpx(6)
                radius: 20
                samples: 32
                color: "#60000000"
            }

            Item {
                anchors {
                    fill: parent
                    margins: vpx(28)
                }

                Text {
                    id: achTitle
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    text: tr("Trophies")
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.026)
                    font.bold: true
                }

                Text {
                    anchors {
                        top: parent.top
                        right: parent.right
                        verticalCenter: achTitle.verticalCenter
                    }
                    visible: root.raAchievementsLoading
                    text: tr("Loading...")
                    color: theme.icon
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.017)
                }

                Column {
                    anchors.centerIn: parent
                    spacing: vpx(16)
                    visible: !root.raAchievementsLoading && root.raAchievementsNotFound
                    width: parent.width * 0.7

                    Text {
                        width: parent.width
                        text: root.raDisplayId === "" ? tr("No RetroAchievements ID set for this game") : tr("No achievements found for this ID")
                        color: theme.icon
                        opacity: 0.6
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.018)
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: setIdText.width + vpx(32)
                        height: vpx(40)
                        radius: height / 2
                        color: theme.accent

                        Text {
                            id: setIdText
                            anchors.centerIn: parent
                            text: root.raDisplayId === "" ? tr("Set ID" ): tr("Change ID")
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.016)
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.openRaInput()
                        }
                    }
                }

                ListView {
                    id: achievementsListDetail
                    anchors {
                        top: achTitle.bottom
                        topMargin: vpx(16)
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    visible: !root.raAchievementsLoading && !root.raAchievementsNotFound
                    spacing: vpx(6)
                    clip: true
                    model: raAchievementsModelDetail
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        width: achievementsListDetail.width
                        height: vpx(64)

                        Rectangle {
                            anchors.fill: parent
                            radius: vpx(10)
                            color: earned ? theme.main : "#1A000000"
                            opacity: earned ? 0.8 : 0.5
                            border.color: earned ? theme.accent : "transparent"
                            border.width: earned ? vpx(1) : 0
                        }

                        Item {
                            id: badgeClipDetail
                            width: vpx(48)
                            height: vpx(48)
                            anchors {
                                left: parent.left
                                leftMargin: vpx(8)
                                verticalCenter: parent.verticalCenter
                            }
                            opacity: earned ? 1.0 : 0.35

                            Image {
                                id: badgeImgDetail
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                visible: false
                                source: badgeUrl
                                asynchronous: true
                            }
                            Rectangle {
                                id: badgeMaskDetail
                                anchors.fill: parent
                                radius: vpx(6)
                                visible: false
                            }
                            OpacityMask {
                                anchors.fill: parent
                                source: badgeImgDetail
                                maskSource: badgeMaskDetail
                            }
                        }

                        Column {
                            anchors {
                                left: badgeClipDetail.right
                                leftMargin: vpx(10)
                                right: pointsBadgeDetail.left
                                rightMargin: vpx(8)
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: vpx(2)

                            Text {
                                width: parent.width
                                text: title
                                color: earned ? theme.text : theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.018)
                                font.bold: earned
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: description
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.014)
                                opacity: 0.7
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: earned && dateEarned !== ""
                                text: tr("Unlocked: ") + dateEarned
                                color: theme.accent
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.013)
                                opacity: 0.8
                            }
                        }

                        Rectangle {
                            id: pointsBadgeDetail
                            anchors {
                                right: parent.right
                                rightMargin: vpx(10)
                                verticalCenter: parent.verticalCenter
                            }
                            width: vpx(44)
                            height: vpx(24)
                            radius: height / 2
                            color: earned ? theme.accent : theme.main
                            opacity: earned ? 1.0 : 0.5

                            Text {
                                anchors.centerIn: parent
                                text: points + "p"
                                color: earned ? "white" : theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.015)
                                font.bold: true
                            }
                        }
                    }
                }
            }

            Keys.onBackPressed: {
                event.accepted = true;
                showAchievements = false;
                stopTrailer();
                closeGameDetail();
                showHomeScreen();
            }
            Keys.onPressed: {
                if (!visible)
                    return;
                event.accepted = true;
                if (api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace || event.key === Qt.Key_Escape) {
                    root.goBack();
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: (root.showSgdbInput || root.showAchievements || root.showRaInput) ? 0.5 : 0
            visible: opacity > 0
            z: 99
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }
    }

    Keys.onUpPressed: {
        if (showOptionsPanel && !anyOverlayOpen) {
            navSound.play();
            optionsFocusedIdx = (optionsFocusedIdx + optionsMenuItems.length - 1) % optionsMenuItems.length;
        }
    }
    Keys.onDownPressed: {
        if (showOptionsPanel && !anyOverlayOpen) {
            navSound.play();
            optionsFocusedIdx = (optionsFocusedIdx + 1) % optionsMenuItems.length;
        }
    }
    Keys.onLeftPressed: {
        if (showMorePhotosModal) {
            if (morePhotosList.length > 1) { navSound.play(); morePhotoIdx = (morePhotoIdx - 1 + morePhotosList.length) % morePhotosList.length; }
            return;
        }
        if (anyOverlayOpen) return;
        navSound.play();
        var order = ["back", "play", "options", "stats", "desc"];
        var i = order.indexOf(focusedButton);
        focusedButton = order[(i - 1 + order.length) % order.length];
    }
    Keys.onRightPressed: {
        if (showMorePhotosModal) {
            if (morePhotosList.length > 1) { navSound.play(); morePhotoIdx = (morePhotoIdx + 1) % morePhotosList.length; }
            return;
        }
        if (anyOverlayOpen) return;
        navSound.play();
        var order = ["back", "play", "options", "stats", "desc"];
        var i = order.indexOf(focusedButton);
        focusedButton = order[(i + 1) % order.length];
    }

    Keys.onBackPressed: {
        event.accepted = true;
        showMorePhotosModal = false;
        showAchievements = false;
        showOptionsPanel = false;
        showDescription = false;
        showHltbInline = false;
        stopTrailer();
        closeGameDetail();
        showHomeScreen();
    }
    Keys.onEscapePressed: { event.accepted = true; goBack(); }
    Keys.onReleased: {
        if (parent && parent.parent && typeof parent.parent.handleGlobalSleepCombo === "function")
            parent.parent.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
    }
    Keys.onPressed: {
        if (parent && parent.parent && typeof parent.parent.handleGlobalSleepCombo === "function" && parent.parent.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) {
            event.accepted = true;
            return;
        }
        if (showMorePhotosModal) {
            if ((api.keys.isCancel(event) || event.key === Qt.Key_Escape || event.key === Qt.Key_B || event.key === Qt.Key_Backspace) && !event.isAutoRepeat) {
                event.accepted = true;
                showMorePhotosModal = false;
                backSfx.play();
            }
            return;
        }
        if (showOptionsPanel && !anyOverlayOpen) {
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                var selOpt = optionsMenuItems[optionsFocusedIdx];
                if (selOpt && selOpt.id === "edit") { showOptionsPanel = false; if (currentGame) openGameEdit(currentGame); }
                else if (selOpt && selOpt.id === "photos") { openMorePhotos(); }
                return;
            }
        }
        if (anyOverlayOpen) return;
        if ((api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace) && !event.isAutoRepeat) {
            event.accepted = true;
            goBack();
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            activateFocusedButton();
        }
    }
}
