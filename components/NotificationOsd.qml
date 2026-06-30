import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: popupWindow

    required property var screen
    
    // Injected broadcaster from shell.qml
    required property var broadcaster

    property string notifSummary: ""
    property string notifBody: ""

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-osd"
    WlrLayershell.keyboardFocus: WlrLayershell.None
    exclusionMode: ExclusionMode.Ignore

    visible: false

    anchors.bottom: true
    anchors.right: true
    
    margins.bottom: 100
    margins.right: 24

    implicitWidth: 360
    implicitHeight: 64
    color: "transparent"

    // Each window handles its own 3-second visibility timeout independently
    Timer {
        id: dismissTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: popupWindow.visible = false
    }

    // Explicitly listen to the injected broadcaster object
    Connections {
        target: popupWindow.broadcaster

        function onBroadcast(summary, body) {
            popupWindow.notifSummary = summary;
            popupWindow.notifBody = body;
            popupWindow.visible = true;
            dismissTimer.restart();
        }
    }

    // --- VISUAL POPUP BANNER ---
    Rectangle {
        id: bannerCard
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(0, 0, 0, 0.01)
        border.width: 0

        y: popupWindow.visible ? 0 : 120
        opacity: popupWindow.visible ? 1.0 : 0.0

        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18

            Rectangle {
                width: 28
                height: 28
                radius: 6
                color: Qt.rgba(1, 1, 1, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "notifications"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 16
                    color: "#ffffff"
                }
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                Text {
                    text: popupWindow.notifSummary
                    color: "#ffffff"
                    font.family: "Google Sans Flex"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: popupWindow.notifBody
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: "Google Sans Flex"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }
}