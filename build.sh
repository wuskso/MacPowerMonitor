#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="MacPowerMonitor"
BUNDLE_DIR="$SCRIPT_DIR/$APP_NAME.app"
MACOS_DIR="$BUNDLE_DIR/Contents/MacOS"
RESOURCES_DIR="$BUNDLE_DIR/Contents/Resources"
CACHE_DIR="$SCRIPT_DIR/.module-cache"

echo "==> Building $APP_NAME for macOS..."

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$CACHE_DIR"

# Collect all swift source files
SOURCES=(
    "$SCRIPT_DIR/Sources/Models/PowerModels.swift"
    "$SCRIPT_DIR/Sources/Services/PowerTelemetryManager.swift"
    "$SCRIPT_DIR/Sources/Services/ThermalTelemetryManager.swift"
    "$SCRIPT_DIR/Sources/Services/CPUTelemetryManager.swift"
    "$SCRIPT_DIR/Sources/Services/TelemetryEngine.swift"
    "$SCRIPT_DIR/Sources/Views/MetricCardView.swift"
    "$SCRIPT_DIR/Sources/Views/PowerChartView.swift"
    "$SCRIPT_DIR/Sources/Views/DashboardView.swift"
    "$SCRIPT_DIR/Sources/Views/MenuBarView.swift"
    "$SCRIPT_DIR/Sources/App/MacPowerMonitorApp.swift"
)

echo "==> Compiling Swift sources..."
swiftc \
    -module-cache-path "$CACHE_DIR" \
    -parse-as-library \
    -O \
    "${SOURCES[@]}" \
    -o "$MACOS_DIR/$APP_NAME"

echo "==> Copying Info.plist..."
cp "$SCRIPT_DIR/Resources/Info.plist" "$BUNDLE_DIR/Contents/Info.plist"

echo "==> Ad-hoc signing app bundle..."
codesign --force --deep --sign - "$BUNDLE_DIR"

echo "==> Build successful! App bundle created at:"
echo "    $BUNDLE_DIR"
