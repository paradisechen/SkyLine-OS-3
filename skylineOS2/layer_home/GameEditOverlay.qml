// skylineOS 2 — GameEditOverlay.qml (Switch 2 "+" Software Options & Instant Name/Cover/Background Editor)
import QtQuick 2.12
import QtGraphicalEffects 1.0

FocusScope {
    id: editRoot
    anchors.fill: parent
    z: 300
    visible: dimBg.opacity > 0.01

    property bool isOpen: false
    property var targetGame: null
    property int focusRow: 0
    property bool inBacklog: false
    property string editingField: "" // "" | "title" | "cover" | "bg"
    property string editDraft: ""
    property int actionCount: 7

    signal closed()

    function readBacklogMap() {
        var raw = api.memory.has("ns2_backlog_titles") ? String(api.memory.get("ns2_backlog_titles")) : "[]";
        try {
            var arr = JSON.parse(raw);
            return Array.isArray(arr) ? arr : [];
        } catch (e) {
            return [];
        }
    }

    function isGameInBacklog(game) {
        if (!game) return false;
        var arr = readBacklogMap();
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] === game.title) return true;
        }
        return false;
    }

    function toggleBacklog(game) {
        if (!game) return;
        var arr = readBacklogMap();
        var next = [];
        var found = false;
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] === game.title) found = true;
            else next.push(arr[i]);
        }
        if (!found) next.push(game.title);
        api.memory.set("ns2_backlog_titles", JSON.stringify(next));
        inBacklog = !found;
        if (inBacklog) turnOnSfx.play(); else turnOffSfx.play();
    }

    function open(game) {
        if (!game) return;
        targetGame = game;
        inBacklog = isGameInBacklog(game);
        editingField = "";
        editDraft = "";
        focusRow = 0;
        isOpen = true;
        editRoot.forceActiveFocus();
        Qt.callLater(function() { sheetFocus.forceActiveFocus(); });
    }

    function close() {
        editingField = "";
        isOpen = false;
        backSfx.play();
        closed();
    }

    function startEdit(fieldKey) {
        if (!targetGame) return;
        editingField = fieldKey;
        var initialVal = "";
        var promptTitle = tr("Edit Game Name:");
        var allowUrl = false;
        if (fieldKey === "title") {
            initialVal = getGameTitle(targetGame);
            promptTitle = tr("Edit Game Name:");
        } else if (fieldKey === "cover") {
            initialVal = getGameCover(targetGame);
            promptTitle = tr("Main Photo URL / Local Path:");
            allowUrl = true;
        } else if (fieldKey === "bg") {
            initialVal = getGameBg(targetGame);
            promptTitle = tr("Game Background URL / Local Path:");
            allowUrl = true;
        }
        editDraft = initialVal;
        selectSfx.play();
        openSwitchKeyboard(promptTitle, initialVal, allowUrl, 240, function(val) {
            editRoot.editDraft = val;
            editRoot.commitEdit();
        }, function() {
            editRoot.cancelEdit();
        });
    }

    function commitEdit() {
        if (!targetGame || editingField === "") return;
        var val = String(editDraft || "").trim();
        var orig = String(targetGame.title || "");
        if (editingField === "title") {
            if (val === "" || val === orig) api.memory.unset("CUSTOM_TITLE::" + orig);
            else api.memory.set("CUSTOM_TITLE::" + orig, val);
        } else if (editingField === "cover") {
            if (val === "") api.memory.unset("CUSTOM_COVER::" + orig);
            else api.memory.set("CUSTOM_COVER::" + orig, val);
        } else if (editingField === "bg") {
            if (val === "") api.memory.unset("CUSTOM_BG::" + orig);
            else api.memory.set("CUSTOM_BG::" + orig, val);
        }
        gameOverrideVersion++;
        editingField = "";
        turnOnSfx.play();
        editRoot.forceActiveFocus();
        sheetFocus.forceActiveFocus();
    }

    function cancelEdit() {
        editingField = "";
        backSfx.play();
        editRoot.forceActiveFocus();
        sheetFocus.forceActiveFocus();
    }

    function resetOverrides() {
        if (!targetGame) return;
        var orig = String(targetGame.title || "");
        api.memory.unset("CUSTOM_TITLE::" + orig);
        api.memory.unset("CUSTOM_COVER::" + orig);
        api.memory.unset("CUSTOM_BG::" + orig);
        gameOverrideVersion++;
        turnOffSfx.play();
    }

    function triggerAction(idx) {
        if (!targetGame) return;
        if (idx === 0) startEdit("title");
        else if (idx === 1) startEdit("cover");
        else if (idx === 2) startEdit("bg");
        else if (idx === 3) {
            targetGame.favorite = !targetGame.favorite;
            if (targetGame.favorite) turnOnSfx.play(); else turnOffSfx.play();
        } else if (idx === 4) {
            toggleBacklog(targetGame);
        } else if (idx === 5) {
            isOpen = false;
            var g = targetGame;
            closed();
            if (homeScreen && g) openGameDetail(homeScreen, g);
        } else if (idx === 6) {
            resetOverrides();
        }
    }

    property bool isDarkSheet: (settings.appearanceMode === "Dark") || (settings.appearanceMode === "Auto" && settings.darkMode === "Yes")
    property color sheetBg: isDarkSheet ? "#1F2126" : "#EFEFEF"
    property color sheetCard: isDarkSheet ? "#2A2D34" : "#FFFFFF"
    property color sheetText: isDarkSheet ? "#F3F4F6" : "#2C2C2C"
    property color sheetMuted: isDarkSheet ? "#9CA3AF" : "#6B7280"
    property color sheetDivider: isDarkSheet ? "#383B44" : "#CFCFCF"

    Rectangle {
        id: dimBg
        anchors.fill: parent
        color: "#000000"
        opacity: editRoot.isOpen ? 0.56 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea { anchors.fill: parent; enabled: editRoot.isOpen; onClicked: editRoot.close() }
    }

    Rectangle {
        id: sheet
        width: parent.width
        height: Math.round(parent.height * 0.78)
        x: 0
        y: editRoot.isOpen ? (parent.height - height) : parent.height
        color: editRoot.sheetBg
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        FocusScope {
            id: sheetFocus
            anchors.fill: parent
            focus: true

            Keys.onUpPressed: {
                if (editRoot.editingField !== "") return;
                navSound.play();
                editRoot.focusRow = (editRoot.focusRow + editRoot.actionCount - 1) % editRoot.actionCount;
                actionsList.positionViewAtIndex(editRoot.focusRow, ListView.Contain);
            }
            Keys.onDownPressed: {
                if (editRoot.editingField !== "") return;
                navSound.play();
                editRoot.focusRow = (editRoot.focusRow + 1) % editRoot.actionCount;
                actionsList.positionViewAtIndex(editRoot.focusRow, ListView.Contain);
            }
            Keys.onBackPressed: {
                event.accepted = true;
                editRoot.close();
                if (typeof showHomeScreen === "function")
                    showHomeScreen();
            }
            Keys.onPressed: {
                if (editRoot.editingField !== "") return;
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    editRoot.triggerAction(editRoot.focusRow);
                } else if ((api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace || event.key === Qt.Key_Escape || event.key === Qt.Key_Plus || event.key === Qt.Key_Equal || event.key === Qt.Key_M || event.key === Qt.Key_Menu) && !event.isAutoRepeat) {
                    event.accepted = true;
                    editRoot.close();
                }
            }

            // Header with Live Cover, Live Background Thumbnail & Live Title
            Item {
                id: editHeader
                anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
                height: Math.round(parent.height * 0.21)

                Row {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    spacing: vpx(16)
                    Rectangle {
                        width: vpx(68); height: vpx(68); radius: vpx(10); color: editRoot.sheetCard; clip: true; anchors.verticalCenter: parent.verticalCenter
                        border.width: 1; border.color: editRoot.sheetDivider
                        Image {
                            anchors.fill: parent
                            source: (gameOverrideVersion >= 0 && editRoot.targetGame) ? getGameCover(editRoot.targetGame) : ""
                            fillMode: Image.PreserveAspectCrop; smooth: true
                        }
                    }
                    Rectangle {
                        width: vpx(110); height: vpx(68); radius: vpx(10); color: editRoot.sheetCard; clip: true; anchors.verticalCenter: parent.verticalCenter
                        border.width: 1; border.color: editRoot.sheetDivider
                        Image {
                            anchors.fill: parent
                            source: (gameOverrideVersion >= 0 && editRoot.targetGame) ? getGameBg(editRoot.targetGame) : ""
                            fillMode: Image.PreserveAspectCrop; smooth: true
                        }
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: vpx(18); color: "#88000000"
                            Text { anchors.centerIn: parent; text: tr("BG Preview"); color: "white"; font.pixelSize: vpx(10); font.bold: true }
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: vpx(3)
                        Text {
                            text: (gameOverrideVersion >= 0 && editRoot.targetGame) ? getGameTitle(editRoot.targetGame) : ""
                            color: editRoot.sheetText; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.032); font.bold: true
                        }
                        Text {
                            text: tr("Manage Software · Instant Name, Main Photo & Background")
                            color: editRoot.sheetMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.020)
                        }
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: editRoot.sheetDivider }
            }

            // Inline Text Editor Strip (pure QML, taps into SwitchKeyboard)
            Rectangle {
                id: editorBar
                visible: editRoot.editingField !== ""
                anchors { top: editHeader.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin; topMargin: vpx(12) }
                height: vpx(112)
                radius: vpx(12)
                color: editRoot.sheetCard
                border.width: vpx(3)
                border.color: theme.accent
                z: 20

                Column {
                    anchors { fill: parent; margins: vpx(14) }
                    spacing: vpx(10)

                    Text {
                        text: editRoot.editingField === "title" ? tr("Edit Game Name:")
                            : (editRoot.editingField === "cover" ? tr("Main Photo URL / Local Path:") : tr("Game Background URL / Local Path:"))
                        color: theme.accent; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.024); font.bold: true
                    }

                    Row {
                        width: parent.width
                        spacing: vpx(10)

                        Rectangle {
                            width: parent.width - vpx(210); height: vpx(44); radius: vpx(8)
                            color: editRoot.sheetBg; border.width: 2; border.color: theme.accent
                            Text {
                                anchors { fill: parent; leftMargin: vpx(12); rightMargin: vpx(12) }
                                verticalAlignment: Text.AlignVCenter
                                color: editRoot.sheetText
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.023)
                                text: editRoot.editDraft
                                elide: Text.ElideMiddle
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: editRoot.startEdit(editRoot.editingField)
                            }
                        }

                        Rectangle {
                            width: vpx(96); height: vpx(44); radius: vpx(8); color: theme.accent
                            Text { anchors.centerIn: parent; text: tr("Apply"); color: "white"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: editRoot.commitEdit() }
                        }

                        Rectangle {
                            width: vpx(96); height: vpx(44); radius: vpx(8); color: editRoot.sheetBg; border.width: 1; border.color: editRoot.sheetDivider
                            Text { anchors.centerIn: parent; text: tr("Cancel"); color: editRoot.sheetText; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: editRoot.cancelEdit() }
                        }
                    }
                }
            }

            // Action Rows
            ListView {
                id: actionsList
                anchors {
                    top: editorBar.visible ? editorBar.bottom : editHeader.bottom
                    bottom: editFooter.top
                    left: parent.left
                    right: parent.right
                    leftMargin: screenmargin
                    rightMargin: screenmargin
                    topMargin: vpx(12)
                    bottomMargin: vpx(10)
                }
                clip: true
                spacing: vpx(8)
                currentIndex: editRoot.focusRow
                model: [
                    { title: "Edit Game Name", sub: (gameOverrideVersion >= 0 && editRoot.targetGame) ? getGameTitle(editRoot.targetGame) : "", badge: "Edit" },
                    { title: "Change Main Photo (Cover)", sub: (gameOverrideVersion >= 0 && editRoot.targetGame) ? (getGameCover(editRoot.targetGame) || "Default cover") : "", badge: "Edit" },
                    { title: "Change Game Background", sub: (gameOverrideVersion >= 0 && editRoot.targetGame) ? (getGameBg(editRoot.targetGame) || "Default background") : "", badge: "Edit" },
                    { title: "Favorite Game", sub: editRoot.targetGame && editRoot.targetGame.favorite ? "On (Pinned first in All Software)" : "Off", badge: (editRoot.targetGame && editRoot.targetGame.favorite) ? "ON" : "OFF" },
                    { title: "Play Backlog (GameShare)", sub: editRoot.inBacklog ? "Added to Play Backlog" : "Not in Backlog", badge: editRoot.inBacklog ? "ON" : "OFF" },
                    { title: "Software Details", sub: "View synopsis, publisher, achievements & playtime", badge: ">" },
                    { title: "Reset Custom Name & Art", sub: "Restore original Pegasus metadata & artwork", badge: "Reset" }
                ]
                delegate: Rectangle {
                    width: actionsList.width
                    height: vpx(58)
                    radius: vpx(10)
                    color: editRoot.sheetCard
                    border.width: editRoot.focusRow === index ? vpx(3) : vpx(1)
                    border.color: editRoot.focusRow === index ? theme.accent : editRoot.sheetDivider

                    Rectangle {
                        visible: editRoot.focusRow === index
                        anchors { left: parent.left; leftMargin: vpx(8); top: parent.top; topMargin: vpx(10); bottom: parent.bottom; bottomMargin: vpx(10) }
                        width: vpx(4); radius: vpx(2); color: theme.accent
                    }
                    Row {
                        anchors { fill: parent; leftMargin: vpx(22); rightMargin: vpx(20) }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; width: parent.width - vpx(110); spacing: vpx(2)
                            Text { width: parent.width; elide: Text.ElideRight; text: tr(modelData.title); color: editRoot.focusRow === index ? theme.accent : editRoot.sheetText; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.025); font.bold: editRoot.focusRow === index }
                            Text { width: parent.width; elide: Text.ElideMiddle; text: tr(modelData.sub); color: editRoot.sheetMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.019) }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.badge
                            color: (modelData.badge === "ON" || editRoot.focusRow === index) ? theme.accent : editRoot.sheetMuted
                            font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); font.bold: true
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: editRoot.focusRow = index
                        onClicked: { editRoot.focusRow = index; editRoot.triggerAction(index); }
                    }
                }
            }

            Item {
                id: editFooter
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
                height: Math.round(parent.height * 0.12)
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: editRoot.sheetDivider }
                Image { anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: vpx(22)
                    Row {
                        spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                        Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: editRoot.sheetText; anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "A"; color: editRoot.sheetBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                        }
                        Text { text: tr("Select"); color: editRoot.sheetText; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row {
                        spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                        Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: editRoot.sheetText; anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "B"; color: editRoot.sheetBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                        }
                        Text { text: tr("Close"); color: editRoot.sheetText; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); anchors.verticalCenter: parent.verticalCenter }
                        MouseArea { anchors.fill: parent; onClicked: editRoot.close() }
                    }
                }
            }
        }
    }
}
