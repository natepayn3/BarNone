import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Column {
    id: notifRoot
    spacing: 8
    width: parent ? parent.width : 0

    // --- HEADER ROW ---
    RowLayout {
        width: notifRoot.width
        visible: notifList.count > 0

        Text {
            text: "Notifications"
            color: "#ffffff"
            font.family: "Google Sans Flex"
            font.pixelSize: 13
            font.weight: Font.Bold
            Layout.fillWidth: true
        }

        Text {
            id: clearBtnText
            text: "Clear all"
            font.family: "Google Sans Flex"
            font.pixelSize: 12
            font.weight: Font.Bold
            color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.4)
            
            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    // Extract the raw backend array data directly from the bound model cache
                    let notifArray = notifList.model;
                    if (notifArray) {
                        // Loop backwards through the actual data objects rather than visual children
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
        width: notifRoot.width
        // 48px row height + 6px spacing = 54px total. Caps at 135px (2.5 items tall).
        height: Math.min(135, notifList.count * 54)
        spacing: 6
        clip: true
        interactive: count > 2

        model: dashboardWindow.notificationModel
        
        // 🎯 FIX: Instantiate ScrollBars cleanly as objects to avoid null assignment errors
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }
        ScrollBar.vertical: ScrollBar { 
            policy: notifList.count > 2 ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff 
        }

        displaced: Transition { 
            NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic } 
        }

        delegate: Rectangle {
            id: delegateCard
            required property var modelData

            width: notifRoot.width // 🎯 FIX: Bound to root ID to dodge initialization lookup drops
            height: 48 
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.05)

            Text {
                id: closeBtn
                text: "close"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 14
                color: "#ffffff"
                opacity: 0.5
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                
                MouseArea { 
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.dismiss()
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: closeBtn.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 10
                spacing: 0

                Text { 
                    text: modelData.summary
                    color: "#ffffff"
                    font.family: "Google Sans Flex"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    width: parent.width
                }
                
                Text { 
                    text: modelData.body
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: "Google Sans Flex"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }
    }

    // --- EMPTY STATE INDICATOR ---
    Text {
        text: "No notifications"
        color: Qt.rgba(1, 1, 1, 0.3)
        font.family: "Google Sans Flex"
        font.pixelSize: 12
        width: notifRoot.width
        horizontalAlignment: Text.AlignHCenter
        visible: notifList.count === 0
    }
}