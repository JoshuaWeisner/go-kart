"""
VESC Codec - Decodes VESC Status Frames from CAN bus
Implements bit-shifting and parsing for VESC Status packets according to
VESC CAN protocol specification.
"""

import struct
from typing import Dict, Any, Optional
from dataclasses import dataclass


@dataclass
class VESCStatus:
    """Decoded VESC Status data structure"""
    # Motor controller state
    temp_mos: float = 0.0  # MOSFET temperature (°C)
    temp_motor: float = 0.0  # Motor temperature (°C)
    current_motor: float = 0.0  # Motor current (A)
    current_battery: float = 0.0  # Battery current (A)
    duty_cycle: float = 0.0  # Duty cycle (0.0-1.0)
    rpm: int = 0  # Motor RPM
    voltage: float = 0.0  # Battery voltage (V)
    amp_hours_consumed: float = 0.0  # Ah consumed
    amp_hours_charged: float = 0.0  # Ah charged
    watt_hours_consumed: float = 0.0  # Wh consumed
    watt_hours_charged: float = 0.0  # Wh charged
    tachometer: int = 0  # Motor tachometer value
    tachometer_abs: int = 0  # Absolute tachometer value
    fault_code: int = 0  # Fault code (0 = no fault)
    
    # Calculated/derived values
    power: float = 0.0  # Instantaneous power (W)
    efficiency: float = 0.0  # Efficiency estimate (%)


