import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ui 1.0

Item {
    id: dashboard
    
    signal diagnosticsRequested()
    
    // Theme reference
    readonly property var theme: Theme
    
    // Telemetry object passed from main.qml
    property var telemetry: null
    
    // Telemetry data (mutable properties that update from signals)
    property real speed: 0.0
    property int rpm: 0
    property real voltage: 0.0
    property real currentMotor: 0.0
    property real currentBattery: 0.0
    property real power: 0.0
    property real tempMos: 0.0
    property real dutyCycle: 0.0
    property real efficiency: 0.0
    
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
            
            // Top Row: Primary Gauges (Speed & RPM)
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: theme.margin * 3
                
                Item { Layout.fillWidth: true }
                
                // Speed Gauge (Primary)
                CircularGauge {
                    Layout.alignment: Qt.AlignCenter
                    size: 350
                    value: speed
                    minimumValue: 0
                    maximumValue: 80
                    unit: "km/h"
                    label: "SPEED"
                }
                
                Item { Layout.fillWidth: true }
                
                // RPM Gauge (Primary)
                CircularGauge {
                    Layout.alignment: Qt.AlignCenter
                    size: 350
                    value: rpm
                    minimumValue: 0
                    maximumValue: 6000
                    redlineValue: 5000
                    showRedline: true
                    unit: "rpm"
                    label: "RPM"
                }
                
                Item { Layout.fillWidth: true }
            }
            
            // Bottom Row: Secondary Gauges & Efficiency
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 280
                spacing: theme.margin * 2
                
                Item { Layout.fillWidth: true }
                
                // Voltage Gauge (Secondary)
                CircularGauge {
                    Layout.alignment: Qt.AlignCenter
                    size: 200
                    value: voltage
                    minimumValue: 0
                    maximumValue: 60
                    unit: "v"
                    label: "VOLTAGE"
                }
                
                Item { Layout.fillWidth: true }
                
                // Efficiency Box (Trip Computer Style)
                Rectangle {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 280
                    color: theme.glassBackground
                    border.color: theme.glassBorder
                    border.width: theme.borderWidth
                    radius: theme.radiusMedium
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: theme.spacing
                        spacing: theme.spacingSmall
                        
                        Text {
                            text: "efficiency".toUpperCase()
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeXSmall
                            font.weight: Font.Normal
                            color: theme.textSecondary
                            font.letterSpacing: 2
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Item { Layout.fillHeight: true }
                        
                        Text {
                            id: effValue
                            text: efficiency.toFixed(1)
                            font.family: theme.fontFamilyMono
                            font.pixelSize: parent.width * 0.25
                            font.weight: Font.Light
                            color: theme.accentSuccess
                            Layout.alignment: Qt.AlignHCenter
                            
                            property real animatedValue: efficiency
                            
                            Behavior on animatedValue {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        
                        Text {
                            text: "%"
                            font.family: theme.fontFamilyMono
                            font.pixelSize: theme.fontSizeSmall
                            color: theme.textTertiary
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Item { Layout.fillHeight: true }
                        
                        // Power readout
                        Text {
                            text: Math.round(power) + "W"
                            font.family: theme.fontFamilyMono
                            font.pixelSize: theme.fontSizeXSmall
                            color: theme.textTertiary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Current Gauge (Secondary)
                CircularGauge {
                    Layout.alignment: Qt.AlignCenter
                    size: 200
                    value: currentMotor
                    minimumValue: 0
                    maximumValue: 200
                    unit: "a"
                    label: "CURRENT"
                }
                
                Item { Layout.fillWidth: true }
            }
            
            // Bottom Bar: MOSFET Temperature & Diagnostics
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: theme.gridUnit * 6
                spacing: theme.margin
                
                // MOSFET Temperature Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height
                    color: theme.glassBackground
                    border.color: theme.glassBorder
                    border.width: theme.borderWidth
                    radius: theme.radiusMedium
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: theme.spacing
                        spacing: theme.spacing
                        
                        Text {
                            text: "MOSFET"
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeXSmall
                            font.weight: Font.Normal
                            color: theme.textSecondary
                            font.letterSpacing: 1.5
                        }
                        
                        // Temperature bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: theme.gridUnit
                            color: theme.gaugeTrack
                            radius: height / 2
                            
                            Rectangle {
                                width: Math.min(1, tempMos / 100) * parent.width
                                height: parent.height
                                color: theme.getTempColor(tempMos)
                                radius: parent.radius
                                
                                Behavior on width {
                                    NumberAnimation {
                                        duration: 400
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 400
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                        
                        Text {
                            text: Math.round(tempMos) + "°C"
                            font.family: theme.fontFamilyMono
                            font.pixelSize: theme.fontSizeSmall
                            font.weight: Font.Light
                            color: theme.getTempColor(tempMos)
                            Layout.preferredWidth: theme.gridUnit * 8
                            
                            Behavior on color {
                                ColorAnimation {
                                    duration: 400
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
                
                // Diagnostics Button
                Button {
                    Layout.preferredWidth: theme.gridUnit * 20
                    Layout.preferredHeight: parent.height
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: theme.radiusMedium
                        border.color: parent.pressed ? theme.accentPrimary : theme.glassBorder
                        border.width: theme.borderWidth
                        
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    contentItem: Text {
                        text: "DIAGNOSTICS"
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.Normal
                        color: parent.pressed ? theme.accentPrimary : theme.textSecondary
                        font.letterSpacing: 2
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    onClicked: dashboard.diagnosticsRequested()
                }
            }
        }
    }
}
