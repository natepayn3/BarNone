import QtQuick

Column {
    id: clockRoot
    spacing: 2

    property date currentTime: new Date()

    Timer {
        interval: 1000
        running: clockRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: clockRoot.currentTime = new Date()
    }

    Text {
        text: Qt.formatDateTime(clockRoot.currentTime, "h:mm ap")
        font.family: "Google Sans Flex"
        font.pixelSize: 46
        font.weight: Font.Bold
        color: "#ffffff"
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.35)
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        text: Qt.formatDateTime(clockRoot.currentTime, "dddd • MMMM d")
        font.family: "Google Sans Flex"
        font.pixelSize: 13
        font.weight: Font.Medium
        color: Qt.rgba(1, 1, 1, 0.6)
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.35)
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
    }
}