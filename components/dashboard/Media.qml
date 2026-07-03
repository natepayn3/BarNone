import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../../configs"

RowLayout {
    id: mediaRoot
    spacing: mediaStatus !== "Stopped" ? 14 : 0 // Remove spacing if hidden to maintain perfect centering

    property string mediaTitle: "Not Playing"
    property string mediaArtist: "---"
    property string mediaStatus: "Stopped"
    property string mediaArtUrl: "" 

    Component.onCompleted: mediaFollower.running = true

    FontConfig { id: fc }

    // --- THUMBNAIL ART CONTAINER WITH ROUNDED EDGES ---
    Item {
        id: artContainer
        width: visible ? 75 : 0 // Collapse width when hidden
        height: 75
        Layout.alignment: Qt.AlignVCenter
        visible: mediaRoot.mediaStatus !== "Stopped" // Hide entirely when not playing

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
            radius: 12
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
            color: Qt.rgba(1, 1, 1, 0.2)
            visible: artImage.status !== Image.Ready
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
            color: "#ffffff"
            font.family: fc.mainFont
            font.pixelSize: 14
            font.weight: Font.Bold
            elide: Text.ElideRight
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            
            Component.onCompleted: {
                fc.applyOutline(this, fc.overlayBackground)
            }
        }

        Text { 
            id: artistText
            text: mediaRoot.mediaArtist
            color: fc.textMuted
            font.family: fc.mainFont
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            Component.onCompleted: {
                fc.applyOutline(this, fc.overlayBackground)
            }
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
                    color: "#ffffff"
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
                    color: "#ffffff"
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
                    color: "#ffffff"
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
                } catch(e) {
                    // Safely ignore standard parsing noise if playerctl emits blank newlines
                }
            }
        }
    }
}
