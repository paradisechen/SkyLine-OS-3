import QtQuick 2.12
import "../global" as Global

FocusScope {
    id: kbRoot
    anchors.fill: parent
    z: 500
    visible: isOpen
    focus: isOpen

    property bool isOpen: false
    property string titleText: "Enter Text"
    property string textValue: ""
    property bool allowUrlKeys: false
    property int maxLength: 160
    property bool shiftOn: false
    property var onCommitCallback: null
    property var onCancelCallback: null

    property int rowIndex: 1
    property int colIndex: 0

    property var rowsLower: [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "_"],
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "/", ":"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l", ".", "?", "="],
        ["SHIFT", "z", "x", "c", "v", "b", "n", "m", "@", "&", "DEL"],
        ["https://", ".com", ".org", "SPACE", "CLEAR", "CANCEL", "OK"]
    ]

    property var rowsUpper: [
        ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "+", "_"],
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "/", ":"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "?", "="],
        ["SHIFT", "Z", "X", "C", "V", "B", "N", "M", "-", "'", "DEL"],
        ["https://", ".com", ".net", "SPACE", "CLEAR", "CANCEL", "OK"]
    ]

    function currentRows() {
        return shiftOn ? rowsUpper : rowsLower;
    }

    function open(title, initial, urlKeys, maxLen, onCommit, onCancel) {
        titleText = title || "Enter Text";
        textValue = initial ? String(initial) : "";
        allowUrlKeys = !!urlKeys;
        maxLength = (typeof maxLen === "number" && maxLen > 0) ? maxLen : 160;
        onCommitCallback = onCommit || null;
        onCancelCallback = onCancel || null;
        shiftOn = false;
        rowIndex = 1;
        colIndex = 0;
        isOpen = true;
        kbRoot.forceActiveFocus();
    }

    function commit() {
        var val = textValue;
        var cb = onCommitCallback;
        onCommitCallback = null;
        onCancelCallback = null;
        isOpen = false;
        if (typeof selectSfx !== "undefined") selectSfx.play();
        if (cb) cb(val);
    }

    function cancel() {
        var cb = onCancelCallback;
        onCommitCallback = null;
        onCancelCallback = null;
        isOpen = false;
        if (typeof backSfx !== "undefined") backSfx.play();
        if (cb) cb();
    }

    function pressKey(label) {
        if (typeof navSound !== "undefined") navSound.play();
        if (label === "SHIFT") {
            shiftOn = !shiftOn;
            return;
        }
        if (label === "DEL") {
            if (textValue.length > 0)
                textValue = textValue.substring(0, textValue.length - 1);
            return;
        }
        if (label === "CLEAR") {
            textValue = "";
            return;
        }
        if (label === "SPACE") {
            if (textValue.length < maxLength)
                textValue += " ";
            return;
        }
        if (label === "OK") {
            commit();
            return;
        }
        if (label === "CANCEL") {
            cancel();
            return;
        }
        if (textValue.length + label.length <= maxLength) {
            textValue += label;
            if (shiftOn && label.length === 1)
                shiftOn = false;
        }
    }

    Keys.onBackPressed: {
        event.accepted = true;
        cancel();
        if (typeof showHomeScreen === "function")
            showHomeScreen();
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Back) {
            event.accepted = true;
            cancel();
            if (typeof showHomeScreen === "function")
                showHomeScreen();
            return;
        }

        if (api.keys.isCancel(event) || event.key === Qt.Key_Escape) {
            event.accepted = true;
            cancel();
            return;
        }

        if (event.key === Qt.Key_Backspace) {
            event.accepted = true;
            pressKey("DEL");
            return;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            event.accepted = true;
            var rows = currentRows();
            var lbl = rows[rowIndex][colIndex];
            if (lbl)
                pressKey(lbl);
            return;
        }

        if (api.keys.isAccept(event)) {
            event.accepted = true;
            var rws = currentRows();
            var keyLbl = rws[rowIndex][colIndex];
            if (keyLbl)
                pressKey(keyLbl);
            return;
        }

        if (api.keys.isDetails(event) || event.key === Qt.Key_X) {
            event.accepted = true;
            pressKey("DEL");
            return;
        }

        if (api.keys.isFilters(event) || event.key === Qt.Key_Y) {
            event.accepted = true;
            pressKey("SPACE");
            return;
        }

        if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal || event.key === Qt.Key_Menu) {
            event.accepted = true;
            commit();
            return;
        }

        if (event.key === Qt.Key_Up) {
            event.accepted = true;
            var prevR = rowIndex;
            rowIndex = (rowIndex > 0) ? rowIndex - 1 : currentRows().length - 1;
            var targetLen = currentRows()[rowIndex].length;
            if (colIndex >= targetLen) colIndex = targetLen - 1;
            if (prevR !== rowIndex && typeof navSound !== "undefined") navSound.play();
            return;
        }

        if (event.key === Qt.Key_Down) {
            event.accepted = true;
            var rowsDown = currentRows();
            rowIndex = (rowIndex + 1 < rowsDown.length) ? rowIndex + 1 : 0;
            if (colIndex >= rowsDown[rowIndex].length) colIndex = rowsDown[rowIndex].length - 1;
            if (typeof navSound !== "undefined") navSound.play();
            return;
        }

        if (event.key === Qt.Key_Left) {
            event.accepted = true;
            var rLen = currentRows()[rowIndex].length;
            colIndex = (colIndex > 0) ? colIndex - 1 : rLen - 1;
            if (typeof navSound !== "undefined") navSound.play();
            return;
        }

        if (event.key === Qt.Key_Right) {
            event.accepted = true;
            var rLen2 = currentRows()[rowIndex].length;
            colIndex = (colIndex + 1 < rLen2) ? colIndex + 1 : 0;
            if (typeof navSound !== "undefined") navSound.play();
            return;
        }

        if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
            event.accepted = true;
            if (textValue.length < maxLength)
                textValue += event.text;
            return;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#CC0B0E14"

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }
    }

    Rectangle {
        id: panel
        width: Math.min(parent.width * 0.88, vpx(960))
        height: Math.min(parent.height * 0.84, vpx(540))
        anchors.centerIn: parent
        radius: vpx(22)
        color: "#1B1F27"
        border.color: "#384152"
        border.width: vpx(2)

        Column {
            anchors.fill: parent
            anchors.margins: vpx(24)
            spacing: vpx(16)

            // Header + Close
            Item {
                width: parent.width
                height: vpx(32)

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: kbRoot.titleText
                    color: "#FFFFFF"
                    font.family: typeof titleFont !== "undefined" ? titleFont.name : "sans-serif"
                    font.pixelSize: vpx(20)
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "A Key  ·  X Del  ·  Y Space  ·  + Done  ·  B Cancel"
                    color: "#9AA5B8"
                    font.family: typeof titleFont !== "undefined" ? titleFont.name : "sans-serif"
                    font.pixelSize: vpx(13)
                }
            }

            // Pure QML Display Bar (NO TextInput / NO Android blue IME box)
            Rectangle {
                id: displayBar
                width: parent.width
                height: vpx(60)
                radius: vpx(12)
                color: "#11141B"
                border.color: (typeof theme !== "undefined" && theme.accent) ? theme.accent : "#10AEBE"
                border.width: vpx(2)
                clip: true

                Row {
                    anchors.left: parent.left
                    anchors.right: clearMiniBtn.left
                    anchors.leftMargin: vpx(18)
                    anchors.rightMargin: vpx(12)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(2)

                    Text {
                        id: previewText
                        width: Math.min(implicitWidth, parent.width - vpx(12))
                        text: kbRoot.textValue
                        color: "#F3F6FA"
                        font.family: typeof titleFont !== "undefined" ? titleFont.name : "sans-serif"
                        font.pixelSize: vpx(22)
                        elide: Text.ElideLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        width: vpx(3)
                        height: vpx(26)
                        anchors.verticalCenter: parent.verticalCenter
                        color: (typeof theme !== "undefined" && theme.accent) ? theme.accent : "#10AEBE"
                        SequentialAnimation on opacity {
                            running: kbRoot.isOpen
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.15; duration: 480 }
                            NumberAnimation { to: 1.0; duration: 480 }
                        }
                    }
                }

                Rectangle {
                    id: clearMiniBtn
                    anchors.right: parent.right
                    anchors.rightMargin: vpx(12)
                    anchors.verticalCenter: parent.verticalCenter
                    width: vpx(72)
                    height: vpx(34)
                    radius: vpx(8)
                    color: "#252B37"
                    visible: kbRoot.textValue.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: "Clear"
                        color: "#D1D5DB"
                        font.pixelSize: vpx(13)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: kbRoot.pressKey("CLEAR")
                    }
                }
            }

            // Keyboard rows
            Column {
                width: parent.width
                height: parent.height - vpx(32) - vpx(60) - vpx(32)
                spacing: vpx(10)

                Repeater {
                    model: kbRoot.currentRows()

                    Row {
                        id: keyRow
                        property int rIdx: index
                        property var rowKeys: modelData
                        width: parent.width
                        height: (parent.height - vpx(40)) / 5
                        spacing: vpx(8)

                        Repeater {
                            model: keyRow.rowKeys

                            Rectangle {
                                property int cIdx: index
                                property string lbl: modelData
                                property bool isFocused: kbRoot.isOpen && kbRoot.rowIndex === keyRow.rIdx && kbRoot.colIndex === cIdx
                                property bool isConfirm: lbl === "OK"
                                property bool isCancel: lbl === "CANCEL"
                                property bool isWide: lbl === "SPACE" || lbl === "OK" || lbl === "CANCEL" || lbl === "https://" || lbl === "CLEAR" || lbl === "SHIFT"
                                property real unitW: {
                                    var totalUnits = 0;
                                    for (var i = 0; i < keyRow.rowKeys.length; i++) {
                                        var k = keyRow.rowKeys[i];
                                        if (k === "SPACE") totalUnits += 2.2;
                                        else if (k === "OK" || k === "CANCEL") totalUnits += 1.6;
                                        else if (k === "SHIFT" || k === "DEL" || k === "CLEAR" || k === "https://") totalUnits += 1.4;
                                        else totalUnits += 1.0;
                                    }
                                    var myUnits = 1.0;
                                    if (lbl === "SPACE") myUnits = 2.2;
                                    else if (lbl === "OK" || lbl === "CANCEL") myUnits = 1.6;
                                    else if (lbl === "SHIFT" || lbl === "DEL" || lbl === "CLEAR" || lbl === "https://") myUnits = 1.4;
                                    return ((keyRow.width - keyRow.spacing * (keyRow.rowKeys.length - 1)) / totalUnits) * myUnits;
                                }

                                width: unitW
                                height: keyRow.height
                                radius: vpx(10)
                                color: isConfirm
                                       ? (isFocused ? "#10B981" : "#059669")
                                       : (isCancel
                                          ? (isFocused ? "#EF4444" : "#374151")
                                          : (isFocused ? "#FFFFFF" : ((lbl === "SHIFT" && kbRoot.shiftOn) ? "#3B82F6" : "#272D3A")))
                                border.color: isFocused
                                              ? ((typeof theme !== "undefined" && theme.accent) ? theme.accent : "#10AEBE")
                                              : "#333B4B"
                                border.width: isFocused ? vpx(3) : vpx(1)

                                Text {
                                    anchors.centerIn: parent
                                    text: lbl === "DEL" ? "⌫ Del" : (lbl === "SPACE" ? "Space" : (lbl === "SHIFT" ? (kbRoot.shiftOn ? "⇧ ABC" : "⇧ abc") : lbl))
                                    color: (isFocused && !isConfirm && !isCancel) ? "#111827" : "#F9FAFB"
                                    font.family: typeof titleFont !== "undefined" ? titleFont.name : "sans-serif"
                                    font.pixelSize: (lbl.length > 3) ? vpx(15) : vpx(18)
                                    font.bold: isFocused || lbl.length > 1
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        kbRoot.rowIndex = keyRow.rIdx;
                                        kbRoot.colIndex = cIdx;
                                        kbRoot.pressKey(lbl);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
