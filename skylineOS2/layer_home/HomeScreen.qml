import QtQuick 2.12
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.3
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

FocusScope {
    id: root
    property int lastHomeSwitcherIndex: 0
    property var lastDockButton: null
    property bool dockWasFocused: false
    property bool raProfileVisible: false
    property var hiddenApps: []
    property bool expandedPanelOpen: homeSwitcher.anyExpanded

    property string hiddenSnapshot: ""

    function rebuildGamesList() {
        var keep = homeSwitcher.currentIndex;
        gamesListModel.clear();
        gamesListModel.buildList();
        if (keep >= 0)
            homeSwitcher.currentIndex = Math.min(keep, gamesListModel.count - 1);
    }

    property int focusedSatIndex: -1
    property bool profileRowActive: profileButton.focus

    onProfileRowActiveChanged: {
        if (profileRowActive)
            refreshSatellites();
    }

    ListModel {
        id: satellitesModel
    }

    function refreshSatellites() {
        var items = [];
        var n = 1;
        while (api.memory.has("profile_" + n)) {
            items.push({
                profileName: String(api.memory.get("profile_" + n)),
                profileImg: api.memory.has("profile_" + n + "_img") ? String(api.memory.get("profile_" + n + "_img")) : ""
            });
            n++;
        }
        if (items.length !== satellitesModel.count) {
            focusedSatIndex = -1;
            satellitesModel.clear();
            for (var i = 0; i < items.length; i++)
                satellitesModel.append(items[i]);
        } else {
            for (var j = 0; j < items.length; j++) {
                var cur = satellitesModel.get(j);
                if (cur.profileName !== items[j].profileName || cur.profileImg !== items[j].profileImg)
                    satellitesModel.set(j, items[j]);
            }
        }
    }

    function updateSatellite(i, name, img) {
        if (i >= 0 && i < satellitesModel.count)
            satellitesModel.set(i, {
                profileName: name,
                profileImg: img
            });
    }

    function focusProfileSlot(slot) {
        profileButton.focus = true;
    }

    property bool minusHeld: false
    property bool plusHeld: false

    function markDockFocused(btn) {
        if (btn) lastDockButton = btn;
        dockWasFocused = true;
    }

    function restoreLastFocus() {
        if (dockWasFocused && lastDockButton && lastDockButton.visible) {
            profileButton.focus = false;
            homeScreen.focus = true;
            homeSwitcher.currentIndex = -1;
            lastDockButton.forceActiveFocus();
            return;
        }
        focusCarousel();
    }

    function focusCarousel() {
        dockWasFocused = false;
        profileButton.focus = false;
        homeScreen.focus = true;
        homeSwitcher.focus = true;
        if (homeSwitcher.count > 0 && homeSwitcher.currentIndex < 0)
            homeSwitcher.currentIndex = (lastHomeSwitcherIndex >= 0 && lastHomeSwitcherIndex < homeSwitcher.count) ? lastHomeSwitcherIndex : 0;
        homeSwitcher.forceActiveFocus();
        if (homeSwitcher.currentItem && homeSwitcher.currentItem.isGame && homeSwitcher.currentItem.gameData)
            currentGame = homeSwitcher.currentItem.gameData;
    }

    function checkSleepCombo(key, pressed, isRepeat) {
        if (typeof handleGlobalSleepCombo === "function")
            return handleGlobalSleepCombo(key, pressed, !!isRepeat);
        if (key === Qt.Key_Minus || key === Qt.Key_Select) minusHeld = pressed;
        if (key === Qt.Key_Plus || key === Qt.Key_Equal || key === Qt.Key_Menu || key === Qt.Key_Start) plusHeld = pressed;
        if (pressed && minusHeld && plusHeld) {
            minusHeld = false;
            plusHeld = false;
            showButtonScreen("suspend");
            return true;
        }
        return false;
    }

    Keys.onPressed: {
        if (checkSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
    }
    Keys.onReleased: {
        checkSleepCombo(event.key, false, event.isAutoRepeat);
    }

    Component.onCompleted: { refreshSatellites(); Qt.callLater(function() { focusCarousel(); }); }

    property string scrapedBackground: ""
    property bool usingScraped: !!(scrapedBackground !== "" && currentGame && currentGame.assets && !(currentGame.assets.background || currentGame.assets.screenshots[0]))
    property var watchedGame: currentGame

    property real bgOverlayOpacity: {
        var v = parseFloat(settings.bgTransparency);
        if (isNaN(v))
            v = 70;
        return 1 - Math.max(0, Math.min(100, v)) / 100;
    }

    property color adaptiveHudTextColor: theme.text
    property color adaptiveHudIconColor: theme.text
    property var _hudColorCache: ({})

    function requestHudSample() {
        var bgEnabled = (settings.gameBackground !== "No" && settings.gameBackground !== "None");
        var src = globalBackground.source ? globalBackground.source.toString() : "";
        if (!bgEnabled || src === "" || globalBackground.status !== Image.Ready) {
            adaptiveHudTextColor = theme.text;
            adaptiveHudIconColor = theme.text;
            return;
        }
        var isDark = (String(theme.main).toLowerCase() === "#22242a") || (settings.darkMode === "Yes" && settings.appearanceMode !== "Light") || (settings.appearanceMode === "Dark");
        var cacheKey = src + "|" + bgOverlayOpacity.toFixed(2) + "|" + (isDark ? "D" : "L");
        if (_hudColorCache[cacheKey]) {
            adaptiveHudTextColor = _hudColorCache[cacheKey].text;
            adaptiveHudIconColor = _hudColorCache[cacheKey].icon;
            return;
        }
        hudColorSampler.requestPaint();
    }

    onBgOverlayOpacityChanged: requestHudSample()

    onWatchedGameChanged: {
        scrapedBackground = "";
        scrapeTimer.restart();
    }

    onVisibleChanged: {
        if (visible) {
            scrapeTimer.restart();
            Qt.callLater(function() { restoreLastFocus(); });
        }
    }

    Timer {
        id: scrapeTimer
        interval: 400
        repeat: false
        onTriggered: root.scrapeBackground()
    }

    function scrapeBackground() {
        var game = currentGame;
        if (settings.gameBackground === "No" || settings.gameBackground === "None" || !game || !game.assets)
            return;
        if (game.assets.background || game.assets.screenshots[0])
            return;

        var title = game.title;
        var manualKey = "SGDB_ID::" + title;
        var manualId = api.memory.has(manualKey) ? api.memory.get(manualKey) : "";
        var apply = function (url) {
            if (currentGame && currentGame.title === title)
                scrapedBackground = url || "";
        };

        if (manualId)
            Utils.sgdbGetHero(manualId, apply);
        else
            Utils.fetchScrapedBackground(title, apply);
    }

    property var menuButtonOrder: [nsoButton, chatButton, infoButton, storeButton, galleryButton, gameshareButton, browserButton, softwareDockButton, settingsButton, suspendButton]

    function firstVisibleMenuButton() {
        for (var i = 0; i < menuButtonOrder.length; i++) {
            if (menuButtonOrder[i].visible)
                return menuButtonOrder[i];
        }
        return null;
    }

    function visibleMenuButtonNeighbor(fromButton, direction) {
        var idx = menuButtonOrder.indexOf(fromButton);
        if (idx < 0)
            return fromButton;
        var n = menuButtonOrder.length;
        for (var step = 1; step <= n; step++) {
            var candidate = menuButtonOrder[(idx + direction * step + n * n) % n];
            if (candidate.visible)
                return candidate;
        }
        return fromButton; // tutti nascosti tranne se stesso, resta fermo
    }

    // Build the games list but with extra menu options at the start and end
    ListModel {
        id: gamesListModel

        property var activeCollection: listRecent.games

        Component.onCompleted: {
            clear();
            buildList();
        }

        onActiveCollectionChanged: root.rebuildGamesList()

        function buildList() {
            var showHidden = api.memory.get("Show Hidden Apps") === "Yes";
            var maxRecent = Math.min(activeCollection.count, 10);
            for (var i = 0; i < maxRecent; i++) {
                var title = listRecent.games.get(i).title;
                if (showHidden || !isAppHidden(title))
                    append(createListElement(i));
            }
            append({
                "name": "All Software",
                "idx": -3,
                "icon": "../assets/images/allsoft_icon.svg",
                "background": ""
            });
        }

        function createListElement(i) {
            return {
                name: listRecent.games.get(i).title,
                idx: i,
                icon: listRecent.games.get(i).assets.logo,
                background: listRecent.games.get(i).assets.screenshots[0] || ""
            };
        }
    }

    onHiddenAppsChanged: {
        var snap = JSON.stringify(hiddenApps);
        if (snap === hiddenSnapshot)
            return;
        hiddenSnapshot = snap;
        rebuildGamesList();
    }

    function openRAPanel() {
        userSfx.play();
        raProfileVisible = true;
        raPanel.open();
        raPanel.forceActiveFocus();
    }

    Item {
        id: homeScreenContainer
        width: parent.width
        height: parent.height

        property var batteryStatus: isNaN(api.device.batteryPercent) ? "" : parseInt(api.device.batteryPercent * 100)

        Item {
            id: globalBgWrapper
            anchors.fill: parent
            visible: (settings.gameBackground !== "No" && settings.gameBackground !== "None") && (globalBackground.status === Image.Ready)

            Image {
                id: globalBackground
                anchors.fill: parent
                cache: !root.usingScraped
                source: (root && currentGame && gameOverrideVersion >= 0) ? (getGameBg(currentGame) || scrapedBackground || "") : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                layer.enabled: (settings.bgBlur !== undefined ? settings.bgBlur : 55) > 0
                layer.effect: FastBlur {
                    radius: Math.max(0, Math.min(64, Math.round(((settings.bgBlur !== undefined ? settings.bgBlur : 55) / 100.0) * 64)))
                }

                onStatusChanged: root.requestHudSample()
                onSourceChanged: root.requestHudSample()

                Behavior on source {
                    SequentialAnimation {
                        NumberAnimation {
                            target: globalBackground
                            property: "opacity"
                            to: 0
                            duration: 200
                        }
                        PropertyAction {}
                        NumberAnimation {
                            target: globalBackground
                            property: "opacity"
                            to: 1
                            duration: 200
                        }
                    }
                }
            }

            Canvas {
                id: hudColorSampler
                width: 32
                height: 32
                opacity: 0
                renderStrategy: Canvas.Immediate

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (globalBackground.status !== Image.Ready)
                        return;
                    try {
                        ctx.drawImage(globalBackground, 0, 0, width, height);
                        var imgData = ctx.getImageData(0, 0, width, height);
                        var isDark = (String(theme.main).toLowerCase() === "#22242a") || (settings.darkMode === "Yes" && settings.appearanceMode !== "Light") || (settings.appearanceMode === "Dark");
                        var res = Utils.extractPrimaryHudColors(imgData, root.bgOverlayOpacity, isDark);
                        if (res && res.text) {
                            root.adaptiveHudTextColor = res.text;
                            root.adaptiveHudIconColor = res.icon || res.text;
                            var src = globalBackground.source ? globalBackground.source.toString() : "";
                            if (src !== "") {
                                root._hudColorCache[src + "|" + root.bgOverlayOpacity.toFixed(2) + "|" + (isDark ? "D" : "L")] = res;
                            }
                        }
                    } catch (e) {
                        root.adaptiveHudTextColor = theme.text;
                        root.adaptiveHudIconColor = theme.text;
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: theme.main
                opacity: root.bgOverlayOpacity
            }
        }

        Item {
            id: topbar

            height: Math.round(screenheight * 0.2569)
            anchors {
                left: parent.left
                leftMargin: vpx(60)
                right: parent.right
                rightMargin: vpx(60)
                top: parent.top
                topMargin: Math.round(screenheight * 0.0472)
            }

            Row {
                spacing: vpx(10)
                anchors {
                    top: parent.top
                    left: parent.left
                }

                Item {
                    id: profileButton
                    width: Math.round(screenheight * 0.0833)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter

                    property bool selected: focus

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + vpx(8)
                        height: parent.height + vpx(8)
                        radius: width / 2
                        color: theme.accent
                        z: -1
                        opacity: profileButton.selected ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    Item {
                        id: profileImageClip
                        anchors.fill: parent

                        Image {
                            id: profileIcon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            source: api.memory.get("RA_LoggedIn") === "Yes"
                                ? "https://media.retroachievements.org/UserPic/" + api.memory.get("RA_Username") + ".png"
                                : "../assets/images/avatars/" + (settings.activeCharacter || "mario") + ".png"
                        }

                        Rectangle {
                            id: maskRect
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: profileIcon
                            maskSource: maskRect
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            profileButton.focus = true;
                            homeSwitcher.currentIndex = -1;
                            navSound.play();
                            openUserSelect("¿Quién está jugando?", null);
                        }
                    }

                    Keys.onBackPressed: {
                        event.accepted = true;
                        backSfx.play();
                        root.focusCarousel();
                    }

                    Keys.onPressed: {
                        if (root.checkSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            openUserSelect("¿Quién está jugando?", null);
                        } else if ((api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace || event.key === Qt.Key_Escape) && !event.isAutoRepeat) {
                            event.accepted = true;
                            backSfx.play();
                            root.focusCarousel();
                        }
                    }

                    Keys.onReleased: {
                        root.checkSleepCombo(event.key, false, event.isAutoRepeat);
                    }

                    Keys.onDownPressed: {
                        navSound.play();
                        root.focusCarousel();
                    }
                }

                Text {
                    id: usernameText
                    text: {
                        if (api.memory.get("RA_LoggedIn") === "Yes")
                            return api.memory.get("RA_Username") || "";
                        if (api.memory.has("Username") && api.memory.get("Username") !== "")
                            return api.memory.get("Username");
                        return "";
                    }
                    color: profileButton.selected ? theme.accent : root.adaptiveHudTextColor
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.036 * fontScale)
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
            }

            Text {
                id: collectionHomeTitle
                text: currentCollection == -1 ? "" : api.collections.get(currentCollection).name
                color: root.adaptiveHudTextColor
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.030 * fontScale)
                font.bold: true
                anchors {
                    verticalCenter: profileButton.verticalCenter
                    left: (usernameText.visible && usernameText.text !== "") ? usernameText.right : profileButton.right
                    leftMargin: vpx(14)
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            Item {
                id: statusArea
                width: statusPill.width
                height: Math.round(screenheight * 0.0833)
                anchors {
                    top: parent.top
                    right: parent.right
                    rightMargin: vpx(15)
                }

                Item {
                    id: statusPill
                    height: Math.round(screenheight * 0.0611)
                    width: statusRow.width + vpx(12)
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: vpx(11)

                        Text {
                            id: sysTime
                            property var timeSetting: (settings.timeFormat === "12hr") ? "h:mm AP" : "hh:mm"
                            function set() {
                                sysTime.text = Qt.formatTime(new Date(), timeSetting);
                            }
                            Timer {
                                interval: 60000
                                repeat: true
                                running: true
                                triggeredOnStart: true
                                onTriggered: sysTime.set()
                            }
                            onTimeSettingChanged: sysTime.set()
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.adaptiveHudTextColor
                            font.family: titleFont.name
                            font.weight: Font.Normal
                            font.pixelSize: Math.round(screenheight * 0.036 * fontScale)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            id: batteryPercentage
                            text: homeScreenContainer.batteryStatus + "%"
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.adaptiveHudTextColor
                            font.family: titleFont.name
                            font.weight: Font.Normal
                            font.pixelSize: Math.round(screenheight * 0.036 * fontScale)
                            visible: isNaN(api.device.batteryPercent) ? false : showPercent
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        BatteryIcon {
                            id: batteryIcon
                            width: Math.round(screenheight * 0.0433)
                            height: width / 1.5
                            anchors.verticalCenter: parent.verticalCenter
                            level: homeScreenContainer.batteryStatus
                            visible: !isNaN(api.device.batteryPercent)
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: (batteryIcon.level <= 20 && !api.device.batteryCharging) ? "#EF4444" : root.adaptiveHudIconColor
                                antialiasing: true
                                cached: true
                            }
                        }

                        Image {
                            id: chargingIcon
                            height: Math.round(screenheight * 0.034)
                            width: height * 0.7
                            anchors.verticalCenter: parent.verticalCenter
                            fillMode: Image.PreserveAspectFit
                            source: "../assets/images/charging.svg"
                            sourceSize.width: 64
                            sourceSize.height: 64
                            smooth: true
                            visible: api.device.batteryCharging && batteryIcon.level < 99
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: root.adaptiveHudIconColor
                                antialiasing: true
                                cached: true
                            }
                        }

                        Image {
                            id: wifiIcon
                            width: Math.round(screenheight * 0.038)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            fillMode: Image.PreserveAspectFit
                            source: "../assets/images/navigation/wifi.svg"
                            sourceSize.width: 64
                            sourceSize.height: 64
                            visible: (settings.showWifi === "Yes")
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: root.adaptiveHudIconColor
                                antialiasing: true
                                cached: true
                            }
                        }
                    }

                    MouseArea {
                        id: statusPillMouse
                        anchors.fill: parent
                        onClicked: {
                            navSound.play();
                            showSettingsScreen(2);
                        }
                    }
                }
            }
        }

        // Home menu
        HomeBar {
            id: homeSwitcher
            anchors {
                left: parent.left
                leftMargin: vpx(98)
                right: parent.right
                top: topbar.bottom
            }
            height: Math.round(screenheight * (parseFloat(settings.homeCardSize) / 100))
            focus: true
            onUserInteracted: sysTime.set()
            onDownPressed: {
                var target = root.firstVisibleMenuButton();
                if (target) {
                    target.focus = true;
                    homeSwitcher.currentIndex = -1;
                }
            }
        }

        // Button menu (Exact 11 Switch 2 Dock Buttons)
        Item {
            id: buttonMenuContainer
            property int dockButtonSize: Math.max(vpx(54), Math.round(buttonBar.height * 0.72))
            anchors {
                top: homeSwitcher.bottom
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: helpbarheight
            }
            width: buttonMenu.width + vpx(64)

            Item {
                id: buttonBar
                anchors.centerIn: parent
                width: buttonMenu.width + vpx(64)
                height: Math.round(screenheight * ((settings.dockHeightPct || 13.3) / 100.0))

                Rectangle {
                    id: buttonBarSolid
                    anchors.fill: parent
                    radius: height / 2
                    color: theme.button
                    border.width: 0

                    layer.enabled: enableDropShadows
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: vpx(4)
                        radius: 12
                        samples: 24
                        color: "#30000000"
                    }
                }
            }

            Keys.onBackPressed: {
                event.accepted = true;
                backSfx.play();
                root.focusCarousel();
            }
            Keys.onPressed: {
                if (root.checkSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
                if ((api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace || event.key === Qt.Key_Escape) && !event.isAutoRepeat) {
                    event.accepted = true;
                    backSfx.play();
                    root.focusCarousel();
                }
            }
            Keys.onReleased: {
                root.checkSleepCombo(event.key, false, event.isAutoRepeat);
            }

            RowLayout {
                id: buttonMenu
                spacing: vpx(16)
                anchors.centerIn: parent

                // 1. Online (Switch 2 Online / NSO)
                MenuButton {
                    id: nsoButton
                    width: buttonMenuContainer.dockButtonSize
                    height: buttonMenuContainer.dockButtonSize
                    Layout.preferredWidth: buttonMenuContainer.dockButtonSize
                    Layout.preferredHeight: buttonMenuContainer.dockButtonSize
                    label: tr("Nintendo Online")
                    clickAnim: "pop"
                    autoColor: false
                    isOnlinePill: true
                    icon: "../assets/images/navigation/ns2_online_idle.svg"
                    selectedIcon: "../assets/images/navigation/ns2_online.svg"
                    onFocusChanged: if (focus) { root.markDockFocused(nsoButton); if (homeSwitcher.currentIndex >= 0) root.lastHomeSwitcherIndex = homeSwitcher.currentIndex; }
                    Keys.onUpPressed: { navSound.play(); root.dockWasFocused = false; homeSwitcher.focus = true; homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0; }
                    Keys.onLeftPressed: { navSound.play(); root.visibleMenuButtonNeighbor(nsoButton, -1).focus = true; }
                    Keys.onRightPressed: { navSound.play(); root.visibleMenuButtonNeighbor(nsoButton, 1).focus = true; }
                    Keys.onPressed: { if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; root.markDockFocused(nsoButton); nsoButton.animate(); showButtonScreen("nso"); } }
                    onClicked: { nsoButton.focus = true; root.markDockFocused(nsoButton); homeSwitcher.currentIndex = -1; nsoButton.animate(); showButtonScreen("nso"); }
                }

                // 2. GameChat
                MenuButton {
                    id: chatButton
                    width: buttonMenuContainer.dockButtonSize
                    height: buttonMenuContainer.dockButtonSize
                    Layout.preferredWidth: buttonMenuContainer.dockButtonSize
                    Layout.preferredHeight: buttonMenuContainer.dockButtonSize
                    label: tr("GameChat")
                    clickAnim: "pop"
                    autoColor: false
                    icon: "../assets/images/navigation/ns2_gamechat.svg"
                    onFocusChanged: if (focus) { root.markDockFocused(chatButton); if (homeSwitcher.currentIndex >= 0) root.lastHomeSwitcherIndex = homeSwitcher.currentIndex; }
                    Keys.onUpPressed: { navSound.play(); root.dockWasFocused = false; homeSwitcher.focus = true; homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0; }
                    Keys.onLeftPressed: { navSound.play(); root.visibleMenuButtonNeighbor(chatButton, -1).focus = true; }
                    Keys.onRightPressed: { navSound.play(); root.visibleMenuButtonNeighbor(chatButton, 1).focus = true; }
                    Keys.onPressed: { if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; root.markDockFocused(chatButton); chatButton.animate(); showButtonScreen("chat"); } }
                    onClicked: { chatButton.focus = true; root.markDockFocused(chatButton); homeSwitcher.currentIndex = -1; chatButton.animate(); showButtonScreen("chat"); }
                }

                // 3. News
                MenuButton {
                    id: infoButton
                    width: buttonMenuContainer.dockButtonSize
                    height: buttonMenuContainer.dockButtonSize
                    Layout.preferredWidth: buttonMenuContainer.dockButtonSize
                    Layout.preferredHeight: buttonMenuContainer.dockButtonSize
                    label: tr("News")
                    clickAnim: "wiggle"
                    autoColor: false
                    visible: api.memory.has("Feed Button Show") ? (api.memory.get("Feed Button Show") === "Yes") : true
                    icon: "../assets/images/navigation/ns2_news.svg"
                    onFocusChanged: if (focus) { root.markDockFocused(infoButton); if (homeSwitcher.currentIndex >= 0) root.lastHomeSwitcherIndex = homeSwitcher.currentIndex; }
                    Keys.onUpPressed: { navSound.play(); root.dockWasFocused = false; homeSwitcher.focus = true; homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0; }
                    Keys.onLeftPressed: { navSound.play(); root.visibleMenuButtonNeighbor(infoButton, -1).focus = true; }
                    Keys.onRightPressed: { navSound.play(); root.visibleMenuButtonNeighbor(infoButton, 1).focus = true; }
                    Keys.onPressed: { if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; root.markDockFocused(infoButton); infoButton.animate(); showButtonScreen("info"); } }
                    onClicked: { infoButton.focus = true; root.markDockFocused(infoButton); homeSwitcher.currentIndex = -1; infoButton.animate(); showButtonScreen("info"); }
                }

                // 4. eShop
                MenuButton {
                    id: storeButton
                    width: buttonMenuContainer.dockButtonSize
                    height: buttonMenuContainer.dockButtonSize
                    Layout.preferredWidth: buttonMenuContainer.dockButtonSize
                    Layout.preferredHeight: buttonMenuContainer.dockButtonSize
                    label: tr("Nintendo eShop")
                    clickAnim: "bounce"
                    autoColor: false
                    icon: "../assets/images/navigation/ns2_eshop.svg"
                    visible: api.memory.has("Store Button Show") ? (api.memory.get("Store Button Show") === "Yes") : true
                    onFocusChanged: if (focus) { root.markDockFocused(storeButton); if (homeSwitcher.currentIndex >= 0) root.lastHomeSwitcherIndex = homeSwitcher.currentIndex; }
                    Keys.onUpPressed: { navSound.play(); root.dockWasFocused = false; homeSwitcher.focus = true; homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0; }
                    Keys.onLeftPressed: { navSound.play(); root.visibleMenuButtonNeighbor(storeButton, -1).focus = true; }
                    Keys.onRightPressed: { navSound.play(); root.visibleMenuButtonNeighbor(storeButton, 1).focus = true; }
                    Keys.onPressed: { if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; root.markDockFocused(storeButton); storeButton.animate(); showButtonScreen("store"); } }
                    onClicked: { storeButton.focus = true; root.markDockFocused(storeButton); homeSwitcher.currentIndex = -1; storeButton.animate(); showButtonScreen("store"); }
                }

                // 5. Album
                MenuButton {
                    id: galleryButton
                    width: buttonMenuContainer.dockButtonSize
                    height: buttonMenuContainer.dockButtonSize
                    Layout.preferredWidth: buttonMenuContainer.dockButtonSize
                    Layout.preferredHeight: buttonMenuContainer.dockButtonSize
                    label: tr("Album")
                    clickAnim: "pop"
                    autoColor: false
                    icon: "../assets/images/navigation/ns2_album.svg"
                    visible: api.memory.has("Gallery Button Show") ? (api.memory.get("Gallery Button Show") === "Yes") : true
                    onFocusChanged: if (focus) { root.markDockFocused(galleryButton); if (homeSwitcher.currentIndex >= 0) root.lastHomeSwitcherIndex = homeSwitcher.currentIndex; }
                    Keys.onUpPressed: { navSound.play(); root.dockWasFocused = false; homeSwitcher.focus = true; homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0; }
                    Keys.onLeftPressed: { navSound.play(); root.visibleMenuButtonNeighbor(galleryButton, -1).focus = true; }
                    Keys.onRightPressed: { navSound.play(); root.visibleMenuButtonNeighbor(galleryButton, 1).focus = true; }
                    Keys.onPressed: { if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; root.markDockFocused(galleryButton); galleryButton.animate(); showButtonScreen("album"); } }
                    onClicked: { galleryButton.focus = true; root.markDockFocused(galleryButton); homeSwitcher.currentIndex = -1; galleryButton.animate(); showButtonScreen("album"); }
                }

                // 6. GameShare
                MenuButton {
                    id: gameshareButton
                    width: buttonMenuContainer.dockButtonSize
                    height: buttonMenuContainer.dockButtonSize
                    Layout.preferredWidth: buttonMenuContainer.dockButtonSize
                    Layout.preferredHeight: buttonMenuContainer.dockButtonSize
                    label: tr("GameShare")
                    clickAnim: "pop"
                    autoColor: false
                    icon: "../assets/images/navigation/ns2_gameshare.svg"
                    onFocusChanged: if (focus) { root.markDockFocused(gameshareButton); if (homeSwitcher.currentIndex >= 0) root.lastHomeSwitcherIndex = homeSwitcher.currentIndex; }
                    Keys.onUpPressed: { navSound.play(); root.dockWasFocused = false; homeSwitcher.focus = true; homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0; }
                    Keys.onLeftPressed: { navSound.play(); root.visibleMenuButtonNeighbor(gameshareButton, -1).focus = true; }
                    Keys.onRightPressed: { navSound.play(); root.visibleMenuButtonNeighbor(gameshareButton, 1).focus = true; }
                    Keys.onPressed: { if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; root.markDockFocused(gameshareButton); gameshareButton.animate(); showButtonScreen("gameshare"); } }
                    onClicked: { gameshareButton.focus = true; root.markDockFocused(gameshareButton); homeSwitcher.currentIndex = -1; gameshareButton.animate(); showButtonScreen("gameshare"); }
                }

                // 7. Internet Browser / Netflix
                MenuButton {
                    id: browserButton
                    width: buttonMenuContainer.dockButtonSize
                    height: buttonMenuContainer.dockButtonSize
                    Layout.preferredWidth: buttonMenuContainer.dockButtonSize
                    Layout.preferredHeight: buttonMenuContainer.dockButtonSize
                    label: tr("Netflix")
                    clickAnim: "pop"
                    autoColor: false
                    visible: api.memory.has("Browser Button Show") ? (api.memory.get("Browser Button Show") === "Yes") : true
                    icon: "../assets/images/navigation/ns2_browser.svg"
                    onFocusChanged: if (focus) { root.markDockFocused(browserButton); if (homeSwitcher.currentIndex >= 0) root.lastHomeSwitcherIndex = homeSwitcher.currentIndex; }
                    Keys.onUpPressed: { navSound.play(); root.dockWasFocused = false; homeSwitcher.focus = true; homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0; }
                    Keys.onLeftPressed: { navSound.play(); root.visibleMenuButtonNeighbor(browserButton, -1).focus = true; }
                    Keys.onRightPressed: { navSound.play(); root.visibleMenuButtonNeighbor(browserButton, 1).focus = true; }
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            root.markDockFocused(browserButton);
                            browserButton.animate();
                            showButtonScreen("browser");
                        }
                    }
                    onClicked: {
                        browserButton.focus = true; root.markDockFocused(browserButton); homeSwitcher.currentIndex = -1; browserButton.animate();
                        showButtonScreen("browser");
                    }
                }

                // 9. All Software
                MenuButton {
                    id: softwareDockButton
                    width: buttonMenuContainer.dockButtonSize
                    height: buttonMenuContainer.dockButtonSize
                    Layout.preferredWidth: buttonMenuContainer.dockButtonSize
                    Layout.preferredHeight: buttonMenuContainer.dockButtonSize
                    label: tr("All Software")
                    clickAnim: "pop"
                    autoColor: true
                    icon: "../assets/images/navigation/ns2_cards.svg"
                    onFocusChanged: if (focus) { root.markDockFocused(softwareDockButton); if (homeSwitcher.currentIndex >= 0) root.lastHomeSwitcherIndex = homeSwitcher.currentIndex; }
                    Keys.onUpPressed: { navSound.play(); root.dockWasFocused = false; homeSwitcher.focus = true; homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0; }
                    Keys.onLeftPressed: { navSound.play(); root.visibleMenuButtonNeighbor(softwareDockButton, -1).focus = true; }
                    Keys.onRightPressed: { navSound.play(); root.visibleMenuButtonNeighbor(softwareDockButton, 1).focus = true; }
                    Keys.onPressed: { if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; root.markDockFocused(softwareDockButton); softwareDockButton.animate(); showSoftwareScreen(); } }
                    onClicked: { softwareDockButton.focus = true; root.markDockFocused(softwareDockButton); homeSwitcher.currentIndex = -1; softwareDockButton.animate(); showSoftwareScreen(); }
                }

                // 10. System Settings
                MenuButton {
                    id: settingsButton
                    width: buttonMenuContainer.dockButtonSize
                    height: buttonMenuContainer.dockButtonSize
                    Layout.preferredWidth: buttonMenuContainer.dockButtonSize
                    Layout.preferredHeight: buttonMenuContainer.dockButtonSize
                    label: tr("System Settings")
                    clickAnim: "spin"
                    autoColor: true
                    visible: api.memory.has("Settings Button Show") ? (api.memory.get("Settings Button Show") === "Yes") : true
                    icon: "../assets/images/navigation/ns2_settings.svg"
                    onFocusChanged: if (focus) { root.markDockFocused(settingsButton); if (homeSwitcher.currentIndex >= 0) root.lastHomeSwitcherIndex = homeSwitcher.currentIndex; }
                    Keys.onUpPressed: { navSound.play(); root.dockWasFocused = false; homeSwitcher.focus = true; homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0; }
                    Keys.onLeftPressed: { navSound.play(); root.visibleMenuButtonNeighbor(settingsButton, -1).focus = true; }
                    Keys.onRightPressed: { navSound.play(); root.visibleMenuButtonNeighbor(settingsButton, 1).focus = true; }
                    Keys.onPressed: { if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; root.markDockFocused(settingsButton); settingsButton.animate(); showSettingsScreen(); } }
                    onClicked: { settingsButton.focus = true; root.markDockFocused(settingsButton); homeSwitcher.currentIndex = -1; settingsButton.animate(); showSettingsScreen(); }
                }

                // 11. Sleep Mode
                MenuButton {
                    id: suspendButton
                    width: buttonMenuContainer.dockButtonSize
                    height: buttonMenuContainer.dockButtonSize
                    Layout.preferredWidth: buttonMenuContainer.dockButtonSize
                    Layout.preferredHeight: buttonMenuContainer.dockButtonSize
                    label: tr("Sleep Mode")
                    clickAnim: "pulse"
                    autoColor: true
                    visible: api.memory.has("Suspend Button Show") ? (api.memory.get("Suspend Button Show") === "Yes") : true
                    icon: "../assets/images/navigation/ns2_sleep.svg"
                    onFocusChanged: if (focus) { root.markDockFocused(suspendButton); if (homeSwitcher.currentIndex >= 0) root.lastHomeSwitcherIndex = homeSwitcher.currentIndex; }
                    Keys.onUpPressed: { navSound.play(); root.dockWasFocused = false; homeSwitcher.focus = true; homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0; }
                    Keys.onLeftPressed: { navSound.play(); root.visibleMenuButtonNeighbor(suspendButton, -1).focus = true; }
                    Keys.onRightPressed: { navSound.play(); root.visibleMenuButtonNeighbor(suspendButton, 1).focus = true; }
                    Keys.onPressed: { if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; root.markDockFocused(suspendButton); suspendButton.animate(); showButtonScreen("suspend"); } }
                    onClicked: { suspendButton.focus = true; root.markDockFocused(suspendButton); homeSwitcher.currentIndex = -1; suspendButton.animate(); showButtonScreen("suspend"); }
                }
            }
        }

        // Dim overlay RA
        Rectangle {
            id: raDim
            anchors.fill: parent
            color: "black"
            opacity: raProfileVisible ? 0.5 : 0
            visible: opacity > 0
            z: 50
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: raPanel.close()
            }
        }

        // RA Panel
        Rectangle {
            id: raPanel
            width: parent.width
            height: Math.round(screenheight * 0.78)
            x: 0
            y: -parent.height
            z: 51
            radius: vpx(24)
            color: theme.button

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: vpx(-4)
                radius: 20
                samples: 32
                color: "#60000000"
            }

            property bool isOpen: false

            function open() {
                isOpen = true;
                raProfileVisible = true;
                slideIn.start();
                Utils.loadRAData();
                Qt.callLater(function () {
                    raFriendsList.forceActiveFocus();
                });
            }

            function close() {
                isOpen = false;
                raGameDetail.visible = false;
                slideOut.start();
            }

            NumberAnimation {
                id: slideIn
                target: raPanel
                property: "y"
                to: 0
                duration: 300
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: slideOut
                target: raPanel
                property: "y"
                to: -homeScreenContainer.height
                duration: 250
                easing.type: Easing.InCubic
                onStopped: {
                    raProfileVisible = false;
                    profileButton.focus = true;
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: vpx(12)
                width: vpx(40)
                height: vpx(4)
                radius: height / 2
                color: theme.icon
                opacity: 0.4
            }

            Item {
                id: raPanelContent
                anchors {
                    fill: parent
                    margins: vpx(32)
                    topMargin: vpx(28)
                }
                visible: !raGameDetail.visible

                Item {
                    id: raHeader
                    width: parent.width
                    height: vpx(80)

                    Item {
                        id: raAvatarClip
                        width: vpx(72)
                        height: vpx(72)
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: raAvatar
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            source: api.memory.get("RA_LoggedIn") === "Yes" ? "https://media.retroachievements.org/UserPic/" + api.memory.get("RA_Username") + ".png" : ""
                            asynchronous: true
                        }
                        Rectangle {
                            id: raAvatarMask
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                        }
                        OpacityMask {
                            anchors.fill: parent
                            source: raAvatar
                            maskSource: raAvatarMask
                        }
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: vpx(-3)
                            radius: width / 2
                            color: "transparent"
                            border.color: theme.accent
                            border.width: vpx(3)
                        }
                    }

                    Column {
                        anchors {
                            left: raAvatarClip.right
                            leftMargin: vpx(16)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: vpx(4)

                        Text {
                            text: api.memory.get("RA_Username") || ""
                            color: theme.text
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.032)
                            font.bold: true
                        }
                        Row {
                            spacing: vpx(16)
                            Text {
                                id: raPointsText
                                text: tr("— pts")
                                color: theme.accent
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                                font.bold: true
                            }
                            Text {
                                id: raRankText
                                text: tr("Rank —")
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                            }
                            Text {
                                id: raRatioText
                                text: tr("Ratio —")
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                            }
                        }
                        Text {
                            id: raLastGameText
                            text: ""
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.017)
                            opacity: 0.7
                        }
                    }
                }

                Rectangle {
                    id: raSeparator
                    anchors {
                        top: raHeader.bottom
                        topMargin: vpx(16)
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: theme.text
                    opacity: 0.12
                }

                Text {
                    id: raFriendsTitle
                    anchors {
                        top: raSeparator.bottom
                        topMargin: vpx(16)
                        left: parent.left
                    }
                    text: tr("RECENTLY PLAYED")
                    color: theme.icon
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.015)
                    font.bold: true
                    font.letterSpacing: 1.5
                    opacity: 0.6
                }

                ListView {
                    id: raFriendsList
                    anchors {
                        top: raFriendsTitle.bottom
                        topMargin: vpx(12)
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    spacing: vpx(8)
                    clip: true
                    model: raFriendsModel
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationWraps: false

                    delegate: Item {
                        width: raFriendsList.width
                        height: vpx(72)
                        property bool isSelected: ListView.isCurrentItem

                        Rectangle {
                            anchors.fill: parent
                            radius: vpx(12)
                            color: isSelected ? theme.accent : theme.main
                            opacity: isSelected ? 0.85 : 0.6
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        Item {
                            id: gameIconClip
                            width: vpx(52)
                            height: vpx(52)
                            anchors {
                                left: parent.left
                                leftMargin: vpx(8)
                                verticalCenter: parent.verticalCenter
                            }
                            Image {
                                id: gameIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                                source: imageUrl
                                asynchronous: true
                            }
                            Rectangle {
                                id: gameIconMask
                                anchors.fill: parent
                                radius: vpx(8)
                                visible: false
                            }
                            OpacityMask {
                                anchors.fill: parent
                                source: gameIcon
                                maskSource: gameIconMask
                            }
                        }

                        Column {
                            anchors {
                                left: gameIconClip.right
                                leftMargin: vpx(12)
                                right: lastPlayedText.left
                                rightMargin: vpx(8)
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: vpx(4)

                            Text {
                                width: parent.width
                                text: title
                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Item {
                                width: parent.width
                                height: vpx(6)
                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: theme.main
                                    opacity: 0.4
                                }
                                Rectangle {
                                    width: parent.width * (percent / 100)
                                    height: parent.height
                                    radius: height / 2
                                    color: percent >= 100 ? "#F59E0B" : theme.accent
                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 400
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }

                            Text {
                                text: earned + " / " + total + " (" + percent + "%)"
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.015)
                                opacity: 0.7
                            }
                        }

                        Text {
                            id: lastPlayedText
                            anchors {
                                right: parent.right
                                rightMargin: vpx(16)
                                verticalCenter: parent.verticalCenter
                            }
                            text: lastPlayed
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.014)
                            opacity: 0.6
                        }
                    }

                    Keys.onUpPressed: {
                        if (currentIndex > 0) {
                            navSound.play();
                            decrementCurrentIndex();
                        }
                    }
                    Keys.onDownPressed: {
                        if (currentIndex < count - 1) {
                            navSound.play();
                            incrementCurrentIndex();
                        }
                    }
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            var data = raFriendsModel.get(currentIndex);
                            raGameDetail.open(data);
                        }
                        if (api.keys.isCancel(event)) {
                            event.accepted = true;
                            raPanel.close();
                        }
                    }
                }
            }

            // Detail panel
            Rectangle {
                id: raGameDetail
                anchors.fill: parent
                radius: vpx(24)
                color: theme.button
                visible: false
                z: 10

                property var gameData: null

                function open(data) {
                    gameData = data;
                    visible = true;
                    Utils.loadGameAchievements(data.gameId, raAchievementsModel);
                    Qt.callLater(function () {
                        achievementsList.forceActiveFocus();
                    });
                }

                function close() {
                    visible = false;
                    raFriendsList.forceActiveFocus();
                }

                Image {
                    anchors.fill: parent
                    source: raGameDetail.gameData ? raGameDetail.gameData.imageUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.1
                    layer.enabled: true
                    layer.effect: FastBlur {
                        radius: 32
                    }
                }

                Item {
                    anchors {
                        fill: parent
                        margins: vpx(32)
                    }

                    Item {
                        id: detailIconClip
                        width: vpx(80)
                        height: vpx(80)
                        anchors.top: parent.top

                        Image {
                            id: detailIcon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            source: raGameDetail.gameData ? raGameDetail.gameData.imageUrl : ""
                            asynchronous: true
                        }
                        Rectangle {
                            id: detailIconMask
                            anchors.fill: parent
                            radius: vpx(12)
                            visible: false
                        }
                        OpacityMask {
                            anchors.fill: parent
                            source: detailIcon
                            maskSource: detailIconMask
                        }
                    }

                    Column {
                        anchors {
                            left: detailIconClip.right
                            leftMargin: vpx(16)
                            verticalCenter: detailIconClip.verticalCenter
                        }
                        spacing: vpx(4)
                        Text {
                            text: raGameDetail.gameData ? raGameDetail.gameData.title : ""
                            color: theme.text
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.032)
                            font.bold: true
                        }
                        Text {
                            text: raGameDetail.gameData ? raGameDetail.gameData.lastPlayed : ""
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.018)
                            opacity: 0.7
                        }
                    }

                    Rectangle {
                        id: detailDivider
                        anchors {
                            top: detailIconClip.bottom
                            topMargin: vpx(20)
                            left: parent.left
                            right: parent.right
                        }
                        height: 1
                        color: theme.text
                        opacity: 0.12
                    }

                    // Progress bar

                    Column {
                        id: progressSection

                        anchors {
                            top: detailDivider.bottom
                            topMargin: vpx(16)
                            left: parent.left
                            right: parent.right
                        }

                        spacing: vpx(16)

                        RowLayout {
                            width: parent.width

                            Text {
                                text: raGameDetail.gameData ? raGameDetail.gameData.earned + " / " + raGameDetail.gameData.total : ""

                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: raGameDetail.gameData ? raGameDetail.gameData.percent + "%" : ""

                                color: raGameDetail.gameData && raGameDetail.gameData.percent >= 100 ? "#F59E0B" : theme.accent

                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                                font.bold: true
                            }
                        }

                        Item {
                            width: parent.width
                            height: vpx(8)

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: theme.main
                                opacity: 0.4
                            }

                            Rectangle {
                                width: raGameDetail.gameData ? parent.width * (raGameDetail.gameData.percent / 100) : 0

                                height: parent.height
                                radius: height / 2

                                color: raGameDetail.gameData && raGameDetail.gameData.percent >= 100 ? "#F59E0B" : theme.accent

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 600
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }

                    // List achievement
                    ListView {
                        id: achievementsList
                        anchors {
                            top: progressSection.bottom
                            topMargin: vpx(16)
                            left: parent.left
                            right: parent.right
                            bottom: backHint.top
                            bottomMargin: vpx(12)
                        }
                        spacing: vpx(6)
                        clip: true
                        model: raAchievementsModel
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Item {
                            width: achievementsList.width
                            height: vpx(64)

                            Rectangle {
                                anchors.fill: parent
                                radius: vpx(10)
                                color: earned ? theme.main : "#1A000000"
                                opacity: earned ? 0.8 : 0.5
                                border.color: earned ? theme.accent : "transparent"
                                border.width: earned ? vpx(1) : 0
                            }

                            // Badge
                            Item {
                                id: badgeClip
                                width: vpx(48)
                                height: vpx(48)
                                anchors {
                                    left: parent.left
                                    leftMargin: vpx(8)
                                    verticalCenter: parent.verticalCenter
                                }
                                opacity: earned ? 1.0 : 0.35

                                Image {
                                    id: badgeImg
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    visible: false
                                    source: badgeUrl
                                    asynchronous: true
                                }
                                Rectangle {
                                    id: badgeMask
                                    anchors.fill: parent
                                    radius: vpx(6)
                                    visible: false
                                }
                                OpacityMask {
                                    anchors.fill: parent
                                    source: badgeImg
                                    maskSource: badgeMask
                                }
                            }

                            Column {
                                anchors {
                                    left: badgeClip.right
                                    leftMargin: vpx(10)
                                    right: pointsBadge.left
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

                            // Points badge
                            Rectangle {
                                id: pointsBadge
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

                    Row {
                        id: backHint
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                        }
                        spacing: vpx(12)
                        Rectangle {
                            width: vpx(32)
                            height: vpx(32)
                            radius: width / 2
                            color: theme.main
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "B"
                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: vpx(16)
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                        Text {
                            text: tr("Back")
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.020)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                        }
                        spacing: vpx(12)
                        Rectangle {
                            width: vpx(32)
                            height: vpx(32)
                            radius: width / 2
                            color: theme.main
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "B"
                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: vpx(16)
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                        Text {
                            text: tr("Back")
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.020)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Keys.onPressed: {
                    if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        raGameDetail.close();
                    }
                }
            }
        }

        ListModel {
            id: raFriendsModel
        }

        ListModel {
            id: raAchievementsModel
        }
    }
}
