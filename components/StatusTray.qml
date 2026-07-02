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

    // Global tracking flag to freeze dismiss cycles when a menu is active
    property bool menuActive: false

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

    mask: Region {
        item: trayWindow.menuActive || trayHitbox.isPinned ? pinnedMaskSurface : minimalMaskSurface
    }

    property color themeText: shellConfig.themeText
    property color themeBorder: shellConfig.colorBorder
    property color themeAccent: shellConfig.themeAccent
    property color hoverBorder: shellConfig.hoverBorder

    property int activeHoverIndex: -1

    function resolveAppName(modelData) {
        if (modelData.title && modelData.title.trim() !== "") {
            return modelData.title;
        }

        let rawId = modelData.id || "";
        if (rawId !== "") {
            // Isolate the last segment if it's a reverse DNS string
            let baseName = rawId.split('.').pop();
            
            // Split into individual words by breaking on dashes, underscores, or spaces
            let words = baseName.split(/[-_\s]+/);
            
            // Filter out generic tray keywords and standalone instance numbers
            let cleanWords = words.filter(word => {
                let lower = word.toLowerCase();
                // Drop common keywords, empty strings, and any standalone digit
                return lower !== "status" && 
                    lower !== "icon" && 
                    lower !== "tray" && 
                    lower !== "" && 
                    !lower.match(/^\d+$/);
            });
            
            // Fallback to the original base name if filtering emptied the array entirely
            let finalName = cleanWords.length > 0 ? cleanWords.join(" ") : baseName.replace(/[-_]/g, " ");
                                    
            // Capitalize the remaining words cleanly
            return finalName.replace(/\b\w/g, c => c.toUpperCase());
        }

        return "Application";
    }

    MouseArea {
        id: trayHitbox
        anchors.fill: parent
        hoverEnabled: true

        property bool isPinned: false
        // FIX: Retains pinned state if mouse is inside OR a native context menu is currently drawn
        property bool stableHover: trayHitbox.containsMouse || trayWindow.menuActive

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
 
            y: (trayHitbox.isPinned || trayWindow.menuActive) ? 6 : -height
            color: fc.trackBackground
            border.color: (trayHitbox.isPinned || trayWindow.menuActive) ? fc.borderMuted : "transparent"
            border.width: 1
            opacity: (trayHitbox.isPinned || trayWindow.menuActive) ? 1.0 : 0.0

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
                    width: 64
                    height: 64
                  
                    Text {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "view_apps"
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
                        id: trayItemDelegate
                        width: 64
                        height: 64
                        z: trayWindow.activeHoverIndex === index ? 10 : 1
            
                        // Bind the platform menu directly to the item's geometry
                        QsMenuAnchor {
                            id: itemMenuAnchor
                            menu: modelData.menu
                            
                            // 1. Target the delegate item wrapper directly instead of the window
                            anchor.item: trayItemDelegate 
                            
                            // 2. Align to the bottom edge of the icon bounds
                            anchor.edges: Edges.Bottom | Edges.Left 
                            anchor.gravity: Edges.Bottom | Edges.Right
                            
                            // 3. Add your exact structural offset (e.g., shifting down by 10px)
                            anchor.rect.x: 32
                            anchor.rect.y: 30

                            onOpened: trayWindow.menuActive = true
                            onClosed: {
                                trayWindow.menuActive = false;
                                trayWindow.activeHoverIndex = -1;
                            }
                        }                        

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: trayWindow.activeHoverIndex === index ? (trayWindow.themeAccent || "transparent") : "transparent"
                            border.color: trayWindow.activeHoverIndex === index ? (trayWindow.hoverBorder || "transparent") : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        IconImage {
                            anchors.centerIn: parent
                            width: 32
                            height: 32
                            
                            // Evaluate if the source is already a file/pixmap URI before invoking iconPath lookup
                            source: modelData.iconPath ? "file://" + modelData.iconPath : 
                                    (modelData.icon && modelData.icon.startsWith("image://")) ? modelData.icon :
                                    Quickshell.iconPath((modelData.icon || "image-missing").replace("image://icon/", ""))
                                    
                            asynchronous: true
                            opacity: (trayHitbox.isPinned || trayWindow.menuActive) ? 0.9 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }

                        Rectangle {
                            id: tooltipBubble
                            // Force visibility to true if we have any way to identify the app, or use a absolute fallback
                            visible: trayWindow.activeHoverIndex === index && !trayWindow.menuActive
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
                                
                                text: trayWindow.resolveAppName(modelData)
                                    
                                font.pointSize: 11
                                font.family: fc.mainFont
                                font.weight: Font.Normal
                                color: trayWindow.themeText
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                if (!trayWindow.menuActive) {
                                    trayWindow.activeHoverIndex = index;
                                }
                            }
                            onExited: {
                                if (!trayWindow.menuActive) {
                                    trayWindow.activeHoverIndex = -1;
                                }
                            }

                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    if (modelData.hasMenu) {
                                        itemMenuAnchor.open();
                                    } else {
                                        modelData.secondaryActivate();
                                    }
                                } else {
                                    if (modelData.hasMenu && !modelData.hasOwnProperty('activate')) {
                                        itemMenuAnchor.open();
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
    }

    Timer {
        id: dismissTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            if (!trayWindow.menuActive) {
                trayHitbox.isPinned = false;
                trayWindow.activeHoverIndex = -1;
            }
        }
    }
}
