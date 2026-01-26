import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: dashboard
    
    signal diagnosticsRequested()
    
    // Telemetry data (bound from Python backend)
    property real speed: 0.0  // km/h (calculated from RPM)
    property real rpm: 0
    property real voltage: 0.0
    property real currentMotor: 0.0
    property real currentBattery: 0.0
    property real power: 0.0
    property real tempMos: 0.0
    property real tempMotor: 0.0
    property real dutyCycle: 0.0
    property real efficiency: 0.0
    
    // Visual constants
    readonly property color primaryColor: "#00FF00"  // Bright green for visibility
    readonly property color warningColor: "#FFAA00"
    readonly property color dangerColor: "#FF0000"
    readonly property color bgColor: "#000000"
    readonly property color textColor: "#FFFFFF"
    
    Rectangle {
        anchors.fill: parent
        color: bgColor
        
        // Main layout
        RowLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 40
            
            // Left panel - Speed and RPM
            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.4
                spacing: 30
                
                // Large Speed Display
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    color: "#111111"
                    radius: 20
                    border.color: primaryColor
                    border.width: 3
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            text: "SPEED"
                            font.pixelSize: 32
                            color: textColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: Math.round(dashboard.speed).toString()
                            font.pixelSize: 120
                            color: primaryColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: "km/h"
                            font.pixelSize: 36
                            color: textColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                // RPM Display
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: "#111111"
                    radius: 15
                    border.color: primaryColor
                    border.width: 2
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        
                        Text {
                            text: "RPM"
                            font.pixelSize: 24
                            color: textColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: Math.round(dashboard.rpm).toLocaleString()
                            font.pixelSize: 64
                            color: primaryColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                // Duty Cycle Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: "#111111"
                    radius: 10
                    border.color: primaryColor
                    border.width: 2
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        
                        Text {
                            text: "THROTTLE"
                            font.pixelSize: 18
                            color: textColor
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            color: "#222222"
                            radius: 5
                            
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, dashboard.dutyCycle))
                                height: parent.height
                                color: primaryColor
                                radius: 5
                                
                                Behavior on width {
                                    NumberAnimation { duration: 100 }
                                }
                            }
                        }
                        
                        Text {
                            text: Math.round(dashboard.dutyCycle * 100) + "%"
                            font.pixelSize: 20
                            color: primaryColor
                            font.bold: true
                        }
                    }
                }
            }
            
            // Center panel - Power and Current
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 20
                
                // Power Display
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 250
                    color: "#111111"
                    radius: 20
                    border.color: primaryColor
                    border.width: 3
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            text: "POWER"
                            font.pixelSize: 28
                            color: textColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: Math.round(dashboard.power).toString()
                            font.pixelSize: 96
                            color: primaryColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: "W"
                            font.pixelSize: 32
                            color: textColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                // Current readings
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20
                    
                    // Motor Current
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        color: "#111111"
                        radius: 15
                        border.color: primaryColor
                        border.width: 2
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            
                            Text {
                                text: "MOTOR CURRENT"
                                font.pixelSize: 18
                                color: textColor
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Text {
                                text: dashboard.currentMotor.toFixed(1) + " A"
                                font.pixelSize: 48
                                color: primaryColor
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    // Battery Current
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        color: "#111111"
                        radius: 15
                        border.color: primaryColor
                        border.width: 2
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            
                            Text {
                                text: "BATTERY CURRENT"
                                font.pixelSize: 18
                                color: textColor
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Text {
                                text: dashboard.currentBattery.toFixed(1) + " A"
                                font.pixelSize: 48
                                color: primaryColor
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
            
            // Right panel - Voltage, Temp, Efficiency
            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.3
                spacing: 20
                
                // Voltage Display
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: "#111111"
                    radius: 15
                    border.color: primaryColor
                    border.width: 2
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        
                        Text {
                            text: "VOLTAGE"
                            font.pixelSize: 24
                            color: textColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: dashboard.voltage.toFixed(1) + " V"
                            font.pixelSize: 64
                            color: primaryColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                // Temperature Display
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: "#111111"
                    radius: 15
                    border.color: getTempColor()
                    border.width: 2
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            text: "MOSFET"
                            font.pixelSize: 18
                            color: textColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: Math.round(dashboard.tempMos) + "°C"
                            font.pixelSize: 48
                            color: getTempColor()
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: "MOTOR: " + Math.round(dashboard.tempMotor) + "°C"
                            font.pixelSize: 20
                            color: getTempColor()
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                // Efficiency
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    color: "#111111"
                    radius: 15
                    border.color: primaryColor
                    border.width: 2
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        
                        Text {
                            text: "EFFICIENCY"
                            font.pixelSize: 18
                            color: textColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: dashboard.efficiency.toFixed(1) + "%"
                            font.pixelSize: 42
                            color: primaryColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                // Diagnostics Button
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    text: "DIAGNOSTICS"
                    font.pixelSize: 20
                    font.bold: true
                    
                    background: Rectangle {
                        color: parent.pressed ? "#003300" : "#001100"
                        border.color: primaryColor
                        border.width: 2
                        radius: 10
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: primaryColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font: parent.font
                    }
                    
                    onClicked: dashboard.diagnosticsRequested()
                }
            }
        }
    }
    
    // Helper function to get temperature color
    function getTempColor() {
        var maxTemp = Math.max(dashboard.tempMos, dashboard.tempMotor)
        if (maxTemp < 60) return primaryColor
        if (maxTemp < 80) return warningColor
        return dangerColor
    }
}
