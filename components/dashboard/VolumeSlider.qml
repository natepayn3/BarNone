import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../../configs"

Item {
    id: volumeSliderRoot
    width: parent.width
    height: 48

    property real currentVolume: 0.0
    property string percentageText: Math.round(volumeSliderRoot.currentVolume * 100) + "%"

    Component.onCompleted: volFetcher.running = true

    Timer {
        id: volPollTimer
        interval: 150 // Snappy enough to feel instant, slow enough to sleep on CPU
        repeat: true
        running: !dragArea.pressed // Don't fight the user's mouse while dragging
        triggeredOnStart: true
        onTriggered: {
            if (!volFetcher.running) {
                volFetcher.running = true;
            }
        }
    }

    FontConfig { id: fc }

    // --- 1. BACKGROUND MASTER TRACK CONTAINER ---
    Rectangle {
        id: bgTrack
        anchors.fill: parent
        color: fc.trackBackground
        border.width: 1
        border.color: fc.borderMuted
        radius: height / 2
        clip: true

        Text {
            anchors.centerIn: parent
            text: volumeSliderRoot.percentageText
            color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.35)
            font.family: fc.mainFont
            font.pixelSize: 13
            font.weight: Font.Bold
            
            Component.onCompleted: {
                fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
            }
        }

        // --- 2. FILL BAR (Nested cleanly inside the background container) ---
        Rectangle {
            id: fillBar
            height: parent.height
            
            width: parent.height + ((parent.width - parent.height) * volumeSliderRoot.currentVolume)
            color: shellConfig.themeText
            radius: height / 2
            anchors.left: parent.left
            anchors.leftMargin: 0
            opacity: 1.0
            clip: true 

            // DARK TEXT: Fixed relative layout calculation matching the absolute track size
            Text {
                x: (volumeSliderRoot.width - width) / 2 - fillBar.anchors.leftMargin
                y: (volumeSliderRoot.height - height) / 2
                
                text: volumeSliderRoot.percentageText
                color: fc.overlayForeground
                font.family: fc.mainFont
                font.pixelSize: 13
                font.weight: Font.Bold
            }
        }

        // --- 3. DUAL-RENDERED SYSTEM ICONS (Also nested inside the master mask) ---
        // Background Icon (White/Dimmed when unfilled)
        Text {
            id: bgIcon
            visible: fillBar.width < (x + width)
            text: volumeSliderRoot.currentVolume === 0 ? "volume_off" : (volumeSliderRoot.currentVolume < 0.4 ? "volume_down" : "volume_up")
            font.family: fc.iconFont
            font.pixelSize: 24
            color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.4)
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
           
            verticalAlignment: Text.AlignVCenter

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: fc.overlayForeground
                anchors.centerIn: parent
                visible: volumeSliderRoot.currentVolume === 0.0
            }
        }

        // Foreground Icon (Dark overlay clipped right inside the moving bar)
        Item {
            height: parent.height
            width: fillBar.width
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: volumeSliderRoot.currentVolume === 0 ? "volume_off" : (volumeSliderRoot.currentVolume < 0.4 ? "volume_down" : "volume_up")
                font.family: fc.iconFont
                font.pixelSize: 24
                color: fc.overlayForeground
                verticalAlignment: Text.AlignVCenter
                x: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // --- 4. INTERACTION MOUSE LOGIC ---
    MouseArea {
        id: dragArea
        anchors.fill: parent

        function updateVolume(mouseX) {
            let trackWidth = width - height;
            let adjustedX = mouseX - (height / 2);
            let newPct = Math.max(0.0, Math.min(1.0, adjustedX / trackWidth));
            
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
