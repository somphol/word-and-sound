import SwiftUI
import WordAndSoundCore

struct MouthDiagramView: View {
    let articulation: Articulation
    var compact = false
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var rest: MouthShape {
        MouthShape(
            tip: 0.12, body: 0.18, back: 0.45, lipRound: 0, jaw: 0.16,
            contact: .none, airflow: .none, voiced: true
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animate || reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let phase = (!animate || reduceMotion) ? 1 : (sin(time * 1.5) + 1) / 2
            let from = articulation.glide == nil ? rest : articulation.shape
            let to = articulation.glide ?? articulation.shape
            let shape = from.blended(to: to, phase: phase)

            Canvas { context, size in
                MouthRenderer.draw(
                    context: &context,
                    size: size,
                    articulation: articulation,
                    shape: shape,
                    restShape: from,
                    phase: phase,
                    compact: compact
                )
            }
        }
        .overlay(alignment: .bottomLeading) {
            if !compact {
                Button {
                    animate.toggle()
                } label: {
                    Label(animate ? "Pause" : "Animate", systemImage: animate ? "pause.fill" : "play.fill")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.35)))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: compact ? 10 : 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 10 : 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(articulation.name + ". " + articulation.steps.joined(separator: " ")))
    }
}

private enum MouthRenderer {
    static func draw(
        context: inout GraphicsContext,
        size: CGSize,
        articulation: Articulation,
        shape: MouthShape,
        restShape: MouthShape,
        phase: Double,
        compact: Bool
    ) {
        func p(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: x * size.width, y: y * size.height)
        }

        func tongueTipPoint(_ s: MouthShape) -> (Double, Double) {
            var tipX = 0.48 + s.tip * 0.19
            var tipY = 0.74 - s.tip * 0.30
            if s.contact == .alveolar, s.airflow != .center {
                tipX = 0.65
                tipY = 0.425
            } else if s.contact == .betweenTeeth {
                tipX = 0.80
                tipY = 0.52
            }
            return (tipX, tipY)
        }

        func tongueGeometry(_ s: MouthShape) -> (tip: (Double, Double), body: (Double, Double), jaw: Double) {
            let tip = tongueTipPoint(s)
            let bodyX = 0.37 + s.back * 0.12
            let bodyY = 0.74 - s.body * 0.22
            return (tip, (bodyX, bodyY), s.jaw * 0.04)
        }

        func tonguePath(_ s: MouthShape) -> Path {
            let geometry = tongueGeometry(s)
            let tip = geometry.tip
            let body = geometry.body
            let jawDrop = geometry.jaw
            var path = Path()
            path.move(to: p(0.24, 0.67 + jawDrop))
            path.addCurve(to: p(body.0, body.1), control1: p(0.29, 0.57), control2: p(0.31, body.1))
            path.addCurve(to: p(tip.0, tip.1), control1: p(body.0 + 0.10, body.1 - 0.04), control2: p(tip.0 - 0.09, tip.1))
            path.addCurve(to: p(0.70, 0.77 + jawDrop), control1: p(tip.0 + 0.02, tip.1 + 0.10), control2: p(0.68, 0.70))
            path.addCurve(to: p(0.24, 0.80 + jawDrop), control1: p(0.50, 0.85), control2: p(0.30, 0.83))
            path.closeSubpath()
            return path
        }

