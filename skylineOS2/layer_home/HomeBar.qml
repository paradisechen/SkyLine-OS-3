import QtQuick 2.12
import QtGraphicalEffects 1.0
import QtMultimedia 5.9
import "../global"
import "../Lists"
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

ListView {
    id: homeLayout
    //anchors.fill: parent
    property bool anyExpanded: false
    property int _index: 0
    property int borderGapPx: vpx(settings.borderGap720 || 7)
    property int borderStrokePx: vpx(settings.borderThick720 || 6)
    property real spacingRatio: settings.cardSpacingRatio || 0.140
    spacing: Math.max((borderGapPx + borderStrokePx) * 2 + vpx(6), Math.round(homeLayout.height * cardScale * spacingRatio))
    orientation: ListView.Horizontal

    displayMarginBeginning: vpx(107)
    displayMarginEnd: vpx(107)

    preferredHighlightBegin: vpx(0)
    preferredHighlightEnd: preferredHighlightBegin + homeLayout.height * homeLayout.cardScale
    highlightRangeMode: ListView.StrictlyEnforceRange
    snapMode: ListView.SnapToItem
    highlightMoveDuration: 100
    highlightMoveVelocity: -1
    keyNavigationWraps: true
    property real cardScale: parseFloat(settings.homeCardSize) / 35.0

    signal userInteracted
    signal downPressed()

    NumberAnimation {
        id: anim
        property: "scale"
        to: 0.7
        duration: 100
    }

    model: gamesListModel
    onCountChanged: {
        if (count > 0 && currentIndex < 0 && homeScreen && homeScreen.focus) {
            var keep = (homeScreen.lastHomeSwitcherIndex >= 0 && homeScreen.lastHomeSwitcherIndex < count) ? homeScreen.lastHomeSwitcherIndex : 0;
            currentIndex = keep;
        }
    }
    onCurrentItemChanged: {
        if (currentItem && currentItem.isGame && currentItem.gameData) {
            currentGame = currentItem.gameData;
            currentScreenID = currentIndex;
        }
    }
    delegate: homeBarDelegate

    boundsBehavior: Flickable.StopAtBounds
    boundsMovement: Flickable.StopAtBounds

    Component {
        id: homeBarDelegate
        Rectangle {
            id: wrapper

            property bool selected: ListView.isCurrentItem
            property var gameData: searchtext ? modelData : listRecent.currentGame(idx)
            property bool isGame: idx >= 0
            property bool expanded: false

            property real savedX: 0
            property real savedY: 0

            onExpandedChanged: {
                homeLayout.anyExpanded = expanded;
                if (expanded) {
                    var pos = wrapper.mapToItem(homeScreenContainer, 0, 0);
                    savedX = pos.x;
                    savedY = pos.y;
                }
            }

            onGameDataChanged: {
                if (selected)
                    updateData();
            }
            onSelectedChanged: {
                if (!selected)
                    expanded = false;
                if (selected)
                    updateData();
            }

            function updateData() {
                currentGame = gameData;
                currentScreenID = idx;
            }

            width: homeLayout.height * homeLayout.cardScale
            height: width
            color: "transparent"

            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            scale: expanded ? 0 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: background

                width: isGame ? homeLayout.height : homeLayout.height * 0.7
                height: width

                radius: vpx(24)
                color: theme.button

                anchors.centerIn: parent
            }

            property var cardBG: {
                if (!gameData || !isGame)
                    return "";
                switch (settings.gameBackground) {
                case "Screenshot":
                    return gameData.assets.screenshots[0] || gameData.assets.background || "";
                case "Fanart":
                    return gameData.assets.background || gameData.assets.screenshots[0] || "";
                case "Boxart":
                    return gameData.assets.background || gameData.assets.screenshots[0] || "";
                default:
                    return "";
                }
            }

            property var gameBG: (gameOverrideVersion >= 0 && gameData && isGame) ? getGameCover(gameData) : ""

            Rectangle {
                id: imageMask
                width: isGame ? homeLayout.height : homeLayout.height * 0.7
                height: width
                radius: vpx(24)
                visible: false
                anchors.centerIn: parent
            }

            AnimatedImage {
                id: gameImage
                playing: true

                width: isGame ? homeLayout.height : homeLayout.height * 0.7
                height: width

                smooth: true
                asynchronous: true

                fillMode: Image.PreserveAspectFit

                source: gameBG

                /* sourceSize {
                    width: 512
                    height: 512
                } */

                anchors.centerIn: parent

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: imageMask
                }

                Rectangle {
                    id: favicon
                    anchors {
                        right: parent.right
                        rightMargin: vpx(5)
                        top: parent.top
                        topMargin: vpx(5)
                    }

                    width: vpx(32)
                    height: width
                    radius: width / 2
                    color: theme.accent
                    visible: isGame ? gameData.favorite : false

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
            }

            //white overlay on screenshot for better logo visibility over screenshot
            Rectangle {
                width: gameImage.width
                height: gameImage.height
                color: "white"
                opacity: 0.15
                visible: logo.source != "" && gameImage.source != ""
            }

            Image {
                id: logo

                anchors.fill: gameImage
                anchors.centerIn: gameImage
                anchors.margins: isGame ? vpx(30) : vpx(60)
                property var logoImage: {
                    if (gameData != null) {
                        if (gameData.collections.get(0).shortName === "retropie")
                            return "";
                        else
                        //gameData.assets.boxFront;
                        if (gameData.collections.get(0).shortName === "steam")
                            return Utils.logo(gameData) ? Utils.logo(gameData) : "";
                        else
                        //root.logo(gameData);
                        if (gameData.assets.tile != "")
                            return "";
                        else if (gameBG == gameData.assets.boxFront)
                            return "";
                        else
                            return gameData.assets.logo;
                    } else {
                        return "";
                    }
                }

                source: gameData ? logoImage : icon //Utils.logo(gameData)
                sourceSize: Qt.size(gameImage.width, gameImage.height)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                visible: !gameData ? true : !!(gameData.assets.logo && gameBG != gameData.assets.boxFront)
            }

            ColorOverlay {
                anchors.fill: logo
                source: logo
                color: theme.icon
                antialiasing: true
                cached: true
                visible: !isGame
            }

            Text {
                text: (gameOverrideVersion >= 0 && idx > -1 && gameData) ? getGameTitle(gameData) : name
                width: gameImage.width
                horizontalAlignment: Text.AlignHCenter
                font.family: titleFont.name
                color: theme.text
                font.pixelSize: Math.round(screenheight * 0.025)
                font.bold: true

                anchors.centerIn: gameImage
                wrapMode: Text.Wrap
                visible: logo.source == "" && gameImage.source == ""
                z: 10
            }

            MouseArea {
                anchors.fill: gameImage
                hoverEnabled: true
                onEntered: {}
                onExited: {}
                onClicked: {
                    if (selected) {
                        if (currentIndex === gamesListModel.count - 1 || (homeLayout.currentItem && !homeLayout.currentItem.isGame)) {
                            gotoSoftware();
                        } else {
                            anim.start();
                            playGame();//launchGame(currentGame);
                        }
                    } else
                        navSound.play();
                    homeSwitcher.currentIndex = index;
                    homeSwitcher.focus = true;
                    buttonMenu.focus = false;
                }

                onPressAndHold: {
                    homeSwitcher.currentIndex = index;
                    homeSwitcher.focus = true;
                    buttonMenu.focus = false;
                    if (wrapper.isGame && wrapper.gameData) {
                        openGameEdit(wrapper.gameData);
                    }
                }
            }

            Text {
                id: topTitle
                text: (gameOverrideVersion >= 0 && idx > -1 && gameData) ? getGameTitle(gameData) : name
                color: theme.accent
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.035 * fontScale)
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                //clip: true
                //elide: Text.ElideRight

                anchors {
                    horizontalCenter: gameImage.horizontalCenter
                    bottom: highlightBorder.top
                    bottomMargin: Math.round(screenheight * 0.018)
                }

                opacity: wrapper.ListView.isCurrentItem ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 75
                    }
                }
            }

            Component.onCompleted: {
                if (wordWrap) {
                    if (topTitle.paintedWidth > gameImage.width * 1.70) {
                        topTitle.width = gameImage.width * 1.5;
                    }
                }
            }

            HighlightBorder {
                id: highlightBorder
                width: gameImage.width + (homeLayout.borderGapPx + homeLayout.borderStrokePx) * 2
                height: width
                anchors.centerIn: gameImage
                z: 20

                coverRadius: vpx(24)
                borderGap: homeLayout.borderGapPx
                borderwidth: homeLayout.borderStrokePx
                borderRadius: vpx(24) + homeLayout.borderGapPx + homeLayout.borderStrokePx
                selected: wrapper.ListView.isCurrentItem
            }
        }
    }

    Keys.onLeftPressed: {
        if (currentIndex < 0 && count > 0) currentIndex = 0;
        navSound.play();
        decrementCurrentIndex();
        userInteracted();
    }
    Keys.onRightPressed: {
        if (currentIndex < 0 && count > 0) currentIndex = 0;
        navSound.play();
        incrementCurrentIndex();
        userInteracted();
    }

    Keys.onUpPressed: {
        borderSfx.play();
        profileButton.focus = true;
        homeSwitcher.currentIndex = -1;
    }

    Keys.onDownPressed: {
    _index = currentIndex;
    navSound.play();
    downPressed();
}

    function gotoSoftware() {
        showSoftwareScreen();
    }

    Keys.onReleased: {
        if (homeScreen && typeof homeScreen.checkSleepCombo === "function")
            homeScreen.checkSleepCombo(event.key, false, event.isAutoRepeat);
    }

    Keys.onPressed: {
        if (homeScreen && typeof homeScreen.checkSleepCombo === "function" && homeScreen.checkSleepCombo(event.key, true, event.isAutoRepeat)) {
            event.accepted = true;
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (currentIndex === gamesListModel.count - 1 || (homeLayout.currentItem && !homeLayout.currentItem.isGame)) {
                gotoSoftware();
            } else {
                var runItem = homeLayout.currentItem;
                if (runItem && runItem.isGame && runItem.gameData)
                    currentGame = runItem.gameData;
                anim.start();
                playGame();
            }
            return;
        }

        if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var hideItem = homeLayout.currentItem;
            var hideTarget = (hideItem && hideItem.isGame && hideItem.gameData) ? hideItem.gameData : null;
            if (hideTarget && currentIndex < gamesListModel.count - 1)
                requestHideApp(hideTarget.title);
            return;
        }
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var favItem = homeLayout.currentItem;
            var favTarget = (favItem && favItem.isGame && favItem.gameData) ? favItem.gameData : null;
            if (favTarget) {
                currentGame = favTarget;
                if (favTarget.favorite) {
                    turnOffSfx.play();
                } else {
                    turnOnSfx.play();
                }
                favTarget.favorite = !favTarget.favorite;
            }
            return;
        }

        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var item = homeLayout.currentItem;
            if (item && item.isGame && item.gameData) {
                currentGame = item.gameData;
                openGameDetail(item, item.gameData);
            } else if (item && !item.isGame) {
                gotoSoftware();
            }
            return;
        }
        if ((event.key === Qt.Key_Plus || event.key === Qt.Key_Equal || event.key === Qt.Key_M || event.key === Qt.Key_Menu) && !event.isAutoRepeat) {
            event.accepted = true;
            var editItem = homeLayout.currentItem;
            var editTarget = (editItem && editItem.isGame && editItem.gameData) ? editItem.gameData : null;
            if (editTarget && currentIndex < gamesListModel.count - 1)
                openGameEdit(editTarget);
            return;
        }
    }
}
