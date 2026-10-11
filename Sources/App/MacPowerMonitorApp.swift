import SwiftUI
import AppKit

@main
struct MacPowerMonitorApp: App {
    @StateObject private var engine = TelemetryEngine.shared
    @Environment(\.openWindow) private var openWindow

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        // Menu Bar Item
        MenuBarExtra {
            MenuBarView(engine: engine) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openWindow(id: "dashboard")
            }
        } label: {
            let snap = engine.currentSnapshot
            let iconName = snap.externalConnected ? "bolt.fill" : "battery.75"
            HStack(spacing: 3) {
                Image(systemName: iconName)
                Text(String(format: "%.1f W", snap.systemLoadWatts))
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)

        // Main Dashboard Window
        Window("MacBook Power Monitor", id: "dashboard") {
            DashboardView(engine: engine)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 720, height: 680)
    }
}
