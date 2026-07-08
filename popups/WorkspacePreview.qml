import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../configs"

Item {
    id: previewRoot

    signal closeRequested()

    property int targetWorkspace: -1 
    property bool active: false
    
    property int stagedWorkspace: -1

    property int currentActiveWorkspace: -1
    property int workingWorkspace: -1

    property bool isHovered: globalTrackingArea.containsMouse || contentHoverHandler.hovered

    property var rootWindow: Quickshell.window
    property var resolvedIconPaths: ({})

    // --- SYSTEM THEME MATRIX ---
    property color colorBackground: shellConfig.colorBackground
    property color colorBorder: shellConfig.colorBorder
    property color colorAccent: shellConfig.colorAccent
    property string shellFont: shellConfig.shellFont
    property real radiusValue: shellConfig.radiusValue

    FontConfig { id: fc }

    property bool isVerticalWorkspace: viewportFrame.calculatedBounds.isVertical
    property real maxCardWidth: viewportFrame.width + 74
    property real maxCardHeight: isVerticalWorkspace ? 440 : 300

    implicitWidth: Math.round(maxCardWidth)
    implicitHeight: 440

    width: implicitWidth
    height: implicitHeight
    
    Behavior on width { 
        id: widthMorphBehavior
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on height { 
        id: heightMorphBehavior
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    opacity: 1.0
    visible: true
    clip: false

    onTargetWorkspaceChanged: {
        if (targetWorkspace !== -1) {
            debounceTimer.restart();
        } else {
            debounceTimer.stop();
            previewRoot.active = false;
        }
    }

    Timer {
        id: debounceTimer
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            if (previewRoot.targetWorkspace !== -1) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
                
                previewRoot.workingWorkspace = previewRoot.targetWorkspace;
                previewRoot.active = true;
                iconFinderProcess.running = true;
            }
        }
    }

    // Purely generic Python filesystem search matching your workspace overview and AppLauncher logic
    Process {
        id: iconFinderProcess
        running: false
        command: {
            let classes = [];
            let windows = viewportFrame.workspaceWindows;
            for (let i = 0; i < windows.length; i++) {
                let cls = windows[i].lastIpcObject ? windows[i].lastIpcObject.class : "";
                if (cls && !classes.includes(cls)) classes.push(cls);
            }
            return ["python", "-c", `
import os, sys, json

class_list = json.loads(sys.argv[1])
icon_dirs = [
    os.path.expanduser("~/.local/share/icons"),
    "/usr/share/icons/hicolor",
    "/usr/share/icons/Papirus",
    "/usr/share/icons",
    "/usr/share/pixmaps"
]

resolved_map = {}

for cl in class_list:
    scrubbed = cl.replace("image://icon/", "").lower().strip()
    if "." in scrubbed:
        scrubbed = scrubbed.split(".")[-1]
        
    found = False
    for base in icon_dirs:
        if found: break
        if not os.path.isdir(base): continue
        for root, dirs, files in os.walk(base):
            for ext in [".svg", ".png", ".xpm"]:
                p = os.path.join(root, scrubbed + ext)
                if os.path.isfile(p):
                    resolved_map[cl] = "file://" + p
                    found = True
                    break
            if found: break
print(json.dumps(resolved_map))
`, JSON.stringify(classes)]
        }
        stdout: StdioCollector {
            onTextChanged: {
                let cleanText = text.trim();
                if (!cleanText || cleanText === "{}") return;
                try {
                    previewRoot.resolvedIconPaths = JSON.parse(cleanText);
                } catch(e) {}
            }
        }
    }

    Item {
        id: animatedGroup
        anchors.fill: parent

        opacity: previewRoot.active ? 1.0 : 0.0
        x: previewRoot.active ? 0 : -50
        visible: true

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        
        Behavior on x { 
            id: exitXAnimation
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic } 
        }
        
        Rectangle {
            id: cardMainBody
            width: parent.width
            height: previewRoot.isVerticalWorkspace ? 440 : 300
            anchors.centerIn: parent
            color: previewRoot.colorBackground
            z: 2
            radius: previewRoot.radiusValue
        }

        Text {
            id: antennaIcon
            text: "network_ping"
            font {
                family: fc.iconFont
                pixelSize: 54
            }
            color: shellConfig.colorBackground
            styleColor: colorBackground
            z: 1
            anchors.bottom: cardMainBody.top
            anchors.horizontalCenter: cardMainBody.horizontalCenter
            anchors.bottomMargin: -19
        }

        Item {
            id: borderClippingMask
            anchors.fill: cardMainBody
            clip: false 
            z: 4

            Rectangle {
                id: borderFrame
                anchors.fill: parent
                color: "transparent"
                border.color: previewRoot.colorBorder
                border.width: 0
                radius: previewRoot.radiusValue
            }
        }

        MouseArea { 
            id: globalTrackingArea
            anchors.fill: parent 
            hoverEnabled: true 
            acceptedButtons: Qt.LeftButton 
            enabled: previewRoot.active 
            onClicked: {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${previewRoot.workingWorkspace}" })`);
                previewRoot.closeRequested();
            }
            z: 4
        }

        Item {
            id: layoutContentWrapper
            anchors.fill: cardMainBody
            opacity: previewRoot.active ? 1.0 : 0.0 
            z: 5

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

            HoverHandler {
                id: contentHoverHandler
            }

            Item {
                anchors.fill: parent
                anchors.margins: 14

                Column {
                    id: tvKnobsColumn
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    spacing: 14

                    Text {
                        text: "clock_loader_10"
                        font { family: fc.iconFont; pixelSize: 30 }
                        color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.4)
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 30
                        height: 30
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        rotation: -45
                    }

                    Text {
                        text: "clock_loader_10"
                        font { family: fc.iconFont; pixelSize: 30 }
                        color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.4)
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 30
                        height: 30
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        rotation: 45
                    }

                    Text {
                        text: "density_small"
                        font { family: fc.iconFont; pixelSize: 30 }
                        color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.4)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                RowLayout {
                    id: headerRow
                    width: parent.width - tvKnobsColumn.width - 16
                    height: 24
                    spacing: 16
                    anchors.top: parent.top
                    anchors.left: tvKnobsColumn.right
                    anchors.leftMargin: 0

                    Item { Layout.fillWidth: true }

                    Row {
                        id: centeredContent
                        spacing: 16
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                        Text {
                            id: titleLabel
                            text: previewRoot.workingWorkspace !== -1 ? "Workspace " + previewRoot.workingWorkspace : ""
                            font.family: previewRoot.shellFont
                            font.pixelSize: 13
                            font.bold: true
                            color: shellConfig.themeText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        RowLayout {
                            id: iconContainerRow
                            height: parent.height
                            spacing: 8
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: viewportFrame.workspaceWindows
                                delegate: Image {
                                    property string currentClass: (modelData && modelData.lastIpcObject) ? (modelData.lastIpcObject.class || "") : ""
                                    property string resolvedPath: (currentClass !== "" && previewRoot.resolvedIconPaths) ? (previewRoot.resolvedIconPaths[currentClass] || "") : ""
                                    
                                    visible: modelData && modelData.lastIpcObject && currentClass !== "" && resolvedPath !== ""
                                    source: resolvedPath
                                    
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    Layout.alignment: Qt.AlignVCenter
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    smooth: true
                                    mipmap: true
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Rectangle {
                    id: headerDivider
                    width: parent.width - tvKnobsColumn.width - 16
                    height: 1
                    color: previewRoot.colorBorder
                    anchors.top: headerRow.bottom
                    anchors.topMargin: 4
                    anchors.left: tvKnobsColumn.right
                    anchors.leftMargin: 16
                }

                Rectangle {
                    id: viewportFrame
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: (tvKnobsColumn.width + 20) / 2
                    anchors.top: headerDivider.bottom
                    anchors.topMargin: 8
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    color: "transparent" 
                    radius: 4
                    clip: true
                    z: 10

                    property var workspaceWindows: Hyprland.toplevels.values.filter(w => {
                        return w.workspace && w.workspace.id === previewRoot.workingWorkspace;
                    })

                    property var calculatedBounds: {
                        if (previewRoot.workingWorkspace === -1 || !workspaceWindows || workspaceWindows.length === 0) {
                            let mWidth = 1920, mHeight = 1080, mX = 0, mY = 0;
                            let wsObj = Hyprland.workspaces.values.find(w => w.id === previewRoot.workingWorkspace);
                            let targetMonitor = wsObj ? wsObj.monitor : Hyprland.activeMonitor;
                            if (targetMonitor) {
                                let scale = targetMonitor.scale > 0 ? targetMonitor.scale : 1.0;
                                mWidth = Math.round(targetMonitor.width / scale);
                                mHeight = Math.round(targetMonitor.height / scale);
                                mX = targetMonitor.x;
                                mY = targetMonitor.y;
                            }
                            return { "w": mWidth, "h": mHeight, "isVertical": mHeight > mWidth, "originX": mX, "originY": mY };
                        }

                        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
                        for (let i = 0; i < workspaceWindows.length; i++) {
                            let win = workspaceWindows[i].lastIpcObject;
                            if (!win || !win.at || !win.size) continue;

                            if (win.at[0] < minX) minX = win.at[0];
                            if (win.at[1] < minY) minY = win.at[1];
                            if ((win.at[0] + win.size[0]) > maxX) maxX = win.at[0] + win.size[0];
                            if ((win.at[1] + win.size[1]) > maxY) maxY = win.at[1] + win.size[1];
                        }

                        let spanX = maxX - minX;
                        let spanY = maxY - minY;
                        let verticalDetected = spanY > spanX;
                        
                        let normW = verticalDetected ? 1080 : 1920;
                        let normH = verticalDetected ? 1920 : 1080;
                        
                        if (spanX > 0 && Math.abs(spanX - normW) > 100) normW = spanX;
                        if (spanY > 0 && Math.abs(spanY - normH) > 100) normH = spanY;
                        return { "w": normW, "h": normH, "isVertical": verticalDetected, "originX": minX, "originY": minY };
                    }

                    height: cardMainBody.height - headerRow.height - 24
                    width: Math.round(height * (calculatedBounds.w / calculatedBounds.h))
                    property real scaleX: width / calculatedBounds.w
                    property real scaleY: height / calculatedBounds.h

                    Rectangle {
                        anchors.fill: parent
                        color: shellConfig.colorBackground
                        radius: 4
                        z: 1
                    }

                    Repeater {
                        model: viewportFrame.workspaceWindows
                        delegate: Rectangle {
                            id: windowDelegate
                        
                            x: modelData.lastIpcObject && modelData.lastIpcObject.at ? Math.round((modelData.lastIpcObject.at[0] - viewportFrame.calculatedBounds.originX) * viewportFrame.scaleX) : 0
                            y: modelData.lastIpcObject && modelData.lastIpcObject.at ? Math.round((modelData.lastIpcObject.at[1] - viewportFrame.calculatedBounds.originY) * viewportFrame.scaleY) : 0
                            width: modelData.lastIpcObject && modelData.lastIpcObject.size ? Math.max(4, Math.round(modelData.lastIpcObject.size[0] * viewportFrame.scaleX)) : 4
                            height: modelData.lastIpcObject && modelData.lastIpcObject.size ? Math.max(4, Math.round(modelData.lastIpcObject.size[1] * viewportFrame.scaleY)) : 4
                            visible: modelData.lastIpcObject ? true : false
                            z: 2
                            
                            color: shellConfig.colorBackground
                            border.color: fc.borderMuted
                            border.width: 0
                            radius: 4

                            property var wlToplevel: modelData.wayland ? modelData.wayland : null

                            Loader {
                                anchors.fill: parent
                                anchors.margins: 1
                                active: windowDelegate.wlToplevel !== null
                                asynchronous: true 
                                
                                opacity: status === Loader.Ready ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                sourceComponent: Component {
                                    ScreencopyView {
                                        captureSource: windowDelegate.wlToplevel
                                        live: true
                                        paintCursor: false
                                    }
                                }
                            }

                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                height: Math.min(16, parent.height * 0.3)
                                color: "#cc11111b"
                                visible: parent.height > 24 && parent.width > 40
                                radius: 2

                                Text {
                                    text: modelData.lastIpcObject ? (modelData.lastIpcObject.class || "") : ""
                                    font.family: fc.mainFont
                                    font.pixelSize: 8;
                                    font.bold: true 
                                    color: shellConfig.themeText
                                    anchors.centerIn: parent
                                    width: parent.width - 4;
                                    elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
