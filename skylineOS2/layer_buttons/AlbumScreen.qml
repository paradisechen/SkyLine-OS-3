// skylineOS 2 — AlbumScreen.qml (Full-Screen Switch 2 Album + Screenshots Lightbox + Device Photos App)
import QtQuick 2.12

FocusScope {
    id: albumRoot
    anchors.fill: parent

    property int selectedIndex: 0
    property int lightboxIndex: -1
    property string folderLabel: (api.memory.has("Photos Directory") && api.memory.get("Photos Directory") !== "") ? String(api.memory.get("Photos Directory")) : (api.memory.has("Gallery Folder Label") && api.memory.get("Gallery Folder Label") !== "" ? String(api.memory.get("Gallery Folder Label")) : "/storage/emulated/0/Pictures")
    property var folderModelObj: null
    property bool isDarkPage: (settings.appearanceMode === "Dark") || (settings.appearanceMode === "Auto" && settings.darkMode === "Yes")
    property color pageBg: isDarkPage ? "#1A1C21" : "#EFEFEF"
    property color cardBg: isDarkPage ? "#252830" : "#FFFFFF"
    property color textMain: isDarkPage ? "#F3F4F6" : "#1F2329"
    property color textMuted: isDarkPage ? "#9CA3AF" : "#5E6570"
    property color dividerColor: isDarkPage ? "#383B44" : "#C8C8C8"

    ListModel { id: photosModel }

    function appendGameScreenshotsFallback() {
        for (var i = 0; i < api.allGames.count; i++) {
            var g = api.allGames.get(i);
            var shots = g.assets ? g.assets.screenshots : null;
            if (shots && shots.length > 0) {
                for (var s = 0; s < Math.min(shots.length, 2); s++) {
                    if (shots[s] && shots[s] !== "") photosModel.append({ title: g.title, url: shots[s] });
                }
            } else if (g.assets && g.assets.background && g.assets.background !== "") {
                photosModel.append({ title: g.title, url: g.assets.background });
            }
        }
    }

    function syncFolderModel() {
        photosModel.clear();
        var addedFromFolder = 0;
        if (folderModelObj && folderModelObj.count > 0) {
            for (var k = 0; k < folderModelObj.count && addedFromFolder < 120; k++) {
                var fUrl = "";
                var fName = "";
                try {
                    fUrl = String(folderModelObj.get(k, "fileURL") || folderModelObj.get(k, "fileUrl") || "");
                    fName = String(folderModelObj.get(k, "fileName") || "Photo");
                } catch (e) {}
                if (fUrl !== "") {
                    photosModel.append({ title: fName, url: fUrl });
                    addedFromFolder++;
                }
            }
        }
        if (addedFromFolder === 0) {
            appendGameScreenshotsFallback();
        }
        selectedIndex = 0;
        lightboxIndex = -1;
    }

    function normalizedFolderUrl(rawPath) {
        var p = String(rawPath || "").trim();
        if (p === "") p = "/storage/emulated/0/Pictures";
        if (p.indexOf("file://") === 0) return p;
        if (p.indexOf("/") !== 0) p = "/" + p;
        return "file://" + p;
    }

    function initFolderModel() {
        if (folderModelObj) {
            try { folderModelObj.folder = normalizedFolderUrl(folderLabel); } catch (e) {}
            return;
        }
        var candidates = [
            'import QtQuick 2.12; import Qt.labs.folderlistmodel 2.12; FolderListModel { showDirs: false; showDotAndDotDot: false; nameFilters: ["*.png","*.jpg","*.jpeg","*.webp","*.gif","*.bmp"] }',
            'import QtQuick 2.12; import Qt.labs.folderlistmodel 2.1; FolderListModel { showDirs: false; showDotAndDotDot: false; nameFilters: ["*.png","*.jpg","*.jpeg","*.webp","*.gif","*.bmp"] }',
            'import QtQuick 2.12; import Qt.labs.folderlistmodel 2.0; FolderListModel { showDirs: false; showDotAndDotDot: false; nameFilters: ["*.png","*.jpg","*.jpeg","*.webp","*.gif","*.bmp"] }'
        ];
        for (var c = 0; c < candidates.length; c++) {
            try {
                var obj = Qt.createQmlObject(candidates[c], albumRoot, "albumFolderModel_" + c);
                if (obj) {
                    folderModelObj = obj;
                    obj.folder = normalizedFolderUrl(folderLabel);
                    return;
                }
            } catch (err) {}
        }
    }

    Connections {
        target: albumRoot.folderModelObj
        ignoreUnknownSignals: true
        onCountChanged: albumRoot.syncFolderModel()
        onStatusChanged: albumRoot.syncFolderModel()
    }

    function scanScreenshots() {
        folderLabel = (api.memory.has("Photos Directory") && api.memory.get("Photos Directory") !== "") ? String(api.memory.get("Photos Directory")) : (api.memory.has("Gallery Folder Label") && api.memory.get("Gallery Folder Label") !== "" ? String(api.memory.get("Gallery Folder Label")) : "/storage/emulated/0/Pictures");
        initFolderModel();
        syncFolderModel();
    }

    function openDevicePhotos() {
        albumSfx.play();
        if (Qt.platform.os === "android") {
            var customUri = api.memory.has("Gallery URI") ? String(api.memory.get("Gallery URI")) : "android-app://com.google.android.apps.photos";
            Qt.openUrlExternally(customUri !== "" ? customUri : "android-app://com.google.android.apps.photos");
        } else {
            Qt.openUrlExternally("file://" + folderLabel);
        }
    }

    onVisibleChanged: { if (visible) { scanScreenshots(); albumRoot.forceActiveFocus(); } }

    Keys.onLeftPressed: { if (photosModel.count === 0) return; navSound.play(); if (lightboxIndex >= 0) lightboxIndex = (lightboxIndex - 1 + photosModel.count) % photosModel.count; else selectedIndex = (selectedIndex - 1 + photosModel.count) % photosModel.count; }
    Keys.onRightPressed: { if (photosModel.count === 0) return; navSound.play(); if (lightboxIndex >= 0) lightboxIndex = (lightboxIndex + 1) % photosModel.count; else selectedIndex = (selectedIndex + 1) % photosModel.count; }
    Keys.onUpPressed: { if (lightboxIndex >= 0 || photosModel.count === 0) return; navSound.play(); selectedIndex = Math.max(0, selectedIndex - 4); }
    Keys.onDownPressed: { if (lightboxIndex >= 0 || photosModel.count === 0) return; navSound.play(); selectedIndex = Math.min(photosModel.count - 1, selectedIndex + 4); }
    Keys.onBackPressed: { event.accepted = true; backSfx.play(); lightboxIndex = -1; showHomeScreen(); }
    Keys.onEscapePressed: { event.accepted = true; backSfx.play(); if (lightboxIndex >= 0) lightboxIndex = -1; else showHomeScreen(); }
    Keys.onReleased: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function")
            root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
    }

    Keys.onPressed: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (lightboxIndex < 0 && photosModel.count > 0) { selectSfx.play(); lightboxIndex = selectedIndex; }
        } else if ((api.keys.isCancel(event) || event.key === Qt.Key_Escape || event.key === Qt.Key_B || event.key === Qt.Key_Backspace) && !event.isAutoRepeat) {
            event.accepted = true; backSfx.play();
            if (lightboxIndex >= 0) lightboxIndex = -1; else showHomeScreen();
        }
    }

    Rectangle { anchors.fill: parent; color: albumRoot.pageBg }

    Item {
        id: albumHeader
        anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.112)
        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter } spacing: vpx(12)
            Image { width: vpx(28); height: vpx(28); source: "../assets/images/navigation/ns2_album.svg"; fillMode: Image.PreserveAspectFit; smooth: true; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: tr("Album"); color: albumRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.035); font.bold: true }
                Text { text: tr("Photos Directory: ") + albumRoot.folderLabel; color: albumRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.017) }
            }
        }
        Rectangle {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: vpx(210); height: vpx(36); radius: height / 2; color: "#215FE5"
            Text { anchors.centerIn: parent; text: tr("Open Device Photos App"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.019); font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: albumRoot.openDevicePhotos() }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: albumRoot.dividerColor }
    }

    Item {
        anchors { top: albumHeader.bottom; bottom: albumFooter.top; left: parent.left; right: parent.right; margins: vpx(24) }
        Item {
            visible: albumRoot.lightboxIndex >= 0 && albumRoot.lightboxIndex < photosModel.count
            anchors.fill: parent
            Image {
                anchors { top: parent.top; bottom: shotCaption.top; bottomMargin: vpx(10); left: parent.left; right: parent.right }
                source: (albumRoot.lightboxIndex >= 0 && albumRoot.lightboxIndex < photosModel.count) ? photosModel.get(albumRoot.lightboxIndex).url : ""
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            }
            Text {
                id: shotCaption; anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                text: (albumRoot.lightboxIndex >= 0 && albumRoot.lightboxIndex < photosModel.count) ? photosModel.get(albumRoot.lightboxIndex).title : ""
                color: albumRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022)
            }
        }
        Text {
            visible: photosModel.count === 0; anchors.centerIn: parent; width: parent.width * 0.7; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
            text: tr("No game screenshots found in Pegasus library yet. Tap 'Open Device Photos App' above to view your Retroid Pocket 5 gallery.")
            color: albumRoot.textMuted; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023)
        }
        GridView {
            visible: albumRoot.lightboxIndex < 0 && photosModel.count > 0; anchors.fill: parent
            cellWidth: Math.floor(width / 4); cellHeight: Math.round(cellWidth * 0.62); clip: true
            model: photosModel; currentIndex: albumRoot.selectedIndex
            delegate: Item {
                width: GridView.view.cellWidth; height: GridView.view.cellHeight
                Rectangle {
                    anchors.fill: parent; anchors.margins: vpx(6); radius: vpx(10); color: albumRoot.cardBg
                    border.width: albumRoot.selectedIndex === index ? vpx(3) : 1; border.color: albumRoot.selectedIndex === index ? "#215FE5" : albumRoot.dividerColor
                    clip: true
                    Image { anchors.fill: parent; source: url; fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true }
                    Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: vpx(24); color: "#99000000"
                        Text { anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: vpx(8); rightMargin: vpx(8) } text: title; color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.016); elide: Text.ElideRight }
                    }
                    MouseArea { anchors.fill: parent; onClicked: { selectSfx.play(); albumRoot.selectedIndex = index; albumRoot.lightboxIndex = index; } }
                }
            }
        }
    }

    Item {
        id: albumFooter
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.088)
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: albumRoot.dividerColor }
        Image { anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter } spacing: vpx(8)
            Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: albumRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "B"; color: albumRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
            }
            Text { text: tr("Back"); color: albumRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); anchors.verticalCenter: parent.verticalCenter }
            MouseArea { anchors.fill: parent; onClicked: { backSfx.play(); if (albumRoot.lightboxIndex >= 0) albumRoot.lightboxIndex = -1; else showHomeScreen(); } }
        }
    }
}
