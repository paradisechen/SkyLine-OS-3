// skylineOS v2
// Se un giorno mi leggerai, sappi che ti amo, Molly. Addio 24/05/2012 - 04/09/2026

import QtQuick 2.12
import QtQuick.Layouts 1.3
import SortFilterProxyModel 0.2
import QtMultimedia 5.9
import QtGraphicalEffects 1.0
import "qrc:/qmlutils" as PegasusUtils
import "utils.js" as Utils
import "translations.js" as Tr
import "layer_home"
import "layer_grid"
import "layer_settings"
import "layer_help"
import "layer_buttons"
import "layer_detail"
import "Lists"
import "layer_2ds"
import "global" as Global
import "resources" as Resources

FocusScope {
    id: root


    // Single-launch debounce lock to prevent duplicate am start intents in Pegasus
    property bool isLaunching: false
    property bool launchingNow: false
    Timer {
        id: launchDebounceTimer
        interval: 3500
        repeat: false
        onTriggered: {
            root.isLaunching = false;
            root.launchingNow = false;
        }
    }
    // Load settings
    property var settings: {
        return {
            gameBackground: api.memory.has("Game Background") ? api.memory.get("Game Background") : "Screenshot",
            timeFormat: api.memory.has("Time Format") ? api.memory.get("Time Format") : "12hr",
            wordWrap: api.memory.has("Word Wrap on Titles") ? api.memory.get("Word Wrap on Titles") : "Yes",
            batteryPercentSetting: api.memory.has("Display Battery Percentage") ? api.memory.get("Display Battery Percentage") : "No",
            enableDropShadows: api.memory.has("Enable DropShadows") ? api.memory.get("Enable DropShadows") : "Yes",
            showWifi: api.memory.has("Display Wifi Icon") ? api.memory.get("Display Wifi Icon") : "Yes",
            username: api.memory.has("Username") ? api.memory.get("Username") : "",
            darkMode: api.memory.has("Dark Mode") ? api.memory.get("Dark Mode") : "Yes",
            homeCardSize: api.memory.has("Home Card Size") ? api.memory.get("Home Card Size") : "35",
            softCount: api.memory.has("Max games on Home Screen") ? parseInt(api.memory.get("Max games on Home Screen")) : 12,
            playBGM: api.memory.has("Background Music") ? api.memory.get("Background Music") : "No",
            showFeed: api.memory.has("Feed Button Show") ? api.memory.get("Feed Button Show") : "Yes",
            showStore: api.memory.has("Store Button Show") ? api.memory.get("Store Button Show") : "Yes",
            showGallery: api.memory.has("Gallery Button Show") ? api.memory.get("Gallery Button Show") : "Yes",
            showController: api.memory.has("Controller Button Show") ? api.memory.get("Controller Button Show") : "Yes",
            showSettings: api.memory.has("Settings Button Show") ? api.memory.get("Settings Button Show") : "Yes",
            showSuspend: api.memory.has("Suspend Button Show") ? api.memory.get("Suspend Button Show") : "Yes",
            bgTransparency: api.memory.has("Background Transparency") ? api.memory.get("Background Transparency") : "70",
            bgBlur: api.memory.has("Background Blur") ? parseInt(api.memory.get("Background Blur")) : 25,
            steamGridDBAPIKey: api.memory.has("SteamGridDB API Key") ? api.memory.get("SteamGridDB API Key") : "",
            RAWGKey: api.memory.has("RAWG API Key") ? api.memory.get("RAWG API Key") : "",
            multiUser: api.memory.has("Multi User") ? api.memory.get("Multi User") : "No",
            exophaseID: api.memory.has("Exophase User ID") ? api.memory.get("Exophase User ID") : "",
            uiSoundsEnabled: api.memory.has("UI Sounds") ? api.memory.get("UI Sounds") : "Yes",
            appearanceMode: api.memory.has("Appearance Polarity") ? api.memory.get("Appearance Polarity") : "Dark",
            hudThemeId: api.memory.has("HUD Theme Accent") ? api.memory.get("HUD Theme Accent") : "Auto",
            browserMode: api.memory.has("Browser Mode") ? api.memory.get("Browser Mode") : "in-app",
            browserLink: (api.memory.has("Browser default link") && api.memory.get("Browser default link") !== "") ? api.memory.get("Browser default link") : "https://www.nintendo.com",
            borderGap720: api.memory.has("Border Gap") ? parseInt(api.memory.get("Border Gap")) : 7,
            borderThick720: api.memory.has("Border Width") ? parseInt(api.memory.get("Border Width")) : 6,
            cardSpacingRatio: api.memory.has("Cover Spacing") ? parseFloat(api.memory.get("Cover Spacing")) : 0.140,
            dockHeightPct: api.memory.has("Dock Size Pct") ? parseFloat(api.memory.get("Dock Size Pct")) : 13.3,
            activeCharacter: (api.memory.has("ns2_active_character") && api.memory.get("ns2_active_character") !== "") ? api.memory.get("ns2_active_character") : "mario",
            photosDirectory: (api.memory.has("Photos Directory") && api.memory.get("Photos Directory") !== "") ? api.memory.get("Photos Directory") : ((api.memory.has("Gallery Folder Label") && api.memory.get("Gallery Folder Label") !== "") ? api.memory.get("Gallery Folder Label") : "/storage/emulated/0/Pictures"),
            systemFontScale: api.memory.has("System Font Scale") ? parseInt(api.memory.get("System Font Scale")) : 100,
            allSoftCols: api.memory.has("All Software Columns") ? parseInt(api.memory.get("All Software Columns")) : 6
        };
    }

    // number of games that appear on the homescreen, not including the All Software button
    property int softCount: settings.softCount

    //Hidden apps
    property var hiddenApps: api.memory.has("HiddenApps") ? api.memory.get("HiddenApps") : []

    property int gameOverrideVersion: 0

    function getGameTitle(game) {
        if (!game) return "";
        var orig = String(game.title || "");
        var key = "CUSTOM_TITLE::" + orig;
        if (api.memory.has(key)) {
            var v = String(api.memory.get(key) || "").trim();
            if (v !== "") return v;
        }
        return orig;
    }

    function getGameCover(game) {
        if (!game) return "";
        var orig = String(game.title || "");
        var key = "CUSTOM_COVER::" + orig;
        if (api.memory.has(key)) {
            var v = String(api.memory.get(key) || "").trim();
            if (v !== "") return v;
        }
        return (game.assets && (game.assets.boxFront || game.assets.tile)) ? (game.assets.boxFront || game.assets.tile) : "";
    }

    function getGameBg(game) {
        if (!game) return "";
        var orig = String(game.title || "");
        var key = "CUSTOM_BG::" + orig;
        if (api.memory.has(key)) {
            var v = String(api.memory.get(key) || "").trim();
            if (v !== "") return v;
        }
        return (game.assets && (game.assets.background || (game.assets.screenshots && game.assets.screenshots[0])))
            ? (game.assets.background || game.assets.screenshots[0]) : "";
    }

    function recordGamePlayer(game) {
        if (!game || !game.title) return;
        var uname = (pendingLauncherUser !== "") ? pendingLauncherUser : currentUsername();
        if (!uname || uname === "") uname = "Mario";
        var charId = api.memory.has("ns2_active_character") ? String(api.memory.get("ns2_active_character") || "mario") : "mario";
        var pKey = "GAME_PLAYERS::" + game.title;
        var list = [];
        if (api.memory.has(pKey)) {
            try {
                var parsed = JSON.parse(String(api.memory.get(pKey)));
                if (Array.isArray(parsed)) list = parsed;
            } catch (e) { list = []; }
        }
        var found = false;
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].name === uname) {
                list[i].charId = charId;
                found = true;
                break;
            }
        }
        if (!found) list.push({ name: uname, charId: charId });
        api.memory.set(pKey, JSON.stringify(list));
    }

    function recordGameActivity(game, minsAdded) {
        if (!game || !game.title) return;
        var title = String(game.title);
        var cover = getGameCover(game);
        var addSec = Math.max(60, Math.round((minsAdded || 15) * 60));
        var prevSecs = api.memory.has(title) ? parseInt(api.memory.get(title)) : 0;
        if (isNaN(prevSecs)) prevSecs = 0;
        api.memory.set(title, String(prevSecs + addSec));
        var prevSeq = api.memory.has("PLAY_SEQ_COUNTER") ? parseInt(api.memory.get("PLAY_SEQ_COUNTER")) : 0;
        if (isNaN(prevSeq)) prevSeq = 0;
        var nextSeq = prevSeq + 1;
        api.memory.set("PLAY_SEQ_COUNTER", String(nextSeq));
        api.memory.set("PLAY_SEQ::" + title, String(nextSeq));
        api.memory.set("LAST_PLAYED_TITLE", title);
        api.memory.set("LAST_PLAYED_COVER", cover);
        api.memory.set("LAST_PLAYED_AT::" + title, "Just now");
    }

    ListHomeRecent {
        id: listRecent
        max: 10
    }
    ListLastPlayed {
        id: listByLastPlayed
    }
    ListMostPlayed {
        id: listByMostPlayed
    }
    ListPublisher {
        id: listByPublisher
    }
    ListFavorites {
        id: listFavorites
    }
    ListAllGames {
        id: listByTitle
    }
    Resources.Music {
        id: music
    }

    property int currentCollection: api.memory.has('Last Collection') ? api.memory.get('Last Collection') : -1
    property int nextCollection: api.memory.has('Last Collection') ? api.memory.get('Last Collection') : -1
    property var currentGame
    property bool gameDetailOpen: false
    property real detailOriginX: 0
    property real detailOriginY: 0
    property real detailOriginWidth: 100
    property real detailOriginHeight: 100
    property var softwareList: [listByLastPlayed, listByMostPlayed, listByTitle, listByPublisher, listFavorites]
    property int sortByIndex: api.memory.has('sortIndex') ? api.memory.get('sortIndex') : 0
    property string searchtext
    property string softwareSearch: ""
    property bool wordWrap: (settings.wordWrap === "Yes") ? true : false
    property bool showPercent: (settings.batteryPercentSetting === "Yes") ? true : false
    property bool enableDropShadows: (settings.enableDropShadows === "Yes") ? true : false
    property bool playBGM: (settings.playBGM === "Yes") ? true : false
    property bool multiUserEnabled: (settings.multiUser === "Yes") ? true : false

    property string language: api.memory.has("Language") ? api.memory.get("Language") : "en"

    function tr(text, arg) {
        return Tr.translate(language, text, arg);
    }

    onNextCollectionChanged: {
        changeCollection();
    }

    function changeCollection() {
        if (nextCollection != currentCollection) {
            currentCollection = nextCollection;
            searchtext = "";
            //gameGrid.currentIndex = 0;
        }
    }

    property int collectionIndex: 0
    property int currentGameIndex: 0
    property int screenmargin: vpx(30)
    property real screenwidth: width
    property real screenheight: height
    property bool widescreen: ((height / width) < 0.7)
    property real helpbarheight: Math.round(screenheight * 0.1041) // Calculated manually based on mockup
    property bool darkThemeActive
    property real fontScale: (settings && settings.systemFontScale) ? Math.max(0.85, Math.min(1.35, settings.systemFontScale / 100.0)) : 1.0
    function refreshSettings() {
        language = api.memory.has("Language") ? api.memory.get("Language") : "en";
        settings = {
            gameBackground: api.memory.has("Game Background") ? api.memory.get("Game Background") : "Screenshot",
            timeFormat: api.memory.has("Time Format") ? api.memory.get("Time Format") : "12hr",
            wordWrap: api.memory.has("Word Wrap on Titles") ? api.memory.get("Word Wrap on Titles") : "Yes",
            batteryPercentSetting: api.memory.has("Display Battery Percentage") ? api.memory.get("Display Battery Percentage") : "No",
            enableDropShadows: api.memory.has("Enable DropShadows") ? api.memory.get("Enable DropShadows") : "Yes",
            showWifi: api.memory.has("Display Wifi Icon") ? api.memory.get("Display Wifi Icon") : "Yes",
            username: api.memory.has("Username") ? api.memory.get("Username") : "",
            darkMode: api.memory.has("Dark Mode") ? api.memory.get("Dark Mode") : "Yes",
            homeCardSize: api.memory.has("Home Card Size") ? api.memory.get("Home Card Size") : "35",
            softCount: api.memory.has("Max games on Home Screen") ? parseInt(api.memory.get("Max games on Home Screen")) : 12,
            playBGM: api.memory.has("Background Music") ? api.memory.get("Background Music") : "No",
            showFeed: api.memory.has("Feed Button Show") ? api.memory.get("Feed Button Show") : "Yes",
            showStore: api.memory.has("Store Button Show") ? api.memory.get("Store Button Show") : "Yes",
            showGallery: api.memory.has("Gallery Button Show") ? api.memory.get("Gallery Button Show") : "Yes",
            showController: api.memory.has("Controller Button Show") ? api.memory.get("Controller Button Show") : "Yes",
            showSettings: api.memory.has("Settings Button Show") ? api.memory.get("Settings Button Show") : "Yes",
            showSuspend: api.memory.has("Suspend Button Show") ? api.memory.get("Suspend Button Show") : "Yes",
            bgTransparency: api.memory.has("Background Transparency") ? api.memory.get("Background Transparency") : "70",
            bgBlur: api.memory.has("Background Blur") ? parseInt(api.memory.get("Background Blur")) : 25,
            steamGridDBAPIKey: api.memory.has("SteamGridDB API Key") ? api.memory.get("SteamGridDB API Key") : "",
            RAWGKey: api.memory.has("RAWG API Key") ? api.memory.get("RAWG API Key") : "",
            multiUser: api.memory.has("Multi User") ? api.memory.get("Multi User") : "No",
            exophaseID: api.memory.has("Exophase User ID") ? api.memory.get("Exophase User ID") : "",
            uiSoundsEnabled: api.memory.has("UI Sounds") ? api.memory.get("UI Sounds") : "Yes",
            appearanceMode: api.memory.has("Appearance Polarity") ? api.memory.get("Appearance Polarity") : "Dark",
            hudThemeId: api.memory.has("HUD Theme Accent") ? api.memory.get("HUD Theme Accent") : "Auto",
            browserMode: api.memory.has("Browser Mode") ? api.memory.get("Browser Mode") : "in-app",
            browserLink: (api.memory.has("Browser default link") && api.memory.get("Browser default link") !== "") ? api.memory.get("Browser default link") : "https://www.nintendo.com",
            borderGap720: api.memory.has("Border Gap") ? parseInt(api.memory.get("Border Gap")) : 7,
            borderThick720: api.memory.has("Border Width") ? parseInt(api.memory.get("Border Width")) : 6,
            cardSpacingRatio: api.memory.has("Cover Spacing") ? parseFloat(api.memory.get("Cover Spacing")) : 0.140,
            dockHeightPct: api.memory.has("Dock Size Pct") ? parseFloat(api.memory.get("Dock Size Pct")) : 13.3,
            activeCharacter: (api.memory.has("ns2_active_character") && api.memory.get("ns2_active_character") !== "") ? api.memory.get("ns2_active_character") : "mario",
            photosDirectory: (api.memory.has("Photos Directory") && api.memory.get("Photos Directory") !== "") ? api.memory.get("Photos Directory") : ((api.memory.has("Gallery Folder Label") && api.memory.get("Gallery Folder Label") !== "") ? api.memory.get("Gallery Folder Label") : "/storage/emulated/0/Pictures"),
            systemFontScale: api.memory.has("System Font Scale") ? parseInt(api.memory.get("System Font Scale")) : 100,
            allSoftCols: api.memory.has("All Software Columns") ? parseInt(api.memory.get("All Software Columns")) : 6
        };
    }

    function showSoftwareScreen() {
        /*homeScreen.visible = false;
        softwareScreen.visible = true;*/
        refreshSettings();
        softwareScreen.focus = true;
        allSoftSfx.play();
    }

    function showSettingsScreen(tabIdx) {
        if (typeof tabIdx === "number")
            settingsScreen.openTab(tabIdx);
        settingsScreen.focus = true;
        settingsSfx.play();
    }

    function openUserSelect(title, cb) {
        userSfx.play();
        userSelectOverlay.open(title || "¿Quién está jugando?", cb || null);
    }

    function openGameEdit(game) {
        if (!game) return;
        selectSfx.play();
        gameEditOverlay.open(game);
    }

    function showSatelliteProfileScreen(n) {
        settingsSfx.play();
        satelliteProfileScreen.open(n);
    }

    function showNewProfileScreen() {
        newUserSfx.play();
        newProfileScreen.open();
    }

    property bool _sleepMinusHeld: false
    property bool _sleepPlusHeld: false

    Timer {
        id: selectSleepTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (root.state !== "suspendscreen" && !globalSwitchKeyboard.isOpen) {
                root._sleepMinusHeld = false;
                showButtonScreen("suspend");
            }
        }
    }

    function openSwitchKeyboard(title, initialText, allowUrlKeys, maxLen, onCommit, onCancel) {
        globalSwitchKeyboard.open(title, initialText, allowUrlKeys, maxLen, onCommit, function() {
            if (onCancel) onCancel();
            restoreActiveScreenFocus();
        });
    }

    function restoreActiveScreenFocus() {
        if (root.launchingNow || root.state === "playgame" || root.state === "playsoftware") {
            return;
        }
        if (globalSwitchKeyboard.isOpen) {
            globalSwitchKeyboard.forceActiveFocus();
            return;
        }
        if (userSelectOverlay.isOpen) {
            userSelectOverlay.forceActiveFocus();
            return;
        }
        if (gameEditOverlay.isOpen) {
            gameEditOverlay.forceActiveFocus();
            return;
        }
        if (gameDetailOpen) {
            gameDetailScreen.forceActiveFocus();
            return;
        }
        if (softwareScreen.visible)
            softwareScreen.forceActiveFocus();
        else if (settingsScreen.visible)
            settingsScreen.forceActiveFocus();
        else if (storeScreen.visible)
            storeScreen.forceActiveFocus();
        else if (infoScreen.visible)
            infoScreen.forceActiveFocus();
        else if (browserScreen.visible)
            browserScreen.forceActiveFocus();
        else if (gameShareScreen.visible)
            gameShareScreen.forceActiveFocus();
        else if (chatScreen.visible)
            chatScreen.forceActiveFocus();
        else if (albumScreen.visible)
            albumScreen.forceActiveFocus();
        else if (backlogScreen.visible)
            backlogScreen.forceActiveFocus();
        else if (suspendScreen.visible)
            suspendScreen.forceActiveFocus();
        else if (homeScreen && typeof homeScreen.focusCarousel === "function")
            homeScreen.focusCarousel();
        else
            homeScreen.forceActiveFocus();
    }

    function handleGlobalSleepCombo(key, isPressed, isRepeat) {
        var isSelect = (key === Qt.Key_Minus || key === Qt.Key_Underscore || key === Qt.Key_Select || key === Qt.Key_MediaPrevious);
        var isStart = (key === Qt.Key_Plus || key === Qt.Key_Equal || key === Qt.Key_Menu || key === Qt.Key_MediaNext);
        if (isSelect) {
            if (isPressed && !isRepeat) {
                _sleepMinusHeld = true;
                if (root.state !== "suspendscreen" && !selectSleepTimer.running)
                    selectSleepTimer.start();
            } else if (!isPressed && !isRepeat) {
                _sleepMinusHeld = false;
                selectSleepTimer.stop();
            }
        }
        if (isStart && !isRepeat) _sleepPlusHeld = isPressed;
        if (isPressed && _sleepMinusHeld && _sleepPlusHeld) {
            _sleepMinusHeld = false;
            _sleepPlusHeld = false;
            selectSleepTimer.stop();
            if (root.state !== "suspendscreen") {
                showButtonScreen("suspend");
            }
            return true;
        }
        return false;
    }

    property string browserReturnScreen: "homescreen"

    function openInThemeBrowser(url) {
        if (root.state === "storescreen" || root.state === "infoscreen" || root.state === "settingsscreen")
            browserReturnScreen = root.state;
        else
            browserReturnScreen = "homescreen";
        browserScreen.focus = true;
        browserSfx.play();
        if (url && url !== "")
            browserScreen.navigate(url, true);
    }

    function closeInThemeBrowser() {
        refreshSettings();
        if (browserReturnScreen === "storescreen") {
            storeScreen.focus = true;
            return;
        }
        if (browserReturnScreen === "infoscreen") {
            infoScreen.focus = true;
            return;
        }
        if (browserReturnScreen === "settingsscreen") {
            settingsScreen.focus = true;
            return;
        }
        showHomeScreen();
    }

    function showButtonScreen(menu) {
        switch (menu) {
        case "nso":
            infoScreen.openSection("nso");
            infoScreen.focus = true;
            feedSfx.play();
            break;
        case "info":
            infoScreen.openSection("news");
            infoScreen.focus = true;
            feedSfx.play();
            break;
        case "chat":
            chatScreen.focus = true;
            feedSfx.play();
            break;
        case "store":
            storeScreen.focus = true;
            storeSfx.play();
            break;
        case "album":
            albumScreen.focus = true;
            albumSfx.play();
            break;
        case "gameshare":
            gameShareScreen.focus = true;
            selectSfx.play();
            break;
        case "browser":
            browserReturnScreen = "homescreen";
            browserScreen.goHome();
            browserScreen.focus = true;
            browserSfx.play();
            break;
        case "backlog":
            backlogScreen.focus = true;
            backlogSfx.play();
            break;
        case "suspend":
            if (typeof suspendScreen.resetLock === "function") suspendScreen.resetLock();
            suspendScreen.focus = true;
            standbySfx.play();
            break;
        default:
            break;
        }
    }

    function openGameDetail(originItem, game) {
        if (!originItem || !game)
            return;
        if (homeScreen) homeScreen.dockWasFocused = false;
        recordGameActivity(game, 5);
        var pos = originItem.mapToItem(root, 0, 0);
        detailOriginX = pos.x;
        detailOriginY = pos.y;
        detailOriginWidth = originItem.width;
        detailOriginHeight = originItem.height;
        currentGame = game;
        gameDetailOpen = true;
        gameDetailScreen.forceActiveFocus();
        gameDetailScreen.currentGame = currentGame;
        detailSfx.play();
    }

    function closeGameDetail() {
        gameDetailOpen = false;
        backSfx.play();
        if (softwareScreen.visible) {
            softwareScreen.forceActiveFocus();
        } else {
            homeScreen.focus = true;
            if (homeScreen && typeof homeScreen.restoreLastFocus === "function")
                homeScreen.restoreLastFocus();
            else if (homeScreen && typeof homeScreen.focusCarousel === "function")
                homeScreen.focusCarousel();
            else
                homeScreen.forceActiveFocus();
        }
    }

    function showHomeScreen() {
        refreshSettings();
        softwareSearch = "";
        gameDetailOpen = false;
        root.launchingNow = false;
        if (userSelectOverlay && userSelectOverlay.isOpen) userSelectOverlay.isOpen = false;
        if (gameEditOverlay && gameEditOverlay.isOpen) gameEditOverlay.isOpen = false;
        if (globalSwitchKeyboard && globalSwitchKeyboard.isOpen) globalSwitchKeyboard.isOpen = false;
        homeScreen.focus = true;
        homeSfx.play();
        Qt.callLater(function () {
            if (homeScreen && typeof homeScreen.restoreLastFocus === "function")
                homeScreen.restoreLastFocus();
            else if (homeScreen && typeof homeScreen.focusCarousel === "function")
                homeScreen.focusCarousel();
            else
                homeScreen.forceActiveFocus();
        });
    }

    function playGame() {
        requestProfile(function () {
            if (root.isLaunching) {
                console.log("[skylineOS2] playGame ignored - launch already in progress");
                return;
            }
            root.launchingNow = true;
            if (root.state === "playgame")
                root.state = "homescreen";
            launchSfx.play();
            root.state = "playgame";
        });
    }

    function playSoftware() {
        requestProfile(function () {
            if (root.isLaunching) {
                console.log("[skylineOS2] playSoftware ignored - launch already in progress");
                return;
            }
            root.launchingNow = true;
            if (root.state === "playsoftware")
                root.state = "softwarescreen";
            launchSfx.play();
            root.state = "playsoftware";
        });
    }

    function pushToStackTimer(game) {
        if (game != null) {
            api.memory.set("STACK_TIMER", [game.title, Math.floor(Date.now() / 1000)]);
            api.memory.set("LAST_STACK_ITEM", game.title);
        }
    }

    function popToStackTimer() {
        if (api.memory.has("LAST_STACK_ITEM")) {
            var last = api.memory.get("LAST_STACK_ITEM");
            var startTime = api.memory.get("STACK_TIMER")[1];
            var elapsed = Math.floor(Date.now() / 1000) - startTime;

            var prevTime = api.memory.has(last) ? parseInt(api.memory.get(last)) : 0;
            api.memory.set(last, prevTime + elapsed);
        }

        api.memory.unset("LAST_STACK_ITEM");
        api.memory.unset("STACK_TIMER");
    }

    function toggleHideApp(title) {
        var list = hiddenApps;
        var idx = list.indexOf(title);
        if (idx >= 0)
            list.splice(idx, 1);
        else
            list.push(title);

        api.memory.set("HiddenApps", list);
        hiddenApps = list;
    }

    function isAppHidden(title) {
        for (var i = 0; i < hiddenApps.length; i++) {
            if (String(hiddenApps[i]).indexOf(title) >= 0)
                return true;
        }
        return false;
    }

    //Hide Popup
    Rectangle {
        id: hideConfirmPopup
        visible: false
        opacity: visible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
        property string pendingTitle: ""
        property bool isReverse: false
        property var confirmAction: null
        property var returnFocusItem: null
        property string customTitle: ""
        property string customSubtitle: ""

        anchors.centerIn: parent
        z: 200

        width: vpx(420)
        height: vpx(200)
        radius: vpx(24)
        color: theme.button

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: vpx(6)
            radius: 20
            samples: 32
            color: "#60000000"
        }

        Column {
            anchors.centerIn: parent
            spacing: vpx(20)

            Text {
                text: hideConfirmPopup.customTitle !== "" ? hideConfirmPopup.customTitle : (hideConfirmPopup.isReverse ? tr("Show \"%1\" again?", hideConfirmPopup.pendingTitle) : tr("Hide \"%1\"?", hideConfirmPopup.pendingTitle))
                width: vpx(380)
                wrapMode: Text.WordWrap
                color: theme.text
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.028)
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: hideConfirmPopup.customSubtitle !== "" ? hideConfirmPopup.customSubtitle : (hideConfirmPopup.isReverse ? "It will appear on the home screen again" : "It won't appear on the home screen anymore")
                width: vpx(380)
                wrapMode: Text.WordWrap
                color: theme.icon
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.020)
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                spacing: vpx(16)
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: vpx(130)
                    height: vpx(44)
                    radius: height / 2
                    color: theme.main
                    Text {
                        text: tr("Cancel  B")
                        color: theme.text
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.022)
                        anchors.centerIn: parent
                    }
                }

                Rectangle {
                    width: vpx(130)
                    height: vpx(44)
                    radius: height / 2
                    color: theme.accent
                    Text {
                        text: tr("A  Confirm")
                        color: "white"
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.022)
                        anchors.centerIn: parent
                    }
                }
            }
        }

        Keys.onPressed: {
            if (confirmAction) {
                event.accepted = true;
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    var act = confirmAction;
                    var target = returnFocusItem;
                    confirmAction = null;
                    returnFocusItem = null;
                    customTitle = "";
                    customSubtitle = "";
                    hideConfirmPopup.visible = false;
                    turnOffSfx.play();
                    act();
                    if (target)
                        target.forceActiveFocus();
                } else if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                    var back = returnFocusItem;
                    confirmAction = null;
                    returnFocusItem = null;
                    customTitle = "";
                    customSubtitle = "";
                    backSfx.play();
                    hideConfirmPopup.visible = false;
                    if (back)
                        back.forceActiveFocus();
                }
                return;
            }
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                toggleHideApp(pendingTitle);
                hideConfirmPopup.isReverse ? turnOnSfx.play() : turnOffSfx.play();
                hideConfirmPopup.visible = false;
                pendingTitle = "";
                if (softwareScreen.visible) {
                    softwareScreen.focus = true;
                } else {
                    homeScreen.focus = true;
                }
                if (api.memory.get("Show Hidden Apps") === "No")
                    softCount--;
            }
            if (api.keys.isCancel(event)) {
                event.accepted = true;
                backSfx.play();
                hideConfirmPopup.visible = false;
                pendingTitle = "";
                if (softwareScreen.visible)
                    softwareScreen.focus = true;
                else
                    homeScreen.focus = true;
            }
        }
    }

    function requestConfirm(title, subtitle, action, focusItem) {
        hideConfirmPopup.customTitle = title;
        hideConfirmPopup.customSubtitle = subtitle;
        hideConfirmPopup.confirmAction = action;
        hideConfirmPopup.returnFocusItem = focusItem;
        hideConfirmPopup.visible = true;
        hideConfirmPopup.forceActiveFocus();
    }

    function requestHideApp(title) {
        hideConfirmPopup.confirmAction = null;
        hideConfirmPopup.customTitle = "";
        hideConfirmPopup.customSubtitle = "";
        hideConfirmPopup.pendingTitle = title;
        hideConfirmPopup.isReverse = isAppHidden(title) && api.memory.get("Show Hidden Apps") === "Yes";
        hideConfirmPopup.visible = true;
        hideConfirmPopup.forceActiveFocus();
    }

    function registerLauncherUser() {
        api.memory.set("Launcher User", pendingLauncherUser !== "" ? pendingLauncherUser : currentUsername());
    }

    function currentUsername() {
        if (api.memory.get("RA_LoggedIn") === "Yes")
            return api.memory.get("RA_Username") || "";
        if (api.memory.has("Username") && api.memory.get("Username") !== "")
            return api.memory.get("Username");
        return "";
    }

    property string pendingLauncherUser: ""
    property var profileGateAction: null

    function requestProfile(action) {
        pendingLauncherUser = "";
        if (api.memory.get("Multi User") === "Yes") {
            userSelectOverlay.open("Who is playing?", function(picked) {
                if (picked && picked.name) pendingLauncherUser = picked.name;
                if (action) action();
                if (!root.launchingNow) restoreFocusAfterProfile();
            });
        } else {
            action();
        }
    }

    function restoreFocusAfterProfile() {
        Qt.callLater(function() {
            if (!root.launchingNow) restoreActiveScreenFocus();
        });
    }

    // Launch the current game from HomeBar (with Eden / Android Direct Boot guard)
    function launchGame(game) {
        if (root.isLaunching) {
            console.log("[skylineOS2] launchGame ignored - debounce active to prevent duplicate intent");
            return;
        }
        root.isLaunching = true;
        launchDebounceTimer.restart();

        registerLauncherUser();
        recordGamePlayer(game || currentGame);
        recordGameActivity(game || currentGame, 25);
        pushToStackTimer(game);

        api.memory.set('Last Collection', currentCollection);
        if (game != null)
            game.launch();
        else if (currentGame != null)
            currentGame.launch();
    }

    // Launch current game from SoftwareScreen (with Eden / Android Direct Boot guard)
    function launchSoftware() {
        if (root.isLaunching) {
            console.log("[skylineOS2] launchSoftware ignored - debounce active to prevent duplicate intent");
            return;
        }
        root.isLaunching = true;
        launchDebounceTimer.restart();

        registerLauncherUser();
        api.memory.set('Last Collection', currentCollection);
        var targetGame = null;
        if (currentGame != null)
            targetGame = currentGame;
        else if (softwareList && softwareList[sortByIndex])
            targetGame = softwareList[sortByIndex].currentGame(currentGameIndex);
        if (targetGame != null) {
            recordGamePlayer(targetGame);
            recordGameActivity(targetGame, 25);
            pushToStackTimer(targetGame);
            targetGame.launch();
        }
    }

    // Theme settings
    FontLoader {
        id: titleFont
        source: "assets/fonts/Nintendo_Switch_UI_Font.ttf"
    }

    function resolveHudAccent(fallbackHex) {
        switch (settings.hudThemeId) {
        case "Mario Red": return "#E60012";
        case "Luigi Green": return "#00A651";
        case "Peach Pink": return "#FF5E99";
        case "Yoshi Green": return "#65C322";
        case "DK Amber": return "#E67E22";
        case "Bowser Gold": return "#D97706";
        case "Switch Cyan": return "#10AEBE";
        default: return fallbackHex;
        }
    }

    property var themeLight: {
        return {
            main: "#EBEBEB",
            secondary: "#2D2D2D",
            accent: resolveHudAccent(api.memory.has("Accent Light Mode") ? api.memory.get("Accent Light Mode") : "#10AEBE"),
            highlight: "white",
            text: "#2C2C2C",
            button: "white",
            icon: "#7e7e7e",
            press: "#7Fc0f0f3"
        };
    }

    property var themeDark: {
        return {
            main: "#2D2D2D",
            secondary: "#EBEBEB",
            accent: resolveHudAccent(api.memory.has("Accent Dark Mode") ? api.memory.get("Accent Dark Mode") : "#1d9bf3"),
            highlight: "black",
            text: "white",
            button: "#515151",
            icon: "white",
            press: "#591d9bf3"
        };
    }

    property var theme: (settings.appearanceMode === "Dark")
        ? themeDark
        : ((settings.appearanceMode === "Light")
            ? themeLight
            : (settings.darkMode === "Yes" ? themeDark : themeLight))

    // State settings
    states: [
        State {
            name: "homescreen"
            when: homeScreen.focus == true && !root.launchingNow
        },
        State {
            name: "softwarescreen"
            when: softwareScreen.focus == true && !root.launchingNow
        },
        State {
            name: "settingsscreen"
            when: settingsScreen.focus == true
        },
        State {
            name: "infoscreen"
            when: infoScreen.focus == true
        },
        State {
            name: "storescreen"
            when: storeScreen.focus == true
        },
        State {
            name: "browserscreen"
            when: browserScreen.focus == true
        },
        State {
            name: "backlogscreen"
            when: backlogScreen.focus == true
        },
        State {
            name: "gamesharescreen"
            when: gameShareScreen.focus == true
        },
        State {
            name: "chatscreen"
            when: chatScreen.focus == true
        },
        State {
            name: "albumscreen"
            when: albumScreen.focus == true
        },
        State {
            name: "suspendscreen"
            when: suspendScreen.focus == true
        },
        State {
            name: "playgame"
        },
        State {
            name: "playsoftware"
        }
    ]

    property int currentScreenID: -3

    transitions: [
        Transition {
            from: "homescreen"
            to: "softwarescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: softwareScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: softwareScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "homescreen"
            to: "settingsscreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: settingsScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: settingsScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "softwarescreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: softwareScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: softwareScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "settingsscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: settingsScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: settingsScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            to: "playgame"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PauseAnimation {
                    duration: 200
                }
                ScriptAction {
                    script: launchGame(currentGame)
                }
            }
        },
        Transition {
            to: "playsoftware"
            SequentialAnimation {
                PropertyAnimation {
                    target: softwareScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PauseAnimation {
                    duration: 200
                }
                ScriptAction {
                    script: launchSoftware()
                }
            }
        },
        Transition {
            from: "homescreen"
            to: "infoscreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: infoScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: infoScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "homescreen"
            to: "storescreen"
            SequentialAnimation {
                PropertyAnimation { target: homeScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: homeScreen; property: "visible"; value: false }
                PropertyAction { target: storeScreen; property: "visible"; value: true }
                PropertyAnimation { target: storeScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "storescreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation { target: storeScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: storeScreen; property: "visible"; value: false }
                PropertyAction { target: homeScreen; property: "visible"; value: true }
                PropertyAnimation { target: homeScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "homescreen"
            to: "browserscreen"
            SequentialAnimation {
                PropertyAnimation { target: homeScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: homeScreen; property: "visible"; value: false }
                PropertyAction { target: browserScreen; property: "visible"; value: true }
                PropertyAnimation { target: browserScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "browserscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation { target: browserScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: browserScreen; property: "visible"; value: false }
                PropertyAction { target: homeScreen; property: "visible"; value: true }
                PropertyAnimation { target: homeScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "storescreen"
            to: "browserscreen"
            SequentialAnimation {
                PropertyAnimation { target: storeScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: storeScreen; property: "visible"; value: false }
                PropertyAction { target: browserScreen; property: "visible"; value: true }
                PropertyAnimation { target: browserScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "browserscreen"
            to: "storescreen"
            SequentialAnimation {
                PropertyAnimation { target: browserScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: browserScreen; property: "visible"; value: false }
                PropertyAction { target: storeScreen; property: "visible"; value: true }
                PropertyAnimation { target: storeScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "infoscreen"
            to: "browserscreen"
            SequentialAnimation {
                PropertyAnimation { target: infoScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: infoScreen; property: "visible"; value: false }
                PropertyAction { target: browserScreen; property: "visible"; value: true }
                PropertyAnimation { target: browserScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "browserscreen"
            to: "infoscreen"
            SequentialAnimation {
                PropertyAnimation { target: browserScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: browserScreen; property: "visible"; value: false }
                PropertyAction { target: infoScreen; property: "visible"; value: true }
                PropertyAnimation { target: infoScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "settingsscreen"
            to: "browserscreen"
            SequentialAnimation {
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: settingsScreen; property: "visible"; value: false }
                PropertyAction { target: browserScreen; property: "visible"; value: true }
                PropertyAnimation { target: browserScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "browserscreen"
            to: "settingsscreen"
            SequentialAnimation {
                PropertyAnimation { target: browserScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: browserScreen; property: "visible"; value: false }
                PropertyAction { target: settingsScreen; property: "visible"; value: true }
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "infoscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: infoScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: infoScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "homescreen"
            to: "backlogscreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: backlogScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: backlogScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "backlogscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: backlogScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: backlogScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "*"
            to: "suspendscreen"
            SequentialAnimation {
                PropertyAction { target: suspendScreen; property: "visible"; value: true }
                PropertyAnimation { target: suspendScreen; property: "opacity"; to: 1; duration: 220 }
                PropertyAction { target: homeScreen; property: "visible"; value: false }
                PropertyAction { target: softwareScreen; property: "visible"; value: false }
                PropertyAction { target: settingsScreen; property: "visible"; value: false }
                PropertyAction { target: storeScreen; property: "visible"; value: false }
                PropertyAction { target: infoScreen; property: "visible"; value: false }
                PropertyAction { target: browserScreen; property: "visible"; value: false }
                PropertyAction { target: albumScreen; property: "visible"; value: false }
                PropertyAction { target: gameShareScreen; property: "visible"; value: false }
                PropertyAction { target: chatScreen; property: "visible"; value: false }
                PropertyAction { target: backlogScreen; property: "visible"; value: false }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "homescreen"
            to: "gamesharescreen"
            SequentialAnimation {
                PropertyAnimation { target: homeScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: homeScreen; property: "visible"; value: false }
                PropertyAction { target: gameShareScreen; property: "visible"; value: true }
                PropertyAnimation { target: gameShareScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "gamesharescreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation { target: gameShareScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: gameShareScreen; property: "visible"; value: false }
                PropertyAction { target: homeScreen; property: "visible"; value: true }
                PropertyAnimation { target: homeScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "homescreen"
            to: "chatscreen"
            SequentialAnimation {
                PropertyAnimation { target: homeScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: homeScreen; property: "visible"; value: false }
                PropertyAction { target: chatScreen; property: "visible"; value: true }
                PropertyAnimation { target: chatScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "chatscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation { target: chatScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: chatScreen; property: "visible"; value: false }
                PropertyAction { target: homeScreen; property: "visible"; value: true }
                PropertyAnimation { target: homeScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "homescreen"
            to: "albumscreen"
            SequentialAnimation {
                PropertyAnimation { target: homeScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: homeScreen; property: "visible"; value: false }
                PropertyAction { target: albumScreen; property: "visible"; value: true }
                PropertyAnimation { target: albumScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "albumscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation { target: albumScreen; property: "opacity"; to: 0; duration: 180 }
                PropertyAction { target: albumScreen; property: "visible"; value: false }
                PropertyAction { target: homeScreen; property: "visible"; value: true }
                PropertyAnimation { target: homeScreen; property: "opacity"; to: 1; duration: 180 }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: "suspendscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: suspendScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: suspendScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
                ScriptAction { script: root.restoreActiveScreenFocus(); }
            }
        },
        Transition {
            from: ""
            to: "homescreen"
            ParallelAnimation {
                NumberAnimation {
                    target: homeScreen
                    property: "scale"
                    from: 1.2
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: homeScreen
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                }
            }
        }
    ]

    // Background
    Rectangle {
        id: background
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        color: theme.main
    }

    //starting collection is set here
    //E' un casino tutto innestato, devi un attimo capire come fare la ricerca UNA VOLTA e non 10mila come sta facendo ora, per ottimizzare il tutto
    Component.onCompleted: {
        root.state = "homescreen";
        refreshSettings();
        popToStackTimer();
        for (var i = 0; i < api.allGames.count; i++)
            console.log(api.allGames.get(i).title);

        currentCollection = -1;
        api.memory.unset('Last Collection');
        homeSfx.play();
    }

    SecondScreenHome {
        id: secondScreenHome
    }

    // Home screen
    HomeScreen {
        id: homeScreen
        hiddenApps: root.hiddenApps
        focus: true
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
    }

    SettingsScreen {
        id: settingsScreen
        opacity: 0
        visible: false
        anchors.fill: parent
    }

    InfoScreen {
        id: infoScreen
        opacity: 0
        visible: false
        anchors.fill: parent
    }

    StoreScreen {
        id: storeScreen
        opacity: 0
        visible: false
        anchors.fill: parent
    }

    BrowserScreen {
        id: browserScreen
        opacity: 0
        visible: false
        anchors.fill: parent
    }

    GameShareScreen {
        id: gameShareScreen
        opacity: 0
        visible: false
        anchors.fill: parent
    }

    ChatScreen {
        id: chatScreen
        opacity: 0
        visible: false
        anchors.fill: parent
    }

    AlbumScreen {
        id: albumScreen
        opacity: 0
        visible: false
        anchors.fill: parent
    }

    BacklogScreen {
        id: backlogScreen
        opacity: 0
        visible: false
        anchors {
            left: parent.left
            leftMargin: screenmargin
            right: parent.right
            rightMargin: screenmargin
            top: parent.top
            bottom: helpBar.top
        }
    }

    SuspendScreen {
        id: suspendScreen
        opacity: 0
        visible: false
        anchors.fill: parent
    }

    // All Software screen
    SoftwareScreen {
        id: softwareScreen
        opacity: 0
        visible: false
        anchors {
            left: parent.left// leftMargin: screenmargin
            right: parent.right// rightMargin: screenmargin
            top: parent.top
            bottom: parent.bottom
        }
    }

    //Changes Sort Option
    function cycleSort() {
        selectSfx.play();
        if (sortByIndex < softwareList.length - 1)
            sortByIndex++;
        else
            sortByIndex = 0;
        api.memory.set('sortIndex', sortByIndex);
    }

    Rectangle {
        id: gameDetailDim
        anchors.fill: parent
        color: "black"
        opacity: gameDetailOpen ? 0.6 : 0
        visible: opacity > 0
        z: 99
        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }
    }

    GameDetailScreen {
        id: gameDetailScreen
        currentGame: currentGame
        z: 100

        x: gameDetailOpen ? 0 : detailOriginX
        y: gameDetailOpen ? 0 : detailOriginY
        width: gameDetailOpen ? screenwidth : detailOriginWidth
        height: gameDetailOpen ? screenheight : detailOriginHeight
        radius: gameDetailOpen ? 0 : vpx(24)
        opacity: gameDetailOpen ? 1 : 0
        visible: opacity > 0.01

        Behavior on x {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 220
            }
        }
    }

    NewProfileScreen {
        id: newProfileScreen
    }

    SatelliteProfileScreen {
        id: satelliteProfileScreen
        onConfirmRequested: requestConfirm(title, subtitle, action, focusItem)
    }

    ProfilePicker {
        id: profilePicker
        onChosen: {
            pendingLauncherUser = name;
            var act = profileGateAction;
            profileGateAction = null;
            restoreFocusAfterProfile();
            if (act)
                act();
        }
        onCancelled: {
            profileGateAction = null;
            restoreFocusAfterProfile();
        }
    }

    UserSelectOverlay {
        id: userSelectOverlay
        onClosed: restoreFocusAfterProfile()
    }

    GameEditOverlay {
        id: gameEditOverlay
        onClosed: restoreFocusAfterProfile()
    }

    Global.SwitchKeyboard {
        id: globalSwitchKeyboard
    }

    // Help bar
    Item {
        id: helpBar
        anchors {
            left: parent.left
            leftMargin: screenmargin
            right: parent.right
            rightMargin: screenmargin
            bottom: parent.bottom
        }
        height: helpbarheight

        opacity: (homeScreen.focus && !homeScreen.expandedPanelOpen && !gameDetailOpen && !userSelectOverlay.isOpen && !gameEditOverlay.isOpen) ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        Rectangle {

            anchors.fill: parent
            color: theme.main
            opacity: softwareScreen.focus ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            opacity: homeScreen.focus ? 0 : 0.3
            color: theme.secondary
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        ControllerHelp {
            id: controllerHelp
            width: parent.width
            height: parent.height
            anchors {
                bottom: parent.bottom
            }
            showBack: !homeScreen.focus
            showCollControls: softwareScreen.focus
            showFav: softwareScreen.focus || homeScreen.focus
            showDetails: homeScreen.focus || softwareScreen.focus
        }
    }

    Timer {
        id: launchRecoveryTimer
        interval: 3500
        running: root.state === "playgame" || root.state === "playsoftware"
        repeat: false
        onTriggered: {
            root.launchingNow = false;
            if (root.state === "playgame") {
                homeScreen.opacity = 1;
                root.state = "homescreen";
            } else if (root.state === "playsoftware") {
                softwareScreen.opacity = 1;
                root.state = "softwarescreen";
            }
        }
    }

    SoundEffect {
        id: navSound
        source: "assets/audio/Klick.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: toSoftware
        source: "assets/audio/EnterBack.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: fillList
        source: "assets/audio/Select.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: backSfx
        source: "assets/audio/Nock.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: launchSfx
        source: "assets/audio/PopupRunTitle.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: homeSfx
        source: "assets/audio/Home.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: turnOnSfx
        source: "assets/audio/Turn On.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: turnOffSfx
        source: "assets/audio/Turn Off.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: selectSfx
        source: "assets/audio/This One.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: settingsSfx
        source: "assets/audio/Settings.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: menuNavSfx
        source: "assets/audio/Tick.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: borderSfx
        source: "assets/audio/Border.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 0.25 : 0.0
    }

    SoundEffect {
        id: storeSfx
        source: "assets/audio/store.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
        onStatusChanged: console.log("SFX store status:", status, source)
        onPlayingChanged: console.log("SFX store playing:", playing)
    }

    SoundEffect {
        id: detailSfx
        source: "assets/audio/detail.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
        onStatusChanged: console.log("SFX detail status:", status, source)
        onPlayingChanged: console.log("SFX detail playing:", playing)
    }

    SoundEffect {
        id: feedSfx
        source: "assets/audio/Dada 3.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: browserSfx
        source: "assets/audio/Browser.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: backlogSfx
        source: "assets/audio/Backlog.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: cloudSfx
        source: "assets/audio/Jig 0.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: albumSfx
        source: "assets/audio/Album.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: filesSfx
        source: "assets/audio/File.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: standbySfx
        source: "assets/audio/Standby.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: allSoftSfx
        source: "assets/audio/Allsf.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: userSfx
        source: "assets/audio/User.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }

    SoundEffect {
        id: newUserSfx
        source: "assets/audio/NewUser.wav"
        volume: (settings.uiSoundsEnabled !== "No") ? 1.0 : 0.0
    }
}
