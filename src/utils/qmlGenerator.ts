import type { SkylineConfig } from '../types/skyline';
import { DEFAULT_SKYLINE_CONFIG } from './rp5Layout';

export interface PatchedQmlFile {
  path: string;
  summary: string;
  content: string;
}

/**
 * Generates the patched skylineOS2 Pegasus Frontend QML files calibrated for
 * Retroid Pocket 5 (1920x1080, 16:9) with Switch 2 spacing, bold concentric
 * HighlightBorder, solid borderless enlarged bottom dock, UD Shin Go NT EL/M/H
 * font weights, User Select bottom-sheet overlay, and real-time artwork-adaptive colors.
 */
export function generatePatchedQmlFiles(config: SkylineConfig = DEFAULT_SKYLINE_CONFIG): PatchedQmlFile[] {
  const cardPct = config.cardSizePct;
  const borderGap720 = config.borderGapPx720;
  const borderThick720 = config.borderThicknessPx720;
  const dockHeightPct = (config.dockHeightPct / 100).toFixed(4);
  const helpBarPct = '0.0950';
  const spacingMult = config.cardSpacingRatio.toFixed(3);
  const buttonSize720 = Math.round(720 * (config.dockHeightPct / 100) * 0.72);
  const iconSize720 = Math.round(buttonSize720 * 0.5);
  const buttonGap720 = Math.max(18, Math.round(buttonSize720 * 0.34));
  const dockPad720 = Math.max(24, Math.round(720 * (config.dockHeightPct / 100) * 0.34));

  const highlightBorderQml = `// skylineOS 2 — Patched HighlightBorder.qml (UI Kit Iridescent + Artwork-Adaptive Concentric Ring)
import QtQuick 2.8
import QtGraphicalEffects 1.0

Item {
    id: hlBorder
    property bool selected: false
    property int borderGap: vpx(${borderGap720})
    property int borderwidth: idx && idx == -3 ? vpx(${borderThick720 + 1}) : vpx(${borderThick720})
    property int coverRadius: vpx(24)
    property int innerRadius: coverRadius + borderGap
    property int outerRadius: coverRadius + borderGap + borderwidth

    opacity: selected ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: outerRing
        anchors.fill: parent
        radius: outerRadius
        color: "transparent"
        border.width: borderwidth
        border.color: uiPalette ? uiPalette.borderPrimary : theme.accent

        Behavior on border.color { ColorAnimation { duration: 180 } }

        layer.enabled: enableDropShadows
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: vpx(4)
            color: "#55000000"
            radius: 10
            samples: 18
        }
    }
}
`;

  const homeBarQml = `// skylineOS 2 — Patched HomeBar.qml (Uniform Switch 2 Spacing & Unobstructed Border)
import QtQuick 2.12
import QtGraphicalEffects 1.0
import QtMultimedia 5.9
import "../global"
import "../Lists"
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

ListView {
    id: homeLayout
    property bool anyExpanded: false
    property int _index: 0

    property real cardBaseSize: homeLayout.height
    property int coverRadius: Math.max(vpx(16), Math.round(cardBaseSize * 0.095))
    property int borderGapPx: vpx(${borderGap720})
    property int borderStrokePx: vpx(${borderThick720})
    spacing: Math.max((borderGapPx + borderStrokePx) * 2 + vpx(6), Math.round(cardBaseSize * ${spacingMult}))

    orientation: ListView.Horizontal
    displayMarginBeginning: vpx(120)
    displayMarginEnd: vpx(120)
    preferredHighlightBegin: vpx(0)
    preferredHighlightEnd: preferredHighlightBegin + cardBaseSize
    highlightRangeMode: ListView.StrictlyEnforceRange
    snapMode: ListView.SnapToItem
    highlightMoveDuration: 120
    keyNavigationWraps: true

    signal userInteracted
    signal downPressed()

    model: gamesListModel
    delegate: homeBarDelegate
    boundsBehavior: Flickable.StopAtBounds

    Component {
        id: homeBarDelegate
        Item {
            id: wrapper
            property bool selected: ListView.isCurrentItem
            property var gameData: searchtext ? modelData : listRecent.currentGame(idx)
            property bool isGame: idx >= 0
            property int tileSize: isGame ? homeLayout.cardBaseSize : Math.round(homeLayout.cardBaseSize * 0.78)
            property int tileRadius: homeLayout.coverRadius

            onGameDataChanged: { if (selected) updateData(); }
            onSelectedChanged: { if (selected) updateData(); }

            function updateData() {
                currentGame = gameData;
                currentScreenID = idx;
                if (typeof requestArtworkPalette === "function") requestArtworkPalette(gameData);
            }

            width: homeLayout.cardBaseSize
            height: homeLayout.cardBaseSize
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            HighlightBorder {
                id: highlightBorder
                width: tileSize + (homeLayout.borderGapPx + homeLayout.borderStrokePx) * 2
                height: width
                anchors.centerIn: coverClip
                z: 20
                coverRadius: tileRadius
                borderGap: homeLayout.borderGapPx
                borderwidth: homeLayout.borderStrokePx
                selected: wrapper.ListView.isCurrentItem
            }

            Item {
                id: coverClip
                width: tileSize
                height: tileSize
                anchors.centerIn: parent
                z: 5

                Rectangle {
                    id: background
                    anchors.fill: parent
                    radius: tileRadius
                    color: uiPalette ? uiPalette.cardSurface : theme.button
                }

                Rectangle { id: imageMask; anchors.fill: parent; radius: tileRadius; visible: false }

                AnimatedImage {
                    id: gameImage
                    playing: true
                    anchors.fill: parent
                    smooth: true
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    source: gameData ? (gameData.assets.boxFront || gameData.assets.tile || "") : ""
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: imageMask }
                }
            }

            // Bold (UD Shin Go NT H) title above active game cover
            Text {
                id: topTitle
                text: idx > -1 && gameData ? gameData.title : name
                color: uiPalette ? uiPalette.gameTitleColor : theme.accent
                font.family: boldFont.name
                font.pixelSize: Math.round(screenheight * 0.036)
                font.weight: Font.ExtraBold
                horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: 180 } }
                anchors {
                    horizontalCenter: coverClip.horizontalCenter
                    bottom: highlightBorder.top
                    bottomMargin: Math.round(screenheight * 0.022)
                }
                opacity: wrapper.ListView.isCurrentItem ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 90 } }
            }
        }
    }
}
`;

  const menuButtonQml = `// skylineOS 2 — Patched MenuButton.qml (Solid Borderless Dock + UI Kit Icons)
import QtQuick 2.8
import QtGraphicalEffects 1.0
import "qrc:/qmlutils" as PegasusUtils

Item {
    id: root
    property bool selected: focus
    property string label: "No label"
    property string icon: "../assets/images/allsoft_icon.svg"
    property color kitColor: uiPalette ? uiPalette.dockIcon : theme.icon
    signal clicked

    width: vpx(${buttonSize720})
    height: vpx(${buttonSize720})

    Item {
        id: visual
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        scale: selected ? 1.08 : 1.0
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        Rectangle {
            id: baseCircle
            anchors.fill: parent
            radius: width / 2
            color: selected ? (uiPalette ? uiPalette.dockActiveCircle : theme.main) : "transparent"
            border.width: 0
            Behavior on color { ColorAnimation { duration: 160 } }
        }

        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: parent.width + vpx(12)
            height: width
            radius: width / 2
            color: "transparent"
            border.width: vpx(4.5)
            border.color: uiPalette ? uiPalette.borderPrimary : theme.accent
            opacity: selected ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Item {
            id: iconHolder
            anchors.centerIn: parent
            width: vpx(${iconSize720})
            height: vpx(${iconSize720})

            Image {
                id: menuIcon
                anchors.fill: parent
                source: icon
                sourceSize: Qt.size(width, height)
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: false
            }

            ColorOverlay {
                anchors.fill: menuIcon
                source: menuIcon
                color: root.kitColor
                antialiasing: true
                smooth: true
            }
        }
    }

    MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }

    Text {
        id: titleText
        text: label
        color: uiPalette ? uiPalette.dockLabel : theme.accent
        font.family: regularFont.name
        font.pixelSize: Math.round(screenheight * 0.025)
        font.weight: Font.Medium
        anchors { top: parent.bottom; topMargin: vpx(18); horizontalCenter: parent.horizontalCenter }
        opacity: selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }
}
`;

  const userSelectOverlayQml = `// skylineOS 2 — UserSelectOverlay.qml (Switch 2 Bottom-Sheet User Switcher + Fast Slide Animation)
import QtQuick 2.12
import QtGraphicalEffects 1.0

Item {
    id: userOverlay
    anchors.fill: parent
    property bool open: false
    property int selectedUserIndex: 0
    z: 120
    visible: open || slideAnim.running || backdrop.opacity > 0

    function show() { open = true; forceActiveFocus(); }
    function hide() { open = false; }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#66000000"
        opacity: userOverlay.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: userOverlay.hide() }
    }

    Rectangle {
        id: sheet
        width: parent.width
        height: Math.round(parent.height * 0.49)
        y: userOverlay.open ? parent.height - height : parent.height
        color: uiPalette ? uiPalette.overlaySheetBg : "#EDEDED"

        Behavior on y {
            NumberAnimation {
                id: slideAnim
                duration: 165
                easing.type: Easing.OutCubic
            }
        }

        // Header: "Select a user." in Thin (EL) weight + hairline divider
        Text {
            id: headerTitle
            text: tr("Select a user.")
            color: uiPalette ? uiPalette.overlayText : "#2C2C2C"
            font.family: thinFont.name
            font.weight: Font.Light
            font.pixelSize: Math.round(screenheight * 0.032)
            anchors { left: parent.left; leftMargin: vpx(44); top: parent.top; topMargin: vpx(20) }
        }

        Rectangle {
            id: topDivider
            height: 1
            color: uiPalette ? uiPalette.overlayDivider : "#BDBDBD"
            anchors { left: parent.left; right: parent.right; leftMargin: vpx(36); rightMargin: vpx(36); top: headerTitle.bottom; topMargin: vpx(16) }
        }

        // Centered User Cards + (+) Button
        Row {
            anchors.centerIn: parent
            spacing: vpx(28)

            Repeater {
                model: userProfilesModel
                delegate: Rectangle {
                    width: vpx(136)
                    height: vpx(168)
                    radius: vpx(4)
                    color: uiPalette ? uiPalette.overlayCardBg : "#FFFFFF"
                    border.width: userOverlay.selectedUserIndex === index ? vpx(4) : 0
                    border.color: uiPalette ? uiPalette.borderPrimary : "#10C8D8"

                    Image {
                        width: parent.width
                        height: parent.width
                        source: avatarSource
                        fillMode: Image.PreserveAspectCrop
                    }

                    Text {
                        text: userName
                        color: uiPalette ? uiPalette.overlayText : "#2C2C2C"
                        font.family: regularFont.name
                        font.weight: Font.Medium
                        font.pixelSize: vpx(18)
                        anchors { bottom: parent.bottom; bottomMargin: vpx(7); horizontalCenter: parent.horizontalCenter }
                    }
                }
            }

            // (+) Add New User Circle
            Rectangle {
                width: vpx(54); height: vpx(54)
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                border.width: vpx(2.5)
                border.color: uiPalette ? uiPalette.overlayMuted : "#666666"
                Text {
                    text: "+"
                    anchors.centerIn: parent
                    color: uiPalette ? uiPalette.overlayMuted : "#666666"
                    font.pixelSize: vpx(28)
                    font.weight: Font.Medium
                }
            }
        }

        Rectangle {
            id: bottomDivider
            height: 1
            color: uiPalette ? uiPalette.overlayDivider : "#BDBDBD"
            anchors { left: parent.left; right: parent.right; leftMargin: vpx(36); rightMargin: vpx(36); bottom: parent.bottom; bottomMargin: Math.round(screenheight * 0.085) }
        }
    }
}
`;

  const controllerHelpQml = `// skylineOS 2 — Patched ControllerHelp.qml (UD Shin Go NT Weights + Adaptive Colors)
import QtQuick 2.8
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0
import "../utils.js" as Utils

FocusScope {
    id: root
    property bool showBack: true
    property bool showFav: true
    property bool showDetails: false
    property string collectionShortName: (currentGame && currentGame.collections && currentGame.collections.count > 0)
        ? Utils.processPlatformName(currentGame.collections.get(0).shortName) : ""

    Item {
        id: background
        anchors.fill: parent

        Image {
            id: controllerIcon
            width: Math.round(screenheight * 0.044)
            height: width
            fillMode: Image.PreserveAspectFit
            source: collectionShortName !== "" ? "../assets/images/platforms/" + collectionShortName + ".svg" : ""
            visible: false
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: vpx(25) }
        }

        ColorOverlay {
            anchors.fill: controllerIcon
            source: controllerIcon
            color: uiPalette ? uiPalette.helpBarIcon : theme.text
            smooth: true
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }
}
`;

  const themePalettePatchQml = `// skylineOS 2 — Patched theme.qml & HomeScreen.qml Excerpt
// 1. Load Thin (EL), Regular (M), Bold (H) UD Shin Go NT fonts:
//    FontLoader { id: thinFont;    source: "assets/fonts/UDShinGoNT-EL.ttf" }
//    FontLoader { id: regularFont; source: "assets/fonts/UDShinGoNT-M.ttf" }
//    FontLoader { id: boldFont;    source: "assets/fonts/UDShinGoNT-H.ttf" }

// 2. Solid borderless bottom button bar in HomeScreen.qml:
    Rectangle {
        id: buttonBar
        anchors.centerIn: parent
        width: buttonMenu.width + vpx(${dockPad720 * 2})
        height: Math.round(screenheight * ${dockHeightPct})
        radius: height / 2
        color: uiPalette ? uiPalette.dockBg : theme.button
        border.width: 0 // Solid color without border
    }

// 3. Metrics calibrated for Retroid Pocket 5 (1920x1080, 16:9):
//    HomeBar height: Math.round(screenheight * ${(cardPct / 100).toFixed(2)})
//    helpbarheight: Math.round(screenheight * ${helpBarPct})
//    RowLayout spacing: vpx(${buttonGap720})
`;

  return [
    {
      path: 'global/HighlightBorder.qml',
      summary: 'Bolder concentric selection border with clear unobstructed inner gap',
      content: highlightBorderQml,
    },
    {
      path: 'layer_home/HomeBar.qml',
      summary: 'Uniform Switch 2 cover spacing, strict OpacityMask clipping, Bold title',
      content: homeBarQml,
    },
    {
      path: 'layer_home/MenuButton.qml',
      summary: 'Enlarged solid borderless dock buttons with UI Kit colored icons',
      content: menuButtonQml,
    },
    {
      path: 'layer_home/UserSelectOverlay.qml',
      summary: 'Bottom-sheet user switcher with (+) button and fast slide-up/down animation',
      content: userSelectOverlayQml,
    },
    {
      path: 'layer_help/ControllerHelp.qml',
      summary: 'Artwork-adaptive bottom controller hint text & platform glyph colors',
      content: controllerHelpQml,
    },
    {
      path: 'RP5_PATCH_GUIDE.qml',
      summary: 'UD Shin Go NT EL/M/H font loaders, solid dock Rectangle, and RP5 metrics',
      content: themePalettePatchQml,
    },
  ];
}
