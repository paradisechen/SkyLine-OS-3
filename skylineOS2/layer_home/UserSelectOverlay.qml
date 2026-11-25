// skylineOS 2 — UserSelectOverlay.qml (Centered User Cards, "¿Quién está jugando?", Exact Preview Parity & Press-to-Show Red X Delete)
import QtQuick 2.12

FocusScope {
    id: overlayRoot
    anchors.fill: parent
    z: 90
    visible: isOpen || sheet.y < parent.height
    focus: isOpen

    property bool isOpen: false
    property string headerTitle: "¿Quién está jugando?"
    property int selectedIndex: 0
    property bool creatingUser: false
    property bool deleteMode: false
    property string newCharId: "luigi"
    property string newUserName: ""
    property var pendingCallback: null

    signal userPicked(var userObj)
    signal closed()

    property var charOptions: ["mario", "luigi", "peach", "yoshi", "dk", "bowser"]
    property var charLabels: ["Mario", "Luigi", "Peach", "Yoshi", "Donkey Kong", "Bowser"]

    property string defaultUsersJson: '[{"id":"u1","name":"Mario","characterId":"mario","friendCode":"SW-4821-7390-1124"},{"id":"u2","name":"Luigi","characterId":"luigi","friendCode":"SW-9053-2814-6632"}]'

    ListModel { id: usersListModel }

    function saveUsersArray(arr) {
        var jsonStr = JSON.stringify(arr);
        api.memory.set("ns2_users_json", jsonStr);
        return jsonStr;
    }

    function realUserCount() {
        var cnt = 0;
        for (var i = 0; i < usersListModel.count; i++) {
            if (!usersListModel.get(i).isCreateTile) cnt++;
        }
        return cnt;
    }

    function loadUsers() {
        var raw = api.memory.has("ns2_users_json") ? String(api.memory.get("ns2_users_json")) : "";
        var arr = [];
        try {
            if (raw !== "") arr = JSON.parse(raw);
        } catch (e) { arr = []; }
        if (!arr || !arr.length) {
            try { arr = JSON.parse(defaultUsersJson); } catch (e2) { arr = []; }
            if (arr.length > 0 && api.memory.has("Username") && String(api.memory.get("Username")) !== "") {
                arr[0].name = String(api.memory.get("Username"));
                arr[0].characterId = api.memory.has("ns2_active_character") ? String(api.memory.get("ns2_active_character")) : "mario";
            }
            saveUsersArray(arr);
        }
        var activeId = api.memory.has("ns2_active_user_id") ? String(api.memory.get("ns2_active_user_id")) : (arr[0] ? arr[0].id : "u1");
        usersListModel.clear();
        var matchIdx = 0;
        for (var i = 0; i < arr.length; i++) {
            var u = arr[i];
            if (!u) continue;
            if (String(u.id) === activeId) matchIdx = usersListModel.count;
            usersListModel.append({
                uid: String(u.id || ("u" + i)),
                uname: String(u.name || "Player"),
                uchar: String(u.characterId || "mario"),
                ufc: String(u.friendCode || "SW-4821-7390-1124"),
                isCreateTile: false
            });
        }
        usersListModel.append({ uid: "__add__", uname: "Add User", uchar: "add", ufc: "", isCreateTile: true });
        selectedIndex = matchIdx;
    }

    function deleteUser(uid) {
        var raw = api.memory.has("ns2_users_json") ? String(api.memory.get("ns2_users_json")) : defaultUsersJson;
        var arr = [];
        try { arr = JSON.parse(raw); } catch (e) { arr = []; }
        if (!arr || arr.length <= 1) return;
        var next = [];
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] && String(arr[i].id) !== String(uid)) next.push(arr[i]);
        }
        if (next.length === 0) return;
        saveUsersArray(next);
        var activeUid = api.memory.has("ns2_active_user_id") ? String(api.memory.get("ns2_active_user_id")) : "";
        if (activeUid === String(uid)) {
            var fallbackUser = next[0];
            api.memory.set("ns2_active_user_id", String(fallbackUser.id));
            api.memory.set("ns2_active_character", String(fallbackUser.characterId || "mario"));
            api.memory.set("Username", String(fallbackUser.name || "Player"));
            api.memory.set("Launcher User", String(fallbackUser.name || "Player"));
            refreshSettings();
            userPicked(fallbackUser);
        }
        deleteMode = false;
        backSfx.play();
        loadUsers();
    }

    function open(title, cb) {
        headerTitle = (title && title !== "") ? title : "¿Quién está jugando?";
        pendingCallback = cb || null;
        creatingUser = false;
        deleteMode = false;
        newCharId = "luigi";
        newUserName = "";
        loadUsers();
        isOpen = true;
        overlayRoot.forceActiveFocus();
        Qt.callLater(function() { sheetFocus.forceActiveFocus(); });
    }

    function closeCancelled() {
        isOpen = false;
        creatingUser = false;
        deleteMode = false;
        pendingCallback = null;
        backSfx.play();
        closed();
    }

    function openNameKeyboard() {
        openSwitchKeyboard(tr("Enter user name..."), overlayRoot.newUserName, false, 14, function(val) {
            overlayRoot.newUserName = val;
            overlayRoot.forceActiveFocus();
            createForm.forceActiveFocus();
        }, function() {
            overlayRoot.forceActiveFocus();
            createForm.forceActiveFocus();
        });
    }

    function activateTile(idx) {
        if (idx < 0 || idx >= usersListModel.count) return;
        var item = usersListModel.get(idx);
        if (item.isCreateTile) {
            deleteMode = false;
            selectSfx.play();
            creatingUser = true;
            newUserName = "";
            newCharId = "luigi";
            Qt.callLater(function() { openNameKeyboard(); });
            return;
        }
        if (deleteMode && realUserCount() > 1) {
            deleteUser(item.uid);
            return;
        }
        api.memory.set("ns2_active_user_id", item.uid);
        api.memory.set("ns2_active_character", item.uchar);
        api.memory.set("Username", item.uname);
        api.memory.set("Launcher User", item.uname);
        refreshSettings();
        selectSfx.play();
        isOpen = false;
        deleteMode = false;
        var pickedObj = { id: item.uid, name: item.uname, characterId: item.uchar, friendCode: item.ufc };
        var cb = pendingCallback;
        pendingCallback = null;
        userPicked(pickedObj);
        closed();
        if (cb) cb(pickedObj);
    }

    function commitCreateUser() {
        var trimmed = String(newUserName || "").trim();
        if (trimmed === "") {
            for (var c = 0; c < charOptions.length; c++) {
                if (charOptions[c] === newCharId) { trimmed = charLabels[c]; break; }
            }
            if (trimmed === "") trimmed = "Player";
        }
        var raw = api.memory.has("ns2_users_json") ? String(api.memory.get("ns2_users_json")) : defaultUsersJson;
        var arr = [];
        try { arr = JSON.parse(raw); } catch (e) { arr = []; }
        if (!arr || !arr.length) {
            try { arr = JSON.parse(defaultUsersJson); } catch (e2) { arr = []; }
        }
        var nid = "u" + String(Date.now());
        var fc = "SW-" + String(1000 + Math.floor(Math.random() * 8999)) + "-" + String(1000 + Math.floor(Math.random() * 8999)) + "-" + String(1000 + Math.floor(Math.random() * 8999));
        var newObj = { id: nid, name: trimmed, characterId: newCharId, friendCode: fc };
        arr.push(newObj);
        saveUsersArray(arr);
        api.memory.set("ns2_active_user_id", nid);
        api.memory.set("ns2_active_character", newCharId);
        api.memory.set("Username", trimmed);
        api.memory.set("Launcher User", trimmed);
        refreshSettings();
        newUserSfx.play();
        creatingUser = false;
        deleteMode = false;
        isOpen = false;
        var cb = pendingCallback;
        pendingCallback = null;
        userPicked(newObj);
        closed();
        if (cb) cb(newObj);
    }

    property bool isDarkSheet: (settings.appearanceMode === "Dark") || (settings.appearanceMode === "Auto" && settings.darkMode === "Yes")
    property color sheetBg: isDarkSheet ? "#22242A" : "#EBEBEB"
    property color sheetCard: isDarkSheet ? "#2C2F37" : "#FFFFFF"
    property color sheetText: isDarkSheet ? "#F3F4F6" : "#24272D"
    property color sheetMuted: isDarkSheet ? "#9CA3AF" : "#6B7280"
    property color sheetDivider: isDarkSheet ? "#3B3F4A" : "#CCCCCC"

    Rectangle {
        id: bgDim
        anchors.fill: parent
        color: "#000000"
        opacity: overlayRoot.isOpen ? 0.42 : 0.0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        MouseArea {
            anchors.fill: parent
            enabled: overlayRoot.isOpen
            onClicked: overlayRoot.closeCancelled()
        }
    }

    Rectangle {
        id: sheet
        width: parent.width
        height: Math.round(parent.height * 0.49)
        x: 0
        y: overlayRoot.isOpen ? (parent.height - height) : parent.height
        color: overlayRoot.sheetBg
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: overlayRoot.sheetDivider }

        // Clean Top Title + Hairline Divider matching UserSelectOverlay.tsx
        Item {
            id: sheetHeader
            anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
            height: Math.round(parent.height * 0.21)

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: overlayRoot.creatingUser ? tr("Create a new user.") : tr(overlayRoot.headerTitle)
                color: overlayRoot.sheetText
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.032)
                font.weight: Font.Light
            }

            Text {
                visible: overlayRoot.creatingUser
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: tr("Cancel")
                color: overlayRoot.sheetMuted
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.022)
                MouseArea { anchors.fill: parent; onClicked: { backSfx.play(); overlayRoot.creatingUser = false; sheetFocus.forceActiveFocus(); } }
            }

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: overlayRoot.sheetDivider }
        }

        // Horizontally Centered Flat Account Cards + Circular (+) Button
        FocusScope {
            id: sheetFocus
            visible: !overlayRoot.creatingUser
            focus: overlayRoot.isOpen && !overlayRoot.creatingUser
            anchors {
                top: sheetHeader.bottom; bottom: sheetFooter.top; left: parent.left; right: parent.right
                leftMargin: screenmargin; rightMargin: screenmargin
            }

            Keys.onLeftPressed: {
                navSound.play();
                if (usersListModel.count > 0)
                    overlayRoot.selectedIndex = (overlayRoot.selectedIndex > 0) ? (overlayRoot.selectedIndex - 1) : (usersListModel.count - 1);
            }
            Keys.onRightPressed: {
                navSound.play();
                if (usersListModel.count > 0)
                    overlayRoot.selectedIndex = (overlayRoot.selectedIndex + 1) % usersListModel.count;
            }
            Keys.onBackPressed: {
                event.accepted = true;
                overlayRoot.closeCancelled();
                if (typeof showHomeScreen === "function")
                    showHomeScreen();
            }
            Keys.onEscapePressed: {
                event.accepted = true;
                if (overlayRoot.deleteMode) overlayRoot.deleteMode = false;
                else overlayRoot.closeCancelled();
            }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    overlayRoot.activateTile(overlayRoot.selectedIndex);
                } else if ((event.key === Qt.Key_Delete || event.key === Qt.Key_Minus || event.key === Qt.Key_X || api.keys.isFilters(event)) && !event.isAutoRepeat) {
                    if (overlayRoot.realUserCount() > 1) {
                        event.accepted = true;
                        overlayRoot.deleteMode = !overlayRoot.deleteMode;
                        navSound.play();
                    }
                } else if ((api.keys.isCancel(event) || event.key === Qt.Key_Backspace || event.key === Qt.Key_B) && !event.isAutoRepeat) {
                    event.accepted = true;
                    if (overlayRoot.deleteMode) overlayRoot.deleteMode = false;
                    else overlayRoot.closeCancelled();
                }
            }

            Flickable {
                id: centeredFlick
                anchors.fill: parent
                clip: true
                contentWidth: Math.max(width, centeredRow.implicitWidth + vpx(28))
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: centeredRow
                    spacing: vpx(24)
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(vpx(14), Math.round((centeredFlick.width - implicitWidth) / 2))

                    Repeater {
                        model: usersListModel
                        delegate: Item {
                            id: userTile
                            property bool isCur: index === overlayRoot.selectedIndex
                            property int cardW: Math.max(vpx(88), Math.round(screenheight * 0.165))
                            property int plusS: Math.max(vpx(42), Math.round(screenheight * 0.068))
                            width: isCreateTile ? plusS : cardW
                            height: isCreateTile ? plusS : (cardW + Math.round(screenheight * 0.050))
                            anchors.verticalCenter: parent.verticalCenter

                            // Regular Flat Rectangular User Card matching UserSelectOverlay.tsx
                            Rectangle {
                                visible: !isCreateTile
                                anchors.fill: parent
                                radius: vpx(4)
                                color: overlayRoot.sheetCard
                                border.width: isCur ? vpx(4) : 1
                                border.color: isCur ? theme.accent : overlayRoot.sheetDivider
                                scale: isCur ? 1.03 : 1.0
                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                clip: true

                                Column {
                                    anchors.fill: parent
                                    Item {
                                        width: parent.width
                                        height: parent.width
                                        Image {
                                            anchors.fill: parent
                                            source: "../assets/images/avatars/" + uchar + ".png"
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                            asynchronous: true
                                        }
                                    }
                                    Item {
                                        width: parent.width
                                        height: Math.max(vpx(26), parent.height - parent.width)
                                        Text {
                                            anchors { fill: parent; leftMargin: vpx(6); rightMargin: vpx(6) }
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignHCenter
                                            text: uname
                                            color: overlayRoot.sheetText
                                            font.family: titleFont.name
                                            font.pixelSize: Math.round(screenheight * 0.023)
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            // Outlined Circular (+) Add User Button
                            Rectangle {
                                visible: isCreateTile
                                anchors.centerIn: parent
                                width: plusS
                                height: plusS
                                radius: width / 2
                                color: isCur ? overlayRoot.sheetCard : "transparent"
                                border.width: vpx(2)
                                border.color: isCur ? theme.accent : overlayRoot.sheetMuted
                                scale: isCur ? 1.06 : 1.0
                                Behavior on scale { NumberAnimation { duration: 140 } }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Math.round(parent.width * 0.46)
                                    height: vpx(3)
                                    radius: height / 2
                                    color: isCur ? theme.accent : overlayRoot.sheetMuted
                                }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: vpx(3)
                                    height: Math.round(parent.height * 0.46)
                                    radius: width / 2
                                    color: isCur ? theme.accent : overlayRoot.sheetMuted
                                }
                            }

                            MouseArea {
                                property bool heldLong: false
                                anchors.fill: parent
                                hoverEnabled: true
                                pressAndHoldInterval: 420
                                onEntered: overlayRoot.selectedIndex = index
                                onPressed: heldLong = false
                                onPressAndHold: {
                                    if (!isCreateTile && overlayRoot.realUserCount() > 1) {
                                        heldLong = true;
                                        overlayRoot.deleteMode = true;
                                        navSound.play();
                                    }
                                }
                                onClicked: {
                                    if (heldLong) { heldLong = false; return; }
                                    overlayRoot.selectedIndex = index;
                                    if (overlayRoot.deleteMode && !isCreateTile) {
                                        overlayRoot.deleteMode = false;
                                        return;
                                    }
                                    overlayRoot.activateTile(index);
                                }
                            }

                            // Red X delete badge — shown ONLY after pressing/holding on an account
                            Rectangle {
                                id: deleteBadgeBtn
                                visible: overlayRoot.deleteMode && !isCreateTile && overlayRoot.realUserCount() > 1
                                width: vpx(28); height: vpx(28); radius: width / 2
                                color: "#E60012"
                                border.width: vpx(2); border.color: "#FFFFFF"
                                z: 30
                                anchors { top: parent.top; right: parent.right; topMargin: -vpx(8); rightMargin: -vpx(8) }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: vpx(13); height: vpx(3); radius: vpx(1.5)
                                    color: "#FFFFFF"
                                    rotation: 45
                                }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: vpx(13); height: vpx(3); radius: vpx(1.5)
                                    color: "#FFFFFF"
                                    rotation: -45
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: overlayRoot.deleteUser(uid)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Create New User Horizontal Row (pure QML, zero TextInput)
        FocusScope {
            id: createForm
            visible: overlayRoot.creatingUser
            focus: overlayRoot.isOpen && overlayRoot.creatingUser
            anchors {
                top: sheetHeader.bottom; bottom: sheetFooter.top; left: parent.left; right: parent.right
                leftMargin: screenmargin; rightMargin: screenmargin
            }

            Keys.onLeftPressed: {
                var idx = overlayRoot.charOptions.indexOf(overlayRoot.newCharId);
                var prev = (idx > 0) ? idx - 1 : overlayRoot.charOptions.length - 1;
                overlayRoot.newCharId = overlayRoot.charOptions[prev];
                navSound.play();
            }
            Keys.onRightPressed: {
                var idx = overlayRoot.charOptions.indexOf(overlayRoot.newCharId);
                var nxt = (idx + 1) % overlayRoot.charOptions.length;
                overlayRoot.newCharId = overlayRoot.charOptions[nxt];
                navSound.play();
            }
            Keys.onBackPressed: {
                event.accepted = true;
                overlayRoot.closeCancelled();
                if (typeof showHomeScreen === "function")
                    showHomeScreen();
            }
            Keys.onPressed: {
                if (api.keys.isCancel(event) || event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    backSfx.play();
                    overlayRoot.creatingUser = false;
                    sheetFocus.forceActiveFocus();
                } else if (api.keys.isAccept(event) || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    overlayRoot.commitCreateUser();
                } else if (api.keys.isFilters(event) || event.key === Qt.Key_Y) {
                    event.accepted = true;
                    overlayRoot.openNameKeyboard();
                } else if (event.key === Qt.Key_Backspace) {
                    event.accepted = true;
                    if (overlayRoot.newUserName.length > 0)
                        overlayRoot.newUserName = overlayRoot.newUserName.substring(0, overlayRoot.newUserName.length - 1);
                } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
                    event.accepted = true;
                    if (overlayRoot.newUserName.length < 14)
                        overlayRoot.newUserName += event.text;
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: vpx(16)

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(10)
                    Repeater {
                        model: overlayRoot.charOptions
                        delegate: Rectangle {
                            width: Math.max(vpx(42), Math.round(screenheight * 0.072))
                            height: width
                            radius: vpx(8)
                            color: overlayRoot.sheetCard
                            border.width: overlayRoot.newCharId === modelData ? vpx(3) : 1
                            border.color: overlayRoot.newCharId === modelData ? theme.accent : overlayRoot.sheetDivider
                            scale: overlayRoot.newCharId === modelData ? 1.08 : 1.0
                            clip: true
                            Image { anchors.fill: parent; source: "../assets/images/avatars/" + modelData + ".png"; fillMode: Image.PreserveAspectCrop; smooth: true }
                            MouseArea { anchors.fill: parent; onClicked: { navSound.play(); overlayRoot.newCharId = modelData; } }
                        }
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(10)
                    Rectangle {
                        width: vpx(210); height: vpx(40); radius: vpx(8)
                        color: overlayRoot.sheetCard
                        border.width: vpx(2); border.color: theme.accent

                        Text {
                            anchors { fill: parent; leftMargin: vpx(12); rightMargin: vpx(12) }
                            verticalAlignment: Text.AlignVCenter
                            text: overlayRoot.newUserName !== "" ? overlayRoot.newUserName : tr("Tap / Y to enter name...")
                            color: overlayRoot.newUserName !== "" ? overlayRoot.sheetText : overlayRoot.sheetMuted
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.020)
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: overlayRoot.openNameKeyboard()
                        }
                    }
                    Rectangle {
                        width: vpx(96); height: vpx(40); radius: vpx(8); color: theme.accent
                        Text { anchors.centerIn: parent; text: tr("Save"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: overlayRoot.commitCreateUser() }
                    }
                }
            }
        }

        // Bottom Footer Row matching UserSelectOverlay.tsx
        Item {
            id: sheetFooter
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
            height: Math.round(parent.height * 0.17)
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: overlayRoot.sheetDivider }
            Image { anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: vpx(24)
                Row {
                    spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                    Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: overlayRoot.sheetText; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "B"; color: overlayRoot.sheetBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                    }
                    Text { text: tr("Back"); color: overlayRoot.sheetText; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); anchors.verticalCenter: parent.verticalCenter }
                    MouseArea { anchors.fill: parent; onClicked: { if (overlayRoot.creatingUser) { overlayRoot.creatingUser = false; sheetFocus.forceActiveFocus(); } else if (overlayRoot.deleteMode) { overlayRoot.deleteMode = false; } else { overlayRoot.closeCancelled(); } } }
                }
                Row {
                    visible: !overlayRoot.creatingUser
                    spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                    Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: overlayRoot.sheetText; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "A"; color: overlayRoot.sheetBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                    }
                    Text { text: tr("OK"); color: overlayRoot.sheetText; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); anchors.verticalCenter: parent.verticalCenter }
                    MouseArea { anchors.fill: parent; onClicked: overlayRoot.activateTile(overlayRoot.selectedIndex) }
                }
            }
        }
    }
}
