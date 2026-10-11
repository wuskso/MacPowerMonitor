import SwiftUI

@MainActor
public struct DashboardView: View {
    @ObservedObject var engine: TelemetryEngine

    @MainActor
    public init(engine: TelemetryEngine) {
        self.engine = engine
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerBar
                heroPowerBanner
                PowerChartView(
                    history: engine.history,
                    minWatts: engine.minWatts,
                    maxWatts: engine.maxWatts,
                    avgWatts: engine.avgWatts
                )
                metricsGrid
            }
            .padding(20)
        }
        .frame(minWidth: 640, minHeight: 600)
        .background(Color(nsColor: .underPageBackgroundColor).opacity(0.4))
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MacBook Power Monitor")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Real-Time System Power & Telemetry")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Source Mode Pill
            let snap = engine.currentSnapshot
            HStack(spacing: 6) {
                Image(systemName: snap.externalConnected ? "bolt.fill" : "battery.75")
                    .foregroundStyle(snap.externalConnected ? .green : .orange)
                Text(snap.externalConnected ? (snap.isCharging ? "Charging" : "AC Connected") : "On Battery")
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill((snap.externalConnected ? Color.green : Color.orange).opacity(0.12))
            )

            // Refresh rate selector
            Picker("", selection: $engine.refreshInterval) {
                Text("0.5s").tag(0.5)
                Text("1.0s").tag(1.0)
                Text("2.0s").tag(2.0)
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
        }
    }

    // MARK: - Hero Power Banner
    private var heroPowerBanner: some View {
        let snap = engine.currentSnapshot
        return HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT TOTAL POWER")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.2f", snap.systemLoadWatts))
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.cyan)

                    Text("W")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(String(format: "(%.0f mW)", snap.systemLoadWatts * 1000.0))
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.8))
                }

                // Sub-description
                HStack(spacing: 6) {
                    if snap.isCharging {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundStyle(.green)
                        Text(String(format: "Battery charging at +%.1f W", snap.batteryPowerWatts))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if !snap.externalConnected {
                        Image(systemName: "arrow.down.right.circle.fill")
                            .foregroundStyle(.orange)
                        Text(String(format: "Battery discharging at %.1f W", abs(snap.batteryPowerWatts)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Powered by AC Adapter (Battery Idle)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Quick Rail Stats
            VStack(alignment: .trailing, spacing: 8) {
                railStat(label: "Rail Voltage", value: String(format: "%.2f V", snap.batteryVoltageVolts))
                railStat(label: "Rail Current", value: String(format: "%.2f A", snap.batteryCurrentAmperes))
                if let minutes = snap.timeRemainingMinutes {
                    railStat(
                        label: snap.isCharging ? "Time to Full" : "Time to Empty",
                        value: "\(minutes / 60)h \(minutes % 60)m"
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.12),
                            Color.blue.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
        )
    }

    private func railStat(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        let snap = engine.currentSnapshot
        let columns = [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]

        return LazyVGrid(columns: columns, spacing: 14) {
            // Card 1: Battery Telemetry
            MetricCardView(
                title: "Battery Status",
                value: "\(snap.batteryPercentage)%",
                subtitle: "\(snap.batteryRemainingCapacityMah) / \(snap.batteryFullCapacityMah) mAh • Health: \(snap.batteryHealthPercentage)%",
                systemImage: "battery.100",
                accentColor: snap.batteryPercentage > 20 ? .green : .red,
                progress: Double(snap.batteryPercentage) / 100.0
            )

            // Card 2: Power Adapter
            MetricCardView(
                title: "AC Adapter Input",
                value: snap.externalConnected ? String(format: "%.1f W", snap.chargerPowerWatts) : "Disconnected",
                subtitle: snap.externalConnected ? "\(snap.adapterName) (\(snap.adapterRatedWatts)W) • Loss: \(String(format: "%.1f W", snap.adapterEfficiencyLossWatts))" : "Operating on battery power",
                systemImage: "powerplug.fill",
                accentColor: .blue
            )

            // Card 3: Thermals
            let socStr = snap.socTemperatureCelsius.map { String(format: "%.1f °C", $0) } ?? "N/A"
            let batStr = snap.batteryTemperatureCelsius.map { String(format: "%.1f °C", $0) } ?? "N/A"
            MetricCardView(
                title: "Hardware Thermals",
                value: socStr,
                subtitle: "SoC Core: \(socStr) • Battery: \(batStr)",
                systemImage: "thermometer.medium",
                accentColor: .orange
            )

            // Card 4: CPU Activity
            MetricCardView(
                title: "Processor Load",
                value: String(format: "%.1f%%", snap.cpuUsagePercent),
                subtitle: "Mach host CPU active load",
                systemImage: "cpu",
                accentColor: .purple,
                progress: snap.cpuUsagePercent / 100.0
            )

            // Card 5: Battery Cycle Count & Health
            MetricCardView(
                title: "Cycle Count & Battery Wear",
                value: "\(snap.batteryCycleCount) Cycles",
                subtitle: "Design: \(snap.batteryDesignCapacityMah) mAh • Max: \(snap.batteryFullCapacityMah) mAh",
                systemImage: "arrow.triangle.2.circlepath",
                accentColor: .teal
            )

            // Card 6: USB-C Peripheral Ports Draw
            let portsDrawTotal = snap.usbPortsPowerMw.values.reduce(0.0, +)
            let portsSummary = snap.usbPortsPowerMw.map { "Port \($0.key): \(String(format: "%.0f mW", $0.value))" }.joined(separator: " • ")
            MetricCardView(
                title: "USB-C Port Peripherals",
                value: portsDrawTotal > 0 ? String(format: "%.1f W", portsDrawTotal / 1000.0) : "0 mW",
                subtitle: portsSummary.isEmpty ? "No active accessory draw" : portsSummary,
                systemImage: "cable.connector",
                accentColor: .indigo
            )
        }
    }
}
