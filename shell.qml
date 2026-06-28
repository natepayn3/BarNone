import QtQuick
import QtQuick.Shapes 
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: rootShell

    // --- Core Styling Context ---
    readonly property color bgDarkGrey: "#1e1e24"
    readonly property int borderRadius: 16 
    readonly property int wingSize: 14

    readonly property string shellFont: "Sans"
    readonly property color colorText: "#f5f5f5"
    readonly property color colorBackground: "#1e1e24"
    readonly property color colorAccent: "#41414d"
    readonly property color colorSubtext: "#a6adc8"

    // --- Clock Engine Fix ---
    QtObject {
        id: clockTicker
        property var currentTime: new Date()
    }

    Timer {
        id: clockUpdateTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockTicker.currentTime = new Date()
    }

    // --- Screen Border Frame ---
    PanelWindow {
        id: frameWindowItem
        WlrLayershell.namespace: "quickshell-frame"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: WlrLayershell.Ignore
        color: "transparent"
        mask: Region {} 

        anchors { left: true; right: true; top: true; bottom: true }

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            
            Shape {
                anchors.fill: parent
                ShapePath {
                    fillColor: rootShell.bgDarkGrey
                    strokeColor: "transparent"
                    fillRule: ShapePath.OddEvenFill
                    
                    PathMove { x: 0; y: 0 }
                    PathLine { x: frameWindowItem.width; y: 0 }
                    PathLine { x: frameWindowItem.width; y: frameWindowItem.height }
                    PathLine { x: 0; y: frameWindowItem.height }
                    PathLine { x: 0; y: 0 }
                    
                    PathMove { x: 8 + rootShell.borderRadius; y: 8 }
                    PathLine { x: frameWindowItem.width - 8 - rootShell.borderRadius; y: 8 }
                    PathArc { x: frameWindowItem.width - 8; y: 8 + rootShell.borderRadius; radiusX: rootShell.borderRadius; radiusY: rootShell.borderRadius }
                    PathLine { x: frameWindowItem.width - 8; y: frameWindowItem.height - 8 - rootShell.borderRadius }
                    PathArc { x: frameWindowItem.width - 8 - rootShell.borderRadius; y: frameWindowItem.height - 8; radiusX: rootShell.borderRadius; radiusY: rootShell.borderRadius }
                    PathLine { x: 8 + rootShell.borderRadius; y: frameWindowItem.height - 8 }
                    PathArc { x: 8; y: frameWindowItem.height - 8 - rootShell.borderRadius; radiusX: rootShell.borderRadius; radiusY: rootShell.borderRadius }
                    PathLine { x: 8; y: 8 + rootShell.borderRadius }
                    PathArc { x: 8 + rootShell.borderRadius; y: 8; radiusX: rootShell.borderRadius; radiusY: rootShell.borderRadius }
                }
            }
        }
    }

    // --- Invisible 2/3 Height Left Edge Trigger ---
    PanelWindow {
        id: leftHoverTrigger
        WlrLayershell.namespace: "quickshell-hovertrigger"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: WlrLayershell.Ignore
        color: "transparent"

        anchors { left: true; top: true; bottom: true }
        implicitWidth: 15 
        mask: Region { item: hoverTriggerZone }

        Item {
            id: hoverTriggerZone
            width: parent.width
            height: parent.height * (2 / 3)
            y: (parent.height - height) / 2

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: popupWindow.isOpen = true
            }
        }
    }

    // --- Pop-out Window ---
    PopupWindow {
        id: popupWindow
        implicitWidth: 320 + rootShell.wingSize // Matches your scaled template perfectly
        implicitHeight: 680 + (rootShell.wingSize * 2)
        color: "transparent" 

        property bool isOpen: false
        visible: isOpen || styleWrapper.opacity > 0.01

        mask: Region {
            item: styleWrapper.isOpen ? styleWrapper : null
        }

        anchor {
            window: leftHoverTrigger
            rect.x: 8 - rootShell.wingSize 
            rect.y: (leftHoverTrigger.height - popupWindow.implicitHeight) / 2
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onExited: popupWindow.isOpen = false

            WindowStyle {
                id: styleWrapper
                isOpen: popupWindow.isOpen

                Dashboard {}
            }
        }
    }
}