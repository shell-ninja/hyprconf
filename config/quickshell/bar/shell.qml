import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    // Invisible 1px windows that only reserve screen space (a PanelWindow
    // anchored on all four edges cannot carry a usable exclusive zone itself).
    component Reserve: PanelWindow {
        property string side: "top"
        property int zone: 12

        anchors {
            top: side !== "bottom"
            bottom: side !== "top"
            left: side !== "right"
            right: side !== "left"
        }
        implicitWidth: 1
        implicitHeight: 1
        exclusiveZone: zone
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

            Bar { screen: scope.modelData }
            Reserve { screen: scope.modelData; side: "top"; zone: 44 }
            Reserve { screen: scope.modelData; side: "left"; zone: 12 }
            Reserve { screen: scope.modelData; side: "right"; zone: 12 }
            Reserve { screen: scope.modelData; side: "bottom"; zone: 12 }
        }
    }
}
