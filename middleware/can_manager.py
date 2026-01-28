"""
CAN Manager - Hardware Abstraction Layer (HAL)
Optimized for Raspberry Pi + CAN SPI Click (10MHz) 
Targeting FSESC75200 (VESC 500k Bitrate)
"""

import can
import struct
import threading
from typing import Optional, Callable, Dict
from PySide6.QtCore import QObject, Signal

class CANManager(QObject):
    """
    HAL that handles the bridge between the physical CAN-SPI Click
    and the Qt/QML Dashboard.
    """
    # Signals for Team C (Dashboard)
    rpm_changed = Signal(int)
    voltage_changed = Signal(float)
    current_changed = Signal(float)
    torque_changed = Signal(float)
    duty_changed = Signal(float)

    def __init__(self, interface: str = "can0", virtual: bool = False):
        super().__init__()
        self.interface = interface
        self.virtual = virtual
        self.bus: Optional[can.BusABC] = None
        self.running = False
        self.listener_thread: Optional[threading.Thread] = None

        # 130KV Motor Constant
        self.KT = 0.0735 

    def connect(self) -> bool:
        """Connects to the bus (SocketCAN on Pi, Virtual on Mac)"""
        try:
            if self.virtual:
                self.bus = can.interface.Bus(channel='test', bustype='virtual')
                print("[CAN] Connected to Virtual Interface")
            else:
                # Based on setup: 500000 bitrate, 10MHz handled by OS overlay
                self.bus = can.interface.Bus(channel=self.interface, bustype='socketcan')
                print(f"[CAN] Connected to {self.interface} at 500k")
            
            self.running = True
            return True
        except Exception as e:
            print(f"[CAN] Connection Error: {e}")
            return False

    def start_listening(self):
        """Starts the background thread to process VESC telemetry"""
        if not self.bus:
            return
        self.listener_thread = threading.Thread(target=self._listen_loop, daemon=True)
        self.listener_thread.start()

    def _listen_loop(self):
        """Processes incoming VESC Extended 29-bit CAN frames"""
        while self.running:
            msg = self.bus.recv(timeout=1.0)
            if msg is None:
                continue

            # VESC IDs use Extended format. 
            # We shift 8 bits to extract the Packet Type (Status 1, 5, etc.)
            packet_id = msg.arbitration_id >> 8

            # STATUS 1: ERPM, Current, Duty Cycle
            if packet_id == 0x09:
                erpm, current_x10, duty_x1000 = struct.unpack(">ihh", msg.data[:8])
                rpm = erpm / 7 # 7 pole pairs for 80100
                current = current_x10 / 10.0
                torque = current * self.KT

                self.rpm_changed.emit(int(rpm))
                self.current_changed.emit(current)
                self.torque_changed.emit(round(torque, 2))
                self.duty_changed.emit(duty_x1000 / 10.0)

            # STATUS 5: Voltage, Tachometer
            elif packet_id == 0x1B:
                # Voltage is located at offset 4 (2 bytes unsigned short)
                voltage_x10 = struct.unpack_from(">H", msg.data, 4)[0]
                self.voltage_changed.emit(voltage_x10 / 10.0)

    def inject_mock_data(self, can_id: int, data: bytes):
        """Helper for Team B to simulate packets on Mac"""
        if self.virtual and self.bus:
            msg = can.Message(arbitration_id=can_id, data=data, is_extended_id=True)
            self.bus.send(msg)