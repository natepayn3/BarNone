import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: notifRootCard
    width: parent ? parent.width : 0
    height: notifList.count === 0 ? 64 : (notifColumnLayout.implicitHeight + 24)
    radius: 12
    
    color: Qt.rgba(1, 1, 1, 0.04) 
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.03)

    FontConfig { id: fc }

    ColumnLayout {
        id: notifColumnLayout
        spacing: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12

        // --- HEADER ROW ---
        RowLayout {
            Layout.fillWidth: true // Required for ColumnLayout children
            visible: notifList.count > 0

            Text {
                text: "Notifications"
                color: "#ffffff"
                font.family: fc.mainFont
                font.pixelSize: 13
                font.weight: Font.Bold
                Layout.fillWidth: true

                Component.onCompleted: {
                    fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
                }
            }

            Text {
                id: clearBtnText
                text: "Clear all"
                font.family: fc.mainFont
                font.pixelSize: 12
                font.weight: Font.Bold
                color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.4)
                
                Component.onCompleted: {
                    fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        let notifArray = notifList.model;
                        if (notifArray) {
                            for (let i = notifArray.length - 1; i >= 0; i--) {
                                let notif = notifArray[i];
                                if (notif) {
                                    notif.dismiss();
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- CONSTRAINED NOTIFICATION LIST ENGINE ---
        ListView {
            id: notifList
            Layout.fillWidth: true 
            
            // Limit the maximum display height of the list container (e.g., max 400px)
            Layout.preferredHeight: Math.min(200, contentHeight)
            height: Layout.preferredHeight 
            
            spacing: 6
            clip: true
            
            // Enable dragging/flicking only when content exceeds the max boundary
            interactive: contentHeight > height

            model: dashboardWindow.notificationModel
            
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }
            ScrollBar.vertical: ScrollBar { 
                // Display the scrollbar automatically when the list is scrollable
                policy: notifList.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff 
            }

            displaced: Transition { 
                NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic } 
            }

            delegate: Rectangle {
                id: delegateCard
                required property var modelData

                width: notifList.width 
                height: delegateLayout.implicitHeight + 20 
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.05)

                Text {
                    id: closeBtn
                    text: "close"
                    font.family: fc.iconFont
                    font.pixelSize: 14
                    color: "#ffffff"
                    opacity: 0.5
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                 
                    Component.onCompleted: {
                        fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
                    }

                    MouseArea { 
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.dismiss()
                    }
                }

                ColumnLayout {
                    id: delegateLayout
                    anchors.left: parent.left
                    anchors.right: closeBtn.left
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 2

                    Text { 
                        text: modelData.summary
                        color: "#ffffff"
                        font.family: fc.mainFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true

                        Component.onCompleted: {
                            fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
                        }
                    }
               
                    Text { 
                        text: modelData.body
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.family: fc.mainFont
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true

                        Component.onCompleted: {
                            fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
                        }
                    }
                }
            }
        }
    }

    // --- EMPTY STATE INDICATOR ---
    Text {
        text: "No notifications"
        color: Qt.rgba(1, 1, 1, 0.25)
        font.family: fc.mainFont
        font.pixelSize: 12
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        anchors.centerIn: parent 
        visible: notifList.count === 0

        Component.onCompleted: {
            fc.applyOutline(this, Qt.rgba(0, 0, 0, 0.35))
        }
    }
}