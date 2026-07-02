import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../configs"

PanelWindow {
    id: trayWindow

    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: WlrLayershell.None
    
    anchors {
        top: true
    }
    
    property int totalItemCount: SystemTray.items.values.length
    
    implicitWidth: totalItemCount === 0 ? 244 : (totalItemCount * 64) + ((totalItemCount - 1) * 16) + 48
    implicitHeight: 120 
    color: "transparent"
    exclusiveZone: 0

    FontConfig { id: fc }
    ModuleConfig { id: shellConfig }

    // --- Mask Surfaces ---
    Item {
        id: minimalMaskSurface
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 16
    }

    Item {
        id: pinnedMaskSurface
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 120
    }

    // Swapping the item reference directly forces Quickshell to update the mask layout
    mask: Region {
        item: trayHitbox.isPinned ? pinnedMaskSurface : minimalMaskSurface
    }

    property color themeText: shellConfig.themeText
    property color themeBorder: shellConfig.colorBorder
    property color themeAccent: shellConfig.themeAccent
    property color hoverBorder: shellConfig.hoverBorder

    property int activeHoverIndex: -1

    MouseArea {
        id: trayHitbox
        anchors.fill: parent
        hoverEnabled: true

        property bool isPinned: false
        // FIX: Evaluates the entire container hitbox so sibling hovers don't trip the timer
        property bool stableHover: trayHitbox.containsMouse

        onStableHoverChanged: {
            if (stableHover) {
                dismissTimer.stop();
                trayHitbox.isPinned = true;
            } else {
                dismissTimer.start();
            }
        }

        MouseArea {
            id: hotspotTrigger
            width: parent.width - 4
            height: 16
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            hoverEnabled: true
         }

        Rectangle {
            id: inputStabilizerCapsule
            width: parent.width - 24
            height: 72
            radius: shellConfig.radiusValue - 2
            anchors.horizontalCenter: parent.horizontalCenter
 
            y: trayHitbox.isPinned ? 6 : -height
            color: fc.trackBackground
            border.color: trayHitbox.isPinned ? fc.borderMuted : "transparent"
            border.width: 1
            opacity: trayHitbox.isPinned ? 1.0 : 0.0

            Behavior on y { 
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic } 
            }
            Behavior on opacity { 
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad } 
            }

            Row {
                id: visualTrayCapsule
                spacing: 16
                anchors.centerIn: parent

                Item {
                    id: placeholderContainer
                    visible: trayWindow.totalItemCount === 0
                    width: 200
                    height: 64
                  
                    Text {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "blur_on"
                        font.family: fc.iconFont
                        font.pixelSize: 28
                        color: Qt.rgba(trayWindow.themeText.r, trayWindow.themeText.g, trayWindow.themeText.b, 0.35)
                        
                        Component.onCompleted: {
                            fc.applyOutline(this, fc.overlayBackground)
                        }
                    }
                }

                Repeater {
                    model: SystemTray.items.values
                    delegate: Item {
                        width: 64
                        height: 64
                        z: trayWindow.activeHoverIndex === index ? 10 : 1
            
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: trayWindow.activeHoverIndex === index ? (trayWindow.themeAccent || "transparent") : "transparent"
                            border.color: trayWindow.activeHoverIndex === index ? (trayWindow.hoverBorder || "transparent") : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Fix: Reverted to use native source bindings driven by Quickshell.iconPath
                        IconImage {
                            anchors.centerIn: parent
                            width: 32
                            height: 32
                            source: modelData.iconPath ? "file://" + modelData.iconPath : Quickshell.iconPath(modelData.icon || "image-missing")
                            asynchronous: true
                            opacity: trayHitbox.isPinned ? 0.9 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }

                        Rectangle {
                            id: tooltipBubble
                            visible: trayWindow.activeHoverIndex === index && modelData.title !== ""
                            width: tooltipText.contentWidth + 16
                            height: 26
                            radius: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.bottom
                            anchors.topMargin: 12
                            color: fc.trackBackground
                            border.color: fc.borderMuted
                            border.width: 1
                            z: 100

                            Text {
                                id: tooltipText
                                anchors.centerIn: parent
                                text: modelData.title || modelData.id || ""
                                font.pointSize: 11
                                font.family: fc.mainFont
                                font.weight: Font.Normal
                                color: trayWindow.themeText
                                
                                Component.onCompleted: {
                                    fc.applyOutline(this, fc.overlayBackground)
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor

                            onEntered: trayWindow.activeHoverIndex = index
                            onExited: trayWindow.activeHoverIndex = -1

                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    modelData.secondaryActivate();
                                } else {
                                    modelData.activate();
                                }
                            }
                        }
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
            trayHitbox.isPinned = false;
            trayWindow.activeHoverIndex = -1;
        }
    }
}
