# Go-Kart Telemetry Dashboard

Real-time telemetry display for our electric kart project. Interfaces with Flipsky FSESC75200 Pro V2.0 VESC controller via CAN bus, running on Raspberry Pi 4/5 with Qt/QML UI.

**Requirements:** Python 3.8+, Qt 6.5+

## Key Features

- <20ms end-to-end latency at 50Hz update rate
- Cross-platform development with virtual CAN mode
- Synchronized gauge animations

## Hardware Stack
- Motor Controller: Flipsky FSESC75200 Pro V2.0 (VESC-based)
- Motor: 80100 Outrunner (130KV)
- Host: Raspberry Pi 4 or 5
- CAN Interface: CAN-SPI Click (MCP2515)
- Display: HDMI/DSI panel

## System Architecture
Hardware-agnostic design allows development on macOS/Windows/Linux without physical hardware using virtual CAN mode.

- Middleware: Python SocketCAN wrapper that decodes VESC status frames
- UI Layer: Qt Quick (QML) for hardware-accelerated graphics
- Data flow: Decoupled telemetry stream

## Project Structure
```
/go-kart
├── /middleware        # Team B: CAN parsing & Signal/Slot management
│   ├── can_manager.py # Hardware Abstraction Layer (HAL)
│   └── vesc_codec.py  # Bit-shifting for VESC Status packets
├── /ui                # Team C: HMI & Graphics
│   ├── main.qml       # Entry point for the UI
│   ├── Dashboard.qml  # Main Driving View
│   └── Diagnostics.qml # Deep-dive telemetry view
├── /mock              # Virtualization & Testing
│   └── simulator.py   # Generates fake VESC CAN packets
├── .cursorrules       # Cursor AI project-specific instructions
├── requirements.txt   # Dependency list
└── main.py            # Main application entry point
```

## Quick Start

### Prerequisites
- Python 3.8+
- Qt 6.5+ (PySide6)
- On Pi: CAN interface configured (see Hardware Setup)

### Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Run in virtual mode (development/testing)
python main.py --virtual

# Run with hardware
python main.py --interface can0
```

### Command Line Options

```bash
python main.py [OPTIONS]

Options:
  --virtual              Use virtual CAN mode (no hardware required)
  --interface INTERFACE  CAN interface name (default: can0)
  --fullscreen          Run in fullscreen mode
  --sim-throttle FLOAT  Initial simulator throttle 0.0-1.0 (virtual mode only)
```

### Testing Gauges

```bash
python test_gauges.py
```

Cycles all telemetry through full range over 10 seconds (speed 0-80 km/h, RPM 0-6000, etc.)

### Development Mode

```bash
# Virtual CAN with simulated throttle
python main.py --virtual --sim-throttle 0.5
```

### Production Mode

```bash
# On Pi with CAN configured
python main.py --interface can0 --fullscreen
```

## Hardware Setup (Raspberry Pi)

### CAN Communication Architecture

SocketCAN-based architecture for low-latency telemetry:

```
VESC FSESC75200 → CAN Bus (500kbps) → CAN-SPI Click (MCP2515) → SPI → Raspberry Pi
                                                                         ↓
                                                                    SocketCAN
                                                                         ↓
                                                                   Python App
                                                                         ↓
                                                                    Qt/QML UI
```

**Data Flow:**
1. VESC broadcasts 5 CAN frames at 50Hz
2. MCP2515 receives and buffers messages
3. SPI interrupt notifies Pi
4. Kernel driver presents via SocketCAN (`can0`)
5. Python middleware decodes VESC protocol
6. Qt signals update QML gauges (<20ms latency)

### 1. Physical Wiring

#### CAN Bus Connections
```
VESC FSESC75200:
├─ CAN_H ──────┐
└─ CAN_L ──────┤ 120Ω termination resistor at each end
               │
CAN-SPI Click: │
├─ CAN_H ──────┘
└─ CAN_L ──────┘
```

#### Raspberry Pi GPIO Connections (CAN-SPI Click)
```
CAN-SPI Click         Raspberry Pi
─────────────────────────────────────
CS    (Chip Select) → GPIO 8  (SPI0_CE0)
SCK   (Clock)       → GPIO 11 (SPI0_SCLK)
MISO  (Data Out)    → GPIO 9  (SPI0_MISO)
MOSI  (Data In)     → GPIO 10 (SPI0_MOSI)
INT   (Interrupt)   → GPIO 25 (or any free GPIO)
3.3V                → 3.3V Power
GND                 → Ground
```

**Note:** Use 120Ω termination resistor at each end of CAN bus.

### 2. Raspberry Pi Configuration

#### Enable SPI Interface
```bash
# Edit boot config
sudo nano /boot/config.txt  # or /boot/firmware/config.txt on newer Pi OS

