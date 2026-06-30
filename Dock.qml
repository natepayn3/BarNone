import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: dockWindow
    
    required property var launcherModule
    required property var wallpaperModule

    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: WlrLayershell.None

    anchors {
        bottom: true
    }
    
    implicitWidth: visualDock.width + 44
    implicitHeight: 85
    color: "transparent"
    exclusiveZone: 0

    FontConfig { id: fc }

    Item {
        id: staticMaskSurface
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: dockHitbox.isPinned ? 78 : 16
    }

    mask: Region {
        Region {
            item: staticMaskSurface
        }
    }

    property color themeText: shellConfig.themeText
    property color themeBorder: shellConfig.colorBorder
    property color themeAccent: shellConfig.themeAccent
    property color hoverBorder: shellConfig.hoverBorder

    BluetoothPopup { id: bluetoothOverlay; visible: false }
    AudioPopup { id: audioOverlay; visible: false }
    WifiPopup { id: wifiOverlay; visible: false }
    PowerPopup { id: powerOverlay; visible: false }

    MouseArea {
        id: dockHitbox
        anchors.fill: parent
        hoverEnabled: true

        property int activeHoverIndex: -1

        property bool stableHover: hotspotTrigger.containsMouse ||
                                   innerCapsuleMouseTracker.containsMouse ||
                                   (dockWindow.launcherModule && dockWindow.launcherModule.launcherWindowObject && dockWindow.launcherModule.launcherWindowObject.visible) ||
                                   bluetoothOverlay.visible ||
                                   audioOverlay.visible ||
                                   wifiOverlay.visible ||
                                   powerOverlay.visible

        property bool isPinned: false

        onStableHoverChanged: {
            if (stableHover) {
                dismissTimer.stop();
                if (dockWindow.wallpaperModule && dockWindow.wallpaperModule.active) {
                    if (dockWindow.wallpaperModule.screen === dockWindow.screen) {
                        isPinned = true;
                    }
                } else {
                    isPinned = true;
                }
            } else {
                dismissTimer.start();
            }
        }

        MouseArea {
            id: hotspotTrigger
            width: parent.width - 4
            height: 16
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            hoverEnabled: true
        }

        Rectangle {
            id: inputStabilizerCapsule
            width: visualDock.width + 24
            height: 72
            radius: shellConfig.radiusValue - 2
            anchors.horizontalCenter: parent.horizontalCenter
           
            y: dockHitbox.isPinned ? (parent.height - height - 6) : parent.height
            color: Qt.rgba(0, 0, 0, 0.01)

            Behavior on y {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Row {
                id: visualDock
                spacing: 16
                anchors.centerIn: parent

                // --- BUTTON 1: APP LAUNCHER ---
                Item {
                    id: btnLauncher
                    width: 64
                    height: 64
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: dockHitbox.activeHoverIndex === 0 ? (dockWindow.themeAccent || "transparent") : "transparent"
                        border.color: dockHitbox.activeHoverIndex === 0 ? (dockWindow.hoverBorder || "transparent") : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "apps"
                        font.family: fc.iconFont
                        font.pixelSize: 32
                        color: dockHitbox.isPinned ? Qt.rgba(dockWindow.themeText.r, dockWindow.themeText.g, dockWindow.themeText.b, 0.9) : "transparent"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Component.onCompleted: fc.applyOutline(this)
                    }
                }

                // --- BUTTON 2: WALLPAPER PICKER ---
                Item {
                    id: btnWallpaper
                    width: 64
                    height: 64
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: dockHitbox.activeHoverIndex === 1 ? (dockWindow.themeAccent || "transparent") : "transparent"
                        border.color: dockHitbox.activeHoverIndex === 1 ? (dockWindow.hoverBorder || "transparent") : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "wallpaper"
                        font.family: fc.iconFont
                        font.pixelSize: 32
                        color: dockHitbox.isPinned ? Qt.rgba(dockWindow.themeText.r, dockWindow.themeText.g, dockWindow.themeText.b, 0.9) : "transparent"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Component.onCompleted: fc.applyOutline(this)
                    }
                }

                // --- BUTTON 3: BLUETOOTH CONFIG ---
                Item {
                    id: btnBluetooth
                    width: 64
                    height: 64
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: dockHitbox.activeHoverIndex === 2 ? (dockWindow.themeAccent || "transparent") : "transparent"
                        border.color: dockHitbox.activeHoverIndex === 2 ? (dockWindow.hoverBorder || "transparent") : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "bluetooth"
                        font.family: fc.iconFont
                        font.pixelSize: 32
                        color: dockHitbox.isPinned ? Qt.rgba(dockWindow.themeText.r, dockWindow.themeText.g, dockWindow.themeText.b, 0.9) : "transparent"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Component.onCompleted: fc.applyOutline(this)
                    }
                }

                // --- BUTTON 4: AUDIO OUTPUT ROUTER ---
                Item {
                    id: btnAudio
                    width: 64
                    height: 64
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: dockHitbox.activeHoverIndex === 3 ? (dockWindow.themeAccent || "transparent") : "transparent"
                        border.color: dockHitbox.activeHoverIndex === 3 ? (dockWindow.hoverBorder || "transparent") : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "volume_up"
                        font.family: fc.iconFont
                        font.pixelSize: 32
                        color: dockHitbox.isPinned ? Qt.rgba(dockWindow.themeText.r, dockWindow.themeText.g, dockWindow.themeText.b, 0.9) : "transparent"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Component.onCompleted: fc.applyOutline(this)
                    }
                }

                // --- BUTTON 5: WIFI CONFIG ---
                Item {
                    id: btnWifi
                    width: 64
                    height: 64
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: dockHitbox.activeHoverIndex === 4 ? (dockWindow.themeAccent || "transparent") : "transparent"
                        border.color: dockHitbox.activeHoverIndex === 4 ? (dockWindow.hoverBorder || "transparent") : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "network_wifi"
                        font.family: fc.iconFont
                        font.pixelSize: 32
                        color: dockHitbox.isPinned ? Qt.rgba(dockWindow.themeText.r, dockWindow.themeText.g, dockWindow.themeText.b, 0.9) : "transparent"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Component.onCompleted: fc.applyOutline(this)
                    }
                }

                // --- BUTTON 6: SCREENSHOT UTILITY ---
                Item {
                    id: btnScreenshot
                    width: 64
                    height: 64
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: dockHitbox.activeHoverIndex === 5 ? (dockWindow.themeAccent || "transparent") : "transparent"
                        border.color: dockHitbox.activeHoverIndex === 5 ? (dockWindow.hoverBorder || "transparent") : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "screenshot_region"
                        font.family: fc.iconFont
                        font.pixelSize: 32
                        color: dockHitbox.isPinned ? Qt.rgba(dockWindow.themeText.r, dockWindow.themeText.g, dockWindow.themeText.b, 0.9) : "transparent"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Component.onCompleted: fc.applyOutline(this)
                    }
                }

                // --- BUTTON 7: POWER TRIGGER MODULE ---
                Item {
                    id: btnPower
                    width: 64
                    height: 64
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: dockHitbox.activeHoverIndex === 6 ? (dockWindow.themeAccent || "transparent") : "transparent"
                        border.color: dockHitbox.activeHoverIndex === 6 ? (dockWindow.hoverBorder || "transparent") : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "power_settings_new"
                        font.family: fc.iconFont
                        font.pixelSize: 32
                        color: dockHitbox.isPinned ? Qt.rgba(dockWindow.themeText.r, dockWindow.themeText.g, dockWindow.themeText.b, 0.9) : "transparent"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Component.onCompleted: fc.applyOutline(this)
                    }
                }
            }

            MouseArea {
                id: innerCapsuleMouseTracker
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: dockHitbox.activeHoverIndex !== -1 ? Qt.PointingHandCursor : Qt.ArrowCursor

                onPositionChanged: (mouse) => {
                    let adjustedX = mouse.x - 12;
                    let totalCellWidth = 80;
                    let calculatedIndex = Math.floor(adjustedX / totalCellWidth);
                    let localX = adjustedX % totalCellWidth;
                    
                    if (calculatedIndex >= 0 && calculatedIndex <= 6 && localX <= 64 && adjustedX >= 0) {
                        dockHitbox.activeHoverIndex = calculatedIndex;
                    } else {
                        dockHitbox.activeHoverIndex = -1;
                    }
                }

                onExited: dockHitbox.activeHoverIndex = -1

                onClicked: (mouse) => {
                    if (dockHitbox.activeHoverIndex === 0) {
                        dockWindow.launcherModule.active = !dockWindow.launcherModule.active;
                    } else if (dockHitbox.activeHoverIndex === 1) {
                        if (dockWindow.wallpaperModule) {
                            dockWindow.wallpaperModule.active = !dockWindow.wallpaperModule.active;
                        }
                    } else if (dockHitbox.activeHoverIndex === 2) {
                        if (!bluetoothOverlay.visible) bluetoothOverlay.visible = true; else bluetoothOverlay.animateActive = false;
                    } else if (dockHitbox.activeHoverIndex === 3) {
                        if (!audioOverlay.visible) audioOverlay.visible = true; else audioOverlay.animateActive = false;
                    } else if (dockHitbox.activeHoverIndex === 4) {
                        if (!wifiOverlay.visible) wifiOverlay.visible = true; else wifiOverlay.animateActive = false;
                    } else if (dockHitbox.activeHoverIndex === 5) {
                        dockHitbox.isPinned = false;
                        Quickshell.execDetached(["fish", "-c", "sleep 0.1; and grim -g (slurp) -t ppm - | satty --filename -"]);
                    } else if (dockHitbox.activeHoverIndex === 6) {
                        if (!powerOverlay.visible) powerOverlay.visible = true; else powerOverlay.animateActive = false;
                    }
                }
            }
        }
    }

    Timer {
        id: dismissTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            dockHitbox.isPinned = false;
            dockHitbox.activeHoverIndex = -1;
        }
    }
}