class VESCCodec:
    """
    Encoder/Decoder for VESC CAN protocol messages.
    Handles VESC Status Frame (ID 0x000002) and other VESC CAN messages.
    """
    
    # VESC CAN IDs (from VESC firmware)
    CAN_PACKET_STATUS = 0x000002
    CAN_PACKET_STATUS_2 = 0x000003
    CAN_PACKET_STATUS_3 = 0x000004
    CAN_PACKET_STATUS_4 = 0x000005
    CAN_PACKET_STATUS_5 = 0x000006
    
    def __init__(self):
        self.status_cache: Dict[int, bytes] = {}  # Cache for multi-frame status packets
    
    def decode_status_frame(self, can_id: int, data: bytes) -> Optional[VESCStatus]:
        """
        Decode VESC Status Frame from CAN message
        
        Args:
            can_id: CAN message ID
            data: 8-byte CAN payload
            
        Returns:
            VESCStatus object if decoding successful, None otherwise
        """
        if can_id == self.CAN_PACKET_STATUS:
            return self._decode_status_1(data)
        elif can_id == self.CAN_PACKET_STATUS_2:
            return self._decode_status_2(data)
        elif can_id == self.CAN_PACKET_STATUS_3:
            return self._decode_status_3(data)
        elif can_id == self.CAN_PACKET_STATUS_4:
            return self._decode_status_4(data)
        elif can_id == self.CAN_PACKET_STATUS_5:
            return self._decode_status_5(data)
        
        return None
    
    def _decode_status_1(self, data: bytes) -> VESCStatus:
        """
        Decode Status Frame 1 (Primary telemetry)
        Byte layout (little-endian):
        0-1:   temp_mos (int16, 0.1°C units)
        2-3:   current_motor (int16, 0.1A units)
        4-5:   current_battery (int16, 0.1A units)
        6:     duty_cycle (int8, 0.1% units, 0-1000)
        7:     reserved
        """
        if len(data) < 8:
            return VESCStatus()
        
        temp_mos_raw, current_motor_raw, current_battery_raw, duty_raw = struct.unpack("<hhhBx", data)
        
        status = VESCStatus()
        status.temp_mos = temp_mos_raw * 0.1
        status.current_motor = current_motor_raw * 0.1
        status.current_battery = current_battery_raw * 0.1
        status.duty_cycle = duty_raw * 0.001  # Convert 0-1000 to 0.0-1.0
        
        return status
    
    def _decode_status_2(self, data: bytes) -> VESCStatus:
        """
        Decode Status Frame 2 (RPM and voltage)
        Byte layout:
        0-3:   rpm (int32, signed)
        4-5:   voltage (uint16, 0.1V units)
        6-7:   reserved
        """
        if len(data) < 8:
            return VESCStatus()
        
        rpm, voltage_raw = struct.unpack("<iHxx", data)
        
        status = VESCStatus()
        status.rpm = rpm
        status.voltage = voltage_raw * 0.1
        
        return status
    
    def _decode_status_3(self, data: bytes) -> VESCStatus:
        """
        Decode Status Frame 3 (Energy consumption)
        Byte layout:
        0-3:   amp_hours_consumed (int32, 0.0001Ah units)
        4-7:   amp_hours_charged (int32, 0.0001Ah units)
        """
        if len(data) < 8:
            return VESCStatus()
        
        ah_consumed_raw, ah_charged_raw = struct.unpack("<ii", data)
        
        status = VESCStatus()
        status.amp_hours_consumed = ah_consumed_raw * 0.0001
        status.amp_hours_charged = ah_charged_raw * 0.0001
        
        return status
    
    def _decode_status_4(self, data: bytes) -> VESCStatus:
        """
        Decode Status Frame 4 (Energy and tachometer)
        Byte layout:
        0-3:   watt_hours_consumed (int32, 0.0001Wh units)
        4-7:   watt_hours_charged (int32, 0.0001Wh units)
        """
        if len(data) < 8:
            return VESCStatus()
        
        wh_consumed_raw, wh_charged_raw = struct.unpack("<ii", data)
        
        status = VESCStatus()
        status.watt_hours_consumed = wh_consumed_raw * 0.0001
        status.watt_hours_charged = wh_charged_raw * 0.0001
        
        return status
    
    def _decode_status_5(self, data: bytes) -> VESCStatus:
        """
        Decode Status Frame 5 (Tachometer and fault codes)
        Byte layout:
        0-3:   tachometer (int32, signed)
        4-7:   tachometer_abs (int32, unsigned)
        """
        if len(data) < 8:
            return VESCStatus()
        
        tachometer, tachometer_abs = struct.unpack("<iI", data)
        
        status = VESCStatus()
        status.tachometer = tachometer
        status.tachometer_abs = tachometer_abs
        
        return status
    
    def merge_status_frames(self, *status_frames: VESCStatus) -> VESCStatus:
        """
        Merge multiple status frames into a single complete status object.
        VESC sends status data across multiple CAN frames, so we need to combine them.
        
        Args:
            *status_frames: Variable number of VESCStatus objects to merge
            
        Returns:
            Merged VESCStatus with all available data
        """
        merged = VESCStatus()
        
        for frame in status_frames:
            if frame is None:
                continue
            
            # Merge non-zero/non-default values
            if frame.temp_mos != 0.0:
                merged.temp_mos = frame.temp_mos
            if frame.temp_motor != 0.0:
                merged.temp_motor = frame.temp_motor
            if frame.current_motor != 0.0:
                merged.current_motor = frame.current_motor
            if frame.current_battery != 0.0:
                merged.current_battery = frame.current_battery
            if frame.duty_cycle != 0.0:
                merged.duty_cycle = frame.duty_cycle
            if frame.rpm != 0:
                merged.rpm = frame.rpm
            if frame.voltage != 0.0:
                merged.voltage = frame.voltage
            if frame.amp_hours_consumed != 0.0:
                merged.amp_hours_consumed = frame.amp_hours_consumed
            if frame.amp_hours_charged != 0.0:
                merged.amp_hours_charged = frame.amp_hours_charged
            if frame.watt_hours_consumed != 0.0:
                merged.watt_hours_consumed = frame.watt_hours_consumed
            if frame.watt_hours_charged != 0.0:
                merged.watt_hours_charged = frame.watt_hours_charged
            if frame.tachometer != 0:
                merged.tachometer = frame.tachometer
            if frame.tachometer_abs != 0:
                merged.tachometer_abs = frame.tachometer_abs
            if frame.fault_code != 0:
                merged.fault_code = frame.fault_code
        
        # Calculate derived values
        merged.power = merged.voltage * merged.current_battery
        if merged.power > 0:
            merged.efficiency = (merged.current_motor * merged.voltage) / merged.power * 100.0
        
        return merged
    
    def status_to_dict(self, status: VESCStatus) -> Dict[str, Any]:
        """
        Convert VESCStatus to dictionary for easy serialization/transmission
        
        Args:
            status: VESCStatus object
            
        Returns:
            Dictionary representation
        """
        return {
            "temp_mos": status.temp_mos,
            "temp_motor": status.temp_motor,
            "current_motor": status.current_motor,
            "current_battery": status.current_battery,
            "duty_cycle": status.duty_cycle,
            "rpm": status.rpm,
            "voltage": status.voltage,
            "amp_hours_consumed": status.amp_hours_consumed,
            "amp_hours_charged": status.amp_hours_charged,
            "watt_hours_consumed": status.watt_hours_consumed,
            "watt_hours_charged": status.watt_hours_charged,
            "tachometer": status.tachometer,
            "tachometer_abs": status.tachometer_abs,
            "fault_code": status.fault_code,
            "power": status.power,
            "efficiency": status.efficiency,
        }
