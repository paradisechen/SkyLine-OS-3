// skylineOS 2 — ChatScreen.qml (Switch 2 GameChat Prompt + Friend Invite)
import QtQuick 2.12

FocusScope {
    id: chatRoot
    anchors.fill: parent

    property bool adding: false
    property string friendCode: ""
    property bool isDarkPage: (settings.appearanceMode === "Dark") || (settings.appearanceMode === "Auto" && settings.darkMode === "Yes")
    property color pageBg: isDarkPage ? "#1A1C21" : "#EFEFEF"
    property color headingColor: isDarkPage ? "#9CA3AF" : "#717680"
    property color subColor: isDarkPage ? "#CBD5E1" : "#858B94"
    property color cardBg: isDarkPage ? "#262932" : "#FFFFFF"
    property color dividerColor: isDarkPage ? "#383B44" : "#C8C8C8"

    ListModel { id: invitedModel }

    function loadInvited() {
        invitedModel.clear();
        var raw = api.memory.has("ns2_friends_invited") ? String(api.memory.get("ns2_friends_invited")) : "[]";
        try {
            var arr = JSON.parse(raw);
            if (Array.isArray(arr)) {
                for (var i = 0; i < arr.length; i++) invitedModel.append({ code: String(arr[i]) });
            }
        } catch (e) {}
    }

    function sendInvite(codeVal) {
        var cleaned = String(codeVal !== undefined ? codeVal : friendCode || "").trim();
        if (cleaned === "") { adding = false; chatRoot.forceActiveFocus(); return; }
        var arr = [];
        for (var i = 0; i < invitedModel.count; i++) arr.push(invitedModel.get(i).code);
        arr.push(cleaned);
        api.memory.set("ns2_friends_invited", JSON.stringify(arr));
        invitedModel.append({ code: cleaned });
        friendCode = ""; adding = false;
        selectSfx.play();
        chatRoot.forceActiveFocus();
    }

    function openFriendKeyboard() {
        adding = true;
        navSound.play();
        openSwitchKeyboard(tr("Add Friend Code"), friendCode, false, 24, function(val) {
            friendCode = val;
            sendInvite(val);
        }, function() {
            adding = false;
            chatRoot.forceActiveFocus();
        });
    }

    onVisibleChanged: {
        if (visible) { adding = false; loadInvited(); chatRoot.forceActiveFocus(); }
    }
    Keys.onBackPressed: {
        event.accepted = true;
        adding = false;
        backSfx.play();
        showHomeScreen();
    }
    Keys.onEscapePressed: {
        event.accepted = true;
        backSfx.play();
        if (adding) { adding = false; chatRoot.forceActiveFocus(); } else showHomeScreen();
    }
    Keys.onReleased: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function")
            root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
    }

    Keys.onPressed: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
        if (api.keys.isAccept(event) && !event.isAutoRepeat && !adding) {
            event.accepted = true;
            openFriendKeyboard();
        } else if ((api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace || event.key === Qt.Key_Escape) && !event.isAutoRepeat) {
            event.accepted = true; backSfx.play();
            if (adding) { adding = false; chatRoot.forceActiveFocus(); } else showHomeScreen();
        }
    }

    Rectangle { anchors.fill: parent; color: chatRoot.pageBg }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.8, vpx(700))
        spacing: vpx(16)

        Image { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(54); height: vpx(54); source: "../assets/images/navigation/ns2_gamechat.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: tr("GameChat"); color: chatRoot.headingColor; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.056); font.bold: true }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: vpx(8)
            Text { anchors.verticalCenter: parent.verticalCenter; text: tr("Add"); color: chatRoot.subColor; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027) }
            Rectangle {
                width: vpx(28); height: vpx(28); radius: width / 2; color: "#EE8600"; anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "+"; color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(18); font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: chatRoot.openFriendKeyboard() }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: tr("your friends to connect."); color: chatRoot.subColor; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.027) }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: vpx(240); height: vpx(44); radius: vpx(22); color: "#EE8600"
            Text { anchors.centerIn: parent; text: tr("A · Add Friend Code"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: chatRoot.openFriendKeyboard() }
        }

        Flow {
            visible: invitedModel.count > 0
            anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; spacing: vpx(8)
            Repeater {
                model: invitedModel
                delegate: Rectangle {
                    width: inviteText.implicitWidth + vpx(24); height: vpx(30); radius: height / 2
                    color: chatRoot.cardBg; border.width: 1; border.color: "#EE8600"
                    Text { id: inviteText; anchors.centerIn: parent; text: tr("Invited ") + code; color: "#EE8600"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.019); font.bold: true }
                }
            }
        }
    }

    Item {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.088)
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: chatRoot.dividerColor }
        Image { anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(8)
            Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: chatRoot.headingColor; anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "B"; color: chatRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
            }
            Text { text: tr("Back"); color: chatRoot.headingColor; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); anchors.verticalCenter: parent.verticalCenter }
            MouseArea { anchors.fill: parent; onClicked: { backSfx.play(); showHomeScreen(); } }
        }
    }
}
