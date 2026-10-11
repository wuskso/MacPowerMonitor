import Foundation
import Combine

@MainActor
public final class TelemetryEngine: ObservableObject {
    public static let shared = TelemetryEngine()

    @Published public var currentSnapshot: PowerSnapshot = .empty
    @Published public var history: [HistoryPoint] = []
    @Published public var minWatts: Double = 0.0
    @Published public var maxWatts: Double = 0.0
    @Published public var avgWatts: Double = 0.0
    @Published public var refreshInterval: Double = 1.0 {
        didSet {
            restartTimer()
        }
    }

    private let powerManager = PowerTelemetryManager.shared
    private let thermalManager = ThermalTelemetryManager.shared
    private let cpuManager = CPUTelemetryManager.shared

    private var timer: Timer?
    private let maxHistoryCount = 60

    public init() {
        tick()
        startMonitoring()
    }

    public func startMonitoring() {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        startMonitoring()
    }

    public func tick() {
        var snapshot = powerManager.captureSnapshot()
        let thermals = thermalManager.readThermals()
        snapshot.socTemperatureCelsius = thermals.socTemperatureCelsius
        snapshot.batteryTemperatureCelsius = thermals.batteryTemperatureCelsius
        snapshot.cpuUsagePercent = cpuManager.readCPUUsagePercent()

        self.currentSnapshot = snapshot

        // Add to history
        let point = HistoryPoint(timestamp: snapshot.timestamp, watts: snapshot.systemLoadWatts)
        history.append(point)
        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }

        // Calculate min, max, avg
        if !history.isEmpty {
            let wattsList = history.map(\.watts)
            minWatts = wattsList.min() ?? 0.0
            maxWatts = wattsList.max() ?? 0.0
            avgWatts = wattsList.reduce(0.0, +) / Double(wattsList.count)
        }
    }
}
