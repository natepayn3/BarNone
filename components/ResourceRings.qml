import QtQuick
import QtQuick.Shapes
import Quickshell.Io

Column {
    id: ringsRoot
    spacing: 16
    width: parent.width

    property real sysCpu: 0.0
    property real sysGpu: 0.0
    property real sysRam: 0.0
    property real sysDisk: 0.0

    property var lastCpuTotal: 0
    property var lastCpuIdle: 0

    FontConfig { id: fc }

    Timer {
        interval: 3000
        running: ringsRoot.visible;
        repeat: true; triggeredOnStart: true
        onTriggered: { 
            cpuStatReader.reload();
            memInfoReader.reload();
            if (!diskGpuProc.running) diskGpuProc.running = true; 
        }
    }

    component StatRingItem : Item {
        id: ringRow
        width: 80  
        height: 80

        property string label: ""
        property real value: 0.0

        Shape {
            anchors.fill: parent
            layer.enabled: true; layer.samples: 4
            
            ShapePath {
                fillColor: "transparent";
                strokeColor: Qt.rgba(1, 1, 1, 0.06); 
                strokeWidth: 2.5 
                PathAngleArc { 
                    centerX: 40; centerY: 40; 
                    radiusX: 36; radiusY: 36; 
                    startAngle: -90; sweepAngle: 360 
                }
            }
            ShapePath {
                fillColor: "transparent";
                strokeColor: "#ffffff"; 
                strokeWidth: 2.5 
                capStyle: ShapePath.RoundCap
                PathAngleArc { 
                    centerX: 40; centerY: 40; 
                    radiusX: 36; radiusY: 36; 
                    startAngle: -90; sweepAngle: Math.max(0.1, ringRow.value * 360) 
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: -1

            Text {
                text: ringRow.label
                color: Qt.rgba(1, 1, 1, 0.4)
                font.family: fc.mainFont
                font.pixelSize: 11 
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
                Component.onCompleted: fc.applySmoothing(this)
            }
            Text {
                text: Math.round(ringRow.value * 100) + "%"
                color: "#ffffff"
                font.family: fc.mainFont
                font.pixelSize: 13 
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
                Component.onCompleted: fc.applySmoothing(this)
            }
        }
    }

    // 🎯 Lock the inner column layout container to stick edge-to-edge
    Column {
        width: parent.width
        spacing: 14
        anchors.right: parent.right
        
        // 🎯 Every item cleanly aligned to the right wall to line up vertically
        StatRingItem { label: "CPU"; value: ringsRoot.sysCpu; anchors.right: parent.right }
        StatRingItem { label: "GPU"; value: ringsRoot.sysGpu; anchors.right: parent.right }
        StatRingItem { label: "RAM"; value: ringsRoot.sysRam; anchors.right: parent.right }
        StatRingItem { label: "DISK"; value: ringsRoot.sysDisk; anchors.right: parent.right }
    }

    FileView {
        id: memInfoReader;
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
        id: cpuStatReader;
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
                        ringsRoot.sysGpu = rawGpu > 1.0 ? rawGpu / 100.0 : rawGpu;
                        ringsRoot.sysDisk = (parseFloat(lines[1]) || 0.0) / 100.0;
                    }
                } catch(e) {}
                diskGpuProc.running = false;
            }
        }
    }
}