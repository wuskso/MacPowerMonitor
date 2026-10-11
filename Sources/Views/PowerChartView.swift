import SwiftUI

public struct PowerChartView: View {
    public let history: [HistoryPoint]
    public let minWatts: Double
    public let maxWatts: Double
    public let avgWatts: Double

    public init(history: [HistoryPoint], minWatts: Double, maxWatts: Double, avgWatts: Double) {
        self.history = history
        self.minWatts = minWatts
        self.maxWatts = maxWatts
        self.avgWatts = avgWatts
    }

    private var chartMin: Double {
        max(0.0, floor(minWatts - 1.0))
    }

    private var chartMax: Double {
        max(chartMin + 5.0, ceil(maxWatts + 1.5))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Real-Time Power Curve", systemImage: "waveform.path.ecg")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 12) {
                    statBadge(label: "Min", value: String(format: "%.1f W", minWatts), color: .green)
                    statBadge(label: "Avg", value: String(format: "%.1f W", avgWatts), color: .blue)
                    statBadge(label: "Peak", value: String(format: "%.1f W", maxWatts), color: .orange)
                }
            }

            ZStack {
                // Background grid & markers
                gridBackground

                // Canvas line & gradient fill
                Canvas { context, size in
                    guard history.count > 1 else { return }

                    let range = chartMax - chartMin
                    guard range > 0 else { return }

                    let stepX = size.width / Double(max(history.count - 1, 1))

                    var points: [CGPoint] = []
                    for (index, point) in history.enumerated() {
                        let x = Double(index) * stepX
                        let normalizedY = (point.watts - chartMin) / range
                        let y = size.height - (normalizedY * size.height)
                        points.append(CGPoint(x: x, y: y))
                    }

                    // Fill Path
                    var fillPath = Path()
                    fillPath.move(to: CGPoint(x: 0, y: size.height))
                    for pt in points {
                        fillPath.addLine(to: pt)
                    }
                    fillPath.addLine(to: CGPoint(x: points.last?.x ?? size.width, y: size.height))
                    fillPath.closeSubpath()

                    let fillGradient = Gradient(colors: [
                        Color.cyan.opacity(0.35),
                        Color.cyan.opacity(0.05),
                        Color.clear
                    ])
                    context.fill(fillPath, with: .linearGradient(fillGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: size.height)))

                    // Stroke Path
                    var strokePath = Path()
                    strokePath.move(to: points[0])
                    for pt in points.dropFirst() {
                        strokePath.addLine(to: pt)
                    }

                    context.stroke(
                        strokePath,
                        with: .color(Color.cyan),
                        lineWidth: 2.5
                    )

                    // Current Point Pulsing Circle
                    if let lastPt = points.last {
                        context.fill(
                            Path(ellipseIn: CGRect(x: lastPt.x - 5, y: lastPt.y - 5, width: 10, height: 10)),
                            with: .color(.white)
                        )
                        context.stroke(
                            Path(ellipseIn: CGRect(x: lastPt.x - 5, y: lastPt.y - 5, width: 10, height: 10)),
                            with: .color(.cyan),
                            lineWidth: 2
                        )
                    }
                }
            }
            .frame(height: 140)
            .padding(.vertical, 4)

            // Timeline footer
            HStack {
                Text("60s ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("30s ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Now")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.cyan)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var gridBackground: some View {
        GeometryReader { geo in
            let range = chartMax - chartMin
            let avgNormalized = range > 0 ? (avgWatts - chartMin) / range : 0.5
            let avgY = geo.size.height - (avgNormalized * geo.size.height)

            ZStack(alignment: .topLeading) {
                // Horizontal reference line for Avg
                Path { path in
                    path.move(to: CGPoint(x: 0, y: avgY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: avgY))
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Color.blue.opacity(0.35))

                // Max guideline text
                HStack {
                    Spacer()
                    Text(String(format: "%.1f W", chartMax))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .offset(y: 2)

                // Avg guideline text
                HStack {
                    Spacer()
                    Text(String(format: "Avg: %.1f W", avgWatts))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.blue.opacity(0.8))
                }
                .offset(y: max(10, avgY - 12))

                // Min guideline text
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(String(format: "%.1f W", chartMin))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
                }
            }
        }
    }

    private func statBadge(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label + ":")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
}
