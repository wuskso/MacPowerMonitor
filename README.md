# MacPowerMonitor

A lightweight, native macOS application written in **Swift** to monitor real-time power consumption on MacBooks (Apple Silicon M-series and Intel MacBooks).

Runs 100% in user space without requiring `sudo` or root privileges.

---

## Features

- **⚡ Real-Time System Power Draw**: Measures total power consumption in Watts (W) and milliwatts (mW) directly from IOKit power telemetry.
- **📈 Dynamic Live Power Chart**: Smooth Canvas curve tracking power variations over time with Min, Average, and Peak markers.
- **🔌 Power Source & AC Adapter Telemetry**:
  - Distinguishes between AC power and Battery operation.
  - Displays adapter model name and rated wattage (e.g. 35W, 67W, 140W).
  - Shows real-time input power and cable/conversion efficiency loss.
- **🔋 Battery Flow & Health**:
  - Active charge / discharge wattage.
  - State of charge (%), health capacity %, design capacity vs current capacity (mAh).
  - Battery cycle count and rail voltage (V) / current (A).
  - Estimated time remaining to full charge or empty.
- **🔌 USB-C Port Peripherals**: Real-time power draw delivered to external connected accessories.
- **🌡️ Hardware Thermals**: Live SoC die temperature and battery temperature via `IOHIDEventSystemClient`.
- **💻 CPU Utilization**: Live Mach kernel processor active load.
- **🎛️ Dual Form Factor**:
  - **Menu Bar Extra**: Minimalist icon and live wattage (`⚡ 8.6 W`) with a quick status popover.
  - **Dashboard Window**: Detailed overview with interactive charts and component cards.

---

## Architecture

- **`Sources/Models/`**: `PowerSnapshot` and `HistoryPoint` models.
- **`Sources/Services/`**:
  - `PowerTelemetryManager.swift`: Direct IOKit interface for `AppleSmartBattery` telemetry.
  - `ThermalTelemetryManager.swift`: Non-root thermal sensor extraction.
  - `CPUTelemetryManager.swift`: Mach kernel `host_statistics64` processor usage.
  - `TelemetryEngine.swift`: Main actor observable state coordinator.
- **`Sources/Views/`**:
  - `DashboardView.swift`: Main macOS dashboard window.
  - `PowerChartView.swift`: Live 60-second power curve canvas.
  - `MetricCardView.swift`: Modular metric cards with progress bars.
  - `MenuBarView.swift`: Menu bar item popover.
- **`Sources/App/`**:
  - `MacPowerMonitorApp.swift`: SwiftUI App entry point configuring `MenuBarExtra` and `Window`.

---

## Build & Run

To build the standalone `.app` bundle:

```bash
./build.sh
```

This compiles all Swift sources with `swiftc -O` and generates `MacPowerMonitor.app`.

To launch the app:

```bash
open MacPowerMonitor.app
```
