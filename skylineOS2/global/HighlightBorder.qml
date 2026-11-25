// skylineOS 2 — Patched HighlightBorder.qml (Switch 2 Bold Concentric Ring, Non-Pulsing & Unobstructed)
import QtQuick 2.8
import QtGraphicalEffects 1.0

Rectangle {
    id: hlBorder
    property bool selected: false
    property int borderGap: vpx(7)
    property int borderwidth: (typeof idx !== "undefined" && idx == -3) ? vpx(8) : vpx(6)
    property int coverRadius: vpx(24)
    property int borderRadius: coverRadius + borderGap + borderwidth

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    color: "transparent"
    radius: borderRadius
    border.width: borderwidth
    border.color: theme.accent

    Behavior on border.color {
        ColorAnimation { duration: 180 }
    }

    layer.enabled: enableDropShadows
    layer.effect: DropShadow {
        transparentBorder: true
        horizontalOffset: 0
        verticalOffset: vpx(2)
        color: "#4D000000"
        radius: 6.0
        samples: 12
    }

    opacity: selected ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 90
            easing.type: Easing.OutCubic
        }
    }
}
