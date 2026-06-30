import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: audioPopupWindow

    // --- Window Configuration ---
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: visible ? WlrLayershell.OnDemand : WlrLayershell.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
        top: true
        left: true
        right: true
    }
    
    color: "transparent"

    // --- Global Theme Mapping ---
    property color colorBackground: shellConfig.colorBackground
    property color colorBorder: shellConfig.colorBorder

    // Internal flag managing the graceful scale/fade execution loop
    property bool animateActive: false

    // --- State Properties ---
    property int systemVolume: 50
    property bool isMuted: false

    // --- Fullscreen Outside Dismiss Wrapper ---
    MouseArea {
        id: outsideDismiss
        anchors.fill: parent
        onClicked: audioPopupWindow.animateActive = false // Initiates uniform collapse cycle

        // --- Main Visual Panel ---
        Rectangle {
            id: bgCard
            width: 360
            height: mainLayout.implicitHeight + 40
            transformOrigin: Item.Center
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 100
            anchors.horizontalCenter: parent.horizontalCenter
            
            color: audioPopupWindow.colorBackground
            border.color: audioPopupWindow.colorBorder
            border.width: 1
            radius: shellConfig.radiusValue

            // --- DECLARATIVE STATE ENGINE ---
            states: [
                State {
                    name: "hidden"
                    when: !audioPopupWindow.animateActive
                    PropertyChanges { target: bgCard; opacity: 0.0; scale: 0.3 }
                },
                State {
                    name: "shown"
                    when: audioPopupWindow.animateActive
                    PropertyChanges { target: bgCard; opacity: 1.0; scale: 1.0 }
                }
            ]

            transitions: [
                Transition {
                    from: "hidden"; to: "shown"
                    ParallelAnimation {
                        NumberAnimation { target: bgCard; property: "scale"; duration: shellConfig.durationIn; easing.type: Easing.OutBack; easing.amplitude: shellConfig.springBack }
                        NumberAnimation { target: bgCard; property: "opacity"; duration: shellConfig.opacityIn; easing.type: Easing.OutQuad }
                    }
                },
                Transition {
                    from: "shown"; to: "hidden"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation { target: bgCard; property: "scale"; duration: shellConfig.durationOut; easing.type: Easing.InBack; easing.amplitude: shellConfig.springIn }
                            NumberAnimation { target: bgCard; property: "opacity"; duration: shellConfig.opacityOut; easing.type: Easing.InQuad }
                        }
                        // Securely clip layout visibility after animation finishes
                        ScriptAction { script: audioPopupWindow.visible = false } 
                    }
                }
            ]

            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => mouse.accepted = true
            }

            ColumnLayout {
                id: mainLayout
                anchors.fill: parent
                anchors.margins: 22
                spacing: 20

                // --- Header Row ---
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Audio Output"
                        color: "#ffffff"
                        font.family: "Google Sans Flex"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        style: Text.Outline
                        styleColor: Qt.rgba(0, 0, 0, 0.35)
                        Layout.fillWidth: true
                    }

                    Text {
                        text: audioPopupWindow.isMuted ? "Muted" : audioPopupWindow.systemVolume + "%"
                        color: "#ffffff"
                        font.family: "Google Sans Flex"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        style: Text.Outline
                        styleColor: Qt.rgba(0, 0, 0, 0.35)
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // --- Slider Control Core ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 18

                    Text {
                        text: audioPopupWindow.isMuted ? "volume_off" : "volume_up"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 32
                        color: Qt.rgba(1, 1, 1, 0.9)
                        style: Text.Outline
                        styleColor: Qt.rgba(0, 0, 0, 0.35)
                    }

                    Slider {
                        id: volumeSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: audioPopupWindow.systemVolume

                        onMoved: {
                            audioPopupWindow.systemVolume = value;
                            if (audioPopupWindow.isMuted) audioPopupWindow.isMuted = false;
                            volumeWriteProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (value / 100).toFixed(2)];
                            volumeWriteProc.running = true;
                        }

                        background: Rectangle {
                            x: volumeSlider.leftPadding
                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 6
                            width: volumeSlider.availableWidth
                            height: implicitHeight
                            radius: 3
                            color: Qt.rgba(1, 1, 1, 0.15)

                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                color: audioPopupWindow.isMuted ? "#666666" : Qt.rgba(1, 1, 1, 0.85)
                                radius: 3
                            }
                        }

                        handle: Rectangle {
                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                            implicitWidth: 18
                            implicitHeight: 18
                            radius: 9
                            color: audioPopupWindow.isMuted ? "#999999" : "#ffffff"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.1)
                }

                // --- Routing Repeater Sink List ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        id: sinkRepeater
                        model: ListModel { id: sinkModel }

                        delegate: MouseArea {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            hoverEnabled: true
                            
                            onClicked: {
                                sinkSetProc.command = ["wpctl", "set-default", model.sinkId];
                                sinkSetProc.running = true;
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: parent.containsMouse ? Qt.rgba(0.4, 0.4, 0.4, 0.28) : "transparent"
                                border.color: parent.containsMouse ? Qt.rgba(0, 0, 0, 0.2) : "transparent"
                                border.width: 1
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14

                                Text {
                                    text: model.sinkName
                                    color: "#ffffff"
                                    font.family: "Google Sans Flex"
                                    font.pixelSize: 15
                                    font.weight: model.isDefault ? Font.DemiBold : Font.Normal
                                    opacity: model.isDefault ? 1.0 : 0.7
                                    style: Text.Outline
                                    styleColor: Qt.rgba(0, 0, 0, 0.35)
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "check"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 20
                                    color: "#ffffff"
                                    opacity: 0.95
                                    style: Text.Outline
                                    styleColor: Qt.rgba(0, 0, 0, 0.35)
                                    visible: model.isDefault
                                }
                            }
                        }
                    }
                }
            }
        }

        focus: true
        Keys.onEscapePressed: audioPopupWindow.animateActive = false
    }

    // --- Backend Audio Pipeline Drivers ---
    Process {
        id: audioEventStream
        command: [
            "sh", "-c",
            "pactl subscribe | grep --line-buffered \"Event 'change' on sink\" | while read -r _; do wpctl get-volume @DEFAULT_AUDIO_SINK@; done"
        ]
        running: true

        stdout: SplitParser {
            onRead: data => {
                let cleaned = data.trim();
                if (!cleaned.startsWith("Volume:")) return;

                let currentMutedState = cleaned.includes("[MUTED]");
                let parts = cleaned.split(" ");
                let volVal = parseFloat(parts[1]);
                
                if (!isNaN(volVal) && !volumeSlider.pressed) {
                    audioPopupWindow.systemVolume = Math.round(volVal * 100);
                    audioPopupWindow.isMuted = currentMutedState;
                }
            }
        }
    }

    Process {
        id: audioQueryProc
        command: ["wpctl", "status"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n");
                sinkModel.clear();
                let seenIds = {};
                let parsingSinks = false;

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i];
                    if (line.includes("Sinks:")) { parsingSinks = true; continue; }
                    if (parsingSinks && (line.includes("Sources:") || line.includes("Filters:") || line.includes("Streams:"))) { 
                        parsingSinks = false;
                    }

                    if (parsingSinks) {
                        let match = line.match(/(\*\s*)?\s*(\d+)\.\s+(.*)/);
                        if (match) {
                            let isDef = (match[1] !== undefined && match[1].includes("*"));
                            let id = match[2].trim();
                            
                            if (seenIds[id]) continue;
                            seenIds[id] = true;

                            let rawName = match[3].trim();
                            let name = rawName.split("[")[0].trim().replace(/[├─└─│]/g, "");
                            if (name === "") continue;

                            sinkModel.append({ isDefault: isDef, sinkId: id, sinkName: name });
                        }
                    }
                }
                audioQueryProc.queryVolume();
            }
        }

        function queryVolume() {
            volumeReadProc.running = true;
        }
    }

    Process {
        id: volumeReadProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let cleaned = this.text.trim();
                let match = cleaned.match(/Volume:\s+([0-9.]+)/);
                if (match) {
                    audioPopupWindow.systemVolume = Math.round(parseFloat(match[1]) * 100);
                    audioPopupWindow.isMuted = cleaned.includes("[MUTED]");
                }
            }
        }
    }

    Process { id: volumeWriteProc; running: false }
    
    Process { 
        id: sinkSetProc
        running: false 
        onExited: audioQueryProc.running = true
    }

    Timer {
        id: pollTimer
        interval: 3000
        running: audioPopupWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: audioQueryProc.running = true
    }

    onVisibleChanged: {
        shellRoot.audioPopupActive = visible;
        if (visible) {
            outsideDismiss.forceActiveFocus();
            pollTimer.start();
            audioPopupWindow.animateActive = true; // Safe visibility cascade kickoff
        } else {
            pollTimer.stop();
            audioPopupWindow.animateActive = false;
        }
    }
}