"""
CAN Manager - Hardware Abstraction Layer (HAL)
Provides a unified interface for CAN bus communication, supporting both
real hardware (SocketCAN on Linux/Raspberry Pi) and virtual CAN for development.
"""

import socket
import struct
import threading
import time
from typing import Optional, Callable, Dict, Any
from enum import Enum


class CANInterface(Enum):
    """Supported CAN interface types"""
    SOCKETCAN = "socketcan"
    VIRTUAL = "virtual"


class CANManager:
    """
    Hardware Abstraction Layer for CAN bus communication.
    Abstracts SocketCAN (Linux) and provides virtual mode for cross-platform development.
    """
    
    def __init__(self, interface: str = "can0", virtual: bool = False):
        """
        Initialize CAN Manager
        
        Args:
            interface: CAN interface name (e.g., "can0" for SocketCAN)
            virtual: If True, use virtual CAN mode (for development/testing)
        """
        self.interface = interface
        self.virtual = virtual
        self.socket: Optional[socket.socket] = None
        self.running = False
        self.receive_thread: Optional[threading.Thread] = None
        self.callbacks: Dict[int, Callable] = {}  # CAN ID -> callback mapping
        self.lock = threading.Lock()
        
    def connect(self) -> bool:
        """
        Connect to CAN bus
        
        Returns:
            True if connection successful, False otherwise
        """
        if self.virtual:
            # Virtual mode - no actual hardware connection needed
            self.running = True
            return True
        
        try:
            # Create SocketCAN socket
            self.socket = socket.socket(socket.AF_CAN, socket.SOCK_RAW, socket.CAN_RAW)
            self.socket.bind((self.interface,))
            self.running = True
            return True
        except OSError as e:
            print(f"Failed to connect to CAN interface {self.interface}: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from CAN bus"""
        self.running = False
        if self.socket:
            try:
                self.socket.close()
            except:
                pass
            self.socket = None
        
        if self.receive_thread and self.receive_thread.is_alive():
            self.receive_thread.join(timeout=1.0)
    
    def register_callback(self, can_id: int, callback: Callable[[bytes], None]):
        """
        Register a callback for a specific CAN ID
        
        Args:
            can_id: CAN message ID to listen for
            callback: Function to call when message received (takes bytes as argument)
        """
        with self.lock:
            self.callbacks[can_id] = callback
    
    def unregister_callback(self, can_id: int):
        """Unregister callback for a CAN ID"""
        with self.lock:
            self.callbacks.pop(can_id, None)
    
    def send(self, can_id: int, data: bytes) -> bool:
        """
        Send CAN message
        
        Args:
            can_id: CAN message ID
            data: Message payload (max 8 bytes)
            
        Returns:
            True if sent successfully, False otherwise
        """
        if not self.running:
            return False
        
        if self.virtual:
            # In virtual mode, messages are just logged
            print(f"[VIRTUAL CAN] TX: ID=0x{can_id:03X}, Data={data.hex()}")
            return True
        
        if not self.socket:
            return False
        
        try:
            # SocketCAN format: (can_id, flags, data)
            can_pkt = struct.pack("=IB3x8s", can_id, 0, data[:8])
            self.socket.send(can_pkt)
            return True
        except Exception as e:
            print(f"Failed to send CAN message: {e}")
            return False
    
    def _receive_loop(self):
        """Internal receive loop (runs in separate thread)"""
        if self.virtual:
            # Virtual mode doesn't need a receive loop
            return
        
        while self.running:
            try:
                if not self.socket:
                    break
                
                # Receive CAN frame (up to 16 bytes: can_id + flags + 8 bytes data)
                can_pkt = self.socket.recv(16)
                if len(can_pkt) < 8:
                    continue
                
                # Unpack: can_id (4 bytes), flags (1 byte), padding (3 bytes), data (8 bytes)
                can_id, flags = struct.unpack("=IB3x", can_pkt[:8])
                data = can_pkt[8:8+8]
                
                # Call registered callback
                with self.lock:
                    callback = self.callbacks.get(can_id)
                    if callback:
                        try:
                            callback(data)
                        except Exception as e:
                            print(f"Error in CAN callback for ID 0x{can_id:03X}: {e}")
                            
            except socket.timeout:
                continue
            except Exception as e:
                if self.running:
                    print(f"Error receiving CAN message: {e}")
                break
    
    def start_receive_thread(self):
        """Start background thread for receiving CAN messages"""
        if self.virtual:
            return
        
        if self.receive_thread and self.receive_thread.is_alive():
            return
        
        self.receive_thread = threading.Thread(target=self._receive_loop, daemon=True)
        self.receive_thread.start()
    
    def inject_virtual_message(self, can_id: int, data: bytes):
        """
        Inject a virtual CAN message (for testing/virtual mode)
        
        Args:
            can_id: CAN message ID
            data: Message payload
        """
        if not self.virtual:
            return
        
        with self.lock:
            callback = self.callbacks.get(can_id)
            if callback:
                try:
                    callback(data)
                except Exception as e:
                    print(f"Error in virtual CAN callback for ID 0x{can_id:03X}: {e}")
