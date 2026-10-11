import Foundation

public struct HistoryPoint: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let watts: Double

    public init(id: UUID = UUID(), timestamp: Date = Date(), watts: Double) {
        self.id = id
        self.timestamp = timestamp
        self.watts = watts
    }
}

public struct PowerSnapshot: Sendable {
    public var timestamp: Date
    
    // System Power
    public var systemLoadWatts: Double
    
    // Battery Power & State
    public var batteryPowerWatts: Double // Positive = charging into battery, Negative = discharging from battery
    public var isCharging: Bool
    public var externalConnected: Bool
    public var batteryPercentage: Int
    public var batteryRemainingCapacityMah: Int
    public var batteryFullCapacityMah: Int
    public var batteryDesignCapacityMah: Int
    public var batteryCycleCount: Int
    public var batteryHealthPercentage: Int
    public var batteryVoltageVolts: Double
    public var batteryCurrentAmperes: Double
    public var timeRemainingMinutes: Int?
    
    // AC Adapter / Charger
    public var chargerPowerWatts: Double
    public var adapterName: String
    public var adapterRatedWatts: Int
    public var adapterEfficiencyLossWatts: Double
    public var adapterVoltageVolts: Double
    public var adapterCurrentAmperes: Double
    
    // USB-C Accessory Ports
    public var usbPortsPowerMw: [Int: Double] // e.g. Port 1: 0 mW, Port 2: 515 mW
    
    // Thermals & CPU
    public var socTemperatureCelsius: Double?
    public var batteryTemperatureCelsius: Double?
    public var cpuUsagePercent: Double

    public init(
        timestamp: Date = Date(),
        systemLoadWatts: Double = 0.0,
        batteryPowerWatts: Double = 0.0,
        isCharging: Bool = false,
        externalConnected: Bool = false,
        batteryPercentage: Int = 0,
        batteryRemainingCapacityMah: Int = 0,
        batteryFullCapacityMah: Int = 0,
        batteryDesignCapacityMah: Int = 0,
        batteryCycleCount: Int = 0,
        batteryHealthPercentage: Int = 100,
        batteryVoltageVolts: Double = 0.0,
        batteryCurrentAmperes: Double = 0.0,
        timeRemainingMinutes: Int? = nil,
        chargerPowerWatts: Double = 0.0,
        adapterName: String = "None",
        adapterRatedWatts: Int = 0,
        adapterEfficiencyLossWatts: Double = 0.0,
        adapterVoltageVolts: Double = 0.0,
        adapterCurrentAmperes: Double = 0.0,
        usbPortsPowerMw: [Int: Double] = [:],
        socTemperatureCelsius: Double? = nil,
        batteryTemperatureCelsius: Double? = nil,
        cpuUsagePercent: Double = 0.0
    ) {
        self.timestamp = timestamp
        self.systemLoadWatts = systemLoadWatts
        self.batteryPowerWatts = batteryPowerWatts
        self.isCharging = isCharging
        self.externalConnected = externalConnected
        self.batteryPercentage = batteryPercentage
        self.batteryRemainingCapacityMah = batteryRemainingCapacityMah
        self.batteryFullCapacityMah = batteryFullCapacityMah
        self.batteryDesignCapacityMah = batteryDesignCapacityMah
        self.batteryCycleCount = batteryCycleCount
        self.batteryHealthPercentage = batteryHealthPercentage
        self.batteryVoltageVolts = batteryVoltageVolts
        self.batteryCurrentAmperes = batteryCurrentAmperes
        self.timeRemainingMinutes = timeRemainingMinutes
        self.chargerPowerWatts = chargerPowerWatts
        self.adapterName = adapterName
        self.adapterRatedWatts = adapterRatedWatts
        self.adapterEfficiencyLossWatts = adapterEfficiencyLossWatts
        self.adapterVoltageVolts = adapterVoltageVolts
        self.adapterCurrentAmperes = adapterCurrentAmperes
        self.usbPortsPowerMw = usbPortsPowerMw
        self.socTemperatureCelsius = socTemperatureCelsius
        self.batteryTemperatureCelsius = batteryTemperatureCelsius
        self.cpuUsagePercent = cpuUsagePercent
    }

    public static var empty: PowerSnapshot {
        PowerSnapshot()
    }
}
