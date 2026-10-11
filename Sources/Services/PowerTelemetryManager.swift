import Foundation
import IOKit

public final class PowerTelemetryManager: Sendable {
    public static let shared = PowerTelemetryManager()

    public init() {}

    public func captureSnapshot() -> PowerSnapshot {
        var snapshot = PowerSnapshot()
        snapshot.timestamp = Date()

        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else {
            return snapshot
        }
        defer {
            IOObjectRelease(service)
        }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else {
            return snapshot
        }

        // Top-level boolean flags
        let isCharging = (dict["IsCharging"] as? Bool) ?? (dict["IsCharging"] as? Int == 1)
        let externalConnected = (dict["ExternalConnected"] as? Bool) ?? (dict["ExternalConnected"] as? Int == 1)
        snapshot.isCharging = isCharging
        snapshot.externalConnected = externalConnected

        // Voltage and Amperage
        let voltageMv = (dict["Voltage"] as? Double) ?? (dict["Voltage"] as? Int).map(Double.init) ?? 0.0
        let instantAmperageMa = (dict["InstantAmperage"] as? Double) ?? (dict["InstantAmperage"] as? Int).map(Double.init) ?? 0.0
        snapshot.batteryVoltageVolts = voltageMv / 1000.0
        snapshot.batteryCurrentAmperes = instantAmperageMa / 1000.0

        // Cycle Count
        if let cycleCount = dict["CycleCount"] as? Int {
            snapshot.batteryCycleCount = cycleCount
        }

        // Top-level Capacity
        if let curCap = dict["CurrentCapacity"] as? Int {
            snapshot.batteryPercentage = curCap
        }

        // BatteryData subdictionary
        if let batteryData = dict["BatteryData"] as? [String: Any] {
            if let curCap = batteryData["CurrentCapacity"] as? Int {
                snapshot.batteryPercentage = curCap
            }
            if let maxCap = batteryData["MaxCapacity"] as? Int {
                snapshot.batteryHealthPercentage = maxCap
            }
            if let rawCur = batteryData["AppleRawCurrentCapacity"] as? Int {
                snapshot.batteryRemainingCapacityMah = rawCur
            } else if let rem = batteryData["RemainingCapacity"] as? Int {
                snapshot.batteryRemainingCapacityMah = rem
            }
            if let rawMax = batteryData["AppleRawMaxCapacity"] as? Int {
                snapshot.batteryFullCapacityMah = rawMax
            } else if let full = batteryData["FullChargeCapacity"] as? Int {
                snapshot.batteryFullCapacityMah = full
            }
            if let design = batteryData["DesignCapacity"] as? Int {
                snapshot.batteryDesignCapacityMah = design
            }
            if let cycles = batteryData["CycleCount"] as? Int {
                snapshot.batteryCycleCount = cycles
            }
        }

        // Time Remaining
        if isCharging {
            if let avgTimeToFull = dict["AvgTimeToFull"] as? Int, avgTimeToFull > 0 && avgTimeToFull < 65535 {
                snapshot.timeRemainingMinutes = avgTimeToFull
            }
        } else {
            if let avgTimeToEmpty = dict["AvgTimeToEmpty"] as? Int, avgTimeToEmpty > 0 && avgTimeToEmpty < 65535 {
                snapshot.timeRemainingMinutes = avgTimeToEmpty
            }
        }

        // Adapter Details
        if let adapterDetails = dict["AdapterDetails"] as? [String: Any] {
            snapshot.adapterName = (adapterDetails["Name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? (adapterDetails["Description"] as? String)
                ?? "Power Adapter"
            snapshot.adapterRatedWatts = (adapterDetails["Watts"] as? Int) ?? 0
            if let vMv = (adapterDetails["AdapterVoltage"] as? Double) ?? (adapterDetails["AdapterVoltage"] as? Int).map(Double.init) {
                snapshot.adapterVoltageVolts = vMv / 1000.0
            }
            if let cMa = (adapterDetails["Current"] as? Double) ?? (adapterDetails["Current"] as? Int).map(Double.init) {
                snapshot.adapterCurrentAmperes = cMa / 1000.0
            }
        } else if !externalConnected {
            snapshot.adapterName = "Disconnected"
            snapshot.adapterRatedWatts = 0
        }

        // Power Distribution
        if let powerDist = dict["PowerDistribution"] as? [String: Any] {
            if let inputPowerMw = (powerDist["IPDInputPower"] as? Double) ?? (powerDist["IPDInputPower"] as? Int).map(Double.init) {
                snapshot.chargerPowerWatts = inputPowerMw / 1000.0
            }
        }

        // Power Telemetry Data
        var foundSystemLoad = false
        if let telemetry = dict["PowerTelemetryData"] as? [String: Any] {
            if let sysLoadMw = (telemetry["SystemLoad"] as? Double) ?? (telemetry["SystemLoad"] as? Int).map(Double.init) {
                if sysLoadMw > 0 {
                    snapshot.systemLoadWatts = sysLoadMw / 1000.0
                    foundSystemLoad = true
                }
            }

            if let sysPowerInMw = (telemetry["SystemPowerIn"] as? Double) ?? (telemetry["SystemPowerIn"] as? Int).map(Double.init) {
                if sysPowerInMw > 0 {
                    snapshot.chargerPowerWatts = sysPowerInMw / 1000.0
                }
            }

            if let lossMw = (telemetry["AdapterEfficiencyLoss"] as? Double) ?? (telemetry["AdapterEfficiencyLoss"] as? Int).map(Double.init) {
                snapshot.adapterEfficiencyLossWatts = max(0.0, lossMw / 1000.0)
            }

            if let batPowerMw = (telemetry["BatteryPower"] as? Double) ?? (telemetry["BatteryPower"] as? Int).map(Double.init) {
                let batWatts = batPowerMw / 1000.0
                if isCharging {
                    snapshot.batteryPowerWatts = abs(batWatts)
                } else if !externalConnected {
                    snapshot.batteryPowerWatts = -abs(batWatts)
                } else {
                    snapshot.batteryPowerWatts = 0.0
                }
            }
        }

        // Fallback calculations if PowerTelemetryData is absent or zero
        let instantaneousBatWatts = (voltageMv * instantAmperageMa) / 1_000_000.0

        if snapshot.batteryPowerWatts == 0.0 && instantAmperageMa != 0.0 {
            snapshot.batteryPowerWatts = instantaneousBatWatts
        }

        if !foundSystemLoad {
            if !externalConnected {
                // Running on battery: system load is exactly discharge rate
                snapshot.systemLoadWatts = max(0.0, abs(instantaneousBatWatts))
            } else {
                // On AC: system load = charger input - battery charging power
                let calc = snapshot.chargerPowerWatts - max(0.0, snapshot.batteryPowerWatts)
                snapshot.systemLoadWatts = max(1.0, calc)
            }
        }

        // USB-C Accessory Ports Power (PowerOutDetails)
        if let powerOutArray = dict["PowerOutDetails"] as? [[String: Any]] {
            for item in powerOutArray {
                if let portIdx = item["PortIndex"] as? Int {
                    let portMw = (item["Watts"] as? Double)
                        ?? (item["Watts"] as? Int).map(Double.init)
                        ?? (item["FilteredPower"] as? Double)
                        ?? (item["FilteredPower"] as? Int).map(Double.init)
                        ?? 0.0
                    snapshot.usbPortsPowerMw[portIdx] = portMw
                }
            }
        }

        return snapshot
    }
}
