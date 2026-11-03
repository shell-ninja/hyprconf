import QtQuick
import "."
import "widgets"

Item {
    id: root
    property string widgetId: ""
    property string zone: "start"

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : (typeof bar !== "undefined" && bar ? bar.barH : 36)

    Loader {
        id: loader
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: {
            switch (root.widgetId) {
                case "launcher": return compLauncher
                case "tray": return compTray
                case "workspaces": return compWorkspaces
                case "weather": return compWeather
                case "power_profile": return compPowerProfile
                case "media": return compMedia
                case "clock": return compClock
                case "notification": return compNotification
                case "pkg_update": return compPkgUpdate
                case "quick_toggles": return compQuickToggles
                case "caffeine": return compCaffeine
                case "nightlight": return compNightlight
                case "clipboard": return compClipboard
                case "system_info": return compSystemInfo
                case "volume": return compVolume
                case "power": return compPower
                case "battery": return compBattery
                case "network": return compNetwork
                case "active_window": return compActiveWindow
                case "visualizer": return compVisualizer
                case "dnd": return compDnd
                default: return null
            }
        }
    }

    Component { id: compLauncher; BarLauncher {} }
    Component { id: compTray; BarTray {} }
    Component { id: compWorkspaces; BarWorkspaces {} }
    Component { id: compWeather; BarWeather {} }
    Component { id: compPowerProfile; BarPowerProfile {} }
    Component { id: compMedia; BarMedia {} }
    Component { id: compClock; BarClock {} }
    Component { id: compNotification; BarNotification {} }
    Component { id: compPkgUpdate; BarPkgUpdate {} }
    Component { id: compQuickToggles; BarQuickToggles {} }
    Component { id: compCaffeine; BarCaffeine {} }
    Component { id: compNightlight; BarNightlight {} }
    Component { id: compClipboard; BarClipboard {} }
    Component { id: compSystemInfo; BarSystemInfo {} }
    Component { id: compVolume; BarVolume {} }
    Component { id: compPower; BarPower {} }
    Component { id: compBattery; BarBattery {} }
    Component { id: compNetwork; BarNetwork {} }
    Component { id: compActiveWindow; BarActiveWindow {} }
    Component { id: compVisualizer; BarVisualizer {} }
    Component { id: compDnd; BarDnd {} }
}