# Add this line (adjust interrupt pin if using different GPIO):
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25,spimaxfrequency=2000000

# Reboot to apply
sudo reboot
```

#### Configure CAN Interface (Manual Setup)
```bash
# Load CAN kernel modules
sudo modprobe can
sudo modprobe can-raw
sudo modprobe can-bcm

# Bring up CAN interface with 500kbps bitrate
sudo ip link set can0 type can bitrate 500000 restart-ms 100
sudo ip link set can0 up

# Verify interface is active
ip -details link show can0

# Expected output:
# can0: <NOARP,UP,LOWER_UP,ECHO> mtu 16 qdisc pfifo_fast state UP mode DEFAULT
#     can state ERROR-ACTIVE (berr-counter tx 0 rx 0) restart-ms 100
#     bitrate 500000 sample-point 0.875
```

#### Automatic Startup Configuration
Create a systemd service for persistent configuration:

```bash
# Create service file
sudo nano /etc/systemd/system/can-setup.service
```

Add the following content:
```ini
[Unit]
Description=CAN Bus Interface Setup
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ip link set can0 type can bitrate 500000 restart-ms 100
ExecStart=/sbin/ip link set can0 up
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enable the service:
```bash
sudo systemctl enable can-setup.service
sudo systemctl start can-setup.service
```

### 3. VESC Configuration

Using VESC Tool:

#### CAN Bus Settings
1. Navigate to **App Settings → General → CAN Status Message Rate**
2. Set **CAN Status Message Rate** to **50 Hz** (recommended)
3. Set **CAN Baud Rate** to **500k** (500,000 bps)
4. Set **Controller ID** to appropriate value (affects CAN frame IDs)

#### CAN Status Frames
VESC broadcasts 5 status frames per cycle:
- `0x000002` - Temperature, current, duty cycle
- `0x000003` - RPM and voltage
- `0x000004` - Amp-hours (consumed/charged)
- `0x000005` - Watt-hours (consumed/charged)
- `0x000006` - Tachometer values

### 4. Display Setup

For outdoor visibility:

```bash
# Edit boot config
sudo nano /boot/config.txt

# Add display settings
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=82  # 1920x1080 60Hz
hdmi_drive=2  # Full RGB range

# Disable screen blanking
sudo nano /etc/xdg/lxsession/LXDE-pi/autostart
# Add: @xset s off
#      @xset -dpms
#      @xset s noblank
```

### 5. Performance Optimization

#### Increase Socket Buffer Size
```bash
# Add to /etc/sysctl.conf
sudo nano /etc/sysctl.conf

# Add these lines:
net.core.rmem_max=8388608
net.core.wmem_max=8388608
net.core.rmem_default=262144
net.core.wmem_default=262144

# Apply changes
sudo sysctl -p
```

#### Set CAN RX Queue Length
```bash
sudo ip link set can0 txqueuelen 1000
```

### 6. Verification and Testing

#### Monitor CAN Traffic
```bash
# Install can-utils if not present
sudo apt-get install can-utils

# Monitor all CAN messages
candump can0

# You should see VESC status frames:
# can0  000002   [8]  64 00 F4 01 2C 00 1E 00
# can0  000003   [8]  70 17 00 00 E8 01 00 00
# ...

# Send test message (for debugging)
cansend can0 000002#6400F4012C001E00
```

#### Check Interface Statistics
```bash
# View detailed interface stats
ip -details -statistics link show can0

# Monitor error counters
watch -n 1 'ip -s link show can0'
```

### 7. Auto-Start Dashboard on Boot

Create a systemd service to run the dashboard automatically:

```bash
sudo nano /etc/systemd/system/gokart-dashboard.service
```

Add:
```ini
[Unit]
Description=Go-Kart Telemetry Dashboard
After=can-setup.service
Wants=can-setup.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/go-kart
ExecStart=/usr/bin/python3 /home/pi/go-kart/main.py --interface can0 --fullscreen
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=graphical.target
```

