// skylineOS 2 — SettingsScreen.qml (Switch 2 Split Settings: Profile, Friends, Customize Home, HUD & Colors, User & Browser, About)
import QtQuick 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

FocusScope {
    id: settingsRoot
    anchors.fill: parent

    property int currentTab: 0
    property string focusZone: "sidebar" // "sidebar" | "content"
    property int contentRowIdx: 0
    property int contentSubCol: 0
    property bool editingStepper: false
    property var customizeSteppers: [
        { key: "Background Transparency", opts: ["0","5","10","15","20","25","30","35","40","45","50","55","60","65","70","75","80","85","90","95","100"] },
        { key: "Background Blur", opts: ["0","5","10","15","20","25","30","35","40","45","50","55","60","65","70","75","80","85","90","95","100"] },
        { key: "Home Card Size", opts: ["25","30","35","40","45"] },
        { key: "Cover Spacing", opts: ["0.050","0.100","0.150","0.200","0.250"] },
        { key: "Border Gap", opts: ["5","10","15"] },
        { key: "Border Width", opts: ["5","10","15"] },
        { key: "Dock Size Pct", opts: ["10.0","15.0","20.0"] },
        { key: "Max games on Home Screen", opts: ["5","10","15","20","25"] },
        { key: "System Font Scale", opts: ["85","90","95","100","105","110","115","120","125","130","135"] }
    ]
    function maxContentRowsForTab(t) {
        if (t === 0) return 1;
        if (t === 1) return 1;
        if (t === 2) return 12; // Reset + UI Sounds + Game Bg + 9 steppers
        if (t === 3) return 9;  // 8 swatches + Polarity
        if (t === 4) return 9 + loadSavedUsers().length; // Active User + savedUsers + Ask + Mode + Photos + URL + Clock + Battery + Wifi + Memory/Reset
        return 1; // Tab 5 About
    }
    function syncScrollToRow() {
        var stepPx = (currentTab === 3) ? vpx(32) : vpx(66);
        var targetY = Math.max(0, contentRowIdx * stepPx - vpx(120));
        var maxY = Math.max(0, rightFlick.contentHeight - rightFlick.height);
        rightFlick.contentY = Math.min(maxY, targetY);
    }
    function isStepperRow() {
        return currentTab === 2 && contentRowIdx >= 3;
    }
    function adjustContentRow(dir) {
        if (currentTab === 2) {
            if (contentRowIdx === 0) resetCustomizeDefaults();
            else if (contentRowIdx === 1) setMem("UI Sounds", settings.uiSoundsEnabled === "Yes" ? "No" : "Yes");
            else if (contentRowIdx === 2) cycleValue("Game Background", ["Screenshot", "Fanart", "Boxart", "No"], settings.gameBackground, dir);
            else {
                var sIdx = contentRowIdx - 3;
                if (sIdx >= 0 && sIdx < customizeSteppers.length) {
                    var st = customizeSteppers[sIdx];
                    var curVal = api.memory.has(st.key) ? String(api.memory.get(st.key)) : st.opts[0];
                    cycleValue(st.key, st.opts, curVal, dir);
                }
            }
        } else if (currentTab === 3) {
            if (contentRowIdx < hudSwatches.length) {
                var nextSw = (contentRowIdx + dir + hudSwatches.length) % hudSwatches.length;
                contentRowIdx = nextSw;
                applyHudSwatch(hudSwatches[nextSw]);
            } else {
                var pols = ["Auto", "Light", "Dark"];
                var nextP = (contentSubCol + dir + pols.length) % pols.length;
                contentSubCol = nextP;
                applyPolarity(pols[nextP]);
            }
        } else if (currentTab === 4) {
            var uCount = loadSavedUsers().length;
            var offset = contentRowIdx - 1 - uCount;
            if (offset === 0) setMem("Multi User", settings.multiUser === "Yes" ? "No" : "Yes");
            else if (offset === 1) setMem("Browser Mode", contentSubCol === 0 ? "in-app" : "chrome");
            else if (offset === 4) setMem("Time Format", settings.timeFormat === "12hr" ? "24hr" : "12hr");
            else if (offset === 5) setMem("Display Battery Percentage", settings.batteryPercentSetting === "Yes" ? "No" : "Yes");
            else if (offset === 6) setMem("Display Wifi Icon", settings.showWifi === "Yes" ? "No" : "Yes");
        }
    }
    function activateContentRow() {
        if (currentTab === 0) {
            startInlineEdit("Username", activeUserName);
        } else if (currentTab === 1) {
            navSound.play();
        } else if (currentTab === 2) {
            if (contentRowIdx === 0) resetCustomizeDefaults();
            else if (contentRowIdx <= 2) adjustContentRow(1);
            else {
                editingStepper = !editingStepper;
                selectSfx.play();
            }
        } else if (currentTab === 3) {
            if (contentRowIdx < hudSwatches.length) applyHudSwatch(hudSwatches[contentRowIdx]);
            else {
                var pols = ["Auto", "Light", "Dark"];
                applyPolarity(pols[Math.max(0, Math.min(2, contentSubCol))]);
            }
        } else if (currentTab === 4) {
            var users = loadSavedUsers();
            var uCount = users.length;
            if (contentRowIdx === 0) {
                openUserSelect("¿Quién está jugando?", function() { settingsRoot.refreshProfileUi(); });
            } else if (contentRowIdx >= 1 && contentRowIdx <= uCount) {
                var u = users[contentRowIdx - 1];
                if (u) {
                    if (contentSubCol === 1 && uCount > 1) deleteSavedUser(u.id);
                    else selectSavedUser(u);
                }
            } else {
                var off = contentRowIdx - 1 - uCount;
                if (off === 0) setMem("Multi User", settings.multiUser === "Yes" ? "No" : "Yes");
                else if (off === 1) setMem("Browser Mode", contentSubCol === 0 ? "in-app" : "chrome");
                else if (off === 2) startInlineEdit("Photos Directory", settings.photosDirectory || "/storage/emulated/0/Pictures");
                else if (off === 3) startInlineEdit("Browser default link", settings.browserLink);
                else if (off === 4) setMem("Time Format", settings.timeFormat === "12hr" ? "24hr" : "12hr");
                else if (off === 5) setMem("Display Battery Percentage", settings.batteryPercentSetting === "Yes" ? "No" : "Yes");
                else if (off === 6) setMem("Display Wifi Icon", settings.showWifi === "Yes" ? "No" : "Yes");
                else if (off === 7) {
                    if (contentSubCol === 1) restoreAllSettings();
                    else { settingsRoot.showMemoryViewer = true; memoryViewerModal.open(); }
                }
            }
        } else if (currentTab === 5) {
            openInThemeBrowser("https://github.com/RBertoCases/skylineOS");
        }
    }
    property bool showMemoryViewer: false
    property bool editingTextField: false
    property string editingKey: ""
    property string editingDraft: ""

    property string activeUserName: (api.memory.has("Username") && api.memory.get("Username") !== "") ? String(api.memory.get("Username")) : "Mario"
    property string activeCharId: api.memory.has("ns2_active_character") ? String(api.memory.get("ns2_active_character")) : "mario"
    property string activeFriendCode: "SW-4821-7094-1122"
    property int refreshTick: 0

    property bool isDarkPage: (settings.appearanceMode === "Dark") || (settings.appearanceMode === "Auto" && settings.darkMode === "Yes")
    property color pageBg: isDarkPage ? "#1A1C21" : "#EFEFEF"
    property color sidebarBg: isDarkPage ? "#22252C" : "#EAEAEA"
    property color cardBg: isDarkPage ? "#2C303A" : "#FFFFFF"
    property color textMain: isDarkPage ? "#F3F4F6" : "#2C2C2C"
    property color textMuted: isDarkPage ? "#9CA3AF" : "#6B7280"
    property color dividerColor: isDarkPage ? "#353944" : "#C8C8C8"

    property var hudSwatches: [
        { id: "Auto", label: "Auto", hex: "#64748B" },
        { id: "Mario Red", label: "Mario Red", hex: "#E60012" },
        { id: "Luigi Green", label: "Luigi Green", hex: "#00A651" },
        { id: "Peach Pink", label: "Peach Pink", hex: "#FF5E99" },
        { id: "Yoshi Green", label: "Yoshi Green", hex: "#65C322" },
        { id: "DK Amber", label: "DK Amber", hex: "#E67E22" },
        { id: "Bowser Gold", label: "Bowser Gold", hex: "#D97706" },
        { id: "Switch Cyan", label: "Switch Cyan", hex: "#10AEBE" }
    ]

    property var navTabs: [
        { id: "profile", label: "Profile", sub: "", dividerAfter: true },
        { id: "friends", label: "Friend List", sub: "", dividerAfter: false },
        { id: "customize", label: "Customize", sub: "", dividerAfter: false },
        { id: "hud", label: "HUD", sub: "", dividerAfter: true },
        { id: "userSettings", label: "User Settings", sub: "", dividerAfter: false },
        { id: "about", label: "About", sub: "", dividerAfter: false }
    ]

    ListModel { id: playActivityModel }

    // Legacy compatibility list models for MemoryViewer inspection
    ListModel {
        id: legacyCompatModel
        ListElement { settingName: "Username"; setting: "" }
        ListElement { settingName: "UI Sounds"; setting: "" }
        ListElement { settingName: "Game Background"; setting: "" }
        ListElement { settingName: "Background Transparency"; setting: "" }
        ListElement { settingName: "Background Blur"; setting: "" }
        ListElement { settingName: "Home Card Size"; setting: "" }
        ListElement { settingName: "Cover Spacing"; setting: "" }
        ListElement { settingName: "Border Gap"; setting: "" }
        ListElement { settingName: "Border Width"; setting: "" }
        ListElement { settingName: "Dock Size Pct"; setting: "" }
        ListElement { settingName: "Max games on Home Screen"; setting: "" }
        ListElement { settingName: "Appearance Polarity"; setting: "" }
        ListElement { settingName: "Dark Mode"; setting: "" }
        ListElement { settingName: "HUD Theme Accent"; setting: "" }
        ListElement { settingName: "Browser Mode"; setting: "" }
        ListElement { settingName: "Browser default link"; setting: "" }
        ListElement { settingName: "Time Format"; setting: "" }
        ListElement { settingName: "Display Battery Percentage"; setting: "" }
        ListElement { settingName: "Display Wifi Icon"; setting: "" }
        ListElement { settingName: "Multi User"; setting: "" }
    }

    function openTab(idx) {
        if (idx >= 0 && idx < navTabs.length) currentTab = idx;
        refreshProfileUi();
    }

    function loadSavedUsers() {
        var fallbackJson = "[{\"id\":\"u1\",\"name\":\"Mario\",\"characterId\":\"mario\",\"friendCode\":\"SW-4821-7094-1122\"}]";
        var raw = api.memory.has("ns2_users_json") ? String(api.memory.get("ns2_users_json")) : fallbackJson;
        var arr = [];
        try { arr = JSON.parse(raw); } catch (e) { arr = []; }
        if (!arr || !arr.length) {
            try { arr = JSON.parse(fallbackJson); } catch (e2) { arr = []; }
        }
        return arr;
    }

    function selectSavedUser(u) {
        if (!u || !u.id) return;
        api.memory.set("ns2_active_user_id", String(u.id));
        api.memory.set("ns2_active_character", String(u.characterId || "mario"));
        api.memory.set("Username", String(u.name || "Player"));
        api.memory.set("Launcher User", String(u.name || "Player"));
        refreshSettings();
        refreshProfileUi();
        selectSfx.play();
    }

    function deleteSavedUser(uidToDelete) {
        var arr = loadSavedUsers();
        if (arr.length <= 1) return;
        var next = [];
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] && String(arr[i].id) !== String(uidToDelete)) next.push(arr[i]);
        }
        if (next.length === 0) return;
        api.memory.set("ns2_users_json", JSON.stringify(next));
        var activeId = api.memory.has("ns2_active_user_id") ? String(api.memory.get("ns2_active_user_id")) : "";
        if (activeId === String(uidToDelete)) {
            var fb = next[0];
            api.memory.set("ns2_active_user_id", String(fb.id));
            api.memory.set("ns2_active_character", String(fb.characterId || "mario"));
            api.memory.set("Username", String(fb.name || "Player"));
            api.memory.set("Launcher User", String(fb.name || "Player"));
        }
        refreshSettings();
        refreshProfileUi();
        backSfx.play();
    }

    function refreshProfileUi() {
        activeUserName = (api.memory.has("Username") && api.memory.get("Username") !== "") ? String(api.memory.get("Username")) : "Mario";
        activeCharId = api.memory.has("ns2_active_character") ? String(api.memory.get("ns2_active_character")) : "mario";
        var arr = loadSavedUsers();
        var activeId = api.memory.has("ns2_active_user_id") ? String(api.memory.get("ns2_active_user_id")) : "";
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] && String(arr[i].id) === activeId && arr[i].friendCode) {
                activeFriendCode = String(arr[i].friendCode);
                break;
            }
        }
        refreshPlayActivity();
        refreshTick++;
    }

    property string onlineGameTitle: "Ready to play"
    property string onlineGameCover: ""

    function resolveLatestGameObj() {
        if (listRecent && listRecent.games && listRecent.games.count > 0)
            return listRecent.games.get(0);
        if (api.allGames && api.allGames.count > 0)
            return api.allGames.get(0);
        return null;
    }

    function refreshPlayActivity() {
        playActivityModel.clear();
        var items = [];
        for (var i = 0; i < api.allGames.count; i++) {
            var g = api.allGames.get(i);
            var secs = api.memory.has(g.title) ? parseInt(api.memory.get(g.title)) : 0;
            if (isNaN(secs)) secs = 0;
            var seq = api.memory.has("PLAY_SEQ::" + g.title) ? parseInt(api.memory.get("PLAY_SEQ::" + g.title)) : 0;
            if (isNaN(seq)) seq = 0;
            var hrs = Math.floor(secs / 3600);
            var mins = Math.floor((secs % 3600) / 60);
            if (secs > 0 && hrs === 0 && mins === 0) mins = 1;
            var durText = hrs > 0 ? (hrs + "h " + mins + "m played") : (mins > 0 ? (mins + "m played") : "0m played");
            var lastAt = api.memory.has("LAST_PLAYED_AT::" + g.title) ? String(api.memory.get("LAST_PLAYED_AT::" + g.title)) : (secs > 0 ? "Recently" : "Not played yet");
            var cover = getGameCover(g);
            items.push({ title: getGameTitle(g), cover: cover, hours: hrs, rawSecs: secs, seq: seq, summary: durText + " \u00B7 " + lastAt });
        }
        items.sort(function(a, b) {
            if (b.seq !== a.seq) return b.seq - a.seq;
            return b.rawSecs - a.rawSecs;
        });
        var savedTitle = api.memory.has("LAST_PLAYED_TITLE") ? String(api.memory.get("LAST_PLAYED_TITLE") || "") : "";
        var savedCover = api.memory.has("LAST_PLAYED_COVER") ? String(api.memory.get("LAST_PLAYED_COVER") || "") : "";
        if (savedTitle !== "") {
            onlineGameTitle = savedTitle;
            onlineGameCover = savedCover;
        } else {
            var fb = resolveLatestGameObj();
            onlineGameTitle = fb ? getGameTitle(fb) : "Ready to play";
            onlineGameCover = fb ? getGameCover(fb) : "";
        }
        for (var j = 0; j < Math.min(5, items.length); j++) {
            playActivityModel.append(items[j]);
        }
    }

    function setMem(key, val) {
        api.memory.set(key, val);
        refreshSettings();
        refreshProfileUi();
    }

    function cycleValue(key, options, currentVal, dir) {
        var idx = -1;
        for (var i = 0; i < options.length; i++) {
            if (String(options[i]) === String(currentVal)) { idx = i; break; }
        }
        if (idx < 0) {
            var numCur = parseFloat(currentVal);
            if (!isNaN(numCur)) {
                var bestDiff = 999999;
                for (var k = 0; k < options.length; k++) {
                    var d = Math.abs(parseFloat(options[k]) - numCur);
                    if (d < bestDiff) { bestDiff = d; idx = k; }
                }
            }
        }
        if (idx < 0) idx = 0;
        var nextIdx = Math.max(0, Math.min(options.length - 1, idx + dir));
        if (String(options[nextIdx]) !== String(options[idx]) || String(currentVal) !== String(options[nextIdx])) {
            setMem(key, String(options[nextIdx]));
        }
        navSound.play();
    }

    function applyHudSwatch(swatch) {
        api.memory.set("HUD Theme Accent", swatch.id);
        if (swatch.id !== "Auto") {
            api.memory.set("Accent Light Mode", swatch.hex);
            api.memory.set("Accent Dark Mode", swatch.hex);
        }
        selectSfx.play();
        refreshSettings();
        refreshTick++;
    }

    function applyPolarity(modeLabel) {
        api.memory.set("Appearance Polarity", modeLabel);
        if (modeLabel === "Dark") api.memory.set("Dark Mode", "Yes");
        else if (modeLabel === "Light") api.memory.set("Dark Mode", "No");
        selectSfx.play();
        refreshSettings();
        refreshTick++;
    }

    function resetCustomizeDefaults() {
        api.memory.set("UI Sounds", "Yes");
        api.memory.set("Game Background", "Screenshot");
        api.memory.set("Background Transparency", "70");
        api.memory.set("Background Blur", "25");
        api.memory.set("Home Card Size", "35");
        api.memory.set("Cover Spacing", "0.150");
        api.memory.set("Border Gap", "5");
        api.memory.set("Border Width", "5");
        api.memory.set("Dock Size Pct", "15.0");
        api.memory.set("Max games on Home Screen", "15");
        api.memory.set("Enable DropShadows", "Yes");
        api.memory.set("System Font Scale", "100");
        selectSfx.play();
        refreshSettings();
        refreshTick++;
    }

    function restoreAllSettings() {
        resetCustomizeDefaults();
        api.memory.set("Appearance Polarity", "Dark");
        api.memory.set("Dark Mode", "Yes");
        api.memory.set("HUD Theme Accent", "Auto");
        api.memory.set("Accent Light Mode", "#10AEBE");
        api.memory.set("Accent Dark Mode", "#1d9bf3");
        api.memory.set("Browser Mode", "in-app");
        api.memory.set("Browser default link", "https://www.nintendo.com");
        api.memory.set("Time Format", "12hr");
        api.memory.set("Display Battery Percentage", "No");
        api.memory.set("Display Wifi Icon", "Yes");
        api.memory.set("Multi User", "No");
        turnOnSfx.play();
        refreshSettings();
        refreshProfileUi();
    }

    function startInlineEdit(key, initialVal) {
        if (typeof openSwitchKeyboard === "function") {
            var isUrlOrPath = (key.indexOf("link") >= 0 || key.indexOf("Directory") >= 0 || key.indexOf("URL") >= 0);
            var maxL = isUrlOrPath ? 200 : 32;
            openSwitchKeyboard(tr("Edit ") + key, String(initialVal || ""), isUrlOrPath, maxL, function(val) {
                var cleanVal = String(val || "").trim();
                if (key === "Username" && cleanVal === "") cleanVal = "Mario";
                if (key === "Photos Directory" && cleanVal === "") cleanVal = "/storage/emulated/0/Pictures";
                api.memory.set(key, cleanVal);
                if (key === "Username") api.memory.set("Launcher User", cleanVal);
                if (key === "Photos Directory") {
                    api.memory.set("Gallery Folder Label", cleanVal);
                    if (typeof albumScreen !== "undefined" && albumScreen.scanScreenshots) albumScreen.scanScreenshots();
                }
                refreshSettings();
                refreshProfileUi();
                selectSfx.play();
                settingsRoot.forceActiveFocus();
            }, function() {
                settingsRoot.forceActiveFocus();
            });
        }
    }

    onVisibleChanged: {
        if (visible) {
            showMemoryViewer = false;
            editingTextField = false;
            editingStepper = false;
            refreshProfileUi();
            settingsRoot.forceActiveFocus();
        }
    }

    Keys.onUpPressed: {
        if (showMemoryViewer || editingTextField) return;
        if (editingStepper) { event.accepted = true; return; }
        navSound.play();
        if (focusZone === "content") {
            if (currentTab === 3) {
                if (contentRowIdx >= 8) contentRowIdx = 4;
                else if (contentRowIdx >= 4) contentRowIdx -= 4;
                else { contentRowIdx = 8; contentSubCol = 0; }
            } else {
                var maxR = maxContentRowsForTab(currentTab);
                contentRowIdx = (contentRowIdx - 1 + maxR) % maxR;
                contentSubCol = 0;
            }
            syncScrollToRow();
        } else {
            currentTab = (currentTab - 1 + navTabs.length) % navTabs.length;
            contentRowIdx = 0;
            contentSubCol = 0;
            rightFlick.contentY = 0;
        }
    }
    Keys.onDownPressed: {
        if (showMemoryViewer || editingTextField) return;
        if (editingStepper) { event.accepted = true; return; }
        navSound.play();
        if (focusZone === "content") {
            if (currentTab === 3) {
                if (contentRowIdx < 4) contentRowIdx += 4;
                else if (contentRowIdx < 8) { contentRowIdx = 8; contentSubCol = 0; }
                else contentRowIdx = 0;
            } else {
                var maxR = maxContentRowsForTab(currentTab);
                contentRowIdx = (contentRowIdx + 1) % maxR;
                contentSubCol = 0;
            }
            syncScrollToRow();
        } else {
            currentTab = (currentTab + 1) % navTabs.length;
            contentRowIdx = 0;
            contentSubCol = 0;
            rightFlick.contentY = 0;
        }
    }
    Keys.onLeftPressed: {
        if (showMemoryViewer || editingTextField) return;
        if (editingStepper && isStepperRow()) {
            adjustContentRow(-1);
            return;
        }
        if (focusZone === "content") {
            if (currentTab === 3) {
                if (contentRowIdx < 8) {
                    if (contentRowIdx % 4 === 0) focusZone = "sidebar";
                    else contentRowIdx--;
                } else {
                    if (contentSubCol > 0) contentSubCol--;
                    else focusZone = "sidebar";
                }
            } else if (currentTab === 2 && contentRowIdx >= 3) {
                focusZone = "sidebar";
            } else if (currentTab === 4) {
                var uCount = loadSavedUsers().length;
                var isSavedUserMulti = (contentRowIdx >= 1 && contentRowIdx <= uCount && uCount > 1);
                var off = contentRowIdx - 1 - uCount;
                var hasTwoCols = isSavedUserMulti || off === 1 || off === 7;
                if (hasTwoCols && contentSubCol > 0) contentSubCol--;
                else focusZone = "sidebar";
            } else {
                focusZone = "sidebar";
            }
            navSound.play();
        }
    }
    Keys.onRightPressed: {
        if (showMemoryViewer || editingTextField) return;
        if (editingStepper && isStepperRow()) {
            adjustContentRow(1);
            return;
        }
        if (focusZone === "sidebar") {
            focusZone = "content";
            contentRowIdx = 0;
            contentSubCol = 0;
            syncScrollToRow();
            navSound.play();
        } else if (currentTab === 3) {
            if (contentRowIdx < 8) contentRowIdx = (contentRowIdx % 4 === 3) ? contentRowIdx : (contentRowIdx + 1);
            else contentSubCol = Math.min(2, contentSubCol + 1);
            navSound.play();
        } else if (currentTab === 4) {
            var uCount = loadSavedUsers().length;
            var isSavedUserMulti = (contentRowIdx >= 1 && contentRowIdx <= uCount && uCount > 1);
            var off = contentRowIdx - 1 - uCount;
            if (isSavedUserMulti || off === 1 || off === 7) contentSubCol = 1;
            navSound.play();
        }
    }
    Keys.onBackPressed: {
        if (showMemoryViewer || editingTextField) return;
        event.accepted = true;
        backSfx.play();
        if (editingStepper) { editingStepper = false; return; }
        showHomeScreen();
    }
    Keys.onEscapePressed: {
        if (showMemoryViewer || editingTextField) return;
        event.accepted = true;
        backSfx.play();
        if (editingStepper) { editingStepper = false; return; }
        if (focusZone === "content") focusZone = "sidebar";
        else showHomeScreen();
    }
    Keys.onReleased: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function") root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
    }

    Keys.onPressed: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
        if (showMemoryViewer || editingTextField) return;
        if ((api.keys.isCancel(event) || event.key === Qt.Key_Escape || event.key === Qt.Key_B || event.key === Qt.Key_Backspace) && !event.isAutoRepeat) {
            event.accepted = true;
            backSfx.play();
            if (editingStepper) { editingStepper = false; return; }
            if (focusZone === "content") focusZone = "sidebar";
            else showHomeScreen();
        } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (focusZone === "content") {
                activateContentRow();
            } else {
                navSound.play();
                focusZone = "content";
                contentRowIdx = 0;
                contentSubCol = 0;
                syncScrollToRow();
            }
        }
    }

    Rectangle { anchors.fill: parent; color: settingsRoot.pageBg }

    // Top Header Row: Avatar + "{User}'s Settings" + Hairline Divider
    Item {
        id: headerBox
        anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.12)

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: vpx(16)

            Item {
                width: Math.round(screenheight * 0.072); height: width; anchors.verticalCenter: parent.verticalCenter
                Image { id: hdrAv; anchors.fill: parent; source: "../assets/images/avatars/" + settingsRoot.activeCharId + ".png"; fillMode: Image.PreserveAspectCrop; visible: false }
                Rectangle { id: hdrMask; anchors.fill: parent; radius: width / 2; visible: false }
                OpacityMask { anchors.fill: parent; source: hdrAv; maskSource: hdrMask }
            }
            Text {
                text: settingsRoot.activeUserName + "\u2019s Settings"
                color: settingsRoot.textMain
                font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.044); font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: settingsRoot.dividerColor }
    }

    // Main Split Layout (Left 29.5% Sidebar / Right Content Pane)
    Item {
        id: splitBody
        anchors { top: headerBox.bottom; left: parent.left; right: parent.right; bottom: settingsFooter.top }

        Rectangle {
            id: leftSidebar
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            width: Math.round(parent.width * 0.295)
            color: settingsRoot.sidebarBg

            Column {
                anchors { top: parent.top; topMargin: Math.round(screenheight * 0.03); left: parent.left; leftMargin: screenmargin; right: parent.right; rightMargin: vpx(16) }
                spacing: vpx(6)

                Repeater {
                    model: settingsRoot.navTabs
                    delegate: Column {
                        width: parent.width
                        spacing: vpx(8)
                        property bool sel: index === settingsRoot.currentTab

                        Rectangle {
                            width: parent.width
                            height: modelData.sub !== "" ? vpx(64) : vpx(54)
                            color: sel ? settingsRoot.cardBg : "transparent"
                            border.width: sel ? vpx(3) : 0
                            border.color: sel ? theme.accent : "transparent"

                            Rectangle {
                                visible: sel
                                anchors { left: parent.left; leftMargin: vpx(7); top: parent.top; topMargin: vpx(8); bottom: parent.bottom; bottomMargin: vpx(8) }
                                width: vpx(3.5); color: theme.accent
                            }
                            Column {
                                anchors { left: parent.left; leftMargin: vpx(18); verticalCenter: parent.verticalCenter }
                                spacing: vpx(2)
                                Text { text: tr(modelData.label); color: sel ? theme.accent : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.042 * fontScale); font.bold: sel }
                                Text { visible: modelData.sub !== ""; text: modelData.sub; color: settingsRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.026) }
                            }
                            MouseArea { anchors.fill: parent; onClicked: { navSound.play(); settingsRoot.editingStepper = false; settingsRoot.currentTab = index; } }
                        }

                        Rectangle { visible: modelData.dividerAfter; width: parent.width; height: 1; color: settingsRoot.dividerColor }
                    }
                }
            }
        }

        // Right Content Pane
        Flickable {
            id: rightFlick
            anchors { top: parent.top; bottom: parent.bottom; left: leftSidebar.right; right: parent.right; leftMargin: vpx(34); rightMargin: screenmargin; topMargin: vpx(22); bottomMargin: vpx(14) }
            contentHeight: rightContentCol.height + vpx(24)
            clip: true

            Column {
                id: rightContentCol
                width: parent.width
                spacing: vpx(16)

                // TAB 0: PROFILE
                Column {
                    visible: settingsRoot.currentTab === 0
                    width: parent.width; spacing: vpx(18)

                    Row {
                        width: parent.width; spacing: vpx(24)

                        // Square Profile Portrait
                        Image {
                            width: Math.round(screenheight * 0.245); height: width
                            source: "../assets/images/avatars/" + settingsRoot.activeCharId + ".png"
                            fillMode: Image.PreserveAspectCrop; smooth: true
                        }

                        Column {
                            width: parent.width - Math.round(screenheight * 0.245) - vpx(24)
                            spacing: 0

                            Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                            // Username Row + Edit
                            Item {
                                width: parent.width; height: vpx(58)
                                Text { anchors { left: parent.left; verticalCenter: parent.verticalCenter } text: settingsRoot.activeUserName; color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.032) }
                                Rectangle {
                                    property bool btnFocused: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 0 && settingsRoot.contentRowIdx === 0
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    width: vpx(80); height: vpx(40); radius: vpx(8); color: settingsRoot.sidebarBg
                                    border.width: btnFocused ? vpx(3) : 1
                                    border.color: btnFocused ? theme.accent : settingsRoot.dividerColor
                                    Text { anchors.centerIn: parent; text: tr("Edit"); color: btnFocused ? theme.accent : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale); font.bold: btnFocused }
                                    MouseArea { anchors.fill: parent; onClicked: settingsRoot.startInlineEdit("Username", settingsRoot.activeUserName) }
                                }
                            }
                            Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                            // Online Status + Current Game
                            Item {
                                width: parent.width; height: vpx(70)
                                Row {
                                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                    spacing: vpx(14)
                                    Image {
                                        width: vpx(50); height: vpx(60)
                                        source: settingsRoot.onlineGameCover
                                        fillMode: Image.PreserveAspectCrop; smooth: true
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: vpx(4)
                                        Row {
                                            spacing: vpx(6)
                                            Rectangle { width: vpx(10); height: vpx(10); radius: vpx(2); color: "#2ED573"; anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: "Online"; color: "#2ED573"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.032); font.bold: true }
                                        }
                                        Text { text: settingsRoot.onlineGameTitle; color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.034 * fontScale); font.bold: true }
                                    }
                                }
                            }
                            Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                            Item {
                                width: parent.width; height: vpx(58)
                                Text {
                                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                    text: "Friend Code: " + settingsRoot.activeFriendCode
                                    color: settingsRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.032 * fontScale)
                                }
                            }
                        }
                    }

                    // Play Activity
                    Column {
                        width: parent.width; spacing: vpx(10)
                        Row {
                            spacing: vpx(10)
                            Rectangle { width: vpx(5); height: vpx(22); color: settingsRoot.textMuted; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: tr("Play Activity"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.038); font.bold: true }
                        }
                        Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                        Repeater {
                            model: playActivityModel
                            delegate: Column {
                                width: parent.width
                                Row {
                                    width: parent.width; height: vpx(64); spacing: vpx(14)
                                    Image { width: vpx(48); height: vpx(48); source: model.cover; fillMode: Image.PreserveAspectCrop; smooth: true; anchors.verticalCenter: parent.verticalCenter }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: vpx(3)
                                        Text { text: model.title; color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.033); font.bold: true }
                                        Text { text: model.summary; color: theme.accent; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.028) }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }
                            }
                        }
                    }
                }

                // TAB 1: FRIEND LIST
                Column {
                    visible: settingsRoot.currentTab === 1
                    width: parent.width; spacing: vpx(10)

                    Row {
                        spacing: vpx(8)
                        Rectangle { width: vpx(4); height: vpx(18); color: theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: tr("Friend List"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.031); font.bold: true }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    Rectangle {
                        property bool cardFocused: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 1 && settingsRoot.contentRowIdx === 0
                        width: parent.width
                        height: vpx(136)
                        radius: vpx(12)
                        color: settingsRoot.cardBg
                        border.width: cardFocused ? vpx(3) : 1
                        border.color: cardFocused ? theme.accent : settingsRoot.dividerColor
                        Column {
                            anchors.centerIn: parent
                            width: parent.width - vpx(40)
                            spacing: vpx(6)
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tr("No Friends Added Yet")
                                color: settingsRoot.textMain
                                font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.028); font.bold: true
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: tr("Share your Friend Code below to connect with friends.")
                                color: settingsRoot.textMuted
                                font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022)
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Friend Code: " + settingsRoot.activeFriendCode
                                color: theme.accent
                                font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true
                            }
                        }
                    }
                }

                // TAB 2: CUSTOMIZE HOME
                Column {
                    visible: settingsRoot.currentTab === 2
                    width: parent.width; spacing: vpx(4)

                    Item {
                        width: parent.width; height: vpx(48)
                        Row {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            spacing: vpx(10)
                            Rectangle { width: vpx(5); height: vpx(22); color: theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: tr("Customize Home"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.038); font.bold: true }
                        }
                        Rectangle {
                            property bool btnFocused: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 2 && settingsRoot.contentRowIdx === 0
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: vpx(114); height: vpx(42); radius: vpx(14); color: settingsRoot.sidebarBg
                            border.width: btnFocused ? vpx(3) : 1
                            border.color: btnFocused ? theme.accent : settingsRoot.dividerColor
                            Text { anchors.centerIn: parent; text: tr("Reset"); color: theme.accent; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.031 * fontScale); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: settingsRoot.resetCustomizeDefaults() }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Toggle: UI Sounds (Row 1)
                    Rectangle {
                        id: uiSoundsRow
                        property bool rowFocused: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 2 && settingsRoot.contentRowIdx === 1
                        width: parent.width; height: vpx(66); radius: vpx(8)
                        color: rowFocused ? settingsRoot.cardBg : "transparent"
                        border.width: rowFocused ? vpx(3) : 0
                        border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(12); verticalCenter: parent.verticalCenter } text: tr("UI Sounds"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.034 * fontScale); font.bold: rowFocused }
                        Rectangle {
                            anchors { right: parent.right; rightMargin: vpx(12); verticalCenter: parent.verticalCenter }
                            width: vpx(106); height: vpx(42); radius: height / 2
                            color: settings.uiSoundsEnabled === "Yes" ? theme.accent : settingsRoot.sidebarBg
                            border.width: uiSoundsRow.rowFocused ? vpx(2) : 0; border.color: "#FFFFFF"
                            Text { anchors.centerIn: parent; text: settings.uiSoundsEnabled === "Yes" ? "ON" : "OFF"; color: settings.uiSoundsEnabled === "Yes" ? "#FFFFFF" : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.032 * fontScale); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: settingsRoot.setMem("UI Sounds", settings.uiSoundsEnabled === "Yes" ? "No" : "Yes") }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Toggle: Game Background (Row 2)
                    Rectangle {
                        id: gameBgRow
                        property bool rowFocused: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 2 && settingsRoot.contentRowIdx === 2
                        width: parent.width; height: vpx(66); radius: vpx(8)
                        color: rowFocused ? settingsRoot.cardBg : "transparent"
                        border.width: rowFocused ? vpx(3) : 0
                        border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(12); verticalCenter: parent.verticalCenter } text: tr("Game Background"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.034 * fontScale); font.bold: rowFocused }
                        Rectangle {
                            anchors { right: parent.right; rightMargin: vpx(12); verticalCenter: parent.verticalCenter }
                            width: vpx(172); height: vpx(42); radius: height / 2
                            color: settings.gameBackground !== "No" ? theme.accent : settingsRoot.sidebarBg
                            border.width: gameBgRow.rowFocused ? vpx(2) : 0; border.color: "#FFFFFF"
                            Text { anchors.centerIn: parent; text: settings.gameBackground; color: settings.gameBackground !== "No" ? "#FFFFFF" : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.032 * fontScale); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: settingsRoot.cycleValue("Game Background", ["Screenshot", "Fanart", "Boxart", "No"], settings.gameBackground, 1) }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Stepper rows (Rows 3..11) — step 5, press A to lock/edit with Left/Right
                    Repeater {
                        model: [
                            { label: "Background Transparency (%)", key: "Background Transparency", val: settings.bgTransparency, opts: ["0","5","10","15","20","25","30","35","40","45","50","55","60","65","70","75","80","85","90","95","100"] },
                            { label: "Background Blur (%)", key: "Background Blur", val: String(settings.bgBlur !== undefined ? settings.bgBlur : 25), opts: ["0","5","10","15","20","25","30","35","40","45","50","55","60","65","70","75","80","85","90","95","100"] },
                            { label: "Home Card Size (%)", key: "Home Card Size", val: settings.homeCardSize, opts: ["25","30","35","40","45"] },
                            { label: "Cover Spacing", key: "Cover Spacing", val: String(settings.cardSpacingRatio), opts: ["0.050","0.100","0.150","0.200","0.250"] },
                            { label: "Border Gap (px @720p)", key: "Border Gap", val: String(settings.borderGap720), opts: ["5","10","15"] },
                            { label: "Border Width (px @720p)", key: "Border Width", val: String(settings.borderThick720), opts: ["5","10","15"] },
                            { label: "Dock Size Pct (%)", key: "Dock Size Pct", val: String(settings.dockHeightPct), opts: ["10.0","15.0","20.0"] },
                            { label: "Max Games on Home", key: "Max games on Home Screen", val: String(settings.softCount), opts: ["5","10","15","20","25"] },
                            { label: "System Font Size (%)", key: "System Font Scale", val: String(settings.systemFontScale || 100), opts: ["85","90","95","100","105","110","115","120","125","130","135"] }
                        ]
                        delegate: Column {
                            width: parent.width
                            property bool rowFocused: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 2 && settingsRoot.contentRowIdx === (index + 3)
                            property bool rowEditing: rowFocused && settingsRoot.editingStepper
                            Rectangle {
                                width: parent.width; height: vpx(68); radius: vpx(10)
                                color: rowEditing ? theme.accent : (rowFocused ? settingsRoot.cardBg : "transparent")
                                border.width: rowFocused ? vpx(3) : 0
                                border.color: rowEditing ? "#FFFFFF" : theme.accent
                                Text { anchors { left: parent.left; leftMargin: vpx(12); verticalCenter: parent.verticalCenter } text: tr(modelData.label); color: rowEditing ? "#FFFFFF" : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.034 * fontScale); font.bold: rowFocused }
                                Row {
                                    anchors { right: parent.right; rightMargin: vpx(12); verticalCenter: parent.verticalCenter }
                                    spacing: vpx(12)
                                    Rectangle {
                                        width: vpx(44); height: vpx(44); radius: vpx(8)
                                        color: rowEditing ? "#FFFFFF" : settingsRoot.sidebarBg
                                        border.width: vpx(2); border.color: rowEditing ? "#FFFFFF" : settingsRoot.dividerColor
                                        Text { anchors.centerIn: parent; text: "<"; color: rowEditing ? theme.accent : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.032); font.bold: true }
                                        MouseArea { anchors.fill: parent; onClicked: settingsRoot.cycleValue(modelData.key, modelData.opts, modelData.val, -1) }
                                    }
                                    Text { width: vpx(82); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; text: modelData.val; color: rowEditing ? "#FFFFFF" : theme.accent; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.034); font.bold: true }
                                    Rectangle {
                                        width: vpx(44); height: vpx(44); radius: vpx(8)
                                        color: rowEditing ? "#FFFFFF" : settingsRoot.sidebarBg
                                        border.width: vpx(2); border.color: rowEditing ? "#FFFFFF" : settingsRoot.dividerColor
                                        Text { anchors.centerIn: parent; text: ">"; color: rowEditing ? theme.accent : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.032); font.bold: true }
                                        MouseArea { anchors.fill: parent; onClicked: settingsRoot.cycleValue(modelData.key, modelData.opts, modelData.val, 1) }
                                    }
                                }
                            }
                            Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }
                        }
                    }
                }

                // TAB 3: HUD & COLORS (4x2 Circular Swatch Grid + Appearance Polarity)
                Column {
                    visible: settingsRoot.currentTab === 3
                    width: parent.width; spacing: vpx(14)

                    Row {
                        spacing: vpx(8)
                        Rectangle { width: vpx(4); height: vpx(18); color: theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: tr("HUD & Colors"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.031); font.bold: true }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    Text { text: tr("Theme Accent Color"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale); font.bold: true }

                    Grid {
                        width: parent.width
                        columns: 4
                        rowSpacing: vpx(18)
                        columnSpacing: vpx(14)

                        Repeater {
                            model: settingsRoot.hudSwatches
                            delegate: Item {
                                width: Math.floor((parent.width - vpx(42)) / 4)
                                height: vpx(108)
                                property bool selected: settings.hudThemeId === modelData.id
                                property bool focusedSwatch: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 3 && settingsRoot.contentRowIdx === index

                                Rectangle {
                                    anchors.fill: parent; radius: vpx(12); color: "transparent"
                                    border.width: focusedSwatch ? vpx(3) : 0; border.color: theme.accent
                                }

                                Column {
                                    anchors.centerIn: parent; spacing: vpx(6)
                                    Rectangle {
                                        width: vpx(64); height: vpx(64); radius: width / 2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: modelData.hex
                                        border.width: (selected || focusedSwatch) ? vpx(4) : 0
                                        border.color: settingsRoot.isDarkPage ? "#FFFFFF" : "#111111"
                                        Text { visible: selected; anchors.centerIn: parent; text: "✓"; color: "#FFFFFF"; font.pixelSize: vpx(18); font.bold: true }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.label
                                        color: focusedSwatch ? theme.accent : (settingsRoot.isDarkPage ? "#FFFFFF" : "#111111")
                                        font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023 * fontScale); font.bold: true
                                    }
                                }
                                MouseArea { anchors.fill: parent; onClicked: settingsRoot.applyHudSwatch(modelData) }
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    Rectangle {
                        property bool polRowFocused: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 3 && settingsRoot.contentRowIdx === 8
                        width: parent.width; height: vpx(60); radius: vpx(8)
                        color: polRowFocused ? settingsRoot.cardBg : "transparent"
                        border.width: polRowFocused ? vpx(3) : 0; border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter } text: tr("Appearance Polarity"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                        Row {
                            anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                            spacing: vpx(8)
                            Repeater {
                                model: ["Auto", "Light", "Dark"]
                                delegate: Rectangle {
                                    property bool active: settings.appearanceMode === modelData
                                    property bool btnF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 3 && settingsRoot.contentRowIdx === 8 && settingsRoot.contentSubCol === index
                                    width: vpx(74); height: vpx(38); radius: height / 2
                                    color: active ? theme.accent : settingsRoot.sidebarBg
                                    border.width: btnF ? vpx(3) : 0; border.color: "#FFFFFF"
                                    Text { anchors.centerIn: parent; text: modelData; color: active ? "#FFFFFF" : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale); font.bold: active || btnF }
                                    MouseArea { anchors.fill: parent; onClicked: settingsRoot.applyPolarity(modelData) }
                                }
                            }
                        }
                    }
                }

                // TAB 4: USER & BROWSER SETTINGS
                Column {
                    id: tab4Col
                    visible: settingsRoot.currentTab === 4
                    width: parent.width; spacing: vpx(2)
                    property int savedUserCount: settingsRoot.refreshTick >= 0 ? settingsRoot.loadSavedUsers().length : 1

                    Row {
                        height: vpx(36); spacing: vpx(8)
                        Rectangle { width: vpx(4); height: vpx(18); color: theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: tr("User & Browser"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.031); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Row 0: Active User Profile Switcher
                    Rectangle {
                        id: activeUserRow
                        property bool rowF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 4 && settingsRoot.contentRowIdx === 0
                        width: parent.width; height: vpx(60); radius: vpx(8)
                        color: rowF ? settingsRoot.cardBg : "transparent"
                        border.width: rowF ? vpx(3) : 0; border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter } text: tr("Active User Profile"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                        Rectangle {
                            anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                            width: vpx(210); height: vpx(36); radius: vpx(8); color: theme.accent
                            border.width: activeUserRow.rowF ? vpx(2) : 0; border.color: "#FFFFFF"
                            Text { anchors.centerIn: parent; text: tr("Switch or Add (+) User"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: openUserSelect("¿Quién está jugando?", function() { settingsRoot.refreshProfileUi(); }) }
                        }
                    }

                    // Rows 1..uCount: Saved User Profiles
                    Column {
                        width: parent.width
                        spacing: vpx(6)
                        Repeater {
                            model: settingsRoot.refreshTick >= 0 ? settingsRoot.loadSavedUsers() : []
                            delegate: Rectangle {
                                property string activeUid: api.memory.has("ns2_active_user_id") ? String(api.memory.get("ns2_active_user_id")) : ""
                                property bool isActive: String(modelData.id) === activeUid
                                property int totalUsers: settingsRoot.loadSavedUsers().length
                                property bool rowF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 4 && settingsRoot.contentRowIdx === (index + 1)
                                width: parent.width
                                height: vpx(54)
                                radius: vpx(8)
                                color: settingsRoot.cardBg
                                border.width: rowF ? vpx(3) : (isActive ? vpx(2) : 1)
                                border.color: rowF ? theme.accent : (isActive ? theme.accent : settingsRoot.dividerColor)

                                Row {
                                    anchors { left: parent.left; leftMargin: vpx(12); verticalCenter: parent.verticalCenter }
                                    spacing: vpx(12)
                                    Image {
                                        width: vpx(36); height: vpx(36)
                                        source: "../assets/images/avatars/" + (modelData.characterId || "mario") + ".png"
                                        fillMode: Image.PreserveAspectCrop; smooth: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: String(modelData.name || "Player")
                                        color: isActive ? theme.accent : settingsRoot.textMain
                                        font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.024); font.bold: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Rectangle {
                                        visible: isActive
                                        width: activeLbl.implicitWidth + vpx(14); height: vpx(22); radius: vpx(11)
                                        color: theme.accent; anchors.verticalCenter: parent.verticalCenter
                                        Text { id: activeLbl; anchors.centerIn: parent; text: "Active"; color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true }
                                    }
                                }

                                Row {
                                    anchors { right: parent.right; rightMargin: vpx(12); verticalCenter: parent.verticalCenter }
                                    spacing: vpx(8)
                                    Rectangle {
                                        visible: !isActive
                                        property bool selF: rowF && settingsRoot.contentSubCol === 0
                                        width: vpx(76); height: vpx(32); radius: vpx(6)
                                        color: settingsRoot.sidebarBg
                                        border.width: selF ? vpx(2.5) : 1; border.color: selF ? theme.accent : settingsRoot.dividerColor
                                        Text { anchors.centerIn: parent; text: tr("Select"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.020); font.bold: true }
                                        MouseArea { anchors.fill: parent; onClicked: settingsRoot.selectSavedUser(modelData) }
                                    }
                                    Rectangle {
                                        visible: totalUsers > 1
                                        property bool delF: rowF && settingsRoot.contentSubCol === 1
                                        width: vpx(86); height: vpx(32); radius: vpx(6)
                                        color: "#E60012"
                                        border.width: delF ? vpx(2.5) : 0; border.color: "#FFFFFF"
                                        Text { anchors.centerIn: parent; text: "- " + tr("Delete"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.020); font.bold: true }
                                        MouseArea { anchors.fill: parent; onClicked: settingsRoot.deleteSavedUser(modelData.id) }
                                    }
                                }
                            }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Ask User on Play (off = 0)
                    Rectangle {
                        id: askUserRow
                        property bool rowF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 4 && settingsRoot.contentRowIdx === (1 + tab4Col.savedUserCount)
                        width: parent.width; height: vpx(58); radius: vpx(8)
                        color: rowF ? settingsRoot.cardBg : "transparent"; border.width: rowF ? vpx(3) : 0; border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter } text: tr("Ask User on Play"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                        Rectangle {
                            anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                            width: vpx(82); height: vpx(38); radius: height / 2
                            color: settings.multiUser === "Yes" ? theme.accent : settingsRoot.sidebarBg
                            border.width: askUserRow.rowF ? vpx(2) : 0; border.color: "#FFFFFF"
                            Text { anchors.centerIn: parent; text: settings.multiUser === "Yes" ? "ON" : "OFF"; color: settings.multiUser === "Yes" ? "#FFFFFF" : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: settingsRoot.setMem("Multi User", settings.multiUser === "Yes" ? "No" : "Yes") }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Internet Browser Mode (off = 1)
                    Rectangle {
                        id: browserModeRow
                        property bool rowF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 4 && settingsRoot.contentRowIdx === (2 + tab4Col.savedUserCount)
                        width: parent.width; height: vpx(58); radius: vpx(8)
                        color: rowF ? settingsRoot.cardBg : "transparent"; border.width: rowF ? vpx(3) : 0; border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter } text: tr("Internet Browser Mode"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                        Row {
                            anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                            spacing: vpx(8)
                            Rectangle {
                                property bool subF: browserModeRow.rowF && settingsRoot.contentSubCol === 0
                                width: vpx(148); height: vpx(38); radius: vpx(8)
                                color: settings.browserMode === "in-app" ? theme.accent : settingsRoot.sidebarBg
                                border.width: subF ? vpx(2.5) : 0; border.color: "#FFFFFF"
                                Text { anchors.centerIn: parent; text: "In-App Browser"; color: settings.browserMode === "in-app" ? "#FFFFFF" : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.021); font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: settingsRoot.setMem("Browser Mode", "in-app") }
                            }
                            Rectangle {
                                property bool subF: browserModeRow.rowF && settingsRoot.contentSubCol === 1
                                width: vpx(148); height: vpx(38); radius: vpx(8)
                                color: settings.browserMode === "chrome" ? theme.accent : settingsRoot.sidebarBg
                                border.width: subF ? vpx(2.5) : 0; border.color: "#FFFFFF"
                                Text { anchors.centerIn: parent; text: "Open in Chrome"; color: settings.browserMode === "chrome" ? "#FFFFFF" : settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.021); font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: settingsRoot.setMem("Browser Mode", "chrome") }
                            }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Photos Directory Root (off = 2)
                    Rectangle {
                        id: photosDirRow
                        property bool rowF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 4 && settingsRoot.contentRowIdx === (3 + tab4Col.savedUserCount)
                        width: parent.width; height: vpx(58); radius: vpx(8)
                        color: rowF ? settingsRoot.cardBg : "transparent"; border.width: rowF ? vpx(3) : 0; border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter } text: tr("Photos Directory"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                        Rectangle {
                            anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                            width: vpx(300); height: vpx(38); radius: vpx(8); color: settingsRoot.sidebarBg; border.width: photosDirRow.rowF ? vpx(2) : 1; border.color: photosDirRow.rowF ? theme.accent : settingsRoot.dividerColor
                            Text { anchors { fill: parent; leftMargin: vpx(10); rightMargin: vpx(10); verticalCenter: parent.verticalCenter } verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; text: settings.photosDirectory || "/storage/emulated/0/Pictures"; color: settingsRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.021) }
                            MouseArea { anchors.fill: parent; onClicked: settingsRoot.startInlineEdit("Photos Directory", settings.photosDirectory || "/storage/emulated/0/Pictures") }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Browser Homepage URL (off = 3)
                    Rectangle {
                        id: browserUrlRow
                        property bool rowF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 4 && settingsRoot.contentRowIdx === (4 + tab4Col.savedUserCount)
                        width: parent.width; height: vpx(58); radius: vpx(8)
                        color: rowF ? settingsRoot.cardBg : "transparent"; border.width: rowF ? vpx(3) : 0; border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter } text: tr("Browser Default URL"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                        Rectangle {
                            anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                            width: vpx(260); height: vpx(38); radius: vpx(8); color: settingsRoot.sidebarBg; border.width: browserUrlRow.rowF ? vpx(2) : 1; border.color: browserUrlRow.rowF ? theme.accent : settingsRoot.dividerColor
                            Text { anchors { fill: parent; leftMargin: vpx(10); rightMargin: vpx(10); verticalCenter: parent.verticalCenter } verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; text: settings.browserLink; color: settingsRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.021) }
                            MouseArea { anchors.fill: parent; onClicked: settingsRoot.startInlineEdit("Browser default link", settings.browserLink) }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Clock Format (off = 4)
                    Rectangle {
                        id: clockRow
                        property bool rowF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 4 && settingsRoot.contentRowIdx === (5 + tab4Col.savedUserCount)
                        width: parent.width; height: vpx(58); radius: vpx(8)
                        color: rowF ? settingsRoot.cardBg : "transparent"; border.width: rowF ? vpx(3) : 0; border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter } text: tr("Clock Format"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                        Rectangle {
                            anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                            width: vpx(114); height: vpx(38); radius: vpx(8); color: settingsRoot.sidebarBg; border.width: clockRow.rowF ? vpx(2) : 1; border.color: clockRow.rowF ? theme.accent : settingsRoot.dividerColor
                            Text { anchors.centerIn: parent; text: settings.timeFormat.toUpperCase(); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: settingsRoot.setMem("Time Format", settings.timeFormat === "12hr" ? "24hr" : "12hr") }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Battery Percentage (off = 5)
                    Rectangle {
                        id: battRow
                        property bool rowF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 4 && settingsRoot.contentRowIdx === (6 + tab4Col.savedUserCount)
                        width: parent.width; height: vpx(58); radius: vpx(8)
                        color: rowF ? settingsRoot.cardBg : "transparent"; border.width: rowF ? vpx(3) : 0; border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter } text: tr("Battery Percentage"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                        Rectangle {
                            anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                            width: vpx(114); height: vpx(38); radius: vpx(8); color: settingsRoot.sidebarBg; border.width: battRow.rowF ? vpx(2) : 1; border.color: battRow.rowF ? theme.accent : settingsRoot.dividerColor
                            Text { anchors.centerIn: parent; text: settings.batteryPercentSetting === "Yes" ? "Shown" : "Hidden"; color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: settingsRoot.setMem("Display Battery Percentage", settings.batteryPercentSetting === "Yes" ? "No" : "Yes") }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Display Wi-Fi Icon (off = 6)
                    Rectangle {
                        id: wifiRow
                        property bool rowF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 4 && settingsRoot.contentRowIdx === (7 + tab4Col.savedUserCount)
                        width: parent.width; height: vpx(58); radius: vpx(8)
                        color: rowF ? settingsRoot.cardBg : "transparent"; border.width: rowF ? vpx(3) : 0; border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter } text: tr("Display Wi-Fi Icon"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                        Rectangle {
                            anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                            width: vpx(114); height: vpx(38); radius: vpx(8); color: settingsRoot.sidebarBg; border.width: wifiRow.rowF ? vpx(2) : 1; border.color: wifiRow.rowF ? theme.accent : settingsRoot.dividerColor
                            Text { anchors.centerIn: parent; text: settings.showWifi === "Yes" ? "Shown" : "Hidden"; color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: settingsRoot.setMem("Display Wifi Icon", settings.showWifi === "Yes" ? "No" : "Yes") }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    // Memory Viewer & Reset (off = 7)
                    Rectangle {
                        id: memResetRow
                        property bool rowF: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 4 && settingsRoot.contentRowIdx === (8 + tab4Col.savedUserCount)
                        width: parent.width; height: vpx(60); radius: vpx(8)
                        color: rowF ? settingsRoot.cardBg : "transparent"; border.width: rowF ? vpx(3) : 0; border.color: theme.accent
                        Text { anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter } text: tr("Pegasus Memory & Defaults"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                        Row {
                            anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                            spacing: vpx(10)
                            Rectangle {
                                property bool subF: memResetRow.rowF && settingsRoot.contentSubCol === 0
                                width: vpx(164); height: vpx(38); radius: vpx(8); color: settingsRoot.sidebarBg; border.width: subF ? vpx(2.5) : 1; border.color: subF ? theme.accent : settingsRoot.dividerColor
                                Text { anchors.centerIn: parent; text: tr("Memory Viewer"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.021); font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: { settingsRoot.showMemoryViewer = true; memoryViewerModal.open(); } }
                            }
                            Rectangle {
                                property bool subF: memResetRow.rowF && settingsRoot.contentSubCol === 1
                                width: vpx(136); height: vpx(38); radius: vpx(8); color: "#DC2626"; border.width: subF ? vpx(2.5) : 0; border.color: "#FFFFFF"
                                Text { anchors.centerIn: parent; text: tr("Reset All"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.021); font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: settingsRoot.restoreAllSettings() }
                            }
                        }
                    }
                }

                // TAB 5: ABOUT (Unbranded)
                Column {
                    visible: settingsRoot.currentTab === 5
                    width: parent.width; spacing: vpx(14)

                    Row {
                        spacing: vpx(8)
                        Rectangle { width: vpx(4); height: vpx(18); color: theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: tr("About SkyLine 3"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.031); font.bold: true }
                    }
                    Rectangle { width: parent.width; height: 1; color: settingsRoot.dividerColor }

                    Rectangle {
                        property bool aboutFocused: settingsRoot.focusZone === "content" && settingsRoot.currentTab === 5 && settingsRoot.contentRowIdx === 0
                        width: parent.width
                        height: aboutCol.implicitHeight + vpx(24)
                        radius: vpx(10)
                        color: aboutFocused ? settingsRoot.cardBg : "transparent"
                        border.width: aboutFocused ? vpx(3) : 1
                        border.color: aboutFocused ? theme.accent : settingsRoot.dividerColor

                        Column {
                            id: aboutCol
                            anchors { fill: parent; margins: vpx(12) }
                            spacing: vpx(10)
                            Text { text: "Designed by Chen.Paradise"; color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027) }
                            Text {
                                text: "Forked from https://github.com/RBertoCases/skylineOS"
                                color: theme.accent; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale)
                                MouseArea { anchors.fill: parent; onClicked: openInThemeBrowser("https://github.com/RBertoCases/skylineOS") }
                            }
                            Text { text: "SkyLine 3 — Our new perfected version (2026)."; color: settingsRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale) }
                            Text { text: "Hecho con \u2764 en Santurce, PR"; color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027) }
                        }
                    }
                }
            }
        }
    }

    // Embedded Memory Viewer
    MemoryViewer {
        id: memoryViewerModal
        models: [legacyCompatModel]
        visible: settingsRoot.showMemoryViewer
        onClosed: {
            settingsRoot.showMemoryViewer = false;
            settingsRoot.forceActiveFocus();
        }
    }

    // Bottom Sticky Switch 2 Footer Bar
    Item {
        id: settingsFooter
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.088)
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: settingsRoot.dividerColor }

        Image {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: vpx(36); height: vpx(26)
            source: "../assets/images/navigation/ns2_controller_glyph.svg"
            fillMode: Image.PreserveAspectFit; smooth: true
            layer.enabled: true; layer.effect: ColorOverlay { color: settingsRoot.textMain; antialiasing: true; cached: true }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(24)

            Row {
                spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: settingsRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "B"; color: settingsRoot.pageBg; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027); font.bold: true }
                }
                Text { text: tr("Back"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale); anchors.verticalCenter: parent.verticalCenter }
                MouseArea { anchors.fill: parent; onClicked: { backSfx.play(); showHomeScreen(); } }
            }

            Row {
                spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: settingsRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "A"; color: settingsRoot.pageBg; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027); font.bold: true }
                }
                Text { text: tr("OK"); color: settingsRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027 * fontScale); anchors.verticalCenter: parent.verticalCenter }
                MouseArea { anchors.fill: parent; onClicked: { navSound.play(); settingsRoot.currentTab = (settingsRoot.currentTab === 0) ? 2 : 0; } }
            }
        }
    }
}
