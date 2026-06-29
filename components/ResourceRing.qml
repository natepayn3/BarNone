import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    width: 100
    height: 100

    // --- PUBLIC INTERFACE ---
    required property string ringName 
    property real value: 0.0 

    onValueChanged: canvas.requestPaint()

    // --- INTERNAL DATA METRIC AUTOMATION ---
    Component.onCompleted: {
        if (ringName === "CPU") {
            cpuProc.running = true;
        } else if (ringName === "GPU") {
            gpuProc.running = true;
        } else if (ringName === "RAM") {
            ramProc.running = true;
        } else if (ringName === "DISK") {
            diskTimer.running = true;
            diskProc.running = true;
        }
    }

    // --- CPU TELEMETRY ---
    Process {
        id: cpuProc
        command: ["sh", "-c", "while true; do head -n1 /proc/stat; sleep 1; done"]
        running: false
        
        property real prevTotal: 0
        property real prevIdle: 0

        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(/\s+/);
                if (parts.length < 5) return;
                
                let user = parseFloat(parts[1]);
                let nice = parseFloat(parts[2]);
                let system = parseFloat(parts[3]);
                let idle = parseFloat(parts[4]);
                
                let work = user + nice + system;
                let total = work + idle;
                let diffWork = work - cpuProc.prevTotal;
                let diffTotal = total - cpuProc.prevIdle;
                if (diffTotal > 0) {
                    root.value = Math.max(0.0, Math.min(1.0, diffWork / diffTotal));
                }
                
                cpuProc.prevTotal = work;
                cpuProc.prevIdle = total;
            }
        }
    }

    // --- GPU TELEMETRY (CROSS-VENDOR PARSER) ---
    Process {
        id: gpuProc
        command: ["fish", "-c", "
            if command -sq nvidia-smi
                while true; nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits; sleep 1; end
            else if test -d /sys/class/drm/card0/device/gpu_busy_percent
                while true; cat /sys/class/drm/card0/device/gpu_busy_percent; sleep 1; end
            else if command -sq intel_gpu_top
                while true; intel_gpu_top -J -s 1 | grep -m1 '\"Render/3D/0\":' | tr -d '[:space:]\"Render/3D/0:,'; sleep 1; end
            else
                while true; echo 0; sleep 1; end
            end
        "]
        running: false
        stdout: SplitParser {
            onRead: data => {
                let val = parseFloat(data.trim());
                if (!isNaN(val)) {
                    root.value = val > 1.0 ? val / 100.0 : val;
                }
            }
        }
    }

    // --- RAM TELEMETRY ---
    Process {
        id: ramProc
        command: ["sh", "-c", "while true; do grep -E 'MemTotal|MemAvailable' /proc/meminfo; sleep 1; done"]
        running: false
        
        property real totalMem: 1

        stdout: SplitParser {
            onRead: data => {
                let line = data.trim();
                let val = parseFloat(line.replace(/[^0-9]/g, ''));
                if (isNaN(val)) return;

                if (line.includes("MemTotal:")) {
                    ramProc.totalMem = val;
                } else if (line.includes("MemAvailable:")) {
                    root.value = (ramProc.totalMem - val) / ramProc.totalMem;
                }
            }
        }
    }

    // --- DISK TELEMETRY ---
    Process {
        id: diskProc
        command: ["sh", "-c", "df --output=pcent / | tail -n 1 | tr -d ' %'"]
        running: false
         
        stdout: SplitParser {
            onRead: data => {
                let pcent = parseFloat(data.trim());
                if (!isNaN(pcent)) {
                    root.value = pcent / 100.0;
                }
            }
        }
    }

    Timer {
        id: diskTimer
        interval: 3600000
        running: false
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            diskProc.running = false;
            diskProc.running = true;
        }
    }

    // --- VISUAL CANVAS RENDERER ---
    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var centreX = width / 2;
            var centreY = height / 2;
            var radius = (width / 2) - 10;

            // --- BACKGROUND TRACK ---
            ctx.beginPath();
            ctx.strokeStyle = "rgba(255, 255, 255, 0.05)";
            ctx.lineWidth = 3;
            ctx.arc(centreX, centreY, radius, 0, 2 * Math.PI, false);
            ctx.stroke();

            // --- PROGRESS RING WITH OUTLINE/SHADOW DECORATION ---
            ctx.beginPath();
            ctx.strokeStyle = "rgba(255, 255, 255, 0.7)";
            ctx.lineWidth = 6;
            ctx.lineCap = "round";
            
            // Inject the outline matrix shadow properties
            ctx.shadowColor = "rgba(0, 0, 0, 0.4)"; // Matches text styleColor
            ctx.shadowBlur = 3;                     // Soft outline spread
            ctx.shadowOffsetX = 0;
            ctx.shadowOffsetY = 1;                  // Subtle vertical drop offset
            
            var startAngle = -Math.PI / 2;
            var endAngle = startAngle + (root.value * 2 * Math.PI);
            
            ctx.arc(centreX, centreY, radius, startAngle, endAngle, false);
            ctx.stroke();
            
            // Reset shadows so future draw calls on this context don't stack effects
            ctx.shadowColor = "transparent";
        }
    }

    // Added style and styleColor attributes to create the drop-shadow/high-contrast border matrix
    Text {
        text: Math.round(root.value * 100) + "%"
        font.family: "Google Sans Flex" 
        font.pixelSize: 20
        font.weight: Font.Light
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.35)
        color: dockHitbox.isPinned ? Qt.rgba(1, 1, 1, 0.8) : "transparent"
        anchors.centerIn: parent

        Behavior on color { ColorAnimation { duration: 180 } }
    }

    Text {
        text: root.ringName
        font.family: "Google Sans Flex"
        font.pixelSize: 12
        font.weight: Font.DemiBold
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.35)
        color: dockHitbox.isPinned ? Qt.rgba(1, 1, 1, 0.5) : "transparent"
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 25

        Behavior on color { ColorAnimation { duration: 180 } }
    }
}
