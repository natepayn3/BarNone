import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import QtQuick.Shapes
import Quickshell.Io
import Quickshell.Services.Notifications
import "../../configs"

PanelWindow {
    id: dashboardWindow

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-resource-dashboard"
    WlrLayershell.keyboardFocus: WlrLayershell.None
    exclusionMode: ExclusionMode.Ignore

    FontConfig { id: fc }

    property var notificationModel: notifServer.trackedNotifications

    anchors {
        right: true
    }

    implicitWidth: bgCard.width + 80
    implicitHeight: bgCard.height 
    color: "transparent"

    property bool wifiAvailable: false
    property bool wifiActive: false
    property bool btActive: false
    property bool caffeineActive: false

    property bool dndActive: false
    signal dndToggled()

    NotificationServer {
        id: notifServer
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: (notif) => {
            if (!dashboardWindow.dndActive) notif.tracked = true;
            else notif.dismiss();
        }
    }

    Process { id: wifiToggleProc; running: false }
    Process { id: btToggleProc; running: false }
    Process { id: caffeineToggleProc; running: false }

    Timer {
        id: statePoller
        interval: 3000
        running: dashboardWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiStateCheck.running = true;
            btStateCheck.running = true;
            checkHypridleProc.running = true;
        }
    }

    Process {
        id: wifiStateCheck
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE device | grep -q '^wifi:' && echo 'AVAILABLE' || echo 'MISSING'; nmcli radio wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 1) dashboardWindow.wifiAvailable = (lines[0] === "AVAILABLE");
                if (lines.length >= 2) dashboardWindow.wifiActive = dashboardWindow.wifiAvailable && (lines[1].trim() === "enabled");
                wifiStateCheck.running = false;
            }
        }
    }

    Process {
        id: btStateCheck
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo 'ON' || echo 'OFF'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                dashboardWindow.btActive = (this.text.trim() === "ON");
                btStateCheck.running = false;
            }
        }
    }

    Process {
        id: checkHypridleProc
        command: ["pgrep", "-x", "hypridle"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                dashboardWindow.caffeineActive = (this.text.trim() === "");
                checkHypridleProc.running = false;
            }
        }
    }

    mask: Region {
        Region { item: hotspotTrigger }
        Region { item: dashHitbox.isPinned ? bgCard : null }
        Region { item: dashHitbox.isPinned ? leftDashboardIcon : null }
    }

    Process {
        id: inlineProcessKiller
        onRunningChanged: {
            if (!running && resourceRingsComp !== null) {
                statePoller.triggered();
            }
        }
    }

    MouseArea {
        id: dashHitbox
        anchors.fill: parent
        hoverEnabled: true

        property bool stableHover: hotspotTrigger.containsMouse || cardHover.hovered || processPanelHover.hovered
        property bool isPinned: false

        onStableHoverChanged: {
            if (stableHover) {
                dismissTimer.stop();
                isPinned = true;
            } else {
                dismissTimer.start();
            }
        }

        MouseArea {
            id: hotspotTrigger
            width: 16
            height: parent.height
            anchors.right: parent.right
            hoverEnabled: true
        }

        Rectangle {
            id: bgCard
            width: resourceRingsComp.listActive ? 614 : 360
            height: mainSplitter.implicitHeight + (mainSplitter.anchors.margins * 2)
            
            x: dashHitbox.isPinned ? (parent.width - width - 6) : parent.width
            opacity: dashHitbox.isPinned ? 1.0 : 0.0

            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            color: shellConfig.colorBackground
            border.color: shellConfig.colorBorder
            border.width: 0
            radius: shellConfig.radiusValue

            Text {
                id: leftDashboardIcon
                text: "more"
                font.family: fc.iconFont
                font.pixelSize: 75
                color: shellConfig.colorBackground
                styleColor: shellConfig.colorBackground
                anchors.right: parent.left
                anchors.rightMargin: -2
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 0
            }

            HoverHandler { id: cardHover }

            RowLayout {
                id: mainSplitter
                anchors.fill: parent
                anchors.margins: 24
                spacing: 0

                ColumnLayout {
                    id: originalDashboardContent
                    Layout.preferredWidth: 312
                    Layout.fillHeight: true
                    spacing: 20

                    RowLayout {
                        id: topMetricsRow
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            id: leftColumn
                            Layout.fillWidth: true
                            spacing: 20

                            Clock { 
                                Layout.fillWidth: true
                                Component.onCompleted: {
                                    for (let i = 0; i < children.length; i++) {
                                        if (children[i].horizontalAlignment !== undefined) {
                                            children[i].horizontalAlignment = Text.AlignHCenter;
                                        }
                                    }
                                }
                            }
                            
                            RowLayout {
                                id: weatherCalendarRow
                                Layout.fillWidth: true
                                spacing: 12

                                Weather { 
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 40
                                    Layout.alignment: Qt.AlignTop
                                    
                                    Component.onCompleted: {
                                        for (let i = 0; i < children.length; i++) {
                                            if (children[i].horizontalAlignment !== undefined) {
                                                children[i].horizontalAlignment = Text.AlignHCenter;
                                            }
                                        }
                                    }
                                }

                                DashCalendar {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 60
                                    Layout.alignment: Qt.AlignTop
                                }
                            }
                            
                            VolumeSlider { 
                                Layout.fillWidth: true
                                Layout.topMargin: -12
                            }

                            BrightnessSlider { 
                                Layout.fillWidth: true
                                Layout.topMargin: 0
                            }

                            BatterySlider {
                                Layout.fillWidth: true
                                Layout.topMargin: 0
                            }
                        }

                        ColumnLayout {
                            id: rightColumn
                            Layout.preferredWidth: 84
                            Layout.fillHeight: true
                            spacing: 0

                            ResourceRings {
                                id: resourceRingsComp
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Toggles {
                        Layout.fillWidth: true
                        
                        wifiAvailable: dashboardWindow.wifiAvailable
                        wifiActive: dashboardWindow.wifiActive
                        btActive: dashboardWindow.btActive
                        caffeineActive: dashboardWindow.caffeineActive

                        dndActive: dashboardWindow.dndActive

                        onDndToggled: dashboardWindow.dndToggled()

                        onWifiToggled: {
                            dashboardWindow.wifiActive = !dashboardWindow.wifiActive
                            wifiToggleProc.command = ["sh", "-c", "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"]
                            wifiToggleProc.running = true
                        }
                        onBtToggled: {
                            dashboardWindow.btActive = !dashboardWindow.btActive
                            btToggleProc.command = ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"]
                            btToggleProc.running = true
                        }
                        onCaffeineToggled: {
                            dashboardWindow.caffeineActive = !dashboardWindow.caffeineActive
                            caffeineToggleProc.command = dashboardWindow.caffeineActive 
                                ? ["pkill", "-x", "hypridle"]
                                : ["hyprctl", "dispatch", "hl.dsp.exec_cmd('hypridle')"];
                            caffeineToggleProc.running = true
                        }
                    }

                    Item {
                        id: mediaWrapper
                        Layout.fillWidth: true
                        implicitHeight: childrenRect.height

                        Media { 
                            width: parent.width
                        }
                    }

                    Item {
                        id: notifWrapper
                        Layout.fillWidth: true
                        implicitHeight: childrenRect.height

                        Notifications { 
                            width: parent.width
                        }
                    }
                }

                Rectangle {
                    id: sideProcessPanel
                    Layout.preferredWidth: resourceRingsComp.listActive ? 234 : 0
                    Layout.leftMargin: resourceRingsComp.listActive ? 20 : 0
                    Layout.fillHeight: true
                    clip: true
                    color: "transparent"

                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on Layout.leftMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    HoverHandler { id: processPanelHover }

                    // Inline Comment: Decoupled container stops rigid layout snapping during width scaling
                    Item {
                        width: 234
                        height: parent.height

                        opacity: resourceRingsComp.listActive ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: processHeader
                            width: parent.width
                            height: 24
                            anchors.top: parent.top

                            Text {
                                text: "Top Resource Consumers"
                                color: shellConfig.themeText
                                font.family: fc.mainFont
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                            }
                            
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                width: 24
                                height: 24
                                radius: 6
                                color: closeListHitbox.containsMouse ? Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.15) : "transparent"

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    text: "×"
                                    color: closeListHitbox.containsMouse ? shellConfig.themeText : Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.5)
                                    font.family: fc.mainFont
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                    anchors.centerIn: parent
                                }
                                MouseArea {
                                    id: closeListHitbox
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: resourceRingsComp.listActive = false
                                }
                            }
                        }

                        ListView {
                            id: processListView
                            width: parent.width
                            anchors.top: processHeader.bottom
                            anchors.bottom: diskSpaceFooter.top
                            anchors.topMargin: 10
                            anchors.bottomMargin: 10
                            clip: true
                            model: resourceRingsComp.activeModel
                            spacing: 6
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            // Inline Comment: Smoothly fade in items completely avoiding coordinate thrashing
                            populate: Transition {
                                NumberAnimation { 
                                    property: "opacity"
                                    from: 0.0
                                    to: 1.0
                                    duration: 400 
                                    easing.type: Easing.OutCubic 
                                }
                            }
                            
                            add: Transition {
                                NumberAnimation { 
                                    property: "opacity"
                                    from: 0.0
                                    to: 1.0
                                    duration: 250 
                                }
                            }

                            section.property: "category"
                            section.delegate: Column {
                                width: 224
                                topPadding: section === "CPU" ? 2 : 14
                                bottomPadding: 6
                                spacing: 6
                                
                                Text {
                                    text: section
                                    color: shellConfig.themeText
                                    font.family: fc.mainFont
                                    font.pixelSize: 11
                                    font.weight: Font.ExtraBold
                                    font.capitalization: Font.AllUppercase
                                    opacity: 0.5
                                }
                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.1)
                                }
                            }

                            delegate: Rectangle {
                                width: 224
                                height: 28
                                color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.04)
                                radius: Math.max(2, shellConfig.radiusValue - 4)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 4

                                    Text {
                                        text: model.metric || ""
                                        color: shellConfig.themeText
                                        font.family: fc.mainFont
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        Layout.preferredWidth: 38
                                    }

                                    Text {
                                        text: model.name || ""
                                        color: shellConfig.themeText
                                        font.family: fc.mainFont
                                        font.pixelSize: 11
                                        font.weight: Font.Normal
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: killMouse.containsMouse ? Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.15) : "transparent"
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            text: "×"
                                            color: killMouse.containsMouse ? shellConfig.themeText : Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.4)
                                            anchors.centerIn: parent
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                        }

                                        MouseArea {
                                            id: killMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                inlineProcessKiller.command = ["kill", "-9", model.pid];
                                                inlineProcessKiller.running = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            id: diskSpaceFooter
                            width: parent.width
                            anchors.bottom: parent.bottom
                            bottomPadding: 8
                            spacing: 6

                            RowLayout {
                                width: parent.width
                                Text {
                                    text: "DISK SPACE"
                                    color: shellConfig.themeText
                                    font.family: fc.mainFont
                                    font.pixelSize: 11
                                    font.weight: Font.ExtraBold
                                    font.capitalization: Font.AllUppercase
                                    opacity: 0.5
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: Math.round(resourceRingsComp.sysDisk * 100) + "%"
                                    color: shellConfig.themeText
                                    font.family: fc.mainFont
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    opacity: 0.5
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.b, shellConfig.themeText.g, 0.1)

                                Rectangle {
                                    width: parent.width * resourceRingsComp.sysDisk
                                    height: parent.height
                                    radius: 3
                                    color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.b, shellConfig.themeText.g, 0.6)
                                    
                                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: dismissTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            dashHitbox.isPinned = false;
            resourceRingsComp.listActive = false; 
        }
    }
}