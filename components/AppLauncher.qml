import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import "../configs"

Scope {
    id: launcherModuleRoot

    property alias launcherWindowObject: launcherWindow

    FontConfig { id: fc }

    property color themeBackground: shellConfig.colorBackground
    property color themeText: shellConfig.themeText
    property color themeAccent: shellConfig.themeAccent 
    property color themeBorder: shellConfig.colorBorder
    property color cardBorder: shellConfig.colorBorder
    property color colorBackground: shellConfig.colorBackground
    property color colorBorder: shellConfig.colorBorder
    
    property bool active: false
    property var targetScreen: null

    function presentOnScreen(scr) {
        targetScreen = scr;
        launcherWindow.screen = scr;
        active = true;
    }
  
    onActiveChanged: {
        if (active) {
            launcherWindow.visible = true;
        } else {
            targetScreen = null;
        }
    }

    signal closeRequested()
    onCloseRequested: launcherModuleRoot.active = false

    // --- NATIVE IPC ROUTING MATRIX ---
    IpcHandler {
        target: "launcher"
        
        // Toggles the launcher overlay visibility state
        function toggle(): void {
            launcherModuleRoot.active = !launcherModuleRoot.active;
        }

        // Directly open the menu and force launch an executable target payload string
        function launch(execStr: string): void {
            launcherWindow.launchApp(execStr);
        }
    }

    PanelWindow {
        id: launcherWindow
        visible: false
        WlrLayershell.namespace: "quickshell-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrLayershell.OnDemand
        exclusionMode: ExclusionMode.Ignore 

        anchors { left: true; right: true; top: true; bottom: true } 
        color: "transparent"

        property var allApps: []
        property var filteredApps: []
        property var localPins: []

        FileView {
            id: pinCacheReader
            path: Quickshell.env("HOME") + "/.cache/quickshell_launcher_pins.json" 
            onTextChanged: {
                let cleanText = text().trim();
                if (!cleanText || cleanText === "[]") return; 
                try {
                    let parsed = JSON.parse(cleanText);
                    if (parsed && parsed.pins) { 
                        launcherWindow.localPins = parsed.pins;
                        launcherWindow.updateModel(); 
                    }
                } catch(e) {}
            }
        }

        function togglePin(appPath) {
            let currentPins = launcherWindow.localPins.slice();
            let idx = currentPins.indexOf(appPath); 
            if (idx !== -1) {
                currentPins.splice(idx, 1);
            } else { 
                currentPins.push(appPath);
            } 
            launcherWindow.localPins = currentPins;
            launcherWindow.updateModel();
            let jsonStr = JSON.stringify({ "pins": currentPins }); 
            Quickshell.execDetached(["fish", "-c", "echo '" + jsonStr + "' > ~/.cache/quickshell_launcher_pins.json"]);
        } 

        Process {
            id: appFetcher
            command: ["python", "-c", `
import os, glob, json

apps = []
fallback_options = [
    "/usr/share/pixmaps/archlinux-logo.png",
    "/usr/share/icons/hicolor/48x48/apps/utilities-terminal.png"
]
fallback = next((p for p in fallback_options if os.path.isfile(p)), "")

icon_dirs = [
    os.path.expanduser("~/.local/share/icons"),
    "/usr/share/icons/hicolor",
    "/usr/share/icons/Papirus",
    "/usr/share/icons",
    "/usr/share/pixmaps"
]

for folder in ["/usr/share/applications", os.path.expanduser("~/.local/share/applications")]:
    for path in glob.glob(os.path.join(folder, "**/*.desktop"), recursive=True):
        if not os.path.isfile(path): continue
        name, exec_cmd, icon, desc, nodisplay = "", "", "", "", False
        try:
            with open(path, "r", errors="ignore") as f:
                for line in f:
                    if line.startswith("Name=") and not name: name = line[5:].strip()
                    elif line.startswith("Exec=") and not exec_cmd: exec_cmd = line[5:].strip()
                    elif line.startswith("Icon=") and not icon: icon = line[5:].strip().split("?")[0]
                    elif line.startswith("Comment=") and not desc: desc = line[8:].strip()
                    elif line.startswith("NoDisplay=true"): nodisplay = True
        except: continue

        if nodisplay or not name or not exec_cmd: continue

        resolved = fallback
        if icon:
            if icon.startswith("/"):
                if os.path.isfile(icon): resolved = icon
            else:
                found = False
                for base in icon_dirs:
                    if found: break
                    for root, dirs, files in os.walk(base):
                        for ext in [".svg", ".png", ".xpm"]:
                            p = os.path.join(root, icon + ext)
                            if os.path.isfile(p):
                                resolved = p
                                found = True
                                break
                        if found: break

        apps.append({
            "name": name.replace("\\x22", "").replace("\\\\", ""),
            "exec": exec_cmd.replace("\\x22", "").replace("\\\\", ""),
            "icon": "file://" + resolved if resolved and not resolved.startswith("file://") else "file://" + fallback,
            "desc": desc.replace("\\x22", "").replace("\\\\", "") if desc else "Application",
            "path": path
        })

print(json.dumps(apps))
            `]
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        launcherWindow.allApps = JSON.parse(this.text);
                        launcherWindow.updateModel();
                    } catch(e) {}
                }
            }
        }

        function updateModel() {
            let query = searchInput.text.trim().toLowerCase();
            let pins = []; 
            let others = [];

            for (let i = 0; i < launcherWindow.allApps.length; i++) {
                let app = launcherWindow.allApps[i];
                if (query !== "" && !app.name.toLowerCase().includes(query) && !app.desc.toLowerCase().includes(query)) continue; 
                if (launcherWindow.localPins.includes(app.path)) {
                    pins.push(app);
                } else { 
                    others.push(app);
                } 
            }

            pins.sort((a,b) => a.name.localeCompare(b.name));
            others.sort((a,b) => a.name.localeCompare(b.name)); 
            launcherWindow.filteredApps = pins.concat(others);
            
            appListView.currentIndex = 0;
            appListView.positionViewAtBeginning();
        } 

        function launchApp(execString) {
            let cleanExec = execString.replace(/%[uUfFkKcCiI]/g, "").trim();
            Hyprland.dispatch(`hl.dsp.exec_cmd("${cleanExec}")`);
            launcherModuleRoot.closeRequested();
        }

        onVisibleChanged: {
            if (visible) {
                appFetcher.running = true; // Trigger every time it opens
                searchInput.text = ""; 
                searchInput.forceActiveFocus();
                pinCacheReader.reload();
                updateModel();
            }
        }

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onPressed: (mouse) => {
                launcherModuleRoot.closeRequested();
                mouse.accepted = false;  
            }
        }

        Item {
            id: launcherCardFrame
            width: shellConfig.launcherWidth
            height: 540 
            transformOrigin: Item.Center 
            anchors.bottom: parent.bottom
            anchors.bottomMargin: shellConfig.panelBottomMargin
            anchors.horizontalCenter: parent.horizontalCenter

            // --- Standalone Top App Icon ---
            Text {
                id: leftAppIcon
                text: "terminal_2"
                font.family: fc.iconFont
                font.pixelSize: 125
                color: launcherModuleRoot.themeBackground
                styleColor: colorBackground
                anchors.right: parent.left
                anchors.rightMargin: -10
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 0
            }

            // --- Standalone Right App Icon ---
            Text {
                id: rightAppIcon
                text: "terminal_2"
                font.family: fc.iconFont
                font.pixelSize: 125
                color: launcherModuleRoot.themeBackground
                styleColor: colorBackground
                anchors.left: parent.right
                anchors.leftMargin: -10
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 0
                transform: Scale { 
                    origin.x: rightAppIcon.width / 2
                    xScale: -1 
                }
            } 

            // --- DECLARATIVE STATE ENGINE ---
            states: [
                State { 
                    name: "hidden"
                    when: !launcherModuleRoot.active
                    PropertyChanges { target: launcherCardFrame; opacity: 0.0; scale: 0.3 } 
                },
                State {
                    name: "shown"
                    when: launcherModuleRoot.active
                    PropertyChanges { target: launcherCardFrame; opacity: 1.0; scale: 1.0 } 
                }
            ]

            transitions: [
                Transition {
                    from: "hidden"; to: "shown"
                    ParallelAnimation {
                        NumberAnimation { target: launcherCardFrame; property: "scale"; duration: shellConfig.durationIn; easing.type: Easing.OutBack; easing.amplitude: shellConfig.springBack }
                        NumberAnimation { target: launcherCardFrame; property: "opacity"; duration: shellConfig.opacityIn; easing.type: Easing.OutQuad }
                    }
                },
                Transition {
                    from: "shown"; to: "hidden"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation { target: launcherCardFrame; property: "scale"; duration: shellConfig.durationOut; easing.type: Easing.InBack; easing.amplitude: shellConfig.springIn }
                            NumberAnimation { target: launcherCardFrame; property: "opacity"; duration: shellConfig.opacityOut; easing.type: Easing.InQuad }
                        }
                        ScriptAction { script: launcherWindow.visible = false } 
                    }
                }
            ]

            Rectangle {
                id: cardMainBody 
                anchors.fill: parent
                color: launcherModuleRoot.themeBackground
                radius: 16 
                visible: false 
            }

            MultiEffect {
                id: cardShadow
                anchors.fill: cardMainBody
                source: cardMainBody
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowBlur: 0
                shadowVerticalOffset: 0
                shadowHorizontalOffset: 0
            }

            Rectangle {
                id: cardBorderOverlay
                anchors.fill: parent
                color: "transparent"
                radius: 16
                antialiasing: true
                border.color: launcherModuleRoot.themeBorder
                border.width: 1
            }

            Rectangle {
                id: layoutContentWrapper 
                anchors.fill: parent
                color: "transparent"
                radius: 16
                clip: true

                Item {
                    anchors.fill: parent
                    anchors.margins: 22

                    ColumnLayout {
                        id: mainLayout
                        anchors.fill: parent
                        spacing: 20 

                        // --- Header Title Row matching Module Specifications ---
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Applications"
                                color: launcherModuleRoot.themeText // 🌟 Map cleanly to component color targets
                                font.family: shellConfig.shellFont
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "terminal"
                                color: launcherModuleRoot.themeText // 🌟 Map cleanly to component color targets
                                font.family: fc.iconFont
                                font.pixelSize: 40
                                font.weight: Font.ExtraLight
                                verticalAlignment: Text.AlignVCenter
                                Layout.preferredHeight: 18
                            }
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true 
                            Layout.preferredHeight: 46 
                            placeholderText: "Search apps..."
                            font.family: shellConfig.shellFont
                            font.pixelSize: 20 
                            color: launcherModuleRoot.themeText
                            // 🌟 Swapped hardcoded translucent white for 30% alpha of your custom picker themeText color
                            placeholderTextColor: Qt.rgba(launcherModuleRoot.themeText.r, launcherModuleRoot.themeText.g, launcherModuleRoot.themeText.b, 0.3)
                            selectByMouse: true
                            verticalAlignment: TextInput.AlignVCenter 

                            background: Rectangle { 
                                color: Qt.rgba(0, 0, 0, 0.15) 
                                border.color: searchInput.activeFocus ? launcherModuleRoot.themeAccent : launcherModuleRoot.themeBorder 
                                border.width: 1
                                radius: 10 
                            }

                            onTextChanged: launcherWindow.updateModel() 

                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Down) {
                                    appListView.incrementCurrentIndex();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    appListView.decrementCurrentIndex();
                                    event.accepted = true; 
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (appListView.currentItem) {
                                        launcherWindow.launchApp(appListView.currentItem.appExec);
                                    } 
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) { 
                                    launcherModuleRoot.closeRequested();
                                    event.accepted = true; 
                                }
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true 
                            clip: true

                            ListView {
                                id: appListView
                                spacing: 4 
                                keyNavigationEnabled: false
                                model: launcherWindow.filteredApps 
                                
                                delegate: ItemDelegate {
                                    id: appDelegate
                                    width: appListView.width 
                                    height: 56 
                                    highlighted: appListView.currentIndex === index 
                                    
                                    property string appExec: modelData.exec
                                    property bool isPinned: launcherWindow.localPins.includes(modelData.path)

                                    background: Rectangle { 
                                        color: appDelegate.highlighted
                                            ? launcherModuleRoot.themeAccent 
                                            // 🌟 Bound the secondary item background hover layout to 5% alpha themeText mix
                                            : (appDelegate.hovered ? Qt.rgba(launcherModuleRoot.themeText.r, launcherModuleRoot.themeText.g, launcherModuleRoot.themeText.b, 0.05) : "transparent")
                                        border.color: appDelegate.highlighted ? launcherModuleRoot.cardBorder : "transparent"
                                        border.width: 1
                                        radius: 10 
                                    } 

                                    contentItem: RowLayout {
                                        spacing: 12

                                        Image { 
                                            Layout.preferredWidth: 28 
                                            Layout.preferredHeight: 28
                                            sourceSize.width: 56 
                                            sourceSize.height: 56
                                            source: modelData.icon ? modelData.icon : "file:///usr/share/icons/hicolor/scalable/apps/utilities-terminal.svg"
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true 
                                            spacing: 1
                                            Layout.alignment: Qt.AlignVCenter 

                                            Text { 
                                                text: modelData.name
                                                font.family: fc.mainFont 
                                                font.pixelSize: 16
                                                color: launcherModuleRoot.themeText 
                                                font.weight: appDelegate.isPinned ? Font.Bold : Font.Normal 
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: modelData.desc !== "" ? modelData.desc : "Application" 
                                                font.family: fc.mainFont
                                                font.pixelSize: 14
                                                // 🌟 Bound muted info secondary labels dynamically to 50% alpha themeText color blend
                                                color: Qt.rgba(launcherModuleRoot.themeText.r, launcherModuleRoot.themeText.g, launcherModuleRoot.themeText.b, 0.5)
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            text: "keep" 
                                            font.family: fc.iconFont
                                            font.pixelSize: 18
                                            color: launcherModuleRoot.themeText
                                            visible: appDelegate.isPinned 
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.rightMargin: 4
                                        }
                                    } 

                                    MouseArea {
                                        anchors.fill: parent 
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton 
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true

                                        property int lastScreenX: -1 
                                        property int lastScreenY: -1

                                        onPositionChanged: (mouse) => { 
                                            let currentX = Math.floor(mouse.screenX);
                                            let currentY = Math.floor(mouse.screenY);

                                            let deltaX = Math.abs(currentX - lastScreenX); 
                                            let deltaY = Math.abs(currentY - lastScreenY);
                                            if (lastScreenX !== -1 && (deltaX > 2 || deltaY > 2)) {
                                                if (appListView.currentIndex !== index) { 
                                                    appListView.currentIndex = index;
                                                }
                                            }
                                            
                                            lastScreenX = currentX;
                                            lastScreenY = currentY; 
                                        }

                                        onExited: {
                                            lastScreenX = -1;
                                            lastScreenY = -1; 
                                        }

                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.RightButton) {
                                                launcherWindow.togglePin(modelData.path);
                                            } else { 
                                                launcherWindow.launchApp(modelData.exec);
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
    }
}
