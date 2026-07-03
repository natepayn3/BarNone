import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../configs"

PanelWindow {
    id: overviewWindow

    // --- ACCELERATED LAYER CONFIGURATION ---
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-workspace-overview"
    WlrLayershell.keyboardFocus: WlrLayershell.OnDemand
    WlrLayershell.exclusionMode: WlrLayershell.Ignore

    color: fontCfg.trackBackground

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: screen && shellRoot.activeOverviewMonitor === screen.name

    // --- INTERNAL STATES & PROCESS FORK ENGINE ---
    property var liveClientJson: []

    onVisibleChanged: {
        if (visible) {
            overviewWindow.WlrLayershell.keyboardFocus = WlrLayershell.OnDemand;
            overviewContent.focus = true;
            
            Hyprland.refreshToplevels();
            Hyprland.refreshWorkspaces();
            clientQueryProcess.running = true; 
            
            let initialIdx = overviewWindow.activeWorkspaceList.indexOf(Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1);
            if (initialIdx !== -1) {
                overviewWindow.activeWorkspace = overviewWindow.activeWorkspaceList[initialIdx];
            }
        } else {
            overviewWindow.WlrLayershell.keyboardFocus = WlrLayershell.None;
            clientQueryProcess.running = false;
        }
    }

    readonly property var activeWorkspaceList: {
        let ids = [1];
        for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
            let ws = Hyprland.workspaces.values[i];
            if (ws.id > 0 && !ids.includes(ws.id)) {
                ids.push(ws.id);
            }
        }
        return ids.sort((a, b) => a - b);
    }
    
    property int activeWorkspace: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    property color colorBackground: shellConfig.colorBackground
    property color colorBorder: shellConfig.colorBorder
    property color colorAccent: shellConfig.colorAccent
    property string shellFont: shellConfig.shellFont
    property real radiusValue: shellConfig.radiusValue

    FontConfig { id: fontCfg }

    Process {
        id: clientQueryProcess
        command: ["hyprctl", "clients", "-j"]
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                let cleanText = text.trim();
                if (!cleanText || cleanText === "[]") return;
                try { 
                    overviewWindow.liveClientJson = JSON.parse(cleanText);
                } catch(e) {}
            }
        }
    }

    Connections {
        target: Hyprland
        ignoreUnknownSignals: true
        function onRawEvent(event) { 
             if (overviewWindow.visible) {
                 Hyprland.refreshToplevels();
                 Hyprland.refreshWorkspaces();
                 clientQueryProcess.running = true;
             }
        }
    }

    function getCleanIconName(className) {
        if (!className) return "application-x-executable";
        
        let scrubbed = className.replace("image://icon/", "").toLowerCase().trim();
        
        if (scrubbed.includes("remmina")) return "remmina";
        if (scrubbed.includes("chrome")) return "google-chrome";
        if (scrubbed.includes("kitty")) return "kitty";
        if (scrubbed.includes("terminal")) return "utilities-terminal";
        if (scrubbed.includes("codium")) return "vscodium";
        if (scrubbed.includes("code")) return "vscode";
        if (scrubbed.includes("signal")) return "signal-desktop";
        
        return scrubbed;
    }

    Item {
        id: overviewContent
        anchors.fill: parent
        focus: true

        // --- MATRIX KEYBOARD NAVIGATION CONTROLLER ENGINE ---
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                shellRoot.activeOverviewMonitor = "";
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Select) {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${overviewWindow.activeWorkspace}" })`);
                shellRoot.activeOverviewMonitor = "";
                event.accepted = true;
                return;
            }

            let currentIndex = overviewWindow.activeWorkspaceList.indexOf(overviewWindow.activeWorkspace);
            if (currentIndex === -1) return;

            let cols = 4;
            let totalItems = overviewWindow.activeWorkspaceList.length;
            let nextIndex = currentIndex;

            if (event.key === Qt.Key_Left) {
                if (currentIndex > 0) nextIndex = currentIndex - 1;
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                if (currentIndex < totalItems - 1) nextIndex = currentIndex + 1;
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                if (currentIndex - cols >= 0) nextIndex = currentIndex - cols;
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                if (currentIndex + cols < totalItems) nextIndex = currentIndex + cols;
                event.accepted = true;
            }

            if (nextIndex !== currentIndex) {
                overviewWindow.activeWorkspace = overviewWindow.activeWorkspaceList[nextIndex];
            }
        }

        TapHandler {
            onTapped: { shellRoot.activeOverviewMonitor = ""; }
        }

        // --- INDEPENDENT HORIZONTAL ROW STACK ---
        ColumnLayout {
            id: positioningContainer
            anchors.centerIn: parent
            spacing: 64

            Repeater {
                model: {
                    let items = overviewWindow.activeWorkspaceList;
                    let chunks = [];
                    let chunkSize = 4; 
                    for (let i = 0; i < items.length; i += chunkSize) {
                        chunks.push(items.slice(i, i + chunkSize));
                    }
                    return chunks;
                }

                // Standard Row forces horizontal positioning without cell/column sizing constraints
                delegate: Row {
                    id: rowContainer
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 64

                    Repeater {
                        model: modelData 

                        delegate: Item {
                            id: tileWrapper
                            property int currentWsId: modelData
                            property int workingWorkspace: currentWsId  
                            property bool isTargetActive: overviewWindow.activeWorkspace === workingWorkspace
                            property int activeHoverWindowIndex: -1

                            property bool isVerticalWorkspace: viewportFrame.calculatedBounds.isVertical
                            property real targetScale: isTargetActive ? 1.18 : (tileCardMouseArea.containsMouse ? 1.02 : 1.0)

                            // Clean dimensions inherited directly from your stable horizontal layout bounds
                            width: Math.round(viewportFrame.width + 74)
                            height: 440

                            Rectangle {
                                id: workspaceTile
                                width: parent.width
                                height: tileWrapper.isVerticalWorkspace ? 440 : 300
                                anchors.centerIn: parent 
                                
                                radius: overviewWindow.radiusValue
                                z: tileWrapper.isTargetActive ? 3 : 2

                                color: overviewWindow.colorBackground
                                border.color: fontCfg.borderMuted
                                border.width: 0

                                scale: tileWrapper.targetScale
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                // --- TV ANTENNA ICON ---
                                Text {
                                    id: antennaIcon
                                    text: "network_ping"
                                    font {
                                        family: fontCfg.iconFont
                                        pixelSize: 54
                                    }
                                    color: fontCfg.overlayBackground
                                    styleColor: overviewWindow.colorBackground
                                    z: 1
                                    
                                    anchors.bottom: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: -19
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 14

                                    // --- TV KNOBS (INSIDE WINDOW, LEFT SIDE) ---
                                    Column {
                                        id: tvKnobsColumn
                                        anchors.left: parent.left
                                        anchors.leftMargin: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 24
                                        spacing: 14

                                        Text {
                                            text: "clock_loader_10"
                                            font { family: fontCfg.iconFont; pixelSize: 30 }
                                            color: fontCfg.textMuted
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 30
                                            height: 30
                                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                            rotation: -45
                                        }

                                        Text {
                                            text: "clock_loader_10"
                                            font { family: fontCfg.iconFont; pixelSize: 30 }
                                            color: fontCfg.textMuted
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 30
                                            height: 30
                                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                            rotation: 45
                                        }

                                        Text {
                                            text: "density_small"
                                            font { family: fontCfg.iconFont; pixelSize: 30 }
                                            color: fontCfg.textMuted
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }

                                    // --- HEADER ROW (TITLE + RUNNING APPS) ---
                                    RowLayout {
                                        id: headerRow
                                        width: parent.width - tvKnobsColumn.width - 16
                                        height: 24 
                                        spacing: 16
                                        anchors.top: parent.top
                                        anchors.left: tvKnobsColumn.right
                                        anchors.leftMargin: 0
                                        
                                        transformOrigin: Item.Center
                                        scale: 1.0 / workspaceTile.scale

                                        Item { Layout.fillWidth: true }

                                        Row {
                                            id: centeredContent
                                            spacing: 16
                                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                            Text {
                                                id: titleLabel
                                                text: "Workspace " + workingWorkspace
                                                font.family: overviewWindow.shellFont
                                                font.pixelSize: tileWrapper.isTargetActive ? 16 : 13
                                                font.bold: true
                                                color: tileWrapper.isTargetActive ? fontCfg.textPrimary : fontCfg.textMuted
                                                anchors.verticalCenter: parent.verticalCenter
                                                Component.onCompleted: fontCfg.applyOutline(this, fontCfg.overlayBackground)
                                                
                                                Behavior on font.pixelSize { NumberAnimation { duration: 120 } }
                                            }

                                            RowLayout {
                                                id: iconContainerRow
                                                height: parent.height
                                                spacing: 8
                                                anchors.verticalCenter: parent.verticalCenter
                                            
                                                Repeater {
                                                    model: viewportFrame.workspaceWindows
                                                    delegate: Image {
                                                        visible: (modelData.class || "") !== "" && modelData.mapped
                                                        source: Quickshell.iconPath(getCleanIconName(modelData.class))
                                                        
                                                        Layout.preferredWidth: tileWrapper.isTargetActive ? 20 : 16
                                                        Layout.preferredHeight: tileWrapper.isTargetActive ? 20 : 16
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
                                        color: overviewWindow.colorBorder
                                        anchors.top: headerRow.bottom
                                        anchors.topMargin: 4
                                        anchors.left: tvKnobsColumn.right
                                        anchors.leftMargin: 16
                                    }

                                    // --- VIEWPORT STREAM ENGINE ---
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

                                        property var workspaceWindows: overviewWindow.liveClientJson.filter(w => w.workspace.id === tileWrapper.workingWorkspace)

                                        property var calculatedBounds: {
                                            if (!workspaceWindows || workspaceWindows.length === 0) {
                                                let mWidth = 1920, mHeight = 1080, mX = 0, mY = 0;
                                                let wsObj = Hyprland.workspaces.values.find(w => w.id === tileWrapper.workingWorkspace);
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
                                                let win = workspaceWindows[i];
                                                if (!win.at || !win.size) continue;
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

                                        height: workspaceTile.height - headerRow.height - 24
                                        width: Math.round(height * (calculatedBounds.w / calculatedBounds.h))
                                        
                                        property real scaleX: width / calculatedBounds.w
                                        property real scaleY: height / calculatedBounds.h

                                        Rectangle {
                                            anchors.fill: parent
                                            color: fontCfg.overlayBackground
                                            radius: 4
                                            z: 1
                                        }

                                        Repeater {
                                            id: windowRepeater
                                            model: viewportFrame.workspaceWindows
                                            delegate: Rectangle {
                                                id: windowDelegate
                                            
                                                x: Math.round((modelData.at[0] - viewportFrame.calculatedBounds.originX) * viewportFrame.scaleX)
                                                y: Math.round((modelData.at[1] - viewportFrame.calculatedBounds.originY) * viewportFrame.scaleY)
                                                width: Math.max(4, Math.round(modelData.size[0] * viewportFrame.scaleX))
                                                height: Math.max(4, Math.round(modelData.size[1] * viewportFrame.scaleY))
                                                visible: modelData.mapped
                                                z: 2
                                                
                                                color: tileWrapper.isTargetActive ? 
                                                    Qt.rgba(fontCfg.textPrimary.r, fontCfg.textPrimary.g, fontCfg.textPrimary.b, 0.15) : fontCfg.overlayBackground
                                                border.color: tileWrapper.isTargetActive ? fontCfg.textPrimary : fontCfg.borderMuted
                                                border.width: 0
                                                radius: 4

                                                property var wlToplevel: {
                                                    if (!modelData || !modelData.address) return null;
                                                    
                                                    let tracker = clientQueryProcess.running; 
                                                    let targetAddr = modelData.address.trim().toLowerCase();
                                                    
                                                    let match = Hyprland.toplevels.values.find(t => {
                                                        if (!t.lastIpcObject || !t.lastIpcObject.address) return false;
                                                        return t.lastIpcObject.address.trim().toLowerCase() === targetAddr;
                                                    });
                                                    if (match && match.wayland) return match.wayland;
                                                    return null;
                                                }

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
                                                    color: tileWrapper.isTargetActive ? fontCfg.textPrimary : "#cc11111b"
                                                    visible: parent.height > 24 && parent.width > 40
                                                    radius: 2

                                                    Text {
                                                        text: (modelData.class || "")
                                                        font.family: fontCfg.mainFont
                                                        font.pixelSize: 8
                                                        font.bold: true 
                                                        color: tileWrapper.isTargetActive ? "#000000" : fontCfg.textPrimary
                                                        anchors.centerIn: parent
                                                        width: parent.width - 4
                                                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: tileCardMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    z: 30 
                                    onClicked: {
                                        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workingWorkspace}" })`);
                                        shellRoot.activeOverviewMonitor = "";
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
