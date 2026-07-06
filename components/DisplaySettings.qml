import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../configs"

PanelWindow {
    id: settingsPopupWindow

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: visible ? WlrLayershell.OnDemand : WlrLayershell.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
        top: true
        left: true
        right: true
    }
    
    color: "transparent"

    property bool animateActive: false
    property bool showFontPicker: false
    property bool showColorPicker: false
    
    property string selectedOskLayout: "Disabled"
    
    property string selectedFont: shellConfig.shellFont ? shellConfig.shellFont : "Sans"
    property color localPickerColor: shellConfig.themeText

    property real currentHue: 0.0
    property real currentSat: 1.0
    property real currentVal: 1.0

    property bool _isUpdatingFromInput: false

    property var masterFontList: Qt.fontFamilies()
    property var filteredFontList: masterFontList

    onShowFontPickerChanged: {
        if (showFontPicker) {
            fontSearchField.forceActiveFocus();
        }
    }

    FontConfig { id: fc }

    OSK {
        id: virtualKeyboard
        visible: settingsPopupWindow.selectedOskLayout !== "Disabled"
        layoutMode: settingsPopupWindow.selectedOskLayout
    }

    Timer {
        id: focusDelayTimer
        interval: 50
        repeat: false
        onTriggered: outsideDismiss.forceActiveFocus()
    }

    function getAbsoluteConfigPath() {
        let currentDir = Qt.resolvedUrl(".").toString().replace("file://", "");
        return `${currentDir}../configs/ModuleConfig.qml`;
    }

    function writeConfigValue(commandString) {
        Quickshell.execDetached(["fish", "-c", commandString]);
    }

    function updateColorFromHSV() {
        if (_isUpdatingFromInput) return;
        _isUpdatingFromInput = true;
        try {
            let nextColor = Qt.hsva(currentHue, currentSat, currentVal, 1.0);
            localPickerColor = nextColor;
            colorHexInput.text = ("" + nextColor).toUpperCase();
        } catch(e) {
            console.log("Error updating color from HSV: " + e);
        } finally {
            _isUpdatingFromInput = false;
        }
    }

    function applyManualHex(textValue) {
        let cleanText = textValue.trim();
        let regExp = /^#?([0-9A-F]{6}|[0-9A-F]{8})$/i;
        
        if (regExp.test(cleanText)) {
            _isUpdatingFromInput = true;
            try {
                if (!cleanText.startsWith("#")) {
                    cleanText = "#" + cleanText;
                }
                
                localPickerColor = cleanText;
                
                let h = localPickerColor.hsvHue;
                let s = localPickerColor.hsvSaturation;
                let v = localPickerColor.hsvValue;
                
                if (s > 0 && h !== undefined && !isNaN(h) && h >= 0) {
                    currentHue = h > 1.0 ? (h / 360.0) : h;
                }
                
                currentSat = isNaN(s) || s === undefined ? 0.0 : s;
                currentVal = isNaN(v) || v === undefined ? 1.0 : v;
            } catch(e) {
                console.log("Error applying manual hex: " + e);
            } finally {
                _isUpdatingFromInput = false;
            }
        }
    }

    function filterFonts(query) {
        if (query.trim() === "") {
            filteredFontList = masterFontList;
        } else {
            let lowerQuery = query.toLowerCase();
            filteredFontList = masterFontList.filter(function(fontName) {
                return fontName.toLowerCase().indexOf(lowerQuery) !== -1;
            });
        }
    }

    MouseArea {
        id: outsideDismiss
        anchors.fill: parent
        
        focus: true
        Keys.onEscapePressed: (event) => {
            settingsPopupWindow.animateActive = false;
            event.accepted = true;
        }

        onClicked: {
            settingsPopupWindow.animateActive = false;
            settingsPopupWindow.showFontPicker = false;
            settingsPopupWindow.showColorPicker = false;
        }

        Rectangle {
            id: bgCard
            width: shellConfig.panelWidth
            
            // bgCard natively calculates its height based on mainLayout's shifting implicitHeight
            height: settingsPopupWindow.showFontPicker 
                ? (fontPickerLayout.implicitHeight + 44)
                : (settingsPopupWindow.showColorPicker ? (colorPickerLayout.implicitHeight + 44) : (mainLayout.implicitHeight + 44))
            
            Behavior on height {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            transformOrigin: Item.Center
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 100
            anchors.horizontalCenter: parent.horizontalCenter
           
            color: shellConfig.colorBackground
            border.color: fc.borderMuted
            border.width: 0
            radius: shellConfig.radiusValue

            Text {
                id: leftDisplayIcon
                text: "palette"
                font.family: fc.iconFont
                font.pixelSize: 150
                color: shellConfig.colorBackground
                styleColor: shellConfig.colorBackground
             
                anchors.right: parent.left
                anchors.rightMargin: -5
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 0
            }

            Text {
                id: rightDisplayIcon
                text: "palette"
                font.family: fc.iconFont
                font.pixelSize: 150
                color: shellConfig.colorBackground
                styleColor: shellConfig.colorBackground

                anchors.left: parent.right
                anchors.leftMargin: -5
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 0
            }

            states: [
                State {
                    name: "hidden"
                    when: !settingsPopupWindow.animateActive
                    PropertyChanges { target: bgCard; opacity: 0.0; scale: 0.3 }
                },
                State {
                    name: "shown"
                    when: settingsPopupWindow.animateActive
                    PropertyChanges { target: bgCard; opacity: 1.0; scale: 1.0 }
                }
            ]

            transitions: [
                Transition {
                    from: "hidden"; to: "shown"
                    ParallelAnimation {
                        NumberAnimation { target: bgCard; property: "scale"; duration: shellConfig.durationIn; easing.type: Easing.OutBack; easing.amplitude: shellConfig.springBack }
                        NumberAnimation { target: bgCard; property: "opacity"; duration: shellConfig.opacityIn; easing.type: Easing.OutQuad }
                    }
                },
                Transition {
                    from: "shown"; to: "hidden"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation { target: bgCard; property: "scale"; duration: shellConfig.durationOut; easing.type: Easing.InBack; easing.amplitude: shellConfig.springIn }
                            NumberAnimation { target: bgCard; property: "opacity"; duration: shellConfig.opacityOut; easing.type: Easing.InQuad }
                        }
                        ScriptAction { script: settingsPopupWindow.visible = false }
                    }
                }
            ]

            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => mouse.accepted = true
                onPressed: (mouse) => mouse.accepted = true
                onReleased: (mouse) => mouse.accepted = true
            }

            // --- VIEW 1: MAIN CONFIGURATION CONTROLS ---
            ColumnLayout {
                id: mainLayout
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14
                visible: !settingsPopupWindow.showFontPicker && !settingsPopupWindow.showColorPicker

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Text {
                        text: "Display Settings"
                        color: shellConfig.themeText
                        font.family: shellConfig.shellFont
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Opacity: " + Math.round(alphaSlider.value * 100) + "%"
                        color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.7)
                        font.family: shellConfig.shellFont
                        font.pixelSize: 13
                    }

                    Slider {
                        id: alphaSlider
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        onValueChanged: {
                            shellConfig.colorBackground = Qt.rgba(0.12, 0.12, 0.14, value);
                        }

                        onPressedChanged: {
                            if (!pressed) {
                                let alpha = value.toFixed(2);
                                let path = settingsPopupWindow.getAbsoluteConfigPath();
                                writeConfigValue(`sed -i -E 's/(property color colorBackground:).*/\\1 Qt.rgba(0.12, 0.12, 0.14, ${alpha})/' ${path}`);
                            }
                        }

                        Component.onCompleted: {
                            let currentAlpha = shellConfig.colorBackground.a;
                            if (currentAlpha !== undefined && !isNaN(currentAlpha)) {
                                alphaSlider.value = currentAlpha;
                            } else {
                                alphaSlider.value = 0.7;
                            }
                        }

                        background: Rectangle {
                            x: alphaSlider.leftPadding
                            y: alphaSlider.topPadding + alphaSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 6
                            width: alphaSlider.availableWidth
                            height: implicitHeight
                            radius: 3
                            color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.15)

                            Rectangle {
                                width: alphaSlider.visualPosition * parent.width
                                height: parent.height
                                color: shellConfig.themeText
                                radius: 3
                            }
                        }

                        handle: Rectangle {
                            x: alphaSlider.leftPadding + alphaSlider.visualPosition * (alphaSlider.availableWidth - width)
                            y: alphaSlider.topPadding + alphaSlider.availableHeight / 2 - height / 2
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 8
                            color: shellConfig.themeText
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Font Family"
                        color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.6)
                        font.family: shellConfig.shellFont
                        font.pixelSize: 13
                    }

                    Button {
                        id: btnFontSelect
                        Layout.fillWidth: true
                        implicitHeight: 36
                        hoverEnabled: true
                        
                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        onClicked: {
                            fontSearchField.text = "";
                            settingsPopupWindow.filteredFontList = settingsPopupWindow.masterFontList;
                            settingsPopupWindow.showFontPicker = true;
                        }

                        contentItem: Text {
                            text: shellConfig.shellFont
                            color: shellConfig.themeText
                            font.family: shellConfig.shellFont
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            leftPadding: 10
                        }
                        background: Rectangle {
                            color: btnFontSelect.hovered ? fc.overlayBackground : fc.trackBackground
                            radius: 6
                            border.color: fc.borderMuted
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Font Color"
                        color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.6)
                        font.family: shellConfig.shellFont
                        font.pixelSize: 13
                    }

                    Button {
                        id: btnColorSelect
                        Layout.fillWidth: true
                        implicitHeight: 36
                        hoverEnabled: true

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        onClicked: settingsPopupWindow.showColorPicker = true

                        contentItem: RowLayout {
                            spacing: 10
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            
                            Rectangle {
                                width: 16; height: 16; radius: 4
                                color: shellConfig.themeText
                                border.color: fc.borderMuted
                            }
                            Text {
                                text: ("" + shellConfig.themeText).toUpperCase()
                                color: shellConfig.themeText
                                font.family: fc.monoFont
                                font.pixelSize: 13
                                Layout.fillWidth: true
                            }
                        }
                        background: Rectangle {
                            color: btnColorSelect.hovered ? fc.overlayBackground : fc.trackBackground
                            radius: 6
                            border.color: fc.borderMuted
                        }
                    }
                }

                // --- OSK DROPDOWN MOVED TO BOTTOM ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "On-Screen Keyboard Layout"
                        color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.6)
                        font.family: shellConfig.shellFont
                        font.pixelSize: 13
                    }

                    ComboBox {
                        id: layoutDropdown
                        Layout.fillWidth: true
                        implicitHeight: 36
                        model: ["Disabled", "Normal", "Gamer", "Minimal"]
                        
                        onCurrentTextChanged: settingsPopupWindow.selectedOskLayout = currentText
                        
                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        background: Rectangle {
                            color: layoutDropdown.hovered ? fc.overlayBackground : fc.trackBackground
                            radius: 6
                            border.color: fc.borderMuted
                        }
                        
                        contentItem: Text {
                            text: layoutDropdown.displayText
                            color: shellConfig.themeText
                            font.family: shellConfig.shellFont
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }
                        
                        delegate: ItemDelegate {
                            width: layoutDropdown.width
                            height: 36
                            
                            HoverHandler { cursorShape: Qt.PointingHandCursor }

                            contentItem: Text {
                                text: modelData
                                color: shellConfig.themeText
                                font.family: shellConfig.shellFont
                                font.pixelSize: 14
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                            }
                            background: Rectangle {
                                color: layoutDropdown.highlightedIndex === index ? fc.overlayBackground : "transparent"
                                radius: 4
                            }
                        }
                        
                        popup: Popup {
                            y: layoutDropdown.height + 4
                            width: layoutDropdown.width
                            implicitHeight: contentItem.implicitHeight
                            padding: 4
                            
                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: layoutDropdown.popup.visible ? layoutDropdown.delegateModel : null
                                currentIndex: layoutDropdown.highlightedIndex
                            }
                            background: Rectangle {
                                // Locked to a solid, non-transparent background to hide underlying UI elements
                                color: Qt.rgba(0.12, 0.12, 0.14, 1.0)
                                border.color: fc.borderMuted
                                border.width: 1
                                radius: 6
                            }
                        }
                    }
                }

                // Reactive spacer block that expands mainLayout's implicitHeight when the popup opens
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layoutDropdown.popup.visible ? (layoutDropdown.popup.contentItem.implicitHeight + 8) : 0
                    
                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }
                }
            }

            // --- VIEW 2: TRANSITION SYSTEM FONT PICKER WINDOW ---
            ColumnLayout {
                id: fontPickerLayout
                anchors.fill: parent
                anchors.margins: 22
                spacing: 12
                visible: settingsPopupWindow.showFontPicker

                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: "Select Font:"
                        color: shellConfig.themeText
                        font.family: shellConfig.shellFont
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Button {
                        id: backButton
                        flat: true
                        implicitWidth: 60
                        implicitHeight: 28
                        hoverEnabled: true
                        
                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        background: Rectangle { 
                            color: backButton.hovered ? fc.overlayBackground : fc.trackBackground
                            radius: 4
                            border.color: backButton.hovered ? Qt.rgba(0, 0, 0, 0.2) : "transparent"
                        }
                        contentItem: Text { 
                            text: "Back"
                            color: shellConfig.themeText
                            font.family: shellConfig.shellFont
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            let path = settingsPopupWindow.getAbsoluteConfigPath();
                            writeConfigValue(`sed -i -E 's/(property string shellFont:).*/\\1 "${shellConfig.shellFont}"/' ${path}`);
                            settingsPopupWindow.showFontPicker = false;
                        }
                    }
                }

                TextField {
                    id: fontSearchField
                    Layout.fillWidth: true
                    implicitHeight: 36
                    placeholderText: "Search fonts..."
                    placeholderTextColor: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.4)
                    color: shellConfig.themeText
                    font.family: shellConfig.shellFont
                    font.pixelSize: 13
                    selectByMouse: true
                    
                    background: Rectangle {
                        color: Qt.rgba(0, 0, 0, 0.15)
                        radius: 6
                        border.color: fontSearchField.activeFocus ? shellConfig.themeText : fc.borderMuted
                        border.width: 1
                    }

                    onTextChanged: settingsPopupWindow.filterFonts(text)
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    color: Qt.rgba(0, 0, 0, 0.15)
                    radius: 8
                    border.color: fc.borderMuted
                    clip: true

                    ListView {
                        id: fontListView
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4
                        model: settingsPopupWindow.filteredFontList

                        delegate: MouseArea {
                            width: fontListView.width
                            height: 36
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: shellConfig.shellFont === modelData ? fc.overlayBackground : (parent.containsMouse ? fc.trackBackground : "transparent")
                            }

                            Text {
                                text: modelData
                                font.family: modelData
                                font.pixelSize: 14
                                color: shellConfig.themeText
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            onClicked: {
                                shellConfig.shellFont = modelData;
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "No matching fonts found"
                            color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.5)
                            font.family: shellConfig.shellFont
                            font.pixelSize: 13
                            visible: fontListView.count === 0
                        }
                    }
                }
            }

            // --- VIEW 3: DEDICATED TRANSITION COLOR PICKER WINDOW ---
            ColumnLayout {
                id: colorPickerLayout
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14
                visible: settingsPopupWindow.showColorPicker
                implicitHeight: 334

                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: "Color Picker"
                        color: settingsPopupWindow.localPickerColor
                        font.family: shellConfig.shellFont
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Button {
                        id: colorBackButton
                        flat: true
                        implicitWidth: 60
                        implicitHeight: 28
                        hoverEnabled: true

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        background: Rectangle { 
                            color: colorBackButton.hovered ? fc.overlayBackground : fc.trackBackground
                            radius: 4
                            border.color: colorBackButton.hovered ? Qt.rgba(0, 0, 0, 0.2) : "transparent"
                        }
                        contentItem: Text { 
                            text: "Done"
                            color: settingsPopupWindow.localPickerColor
                            font.family: shellConfig.shellFont
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            settingsPopupWindow.applyManualHex(colorHexInput.text);
                            shellConfig.themeText = settingsPopupWindow.localPickerColor;
                            
                            let hex = ("" + settingsPopupWindow.localPickerColor).toUpperCase();
                            let path = settingsPopupWindow.getAbsoluteConfigPath();
                            writeConfigValue(`sed -i -E 's/(property color themeText:).*/\\1 "${hex}"/' ${path}`);
                            
                            settingsPopupWindow.showColorPicker = false;
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    spacing: 16

                    Rectangle {
                        id: satValMatrix
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        radius: 6
                        clip: true
                        border.color: fc.borderMuted
                        border.width: 1

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.hsva(settingsPopupWindow.currentHue, 1.0, 1.0, 1.0)
                        }

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#FFFFFF" }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: "#000000" }
                            }
                        }

                        Rectangle {
                            x: (settingsPopupWindow.currentSat * parent.width) - width / 2
                            y: ((1.0 - settingsPopupWindow.currentVal) * parent.height) - height / 2
                            width: 12; height: 12; radius: 6
                            color: "transparent"
                            border.color: "#FFFFFF"
                            border.width: 2

                            Rectangle {
                                anchors.centerIn: parent
                                width: 4; height: 4; radius: 2
                                color: "#000000"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor
                            
                            function updateCoordinates(mouse) {
                                let normX = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                let normY = Math.max(0.0, Math.min(1.0, mouse.y / height))
                                settingsPopupWindow.currentSat = normX;
                                settingsPopupWindow.currentVal = 1.0 - normY;
                                settingsPopupWindow.updateColorFromHSV();
                            }
                            onPressed: (mouse) => updateCoordinates(mouse)
                            onPositionChanged: (mouse) => updateCoordinates(mouse)
                        }
                    }

                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: satValMatrix.height

                        Rectangle {
                            id: hueBarTrack
                            anchors.fill: parent
                            radius: 6
                            border.color: fc.borderMuted

                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "#ff0000" }
                                GradientStop { position: 0.17; color: "#ffff00" }
                                GradientStop { position: 0.33; color: "#00ff00" }
                                GradientStop { position: 0.5; color: "#00ffff" }
                                GradientStop { position: 0.67; color: "#0000ff" }
                                GradientStop { position: 0.83; color: "#ff00ff" }
                                GradientStop { position: 1.0; color: "#ff0000" }
                            }

                            Rectangle {
                                y: (settingsPopupWindow.currentHue * hueBarTrack.height) - (height / 2)
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width + 4
                                height: 8
                                radius: 2
                                color: "#FFFFFF"
                                border.color: "#000000"
                                border.width: 1
                            }

                            MouseArea {
                                anchors.fill: parent
                                preventStealing: true
                                cursorShape: Qt.PointingHandCursor
                                
                                function updateHue(mouse) {
                                    let normY = Math.max(0.0, Math.min(1.0, mouse.y / hueBarTrack.height))
                                    settingsPopupWindow.currentHue = normY
                                    
                                    if (settingsPopupWindow.currentSat === 0.0) settingsPopupWindow.currentSat = 1.0;
                                    if (settingsPopupWindow.currentVal === 0.0) settingsPopupWindow.currentVal = 1.0;

                                    settingsPopupWindow.updateColorFromHSV()
                                }
                                onPressed: (mouse) => updateHue(mouse)
                                onPositionChanged: (mouse) => updateHue(mouse)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 44; height: 36; radius: 6
                        color: settingsPopupWindow.localPickerColor
                        border.color: fc.borderMuted
                        border.width: 1
                    }

                    TextField {
                        id: colorHexInput
                        Layout.fillWidth: true
                        height: 36
                        placeholderText: "#FFFFFFFF"
                        placeholderTextColor: Qt.rgba(settingsPopupWindow.localPickerColor.r, settingsPopupWindow.localPickerColor.g, settingsPopupWindow.localPickerColor.b, 0.4)
                        color: settingsPopupWindow.localPickerColor
                        font.family: fc.monoFont
                        font.pixelSize: 14
                        font.bold: true
                        selectByMouse: true
                        
                        background: Rectangle {
                            color: Qt.rgba(0, 0, 0, 0.15)
                            radius: 6
                            border.color: colorHexInput.activeFocus ? settingsPopupWindow.localPickerColor : fc.borderMuted
                            border.width: 1
                        }

                        onAccepted: settingsPopupWindow.applyManualHex(text)
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            focusDelayTimer.start();
            settingsPopupWindow.animateActive = true;
            
            let c = shellConfig.themeText;
            settingsPopupWindow.localPickerColor = c;
            
            let h = c.hsvHue;
            let s = c.hsvSaturation;
            let v = c.hsvValue;
            
            if (s > 0 && h !== undefined && !isNaN(h) && h >= 0) {
                settingsPopupWindow.currentHue = h > 1.0 ? (h / 360.0) : h;
            }
            
            settingsPopupWindow.currentSat = isNaN(s) || s === undefined ? 0.0 : s;
            settingsPopupWindow.currentVal = isNaN(v) || v === undefined ? 1.0 : v;
            colorHexInput.text = ("" + c).toUpperCase();
        } else {
            focusDelayTimer.stop();
            settingsPopupWindow.animateActive = false;
            settingsPopupWindow.showFontPicker = false;
            settingsPopupWindow.showColorPicker = false;
        }
    }
}