Enable and start:
```bash
sudo systemctl enable gokart-dashboard.service
sudo systemctl start gokart-dashboard.service

# Check status
sudo systemctl status gokart-dashboard.service
```

## UI Design

### Dashboard Layout

Main driving view layout:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│    ⚙️ SPEED         ⚙️ RPM                          │
│    (350px)          (350px)                         │
│                                                     │
│  ⚡ VOLTAGE  📊 EFFICIENCY  🔌 CURRENT               │
│   (200px)      (Card)       (200px)                 │
│                                                     │
│  🌡️ MOSFET TEMPERATURE ━━━━━━━ 45°C  [DIAG]         │
└─────────────────────────────────────────────────────┘
```

### Circular Gauge Design

**Features:**
- 270° arc with bottom gap
- Needle synchronized with colored sweep arc
- Tick marks aligned at 31% opacity
- Color-coded: Cyan (#0099AA) normal, Red (#CC1133) danger
- 400ms cubic easing animations
- Glassmorphism with 10% white background
- Hardware-accelerated rendering

**Specifications:**
- Primary gauges: 350×350px (Speed, RPM)
- Secondary gauges: 200×200px (Voltage, Current)
- Needle width: 2.5% of diameter
- Arc thickness: 5% of diameter
- Update rate: 60 FPS

### Color Palette

| Element | Color | Usage |
|---------|-------|-------|
| Background | `#0A0A0B` | Deep automotive black |
| Primary Accent | `#0099AA` | Muted cyan (needles, normal state) |
| Danger | `#CC1133` | Deep red (redline, critical alerts) |
| Warning | `#CC8800` | Amber (caution zones) |
| Success | `#00AA55` | Deep green (efficiency indicator) |
| Text Primary | `#FFFFFF` | Full white (values) |
| Text Secondary | `#B0B0B0` | 70% white (labels) |
| Glass Surface | `#15FFFFFF` | 8% white (glassmorphism) |
| Tick Marks | `#50FFFFFF` | 31% white (gauge markers) |

Colors tested for >4.5:1 contrast ratio in sunlight.

### Typography

- **Value Display:** Monaco (monospace) for precise alignment
- **Labels:** Helvetica for clean, modern look
- **Font Sizes:** 
  - Primary values: 16% of gauge size
  - Units: 8% of gauge size
  - Labels: 9% of gauge size with 2px letter spacing

### Animations

Cubic Bézier easing for smooth motion:

```qml
Behavior on value {
    NumberAnimation {
        duration: 400ms
        easing.type: Easing.OutCubic  // Deceleration curve
    }
}
```

Reduces eye strain during rapid changes while maintaining readability.

## Telemetry Data

### Primary Metrics (Dashboard View)
- **Speed** (km/h) - Calculated from RPM and wheel diameter
- **RPM** - Motor revolutions per minute with redline indicator at 5000
- **Power** (W) - Instantaneous power consumption (derived from V×I)
- **Voltage** (V) - Battery pack voltage (48-54V typical range)
- **Current** (A) - Motor and battery current (0-200A range)
- **Temperature** (°C) - MOSFET temperature with color-coded warnings
  - Normal: <60°C (cyan)
  - Warning: 60-80°C (amber)
  - Critical: >80°C (red)
- **Duty Cycle** (%) - Throttle position (0-100%)
- **Efficiency** (%) - Real-time drive efficiency calculation

### Extended Metrics (Diagnostics View)
- **Amp-Hours:** Consumed/charged energy tracking
- **Watt-Hours:** Total energy consumption
- **Tachometer:** Cumulative motor rotations
- **Fault Codes:** VESC error reporting
- **Temperature Details:** Motor and MOSFET temps
- **Current Breakdown:** Separate motor and battery current readings

### Calculated Values

The system derives additional metrics:

```python
# Speed calculation from RPM
speed_ms = (rpm / gear_ratio) * wheel_circumference / 60.0
speed_kmh = speed_ms * 3.6

# Instantaneous power
power_watts = voltage * current_battery

# Efficiency estimate
efficiency_pct = (current_motor * voltage) / power * 100
```

## Testing

### Virtual Mode
Simulator generates realistic motor behavior (throttle/brake, temperature, voltage sag, current).

