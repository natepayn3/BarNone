import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: popupWindow

    required property var screen
    required property var broadcaster

    FontConfig {
        id: fc
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-osd"
    WlrLayershell.keyboardFocus: WlrLayershell.None
    exclusionMode: ExclusionMode.Ignore

    visible: notifModel.count > 0

    anchors.bottom: true
    anchors.right: true
    
    margins.bottom: 100
    margins.right: 24

    // The container expands dynamically up to a maximum stack height
    implicitWidth: 360
    implicitHeight: 500 
    color: "transparent"

    // --- INTERNAL DATA STORAGE ---
    ListModel {
        id: notifModel
    }

    // --- PIPELINE LISTENER ---
    Connections {
        target: popupWindow.broadcaster

        function onBroadcast(summary, body) {
            // Generate a unique timestamp ID to safely identify this card instance
            let itemKey = Date.now() + "_" + Math.random();
            
            notifModel.append({
                "key": itemKey,
                "summary": summary,
                "body": body
            });

            // Trigger a single-shot timer loop bound to this item's specific lifespan
            let autoDismiss = Qt.createQmlObject('import QtQuick; Timer { interval: 3000; repeat: false }', popupWindow);
            autoDismiss.triggered.connect(function() {
                // Find and remove the exact item from the model stack
                for (let i = 0; i < notifModel.count; i++) {
                    if (notifModel.get(i).key === itemKey) {
                        notifModel.remove(i);
                        break;
                    }
                }
                autoDismiss.destroy();
            });
            autoDismiss.start();
        }
    }

    // --- STACKING VIEW CONTAINER ---
    ListView {
        id: stackView
        anchors.fill: parent
        model: notifModel
        spacing: 12 // Clean gap between stacked notification blocks
        interactive: false // Lock input passthrough
        verticalLayoutDirection: ListView.BottomToTop // Newest alerts stack on top of old ones

        delegate: Item {
            width: stackView.width
            height: 64 // Match your original card proportions exactly

            Rectangle {
                id: bannerCard
                anchors.fill: parent
                radius: 16
                // 🎯 RESTORED: Back to your clean, transparent styling
                color: Qt.rgba(0, 0, 0, 0.01) 
                border.color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    spacing: 18

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: Qt.rgba(1, 1, 1, 0.06)
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: iconText
                            anchors.centerIn: parent
                            text: "notifications_unread"
                            font.family: fc.iconFont
                            font.pixelSize: 25
                            color: "#ffffff"
                            Component.onCompleted: fc.applySmoothing(this)
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: summaryText
                            text: model.summary
                            color: "#ffffff"
                            font.family: fc.mainFont
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Component.onCompleted: fc.applySmoothing(this)
                        }

                        Text {
                            id: bodyText
                            text: model.body
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.family: fc.mainFont
                            font.pixelSize: 15
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Component.onCompleted: fc.applySmoothing(this)
                        }
                    }
                }
            }

            // Instantiate named animations as standard child items of the delegate
            SequentialAnimation {
                id: addAnim
                PropertyAction { target: bannerCard; property: "opacity"; value: 0.0 }
                PropertyAction { target: bannerCard; property: "y"; value: 40 }
                ParallelAnimation {
                    NumberAnimation { target: bannerCard; property: "opacity"; to: 1.0; duration: 150 }
                    NumberAnimation { target: bannerCard; property: "y"; to: 0; duration: 200; easing.type: Easing.OutCubic }
                }
            }

            SequentialAnimation {
                id: removeAnim
                ParallelAnimation {
                    NumberAnimation { target: bannerCard; property: "opacity"; to: 0.0; duration: 150 }
                    NumberAnimation { target: bannerCard; property: "scale"; to: 0.9; duration: 150 }
                }
            }

            // Clean, non-deprecated signal handler blocks to execute them safely
            ListView.onAdd: addAnim.start()
            ListView.onRemove: removeAnim.start()
        }
    }
}