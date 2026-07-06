import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../configs"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osk"
    WlrLayershell.keyboardFocus: WlrLayershell.None
    
    anchors {
        top: true; bottom: true
        left: true; right: true
    }
    
    color: "transparent"
    mask: oskInputBounds
    
    // Property dynamically bound from DisplaySettings.qml
    property string layoutMode: "Normal"

    Region {
        id: oskInputBounds
        item: keyboardWrapper
    }

    FontConfig { id: fc }

    property var pressedKeys: new Set()

    readonly property var layoutNormal: [
        [
            ["~", "KEY_GRAVE", 1], ["1", "KEY_1", 1], ["2", "KEY_2", 1], ["3", "KEY_3", 1], 
            ["4", "KEY_4", 1], ["5", "KEY_5", 1], ["6", "KEY_6", 1], ["7", "KEY_7", 1], 
            ["8", "KEY_8", 1], ["9", "KEY_9", 1], ["0", "KEY_0", 1], ["-", "KEY_MINUS", 1], 
            ["=", "KEY_EQUAL", 1], ["Bksp", "KEY_BACKSPACE", 1.75]
        ],
        [
            ["Tab", "KEY_TAB", 1.5], ["Q", "KEY_Q", 1], ["W", "KEY_W", 1], ["E", "KEY_E", 1], 
            ["R", "KEY_R", 1], ["T", "KEY_T", 1], ["Y", "KEY_Y", 1], ["U", "KEY_U", 1], 
            ["I", "KEY_I", 1], ["O", "KEY_O", 1], ["P", "KEY_P", 1], ["[", "KEY_LEFTBRACE", 1], 
            ["]", "KEY_RIGHTBRACE", 1], ["\\", "KEY_BACKSLASH", 1.25]
        ],
        [
            ["Caps", "KEY_CAPSLOCK", 1.75], ["A", "KEY_A", 1], ["S", "KEY_S", 1], ["D", "KEY_D", 1], 
            ["F", "KEY_F", 1], ["G", "KEY_G", 1], ["H", "KEY_H", 1], ["J", "KEY_J", 1], 
            ["K", "KEY_K", 1], ["L", "KEY_L", 1], [";", "KEY_SEMICOLON", 1], ["'", "KEY_APOSTROPHE", 1], 
            ["Enter", "KEY_ENTER", 2]
        ],
        [
            ["Shift", "KEY_LEFTSHIFT", 2.25], ["Z", "KEY_Z", 1], ["X", "KEY_X", 1], ["C", "KEY_C", 1], 
            ["V", "KEY_V", 1], ["B", "KEY_B", 1], ["N", "KEY_N", 1], ["M", "KEY_M", 1], 
            [",", "KEY_COMMA", 1], [".", "KEY_DOT", 1], ["/", "KEY_SLASH", 1], ["Shift", "KEY_RIGHTSHIFT", 2.5]
        ],
        [
            ["Ctrl", "KEY_LEFTCTRL", 1.25], ["Super", "KEY_LEFTMETA", 1.25], ["Alt", "KEY_LEFTALT", 1.25], 
            ["Space", "KEY_SPACE", 5.25], ["Alt", "KEY_RIGHTALT", 1.25], ["Ctrl", "KEY_RIGHTCTRL", 1.25]
        ]
    ]

    readonly property var layoutMinimal: [
        [
            ["Q", "KEY_Q", 1], ["W", "KEY_W", 1], ["E", "KEY_E", 1], ["R", "KEY_R", 1], 
            ["T", "KEY_T", 1], ["Y", "KEY_Y", 1], ["U", "KEY_U", 1], ["I", "KEY_I", 1], 
            ["O", "KEY_O", 1], ["P", "KEY_P", 1], ["Bksp", "KEY_BACKSPACE", 1.5]
        ],
        [
            ["A", "KEY_A", 1], ["S", "KEY_S", 1], ["D", "KEY_D", 1], ["F", "KEY_F", 1], 
            ["G", "KEY_G", 1], ["H", "KEY_H", 1], ["J", "KEY_J", 1], ["K", "KEY_K", 1], 
            ["L", "KEY_L", 1], ["Enter", "KEY_ENTER", 1.75]
        ],
        [
            ["Shift", "KEY_LEFTSHIFT", 2], ["Z", "KEY_Z", 1], ["X", "KEY_X", 1], 
            ["C", "KEY_C", 1], ["V", "KEY_V", 1], ["B", "KEY_B", 1], ["N", "KEY_N", 1], 
            ["M", "KEY_M", 1], ["Shift", "KEY_RIGHTSHIFT", 1.75]
        ],
        [
            ["Ctrl", "KEY_LEFTCTRL", 1.5], ["Alt", "KEY_LEFTALT", 1.5], 
            ["Space", "KEY_SPACE", 5.5], ["Alt", "KEY_RIGHTALT", 1.5], ["Ctrl", "KEY_RIGHTCTRL", 1.5]
        ]
    ]

    // Uses empty string ("") as a spacer indicator to format the WASD cluster correctly
    readonly property var layoutGamer: [
        [
            ["", "", 1], ["W", "KEY_W", 1], ["", "", 1]
        ],
        [
            ["A", "KEY_A", 1], ["S", "KEY_S", 1], ["D", "KEY_D", 1]
        ],
        [
            ["Shift", "KEY_LEFTSHIFT", 2], ["Space", "KEY_SPACE", 3], ["Enter", "KEY_ENTER", 2]
        ]
    ]

    Process {
        id: keySniffer
        command: ["stdbuf", "-oL", "sudo", "showmethekey-cli"]
        running: root.visible 
        
        stdout: SplitParser {
            onRead: (line) => {
                let trimmed = line.trim();
                if (!trimmed) return;
                
                try {
                    let obj = JSON.parse(trimmed);
                    if (obj.event_name === "KEYBOARD_KEY") {
                        let updatedKeys = new Set(root.pressedKeys);
                        
                        if (obj.state_name === "PRESSED") {
                            updatedKeys.add(obj.key_name);
                        } else if (obj.state_name === "RELEASED") {
                            updatedKeys.delete(obj.key_name);
                        }
                        
                        root.pressedKeys = updatedKeys;
                    }
                } catch(e) {}
            }
        }
    }

    Rectangle {
        id: keyboardWrapper
        color: "transparent"
        
        property real posX: (root.width - width) / 2
        property real posY: root.height - height - shellConfig.panelBottomMargin 
        
        // Dynamically adjust wrapper boundaries based on layout selection
        x: posX
        y: posY
        width: root.layoutMode === "Gamer" ? 300 : (root.layoutMode === "Minimal" ? 540 : 720)
        height: root.layoutMode === "Gamer" ? 180 : (root.layoutMode === "Minimal" ? 220 : 280)
        
        MouseArea {
            id: dragArea
            anchors.fill: parent
            cursorShape: containsMouse ? Qt.SizeAllCursor : Qt.ArrowCursor
            
            property int clickOffsetX: 0
            property int clickOffsetY: 0

            onPressed: (mouse) => {
                clickOffsetX = mouse.x
                clickOffsetY = mouse.y
            }

            onPositionChanged: (mouse) => {
                if (pressed) {
                    keyboardWrapper.posX = keyboardWrapper.posX + mouse.x - clickOffsetX
                    keyboardWrapper.posY = keyboardWrapper.posY + mouse.y - clickOffsetY
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            Repeater {
                // Instantly re-evaluates the array matrix when the dropdown changes
                model: root.layoutMode === "Gamer" ? root.layoutGamer : (root.layoutMode === "Minimal" ? root.layoutMinimal : root.layoutNormal)
                
                delegate: RowLayout {
                    id: rowContainer
                    required property var modelData
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5

                    Repeater {
                        model: rowContainer.modelData
                        delegate: Rectangle {
                            id: keyCap
                            required property var modelData
                            
                            implicitWidth: 38 * modelData[2]
                            implicitHeight: 38
                            radius: shellConfig.radiusValue 
                            
                            property bool isPressed: root.pressedKeys.has(modelData[1])
                            property bool isSpacer: modelData[0] === ""

                            // Hides the visual elements if this is flagged as a spacer geometry block
                            color: isSpacer ? "transparent" : (isPressed ? shellConfig.themeText : shellConfig.colorBackground) 
                            border.color: isSpacer ? "transparent" : (isPressed ? shellConfig.themeText : shellConfig.colorBorder) 
                            border.width: isSpacer ? 0 : 1

                            Behavior on color {
                                ColorAnimation { duration: shellConfig.durationOut } 
                            }

                            Text {
                                anchors.centerIn: parent
                                text: keyCap.modelData[0]
                                color: keyCap.isPressed ? shellConfig.themeBackground : fc.textPrimary 
                                font.bold: true
                                font.pixelSize: 11
                                font.family: fc.mainFont 
                                renderType: fc.preferredRenderType 
                                antialiasing: fc.useAntialiasing 
                                visible: !keyCap.isSpacer
                            }
                        }
                    }
                }
            }
        }
    }
}