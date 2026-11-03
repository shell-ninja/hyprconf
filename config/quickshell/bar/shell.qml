import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
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
