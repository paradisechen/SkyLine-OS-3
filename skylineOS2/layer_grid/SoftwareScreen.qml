import QtQuick 2.12
import QtGraphicalEffects 1.0
import SortFilterProxyModel 0.2
import "../global"
import "../Lists"
import "../layer_help"
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

FocusScope {
    property int numcolumns: (settings && settings.allSoftCols >= 3 && settings.allSoftCols <= 6) ? settings.allSoftCols : (widescreen ? 6 : 5)
    function changeGridSize(delta) {
        var next = Math.max(3, Math.min(6, numcolumns + delta));
        if (next !== numcolumns) {
            numcolumns = next;
            api.memory.set("All Software Columns", String(next));
            navSound.play();
        }
    }
    property int idx: 0
    property var sortTitle: {
        switch (sortByIndex) {
        case 0:
            return tr("By Time Last Played");
        case 1:
            return tr("By Total Play Time");
        case 2:
            return tr("By Title");
        case 3:
            return tr("By Publisher");
        case 4:
            return tr("Favorites");
        default:
            return "";
        }
    }

    Item {
        id: softwareScreenContainer
        property int barIndex: -1
        property bool searchEditing: false

        property bool tabsFocused: false
        property int tabIndex: 0
        readonly property bool gridActive: barIndex < 0 && !tabsFocused

        onTabIndexChanged: tabList.positionViewAtIndex(tabIndex, ListView.Contain)

        function focusGrid() {
            barIndex = -1;
            tabsFocused = false;
            gameGrid.forceActiveFocus();
        }

        function applySearch(text) {
            softwareSearch = text;
            gameGrid.currentIndex = 0;
        }

        function startSearch() {
            searchEditing = true;
            openSwitchKeyboard(tr("Search"), softwareSearch, false, 60, function(val) {
                searchEditing = false;
                applySearch(val);
                barIndex = -1;
                gameGrid.forceActiveFocus();
            }, function() {
                searchEditing = false;
                gameGrid.forceActiveFocus();
            });
        }

        function activateBar() {
            selectSfx.play();
            if (barIndex === 0) {
                focusGrid();
                showHomeScreen();
            } else if (barIndex === 1) {
                startSearch();
            } else if (barIndex === 2) {
                cycleSort();
            }
        }

        function setCollection(i) {
            currentCollection = i;
            nextCollection = i;
            tabIndex = i + 1;
            gameGrid.currentIndex = 0;
        }

        function cycleCollection(step) {
            var total = api.collections.count + 1;
            var pos = (currentCollection + 1 + step + total) % total;
            if (step > 0)
                turnOnSfx.play();
            else
                turnOffSfx.play();
            setCollection(pos - 1);
        }

        anchors {
            fill: parent
            leftMargin: screenmargin
            rightMargin: screenmargin
        }

        SortFilterProxyModel {
            id: searchProxy
            sourceModel: softwareList[sortByIndex].games
            filters: RegExpFilter {
                roleName: "title"
                pattern: softwareSearch.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
                caseSensitivity: Qt.CaseInsensitive
                enabled: softwareSearch !== ""
            }
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
            if (event.isAutoRepeat || searchEditing)
                return;

            if (api.keys.isDetails(event)) {
                event.accepted = true;
                if (gridActive && gameGrid.count > 0) {
                    var favItem = gameGrid.currentItem;
                    var favTarget = (favItem && favItem.gameModel) ? favItem.gameModel : currentGame;
                    if (favTarget) {
                        currentGame = favTarget;
                        if (favTarget.favorite)
                            turnOffSfx.play();
                        else
                            turnOnSfx.play();
                        favTarget.favorite = !favTarget.favorite;
                    }
                }
                return;
            }
            if ((event.key === Qt.Key_Minus || event.key === Qt.Key_BracketLeft) && !event.isAutoRepeat) {
                event.accepted = true;
                changeGridSize(1);
                return;
            }
            if ((event.key === Qt.Key_Plus || event.key === Qt.Key_Equal || event.key === Qt.Key_BracketRight) && !event.isAutoRepeat) {
                event.accepted = true;
                changeGridSize(-1);
                return;
            }
            if ((event.key === Qt.Key_M || event.key === Qt.Key_Menu) && !event.isAutoRepeat) {
                event.accepted = true;
                var editItem = gameGrid.currentItem;
                var editTarget = (editItem && editItem.gameModel) ? editItem.gameModel : currentGame;
                if (gridActive && gameGrid.count > 0 && editTarget) openGameEdit(editTarget);
                return;
            }
            if (api.keys.isFilters(event)) {
                event.accepted = true;
                var detItem = gameGrid.currentItem;
                var detTarget = (detItem && detItem.gameModel) ? detItem.gameModel : currentGame;
                if (gridActive && gameGrid.count > 0 && detItem && detTarget) {
                    currentGame = detTarget;
                    openGameDetail(detItem, detTarget);
                }
                return;
            }
            if (api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace) {
                event.accepted = true;
                if (softwareSearch !== "") {
                    backSfx.play();
                    applySearch("");
                } else {
                    showHomeScreen();
                }
                return;
            }
            if (api.keys.isNextPage(event)) {
                event.accepted = true;
                cycleCollection(1);
                return;
            }
            if (api.keys.isPrevPage(event)) {
                event.accepted = true;
                cycleCollection(-1);
                return;
            }
        }

        Item {
            id: topBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: parent.right
            height: Math.round(screenheight * 0.1222)
            z: 5

            Image {
                id: headerIcon
                width: Math.round(screenheight * 0.0611)
                height: width
                source: "../assets/images/allsoft_icon.svg"
                sourceSize.width: vpx(128)
                sourceSize.height: vpx(128)

                anchors {
                    top: parent.top
                    topMargin: Math.round(screenheight * 0.0416)
                    left: parent.left
                    leftMargin: vpx(38)
                }

                Text {
                    id: collectionTitle
                    text: tr("All Software")
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.0277)
                    font.bold: true
                    anchors {
                        verticalCenter: headerIcon.verticalCenter
                        left: parent.right
                        leftMargin: vpx(12)
                    }
                }
            }

            ColorOverlay {
                anchors.fill: headerIcon
                source: headerIcon
                color: theme.text
                cached: true
            }

            MouseArea {
                x: headerIcon.x
                y: headerIcon.y
                width: headerIcon.width + collectionTitle.width + vpx(12)
                height: headerIcon.height
                onClicked: showHomeScreen()
            }

            Rectangle {
                id: sortButton
                height: Math.round(screenheight * 0.0611)
                width: sortTypeTxt.contentWidth + sortArrow.width + vpx(66)
                radius: height / 2
                color: theme.button
                border.width: softwareScreenContainer.barIndex === 2 ? vpx(3) : 0
                border.color: theme.accent
                scale: sortMouse.pressed ? 0.95 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }

                anchors {
                    top: parent.top
                    topMargin: Math.round(screenheight * 0.0416)
                    right: parent.right
                    rightMargin: vpx(23)
                }

                Text {
                    id: sortTypeTxt
                    text: sortTitle
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.02)
                    anchors {
                        left: parent.left
                        leftMargin: vpx(24)
                        verticalCenter: parent.verticalCenter
                    }
                }

                Image {
                    id: sortArrow
                    width: Math.round(screenheight * 0.02)
                    height: width
                    source: "../assets/images/navigation/sort_arrow.png"
                    sourceSize.width: 64
                    sourceSize.height: 64
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: sortTypeTxt.right
                        leftMargin: vpx(10)
                    }
                }

                ColorOverlay {
                    anchors.fill: sortArrow
                    source: sortArrow
                    color: theme.text
                    cached: true
                }

                MouseArea {
                    id: sortMouse
                    anchors.fill: parent
                    onClicked: {
                        softwareScreenContainer.focusGrid();
                        cycleSort();
                    }
                }

            }

            Rectangle {
                id: sizeZoomRow
                height: Math.round(screenheight * 0.0611)
                width: vpx(98)
                radius: height / 2
                color: theme.button
                anchors {
                    top: parent.top
                    topMargin: Math.round(screenheight * 0.0416)
                    right: backButton.left
                    rightMargin: vpx(12)
                }
                Row {
                    anchors.centerIn: parent
                    spacing: vpx(10)
                    Rectangle {
                        width: vpx(32); height: vpx(32); radius: width / 2; color: theme.main
                        Text { anchors.centerIn: parent; text: "-"; color: theme.text; font.family: titleFont.name; font.pixelSize: vpx(18); font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: changeGridSize(1) }
                    }
                    Rectangle {
                        width: vpx(32); height: vpx(32); radius: width / 2; color: theme.main
                        Text { anchors.centerIn: parent; text: "+"; color: theme.text; font.family: titleFont.name; font.pixelSize: vpx(18); font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: changeGridSize(-1) }
                    }
                }
            }

            Rectangle {
                id: backButton
                width: Math.round(screenheight * 0.0611)
                height: width
                radius: width / 2
                color: theme.button
                border.width: softwareScreenContainer.barIndex === 0 ? vpx(3) : 0
                border.color: theme.accent
                scale: backMouse.pressed ? 0.95 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }

                anchors {
                    top: parent.top
                    topMargin: Math.round(screenheight * 0.0416)
                    right: searchButton.left
                    rightMargin: vpx(12)
                }

                Image {
                    anchors.centerIn: parent
                    width: vpx(22)
                    height: width
                    fillMode: Image.PreserveAspectFit
                    source: "../assets/images/navigation/back.svg"
                    sourceSize.width: 64
                    sourceSize.height: 64
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: theme.text
                    }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    onClicked: {
                        softwareScreenContainer.focusGrid();
                        showHomeScreen();
                    }
                }

            }

            Rectangle {
                id: searchButton
                height: Math.round(screenheight * 0.0611)
                width: searchRow.width + vpx(44)
                radius: height / 2
                color: theme.button
                border.width: (softwareScreenContainer.barIndex === 1 || softwareScreenContainer.searchEditing) ? vpx(3) : 0
                border.color: theme.accent
                scale: searchMouse.pressed ? 0.95 : 1

                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }

                anchors {
                    top: parent.top
                    topMargin: Math.round(screenheight * 0.0416)
                    right: sortButton.left
                    rightMargin: vpx(12)
                }

                Row {
                    id: searchRow
                    anchors.centerIn: parent
                    spacing: vpx(10)

                    Item {
                        id: magnifier
                        width: vpx(20)
                        height: vpx(20)
                        anchors.verticalCenter: parent.verticalCenter
                        property color iconColor: softwareSearch !== "" ? theme.accent : theme.text

                        Rectangle {
                            width: vpx(13)
                            height: vpx(13)
                            radius: width / 2
                            color: "transparent"
                            border.width: vpx(2)
                            border.color: magnifier.iconColor
                        }
                        Rectangle {
                            x: vpx(11)
                            y: vpx(10)
                            width: vpx(8)
                            height: vpx(2.5)
                            radius: height / 2
                            color: magnifier.iconColor
                            rotation: 45
                            transformOrigin: Item.Left
                        }
                    }

                    Text {
                        id: searchLabel
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, Math.round(screenwidth * 0.28))
                        elide: softwareScreenContainer.searchEditing ? Text.ElideLeft : Text.ElideRight
                        text: softwareSearch !== "" ? softwareSearch : (softwareScreenContainer.searchEditing ? "" : tr("Search"))
                        color: softwareSearch !== "" ? theme.accent : theme.text
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.02)
                    }

                    Rectangle {
                        width: vpx(2)
                        height: vpx(22)
                        color: theme.accent
                        visible: softwareScreenContainer.searchEditing
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity {
                            running: softwareScreenContainer.searchEditing
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 0
                                duration: 500
                            }
                            NumberAnimation {
                                to: 1
                                duration: 500
                            }
                        }
                    }
                }

                MouseArea {
                    id: searchMouse
                    anchors.fill: parent
                    onClicked: {
                        softwareScreenContainer.tabsFocused = false;
                        softwareScreenContainer.barIndex = 1;
                        softwareScreenContainer.startSearch();
                    }
                }
            }
        }

        Item {
            id: tabBar
            property real pillH: Math.round(screenheight * 0.05)

            anchors {
                top: topBar.bottom
                left: parent.left
                right: parent.right
                leftMargin: vpx(38)
                rightMargin: vpx(38)
            }
            height: Math.round(screenheight * 0.075)
            z: 5

            Rectangle {
                id: prevHint
                width: Math.round(tabBar.pillH * 1.2)
                height: tabBar.pillH
                radius: height / 2
                color: theme.button
                scale: prevMouse.pressed ? 0.92 : 1
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.centerIn: parent
                    text: "L"
                    color: theme.icon
                    font.family: titleFont.name
                    font.bold: true
                    font.pixelSize: Math.round(screenheight * 0.022)
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    onClicked: softwareScreenContainer.cycleCollection(-1)
                }
            }

            Rectangle {
                id: nextHint
                width: Math.round(tabBar.pillH * 1.2)
                height: tabBar.pillH
                radius: height / 2
                color: theme.button
                scale: nextMouse.pressed ? 0.92 : 1
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.centerIn: parent
                    text: "R"
                    color: theme.icon
                    font.family: titleFont.name
                    font.bold: true
                    font.pixelSize: Math.round(screenheight * 0.022)
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    onClicked: softwareScreenContainer.cycleCollection(1)
                }
            }

            ListView {
                id: tabList
                anchors {
                    left: prevHint.right
                    right: nextHint.left
                    leftMargin: vpx(12)
                    rightMargin: vpx(12)
                    verticalCenter: parent.verticalCenter
                }
                height: tabBar.pillH
                orientation: ListView.Horizontal
                spacing: vpx(10)
                clip: true
                interactive: false
                model: api.collections.count + 1
                currentIndex: currentCollection + 1
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: width * 0.25
                preferredHighlightEnd: width * 0.75
                highlightMoveDuration: 200

                delegate: Rectangle {
                    property bool active: index === tabList.currentIndex
                    property bool focusedTab: softwareScreenContainer.tabsFocused && index === softwareScreenContainer.tabIndex
                    height: tabBar.pillH
                    width: tabLabel.implicitWidth + vpx(40)
                    radius: height / 2
                    color: active ? theme.accent : theme.button
                    border.width: focusedTab ? vpx(3) : 0
                    border.color: active ? theme.text : theme.accent

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: index === 0 ? tr("All") : api.collections.get(index - 1).name
                        color: parent.active ? "white" : theme.icon
                        font.family: titleFont.name
                        font.bold: true
                        font.pixelSize: Math.round(screenheight * 0.02)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            softwareScreenContainer.focusGrid();
                            if (!parent.active) {
                                navSound.play();
                                softwareScreenContainer.setCollection(index - 1);
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                right: parent.right
            }
            color: theme.main
            height: topBar.height + tabBar.height
            z: 4
        }

        Text {
            anchors.centerIn: parent
            visible: gameGrid.count === 0
            text: softwareSearch !== "" ? tr("No results for \"%1\"", softwareSearch) : tr("No software")
            color: theme.icon
            font.family: titleFont.name
            font.pixelSize: Math.round(screenheight * 0.026)
            font.bold: true
        }

        GridView {
            id: gameGrid
            focus: true

            Keys.onBackPressed: {
                event.accepted = true;
                backSfx.play();
                softwareScreenContainer.tabsFocused = false;
                softwareScreenContainer.barIndex = -1;
                showHomeScreen();
            }
            Keys.onEscapePressed: {
                event.accepted = true;
                backSfx.play();
                if (softwareScreenContainer.tabsFocused) { softwareScreenContainer.tabsFocused = false; }
                else if (softwareScreenContainer.barIndex >= 0) { softwareScreenContainer.barIndex = -1; }
                else if (softwareSearch !== "") { softwareScreenContainer.applySearch(""); }
                else showHomeScreen();
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
                if (softwareScreenContainer.tabsFocused) {
                    if (event.isAutoRepeat)
                        return;
                    if (api.keys.isAccept(event)) {
                        event.accepted = true;
                        selectSfx.play();
                        softwareScreenContainer.setCollection(softwareScreenContainer.tabIndex - 1);
                    } else if (api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace) {
                        event.accepted = true;
                        backSfx.play();
                        softwareScreenContainer.tabsFocused = false;
                    } else if (api.keys.isDetails(event) || api.keys.isFilters(event) || api.keys.isPageDown(event)) {
                        event.accepted = true;
                    }
                    return;
                }

                if (softwareScreenContainer.barIndex >= 0) {
                    if (event.isAutoRepeat)
                        return;
                    if (api.keys.isAccept(event)) {
                        event.accepted = true;
                        softwareScreenContainer.activateBar();
                    } else if (api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace) {
                        event.accepted = true;
                        backSfx.play();
                        softwareScreenContainer.barIndex = -1;
                    } else if (api.keys.isDetails(event)) {
                        event.accepted = true;
                        if (softwareScreenContainer.barIndex === 1 && softwareSearch !== "") {
                            turnOffSfx.play();
                            softwareScreenContainer.applySearch("");
                        }
                    } else if (api.keys.isFilters(event)) {
                        event.accepted = true;
                    }
                    return;
                }

                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    if (count > 0) {
                        var curG = (gameGrid.currentItem && gameGrid.currentItem.gameModel) ? gameGrid.currentItem.gameModel : currentGame;
                        if (curG) currentGame = curG;
                        playSoftware();
                    }
                    return;
                }

                if (api.keys.isPageDown(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    var hideG = (gameGrid.currentItem && gameGrid.currentItem.gameModel) ? gameGrid.currentItem.gameModel : currentGame;
                    if (count > 0 && hideG)
                        requestHideApp(hideG.title);
                    return;
                }
            }
            Keys.onUpPressed: {
                if (softwareScreenContainer.barIndex >= 0)
                    return;
                if (softwareScreenContainer.tabsFocused) {
                    borderSfx.play();
                    softwareScreenContainer.tabsFocused = false;
                    softwareScreenContainer.barIndex = 1;
                } else if (currentIndex < numcolumns) {
                    borderSfx.play();
                    softwareScreenContainer.tabIndex = currentCollection + 1;
                    softwareScreenContainer.tabsFocused = true;
                } else {
                    navSound.play();
                    moveCurrentIndexUp();
                }
            }
            Keys.onDownPressed: {
                navSound.play();
                if (softwareScreenContainer.barIndex >= 0) {
                    softwareScreenContainer.barIndex = -1;
                    softwareScreenContainer.tabIndex = currentCollection + 1;
                    softwareScreenContainer.tabsFocused = true;
                } else if (softwareScreenContainer.tabsFocused) {
                    softwareScreenContainer.tabsFocused = false;
                } else {
                    moveCurrentIndexDown();
                }
            }
            Keys.onLeftPressed: {
                if (softwareScreenContainer.barIndex >= 0) {
                    if (softwareScreenContainer.barIndex > 0) {
                        navSound.play();
                        softwareScreenContainer.barIndex--;
                    }
                    return;
                }
                if (softwareScreenContainer.tabsFocused) {
                    if (softwareScreenContainer.tabIndex > 0) {
                        navSound.play();
                        softwareScreenContainer.tabIndex--;
                    }
                    return;
                }
                navSound.play();
                moveCurrentIndexLeft();
            }
            Keys.onRightPressed: {
                if (softwareScreenContainer.barIndex >= 0) {
                    if (softwareScreenContainer.barIndex < 2) {
                        navSound.play();
                        softwareScreenContainer.barIndex++;
                    }
                    return;
                }
                if (softwareScreenContainer.tabsFocused) {
                    if (softwareScreenContainer.tabIndex < api.collections.count) {
                        navSound.play();
                        softwareScreenContainer.tabIndex++;
                    }
                    return;
                }
                navSound.play();
                moveCurrentIndexRight();
            }

            onCurrentIndexChanged: {
                currentGameIndex = currentIndex;
            }

            anchors {
                left: parent.left
                leftMargin: vpx(63)
                top: tabBar.bottom
                right: parent.right
                rightMargin: vpx(63)
                bottom: parent.bottom
            }
            topMargin: Math.round(screenheight * 0.08)
            bottomMargin: Math.round(screenheight * 0.12)

            cellWidth: width / numcolumns
            cellHeight: cellWidth
            preferredHighlightBegin: Math.round(screenheight * 0.1388)
            preferredHighlightEnd: Math.round(screenheight * 0.6527)
            highlightRangeMode: ListView.ApplyRange
            snapMode: ListView.NoSnap
            highlightMoveDuration: 100

            model: searchProxy
            delegate: gameGridDelegate

            Component {
                id: gameGridDelegate

                Item {
                    id: delegateContainer
                    property var gameModel: modelData
                    property bool selected: delegateContainer.GridView.isCurrentItem && softwareScreenContainer.gridActive
                    property var gameBG: (gameOverrideVersion >= 0 && modelData) ? getGameCover(modelData) : ""

                    function updateData() {
                        currentGame = modelData;
                    }

                    onSelectedChanged: {
                        if (selected)
                            updateData();
                    }
                    Component.onCompleted: {
                        if (selected)
                            updateData();
                    }

                    width: gameGrid.cellWidth
                    height: gameGrid.cellHeight
                    z: selected ? 10 : 0

                    Item {
                        id: tile
                        width: gameGrid.cellWidth - vpx(14)
                        height: width
                        anchors.centerIn: parent
                        scale: delegateContainer.selected ? 1.08 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }

                        HighlightBorder {
                            width: tile.width + vpx(18)
                            height: width
                            anchors.centerIn: tile
                            z: -1
                            borderRadius: vpx(30)
                            selected: delegateContainer.selected
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: vpx(24)
                            color: theme.button
                        }

                        Rectangle {
                            id: tileMask
                            anchors.fill: parent
                            radius: vpx(24)
                            visible: false
                        }

                        Image {
                            id: gameImage
                            anchors.fill: parent
                            asynchronous: true
                            smooth: true
                            source: delegateContainer.gameBG
                            sourceSize {
                                width: 256
                                height: 256
                            }
                            fillMode: (delegateContainer.gameBG == modelData.assets.boxFront) ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: tileMask
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: vpx(24)
                            color: "white"
                            opacity: 0.15
                            visible: logo.source != "" && gameImage.source != ""
                        }

                        Image {
                            id: logo
                            anchors {
                                fill: parent
                                margins: vpx(12)
                            }
                            asynchronous: true

                            property var logoImage: {
                                if (modelData != null) {
                                    if (modelData.collections.get(0).shortName === "retropie")
                                        return "";
                                    else if (modelData.collections.get(0).shortName === "steam")
                                        return Utils.logo(modelData) ? Utils.logo(modelData) : "";
                                    else if (modelData.assets.tile != "")
                                        return "";
                                    else
                                        return modelData.assets.logo;
                                } else {
                                    return "";
                                }
                            }

                            source: modelData ? logoImage || "" : ""
                            sourceSize {
                                width: 256
                                height: 256
                            }
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: modelData.assets.logo && delegateContainer.gameBG != modelData.assets.boxFront ? true : false
                        }

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - vpx(24)
                            text: (gameOverrideVersion >= 0 && modelData) ? getGameTitle(modelData) : ""
                            font.family: titleFont.name
                            color: theme.text
                            font.pixelSize: Math.round(screenheight * 0.0194)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            visible: logo.source == "" && gameImage.source == ""
                        }

                        Rectangle {
                            anchors {
                                right: parent.right
                                rightMargin: vpx(8)
                                top: parent.top
                                topMargin: vpx(8)
                            }
                            width: vpx(32)
                            height: width
                            radius: width / 2
                            color: theme.accent
                            visible: modelData.favorite

                            Image {
                                id: faviconImage
                                source: "../assets/images/heart_filled.png"
                                asynchronous: true
                                anchors.fill: parent
                                anchors.margins: vpx(7)
                            }

                            ColorOverlay {
                                anchors.fill: faviconImage
                                source: faviconImage
                                color: "white"
                                antialiasing: true
                                smooth: true
                                cached: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                softwareScreenContainer.focusGrid();
                                gameGrid.currentIndex = index;
                                currentGameIndex = index;
                                currentGame = modelData;
                                playSoftware();
                            }
                            onPressAndHold: {
                                softwareScreenContainer.focusGrid();
                                gameGrid.currentIndex = index;
                                currentGameIndex = index;
                                if (modelData) {
                                    currentGame = modelData;
                                    openGameEdit(modelData);
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: titleBubble
                        property string platformShort: (modelData && modelData.collections && modelData.collections.count > 0) ? Utils.processPlatformName(modelData.collections.get(0).shortName) : ""
                        property bool hasPlatform: platformIcon.status === Image.Ready
                        height: Math.round(screenheight * 0.0611)
                        width: Math.min(gameTitle.implicitWidth + (hasPlatform ? platformIcon.width + vpx(10) : 0) + vpx(44), delegateContainer.width * 2)
                        radius: height / 2
                        color: theme.button
                        opacity: delegateContainer.selected ? 0.97 : 0
                        visible: opacity > 0

                        anchors {
                            horizontalCenter: tile.horizontalCenter
                            bottom: tile.top
                            bottomMargin: vpx(18)
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 100
                            }
                        }

                        layer.enabled: enableDropShadows
                        layer.effect: DropShadow {
                            transparentBorder: true
                            horizontalOffset: 0
                            verticalOffset: vpx(3)
                            radius: 10
                            samples: 20
                            color: "#40000000"
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: vpx(10)

                            Image {
                                id: platformIcon
                                width: vpx(26)
                                height: width
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: 64
                                sourceSize.height: 64
                                source: (delegateContainer.selected && titleBubble.platformShort !== "") ? "../assets/images/platforms/" + titleBubble.platformShort + ".svg" : ""
                                visible: titleBubble.hasPlatform
                                layer.enabled: true
                                layer.effect: ColorOverlay {
                                    color: theme.accent
                                }
                            }

                            Text {
                                id: gameTitle
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, titleBubble.width - vpx(44) - (titleBubble.hasPlatform ? platformIcon.width + vpx(10) : 0))
                                elide: Text.ElideRight
                                text: sortByIndex == 3 ? modelData.publisher + " / " + modelData.title : modelData.title
                                color: theme.accent
                                font.pixelSize: Math.round(screenheight * 0.0222)
                                font.bold: true
                                font.family: titleFont.name
                            }
                        }
                    }
                }
            }
        }
    }
}

