import QtQuick
import Quickshell.Io

Column {
    id: mediaRoot
    spacing: 10

    property string mediaTitle: "Not Playing"
    property string mediaArtist: "---"
    property string mediaStatus: "Stopped"

    Component.onCompleted: mediaFollower.running = true

    Text { text: mediaRoot.mediaTitle; color: "#ffffff"; font.family: "Google Sans Flex"; font.pixelSize: 14; font.weight: Font.Bold; elide: Text.ElideRight; width: parent.width; horizontalAlignment: Text.AlignHCenter }
    Text { text: mediaRoot.mediaArtist; color: Qt.rgba(1, 1, 1, 0.5); font.family: "Google Sans Flex"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width; horizontalAlignment: Text.AlignHCenter }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item {
            width: 32; height: 32
            Text { anchors.centerIn: parent; text: "skip_previous"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: "#ffffff" }
            MouseArea { anchors.fill: parent; onClicked: { mediaControlProc.command = ["playerctl", "previous"]; mediaControlProc.running = true; } }
        }
        Item {
            width: 36; height: 36
            Text { anchors.centerIn: parent; text: mediaRoot.mediaStatus === "Playing" ? "pause_circle" : "play_circle"; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: "#ffffff" }
            MouseArea { anchors.fill: parent; onClicked: { mediaControlProc.command = ["playerctl", "play-pause"]; mediaControlProc.running = true; } }
        }
        Item {
            width: 32; height: 32
            Text { anchors.centerIn: parent; text: "skip_next"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: "#ffffff" }
            MouseArea { anchors.fill: parent; onClicked: { mediaControlProc.command = ["playerctl", "next"]; mediaControlProc.running = true; } }
        }
    }

    Process { id: mediaControlProc; running: false }
    Process {
        id: mediaFollower
        command: ["playerctl", "metadata", "--follow", "--format", "{\"title\": \"{{title}}\", \"artist\": \"{{artist}}\", \"status\": \"{{status}}\"}"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    let parsed = JSON.parse(data.trim());
                    if (parsed.status === "Stopped") {
                        mediaRoot.mediaTitle = "Not Playing"; mediaRoot.mediaArtist = "---"; mediaRoot.mediaStatus = "Stopped";
                    } else {
                        mediaRoot.mediaTitle = parsed.title || "Unknown"; mediaRoot.mediaArtist = parsed.artist || "Unknown"; mediaRoot.mediaStatus = parsed.status || "Stopped";
                    }
                } catch(e) {}
            }
        }
    }
}