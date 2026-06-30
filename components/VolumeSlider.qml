import QtQuick
import QtQuick.Controls
import Quickshell.Io

Item {
    id: volumeSliderRoot
    width: parent.width
    height: 48

    property real currentVolume: 0.0
    property string percentageText: Math.round(volumeSliderRoot.currentVolume * 100) + "%"

    Component.onCompleted: volFetcher.running = true

    FontConfig { id: fc }

    // --- 1. BACKGROUND TRACK (The empty part) ---
    Rectangle {
        id: bgTrack
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.03)
        radius: height / 2

        // LIGHT TEXT: Sits stationary underneath the fill bar
        Text {
            anchors.centerIn: parent
            text: volumeSliderRoot.percentageText
            color: Qt.rgba(1, 1, 1, 0.35)
            font.family: fc.mainFont
            font.pixelSize: 13
            font.weight: Font.Bold
            
            Component.onCompleted: {
                fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
            }
        }
    }

    // --- 2. FILL BAR (The colored part that clips) ---
    Rectangle {
        id: fillBar
        height: parent.height
        width: volumeSliderRoot.width * volumeSliderRoot.currentVolume
        color: "#ffffff"
        radius: height / 2
        
        // 🎯 THE CLIPPING MAGIC
        clip: true 

        // DARK TEXT: Absolutely positioned relative to the root frame size
        Text {
            x: (volumeSliderRoot.width - width) / 2
            y: (volumeSliderRoot.height - height) / 2
            
            text: volumeSliderRoot.percentageText
            color: Qt.rgba(0, 0, 0, 0.85)
            font.family: fc.mainFont
            font.pixelSize: 13
            font.weight: Font.Bold
            
            Component.onCompleted: {
                fc.applySmoothing(this)
            }
        }
    }

    // --- 3. DUAL-RENDERED SYSTEM ICONS ---
    // Background Icon (White/Dimmed when unfilled)
    Text {
        id: bgIcon
        text: volumeSliderRoot.currentVolume === 0 ? "volume_off" : (volumeSliderRoot.currentVolume < 0.4 ? "volume_down" : "volume_up")
        font.family: fc.iconFont
        font.pixelSize: 18
        color: Qt.rgba(1, 1, 1, 0.4)
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        
        Component.onCompleted: {
            fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
        }
    }

    // Foreground Icon (Dark overlay clipped right inside the moving bar)
    Item {
        height: parent.height
        width: fillBar.width
        clip: true

        Text {
            text: volumeSliderRoot.currentVolume === 0 ? "volume_off" : (volumeSliderRoot.currentVolume < 0.4 ? "volume_down" : "volume_up")
            font.family: fc.iconFont
            font.pixelSize: 18
            color: Qt.rgba(0, 0, 0, 0.75)
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            
            Component.onCompleted: {
                fc.applySmoothing(this)
            }
        }
    }

    // --- 4. INTERACTION MOUSE LOGIC ---
    MouseArea {
        id: dragArea
        anchors.fill: parent

        function updateVolume(mouseX) {
            let newPct = Math.max(0.0, Math.min(1.0, mouseX / width));
            volumeSliderRoot.currentVolume = newPct;
            volSetter.command = ["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + newPct.toFixed(2)];
            volSetter.running = true;
        }

        onPositionChanged: (mouse) => {
            if (pressed) updateVolume(mouse.x);
        }
        
        onClicked: (mouse) => {
            updateVolume(mouse.x);
        }
    }

    Process { id: volSetter; running: false } 
    
    Process {
        id: volFetcher
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(" ");
                if (parts.length >= 2) {
                    volumeSliderRoot.currentVolume = parseFloat(parts[1]);
                }
                volFetcher.running = false;
            }
        }
    }
}