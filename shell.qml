//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import "components"
import "components/dashboard"
import "configs"
import "popups"

ShellRoot {
    id: shellRoot
    
    // --- GLOBAL TRACKING STATES ---
    property string activeOverviewMonitor: ""
    property bool audioPopupActive: false
    property var activeNotifications: []
    property bool dndActive: false

    IpcHandler {
        target: "overview"
        function toggle(): void {
            if (shellRoot.activeOverviewMonitor !== "") {
                shellRoot.activeOverviewMonitor = "";
            } else {
                let monitor = Hyprland.activeMonitor;
                if (monitor && monitor.name) {
                    shellRoot.activeOverviewMonitor = monitor.name;
                } else if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.monitor) {
                    // Pull the display identifier natively from the active workspace profile context
                    shellRoot.activeOverviewMonitor = Hyprland.focusedWorkspace.monitor.name;
                }
            }
        }
    }

    QtObject {
        id: notifBroadcaster
        signal broadcast(string summary, string body)
    }

    ModuleConfig { id: shellConfig }

    AppLauncher { id: appLauncherModule }
    Wallpaper { id: wallpaperWindowModule; rootShell: shellRoot }

    StatusTray {
        id: topStatusTraySurface
    }

    // Instantiated high up so that downstream dashboards can cleanly resolve it
    NotificationServer {
        id: notifServer
        bodySupported: true
        actionsSupported: false
        
        onNotification: (notification) => {
            notifBroadcaster.broadcast(notification.summary, notification.body);
        }
    }

    // --- MONITOR REPEATERS ---
    Variants {
        model: Quickshell.screens
        Dock {
            required property var modelData
            screen: modelData
            launcherModule: appLauncherModule
            wallpaperModule: wallpaperWindowModule
        }
    }

    Variants {
        model: Quickshell.screens
        WorkspaceDock {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        Dashboard {
            required property var modelData
            screen: modelData
            notificationModel: notifServer.trackedNotifications.values
            dndActive: shellRoot.dndActive
            onDndToggled: shellRoot.dndActive = !shellRoot.dndActive
        }
    }

    Variants {
        model: Quickshell.screens
        VolumeOsd {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        NotificationOsd {
            required property var modelData
            screen: modelData
            broadcaster: notifBroadcaster
            dndActive: shellRoot.dndActive
        }
    }

    // Placed at the bottom to guarantee all upstream services are fully evaluated
    Variants {
        model: Quickshell.screens
        WorkspaceOverview {
            required property var modelData
            screen: modelData
            visible: shellRoot.activeOverviewMonitor === modelData.name
        }
    }
}
