import QtQuick
import QtQuick.Controls
import Quickshell.Io

Item {
    id: brightnessSliderRoot
    width: parent.width
    height: 48

    property real currentBrightness: 0.0
    property string percentageText: Math.round(brightnessSliderRoot.currentBrightness * 100) + "%"

    Component.onCompleted: brightFetcher.running = true

    FontConfig { id: fc }

    // --- 1. BACKGROUND MASTER TRACK CONTAINER ---
    Rectangle {
        id: bgTrack
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.03)
        radius: height / 2
        
        // Enforce master clipping bounds so the slider fill can never escape or deform
        clip: true

        // LIGHT TEXT: Sits stationary underneath the fill bar
        Text {
            anchors.centerIn: parent
            text: brightnessSliderRoot.percentageText
            color: Qt.rgba(1, 1, 1, 0.35)
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
            
            // Map the width dynamically so 0% brightness sits exactly at the height (48px circle)
            width: parent.height + ((parent.width - parent.height) * brightnessSliderRoot.currentBrightness)
            color: "#ffffff"
            radius: height / 2
            
            // Keep it hard-pinned to the left edge of the container at all times
            anchors.left: parent.left
            anchors.leftMargin: 0
            
            // Permanent visibility: Keep it solid even at 0% to prevent the circle from disappearing
            opacity: 1.0
            clip: true 

            // DARK TEXT: Fixed relative layout calculation matching the absolute track size
            Text {
                x: (brightnessSliderRoot.width - width) / 2 - fillBar.anchors.leftMargin
                y: (brightnessSliderRoot.height - height) / 2
                
                text: brightnessSliderRoot.percentageText
                color: Qt.rgba(0, 0, 0, 0.85)
                font.family: fc.mainFont
                font.pixelSize: 13
                font.weight: Font.Bold
                
                Component.onCompleted: {
                    fc.applySmoothing(this)
                }
            }
        }

        // --- 3. DUAL-RENDERED SYSTEM ICONS (Also nested inside the master mask) ---
        // Background Icon (White/Dimmed when unfilled)
        Text {
            id: bgIcon
            text: brightnessSliderRoot.currentBrightness < 0.4 ? "light_mode" : "brightness_high"
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
                text: brightnessSliderRoot.currentBrightness < 0.4 ? "light_mode" : "brightness_high"
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
    }

    // --- 4. INTERACTION MOUSE LOGIC ---
    MouseArea {
        id: dragArea
        anchors.fill: parent

        function updateBrightness(mouseX) {
            let trackWidth = width - height;
            // Clamp the mouse registration strictly to the center coordinates of our circular boundary
            let adjustedX = mouseX - (height / 2);
            let newPct = Math.max(0.0, Math.min(1.0, adjustedX / trackWidth));
            
            brightnessSliderRoot.currentBrightness = newPct;
            // Set brightness level via brightnessctl using percentage syntax
            brightSetter.command = ["sh", "-c", "brightnessctl set " + Math.round(newPct * 100) + "%"];
            brightSetter.running = true;
        }

        onPositionChanged: (mouse) => {
            if (pressed) updateBrightness(mouse.x);
        }
        
        onClicked: (mouse) => {
            updateBrightness(mouse.x);
        }
    }

    Process { id: brightSetter; running: false } 
    
    Process {
        id: brightFetcher
        // Reads raw current vs max values to compute the precise decimal ratio
        command: ["sh", "-c", "echo $(brightnessctl get) $(brightnessctl max)"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(" ");
                if (parts.length >= 2) {
                    let current = parseFloat(parts[0]);
                    let max = parseFloat(parts[1]);
                    if (max > 0) {
                        brightnessSliderRoot.currentBrightness = current / max;
                    }
                }
                brightFetcher.running = false;
            }
        }
    }
}