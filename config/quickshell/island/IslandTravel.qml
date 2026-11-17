import QtQuick

// ═══════════════════════════════════════════════════════════════════════════
// ISLAND TRAVEL — water-drop perimeter journey
// ═══════════════════════════════════════════════════════════════════════════
// The island turns into a gel drop for the trip around the screen edge:
//
//   docked pill ─► stretch to the departure corner ─► squeeze into a ball
//               ─► bounce off the departure corner
//               ─► stretch into a hanging drip ─► free fall down the bezel
//               ─► impact · lift off the surface · second squash · rebound
//               ─► hold ─► glide home ─► jelly wobble ─► settle into the pill
//
// A velocity-driven ghost trail smears the body while it is in motion.
//
// The droplet never rotates; deformation is expressed purely through
// width/height/radius. Paired animations (x/width and y/height) share the same
// easing and duration whenever an edge must stay welded to a bezel, so the
// invariant also holds on intermediate frames, not just at phase boundaries.
//
// The component owns bodyX/bodyY/bodyWidth/bodyHeight/bodyRadius/contentOpacity
// so the host can bind its container to them while `running` is true. This
// avoids animating (and thereby destroying) the container's own bindings.
Item {
    id: controller

    visible: false
    width: 0
    height: 0

    // ── Pacing (milliseconds) ──────────────────────────────────────────────
    readonly property int fadeOutDuration: 90
    readonly property int reachCornerDuration: 200
    readonly property int squeezeDuration: 170
    readonly property int stretchDuration: 150
    readonly property int fallDuration: 380
    readonly property int impactDuration: 100
    readonly property int hopDuration: 140
    readonly property int dropBackDuration: 130
    readonly property int settleBounceDuration: 190
    readonly property int stretchHoldDuration: 300
    readonly property int glideDuration: 360
    readonly property int reformWobbleDuration: 170
    readonly property int reformSettleDuration: 230
    readonly property int fadeInDuration: 100
    readonly property int departureImpactDuration: 90
    readonly property int departureReboundDuration: 220

    // ── Water-drop proportions ─────────────────────────────────────────────
    // Horizontal reach along the bezel.
    readonly property real stretchFactor: 1.35
    // Thickness of the stretched pill / drip.
    readonly property real thicknessFactor: 0.8
    // Ball diameter, relative to the resting island height.
    readonly property real ballFactor: 1.7
    // Drip width, relative to the resting island height.
    readonly property real dropWidthFactor: 0.9
    // Drip length, relative to the resting island height.
    readonly property real dropLengthFactor: 4.2
    // Extra elongation during the fall (speed stretch).
    readonly property real fallStretchFactor: 1.25
    // Arrival squash: the ball stretches only slightly wider than itself, the
    // way a gel bead flattens a little when it lands.
    readonly property real splashWidthFactor: 1.28
    readonly property real splashHeightFactor: 0.86
    // Bouncy impacts: on contact the ball over-squashes, then rebounds back
    // through neutral into the held shape. Departure hits the bezel first.
    readonly property real departureImpactWidthFactor: 1.3
    readonly property real departureImpactHeightFactor: 0.78
    readonly property real arrivalImpactWidthFactor: 1.42
    readonly property real arrivalImpactHeightFactor: 0.7
    // Second bounce: the ball lifts off the destination surface, drops back
    // and squashes again, less than the first time.
    readonly property real hopFactor: 0.4
    readonly property real contactWidthFactor: 1.34
    readonly property real contactHeightFactor: 0.76
    // Final reform: the pill overshoots wide/flat, then narrow/tall, before it
    // settles exactly on the resting shape.
    readonly property real reformWideWidthFactor: 1.09
    readonly property real reformWideHeightFactor: 0.8
    readonly property real reformTallWidthFactor: 0.965
    readonly property real reformTallHeightFactor: 1.15

    // ── Motion trail (velocity smear) ──────────────────────────────────────
    // Offset, in pixels, that the ghost echoes trail behind the body, plus the
    // overall strength (0..1). Sampled from the body's own motion.
    property real trailX: 0
    property real trailY: 0
    property real trailStrength: 0
    readonly property real trailMaxLength: 34
    // Low-pass velocity state (internal).
    property real _velX: 0
    property real _velY: 0
    property real _lastX: 0
    property real _lastY: 0

    // ── Runtime context, supplied by the host before start() ───────────────
    property real screenW: 0
    property real screenH: 0
    property real margin: 10
    property real baseWidth: 312
    property real baseHeight: 36
    property real restRadius: 11

    // ── Live body state, read by the host container ────────────────────────
    property bool running: false
    property bool targetBottom: false
    property real bodyX: 0
    property real bodyY: 0
    property real bodyWidth: 0
    property real bodyHeight: 0
    property real bodyRadius: 18
    property real contentOpacity: 1

    // settled() fires when the drop has fully reshaped into the resting pill
    // (before the content fade-in). finished() fires after the content return.
    signal settled(bool destinationBottom)
    signal finished(bool destinationBottom)

    // ── Targets, resolved by start() ───────────────────────────────────────
    property real reachX: 0
    property real reachY: 0
    property real reachW: 0
    property real reachH: 0
    property real reachR: 0

    property real ballX: 0
    property real ballY: 0
    property real ballW: 0
    property real ballH: 0
    property real ballR: 0

    property real dripX: 0
    property real dripY: 0
    property real dripW: 0
    property real dripH: 0
    property real dripR: 0

    property real fallY: 0
    property real fallH: 0

    // Arrival corner: the ball squashes just slightly wider than itself,
    // welded to the arrival corner and to the top/bottom margin.
    property real splashX: 0
    property real splashY: 0
    property real splashW: 0
    property real splashH: 0
    property real splashR: 0

    // Deepest over-squash reached at each corner impact, before the rebound.
    // Departure corner (where the ball first lands on the bezel).
    property real bounceX: 0
    property real bounceY: 0
    property real bounceW: 0
    property real bounceH: 0
    property real bounceR: 0

    // Arrival corner (where the falling strand lands).
    property real impactX: 0
    property real impactY: 0
    property real impactW: 0
    property real impactH: 0
    property real impactR: 0

    // The ball lifted off the destination surface between the two contacts.
    property real hopX: 0
    property real hopY: 0
    property real hopW: 0
    property real hopH: 0
    property real hopR: 0

    // The smaller second squash when the ball drops back down.
    property real contactX: 0
    property real contactY: 0
    property real contactW: 0
    property real contactH: 0
    property real contactR: 0

    // The resting pill shape at the destination centre.
    property real settleX: 0
    property real settleY: 0
    property real settleW: 0
    property real settleH: 0
    property real settleR: 0

    // Final reform wobble: wide/flat overshoot, then narrow/tall undershoot,
    // both centred on the destination.
    property real wideX: 0
    property real wideY: 0
    property real wideW: 0
    property real wideH: 0
    property real wideR: 0

    property real tallX: 0
    property real tallY: 0
    property real tallW: 0
    property real tallH: 0
    property real tallR: 0

    // ── Coordinate helpers (right-bezel default) ───────────────────────────
    function edgeX(w) {
        return controller.screenW - w - controller.margin
    }

    function centredX(w) {
        return (controller.screenW - w) / 2
    }

    function topY() {
        return controller.margin
    }

    function bottomY(h) {
        return controller.screenH - h - controller.margin
    }

    // ── Journey setup ──────────────────────────────────────────────────────
    function start(destinationBottom) {
        if (controller.running) return false
        if (controller.screenW <= 0 || controller.screenH <= 0) return false

        var bw = Math.max(1, controller.baseWidth)
        var bh = Math.max(1, controller.baseHeight)

        var sw = bw * controller.stretchFactor                      // reach length
        var nv = Math.max(14, bh * controller.thicknessFactor)      // stretched thickness
        var ball = Math.max(44, bh * controller.ballFactor)         // corner ball
        var dropW = Math.max(24, bh * controller.dropWidthFactor)   // drip width
        var dropH = Math.max(ball * 2.2, bh * controller.dropLengthFactor)
        var fallH = dropH * controller.fallStretchFactor            // stretched in free fall
        var splashW = ball * controller.splashWidthFactor
        var splashH = ball * controller.splashHeightFactor
        var departW = ball * controller.departureImpactWidthFactor
        var departH = ball * controller.departureImpactHeightFactor
        var arrivalW = ball * controller.arrivalImpactWidthFactor
        var arrivalH = ball * controller.arrivalImpactHeightFactor
        var contactW = ball * controller.contactWidthFactor
        var contactH = ball * controller.contactHeightFactor
        var hop = Math.max(12, ball * controller.hopFactor)
        var wideW = bw * controller.reformWideWidthFactor
        var wideH = bh * controller.reformWideHeightFactor
        var tallW = bw * controller.reformTallWidthFactor
        var tallH = bh * controller.reformTallHeightFactor

        controller.targetBottom = destinationBottom

        // Seed the body at the current docked geometry so the hand-off from the
        // host's resting bindings is pixel-identical.
        controller.bodyWidth = bw
        controller.bodyHeight = bh
        controller.bodyRadius = controller.restRadius
        controller.bodyX = controller.centredX(bw)
        controller.bodyY = destinationBottom ? controller.topY() : controller.bottomY(bh)
        controller.contentOpacity = 1

        // Reset the motion trail so no smear leaks in from a previous trip.
        controller._lastX = controller.bodyX
        controller._lastY = controller.bodyY
        controller._velX = 0
        controller._velY = 0
        controller.trailX = 0
        controller.trailY = 0
        controller.trailStrength = 0

        // Reach the departure corner, stretched along the bezel.
        controller.reachX = controller.edgeX(sw)
        controller.reachY = destinationBottom ? controller.topY() : controller.bottomY(nv)
        controller.reachW = sw
        controller.reachH = nv
        controller.reachR = nv / 2

        // Squeeze into a ball, welded to the departure corner.
        controller.ballX = controller.edgeX(ball)
        controller.ballY = destinationBottom ? controller.topY() : controller.bottomY(ball)
        controller.ballW = ball
        controller.ballH = ball
        controller.ballR = ball / 2

        // Stretch the ball into a hanging drip.
        controller.dripX = controller.edgeX(dropW)
        controller.dripY = destinationBottom ? controller.topY() : controller.bottomY(dropH)
        controller.dripW = dropW
        controller.dripH = dropH
        controller.dripR = dropW / 2

        // Departure impact: the ball flattens against the departure bezel.
        controller.bounceX = controller.edgeX(departW)
        controller.bounceY = destinationBottom ? controller.topY() : controller.bottomY(departH)
        controller.bounceW = departW
        controller.bounceH = departH
        controller.bounceR = departH / 2

        // Free fall: the drip elongates a little as it accelerates, and lands
        // on the arrival bezel with its leading edge exactly on the margin.
        controller.fallY = destinationBottom ? controller.bottomY(fallH) : controller.topY()
        controller.fallH = fallH

        // Arrival squash: the strand collapses back into a ball at the corner
        // and flattens only slightly wider than itself, the way a gel bead
        // squishes when it lands. Right edge and leading edge stay welded.
        controller.splashX = controller.edgeX(splashW)
        controller.splashY = destinationBottom ? controller.bottomY(splashH) : controller.topY()
        controller.splashW = splashW
        controller.splashH = splashH
        controller.splashR = splashH / 2

        // Arrival impact: the strand over-squashes into the corner before it
        // rebounds into the held splash shape above.
        controller.impactX = controller.edgeX(arrivalW)
        controller.impactY = destinationBottom ? controller.bottomY(arrivalH) : controller.topY()
        controller.impactW = arrivalW
        controller.impactH = arrivalH
        controller.impactR = arrivalH / 2

        // Second bounce: the ball springs back off the destination surface,
        // then drops down again onto it (hopY is `hop` px away from the bezel).
        controller.hopX = controller.edgeX(ball)
        controller.hopY = destinationBottom
            ? controller.bottomY(ball) - hop
            : controller.topY() + hop
        controller.hopW = ball
        controller.hopH = ball
        controller.hopR = ball / 2

        // Smaller second contact squash when the ball lands again.
        controller.contactX = controller.edgeX(contactW)
        controller.contactY = destinationBottom ? controller.bottomY(contactH) : controller.topY()
        controller.contactW = contactW
        controller.contactH = contactH
        controller.contactR = contactH / 2

        // The squashed ball then glides to the centre and reforms into the
        // exact resting pill on arrival.
        controller.settleX = controller.centredX(bw)
        controller.settleY = destinationBottom ? controller.bottomY(bh) : controller.topY()
        controller.settleW = bw
        controller.settleH = bh
        controller.settleR = controller.restRadius

        // Final jelly wobble: the reforming pill first overshoots wide/flat,
        // then narrow/tall, before it settles on the resting shape.
        controller.wideX = controller.centredX(wideW)
        controller.wideY = destinationBottom ? controller.bottomY(wideH) : controller.topY()
        controller.wideW = wideW
        controller.wideH = wideH
        controller.wideR = wideH / 2

        controller.tallX = controller.centredX(tallW)
        controller.tallY = destinationBottom ? controller.bottomY(tallH) : controller.topY()
        controller.tallW = tallW
        controller.tallH = tallH
        controller.tallR = tallH / 2

        controller.running = true
        travelSequence.restart()
        return true
    }

    function stop() {
        if (travelSequence.running) travelSequence.stop()
        controller.running = false
        controller.contentOpacity = 1
        controller.trailX = 0
        controller.trailY = 0
        controller.trailStrength = 0
    }

    function complete() {
        if (!controller.running) return
        controller.contentOpacity = 1
        controller.running = false
        controller.trailX = 0
        controller.trailY = 0
        controller.trailStrength = 0
        controller.finished(controller.targetBottom)
    }

    // Samples the body's motion every frame and converts it into a trailing
    // offset plus a strength value. Ghost echoes rendered behind the body use
    // the offset; fainter, further echoes sell the smear.
    function sampleTravel() {
        var dx = controller.bodyX - controller._lastX
        var dy = controller.bodyY - controller._lastY
        controller._lastX = controller.bodyX
        controller._lastY = controller.bodyY

        // Low-pass filter so the smear follows the gesture, not frame jitter.
        controller._velX = controller._velX * 0.6 + dx * 0.4
        controller._velY = controller._velY * 0.6 + dy * 0.4

        var mag = Math.sqrt(controller._velX * controller._velX
                            + controller._velY * controller._velY)

        if (mag < 0.15) {
            // Motion stopped: fade the smear out instead of snapping it.
            controller.trailStrength *= 0.72
            if (controller.trailStrength < 0.01) {
                controller.trailStrength = 0
                controller.trailX = 0
                controller.trailY = 0
            }
            return
        }

        var len = Math.min(controller.trailMaxLength, mag * 2.6)
        controller.trailX = -controller._velX / mag * len
        controller.trailY = -controller._velY / mag * len
        var target = Math.min(1, mag / 16)
        controller.trailStrength = controller.trailStrength * 0.55 + target * 0.45
    }

    Timer {
        interval: 16
        repeat: true
        running: controller.running
        onTriggered: controller.sampleTravel()
    }

    // ── Timeline ───────────────────────────────────────────────────────────
    SequentialAnimation {
        id: travelSequence

        // Content leaves first so only the drop travels.
        NumberAnimation {
            target: controller
            property: "contentOpacity"
            from: 1
            to: 0
            duration: controller.fadeOutDuration
            easing.type: Easing.InQuad
        }

        // ── Phase 1 · stretch to the corner ───────────────────────────────
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.reachX
                duration: controller.reachCornerDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.reachY
                duration: controller.reachCornerDuration
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.reachW
                duration: controller.reachCornerDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.reachH
                duration: controller.reachCornerDuration
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.reachR
                duration: controller.reachCornerDuration
                easing.type: Easing.InOutSine
            }
        }

        // ── Phase 2 · squeeze into a ball on the corner ───────────────────
        // Paired x/width and y/height easings keep the ball welded to the
        // corner while it compresses.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.ballX
                duration: controller.squeezeDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.ballW
                duration: controller.squeezeDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.ballY
                duration: controller.squeezeDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.ballH
                duration: controller.squeezeDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.ballR
                duration: controller.squeezeDuration
                easing.type: Easing.OutCubic
            }
        }

        // ── Phase 2b · departure impact · bounce off the bezel ────────────
        // The ball hits the departure corner and over-squashes flatter and
        // wider, then rebounds back through neutral into the resting ball.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.bounceX
                duration: controller.departureImpactDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.bounceW
                duration: controller.departureImpactDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.bounceY
                duration: controller.departureImpactDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.bounceH
                duration: controller.departureImpactDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.bounceR
                duration: controller.departureImpactDuration
                easing.type: Easing.OutQuad
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.ballX
                duration: controller.departureReboundDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.7
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.ballW
                duration: controller.departureReboundDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.7
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.ballY
                duration: controller.departureReboundDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.7
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.ballH
                duration: controller.departureReboundDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.7
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.ballR
                duration: controller.departureReboundDuration
                easing.type: Easing.OutCubic
            }
        }

        // ── Phase 3 · stretch the ball towards the side ───────────────────
        // The ball is pulled into a hanging drip: width necks down while the
        // length accelerates away from the corner.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.dripX
                duration: controller.stretchDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.dripW
                duration: controller.stretchDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.dripY
                duration: controller.stretchDuration
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.dripH
                duration: controller.stretchDuration
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.dripR
                duration: controller.stretchDuration
                easing.type: Easing.InOutCubic
            }
        }

        // ── Phase 4 · free fall down the bezel ────────────────────────────
        // Gravity easing: the drop keeps its bead on the outer edge, gaining
        // speed and stretching slightly until it reaches the far bezel.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.fallY
                duration: controller.fallDuration
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.fallH
                duration: controller.fallDuration
                easing.type: Easing.InQuad
            }
        }

        // ── Phase 5 · arrival impact · over-squash at the corner ──────────
        // The strand collapses into a ball at the corner and over-squashes
        // flatter and wider than the held shape. Right edge and leading edge
        // stay welded to the corner on every frame.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.impactX
                duration: controller.impactDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.impactW
                duration: controller.impactDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.impactY
                duration: controller.impactDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.impactH
                duration: controller.impactDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.impactR
                duration: controller.impactDuration
                easing.type: Easing.OutQuad
            }
        }

        // ── Phase 5b · second bounce · the ball lifts off the surface ─────
        // A real bounce: the gel ball springs back off the top/bottom bezel.
        // The right edge stays welded while it hops away from the surface.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.hopX
                duration: controller.hopDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.hopW
                duration: controller.hopDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.hopY
                duration: controller.hopDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.hopH
                duration: controller.hopDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.hopR
                duration: controller.hopDuration
                easing.type: Easing.OutQuad
            }
        }

        // ── Phase 5c · drop back onto the surface ─────────────────────────
        // Gravity pulls the ball down for the smaller second contact.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.contactX
                duration: controller.dropBackDuration
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.contactW
                duration: controller.dropBackDuration
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.contactY
                duration: controller.dropBackDuration
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.contactH
                duration: controller.dropBackDuration
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.contactR
                duration: controller.dropBackDuration
                easing.type: Easing.InQuad
            }
        }

        // ── Phase 5d · jelly rebound into the held shape ──────────────────
        // The second contact settles with a small overshoot into the shape
        // that is held at the corner.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.splashX
                duration: controller.settleBounceDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.splashW
                duration: controller.settleBounceDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.splashY
                duration: controller.settleBounceDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.splashH
                duration: controller.settleBounceDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.splashR
                duration: controller.settleBounceDuration
                easing.type: Easing.OutCubic
            }
        }

        // Hold the small squashed ball at the corner before it moves on.
        PauseAnimation {
            duration: controller.stretchHoldDuration
        }

        // ── Phase 6 · glide home and reform ───────────────────────────────
        // The blob slides to the destination centre while it stretches into a
        // slightly over-wide, over-flat pill.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.wideX
                duration: controller.glideDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.wideY
                duration: controller.glideDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.wideW
                duration: controller.glideDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.wideH
                duration: controller.glideDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.wideR
                duration: controller.glideDuration
                easing.type: Easing.InOutCubic
            }
        }

        // ── Phase 6b · jelly wobble · narrow and tall ─────────────────────
        // The pill rebounds through the opposite deformation, still centred.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.tallX
                duration: controller.reformWobbleDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.tallY
                duration: controller.reformWobbleDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.tallW
                duration: controller.reformWobbleDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.tallH
                duration: controller.reformWobbleDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.tallR
                duration: controller.reformWobbleDuration
                easing.type: Easing.InOutCubic
            }
        }

        // ── Phase 6c · settle exactly on the resting pill ─────────────────
        // The wobble dies out on the exact docked geometry, so the hand-off
        // back to the host's bindings is pixel-identical.
        ParallelAnimation {
            NumberAnimation {
                target: controller
                property: "bodyX"
                to: controller.settleX
                duration: controller.reformSettleDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyY"
                to: controller.settleY
                duration: controller.reformSettleDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyWidth"
                to: controller.settleW
                duration: controller.reformSettleDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyHeight"
                to: controller.settleH
                duration: controller.reformSettleDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: controller
                property: "bodyRadius"
                to: controller.settleR
                duration: controller.reformSettleDuration
                easing.type: Easing.OutCubic
            }
        }

        // Commit the new docked position while the body is pixel-identical to
        // the rest pose, so the host can swap back to its normal bindings.
        ScriptAction {
            script: controller.settled(controller.targetBottom)
        }

        // Content only returns after the body has fully reshaped.
        NumberAnimation {
            target: controller
            property: "contentOpacity"
            from: 0
            to: 1
            duration: controller.fadeInDuration
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: controller.complete()
        }
    }
}
