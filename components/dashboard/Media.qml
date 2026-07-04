import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../../configs"

RowLayout {
    id: mediaRoot
    spacing: mediaStatus !== "Stopped" ? 14 : 0 

    property string mediaTitle: "Not Playing"
    property string mediaArtist: "---"
    property string mediaStatus: "Stopped"
    property string mediaArtUrl: "" 
    
    // Array to store raw CAVA values (e.g., 32 bars)
    property var cavaBars: []

    Component.onCompleted: {
        mediaFollower.running = true
        cavaProc.running = true
    }

    FontConfig { id: fc }

    // --- THUMBNAIL ART CONTAINER WITH CIRCULAR CAVA ---
    Item {
    id: artContainer
    width: visible ? 130 : 0  // Increased from 110 to accommodate longer bars
    height: 130               // Increased from 110
    Layout.alignment: Qt.AlignVCenter
    visible: mediaRoot.mediaStatus !== "Stopped"

        Canvas {
            id: visualizerCanvas
            anchors.fill: parent
            antialiasing: true
            
            property real rotationAngle: 0.0

            PropertyAnimation on rotationAngle {
                from: 0.0
                to: 2 * Math.PI
                duration: 20000
                loops: Animation.Infinite
                running: mediaRoot.mediaStatus === "Playing"
            }

            onRotationAngleChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                
                if (!mediaRoot.cavaBars || mediaRoot.cavaBars.length === 0) return;
                
                var centerX = width / 2;
                var centerY = height / 2;
                var innerRadius = 37.5; 
                var barCount = mediaRoot.cavaBars.length;
                
                var maxBarLength = 20;  
                var barWidth = 3;       
                
                ctx.save();
                ctx.fillStyle = shellConfig.themeText; 
                
                for (var i = 0; i < barCount; i++) {
                    var angle = ((i * 2 * Math.PI) / barCount) + visualizerCanvas.rotationAngle;
                    var value = mediaRoot.cavaBars[i] / 255.0; 
                    var barLength = value * maxBarLength;
                    
                    ctx.save();
                    ctx.translate(centerX, centerY);
                    ctx.rotate(angle);
                    
                    var startY = innerRadius + 3;
                    var endY = startY + barLength;
                    
                    var baseRadius = barWidth / 2;
                    var tipRadius = baseRadius + (value * 2);
                    
                    ctx.beginPath();
                    ctx.moveTo(-baseRadius, startY);
                    ctx.lineTo(-tipRadius, endY);
                    ctx.arc(0, endY, tipRadius, Math.PI, 0, true); 
                    ctx.lineTo(baseRadius, startY);
                    ctx.closePath();
                    ctx.fill();
                    
                    ctx.restore();
                }
                ctx.restore();
            }
        }

        // Inner Image Container
        Item {
            width: 75
            height: 75
            anchors.centerIn: parent

            Image {
                id: artImage
                anchors.fill: parent
                source: mediaRoot.mediaArtUrl ? mediaRoot.mediaArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            Rectangle {
                id: maskTarget
                anchors.fill: parent
                radius: width / 2 // Perfect circle
                color: "black"
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: artImage
                maskSource: maskTarget
                visible: artImage.status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: "music_note"
                font.family: fc.iconFont
                font.pixelSize: 24
                color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.2)
                visible: artImage.status !== Image.Ready
            }
        }
    }

    // --- CONTROLS & TEXT BLOCK ---
    ColumnLayout {
        spacing: 6
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        Text { 
            id: titleText
            text: mediaRoot.mediaTitle
            color: shellConfig.themeText
            font.family: fc.mainFont
            font.pixelSize: 14
            font.weight: Font.Bold
            elide: Text.ElideRight
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            
            Component.onCompleted: fc.applyOutline(this, fc.overlayBackground)
        }

        Text { 
            id: artistText
            text: mediaRoot.mediaArtist
            color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.5)
            font.family: fc.mainFont
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            Component.onCompleted: fc.applyOutline(this, fc.overlayBackground)
        }

        RowLayout {
            spacing: 12
            Layout.alignment: Qt.AlignHCenter

            Item {
                implicitWidth: 24
                implicitHeight: 24
                Layout.alignment: Qt.AlignVCenter
                Text { 
                    anchors.centerIn: parent
                    text: "skip_previous"
                    font.family: fc.iconFont
                    font.pixelSize: 20
                    color: shellConfig.themeText
                    Component.onCompleted: fc.applyOutline(this, fc.overlayBackground)
                }
                MouseArea { 
                    anchors.fill: parent
                    onClicked: { mediaControlProc.command = ["playerctl", "previous"]; mediaControlProc.running = true; }
                }
            }

            Item {
                implicitWidth: 28
                implicitHeight: 28
                Layout.alignment: Qt.AlignVCenter
                Text { 
                    anchors.centerIn: parent
                    text: mediaRoot.mediaStatus === "Playing" ? "pause_circle" : "play_circle"
                    font.family: fc.iconFont
                    font.pixelSize: 26
                    color: shellConfig.themeText
                    Component.onCompleted: fc.applyOutline(this, fc.overlayBackground)
                }
                MouseArea { 
                    anchors.fill: parent
                    onClicked: { mediaControlProc.command = ["playerctl", "play-pause"]; mediaControlProc.running = true; }
                }
            }

            Item {
                implicitWidth: 24
                implicitHeight: 24
                Layout.alignment: Qt.AlignVCenter
                Text { 
                    anchors.centerIn: parent
                    text: "skip_next"
                    font.family: fc.iconFont
                    font.pixelSize: 20
                    color: shellConfig.themeText
                    Component.onCompleted: fc.applyOutline(this, fc.overlayBackground)
                }
                MouseArea { 
                    anchors.fill: parent
                    onClicked: { mediaControlProc.command = ["playerctl", "next"]; mediaControlProc.running = true; }
                }
            }
        }
    }

    Process { id: mediaControlProc; running: false }
    
    Process {
        id: mediaFollower
        command: ["playerctl", "--follow", "--format", '{"title": "{{title}}", "artist": "{{artist}}", "status": "{{status}}", "art": "{{mpris:artUrl}}"}', "metadata"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    let parsed = JSON.parse(data.trim());
                    if (parsed.status === "Stopped" || !parsed.title) {
                        mediaRoot.mediaTitle = "Not Playing";
                        mediaRoot.mediaArtist = "---"; 
                        mediaRoot.mediaStatus = "Stopped";
                        mediaRoot.mediaArtUrl = "";
                    } else {
                        mediaRoot.mediaTitle = parsed.title;
                        mediaRoot.mediaArtist = parsed.artist || "Unknown Artist";
                        mediaRoot.mediaStatus = parsed.status;
                        mediaRoot.mediaArtUrl = parsed.art || "";
                    }
                } catch(e) {}
            }
        }
    }

    // --- CAVA PROCESS ---
    // Switched to raw ASCII output mode parsed natively by SplitParser line-by-line
    Process {
        id: cavaProc
        command: ["sh", "-c", "stdbuf -o0 cava -p <(echo '[general]\nbars = 40\nsensitivity = 150\n[output]\nmethod = raw\ndata_format = ascii\nascii_max_range = 255\nbar_delimiter = 59\nframe_delimiter = 10')"]
        running: false
        
        stdout: SplitParser {
            splitMarker: "\n" // Emit onEvery clean frame line feed
            onRead: (data) => {
                let clean = data.trim();
                if (!clean) return;
                
                // CAVA appends delimiters between values (e.g., "12;45;78;")
                let points = clean.split(';');
                let arr = [];
                
                for (let i = 0; i < points.length; i++) {
                    if (points[i] !== "") {
                        arr.push(parseInt(points[i], 10) || 0);
                    }
                }
                
                if (arr.length > 0) {
                    mediaRoot.cavaBars = arr;
                    visualizerCanvas.requestPaint(); // Force 2D canvas frame render loop
                }
            }
        }
    }
}
