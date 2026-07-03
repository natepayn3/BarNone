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
    
    implicitWidth: visualTrayCapsule.width + 72
    implicitHeight: 120 
    color: "transparent"
    exclusiveZone: 0

    property bool menuActive: false

    FontConfig { id: fc }
    ModuleConfig { id: shellConfig }

    Item {
        id: minimalMaskSurface
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 32
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
            let baseName = rawId.split('.').pop();
            let words = baseName.split(/[-_\s]+/);
            
            let cleanWords = words.filter(word => {
                let lower = word.toLowerCase();
                return lower !== "status" && 
                    lower !== "icon" && 
                    lower !== "tray" && 
                    lower !== "" && 
                    !lower.match(/^\d+$/);
            });
            
            let finalName = cleanWords.length > 0 ? cleanWords.join(" ") : baseName.replace(/[-_]/g, " ");
            return finalName.replace(/\b\w/g, c => c.toUpperCase());
        }

        return "Application";
    }

    MouseArea {
        id: trayHitbox
        anchors.fill: parent
        hoverEnabled: true

        property bool isPinned: false
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
            width: visualTrayCapsule.width + 48
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
                anchors.centerIn: inputStabilizerCapsule

                Taskbar {}

                Item {
                    id: placeholderContainer
                    visible: trayRepeater.count === 0
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
                    id: trayRepeater
                    model: SystemTray.items.values
                    delegate: Item {
                        id: trayItemDelegate
                        width: 64
                        height: 64
                        z: trayWindow.activeHoverIndex === index ? 10 : 1
            
                        QsMenuAnchor {
                            id: itemMenuAnchor
                            menu: modelData.menu
                            anchor.item: trayItemDelegate 
                            anchor.edges: Edges.Bottom | Edges.Left 
                            anchor.gravity: Edges.Bottom | Edges.Right
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
                            asynchronous: true
                            
                            source: {
                                let rawId = modelData.id || "";
                                if (rawId !== "") {
                                    let cleanId = rawId.split('.').pop().toLowerCase();
                                    
                                    if (cleanId.includes("signal")) {
                                        let sigPath = Quickshell.iconPath("signal-desktop", true);
                                        if (sigPath !== "") return sigPath;
                                    }
                                    if (cleanId.includes("remmina")) {
                                        let remPath = Quickshell.iconPath("org.remmina.Remmina", true);
                                        if (remPath !== "") return remPath;
                                    }
                                }
                                
                                if (modelData.iconPath) return "file://" + modelData.iconPath;
                                if (modelData.icon && modelData.icon.startsWith("image://")) return modelData.icon;
                                
                                let lookupIcon = (modelData.icon || "").replace("image://icon/", "").trim();
                                if (lookupIcon === "") return "";
                                return Quickshell.iconPath(lookupIcon);
                            }
                                    
                            opacity: (trayHitbox.isPinned || trayWindow.menuActive) ? 0.9 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }

                        // --- LOCAL ICON-ANCHORED POPUP WINDOW ---
                        // Attached directly to the item delegate with automatic translation
                        PopupWindow {
                            id: inlineTooltipPopup
                            visible: trayWindow.activeHoverIndex === index && !trayWindow.menuActive
                            
                            // Locks tracking straight to the current icon delegate context
                            anchor.item: trayItemDelegate
                            anchor.edges: Edges.Bottom
                            anchor.gravity: Edges.Bottom
                            
                            // Perfectly centers the 220px box directly under the 64px icon bounds
                            anchor.rect.x: 31
                            anchor.rect.y: 55

                            implicitWidth: 220
                            implicitHeight: 40
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: trayWindow.resolveAppName(modelData)
                                font.pointSize: 11
                                font.family: fc.mainFont
                                font.weight: Font.Normal
                                color: trayWindow.themeText
                                
                                width: parent.width - 24
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
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
