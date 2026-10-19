import QtQuick
import "."

Item {
    id: root

    property string moduleKey: ""
    property string title: ""
    property real normX: 0.5
    property real normY: 0.5
    property real widgetScale: 1.0
    property real previewScale: 1.0
    readonly property real effectiveScale: widgetScale * previewScale
    property real canvasWidth: 600
    property real canvasHeight: 400
    property bool isSelected: false
    property bool isDragging: dragArea.drag.active
    property bool isResizing: resizeMouse.drag.active

    signal positionDropped(real newNormX, real newNormY)
    signal scaleModified(real newScale)
    signal widgetSelected(string key)

    default property alias content: contentWrapper.data

    width: (contentWrapper.childrenRect.width > 0 ? contentWrapper.childrenRect.width : 100) * effectiveScale
    height: (contentWrapper.childrenRect.height > 0 ? contentWrapper.childrenRect.height : 50) * effectiveScale

    function updatePositionFromNorm() {
        if (!isDragging && canvasWidth > 0 && canvasHeight > 0) {
            x = Math.max(2, Math.min(canvasWidth - width - 2, Math.round(normX * canvasWidth - width / 2)))
            y = Math.max(2, Math.min(canvasHeight - height - 2, Math.round(normY * canvasHeight - height / 2)))
        }
    }

    onNormXChanged: updatePositionFromNorm()
    onNormYChanged: updatePositionFromNorm()
    onCanvasWidthChanged: updatePositionFromNorm()
    onCanvasHeightChanged: updatePositionFromNorm()
    onWidgetScaleChanged: updatePositionFromNorm()
    onPreviewScaleChanged: updatePositionFromNorm()
    onWidthChanged: updatePositionFromNorm()
    onHeightChanged: updatePositionFromNorm()

    Component.onCompleted: updatePositionFromNorm()

    // Hover & Active Selection / Drag Bounding Ring
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 14
        color: root.isDragging
            ? Theme.alpha(Theme.accent, 0.16)
            : (root.isSelected ? Theme.alpha(Theme.accent, 0.08) : "transparent")
        border.width: (root.isSelected || root.isDragging || root.isResizing) ? 2 : (dragArea.containsMouse ? 1 : 0)
        border.color: (root.isSelected || root.isDragging || root.isResizing)
            ? Theme.accent
            : Theme.alpha(Theme.accent, 0.60)
        Behavior on border.width { NumberAnimation { duration: 90 } }
        Behavior on color { ColorAnimation { duration: 110 } }
    }

    // Top Coordinate & Scale Pill Badge
    Rectangle {
        anchors.bottom: parent.top
        anchors.bottomMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        height: 20
        width: dragTagText.implicitWidth + 16
        radius: 10
        color: Theme.alpha(Theme.background, 0.94)
        border.width: 1
        border.color: (root.isSelected || root.isDragging || root.isResizing) ? Theme.accent : Theme.alpha(Theme.accent, 0.40)
        visible: root.isSelected || root.isDragging || root.isResizing || dragArea.containsMouse
        z: 200

        Text {
            id: dragTagText
            anchors.centerIn: parent
            text: root.title + " (" + Math.round(((root.x + root.width / 2) / Math.max(1, root.canvasWidth)) * 100) + "%, "
                + Math.round(((root.y + root.height / 2) / Math.max(1, root.canvasHeight)) * 100) + "%) • "
                + root.widgetScale.toFixed(2) + "x"
            color: Theme.accent
            font.family: "Outfit"
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }
    }

    // Scaled Content Wrapper
    Item {
        id: contentWrapper
        scale: root.effectiveScale
        transformOrigin: Item.TopLeft
        x: contentWrapper.childrenRect.x < 0 ? -contentWrapper.childrenRect.x * root.effectiveScale : 0
        y: contentWrapper.childrenRect.y < 0 ? -contentWrapper.childrenRect.y * root.effectiveScale : 0
    }

    // Drag Mouse Area
    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: root
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 4
        drag.maximumX: Math.max(4, root.canvasWidth - root.width - 4)
        drag.minimumY: 4
        drag.maximumY: Math.max(4, root.canvasHeight - root.height - 4)

        onPressed: {
            root.widgetSelected(root.moduleKey)
        }

        onReleased: {
            var rawCenterX = root.x + root.width / 2
            var rawCenterY = root.y + root.height / 2

            // Magnetic snap to center X (within 4%)
            if (Math.abs(rawCenterX - root.canvasWidth / 2) < root.canvasWidth * 0.04) {
                rawCenterX = root.canvasWidth / 2
                root.x = Math.round(rawCenterX - root.width / 2)
            }
            // Magnetic snap to center Y (within 4%)
            if (Math.abs(rawCenterY - root.canvasHeight / 2) < root.canvasHeight * 0.04) {
                rawCenterY = root.canvasHeight / 2
                root.y = Math.round(rawCenterY - root.height / 2)
            }

            var calcNormX = Math.max(0.05, Math.min(0.95, rawCenterX / Math.max(1, root.canvasWidth)))
            var calcNormY = Math.max(0.05, Math.min(0.95, rawCenterY / Math.max(1, root.canvasHeight)))

            root.positionDropped(calcNormX, calcNormY)
        }
    }

    // Bottom-Right Corner Resize Handle
    Rectangle {
        id: resizeHandle
        width: 18
        height: 18
        radius: 9
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -5
        visible: root.isSelected || dragArea.containsMouse || root.isResizing
        color: resizeMouse.containsMouse || root.isResizing ? Theme.accent : Theme.alpha(Theme.background, 0.90)
        border.width: 1.5
        border.color: Theme.accent
        z: 300

        Text {
            anchors.centerIn: parent
            text: "⤡"
            color: resizeMouse.containsMouse || root.isResizing ? Theme.on_primary : Theme.accent
            font.pixelSize: 10
            font.weight: Font.Bold
        }

        MouseArea {
            id: resizeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor

            property real startWindowX: 0
            property real startWindowY: 0
            property real startScale: 1.0

            onPressed: function(mouse) {
                root.widgetSelected(root.moduleKey)
                var pt = resizeMouse.mapToItem(null, mouse.x, mouse.y)
                startWindowX = pt.x
                startWindowY = pt.y
                startScale = root.widgetScale
            }

            onPositionChanged: function(mouse) {
                if (pressed) {
                    var pt = resizeMouse.mapToItem(null, mouse.x, mouse.y)
                    var delta = (pt.x - startWindowX + pt.y - startWindowY) / (120.0 * Math.max(0.2, root.previewScale))
                    var newS = Math.max(0.55, Math.min(2.20, startScale + delta))
                    root.widgetScale = Math.round(newS * 20) / 20.0
                    root.scaleModified(root.widgetScale)
                }
            }
        }
    }

    Item {
        id: resizeProxy
    }
}