### Unit Testing
```bash
pytest tests/  # When implemented
```

## Development

### Architecture

Layered architecture with clear separation:

```
┌──────────────────────────────────────────────────────────────┐
│                    Physical Layer                             │
│  VESC FSESC75200 ──CAN Bus(500kbps)──> CAN-SPI Click(MCP2515)│
└───────────────────────────┬──────────────────────────────────┘
                            │ SPI
┌───────────────────────────▼──────────────────────────────────┐
│                    Hardware Layer                             │
│  Raspberry Pi GPIO/SPI ──> Linux SocketCAN (can0)            │
└───────────────────────────┬──────────────────────────────────┘
                            │ Raw Socket
┌───────────────────────────▼──────────────────────────────────┐
│                  Middleware Layer (Python)                    │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │  CANManager    │→ │ VESCCodec    │→ │ TelemetryBridge │  │
│  │  (HAL)         │  │ (Protocol)   │  │ (Qt Bridge)     │  │
│  └────────────────┘  └──────────────┘  └─────────────────┘  │
└───────────────────────────┬──────────────────────────────────┘
                            │ Qt Signals/Properties
┌───────────────────────────▼──────────────────────────────────┐
│                  Presentation Layer (QML)                     │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │  Dashboard     │  │ CircularGauge│  │   Diagnostics   │  │
│  │  (Main View)   │  │ (Component)  │  │  (Detail View)  │  │
│  └────────────────┘  └──────────────┘  └─────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

#### 1. CANManager (Hardware Abstraction Layer)
**File:** `middleware/can_manager.py`

- Abstracts SocketCAN interface for cross-platform development
- Provides virtual CAN mode for testing without hardware
- Manages receive thread for asynchronous message handling
- Implements callback system for CAN ID filtering

**Key Features:**
- Thread-safe callback registration
- Automatic reconnection handling
- Virtual mode for development on any platform
- Zero-copy message passing

#### 2. VESCCodec (Protocol Handler)
**File:** `middleware/vesc_codec.py`

- Decodes VESC CAN protocol (5 status frames)
- Handles bit-shifting and byte-order conversion
- Merges multi-frame status into single telemetry object
- Validates data integrity and range

**VESC Protocol Details:**

| Frame ID | Content | Update Rate | Byte Structure |
|----------|---------|-------------|----------------|
| `0x000002` | Temp, Current, Duty | 50Hz | 2×int16 (temp, current) + 1×uint8 (duty) |
| `0x000003` | RPM, Voltage | 50Hz | 1×int32 (rpm) + 1×uint16 (voltage) |
| `0x000004` | Amp-Hours | 50Hz | 2×int32 (consumed, charged) |
| `0x000005` | Watt-Hours | 50Hz | 2×int32 (consumed, charged) |
| `0x000006` | Tachometer | 50Hz | 2×int32 (relative, absolute) |

**Scaling Factors:**
- Temperature: `raw * 0.1` (°C)
- Current: `raw * 0.1` (A)
- Voltage: `raw * 0.1` (V)
- Duty Cycle: `raw * 0.001` (0.0-1.0)
- Energy: `raw * 0.0001` (Ah/Wh)

#### 3. TelemetryBridge (Qt Interface)
**File:** `main.py`

- Bridges Python middleware to QML UI layer
- Exposes telemetry as Qt Properties for QML binding
- Calculates derived values (speed, power, efficiency)
- Emits signals for reactive UI updates

**Signal/Slot Architecture:**
```python
# Property with change notification
@Property(float, notify=speedChanged)
def speed(self):
    return self._speed

