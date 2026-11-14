import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "./dock_mod" as DockMod
import "./widgets_mod" as WidgetsMod
import "./island_mod" as IslandMod

ShellRoot {
    DockMod.DockLayer {}
    WidgetsMod.DesktopWidgetsLayer {}
    IslandMod.WallpaperFx {}

    Process {
        id: pkgNotifyOnceProc
        command: ["python3", (Quickshell.env("HOME") || "/home") + "/.hyprconf/hypr/scripts/py/pkgupdate-notifier.py", "--once"]
    }
    Timer {
        id: pkgBootTimer
        interval: 90000
        running: true
        repeat: false
        onTriggered: if (!pkgNotifyOnceProc.running) pkgNotifyOnceProc.running = true
    }
    Timer {
        id: pkgPeriodicTimer
        interval: 18000000
        running: true
        repeat: true
        onTriggered: if (!pkgNotifyOnceProc.running) pkgNotifyOnceProc.running = true
    }

    component Reserve: PanelWindow {
        property string side: "top"
        property int zone: 44

        anchors {
            top: side !== "bottom"
            bottom: side !== "top"
            left: side !== "right"
            right: side !== "left"
        }
        implicitWidth: 1
        implicitHeight: 1
        exclusiveZone: visible ? zone : 0
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "bar-zone"
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: scope
            required property var modelData

            Bar {
                id: mainBar
                screen: scope.modelData
            }

            Reserve {
                screen: scope.modelData
                side: "top"
                zone: (mainBar.capsuleStyle === "glass") ? mainBar.barH : mainBar.totalBarHeight
            }

            Reserve {
                screen: scope.modelData
                side: "left"
                zone: (mainBar.capsuleStyle === "glass") ? mainBar.frameThickness : 12
                visible: (mainBar.capsuleStyle === "glass") || mainBar.enableScreenFrame
            }
            Reserve {
                screen: scope.modelData
                side: "right"
                zone: (mainBar.capsuleStyle === "glass") ? mainBar.frameThickness : 12
                visible: (mainBar.capsuleStyle === "glass") || mainBar.enableScreenFrame
            }
            Reserve {
                screen: scope.modelData
                side: "bottom"
                zone: (mainBar.capsuleStyle === "glass") ? mainBar.frameThickness : 12
                visible: (mainBar.capsuleStyle === "glass") || mainBar.enableScreenFrame
            }
        }
    }
}
