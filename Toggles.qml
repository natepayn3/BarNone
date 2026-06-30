import QtQuick
import QtQuick.Layouts

Item {
    id: togglesWrapper
    Layout.fillWidth: true
    implicitHeight: togglesGrid.childrenRect.height

    property bool wifiAvailable: false
    property bool wifiActive: false
    property bool btActive: false
    property bool dndActive: false
    property bool caffeineActive: false

    signal wifiToggled()
    signal btToggled()
    signal dndToggled()
    signal caffeineToggled()

    FontConfig { id: fc }

    GridLayout {
        id: togglesGrid
        anchors.left: parent.left
        anchors.right: parent.right
        columns: 2
        rowSpacing: 16
        columnSpacing: 16

        // --- 1. WI-FI TOGGLE ---
        Rectangle {
            id: wifiContainer
            Layout.fillWidth: true
            height: 64
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.03)
            radius: height / 2
            clip: true
            opacity: togglesWrapper.wifiAvailable ? 1.0 : 0.5

            Text {
                id: wifiText
                text: "Wi-Fi"
                font.family: fc.mainFont
                font.pixelSize: 13
                font.weight: Font.Bold
                color: togglesWrapper.wifiActive ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(1, 1, 1, 0.35)
                
                anchors.verticalCenter: parent.verticalCenter

                states: [
                    State {
                        name: "on"; when: togglesWrapper.wifiActive
                        // 🎯 Margins are cleanly encapsulated directly inside the anchor translation passes
                        AnchorChanges { target: wifiText; anchors.left: parent.left; anchors.right: undefined }
                        PropertyChanges { target: wifiText; anchors.leftMargin: 20 }
                    },
                    State {
                        name: "off"; when: !togglesWrapper.wifiActive
                        AnchorChanges { target: wifiText; anchors.left: undefined; anchors.right: parent.right }
                        PropertyChanges { target: wifiText; anchors.rightMargin: 20 }
                    }
                ]

                Component.onCompleted: fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
            }

            Rectangle {
                width: parent.height - 4
                height: parent.height - 4
                radius: height / 2
                color: togglesWrapper.wifiActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.12)
                anchors.verticalCenter: parent.verticalCenter
                x: togglesWrapper.wifiActive ? parent.width - width - 2 : 2

                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                Text {
                    anchors.centerIn: parent
                    text: !togglesWrapper.wifiAvailable ? "wifi_off" : "wifi"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: togglesWrapper.wifiActive ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(1, 1, 1, 0.4)
                    Component.onCompleted: fc.applySmoothing(this)
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: togglesWrapper.wifiAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (togglesWrapper.wifiAvailable) togglesWrapper.wifiToggled()
            }
        }

        // --- 2. BLUETOOTH TOGGLE ---
        Rectangle {
            id: btContainer
            Layout.fillWidth: true
            height: 64
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.03)
            radius: height / 2
            clip: true

            Text {
                id: btText
                text: "Bluetooth"
                font.family: fc.mainFont
                font.pixelSize: 13
                font.weight: Font.Bold
                color: togglesWrapper.btActive ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(1, 1, 1, 0.35)
                
                anchors.verticalCenter: parent.verticalCenter

                states: [
                    State {
                        name: "on"; when: togglesWrapper.btActive
                        AnchorChanges { target: btText; anchors.left: parent.left; anchors.right: undefined }
                        PropertyChanges { target: btText; anchors.leftMargin: 20 }
                    },
                    State {
                        name: "off"; when: !togglesWrapper.btActive
                        AnchorChanges { target: btText; anchors.left: undefined; anchors.right: parent.right }
                        PropertyChanges { target: btText; anchors.rightMargin: 20 }
                    }
                ]

                Component.onCompleted: fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
            }

            Rectangle {
                width: parent.height - 4
                height: parent.height - 4
                radius: height / 2
                color: togglesWrapper.btActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.12)
                anchors.verticalCenter: parent.verticalCenter
                x: togglesWrapper.btActive ? parent.width - width - 2 : 2

                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                Text {
                    anchors.centerIn: parent
                    text: "bluetooth"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: togglesWrapper.btActive ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(1, 1, 1, 0.4)
                    Component.onCompleted: fc.applySmoothing(this)
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: togglesWrapper.btToggled()
            }
        }

        // --- 3. FOCUS (DND) TOGGLE ---
        Rectangle {
            id: dndContainer
            Layout.fillWidth: true
            height: 64
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.03)
            radius: height / 2
            clip: true

            Text {
                id: dndText
                text: "Focus"
                font.family: fc.mainFont
                font.pixelSize: 13
                font.weight: Font.Bold
                color: togglesWrapper.dndActive ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(1, 1, 1, 0.35)
                
                anchors.verticalCenter: parent.verticalCenter

                states: [
                    State {
                        name: "on"; when: togglesWrapper.dndActive
                        AnchorChanges { target: dndText; anchors.left: parent.left; anchors.right: undefined }
                        PropertyChanges { target: dndText; anchors.leftMargin: 20 }
                    },
                    State {
                        name: "off"; when: !togglesWrapper.dndActive
                        AnchorChanges { target: dndText; anchors.left: undefined; anchors.right: parent.right }
                        PropertyChanges { target: dndText; anchors.rightMargin: 20 }
                    }
                ]

                Component.onCompleted: fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
            }

            Rectangle {
                width: parent.height - 4
                height: parent.height - 4
                radius: height / 2
                color: togglesWrapper.dndActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.12)
                anchors.verticalCenter: parent.verticalCenter
                x: togglesWrapper.dndActive ? parent.width - width - 2 : 2

                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                Text {
                    anchors.centerIn: parent
                    text: "do_not_disturb_on"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: togglesWrapper.dndActive ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(1, 1, 1, 0.4)
                    Component.onCompleted: fc.applySmoothing(this)
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: togglesWrapper.dndToggled()
            }
        }

        // --- 4. CAFFEINE TOGGLE ---
        Rectangle {
            id: caffeineContainer
            Layout.fillWidth: true
            height: 64
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.03)
            radius: height / 2
            clip: true

            Text {
                id: caffeineText
                text: "Caffeine"
                font.family: fc.mainFont
                font.pixelSize: 13
                font.weight: Font.Bold
                color: togglesWrapper.caffeineActive ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(1, 1, 1, 0.35)
                
                anchors.verticalCenter: parent.verticalCenter

                states: [
                    State {
                        name: "on"; when: togglesWrapper.caffeineActive
                        AnchorChanges { target: caffeineText; anchors.left: parent.left; anchors.right: undefined }
                        PropertyChanges { target: caffeineText; anchors.leftMargin: 20 }
                    },
                    State {
                        name: "off"; when: !togglesWrapper.caffeineActive
                        AnchorChanges { target: caffeineText; anchors.left: undefined; anchors.right: parent.right }
                        PropertyChanges { target: caffeineText; anchors.rightMargin: 20 }
                    }
                ]

                Component.onCompleted: fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
            }

            Rectangle {
                width: parent.height - 4
                height: parent.height - 4
                radius: height / 2
                color: togglesWrapper.caffeineActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.12)
                anchors.verticalCenter: parent.verticalCenter
                x: togglesWrapper.caffeineActive ? parent.width - width - 2 : 2

                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                Text {
                    anchors.centerIn: parent
                    text: "local_cafe"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: togglesWrapper.caffeineActive ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(1, 1, 1, 0.4)
                    Component.onCompleted: fc.applySmoothing(this)
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: togglesWrapper.caffeineToggled()
            }
        }
    }
}