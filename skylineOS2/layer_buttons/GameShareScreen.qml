// skylineOS 2 — GameShareScreen.qml (Switch 2 Split Screen: Most Played, Screen Time, Play Backlog)
import QtQuick 2.12
import QtGraphicalEffects 1.0

FocusScope {
    id: shareRoot
    anchors.fill: parent
    property int currentTab: 0
    property string activeUserName: (api.memory.has("Username") && api.memory.get("Username") !== "") ? String(api.memory.get("Username")) : "Mario"
    property real totalHoursSum: 0

    property bool isDarkPage: (settings.appearanceMode === "Dark") || (settings.appearanceMode === "Auto" && settings.darkMode === "Yes")
    property color pageBg: isDarkPage ? "#1A1C21" : "#EFEFEF"
    property color sidebarBg: isDarkPage ? "#22252B" : "#EAEAEA"
    property color cardBg: isDarkPage ? "#262932" : "#FFFFFF"
    property color textMain: isDarkPage ? "#F3F4F6" : "#2C2C2C"
    property color textMuted: isDarkPage ? "#9CA3AF" : "#6B7280"
    property color dividerColor: isDarkPage ? "#383B44" : "#C8C8C8"
    property color accentTeal: "#2CADBF"

    ListModel { id: mostPlayedModel }
    ListModel { id: backlogModel }

    function readBacklogTitles() {
        var raw = api.memory.has("ns2_backlog_titles") ? String(api.memory.get("ns2_backlog_titles")) : "[]";
        try {
            var arr = JSON.parse(raw);
            return Array.isArray(arr) ? arr : [];
        } catch (e) { return []; }
    }

    function isInBacklogList(arr, title) {
        for (var i = 0; i < arr.length; i++) { if (arr[i] === title) return true; }
        return false;
    }

    property string activeCharId: api.memory.has("ns2_active_character") ? String(api.memory.get("ns2_active_character") || "mario") : "mario"

    function getPlayersForGame(origTitle) {
        var list = [];
        var pKey = "GAME_PLAYERS::" + origTitle;
        if (api.memory.has(pKey)) {
            try {
                var parsed = JSON.parse(String(api.memory.get(pKey)));
                if (Array.isArray(parsed)) list = parsed;
            } catch (e) { list = []; }
        }
        if (list.length === 0) {
            list.push({ name: activeUserName, charId: activeCharId });
        }
        return list;
    }

    function formatPlayersNames(players) {
        var names = [];
        for (var i = 0; i < players.length; i++) {
            if (players[i] && players[i].name) names.push(players[i].name);
        }
        return names.join(", ");
    }

    function reloadData() {
        activeUserName = (api.memory.has("Username") && api.memory.get("Username") !== "") ? String(api.memory.get("Username")) : "Mario";
        activeCharId = api.memory.has("ns2_active_character") ? String(api.memory.get("ns2_active_character") || "mario") : "mario";
        mostPlayedModel.clear();
        backlogModel.clear();
        var items = [];
        var bl = readBacklogTitles();
        var sumHrs = 0;

        for (var i = 0; i < api.allGames.count; i++) {
            var g = api.allGames.get(i);
            var secs = api.memory.has(g.title) ? parseInt(api.memory.get(g.title)) : 0;
            if (isNaN(secs)) secs = 0;
            var hrs = Math.round((secs / 3600.0) * 10) / 10;
            if (hrs < 0.1 && g.playTime > 0) hrs = Math.round((g.playTime / 3600.0) * 10) / 10;
            sumHrs += hrs;
            var cover = getGameCover(g);
            var players = getPlayersForGame(g.title);
            items.push({
                gindex: i, title: getGameTitle(g), cover: cover, hours: hrs,
                playersJson: JSON.stringify(players),
                playersText: formatPlayersNames(players),
                platform: (g.collections && g.collections.count > 0) ? g.collections.get(0).name : "System"
            });
            if (isInBacklogList(bl, g.title)) {
                backlogModel.append({ gindex: i, title: g.title, cover: cover, platform: (g.collections && g.collections.count > 0) ? g.collections.get(0).name : "System" });
            }
        }
        items.sort(function(a, b) { return b.hours - a.hours; });
        totalHoursSum = Math.round(sumHrs * 10) / 10;
        var limit = Math.min(items.length, 24);
        for (var k = 0; k < limit; k++) mostPlayedModel.append(items[k]);
    }

    function removeFromBacklog(title) {
        var bl = readBacklogTitles();
        var next = [];
        for (var i = 0; i < bl.length; i++) { if (bl[i] !== title) next.push(bl[i]); }
        api.memory.set("ns2_backlog_titles", JSON.stringify(next));
        turnOffSfx.play();
        reloadData();
    }

    onVisibleChanged: {
        if (visible) {
            reloadData();
            shareRoot.forceActiveFocus();
        }
    }

    Keys.onUpPressed: { navSound.play(); currentTab = (currentTab + 2) % 3; }
    Keys.onDownPressed: { navSound.play(); currentTab = (currentTab + 1) % 3; }
    Keys.onBackPressed: { event.accepted = true; backSfx.play(); showHomeScreen(); }
    Keys.onEscapePressed: { event.accepted = true; backSfx.play(); showHomeScreen(); }
    Keys.onReleased: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function")
            root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
    }

    Keys.onPressed: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
        if ((api.keys.isCancel(event) || event.key === Qt.Key_Escape || event.key === Qt.Key_B || event.key === Qt.Key_Backspace) && !event.isAutoRepeat) {
            event.accepted = true; backSfx.play(); showHomeScreen();
        }
    }

    Rectangle { anchors.fill: parent; color: shareRoot.pageBg }

    Item {
        id: headerRow
        anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.115)

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: vpx(14)
            Image { width: vpx(28); height: vpx(28); source: "../assets/images/navigation/ns2_gameshare.svg"; fillMode: Image.PreserveAspectFit; smooth: true; anchors.verticalCenter: parent.verticalCenter }
            Text { text: tr("GameShare"); color: shareRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.042 * fontScale); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
        }
        Text { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: shareRoot.activeUserName + " · Retroid Pocket 5"; color: shareRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.025 * fontScale) }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: shareRoot.dividerColor }
    }

    Item {
        anchors { top: headerRow.bottom; bottom: footerBar.top; left: parent.left; right: parent.right }

        Rectangle {
            id: leftPane
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            width: Math.round(parent.width * 0.295)
            color: shareRoot.sidebarBg

            Column {
                anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: vpx(22); leftMargin: screenmargin; rightMargin: vpx(18) }
                spacing: vpx(8)
                Repeater {
                    model: [
                        { label: "Most Played", sub: mostPlayedModel.count > 0 ? mostPlayedModel.get(0).title : "No games" },
                        { label: "Screen Time", sub: shareRoot.totalHoursSum + " hrs total" },
                        { label: "Play Backlog", sub: backlogModel.count + " queued" }
                    ]
                    delegate: Rectangle {
                        width: parent.width; height: vpx(74)
                        color: shareRoot.currentTab === index ? (shareRoot.isDarkPage ? "#2C303A" : "#FFFFFF") : "transparent"
                        border.width: shareRoot.currentTab === index ? vpx(3) : 0
                        border.color: shareRoot.accentTeal
                        Rectangle { visible: shareRoot.currentTab === index; anchors { left: parent.left; leftMargin: vpx(8); top: parent.top; topMargin: vpx(10); bottom: parent.bottom; bottomMargin: vpx(10) } width: vpx(4); color: shareRoot.accentTeal }
                        Column {
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: vpx(18); right: parent.right; rightMargin: vpx(10) }
                            spacing: vpx(2)
                            Text { width: parent.width; text: tr(modelData.label); color: shareRoot.currentTab === index ? shareRoot.accentTeal : shareRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.032 * fontScale); font.bold: shareRoot.currentTab === index; elide: Text.ElideRight }
                            Text { width: parent.width; text: modelData.sub; color: shareRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023 * fontScale); elide: Text.ElideRight }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { navSound.play(); shareRoot.currentTab = index; } }
                    }
                }
            }
        }

        Item {
            anchors { top: parent.top; bottom: parent.bottom; left: leftPane.right; right: parent.right; margins: vpx(28) }

            ListView {
                visible: shareRoot.currentTab === 0
                anchors.fill: parent; clip: true; spacing: vpx(10)
                model: mostPlayedModel
                delegate: Rectangle {
                    width: ListView.view.width; height: vpx(78); color: shareRoot.cardBg; radius: vpx(8); border.width: 1; border.color: shareRoot.dividerColor
                    Row {
                        anchors { fill: parent; margins: vpx(10) }
                        spacing: vpx(14)
                        Image { width: vpx(48); height: vpx(48); source: cover; fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            width: parent.width - vpx(260); anchors.verticalCenter: parent.verticalCenter; spacing: vpx(2)
                            Text { width: parent.width; text: title; color: shareRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.031 * fontScale); font.bold: true; elide: Text.ElideRight }
                            Text { text: hours + " hours played"; color: shareRoot.accentTeal; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.025 * fontScale) }
                        }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: vpx(8)
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: vpx(4)
                                Repeater {
                                    model: {
                                        try { return JSON.parse(playersJson); } catch (e) { return [{ name: shareRoot.activeUserName, charId: shareRoot.activeCharId }]; }
                                    }
                                    delegate: Item {
                                        width: vpx(28); height: vpx(28)
                                        Image {
                                            id: pAv
                                            anchors.fill: parent
                                            source: "../assets/images/avatars/" + (modelData.charId || "mario") + ".png"
                                            fillMode: Image.PreserveAspectCrop; visible: false
                                        }
                                        Rectangle { id: pMask; anchors.fill: parent; radius: width / 2; visible: false }
                                        OpacityMask { anchors.fill: parent; source: pAv; maskSource: pMask }
                                        Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.width: vpx(1.5); border.color: shareRoot.cardBg }
                                    }
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: playersText || shareRoot.activeUserName
                                color: shareRoot.textMuted
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.025 * fontScale)
                                font.bold: true
                            }
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: { var gameObj = api.allGames.get(gindex); if (gameObj) openGameDetail(shareRoot, gameObj); } }
                }
            }

            ListView {
                visible: shareRoot.currentTab === 1
                anchors.fill: parent; clip: true; spacing: vpx(14)
                model: mostPlayedModel
                delegate: Item {
                    width: ListView.view.width; height: vpx(54)
                    property real maxHrs: mostPlayedModel.count > 0 ? Math.max(1.0, mostPlayedModel.get(0).hours) : 1.0
                    property real pct: Math.min(1.0, Math.max(0.04, hours / maxHrs))
                    Column {
                        anchors.fill: parent; spacing: vpx(6)
                        Row {
                            width: parent.width
                            Text { width: parent.width - vpx(70); text: title; color: shareRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); font.bold: true; elide: Text.ElideRight }
                            Text { width: vpx(70); horizontalAlignment: Text.AlignRight; text: hours + "h"; color: shareRoot.accentTeal; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true }
                        }
                        Rectangle {
                            width: parent.width; height: vpx(12); radius: vpx(6); color: shareRoot.sidebarBg
                            Rectangle { width: Math.round(parent.width * pct); height: parent.height; radius: vpx(6); color: shareRoot.accentTeal }
                        }
                    }
                }
            }

            Item {
                visible: shareRoot.currentTab === 2
                anchors.fill: parent
                Text {
                    visible: backlogModel.count === 0; anchors.centerIn: parent; width: parent.width * 0.8; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                    text: tr("No titles queued in Play Backlog. Press (+) on any game on Home to add it here.")
                    color: shareRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.024)
                }
                ListView {
                    visible: backlogModel.count > 0; anchors.fill: parent; clip: true; spacing: vpx(10)
                    model: backlogModel
                    delegate: Rectangle {
                        width: ListView.view.width; height: vpx(78); color: shareRoot.cardBg; radius: vpx(8); border.width: 1; border.color: shareRoot.dividerColor
                        Row {
                            anchors { fill: parent; margins: vpx(10) }
                            spacing: vpx(14)
                            Image { width: vpx(48); height: vpx(48); source: cover; fillMode: Image.PreserveAspectCrop; smooth: true; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                width: parent.width - vpx(160); anchors.verticalCenter: parent.verticalCenter
                                Text { width: parent.width; text: title; color: shareRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.024); font.bold: true; elide: Text.ElideRight }
                                Text { text: platform; color: shareRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023 * fontScale) }
                            }
                            Rectangle {
                                width: vpx(88); height: vpx(32); radius: vpx(6); color: shareRoot.sidebarBg; anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.centerIn: parent; text: tr("Remove"); color: shareRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.019) }
                                MouseArea { anchors.fill: parent; onClicked: shareRoot.removeFromBacklog(title) }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: footerBar
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.088)
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: shareRoot.dividerColor }
        Image { anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(8)
            Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: shareRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "B"; color: shareRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
            }
            Text { text: tr("Back"); color: shareRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); anchors.verticalCenter: parent.verticalCenter }
            MouseArea { anchors.fill: parent; onClicked: { backSfx.play(); showHomeScreen(); } }
        }
    }
}
