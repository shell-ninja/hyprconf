import QtQuick

Item {
    id: root

    property string moduleKey: ""
    property string title: ""
    property real normX: 0.5
    property real normY: 0.5
    property real canvasWidth: 350
    property real canvasHeight: 550
    property bool isDragging: dragArea.drag.active

    signal positionDropped(real newNormX, real newNormY)

    default property alias content: contentWrapper.data

    width: contentWrapper.childrenRect.width > 0 ? contentWrapper.childrenRect.width : 100
    height: contentWrapper.childrenRect.height > 0 ? contentWrapper.childrenRect.height : 40

    function updatePositionFromNorm() {
        if (!isDragging && canvasWidth > 0 && canvasHeight > 0) {
            x = Math.max(4, Math.min(canvasWidth - width - 4, Math.round(normX * canvasWidth - width / 2)))
            y = Math.max(4, Math.min(canvasHeight - height - 4, Math.round(normY * canvasHeight - height / 2)))
        }
    }

    onNormXChanged: updatePositionFromNorm()
    onNormYChanged: updatePositionFromNorm()
    onCanvasWidthChanged: updatePositionFromNorm()
    onCanvasHeightChanged: updatePositionFromNorm()
    onWidthChanged: updatePositionFromNorm()
    onHeightChanged: updatePositionFromNorm()

    Component.onCompleted: updatePositionFromNorm()

    // Hover & Active Drag Visual Feedback Ring
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 14
        color: root.isDragging ? Theme.alpha(Theme.accent, 0.16) : "transparent"
        border.width: root.isDragging ? 2 : (dragArea.containsMouse ? 1 : 0)
        border.color: root.isDragging ? Theme.accent : Theme.alpha(Theme.accent, 0.65)
        Behavior on border.width { NumberAnimation { duration: 90 } }
        Behavior on color { ColorAnimation { duration: 110 } }
    }

    // Dragging / Hover Coordinate Pill Badge
    Rectangle {
        anchors.bottom: parent.top
        anchors.bottomMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        height: 20
        width: dragTagText.implicitWidth + 14
        radius: 10
        color: Theme.alpha(Theme.background, 0.92)
        border.width: 1
        border.color: root.isDragging ? Theme.accent : Theme.alpha(Theme.accent, 0.40)
        visible: root.isDragging || dragArea.containsMouse
        z: 200

        Text {
            id: dragTagText
            anchors.centerIn: parent
            text: root.title + (root.isDragging ? (" (" + Math.round(((root.x + root.width / 2) / Math.max(1, root.canvasWidth)) * 100) + "%, " + Math.round(((root.y + root.height / 2) / Math.max(1, root.canvasHeight)) * 100) + "%)") : " (Drag)")
            color: Theme.accent
            font.family: "Outfit"
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }
    }

    Item {
        id: contentWrapper
        x: contentWrapper.childrenRect.x < 0 ? -contentWrapper.childrenRect.x : 0
        y: contentWrapper.childrenRect.y < 0 ? -contentWrapper.childrenRect.y : 0
    }

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

        onReleased: {
            var rawCenterX = root.x + root.width / 2
            var rawCenterY = root.y + root.height / 2

            // Magnetic snap to center X (if within 4% of canvas width)
            if (Math.abs(rawCenterX - root.canvasWidth / 2) < root.canvasWidth * 0.04) {
                rawCenterX = root.canvasWidth / 2
                root.x = Math.round(rawCenterX - root.width / 2)
            }

            // Magnetic snap to center Y (if within 4% of canvas height)
            if (Math.abs(rawCenterY - root.canvasHeight / 2) < root.canvasHeight * 0.04) {
                rawCenterY = root.canvasHeight / 2
                root.y = Math.round(rawCenterY - root.height / 2)
            }

            var calcNormX = Math.max(0.05, Math.min(0.95, rawCenterX / Math.max(1, root.canvasWidth)))
            var calcNormY = Math.max(0.05, Math.min(0.95, rawCenterY / Math.max(1, root.canvasHeight)))

            root.positionDropped(calcNormX, calcNormY)
        }
    }
}
