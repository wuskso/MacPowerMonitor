import Foundation
import IOKit

public struct ThermalReading: Sendable {
    public var socTemperatureCelsius: Double?
    public var batteryTemperatureCelsius: Double?
}

public final class ThermalTelemetryManager: @unchecked Sendable {
    public static let shared = ThermalTelemetryManager()

    private let client: AnyObject?

    // IOHID Private function bindings
    private typealias ClientCreateFunc = @convention(c) (CFAllocator?) -> AnyObject?
    private typealias SetMatchingFunc = @convention(c) (AnyObject, CFDictionary) -> Int32
    private typealias CopyServicesFunc = @convention(c) (AnyObject) -> CFArray?
    private typealias CopyPropertyFunc = @convention(c) (AnyObject, CFString) -> AnyObject?
    private typealias CopyEventFunc = @convention(c) (AnyObject, Int64, Int32, Int64) -> AnyObject?
    private typealias GetFloatValueFunc = @convention(c) (AnyObject, UInt32) -> Double

    private let setMatchingFn: SetMatchingFunc?
    private let copyServicesFn: CopyServicesFunc?
    private let copyPropertyFn: CopyPropertyFunc?
    private let copyEventFn: CopyEventFunc?
    private let getFloatValueFn: GetFloatValueFunc?

    public init() {
        let handle = dlopen(nil, RTLD_NOW)
        if let handle = handle {
            if let pCreate = dlsym(handle, "IOHIDEventSystemClientCreate"),
               let pSetMatching = dlsym(handle, "IOHIDEventSystemClientSetMatching"),
               let pCopyServices = dlsym(handle, "IOHIDEventSystemClientCopyServices"),
               let pCopyProperty = dlsym(handle, "IOHIDServiceClientCopyProperty"),
               let pCopyEvent = dlsym(handle, "IOHIDServiceClientCopyEvent"),
               let pGetFloat = dlsym(handle, "IOHIDEventGetFloatValue") {
                
                let createFn = unsafeBitCast(pCreate, to: ClientCreateFunc.self)
                self.setMatchingFn = unsafeBitCast(pSetMatching, to: SetMatchingFunc.self)
                self.copyServicesFn = unsafeBitCast(pCopyServices, to: CopyServicesFunc.self)
                self.copyPropertyFn = unsafeBitCast(pCopyProperty, to: CopyPropertyFunc.self)
                self.copyEventFn = unsafeBitCast(pCopyEvent, to: CopyEventFunc.self)
                self.getFloatValueFn = unsafeBitCast(pGetFloat, to: GetFloatValueFunc.self)
                self.client = createFn(kCFAllocatorDefault)

                if let client = self.client, let setMatching = self.setMatchingFn {
                    let matchDict = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 5] as CFDictionary
                    _ = setMatching(client, matchDict)
                }
                return
            }
        }

        self.client = nil
        self.setMatchingFn = nil
        self.copyServicesFn = nil
        self.copyPropertyFn = nil
        self.copyEventFn = nil
        self.getFloatValueFn = nil
    }

    public func readThermals() -> ThermalReading {
        guard let client = client,
              let copyServices = copyServicesFn,
              let copyProperty = copyPropertyFn,
              let copyEvent = copyEventFn,
              let getFloatValue = getFloatValueFn else {
            return ThermalReading(socTemperatureCelsius: nil, batteryTemperatureCelsius: nil)
        }

        guard let services = copyServices(client) as? [AnyObject] else {
            return ThermalReading(socTemperatureCelsius: nil, batteryTemperatureCelsius: nil)
        }

        var socTemps: [Double] = []
        var batTemp: Double? = nil

        let tempEventField: UInt32 = (15 << 16) // IOHIDEventTypeTemperature = 15

        for service in services {
            guard let name = copyProperty(service, "Product" as CFString) as? String else { continue }
            guard let event = copyEvent(service, 15, 0, 0) else { continue }
            let temp = getFloatValue(event, tempEventField)
            guard temp > 0.0 && temp < 130.0 else { continue }

            let lowerName = name.lowercased()
            if lowerName.contains("gas gauge") || lowerName.contains("battery") {
                batTemp = temp
            } else if lowerName.contains("tdie") || lowerName.contains("soc") || lowerName.contains("cpu") {
                socTemps.append(temp)
            }
        }

        let avgSoc = socTemps.isEmpty ? nil : (socTemps.reduce(0.0, +) / Double(socTemps.count))

        return ThermalReading(
            socTemperatureCelsius: avgSoc,
            batteryTemperatureCelsius: batTemp
        )
    }
}
