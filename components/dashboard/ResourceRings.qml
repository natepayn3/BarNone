import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../configs"

Item {
    id: ringsRoot
    width: parent.width

    property real sysCpu: 0.0
    property real sysGpu: 0.0
    property real sysRam: 0.0
    property real sysDisk: 0.0

    property var lastCpuTotal: 0
    property var lastCpuIdle: 0

    property alias activeModel: globalProcessModel
    property string activeLabel: ""
    property bool listActive: false

    FontConfig { id: fc }

    ListModel {
        id: globalProcessModel
    }

    // Inline Comment: Instantly purge stale rows on collapse so they don't pop up on next expand
    onListActiveChanged: {
        if (!listActive) {
            globalProcessModel.clear();
        }
    }

    // Inline Comment: This timer lets the tray expand smoothly before firing the heavy process commands
    Timer {
        id: deferFetchTimer
        interval: 300 // Slightly longer than the expansion animation duration
        repeat: false
        onTriggered: {
            allProcessesFetcher.running = true;
        }
    }

    Timer {
        interval: 3000
        running: ringsRoot.visible
        repeat: true; triggeredOnStart: true
        onTriggered: { 
            cpuStatReader.reload();
            memInfoReader.reload();
            if (!diskGpuProc.running) diskGpuProc.running = true; 
        }
    }

    // Inline Comment: Master hitbox handles instant geometry activation, then staggers data fetching
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
            // Signal the parent layout to expand instantly
            ringsRoot.activeLabel = "System";
            ringsRoot.listActive = true;
            
            // Defer the heavy system processing until the animation finishes
            deferFetchTimer.start();
        }
    }

    Process {
        id: allProcessesFetcher
        command: ["/bin/fish", "-c", "echo '___CAT___|CPU'; ps -eo pid,pcpu,comm --sort=-pcpu | head -n 9 | tail -n +2 | awk -v cores=(nproc) '{print $1\"|\"$2/cores\"|\"$3}'; echo '___CAT___|GPU'; nvidia-smi --query-compute-apps=pid,used_memory,name --format=csv,noheader,nounits 2>/dev/null | head -n 8 | awk -F', ' '{print $1\"|\"$2\" MB|\"$3}'; echo '___CAT___|RAM'; ps -eo pid,pmem,comm --sort=-pmem | head -n 9 | tail -n +2 | awk '{print $1\"|\"$2\"|\"$3}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parsedItems = [];
                let currentCat = "CPU";
                let lines = this.text.trim().split("\n");
                
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue;
                    let parts = lines[i].split("|");
                    
                    if (parts[0] === "___CAT___") {
                        currentCat = parts[1];
                    } else if (parts.length === 3) {
                        let percentage = currentCat === "GPU" ? parts[1] : Math.round(parseFloat(parts[1])) + "%";
                        if (currentCat !== "GPU" && Math.round(parseFloat(parts[1])) > 100) percentage = "100%";
                        
                        parsedItems.push({
                            "category": currentCat,
                            "metric": percentage,
                            "name": parts[2],
                            "pid": parts[0]
                        });
                    }
                }

                // Atomic bulk update prevents multi-frame layout thrashing
                ringsRoot.activeModel.clear();
                for (let item of parsedItems) {
                    ringsRoot.activeModel.append(item);
                }
            }
        }
    }

    component StatRingItem : Item {
        id: ringRow
        width: 84  
        height: 84

        property string label: ""
        property real value: 0.0

        // Performance Optimization & Sharpness Fix
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4
        layer.textureSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)

        Shape {
            anchors.fill: parent

            ShapePath {
                fillColor: "transparent"
                strokeColor: fc.trackBackground
                strokeWidth: 3.5
                PathAngleArc { 
                    centerX: 42; centerY: 42; radiusX: 37; radiusY: 37
                    startAngle: -90; sweepAngle: 360
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: shellConfig.themeText
                strokeWidth: 3.5
                capStyle: ShapePath.RoundCap
                PathAngleArc { 
                    centerX: 42; centerY: 42; radiusX: 37; radiusY: 37
                    startAngle: -90; sweepAngle: Math.max(0.1, ringRow.value * 360)
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: -1

            Text {
                text: ringRow.label
                color: Qt.rgba(shellConfig.themeText.r, shellConfig.themeText.g, shellConfig.themeText.b, 0.5)
                font.family: fc.mainFont
                font.pixelSize: 10
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
                Component.onCompleted: fc.applyOutline(this, fc.overlayBackground)
            }
            Text {
                text: Math.round(ringRow.value * 100) + "%"
                color: shellConfig.themeText
                font.family: fc.mainFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
                Component.onCompleted: fc.applyOutline(this, fc.overlayBackground)
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        StatRingItem { 
            label: "CPU"
            value: ringsRoot.sysCpu
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
        StatRingItem { 
            label: "GPU"
            value: ringsRoot.sysGpu
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
        StatRingItem { 
            label: "RAM"
            value: ringsRoot.sysRam
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
        StatRingItem { 
            label: "DISK"
            value: ringsRoot.sysDisk
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
    }

    FileView {
        id: memInfoReader
        path: "/proc/meminfo"
        onTextChanged: {
            let lines = text().split('\n'), total = 0, avail = 0;
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].startsWith("MemTotal:")) total = parseInt(lines[i].replace(/\D/g, ''));
                if (lines[i].startsWith("MemAvailable:")) avail = parseInt(lines[i].replace(/\D/g, ''));
            }
            if (total > 0) ringsRoot.sysRam = (total - avail) / total;
        }
    }

    FileView {
        id: cpuStatReader
        path: "/proc/stat"
        onTextChanged: {
            let parts = text().split('\n')[0].split(/\s+/).filter(Boolean);
            if (parts.length >= 5) {
                let user = parseInt(parts[1])||0, nice = parseInt(parts[2])||0, sys = parseInt(parts[3])||0, idle = parseInt(parts[4])||0, io = parseInt(parts[5])||0, irq = parseInt(parts[6])||0, soft = parseInt(parts[7])||0;
                let total = user + nice + sys + idle + io + irq + soft;
                let totalDelta = total - ringsRoot.lastCpuTotal, idleDelta = idle - ringsRoot.lastCpuIdle;
                if (totalDelta > 0) ringsRoot.sysCpu = (totalDelta - idleDelta) / totalDelta;
                ringsRoot.lastCpuTotal = total; ringsRoot.lastCpuIdle = idle;
            }
        }
    }

    Process {
        id: diskGpuProc
        command: ["sh", "-c", "cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || cat /sys/class/hwmon/hwmon*/device/gpu_busy_percent 2>/dev/null || nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo 0; df / | awk 'NR==2 {print $5}' | sed 's/%//'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let lines = this.text.trim().split("\n");
                    if (lines.length >= 2) {
                        let rawGpu = parseFloat(lines[0]) || 0.0;
                        ringsRoot.sysGpu = rawGpu / 100.0;
                        let rawDisk = parseFloat(lines[1]) || 0.0;
                        ringsRoot.sysDisk = rawDisk / 100.0;
                    }
                } catch(e) {}
                diskGpuProc.running = false;
            }
        }
    }
}