# Automatic signal emission triggers QML update
self.speedChanged.emit(new_speed)
```

#### 4. QML UI Components
**Files:** `ui/*.qml`

- Hardware-accelerated rendering via Qt Quick
- Declarative reactive bindings to telemetry properties
- Custom gauge components with smooth animations
- Glassmorphism design for outdoor visibility

**Component Hierarchy:**
```
main.qml (ApplicationWindow)
├── Dashboard.qml (Primary driving view)
│   ├── CircularGauge.qml (Speed, RPM, Voltage, Current)
│   ├── TelemetryCard.qml (Efficiency display)
│   └── Temperature bars
└── Diagnostics.qml (Extended telemetry view)
    └── TelemetryCard.qml (Multiple instances)
```

### Adding New Telemetry Parameters

Workflow for adding new data:

#### Step 1: Update VESCStatus
```python
# middleware/vesc_codec.py
@dataclass
class VESCStatus:
    # ... existing fields ...
    new_parameter: float = 0.0  # Add your new field
```

#### Step 2: Decode in Protocol Handler
```python
# middleware/vesc_codec.py
def _decode_status_N(self, data: bytes) -> VESCStatus:
    # Unpack according to VESC protocol
    new_param_raw = struct.unpack("<H", data[6:8])[0]
    status.new_parameter = new_param_raw * 0.1  # Apply scaling
    return status
```

#### Step 3: Expose via TelemetryBridge
```python
# main.py
class TelemetryBridge(QObject):
    newParameterChanged = Signal(float)  # Add signal
    
    @Property(float, notify=newParameterChanged)
    def newParameter(self):
        return self._new_parameter
```

#### Step 4: Display in QML
```qml
// ui/Dashboard.qml
property real newParameter: 0.0

Connections {
    target: telemetry
    function onNewParameterChanged(value) { newParameter = value }
}

Text {
    text: newParameter.toFixed(1) + " units"
}
```

### Code Style

#### Python
- PEP 8 compliant
- Type hints where practical
- Google-style docstrings for public methods
- Graceful error handling (log, don't crash)
- Use locks for shared state

Example:
```python
def decode_status_frame(self, can_id: int, data: bytes) -> Optional[VESCStatus]:
    """
    Decode VESC Status Frame from CAN message.
    
    Args:
        can_id: CAN message ID (0x000002-0x000006)
        data: 8-byte CAN payload
        
    Returns:
        VESCStatus object if successful, None otherwise
    """
    # Implementation
```

#### QML
- Qt Quick Controls 2.15
- Prefer declarative bindings
- Use `readonly property` for constants
- Use `Behavior` for transitions
- Avoid bindings in loops

Example:
```qml
property real value: 0.0  // Reactive property

Behavior on value {
    NumberAnimation {
        duration: 400
        easing.type: Easing.OutCubic
    }
}
```

### Testing

```bash
# Unit tests
pytest tests/
pytest --cov=middleware tests/  # With coverage

# Integration
python main.py --virtual --sim-throttle 0.7
python test_gauges.py

# Hardware
candump can0 -L
python main.py --interface can0 > telemetry.log
```

### Profiling

```bash
# Python
python -m cProfile -o profile.stats main.py --virtual

# QML
export QSG_VISUALIZE=overdraw
python main.py --virtual
```

## Performance Targets

| Metric | Target | Typical |
|--------|--------|---------|
| **CAN → Pi Kernel** | <1ms | 0.5ms |
| **Kernel → Python** | <5ms | 2ms |
| **Python → QML** | <10ms | 5ms |
| **Total End-to-End Latency** | <50ms | 15-20ms |
| **Update Rate** | 50Hz | 50Hz |
| **CPU Usage (Pi 4)** | <30% | 20-25% |

Target: 60 FPS UI rendering under full telemetry load.

## Troubleshooting

### CAN Interface Issues

#### Interface Not Found
```bash
# Check if MCP2515 driver loaded
lsmod | grep mcp251x

# Check device tree overlay
vcgencmd get_config int | grep mcp2515

# Verify SPI is enabled
ls /dev/spidev*  # Should show spidev0.0
```

**Solutions:**
- Ensure SPI is enabled in `/boot/config.txt`
- Verify `dtoverlay=mcp2515-can0` line is correct
- Check physical wiring connections
- Try reducing SPI frequency: `spimaxfrequency=1000000`

#### Interface Won't Come Up
```bash
# Check kernel logs for errors
dmesg | grep -i can
dmesg | grep -i mcp

# Common errors and fixes:
# "mcp251x spi0.0: Cannot initialize MCP2515"
#   → Check oscillator frequency (should be 16MHz)
#   → Verify interrupt pin connection

# "RTNETLINK answers: Operation not permitted"
#   → Run with sudo or add user to appropriate group:
#     sudo usermod -a -G dialout $USER
```

#### Bus-Off Errors
```bash
# Check error counters
ip -s link show can0

# If you see many errors:
# 1. Check termination resistors (120Ω at each end)
# 2. Verify bitrate matches VESC (500kbps)
# 3. Check cable quality and length (keep under 5m for high speeds)
# 4. Reduce EMI with shielded cables
```

### No Telemetry Data

#### VESC Not Sending
```bash
# Monitor CAN bus
candump can0

# If empty:
# 1. Verify VESC is powered on
# 2. Check VESC CAN settings in VESC Tool
# 3. Confirm CAN status rate is not 0 (disabled)
# 4. Test with VESC Tool's CAN analyzer
```

#### Wrong CAN IDs
```bash
# Monitor with filter
candump can0,000002:1FFFFFFF

# VESC uses IDs 0x000002-0x000006
# If you see different IDs, adjust in vesc_codec.py
```

#### Data Not Reaching UI
```bash
# Run with debug output
python main.py --interface can0

# Check Python console for:
# - "CAN message received" logs
# - Decoding errors
# - Qt signal emissions

# Enable QML debug output:
export QT_LOGGING_RULES="qml.debug=true"
python main.py --interface can0
```

### Display Issues

#### UI Not Loading
```bash
# Verify PySide6 installation
python3 -c "import PySide6; print(PySide6.__version__)"

# Check Qt platform plugin
export QT_DEBUG_PLUGINS=1
python3 main.py --virtual

# Test basic Qt functionality
python3 -c "from PySide6.QtWidgets import QApplication; import sys; app = QApplication(sys.argv)"
```

#### Black Screen / No Rendering
```bash
# Check if running under X11
echo $DISPLAY  # Should show :0 or similar

# If running from SSH, use:
export DISPLAY=:0
python3 main.py --interface can0 --fullscreen

# Or use VNC for remote access
```

#### Performance Issues / Lag
```bash
# Check CPU usage
top -p $(pgrep -f main.py)

# Enable GPU acceleration
sudo raspi-config
# → Advanced Options → GL Driver → Full KMS

# Reduce gauge update rate in Theme.qml
# Change animationDuration from 400 to 200ms
```

### Permission Issues

#### Cannot Access CAN Interface
```bash
# Add user to necessary groups
sudo usermod -a -G dialout,gpio,spi $USER
sudo reboot

# Or run with sudo (not recommended for production)
sudo python3 main.py --interface can0
```

### Development on Non-Linux Systems

If developing on macOS/Windows where SocketCAN isn't available:

```bash
# Always use virtual mode
python main.py --virtual --sim-throttle 0.5

# Or use the test script
python test_gauges.py
```

### Getting Help

If issues persist:

1. **Check logs:**
   ```bash
   journalctl -u gokart-dashboard.service -f
   ```

2. **Enable verbose CAN logging:**
   ```bash
   sudo ip link set can0 down
   sudo ip link set can0 up type can bitrate 500000 berr-reporting on
   candump -e can0
   ```

3. **Test with minimal setup:**
   ```bash
   # Test CAN interface independently
   cansend can0 123#DEADBEEF
   candump can0
   ```

4. **Verify hardware with loopback test:**
   ```bash
   # Connect CAN_H to CAN_L for loopback
   sudo ip link set can0 down
   sudo ip link set can0 up type can bitrate 500000 loopback on
   cansend can0 123#DEADBEEF  # Should receive your own message
   ```

## TODO / Future Work

- [ ] Data logging (CSV/SQLite)
- [ ] Lap timer with GPS
- [ ] Thermal management warnings
- [ ] Energy optimization display
- [ ] Dual motor support
- [ ] Wireless telemetry streaming
- [ ] Battery SoC estimation


## Contributing

Standard workflow:
1. Create feature branch (`git checkout -b feature/name`)
2. Make changes
3. Test (`python test_gauges.py`)
4. Commit with clear message
5. Push and create PR

Guidelines:
- Follow PEP 8 for Python, Qt conventions for QML
- Add tests for new features
- Update docs
- Clear commit messages

## References

- [VESC Project](https://vesc-project.com/) - Motor controller firmware and CAN protocol
- [VESC Tool](https://vesc-project.com/vesc_tool) - Configuration software
- [Qt Documentation](https://www.qt.io/) - Framework documentation
- [SocketCAN](https://www.kernel.org/doc/html/latest/networking/can.html) - Linux CAN subsystem


---

Internal project for electric kart team. Real-time telemetry display with Qt/QML interface.
