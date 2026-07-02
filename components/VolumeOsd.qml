import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../configs"

PanelWindow {
    id: volumeOsdWindow

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: WlrLayershell.None
    exclusionMode: ExclusionMode.Ignore

    visible: false

    anchors {
        bottom: true
    }
    
    margins {
        bottom: 100 
    }

    implicitWidth: 360
    implicitHeight: osdLayout.implicitHeight + 44
    color: "transparent"

    property int systemVolume: 50
    property bool isMuted: false
    property bool bootComplete: false

    Timer {
        id: osdTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: volumeOsdWindow.visible = false
    }

    FontConfig { id: fc }

    Rectangle {
        id: pillCard
        anchors.fill: parent
        color: fc.trackBackground
        border.color: fc.borderMuted
        border.width: 1
        radius: 16

        RowLayout {
            id: osdLayout
            anchors.fill: parent
            anchors.margins: 22 
            spacing: 18

            Text {
                text: volumeOsdWindow.isMuted ? "volume_off" : "volume_up"
                font.family: fc.iconFont
                font.pixelSize: 32
                color: "#ffffff"
                
                Component.onCompleted: {
                    fc.applyOutline(this, fc.overlayBackground)
                }
            }

            Slider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                value: volumeOsdWindow.systemVolume
                enabled: false

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
                        color: volumeOsdWindow.isMuted ? fc.overlayForeground : "#ffffff"
                        radius: 3
                    }
                }

                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: volumeOsdWindow.isMuted ? fc.overlayForeground : "#ffffff"
                }
            }

            Text {
                text: volumeOsdWindow.isMuted ? "Muted" : volumeOsdWindow.systemVolume + "%"
                color: "#ffffff"
                font.family: fc.mainFont
                font.pixelSize: 18
                font.weight: Font.Bold
                Layout.minimumWidth: 54
                horizontalAlignment: Text.AlignRight
                
                Component.onCompleted: {
                    fc.applyOutline(this, fc.overlayBackground)
                }
            }
        }
    }

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
                
                let match = cleaned.match(/Volume:\s+([0-9.]+)/);
                if (match) {
                    let volVal = parseFloat(match[1]);
                    if (!isNaN(volVal)) {
                        let newVol = Math.round(volVal * 100);
                        let volChanged = (volumeOsdWindow.systemVolume !== newVol);
                        let muteChanged = (volumeOsdWindow.isMuted !== currentMutedState);

                        volumeOsdWindow.systemVolume = newVol;
                        volumeOsdWindow.isMuted = currentMutedState;
                        if (volumeOsdWindow.bootComplete && (volChanged || muteChanged) && !shellRoot.audioPopupActive) {
                            volumeOsdWindow.visible = true;
                            osdTimer.restart();
                        }
                    }
                }
            }
        }
    }

    Process {
        id: startupQueryProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let cleaned = this.text.trim();
                let match = cleaned.match(/Volume:\s+([0-9.]+)/);
                if (match) {
                    volumeOsdWindow.systemVolume = Math.round(parseFloat(match[1]) * 100);
                    volumeOsdWindow.isMuted = cleaned.includes("[MUTED]");
                    Qt.callLater(() => { volumeOsdWindow.bootComplete = true; });
                }
            }
        }
    }
}