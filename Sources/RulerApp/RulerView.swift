import SwiftUI

/// Full-screen measuring surface: the metric/imperial ticks, optional grid, and
/// a draggable crosshair with a live X/Y readout. Fills the whole screen
/// (ignoring safe areas) so the ruler origin is the true top-left corner.
struct RulerView: View {
    @ObservedObject var state: RulerState

    var body: some View {
        let ppm = state.pointsPerMm
        let unit = state.unit
        let gridMode = state.gridMode

        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    drawGrid(into: &context, size: size, pointsPerMm: ppm, unit: unit, mode: gridMode)
                    drawRulers(into: &context, size: size, pointsPerMm: ppm, unit: unit)
                    if let p = state.cursorLocal {
                        drawCrosshair(at: p, size: size, into: &context)
                    }
                }
                .background(Color(uiColor: .systemBackground))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in state.cursorLocal = value.location }
                    // Sticky: keep the last point on lift so the reading stays visible.
                )
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let p): state.cursorLocal = p
                    case .ended: state.cursorLocal = nil
                    }
                }

                cursorBadge(in: geo.size, pointsPerMm: ppm, unit: unit)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Cursor badge

    @ViewBuilder
    private func cursorBadge(in size: CGSize, pointsPerMm ppm: CGFloat, unit: RulerUnit) -> some View {
        if let local = state.cursorLocal {
            let xMm = local.x / ppm
            let yMm = local.y / ppm
            // Offset the badge up-and-right of the touch point and clamp it on
            // screen, so a finger never hides the reading.
            let bx = min(max(local.x + 16, 8), max(8, size.width - 150))
            let by = min(max(local.y - 56, 8), max(8, size.height - 52))
            VStack(alignment: .leading, spacing: 2) {
                Text("X: \(RulerFormat.format(mm: xMm, unit: unit))")
                Text("Y: \(RulerFormat.format(mm: yMm, unit: unit))")
            }
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.78))
            )
            .fixedSize()
            .position(x: bx, y: by)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Crosshair

    private func drawCrosshair(at p: CGPoint, size: CGSize, into context: inout GraphicsContext) {
        let guide = GraphicsContext.Shading.color(.accentColor.opacity(0.7))
        var vLine = Path()
        vLine.move(to: CGPoint(x: p.x, y: 0))
        vLine.addLine(to: CGPoint(x: p.x, y: size.height))
        var hLine = Path()
        hLine.move(to: CGPoint(x: 0, y: p.y))
        hLine.addLine(to: CGPoint(x: size.width, y: p.y))
        context.stroke(vLine, with: guide, lineWidth: 0.75)
        context.stroke(hLine, with: guide, lineWidth: 0.75)

        let r: CGFloat = 7
        let dot = Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
        context.stroke(dot, with: .color(.accentColor), lineWidth: 1.5)
    }

    // MARK: - Tick drawing

    private func drawRulers(into context: inout GraphicsContext, size: CGSize, pointsPerMm ppm: CGFloat, unit: RulerUnit) {
        switch unit {
        case .mmcm:
            drawMetricTop(into: &context, width: size.width, ppm: ppm, yOffset: 0)
            drawMetricLeft(into: &context, height: size.height, ppm: ppm, xOffset: 0)
        case .inches:
            drawImperialTop(into: &context, width: size.width, ppm: ppm, yOffset: 0)
            drawImperialLeft(into: &context, height: size.height, ppm: ppm, xOffset: 0)
        case .both:
            drawMetricTop(into: &context, width: size.width, ppm: ppm, yOffset: 0)
            drawImperialTop(into: &context, width: size.width, ppm: ppm, yOffset: 30)
            drawMetricLeft(into: &context, height: size.height, ppm: ppm, xOffset: 0)
            drawImperialLeft(into: &context, height: size.height, ppm: ppm, xOffset: 30)
        }
    }

    // MARK: Metric

    private func drawMetricTop(into context: inout GraphicsContext, width: CGFloat, ppm: CGFloat, yOffset: CGFloat) {
        let totalMm = Int(floor(width / ppm))
        for mm in 0...totalMm {
            let x = CGFloat(mm) * ppm
            let length = metricTickLength(forMm: mm)
            var path = Path()
            path.move(to: CGPoint(x: x, y: yOffset))
            path.addLine(to: CGPoint(x: x, y: yOffset + length))
            stroke(path, into: &context)

            if mm > 0, mm % 10 == 0 {
                drawLabel(String(mm / 10), at: CGPoint(x: x + 3, y: yOffset + length + 1), into: &context)
            }
        }
    }

    private func drawMetricLeft(into context: inout GraphicsContext, height: CGFloat, ppm: CGFloat, xOffset: CGFloat) {
        let totalMm = Int(floor(height / ppm))
        for mm in 0...totalMm {
            let y = CGFloat(mm) * ppm
            let length = metricTickLength(forMm: mm)
            var path = Path()
            path.move(to: CGPoint(x: xOffset, y: y))
            path.addLine(to: CGPoint(x: xOffset + length, y: y))
            stroke(path, into: &context)

            if mm > 0, mm % 10 == 0 {
                drawLabel(String(mm / 10), at: CGPoint(x: xOffset + length + 2, y: y + 1), into: &context)
            }
        }
    }

    private func metricTickLength(forMm mm: Int) -> CGFloat {
        if mm % 10 == 0 { return 14 }
        if mm % 5 == 0 { return 9 }
        return 4
    }

    // MARK: Imperial

    private func drawImperialTop(into context: inout GraphicsContext, width: CGFloat, ppm: CGFloat, yOffset: CGFloat) {
        let step = ppm * 25.4 / 16
        let total = Int(floor(width / step))
        for s in 0...total {
            let x = CGFloat(s) * step
            let length = imperialTickLength(forSixteenths: s)
            var path = Path()
            path.move(to: CGPoint(x: x, y: yOffset))
            path.addLine(to: CGPoint(x: x, y: yOffset + length))
            stroke(path, into: &context)

            if s > 0, s % 16 == 0 {
                drawLabel(String(s / 16), at: CGPoint(x: x + 3, y: yOffset + length + 1), into: &context)
            }
        }
    }

    private func drawImperialLeft(into context: inout GraphicsContext, height: CGFloat, ppm: CGFloat, xOffset: CGFloat) {
        let step = ppm * 25.4 / 16
        let total = Int(floor(height / step))
        for s in 0...total {
            let y = CGFloat(s) * step
            let length = imperialTickLength(forSixteenths: s)
            var path = Path()
            path.move(to: CGPoint(x: xOffset, y: y))
            path.addLine(to: CGPoint(x: xOffset + length, y: y))
            stroke(path, into: &context)

            if s > 0, s % 16 == 0 {
                drawLabel(String(s / 16), at: CGPoint(x: xOffset + length + 2, y: y + 1), into: &context)
            }
        }
    }

    private func imperialTickLength(forSixteenths s: Int) -> CGFloat {
        if s % 16 == 0 { return 14 }
        if s % 8 == 0 { return 11 }
        if s % 4 == 0 { return 8 }
        if s % 2 == 0 { return 5 }
        return 3
    }

    // MARK: Grid

    private func drawGrid(into context: inout GraphicsContext, size: CGSize, pointsPerMm ppm: CGFloat, unit: RulerUnit, mode: RulerGridMode) {
        guard mode.showsMajor else { return }

        let (majorStep, minorStep): (CGFloat, CGFloat) = {
            switch unit {
            case .inches:
                let inch = ppm * 25.4
                return (inch, inch / 8)            // 1" major, 1/8" minor
            case .mmcm, .both:
                return (10 * ppm, ppm)             // 10mm major, 1mm minor
            }
        }()

        if mode.showsMinor {
            drawGridLines(
                into: &context,
                size: size,
                step: minorStep,
                shading: .color(.secondary.opacity(0.15)),
                lineWidth: 0.5
            )
        }

        drawGridLines(
            into: &context,
            size: size,
            step: majorStep,
            shading: .color(.secondary.opacity(0.4)),
            lineWidth: 0.5
        )
    }

    private func drawGridLines(into context: inout GraphicsContext, size: CGSize, step: CGFloat, shading: GraphicsContext.Shading, lineWidth: CGFloat) {
        var v = step
        while v < size.width {
            var path = Path()
            path.move(to: CGPoint(x: v, y: 0))
            path.addLine(to: CGPoint(x: v, y: size.height))
            context.stroke(path, with: shading, lineWidth: lineWidth)
            v += step
        }
        var h = step
        while h < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: size.width, y: h))
            context.stroke(path, with: shading, lineWidth: lineWidth)
            h += step
        }
    }

    // MARK: Drawing helpers

    private func stroke(_ path: Path, into context: inout GraphicsContext) {
        context.stroke(path, with: .color(.primary), lineWidth: 1)
    }

    private func drawLabel(_ text: String, at point: CGPoint, into context: inout GraphicsContext) {
        let styled = Text(text)
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundColor(.primary)
        let resolved = context.resolve(styled)
        context.draw(resolved, at: point, anchor: .topLeading)
    }
}
