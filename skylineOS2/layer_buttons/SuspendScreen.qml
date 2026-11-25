// skylineOS 2 — SuspendScreen.qml (Nintendo Switchboard Lock Screen)
import QtQuick 2.12
import QtGraphicalEffects 1.0
import "qrc:/qmlutils" as PegasusUtils
import "../utils.js" as Utils
import "../layer_home"

Item {
    id: suspendRoot
    width: parent.width
    height: parent.height

    property int pressCount: 0
    property int requiredPresses: 3
    property bool unlocking: false
    property string timeString: Qt.formatTime(new Date(), settings.timeFormat === "12hr" ? "h:mm AP" : "hh:mm")

    focus: true

    property var fallbackTopNews: [
        {
            title: "The Latest News, Right on Your Nintendo Switch System!",
            image: "https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/m/mario-kart-8-deluxe-switch/hero",
            accent: "#E60012"
        },
        {
            title: "Nintendo eShop: Games? DLC? Demos? Tell me more!",
            image: "https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-tears-of-the-kingdom-switch/hero",
            accent: "#EA580C"
        },
        {
            title: "Switch 2 GameShare, News & Online Ready When You Unlock",
            image: "https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_800/ncom/en_US/games/switch/s/super-mario-party-jamboree-switch/hero",
            accent: "#2563EB"
        }
    ]

    ListModel { id: topNewsModel }

    function resetLock() {
        pressCount = 0;
        unlocking = false;
        timeString = Qt.formatTime(new Date(), settings.timeFormat === "12hr" ? "h:mm AP" : "hh:mm");
        if (topNewsModel.count === 0) loadTopNews();
    }

    function decodeEntities(str) {
        if (!str) return "";
        return String(str)
            .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;|&apos;/g, "\x27")
            .replace(/&nbsp;/g, " ");
    }

    function applyFallbackNews() {
        topNewsModel.clear();
        for (var i = 0; i < fallbackTopNews.length; i++) {
            topNewsModel.append(fallbackTopNews[i]);
        }
    }

    function fetchTopNewsUrls(urls, idx) {
        if (idx >= urls.length) {
            if (topNewsModel.count === 0) applyFallbackNews();
            return;
        }
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status >= 200 && xhr.status < 400 && xhr.responseText) {
                var xml = xhr.responseText;
                var itemRe = /<(item|entry)\b[\s\S]*?<\/\1>/gi;
                var match;
                var parsed = [];
                while ((match = itemRe.exec(xml)) !== null && parsed.length < 3) {
                    var blk = match[0];
                    var tm = blk.match(/<title(?:\s[^>]*)?>([\s\S]*?)<\/title>/i);
                    var title = tm ? decodeEntities(tm[1]).replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim() : "";
                    if (!title) continue;
                    var im = blk.match(/<media:(?:content|thumbnail)[^>]+url=["']([^"']+)["']/i)
                          || blk.match(/<enclosure[^>]+url=["']([^"']+)["']/i)
                          || blk.match(/<img[^>]+src=["']([^"']+)["']/i);
                    var img = (im && im[1]) ? decodeEntities(im[1]).trim() : fallbackTopNews[parsed.length].image;
                    if (img.indexOf("http://") === 0) img = "https://" + img.slice(7);
                    parsed.push({
                        title: title,
                        image: img,
                        accent: fallbackTopNews[parsed.length].accent
                    });
                }
                if (parsed.length >= 2) {
                    while (parsed.length < 3) parsed.push(fallbackTopNews[parsed.length]);
                    topNewsModel.clear();
                    for (var j = 0; j < 3; j++) topNewsModel.append(parsed[j]);
                    return;
                }
            }
            fetchTopNewsUrls(urls, idx + 1);
        };
        xhr.open("GET", urls[idx]);
        xhr.setRequestHeader("Accept", "application/rss+xml, application/xml, text/xml");
        xhr.send();
    }

    function loadTopNews() {
        applyFallbackNews();
        fetchTopNewsUrls([
            "https://www.nintendolife.com/feeds/latest",
            "https://www.elnuevodia.com/arc/outboundfeeds/rss/?outputType=xml"
        ], 0);
    }

    function triggerAdvancePress() {
        if (unlocking) return;
        pressCount = Math.min(requiredPresses, pressCount + 1);
        pressFeedback.restart();
        if (pressCount >= requiredPresses) {
            unlocking = true;
            selectSfx.play();
            unlockTimer.restart();
        } else {
            navSound.play();
        }
    }

    Component.onCompleted: {
        applyFallbackNews();
    }

    onVisibleChanged: {
        if (visible) {
            resetLock();
        }
    }

    Timer {
        interval: 30000
        running: suspendRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: suspendRoot.timeString = Qt.formatTime(new Date(), settings.timeFormat === "12hr" ? "h:mm AP" : "hh:mm")
    }

    Timer {
        id: unlockTimer
        interval: 170
        repeat: false
        onTriggered: {
            suspendRoot.pressCount = 0;
            suspendRoot.unlocking = false;
            showHomeScreen();
        }
    }

    // LEFT DARK SIDEBAR: "- / +" + "Nintendo Switchboard" + 3 Top News Cards
    Rectangle {
        id: switchboardSidebar
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        width: Math.round(parent.width * 0.275)
        color: "#191A1E"

        // Top "- / +" + "Nintendo Switchboard" Header
        Item {
            id: sbHeader
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: Math.round(parent.height * 0.22)

            Column {
                anchors.centerIn: parent
                spacing: vpx(6)

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: vpx(10)

                    Rectangle {
                        width: vpx(26); height: vpx(7); radius: vpx(1)
                        color: "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "/"
                        color: "#52525B"
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.056)
                        font.weight: Font.Light
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item {
                        width: vpx(26); height: vpx(26)
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle { anchors.centerIn: parent; width: vpx(26); height: vpx(7); color: "#FFFFFF" }
                        Rectangle { anchors.centerIn: parent; width: vpx(7); height: vpx(26); color: "#FFFFFF" }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Nintendo Switchboard"
                    color: "#F3F4F6"
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.025)
                    font.weight: Font.Normal
                }
            }
        }

        // 3 Top News Cards
        Column {
            anchors {
                top: sbHeader.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                leftMargin: Math.round(switchboardSidebar.width * 0.13)
                rightMargin: Math.round(switchboardSidebar.width * 0.13)
                bottomMargin: Math.round(parent.height * 0.05)
            }
            spacing: Math.round(parent.height * 0.022)

            Repeater {
                model: topNewsModel
                delegate: Item {
                    width: parent.width
                    height: Math.floor((parent.height - Math.round(suspendRoot.height * 0.044)) / 3)

                    Rectangle {
                        anchors.fill: parent
                        radius: vpx(4)
                        color: "#2C2E36"
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: model.accent || "#E60012" }
                                GradientStop { position: 1.0; color: "#111827" }
                            }
                        }

                        Image {
                            anchors.fill: parent
                            source: model.image || ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: status === Image.Ready
                        }

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#10000000" }
                                GradientStop { position: 0.45; color: "#45000000" }
                                GradientStop { position: 1.0; color: "#DD000000" }
                            }
                        }

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                leftMargin: vpx(10)
                                rightMargin: vpx(10)
                                bottomMargin: vpx(8)
                            }
                            text: model.title
                            color: "#FFFFFF"
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.020)
                            font.bold: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            lineHeight: 1.15
                        }
                    }
                }
            }
        }
    }

    // RIGHT LIGHT LOCK PANEL (#EBEBEB)
    Rectangle {
        id: lockPanel
        anchors { top: parent.top; bottom: parent.bottom; left: switchboardSidebar.right; right: parent.right }
        color: "#EBEBEB"

        // Top-Right Flat Status Bar (matching Home Screen flat style, no bubble)
        Row {
            anchors {
                top: parent.top
                right: parent.right
                topMargin: Math.round(screenheight * 0.0472)
                rightMargin: vpx(44)
            }
            spacing: vpx(12)

            Text {
                text: suspendRoot.timeString
                color: "#1E1E1E"
                font.family: titleFont.name
                font.weight: Font.Normal
                font.pixelSize: Math.round(screenheight * 0.036 * fontScale)
                anchors.verticalCenter: parent.verticalCenter
            }

            Image {
                width: Math.round(screenheight * 0.036)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                source: "../assets/images/navigation/wifi.svg"
                sourceSize.width: 64
                sourceSize.height: 64
                visible: settings.showWifi === "Yes"
                layer.enabled: true
                layer.effect: ColorOverlay {
                    color: "#1E1E1E"
                    antialiasing: true
                }
            }

            Row {
                spacing: vpx(6)
                anchors.verticalCenter: parent.verticalCenter
                visible: !isNaN(api.device.batteryPercent)

                Text {
                    text: parseInt(api.device.batteryPercent * 100) + "%"
                    color: "#1E1E1E"
                    font.family: titleFont.name
                    font.weight: Font.Normal
                    font.pixelSize: Math.round(screenheight * 0.036 * fontScale)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: settings.batteryPercentSetting === "Yes"
                }

                BatteryIcon {
                    width: Math.round(screenheight * 0.0433)
                    height: width / 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    level: isNaN(api.device.batteryPercent) ? 100 : parseInt(api.device.batteryPercent * 100)
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: "#1E1E1E"
                        antialiasing: true
                    }
                }
            }
        }

        // Center HOME Menu Icon + "HOME Menu" + 3 Progressive Black Dots
        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -vpx(16)
            spacing: vpx(18)

            // Large Black Circular Outline HOME Button
            Rectangle {
                id: homeCircleBtn
                width: Math.round(screenheight * 0.195)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: Math.max(3, Math.round(screenheight * 0.0085))
                border.color: "#1E1E1E"
                anchors.horizontalCenter: parent.horizontalCenter

                // Crisp Vector HOME House Icon (SVG Image — reliable on Android Qt)
                Image {
                    id: homeGlyphIcon
                    anchors.centerIn: parent
                    width: Math.round(parent.width * 0.56)
                    height: width
                    source: "../assets/images/navigation/ns2_switchboard_home.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    sourceSize: Qt.size(128, 128)
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "HOME Menu"
                color: "#1E1E1E"
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.029)
                font.weight: Font.Normal
            }

            // 3 Black Dots appearing progressively below HOME logo as user presses A (1..3)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: vpx(16)
                height: vpx(18)

                Repeater {
                    model: suspendRoot.requiredPresses
                    delegate: Rectangle {
                        property bool lit: index < suspendRoot.pressCount
                        width: vpx(14)
                        height: vpx(14)
                        radius: width / 2
                        color: "#111111"
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: lit ? 1.0 : 0.0
                        scale: lit ? 1.0 : 0.35

                        Behavior on opacity { NumberAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack } }
                    }
                }
            }
        }

        // Bottom Center "(A) Start"
        Row {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: Math.round(screenheight * 0.095)
            }
            spacing: vpx(12)

            Rectangle {
                width: Math.round(screenheight * 0.052)
                height: width
                radius: width / 2
                color: "#1E1E1E"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "A"
                    color: "#FFFFFF"
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.028)
                    font.bold: true
                }
            }

            Text {
                text: tr("Start")
                color: "#1E1E1E"
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.044)
                font.weight: Font.Normal
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: suspendRoot.triggerAdvancePress()
        }
    }

    SequentialAnimation {
        id: pressFeedback
        NumberAnimation {
            target: homeCircleBtn
            property: "scale"
            to: 0.91
            duration: 70
        }
        NumberAnimation {
            target: homeCircleBtn
            property: "scale"
            to: 1.0
            duration: 140
            easing.type: Easing.OutBack
        }
    }

    Keys.onBackPressed: {
        event.accepted = true;
        suspendRoot.pressCount = 0;
        suspendRoot.unlocking = false;
        showHomeScreen();
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            event.accepted = true;
            return;
        }
        if (api.keys.isAccept(event) || event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            event.accepted = true;
            suspendRoot.triggerAdvancePress();
        } else if (api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace) {
            event.accepted = true;
            suspendRoot.pressCount = 0;
        }
    }
}
