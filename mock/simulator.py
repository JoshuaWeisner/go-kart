"""
Virtual CAN Simulator - Generates fake VESC CAN packets for development
Allows testing the dashboard without physical hardware.
"""

import time
import struct
import math
import random
from typing import Callable, Optional


class VESCSimulator:
    """
    Simulates VESC motor controller behavior by generating realistic CAN packets.
    Models a 80100 Outrunner (130KV) motor with FSESC75200 controller.
    """
    
    # VESC CAN IDs
    CAN_PACKET_STATUS = 0x000002
    CAN_PACKET_STATUS_2 = 0x000003
    CAN_PACKET_STATUS_3 = 0x000004
    CAN_PACKET_STATUS_4 = 0x000005
    CAN_PACKET_STATUS_5 = 0x000006
    
    def __init__(self, callback: Optional[Callable[[int, bytes], None]] = None):
        """
        Initialize simulator
        
        Args:
            callback: Function to call when generating packets (can_id, data)
        """
        self.callback = callback
        self.running = False
        self.sim_time = 0.0
        
        # Simulation state
        self.throttle = 0.0  # 0.0 to 1.0
        self.brake = 0.0  # 0.0 to 1.0
        self.rpm = 0
        self.voltage = 48.0  # Nominal battery voltage (adjust for your pack)
        self.temp_mos = 25.0
        self.temp_motor = 25.0
        
    def set_throttle(self, value: float):
        """Set throttle position (0.0 to 1.0)"""
        self.throttle = max(0.0, min(1.0, value))
    
    def set_brake(self, value: float):
        """Set brake position (0.0 to 1.0)"""
        self.brake = max(0.0, min(1.0, value))
    
    def start(self, update_rate: float = 50.0):
        """
        Start simulation loop
        
        Args:
            update_rate: Update frequency in Hz (default 50Hz for VESC)
        """
        self.running = True
        self.sim_time = 0.0
        
        period = 1.0 / update_rate
        last_update = time.time()
        
        while self.running:
            current_time = time.time()
            dt = current_time - last_update
            self.sim_time += dt
            
            if dt >= period:
                self._update_physics(dt)
                self._generate_packets()
                last_update = current_time
            else:
                time.sleep(period - dt)
    
    def stop(self):
        """Stop simulation"""
        self.running = False
    
    def _update_physics(self, dt: float):
        """Update simulated physics state"""
        # Simple motor model for 80100 130KV motor
        # KV rating: 130 RPM per volt
        max_rpm = self.voltage * 130  # Theoretical max RPM
        
        # Target RPM based on throttle (with some inertia)
        target_rpm = max_rpm * self.throttle * (1.0 - self.brake)
        
        # Smooth RPM change (simulate motor inertia)
        rpm_diff = target_rpm - self.rpm
        self.rpm += rpm_diff * dt * 5.0  # 5.0 is inertia factor
        
        # Clamp RPM
        self.rpm = max(0, min(self.rpm, max_rpm))
        
        # Calculate currents based on RPM and load
        # Simplified model: current proportional to power demand
        if self.rpm > 0:
            # Motor current (simplified: higher RPM = more current)
            motor_current = (self.rpm / max_rpm) * 50.0 * (1.0 + random.uniform(-0.1, 0.1))
            # Battery current (accounting for efficiency losses)
            battery_current = motor_current * 1.15  # ~85% efficiency
        else:
            motor_current = 0.0
            battery_current = 0.0
        
        # Temperature simulation (heating/cooling)
        # MOSFET temp based on current
        target_mos_temp = 25.0 + abs(battery_current) * 2.0
        self.temp_mos += (target_mos_temp - self.temp_mos) * dt * 0.5
        
        # Motor temp based on RPM and current
        target_motor_temp = 25.0 + (self.rpm / 1000.0) * 5.0 + abs(motor_current) * 1.5
        self.temp_motor += (target_motor_temp - self.temp_motor) * dt * 0.3
        
        # Voltage sag under load
        voltage_sag = battery_current * 0.1  # 0.1V per amp
        self.voltage = 48.0 - voltage_sag + random.uniform(-0.2, 0.2)
    
    def _generate_packets(self):
        """Generate and emit VESC status packets"""
        if not self.callback:
            return
        
        # Calculate derived values
        duty_cycle = self.throttle * (1.0 - self.brake)
        motor_current = (self.rpm / (48.0 * 130)) * 50.0 if self.rpm > 0 else 0.0
        battery_current = motor_current * 1.15
        
        # Status Frame 1: Temp, Currents, Duty
        temp_mos_raw = int(self.temp_mos * 10)
        current_motor_raw = int(motor_current * 10)
        current_battery_raw = int(battery_current * 10)
        duty_raw = int(duty_cycle * 1000)
        
        data1 = struct.pack("<hhhBx", temp_mos_raw, current_motor_raw, current_battery_raw, duty_raw)
        self.callback(self.CAN_PACKET_STATUS, data1)
        
        # Status Frame 2: RPM, Voltage
        voltage_raw = int(self.voltage * 10)
        data2 = struct.pack("<iHxx", int(self.rpm), voltage_raw)
        self.callback(self.CAN_PACKET_STATUS_2, data2)
        
        # Status Frame 3: Ah consumed/charged (simplified - just increment)
        # In real scenario, these would be accumulated over time
        ah_consumed = self.sim_time * battery_current / 3600.0 if battery_current > 0 else 0.0
        ah_charged = 0.0  # Not charging in this sim
        ah_consumed_raw = int(ah_consumed * 10000)
        ah_charged_raw = int(ah_charged * 10000)
        data3 = struct.pack("<ii", ah_consumed_raw, ah_charged_raw)
        self.callback(self.CAN_PACKET_STATUS_3, data3)
        
        # Status Frame 4: Wh consumed/charged
        wh_consumed = ah_consumed * self.voltage
        wh_charged = 0.0
        wh_consumed_raw = int(wh_consumed * 10000)
        wh_charged_raw = int(wh_charged * 10000)
        data4 = struct.pack("<ii", wh_consumed_raw, wh_charged_raw)
        self.callback(self.CAN_PACKET_STATUS_4, data4)
        
        # Status Frame 5: Tachometer
        # Tachometer = RPM * pole_pairs / 60 (simplified)
        pole_pairs = 7  # Typical for 80100 motor
        tachometer = int((self.rpm * pole_pairs) / 60.0 * self.sim_time)
        tachometer_abs = abs(tachometer)
        data5 = struct.pack("<iI", tachometer, tachometer_abs)
        self.callback(self.CAN_PACKET_STATUS_5, data5)
    
    def generate_test_sequence(self, duration: float = 10.0):
        """
        Generate a test sequence simulating a drive cycle
        
        Args:
            duration: Duration of test sequence in seconds
        """
        start_time = time.time()
        while time.time() - start_time < duration:
            # Simulate acceleration
            t = (time.time() - start_time) / duration
            if t < 0.3:
                # Accelerate
                self.set_throttle(t / 0.3)
            elif t < 0.6:
                # Cruise
                self.set_throttle(0.7)
            elif t < 0.8:
                # Decelerate
                self.set_throttle(0.7 * (1.0 - (t - 0.6) / 0.2))
            else:
                # Brake
                self.set_brake((t - 0.8) / 0.2)
            
            self._update_physics(0.02)  # 50Hz update
            self._generate_packets()
            time.sleep(0.02)
