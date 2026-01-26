"""
Middleware package - CAN bus communication and VESC protocol decoding
"""

from .can_manager import CANManager, CANInterface
from .vesc_codec import VESCCodec, VESCStatus

__all__ = ['CANManager', 'CANInterface', 'VESCCodec', 'VESCStatus']
