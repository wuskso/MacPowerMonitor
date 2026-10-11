import Foundation
import Darwin

public final class CPUTelemetryManager: @unchecked Sendable {
    public static let shared = CPUTelemetryManager()

    private var previousCPULoad: host_cpu_load_info?

    public init() {}

    public func readCPUUsagePercent() -> Double {
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var cpuLoad = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0.0
        }

        guard let prev = previousCPULoad else {
            previousCPULoad = cpuLoad
            return 0.0
        }

        let userDiff = Double(cpuLoad.cpu_ticks.0 - prev.cpu_ticks.0)
        let sysDiff  = Double(cpuLoad.cpu_ticks.1 - prev.cpu_ticks.1)
        let idleDiff = Double(cpuLoad.cpu_ticks.2 - prev.cpu_ticks.2)
        let niceDiff = Double(cpuLoad.cpu_ticks.3 - prev.cpu_ticks.3)

        let total = userDiff + sysDiff + idleDiff + niceDiff
        previousCPULoad = cpuLoad

        guard total > 0.0 else { return 0.0 }
        let active = userDiff + sysDiff + niceDiff
        return max(0.0, min(100.0, (active / total) * 100.0))
    }
}
