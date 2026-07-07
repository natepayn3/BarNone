import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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
                    if (obj.event_name === "KEYBOARD_KEY" || obj.event_name === "POINTER_BUTTON") {
                        let updatedKeys = new Set(root.pressedKeys);
                        
                        let targetIdentifier = obj.key_name || obj.button_name;
                        if (!targetIdentifier) return;

                        if (obj.state_name === "PRESSED") {
                            updatedKeys.add(targetIdentifier);
                        } else if (obj.state_name === "RELEASED") {
                            updatedKeys.delete(targetIdentifier);
                        }
                        
                        root.pressedKeys = updatedKeys;
                    }
                } catch(e) {}
            }
        }
    }

    Component {
        id: keyCapComponent
        Item {
            id: keyCapRoot
            property var keyData
            property bool isPressed: root.pressedKeys.has(keyData[1])
            property bool isSpacer: keyData[0] === ""

            anchors.fill: parent
            visible: !isSpacer

            Rectangle {
                id: keyBackground
                anchors.fill: parent
                radius: root.layoutMode === "Gamer" ? 4 : shellConfig.radiusValue
                color: keyCapRoot.isPressed ? shellConfig.themeText : shellConfig.colorBackground
                border.color: keyCapRoot.isPressed ? shellConfig.themeText : shellConfig.colorBorder
                border.width: 1

                transform: Matrix4x4 {
                    matrix: {
                        let m = Qt.matrix4x4();
                        if (root.layoutMode === "Gamer") {
                            m.m12 = -0.25; 
                        }
                        return m;
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: shellConfig.durationOut }
                }
            }

            Text {
                // Precise coordinate translation lines that completely balance layout skew changes
                x: ((parent.width - width) / 2) - (root.layoutMode === "Gamer" ? ((parent.height * 0.125) - 1): 0)
                y: (parent.height - height) / 2
                
                text: keyCapRoot.keyData[0]
                color: keyCapRoot.isPressed ? shellConfig.themeBackground : fc.textPrimary
                font.bold: true
                font.italic: root.layoutMode === "Gamer"
                font.pixelSize: 12
                font.family: fc.mainFont
                renderType: fc.preferredRenderType
                antialiasing: fc.useAntialiasing
            }
        }
    }

    Rectangle {
        id: keyboardWrapper
        color: "transparent"
        
        property real posX: root.width - width - 30
        property real posY: root.height - height - 30
        
        x: posX
        y: posY
        width: root.layoutMode === "Gamer" ? 440 : (root.layoutMode === "Minimal" ? 540 : 720)
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

        // --- VIEW MODE 1: STANDARD KEYBOARDS (NORMAL / MINIMAL) ---
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5
            visible: root.layoutMode !== "Gamer"

            Repeater {
                model: root.layoutMode === "Minimal" ? root.layoutMinimal : root.layoutNormal
                delegate: RowLayout {
                    id: rowContainer
                    required property var modelData
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5

                    Repeater {
                        model: rowContainer.modelData
                        delegate: Loader {
                            required property var modelData
                            sourceComponent: keyCapComponent
                            onLoaded: item.keyData = modelData
                            width: 38 * modelData[2]
                            height: 38
                        }
                    }
                }
            }
        }

        // --- VIEW MODE 2: ABSOLUTE COORDINATE POSITIONING (GAMER) ---
        Item {
            anchors.fill: parent
            visible: root.layoutMode === "Gamer"

            // Tab
            Loader {
                x: 25; y: 15
                sourceComponent: keyCapComponent
                onLoaded: item.keyData = ["Tab", "KEY_TAB", 1]
                width: 55; height: 38
            }

            // Shift
            Loader {
                x: 15; y: 59
                sourceComponent: keyCapComponent
                onLoaded: item.keyData = ["Shift", "KEY_LEFTSHIFT", 1]
                width: 55; height: 38
            }

            // W
            Loader {
                x: 138; y: 15
                sourceComponent: keyCapComponent
                onLoaded: item.keyData = ["W", "KEY_W", 1]
                width: 40; height: 38
            }

            // A
            Loader {
                x: 82; y: 59
                sourceComponent: keyCapComponent
                onLoaded: item.keyData = ["A", "KEY_A", 1]
                width: 40; height: 38
            }

            // S
            Loader {
                x: 128; y: 59
                sourceComponent: keyCapComponent
                onLoaded: item.keyData = ["S", "KEY_S", 1]
                width: 40; height: 38
            }

            // D
            Loader {
                x: 174; y: 59
                sourceComponent: keyCapComponent
                onLoaded: item.keyData = ["D", "KEY_D", 1]
                width: 40; height: 38
            }

            // Enter
            Loader {
                x: 234; y: 15
                sourceComponent: keyCapComponent
                onLoaded: item.keyData = ["Enter", "KEY_ENTER", 1]
                width: 65; height: 82
            }

            // Spacebar (Locked directly to the cluster center vertical axis alignment layout point)
            Loader {
                x: 30; y: 115
                sourceComponent: keyCapComponent
                onLoaded: item.keyData = ["Space", "KEY_SPACE", 1]
                width: 220; height: 38
            }

            // --- UNIFIED INTEGRATED MOUSE CHASSIS ---
            Item {
                id: mouseChassis
                x: 320; y: 15
                width: 105; height: 138

                // Track button states from the root process handler
                readonly property bool leftPressed: root.pressedKeys.has("BTN_LEFT")
                readonly property bool rightPressed: root.pressedKeys.has("BTN_RIGHT")
                readonly property bool middlePressed: root.pressedKeys.has("BTN_MIDDLE")

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: shellConfig.colorBackground
                    border.color: shellConfig.colorBorder
                    border.width: 1

                    // Left Click Target Zone
                    Rectangle {
                        id: leftClickPart
                        width: (parent.width / 2)
                        height: parent.height * 0.45
                        x: 0; y: 0
                        topLeftRadius: parent.radius
                        color: mouseChassis.leftPressed ? shellConfig.themeText : "transparent"
                        border.color: mouseChassis.leftPressed ? shellConfig.themeText : shellConfig.colorBorder
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: shellConfig.durationOut } }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: mouseChassis.leftPressed ? shellConfig.themeBackground : fc.textPrimary
                            font.bold: true
                            font.pixelSize: 11
                            font.family: fc.mainFont
                        }
                    }

                    // Right Click Target Zone
                    Rectangle {
                        id: rightClickPart
                        width: (parent.width / 2)
                        height: parent.height * 0.45
                        x: parent.width / 2; y: 0
                        topRightRadius: parent.radius
                        color: mouseChassis.rightPressed ? shellConfig.themeText : "transparent"
                        border.color: mouseChassis.rightPressed ? shellConfig.themeText : shellConfig.colorBorder
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: shellConfig.durationOut } }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: mouseChassis.rightPressed ? shellConfig.themeBackground : fc.textPrimary
                            font.bold: true
                            font.pixelSize: 11
                            font.family: fc.mainFont
                        }
                    }

                    // Interactive Reactive Scroll Wheel Block
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (parent.height * 0.45) - (height / 2)
                        width: 12; height: 26
                        radius: 5
                        color: mouseChassis.middlePressed ? shellConfig.themeText : shellConfig.colorBorder
                        border.color: mouseChassis.middlePressed ? shellConfig.themeText : shellConfig.colorBorder
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: shellConfig.durationOut } }
                    }
                }

                // Explicit bracket wrapping for calculation matrix properties prevents parsing faults
                transform: Matrix4x4 {
                    matrix: {
                        let m = Qt.matrix4x4();
                        m.m12 = -0.25;
                        return m;
                    }
                }
            }
        }
    }
}
