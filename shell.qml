import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "components"

ShellRoot {
    id: shellRoot

    // --- REFACTORED MODULAR COMPONENTS ---
    AppLauncher {
        id: appLauncherModule
    }

    // Wallpaper configuration interface module
    Wallpaper {
        id: wallpaperWindowModule
        rootShell: shellRoot
    }

    // Primary bottom system dashboard launcher dock
    Dock {
        id: desktopDock
        launcherModule: appLauncherModule
        wallpaperModule: wallpaperWindowModule
    }

    // Dynamic workspace monitoring panel (Left edge)
    WorkspaceDock {
        id: leftWorkspaceDock
    }

    // Slide-out telemetry metric monitor panel (Right edge)
    ResourceDock {
        id: rightResourceDock
    }
}