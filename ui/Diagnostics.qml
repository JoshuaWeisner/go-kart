import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: diagnostics
    
    signal backRequested()
    
    // Extended telemetry data
    property real speed: 0.0
    property real rpm: 0
    property real voltage: 0.0
    property real currentMotor: 0.0
    property real currentBattery: 0.0
    property real power: 0.0
    property real tempMos: 0.0
    property real tempMotor: 0.0
    property real dutyCycle: 0.0
    property real efficiency: 0.0
    property real ampHoursConsumed: 0.0
    property real ampHoursCharged: 0.0
    property real wattHoursConsumed: 0.0
    property real wattHoursCharged: 0.0
    property int tachometer: 0
    property int tachometerAbs: 0
    property int faultCode: 0
    
    readonly property color primaryColor: "#00FF00"
    readonly property color warningColor: "#FFAA00"
    readonly property color dangerColor: "#FF0000"
    readonly property color bgColor: "#000000"
    readonly property color textColor: "#FFFFFF"
    
    Rectangle {
        anchors.fill: parent
        color: bgColor
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 20
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                
                Button {
                    text: "← BACK"
                    font.pixelSize: 18
                    font.bold: true
                    
                    background: Rectangle {
                        color: parent.pressed ? "#003300" : "#001100"
                        border.color: primaryColor
                        border.width: 2
                        radius: 8
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: primaryColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font: parent.font
                    }
                    
                    onClicked: diagnostics.backRequested()
                }
                
                Text {
                    text: "DIAGNOSTICS"
                    font.pixelSize: 36
                    font.bold: true
                    color: primaryColor
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Item {
                    width: backButton.width
                }
            }
            
            // Scrollable content
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                GridLayout {
                    width: parent.width
                    columns: 3
                    columnSpacing: 20
                    rowSpacing: 20
                    
                    // Row 1: Speed, RPM, Voltage
                    TelemetryCard {
                        title: "SPEED"
                        value: Math.round(diagnostics.speed).toString()
                        unit: "km/h"
                        Layout.fillWidth: true
                    }
                    
                    TelemetryCard {
                        title: "RPM"
                        value: Math.round(diagnostics.rpm).toLocaleString()
                        unit: ""
                        Layout.fillWidth: true
                    }
                    
                    TelemetryCard {
                        title: "VOLTAGE"
                        value: diagnostics.voltage.toFixed(2)
                        unit: "V"
                        Layout.fillWidth: true
                    }
                    
                    // Row 2: Currents
                    TelemetryCard {
                        title: "MOTOR CURRENT"
                        value: diagnostics.currentMotor.toFixed(2)
                        unit: "A"
                        Layout.fillWidth: true
                    }
                    
                    TelemetryCard {
                        title: "BATTERY CURRENT"
                        value: diagnostics.currentBattery.toFixed(2)
                        unit: "A"
                        Layout.fillWidth: true
                    }
                    
                    TelemetryCard {
                        title: "POWER"
                        value: Math.round(diagnostics.power).toString()
                        unit: "W"
                        Layout.fillWidth: true
                    }
                    
                    // Row 3: Temperatures
                    TelemetryCard {
                        title: "MOSFET TEMP"
                        value: diagnostics.tempMos.toFixed(1)
                        unit: "°C"
                        color: getTempColor(diagnostics.tempMos)
                        Layout.fillWidth: true
                    }
                    
                    TelemetryCard {
                        title: "MOTOR TEMP"
                        value: diagnostics.tempMotor.toFixed(1)
                        unit: "°C"
                        color: getTempColor(diagnostics.tempMotor)
                        Layout.fillWidth: true
                    }
                    
                    TelemetryCard {
                        title: "EFFICIENCY"
                        value: diagnostics.efficiency.toFixed(2)
                        unit: "%"
                        Layout.fillWidth: true
                    }
                    
                    // Row 4: Energy
                    TelemetryCard {
                        title: "Ah CONSUMED"
                        value: diagnostics.ampHoursConsumed.toFixed(3)
                        unit: "Ah"
                        Layout.fillWidth: true
                    }
                    
                    TelemetryCard {
                        title: "Ah CHARGED"
                        value: diagnostics.ampHoursCharged.toFixed(3)
                        unit: "Ah"
                        Layout.fillWidth: true
                    }
                    
                    TelemetryCard {
                        title: "Wh CONSUMED"
                        value: diagnostics.wattHoursConsumed.toFixed(2)
                        unit: "Wh"
                        Layout.fillWidth: true
                    }
                    
                    // Row 5: Tachometer and Fault
                    TelemetryCard {
                        title: "TACHOMETER"
                        value: diagnostics.tachometer.toString()
                        unit: ""
                        Layout.fillWidth: true
                    }
                    
                    TelemetryCard {
                        title: "TACHOMETER ABS"
                        value: diagnostics.tachometerAbs.toString()
                        unit: ""
                        Layout.fillWidth: true
                    }
                    
                    TelemetryCard {
                        title: "FAULT CODE"
                        value: diagnostics.faultCode.toString()
                        unit: diagnostics.faultCode === 0 ? "(OK)" : "(ERROR)"
                        color: diagnostics.faultCode === 0 ? primaryColor : dangerColor
                        Layout.fillWidth: true
                    }
                    
                    // Row 6: Duty Cycle
                    TelemetryCard {
                        title: "DUTY CYCLE"
                        value: (diagnostics.dutyCycle * 100).toFixed(1)
                        unit: "%"
                        Layout.fillWidth: true
                        Layout.columnSpan: 3
                    }
                }
            }
        }
    }
    
    function getTempColor(temp) {
        if (temp < 60) return primaryColor
        if (temp < 80) return warningColor
        return dangerColor
    }
    
    // Reusable telemetry card component
    component TelemetryCard: Rectangle {
        property string title: ""
        property string value: ""
        property string unit: ""
        property color color: primaryColor
        
        height: 120
        color: "#111111"
        radius: 10
        border.color: color
        border.width: 2
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5
            
            Text {
                text: parent.parent.title
                font.pixelSize: 14
                color: textColor
                Layout.alignment: Qt.AlignHCenter
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5
                
                Text {
                    text: parent.parent.value
                    font.pixelSize: 32
                    color: parent.parent.color
                    font.bold: true
                }
                
                Text {
                    text: parent.parent.unit
                    font.pixelSize: 16
                    color: textColor
                }
            }
        }
    }
}