        let background = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: compact ? 10 : 16)
        context.fill(
            background,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.09, green: 0.12, blue: 0.17),
                    Color(red: 0.12, green: 0.16, blue: 0.22),
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)
            )
        )

        // Stylised side profile, facing right.
        var head = Path()
        head.move(to: p(0.12, 0.20))
        head.addCurve(to: p(0.55, 0.12), control1: p(0.20, 0.10), control2: p(0.40, 0.10))
        head.addCurve(to: p(0.78, 0.30), control1: p(0.68, 0.14), control2: p(0.78, 0.20))
        head.addCurve(to: p(0.85, 0.48), control1: p(0.81, 0.36), control2: p(0.85, 0.42))
        head.addCurve(to: p(0.79, 0.64), control1: p(0.85, 0.55), control2: p(0.83, 0.61))
        head.addCurve(to: p(0.62, 0.82), control1: p(0.75, 0.72), control2: p(0.70, 0.80))
        head.addCurve(to: p(0.15, 0.90), control1: p(0.40, 0.90), control2: p(0.20, 0.92))
        head.addCurve(to: p(0.12, 0.20), control1: p(0.05, 0.70), control2: p(0.05, 0.35))
        head.closeSubpath()
        context.fill(head, with: .color(Color(red: 0.96, green: 0.72, blue: 0.62).opacity(0.16)))
        context.stroke(head, with: .color(Color(red: 0.96, green: 0.78, blue: 0.70).opacity(0.20)), lineWidth: 1)

        // Oral cavity and throat.
        var cavity = Path()
        cavity.move(to: p(0.80, 0.48))
        cavity.addCurve(to: p(0.30, 0.42), control1: p(0.66, 0.35), control2: p(0.45, 0.34))
        cavity.addCurve(to: p(0.20, 0.70), control1: p(0.23, 0.48), control2: p(0.18, 0.60))
        cavity.addCurve(to: p(0.48, 0.80), control1: p(0.24, 0.78), control2: p(0.40, 0.80))
        cavity.addCurve(to: p(0.81, 0.62), control1: p(0.66, 0.79), control2: p(0.79, 0.68))
        cavity.closeSubpath()
        context.fill(cavity, with: .color(Color(red: 0.33, green: 0.08, blue: 0.11).opacity(0.92)))

        // Palate and alveolar ridge.
        var palate = Path()
        palate.move(to: p(0.23, 0.43))
        palate.addCurve(to: p(0.62, 0.405), control1: p(0.36, 0.37), control2: p(0.52, 0.38))
        palate.addCurve(to: p(0.80, 0.48), control1: p(0.68, 0.41), control2: p(0.78, 0.43))
        context.stroke(palate, with: .color(Color(red: 0.98, green: 0.70, blue: 0.64).opacity(0.75)), style: StrokeStyle(lineWidth: compact ? 5 : 7, lineCap: .round))

        // Soft palate / velum.
        var velum = Path()
        velum.move(to: p(0.30, 0.42))
        velum.addCurve(to: p(0.22, 0.55), control1: p(0.24, 0.45), control2: p(0.20, 0.50))
        context.stroke(velum, with: .color(Color(red: 0.92, green: 0.62, blue: 0.62).opacity(0.55)), style: StrokeStyle(lineWidth: compact ? 4 : 6, lineCap: .round))

        // Tongue: dashed rest position, solid target position.
        let ghost = tonguePath(restShape)
        context.stroke(
            ghost,
            with: .color(Color.white.opacity(0.30)),
            style: StrokeStyle(lineWidth: 1.3, dash: [4, 4])
        )

        let tongue = tonguePath(shape)
        context.fill(
            tongue,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.96, green: 0.44, blue: 0.45),
                    Color(red: 0.74, green: 0.20, blue: 0.28),
                ]),
                startPoint: p(0.3, 0.55),
                endPoint: p(0.7, 0.8)
            )
        )
        context.stroke(tongue, with: .color(Color(red: 1, green: 0.76, blue: 0.72).opacity(0.55)), lineWidth: 1)

        // Movement arrow from the rest position to the target.
        let fromTip = tongueTipPoint(restShape)
        let toTip = tongueTipPoint(shape)
        let startPoint = p(fromTip.0, fromTip.1)
        let endPoint = p(toTip.0, toTip.1)
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let distance = sqrt(dx * dx + dy * dy)
        if distance > size.width * 0.03 {
            var arrow = Path()
            arrow.move(to: startPoint)
            arrow.addLine(to: endPoint)
            context.stroke(
                arrow,
                with: .color(Color.white.opacity(0.45)),
                style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])
            )
            let angle = atan2(dy, dx)
            let head = 7.0
            var arrowHead = Path()
            arrowHead.move(to: endPoint)
            arrowHead.addLine(to: CGPoint(
                x: endPoint.x - head * cos(angle - .pi / 6),
                y: endPoint.y - head * sin(angle - .pi / 6)
            ))
            arrowHead.addLine(to: CGPoint(
                x: endPoint.x - head * cos(angle + .pi / 6),
                y: endPoint.y - head * sin(angle + .pi / 6)
            ))
            arrowHead.closeSubpath()
            context.fill(arrowHead, with: .color(Color.white.opacity(0.55)))
        }

        // Teeth and lips.
        let jawDrop = shape.jaw * 0.04
        let upperTooth = CGRect(x: 0.70 * size.width, y: 0.445 * size.height, width: 0.045 * size.width, height: 0.055 * size.height)
        let lowerTooth = CGRect(x: 0.70 * size.width, y: (0.575 + jawDrop) * size.height, width: 0.045 * size.width, height: 0.045 * size.height)
        let toothPath = Path(roundedRect: upperTooth, cornerRadius: 0.008 * size.width)
        context.fill(toothPath, with: .color(Color(red: 0.98, green: 0.95, blue: 0.88).opacity(0.9)))
        let lowerPath = Path(roundedRect: lowerTooth, cornerRadius: 0.008 * size.width)
        context.fill(lowerPath, with: .color(Color(red: 0.98, green: 0.95, blue: 0.88).opacity(0.9)))

        // Lips.
        let lipWidth = 0.055 + shape.lipRound * 0.015
        var upperLip = Path()
        upperLip.move(to: p(0.76, 0.46))
        upperLip.addCurve(to: p(0.80 + lipWidth, 0.49), control1: p(0.79, 0.44), control2: p(0.82, 0.46))
        upperLip.addCurve(to: p(0.77, 0.53), control1: p(0.82, 0.52), control2: p(0.80, 0.53))
        upperLip.closeSubpath()
        context.fill(upperLip, with: .color(Color(red: 0.86, green: 0.34, blue: 0.42).opacity(0.92)))

        var lowerLip = Path()
        lowerLip.move(to: p(0.77, 0.57 + jawDrop))
        lowerLip.addCurve(to: p(0.80 + lipWidth, 0.61 + jawDrop), control1: p(0.82, 0.57), control2: p(0.83, 0.59))
        lowerLip.addCurve(to: p(0.75, 0.65 + jawDrop), control1: p(0.79, 0.65), control2: p(0.78, 0.66))
        lowerLip.closeSubpath()
        context.fill(lowerLip, with: .color(Color(red: 0.74, green: 0.25, blue: 0.34).opacity(0.92)))

        // Airflow.
        drawAirflow(
            context: &context,
            p: p,
            shape: shape,
            phase: phase,
            compact: compact,
            size: size
        )

        // Voice indicator.
        let voiceColor = shape.voiced
            ? Color(red: 1.0, green: 0.68, blue: 0.25)
            : Color.white.opacity(0.25)
        var foldA = Path()
        foldA.move(to: p(0.175, 0.79))
        foldA.addLine(to: p(0.195, 0.77))
        var foldB = Path()
        foldB.move(to: p(0.205, 0.79))
        foldB.addLine(to: p(0.185, 0.77))
        context.stroke(foldA, with: .color(voiceColor), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        context.stroke(foldB, with: .color(voiceColor), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        if shape.voiced {
            let radius = 0.018 + sin(phase * .pi * 2) * 0.004
            let ring = Path(ellipseIn: CGRect(x: (0.20 - radius) * size.width, y: (0.79 - radius) * size.height, width: radius * 2 * size.width, height: radius * 2 * size.height))
            context.stroke(ring, with: .color(voiceColor.opacity(0.45)), lineWidth: 1)
        }

        // Contact target.
        if let target = contactPoint(shape.contact, p: p) {
            let radius = (compact ? 4.5 : 7) + sin(phase * .pi * 2) * 1.2
            let ring = Path(ellipseIn: CGRect(
                x: target.x - radius, y: target.y - radius,
                width: radius * 2, height: radius * 2
            ))
            context.stroke(ring, with: .color(Color(red: 0.36, green: 0.95, blue: 0.56)), lineWidth: 2)
            let dot = Path(ellipseIn: CGRect(x: target.x - 1.5, y: target.y - 1.5, width: 3, height: 3))
            context.fill(dot, with: .color(Color(red: 0.36, green: 0.95, blue: 0.56)))
        }

        if !compact {
            let labelColor = Color.white.opacity(0.62)
            let geometry = tongueGeometry(shape)

            func label(_ text: String, at: (Double, Double), to: (Double, Double)) {
                var leader = Path()
                leader.move(to: p(at.0, at.1))
                leader.addLine(to: p(to.0, to.1))
                context.stroke(
                    leader,
                    with: .color(Color.white.opacity(0.22)),
                    style: StrokeStyle(lineWidth: 0.8, dash: [2, 2])
                )
                context.draw(
                    Text(text)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(labelColor),
                    at: p(at.0, at.1)
                )
            }

            label("ridge", at: (0.60, 0.28), to: (0.65, 0.405))
            label("tongue tip", at: (0.53, 0.22), to: geometry.tip)
            label("tongue body", at: (0.17, 0.56), to: geometry.body)
            label("lips", at: (0.92, 0.52), to: (0.82, 0.55))
            label("vocal folds", at: (0.10, 0.86), to: (0.19, 0.79))
        }
    }

    private static func drawAirflow(
        context: inout GraphicsContext,
        p: (Double, Double) -> CGPoint,
        shape: MouthShape,
        phase: Double,
        compact: Bool,
        size: CGSize
    ) {
        let blue = Color(red: 0.35, green: 0.78, blue: 1.0)
        let style = StrokeStyle(
            lineWidth: compact ? 1.5 : 2,
            lineCap: .round,
            dash: [3, 6],
            dashPhase: phase * 18
        )

        func stream(_ points: [(Double, Double)]) {
            var path = Path()
            guard let first = points.first else { return }
            path.move(to: p(first.0, first.1))
            for point in points.dropFirst() {
                path.addLine(to: p(point.0, point.1))
            }
            context.stroke(path, with: .color(blue.opacity(0.8)), style: style)
        }

        switch shape.airflow {
        case .center:
            stream([(0.22, 0.74), (0.30, 0.62), (0.46, 0.54), (0.62, 0.50), (0.80, 0.54)])
        case .side:
            stream([(0.22, 0.74), (0.30, 0.64), (0.45, 0.66), (0.60, 0.70), (0.72, 0.70)])
            stream([(0.24, 0.76), (0.34, 0.68), (0.50, 0.72), (0.64, 0.75)])
        case .nasal:
            var nasal = Path()
            nasal.move(to: p(0.22, 0.74))
            nasal.addCurve(to: p(0.28, 0.44), control1: p(0.22, 0.60), control2: p(0.25, 0.50))
            nasal.addCurve(to: p(0.70, 0.27), control1: p(0.40, 0.34), control2: p(0.55, 0.25))
            context.stroke(nasal, with: .color(blue.opacity(0.8)), style: style)
        case .stop:
            let target = contactPoint(shape.contact, p: p)
            if let target {
                for offset in [-0.035, 0, 0.035] {
                    var burst = Path()
                    burst.move(to: CGPoint(x: target.x + CGFloat(offset) * size.width, y: target.y))
                    burst.addLine(to: CGPoint(x: target.x + CGFloat(offset) * size.width + size.width * 0.045, y: target.y - size.height * 0.045))
                    context.stroke(burst, with: .color(blue.opacity(0.8)), style: style)
                }
            }
        case .none:
            break
        }
    }

    private static func contactPoint(_ contact: ArticulationContact, p: (Double, Double) -> CGPoint) -> CGPoint? {
        switch contact {
        case .none: return nil
        case .lips: return p(0.81, 0.55)
        case .teeth: return p(0.73, 0.52)
        case .betweenTeeth: return p(0.82, 0.54)
        case .alveolar: return p(0.65, 0.41)
        case .postAlveolar: return p(0.59, 0.40)
        case .palatal: return p(0.49, 0.37)
        case .velar: return p(0.29, 0.39)
        case .glottal: return p(0.20, 0.82)
        }
    }
}
