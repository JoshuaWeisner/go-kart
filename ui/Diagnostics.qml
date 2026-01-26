import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ui 1.0

Item {
    id: diagnostics
    
    signal backRequested()
    
    // Theme reference
    readonly property var theme: Theme
    
    // Telemetry object passed from main.qml
    property var telemetry: null
    
    // Extended telemetry data (mutable properties that update from signals)
    property real speed: 0.0
    property int rpm: 0
    property real voltage: 0.0
    property real currentMotor: 0.0
    property real currentBattery: 0.0
    property real power: 0.0
    property real tempMos: 0.0
    property real dutyCycle: 0.0
    property real efficiency: 0.0
    property real ampHoursConsumed: 0.0
    property real ampHoursCharged: 0.0
    property real wattHoursConsumed: 0.0
    property real wattHoursCharged: 0.0
    property int tachometer: 0
    property int tachometerAbs: 0
    property int faultCode: 0
    
    // Connect to telemetry signals when telemetry object is available
    Connections {
        target: telemetry
        function onSpeedChanged(value) { speed = value }
        function onRpmChanged(value) { rpm = value }
        function onVoltageChanged(value) { voltage = value }
        function onCurrentMotorChanged(value) { currentMotor = value }
        function onCurrentBatteryChanged(value) { currentBattery = value }
        function onPowerChanged(value) { power = value }
        function onTempMosChanged(value) { tempMos = value }
        function onDutyCycleChanged(value) { dutyCycle = value }
        function onEfficiencyChanged(value) { efficiency = value }
        function onAmpHoursConsumedChanged(value) { ampHoursConsumed = value }
        function onAmpHoursChargedChanged(value) { ampHoursCharged = value }
        function onWattHoursConsumedChanged(value) { wattHoursConsumed = value }
        function onWattHoursChargedChanged(value) { wattHoursCharged = value }
        function onTachometerChanged(value) { tachometer = value }
        function onTachometerAbsChanged(value) { tachometerAbs = value }
        function onFaultCodeChanged(value) { faultCode = value }
    }
    
    // Initialize values from telemetry if available
    Component.onCompleted: {
        if (telemetry) {
            speed = telemetry.speed
            rpm = telemetry.rpm
            voltage = telemetry.voltage
            currentMotor = telemetry.currentMotor
            currentBattery = telemetry.currentBattery
            power = telemetry.power
            tempMos = telemetry.tempMos
            dutyCycle = telemetry.dutyCycle
            efficiency = telemetry.efficiency
            ampHoursConsumed = telemetry.ampHoursConsumed
            ampHoursCharged = telemetry.ampHoursCharged
            wattHoursConsumed = telemetry.wattHoursConsumed
            wattHoursCharged = telemetry.wattHoursCharged
            tachometer = telemetry.tachometer
            tachometerAbs = telemetry.tachometerAbs
            faultCode = telemetry.faultCode
        }
    }
    
    // Automotive-grade black background
    Rectangle {
        anchors.fill: parent
        color: theme.background
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: theme.margin
            spacing: theme.margin
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: theme.spacing
                
                Button {
                    id: backButton
                    Layout.preferredWidth: theme.gridUnit * 14
                    Layout.preferredHeight: theme.gridUnit * 7
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: theme.cardRadius
                        border.color: parent.pressed ? theme.accentPrimary : theme.borderSubtle
                        border.width: theme.borderWidth
                        
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    contentItem: Text {
                        text: "← back"
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.Normal
                        color: parent.pressed ? theme.accentPrimary : theme.textSecondary
                        font.letterSpacing: 1.2
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    onClicked: diagnostics.backRequested()
                }
                
                Text {
                    text: "diagnostics"
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeLarge
                    font.weight: Font.Light
                    color: theme.textPrimary
                    font.letterSpacing: 2
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Item {
                    Layout.preferredWidth: backButton.width
                }
            }
            
            // Scrollable content
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                GridLayout {
                    width: parent.width
                    columns: 3
                    columnSpacing: theme.spacing
                    rowSpacing: theme.spacing
                    
                    // Row 1: Speed, RPM, Voltage
                    TelemetryCard {
                        title: "SPEED"
                        value: Math.round(speed).toString()
                        unit: "km/h"
                    }
                    
                    TelemetryCard {
                        title: "RPM"
                        value: Math.round(rpm).toLocaleString()
                        unit: ""
                    }
                    
                    TelemetryCard {
                        title: "VOLTAGE"
                        value: voltage.toFixed(2)
                        unit: "V"
                    }
                    
                    // Row 2: Currents
                    TelemetryCard {
                        title: "MOTOR CURRENT"
                        value: currentMotor.toFixed(2)
                        unit: "A"
                    }
                    
                    TelemetryCard {
                        title: "BATTERY CURRENT"
                        value: currentBattery.toFixed(2)
                        unit: "A"
                    }
                    
                    TelemetryCard {
                        title: "POWER"
                        value: Math.round(power).toString()
                        unit: "W"
                    }
                    
                    // Row 3: Temperature & Efficiency
                    TelemetryCard {
                        title: "MOSFET TEMP"
                        value: tempMos.toFixed(1)
                        unit: "°C"
                        accentColor: theme.getTempColor(tempMos)
                    }
                    
                    TelemetryCard {
                        title: "EFFICIENCY"
                        value: efficiency.toFixed(2)
                        unit: "%"
                    }
                    
                    TelemetryCard {
                        title: "DUTY CYCLE"
                        value: (dutyCycle * 100).toFixed(1)
                        unit: "%"
                    }
                    
                    // Row 4: Energy
                    TelemetryCard {
                        title: "Ah CONSUMED"
                        value: ampHoursConsumed.toFixed(3)
                        unit: "Ah"
                    }
                    
                    TelemetryCard {
                        title: "Ah CHARGED"
                        value: ampHoursCharged.toFixed(3)
                        unit: "Ah"
                    }
                    
                    TelemetryCard {
                        title: "Wh CONSUMED"
                        value: wattHoursConsumed.toFixed(2)
                        unit: "Wh"
                    }
                    
                    // Row 5: Tachometer and Fault
                    TelemetryCard {
                        title: "TACHOMETER"
                        value: tachometer.toString()
                        unit: ""
                    }
                    
                    TelemetryCard {
                        title: "TACHOMETER ABS"
                        value: tachometerAbs.toString()
                        unit: ""
                    }
                    
                    TelemetryCard {
                        title: "FAULT CODE"
                        value: faultCode.toString()
                        unit: faultCode === 0 ? "(OK)" : "(ERROR)"
                        accentColor: faultCode === 0 ? theme.accentPrimary : theme.accentDanger
                    }
                }
            }
        }
    }
}
