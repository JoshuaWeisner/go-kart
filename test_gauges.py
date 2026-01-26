#!/usr/bin/env python3
"""
Test file to cycle through all telemetry values to visualize gauge animations.
Smoothly animates all values from 0 to max range over 10 seconds, then repeats.
"""

import sys
import os
import math
from pathlib import Path

# Set Qt Quick Controls style BEFORE importing Qt
# (macOS native style doesn't support customization)
os.environ['QT_QUICK_CONTROLS_STYLE'] = 'Basic'

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from PySide6.QtCore import QObject, QTimer, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from main import TelemetryBridge


class GaugeTester(QObject):
    """Cycles through telemetry values to test gauge animations"""
    
    def __init__(self, telemetry_bridge: TelemetryBridge, debug=False):
        super().__init__()
        self.telemetry = telemetry_bridge
        self.time = 0.0
        self.cycle_duration = 10.0  # 10 seconds per full cycle
        self.debug = debug
        
        # Connect to a signal to verify updates are working
        if self.debug:
            self.telemetry.speedChanged.connect(
                lambda v: print(f"[DEBUG] Speed changed signal received: {v:.1f} km/h")
            )
            self.telemetry.rpmChanged.connect(
                lambda v: print(f"[DEBUG] RPM changed signal received: {v}")
            )
        
        # Setup timer for smooth animation (60 FPS)
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_values)
        self.timer.start(16)  # ~60 FPS
        
    def update_values(self):
        """Update all telemetry values based on sine wave progression"""
        # Increment time
        self.time += 0.016  # 16ms per frame
        
        # Normalize time to 0-1 range for one cycle
        cycle_progress = (self.time % self.cycle_duration) / self.cycle_duration
        
        # Use sine wave for smooth back-and-forth motion (0 -> 1 -> 0)
        # This creates a more realistic "driving" feel
        wave = (math.sin(cycle_progress * 2 * math.pi - math.pi / 2) + 1) / 2
        
        # Create a mock VESC status with calculated values
        from middleware.vesc_codec import VESCStatus
        
        # Calculate values based on wave position
        status = VESCStatus()
        
        # RPM: Full range 0-6000 for dramatic gauge animation
        status.rpm = int(wave * 6000)
        
        # Voltage: 48-54V (typical for 48V system under load)
        status.voltage = 48 + (wave * 6)
        
        # Motor Current: 0-200A
        status.current_motor = wave * 200
        
        # Battery Current: 0-200A (similar to motor current)
        status.current_battery = wave * 195
        
        # Power: calculated from voltage and current
        status.power = status.voltage * status.current_motor
        
        # MOSFET Temperature: 25-95°C (ambient to hot)
        status.temp_mos = 25 + (wave * 70)
        
        # Motor temperature (not displayed but needed for VESCStatus)
        status.temp_motor = 25 + (wave * 60)
        
        # Duty Cycle: 0-100%
        status.duty_cycle = wave
        
        # Efficiency: 75-95% (realistic range)
        status.efficiency = 75 + (wave * 20)
        
        # Energy consumed: slowly increasing
        status.amp_hours_consumed = self.time * 0.1
        status.amp_hours_charged = 0
        status.watt_hours_consumed = self.time * 5
        status.watt_hours_charged = 0
        
        # Tachometer: correlates with RPM
        status.tachometer = int(self.time * 100)
        status.tachometer_abs = int(self.time * 100)
        
        # Fault code: 0 = no fault
        status.fault_code = 0
        
        # Update telemetry bridge using the proper method
        self.telemetry.update_from_status(status)
        
        # Print current status every second
        if int(self.time * 10) % 10 == 0:
            print(f"Progress: {cycle_progress*100:.1f}% | Speed: {self.telemetry.speed:.1f} km/h | "
                  f"RPM: {self.telemetry.rpm} | Voltage: {self.telemetry.voltage:.1f}V | "
                  f"Current: {self.telemetry.currentMotor:.1f}A | Temp: {self.telemetry.tempMos:.1f}°C")


def main():
    # Create Qt application
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Go-Kart Gauge Tester")
    
    # Create telemetry bridge
    telemetry = TelemetryBridge()
    
    # Adjust wheel parameters for realistic speed display in test mode
    # At 6000 RPM, we want ~80 km/h max speed
    # Speed (km/h) = (RPM / gear_ratio) * wheel_circumference * 60 / 1000 * 3.6
    # 80 = 6000 * wheel_circumference * 0.06 * 3.6
    # wheel_circumference = 80 / (6000 * 0.216) = 0.0617m
    # diameter = 0.0617 / 3.14159 = 0.0196m
    telemetry.wheel_diameter_m = 0.0196  # Adjusted for realistic test speeds
    
    # Create QML engine
    engine = QQmlApplicationEngine()
    
    # Add project root to QML import path so "import ui 1.0" can find ui/qmldir
    engine.addImportPath(str(project_root))
    
    # Expose telemetry bridge to QML
    engine.rootContext().setContextProperty("telemetry", telemetry)
    
    # Load main QML file
    qml_file = project_root / "ui" / "main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))
    
    if not engine.rootObjects():
        print("ERROR: Failed to load QML")
        sys.exit(1)
    
    # Create gauge tester (set debug=True to see signal emissions)
    tester = GaugeTester(telemetry, debug=False)
    
    print("=" * 80)
    print("GAUGE TESTER STARTED")
    print("=" * 80)
    print("Watch the gauges animate through their full range!")
    print("- Speed: 0-80 km/h")
    print("- RPM: 0-6000 (redline at 5000)")
    print("- Voltage: 48-54V")
    print("- Current: 0-200A")
    print("- MOSFET Temp: 25-95°C")
    print("- Cycle duration: 10 seconds")
    print("=" * 80)
    print()
    
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
