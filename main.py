#!/usr/bin/env python3
"""
Go-Kart Telemetry Dashboard - Main Application Entry Point
Bridges CAN bus telemetry with Qt/QML UI using signal/slot architecture.
"""

import sys
import os
import argparse
from pathlib import Path

# Set Qt Quick Controls style BEFORE importing Qt
# (macOS native style doesn't support customization)
os.environ['QT_QUICK_CONTROLS_STYLE'] = 'Basic'

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from PySide6.QtCore import QObject, Signal, QTimer, QUrl, Slot, Property
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import qmlRegisterType, QQmlApplicationEngine

from middleware.can_manager import CANManager
from middleware.vesc_codec import VESCCodec, VESCStatus
from mock.simulator import VESCSimulator


class TelemetryBridge(QObject):
    """
    Bridge between CAN middleware and QML UI.
    Exposes telemetry data as Qt properties for QML binding.
    """
    
    # Signals for QML
    speedChanged = Signal(float)
    rpmChanged = Signal(int)
    voltageChanged = Signal(float)
    currentMotorChanged = Signal(float)
    currentBatteryChanged = Signal(float)
    powerChanged = Signal(float)
    tempMosChanged = Signal(float)
    tempMotorChanged = Signal(float)
    dutyCycleChanged = Signal(float)
    efficiencyChanged = Signal(float)
    ampHoursConsumedChanged = Signal(float)
    ampHoursChargedChanged = Signal(float)
    wattHoursConsumedChanged = Signal(float)
    wattHoursChargedChanged = Signal(float)
    tachometerChanged = Signal(int)
    tachometerAbsChanged = Signal(int)
    faultCodeChanged = Signal(int)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Current telemetry state
        self._speed = 0.0
        self._rpm = 0
        self._voltage = 0.0
        self._current_motor = 0.0
        self._current_battery = 0.0
        self._power = 0.0
        self._temp_mos = 0.0
        self._temp_motor = 0.0
        self._duty_cycle = 0.0
        self._efficiency = 0.0
        self._amp_hours_consumed = 0.0
        self._amp_hours_charged = 0.0
        self._watt_hours_consumed = 0.0
        self._watt_hours_charged = 0.0
        self._tachometer = 0
        self._tachometer_abs = 0
        self._fault_code = 0
        
        # VESC decoder
        self.codec = VESCCodec()
        
        # Status frame cache for merging multi-frame packets
        self.status_cache = {}
        
        # Motor parameters for speed calculation
        self.wheel_diameter_m = 0.330  # 13" wheel ≈ 0.33m diameter
        self.gear_ratio = 1.0  # Direct drive (adjust if geared)
        self.motor_kv = 130  # 130KV motor
        
    def update_from_status(self, status: VESCStatus):
        """Update all telemetry properties from VESCStatus"""
        # Calculate speed from RPM
        # Speed (km/h) = (RPM / gear_ratio) * wheel_circumference * 60 / 1000
        wheel_circumference = 3.14159 * self.wheel_diameter_m
        speed_ms = (status.rpm / self.gear_ratio) * wheel_circumference / 60.0
        
        # Update properties - need to check for changes and emit signals manually
        new_speed = speed_ms * 3.6
        if self._speed != new_speed:
            self._speed = new_speed
            self.speedChanged.emit(new_speed)
        
        if self._rpm != status.rpm:
            self._rpm = status.rpm
            self.rpmChanged.emit(status.rpm)
        
        if self._voltage != status.voltage:
            self._voltage = status.voltage
            self.voltageChanged.emit(status.voltage)
        
        if self._current_motor != status.current_motor:
            self._current_motor = status.current_motor
            self.currentMotorChanged.emit(status.current_motor)
        
        if self._current_battery != status.current_battery:
            self._current_battery = status.current_battery
            self.currentBatteryChanged.emit(status.current_battery)
        
        if self._power != status.power:
            self._power = status.power
            self.powerChanged.emit(status.power)
        
        if self._temp_mos != status.temp_mos:
            self._temp_mos = status.temp_mos
            self.tempMosChanged.emit(status.temp_mos)
        
        if self._temp_motor != status.temp_motor:
            self._temp_motor = status.temp_motor
            self.tempMotorChanged.emit(status.temp_motor)
        
        if self._duty_cycle != status.duty_cycle:
            self._duty_cycle = status.duty_cycle
            self.dutyCycleChanged.emit(status.duty_cycle)
        
        if self._efficiency != status.efficiency:
            self._efficiency = status.efficiency
            self.efficiencyChanged.emit(status.efficiency)
        
        if self._amp_hours_consumed != status.amp_hours_consumed:
            self._amp_hours_consumed = status.amp_hours_consumed
            self.ampHoursConsumedChanged.emit(status.amp_hours_consumed)
        
        if self._amp_hours_charged != status.amp_hours_charged:
            self._amp_hours_charged = status.amp_hours_charged
            self.ampHoursChargedChanged.emit(status.amp_hours_charged)
        
        if self._watt_hours_consumed != status.watt_hours_consumed:
            self._watt_hours_consumed = status.watt_hours_consumed
            self.wattHoursConsumedChanged.emit(status.watt_hours_consumed)
        
        if self._watt_hours_charged != status.watt_hours_charged:
            self._watt_hours_charged = status.watt_hours_charged
            self.wattHoursChargedChanged.emit(status.watt_hours_charged)
        
        if self._tachometer != status.tachometer:
            self._tachometer = status.tachometer
            self.tachometerChanged.emit(status.tachometer)
        
        if self._tachometer_abs != status.tachometer_abs:
            self._tachometer_abs = status.tachometer_abs
            self.tachometerAbsChanged.emit(status.tachometer_abs)
        
        if self._fault_code != status.fault_code:
            self._fault_code = status.fault_code
            self.faultCodeChanged.emit(status.fault_code)
    
    # Property getters/setters with signals
    @Property(float, notify=speedChanged)
    def speed(self):
        return self._speed
    
    @speed.setter
    def speed(self, value):
        if self._speed != value:
            self._speed = value
            self.speedChanged.emit(value)
    
    @Property(int, notify=rpmChanged)
    def rpm(self):
        return self._rpm
    
    @rpm.setter
    def rpm(self, value):
        if self._rpm != value:
            self._rpm = value
            self.rpmChanged.emit(value)
    
    @Property(float, notify=voltageChanged)
    def voltage(self):
        return self._voltage
    
    @voltage.setter
    def voltage(self, value):
        if self._voltage != value:
            self._voltage = value
            self.voltageChanged.emit(value)
    
    @Property(float, notify=currentMotorChanged)
    def currentMotor(self):
        return self._current_motor
    
    @currentMotor.setter
    def currentMotor(self, value):
        if self._current_motor != value:
            self._current_motor = value
            self.currentMotorChanged.emit(value)
    
    @Property(float, notify=currentBatteryChanged)
    def currentBattery(self):
        return self._current_battery
    
    @currentBattery.setter
    def currentBattery(self, value):
        if self._current_battery != value:
            self._current_battery = value
            self.currentBatteryChanged.emit(value)
    
    @Property(float, notify=powerChanged)
    def power(self):
        return self._power
    
    @power.setter
    def power(self, value):
        if self._power != value:
            self._power = value
            self.powerChanged.emit(value)
    
    @Property(float, notify=tempMosChanged)
    def tempMos(self):
        return self._temp_mos
    
    @tempMos.setter
    def tempMos(self, value):
        if self._temp_mos != value:
            self._temp_mos = value
            self.tempMosChanged.emit(value)
    
    @Property(float, notify=tempMotorChanged)
    def tempMotor(self):
        return self._temp_motor
    
    @tempMotor.setter
    def tempMotor(self, value):
        if self._temp_motor != value:
            self._temp_motor = value
            self.tempMotorChanged.emit(value)
    
    @Property(float, notify=dutyCycleChanged)
    def dutyCycle(self):
        return self._duty_cycle
    
    @dutyCycle.setter
    def dutyCycle(self, value):
        if self._duty_cycle != value:
            self._duty_cycle = value
            self.dutyCycleChanged.emit(value)
    
    @Property(float, notify=efficiencyChanged)
    def efficiency(self):
        return self._efficiency
    
    @efficiency.setter
    def efficiency(self, value):
        if self._efficiency != value:
            self._efficiency = value
            self.efficiencyChanged.emit(value)
    
    @Property(float, notify=ampHoursConsumedChanged)
    def ampHoursConsumed(self):
        return self._amp_hours_consumed
    
    @ampHoursConsumed.setter
    def ampHoursConsumed(self, value):
        if self._amp_hours_consumed != value:
            self._amp_hours_consumed = value
            self.ampHoursConsumedChanged.emit(value)
    
    @Property(float, notify=ampHoursChargedChanged)
    def ampHoursCharged(self):
        return self._amp_hours_charged
    
    @ampHoursCharged.setter
    def ampHoursCharged(self, value):
        if self._amp_hours_charged != value:
            self._amp_hours_charged = value
            self.ampHoursChargedChanged.emit(value)
    
    @Property(float, notify=wattHoursConsumedChanged)
    def wattHoursConsumed(self):
        return self._watt_hours_consumed
    
    @wattHoursConsumed.setter
    def wattHoursConsumed(self, value):
        if self._watt_hours_consumed != value:
            self._watt_hours_consumed = value
            self.wattHoursConsumedChanged.emit(value)
    
    @Property(float, notify=wattHoursChargedChanged)
    def wattHoursCharged(self):
        return self._watt_hours_charged
    
    @wattHoursCharged.setter
    def wattHoursCharged(self, value):
        if self._watt_hours_charged != value:
            self._watt_hours_charged = value
            self.wattHoursChargedChanged.emit(value)
    
    @Property(int, notify=tachometerChanged)
    def tachometer(self):
        return self._tachometer
    
    @tachometer.setter
    def tachometer(self, value):
        if self._tachometer != value:
            self._tachometer = value
            self.tachometerChanged.emit(value)
    
    @Property(int, notify=tachometerAbsChanged)
    def tachometerAbs(self):
        return self._tachometer_abs
    
    @tachometerAbs.setter
    def tachometerAbs(self, value):
        if self._tachometer_abs != value:
            self._tachometer_abs = value
            self.tachometerAbsChanged.emit(value)
    
    @Property(int, notify=faultCodeChanged)
    def faultCode(self):
        return self._fault_code
    
    @faultCode.setter
    def faultCode(self, value):
        if self._fault_code != value:
            self._fault_code = value
            self.faultCodeChanged.emit(value)
    
    @Slot(int, bytes)
    def on_can_message(self, can_id: int, data: bytes):
        """Handle incoming CAN message"""
        status = self.codec.decode_status_frame(can_id, data)
        if status:
            # Cache this status frame
            self.status_cache[can_id] = status
            
            # Try to merge all available status frames
            frames = [
                self.status_cache.get(VESCCodec.CAN_PACKET_STATUS),
                self.status_cache.get(VESCCodec.CAN_PACKET_STATUS_2),
                self.status_cache.get(VESCCodec.CAN_PACKET_STATUS_3),
                self.status_cache.get(VESCCodec.CAN_PACKET_STATUS_4),
                self.status_cache.get(VESCCodec.CAN_PACKET_STATUS_5),
            ]
            
            merged = self.codec.merge_status_frames(*frames)
            self.update_from_status(merged)


