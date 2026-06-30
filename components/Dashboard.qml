import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: dashboardWindow

    property var notificationModel: notifServer.trackedNotifications

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-resource-dashboard"
    WlrLayershell.keyboardFocus: WlrLayershell.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        right: true
    }

    implicitWidth: 400
    color: "transparent"

    NotificationServer {
        id: notifServer
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        
        onNotification: (notif) => {
            notif.tracked = true;
        }
    }

    mask: Region {
        Region { item: hotspotTrigger }
        Region { item: dashHitbox.isPinned ? bgCard : null }
    }

    MouseArea {
        id: dashHitbox
        anchors.fill: parent
        hoverEnabled: true

        property bool stableHover: hotspotTrigger.containsMouse || cardHover.hovered
        property bool isPinned: false

        onStableHoverChanged: {
            if (stableHover) {
                dismissTimer.stop();
                isPinned = true;
            } else {
                dismissTimer.start();
            }
        }

        MouseArea {
            id: hotspotTrigger
            width: 16
            height: parent.height
            anchors.right: parent.right
            hoverEnabled: true
        }

        Rectangle {
            id: bgCard
            width: 360
            // Dynamic height combining the highest column and the wide footer tray below it
            height: Math.max(leftColumn.implicitHeight, rightColumn.implicitHeight) + notifWrapper.implicitHeight + 68
            anchors.verticalCenter: parent.verticalCenter
            
            x: dashHitbox.isPinned ? (parent.width - width - 16) : parent.width
            opacity: dashHitbox.isPinned ? 1.0 : 0.0

            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            color: Qt.rgba(0.2, 0.2, 0.2, 0.28)
            border.width: 0
            radius: 16

            HoverHandler { id: cardHover }

            Item {
                id: contentGrid
                anchors.fill: parent
                anchors.margins: 24

                // LEFT PANEL COLUMN (Clock, Weather, Sliders)
                Column {
                    id: leftColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: rightColumn.left
                    anchors.rightMargin: 24
                    spacing: 20

                    Clock { 
                        width: parent.width
                        Component.onCompleted: {
                            for (let i = 0; i < children.length; i++) {
                                if (children[i].horizontalAlignment !== undefined) {
                                    children[i].horizontalAlignment = Text.AlignHCenter;
                                }
                            }
                        }
                    }
                    
                    Weather { 
                        width: parent.width
                        Component.onCompleted: {
                            for (let i = 0; i < children.length; i++) {
                                if (children[i].horizontalAlignment !== undefined) {
                                    children[i].horizontalAlignment = Text.AlignHCenter;
                                }
                            }
                        }
                    }
                    
                    VolumeSlider { width: parent.width }
                    Media { width: parent.width }
                }

                // RIGHT PANEL COLUMN (Resource Rings)
                Column {
                    id: rightColumn
                    width: 64
                    anchors.top: parent.top
                    anchors.right: parent.right

                    ResourceRings {
                        width: parent.width
                    }
                }

                // 🎯 FULL-WIDTH NOTIFICATION TRAY (Spans all the way from left edge to right edge)
                Item {
                    id: notifWrapper
                    // Aligns below whichever column ends up being taller
                    anchors.top: leftColumn.implicitHeight > rightColumn.implicitHeight ? leftColumn.bottom : rightColumn.bottom
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.right: parent.right // 🎯 Stretches across the full dashboard width
                    implicitHeight: childrenRect.height

                    Notifications { 
                        width: parent.width 
                    }
                }
            }
        }
    }

    Timer {
        id: dismissTimer
        interval: 350 
        running: false
        repeat: false
        onTriggered: dashHitbox.isPinned = false
    }
}
