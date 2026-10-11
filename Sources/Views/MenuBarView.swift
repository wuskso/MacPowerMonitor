import SwiftUI
import AppKit

@MainActor
public struct MenuBarView: View {
    @ObservedObject var engine: TelemetryEngine
    public let onOpenDashboard: () -> Void

    @MainActor
    public init(engine: TelemetryEngine, onOpenDashboard: @escaping () -> Void) {
        self.engine = engine
        self.onOpenDashboard = onOpenDashboard
    }

    public var body: some View {
        let snap = engine.currentSnapshot

        VStack(alignment: .leading, spacing: 12) {
            // Header: Live Wattage
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: snap.externalConnected ? "bolt.fill" : "battery.75")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(snap.externalConnected ? .green : .orange)
                    Text("System Power")
                        .font(.headline)
                }

                Spacer()

                Text(String(format: "%.1f W", snap.systemLoadWatts))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.cyan)
            }

            Divider()

            // Quick Stats Rows
            VStack(spacing: 8) {
                // Row 1: Battery
                HStack {
                    Label("Battery Level", systemImage: "battery.100")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(snap.batteryPercentage)%")
                        .fontWeight(.semibold)
                    if snap.isCharging {
                        Text("(+\(String(format: "%.1f", snap.batteryPowerWatts)) W)")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if !snap.externalConnected {
                        Text("(-\(String(format: "%.1f", abs(snap.batteryPowerWatts))) W)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                // Row 2: Adapter
                if snap.externalConnected {
                    HStack {
                        Label("AC Adapter", systemImage: "powerplug")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(snap.adapterName) (\(snap.adapterRatedWatts)W)")
                            .fontWeight(.medium)
                    }
                }

                // Row 3: Thermals & CPU
                HStack {
                    Label("SoC Temp", systemImage: "thermometer.medium")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(snap.socTemperatureCelsius.map { String(format: "%.1f °C", $0) } ?? "N/A")
                        .fontWeight(.medium)

                    Spacer().frame(width: 12)

                    Label("CPU", systemImage: "cpu")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", snap.cpuUsagePercent))
                        .fontWeight(.medium)
                }

                // Row 4: Min / Max Range
                HStack {
                    Text("1-min Range:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(String(format: "%.1f", engine.minWatts)) W  —  \(String(format: "%.1f", engine.maxWatts)) W")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)

            Divider()

            // Footer Actions
            HStack {
                Button(action: onOpenDashboard) {
                    Label("Open Dashboard", systemImage: "macwindow")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 300)
    }
}