def main():
    parser = argparse.ArgumentParser(description="Go-Kart Telemetry Dashboard")
    parser.add_argument("--virtual", action="store_true", 
                       help="Use virtual CAN mode (for development)")
    parser.add_argument("--interface", default="can0",
                       help="CAN interface name (default: can0)")
    parser.add_argument("--fullscreen", action="store_true",
                       help="Run in fullscreen mode")
    parser.add_argument("--sim-throttle", type=float, default=0.0,
                       help="Initial simulator throttle (0.0-1.0)")
    
    args = parser.parse_args()
    
    # Create Qt application
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Go-Kart Dashboard")
    
    # Create telemetry bridge
    telemetry = TelemetryBridge()
    
    # Setup CAN or virtual mode
    if args.virtual:
        print("Starting in VIRTUAL mode (no hardware required)")
        can_manager = CANManager(interface=args.interface, virtual=True)
        can_manager.connect()
        
        # Create and start simulator
        simulator = VESCSimulator(callback=lambda can_id, data: 
                                  telemetry.on_can_message(can_id, data))
        simulator.set_throttle(args.sim_throttle)
        
        # Start simulator in background thread
        import threading
        sim_thread = threading.Thread(target=simulator.start, daemon=True)
        sim_thread.start()
        
        print("Virtual CAN simulator started")
    else:
        print(f"Connecting to CAN interface: {args.interface}")
        can_manager = CANManager(interface=args.interface, virtual=False)
        if not can_manager.connect():
            print("ERROR: Failed to connect to CAN interface")
            print("Use --virtual flag for development without hardware")
            sys.exit(1)
        
        # Register callback for VESC status frames
        for can_id in [VESCCodec.CAN_PACKET_STATUS,
                      VESCCodec.CAN_PACKET_STATUS_2,
                      VESCCodec.CAN_PACKET_STATUS_3,
                      VESCCodec.CAN_PACKET_STATUS_4,
                      VESCCodec.CAN_PACKET_STATUS_5]:
            can_manager.register_callback(can_id, 
                lambda data, cid=can_id: telemetry.on_can_message(cid, data))
        
        can_manager.start_receive_thread()
        print("CAN interface connected and listening")
    
    # Create QML engine
    engine = QQmlApplicationEngine()
    
    # Add project root to QML import path so "import ui 1.0" can find ui/qmldir
    engine.addImportPath(str(project_root))
    
    # Register TelemetryBridge as QML type
    qmlRegisterType(TelemetryBridge, "Telemetry", 1, 0, "TelemetryBridge")
    
    # Expose telemetry bridge to QML
    engine.rootContext().setContextProperty("telemetry", telemetry)
    
    # Load main QML file
    qml_file = project_root / "ui" / "main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))
    
    if not engine.rootObjects():
        print("ERROR: Failed to load QML")
        sys.exit(1)
    
    # Set fullscreen if requested
    if args.fullscreen:
        window = engine.rootObjects()[0]
        if hasattr(window, 'fullscreen'):
            window.fullscreen = True
    
    print("Dashboard started successfully")
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
