import QtQuick 2.15
import QtQuick.Shapes 1.15
import ui 1.0

Item {
    id: gauge
    
    // Public properties
    property real value: 0
    property real minimumValue: 0
    property real maximumValue: 100
    property real redlineValue: 80
    property string unit: ""
    property string label: ""
    property bool showRedline: false
    property int size: 200
    
    // Theme reference
    readonly property var theme: Theme
    
    // Internal calculations
    readonly property real normalizedValue: Math.max(minimumValue, Math.min(maximumValue, value))
    readonly property real valueSweep: ((normalizedValue - minimumValue) / (maximumValue - minimumValue)) * 270
    readonly property real valueAngle: 135 + valueSweep
    readonly property real redlineAngle: showRedline ? 135 + ((redlineValue - minimumValue) / (maximumValue - minimumValue)) * 270 : 405
    
    width: size
    height: size
    
    // Background circle with glassmorphism
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: theme.glassBackground
        border.color: theme.glassBorder
        border.width: theme.borderWidth
    }
    
    // Gauge arc track (background) - thinner arc with gap at bottom
    Shape {
        id: arcShape
        anchors.fill: parent
        anchors.margins: parent.width * 0.1
        
        ShapePath {
            strokeColor: theme.gaugeTrack
            strokeWidth: gauge.width * 0.05  // Thinner stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            
            PathAngleArc {
                // Center relative to the Shape's bounds (after margins)
                centerX: arcShape.width / 2
                centerY: arcShape.height / 2
                radiusX: arcShape.width * 0.4375  // Proportional to shape size
                radiusY: arcShape.height * 0.4375
                startAngle: 135  // Start at bottom-right (4:30 position)
                sweepAngle: 270  // Sweep to top-right, leaving gap at bottom
            }
        }
    }
    
    // Active value sweep (colored arc following needle)
    Shape {
        id: sweepShape
        anchors.fill: parent
        anchors.margins: parent.width * 0.1
        opacity: 0.7  // Subtle transparency
        
        ShapePath {
            strokeColor: gauge.normalizedValue >= redlineValue && showRedline ? theme.accentDanger : theme.accentPrimary
            strokeWidth: gauge.width * 0.05  // Match background thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            
            PathAngleArc {
                centerX: arcShape.width / 2
                centerY: arcShape.height / 2
                radiusX: arcShape.width * 0.4375
                radiusY: arcShape.height * 0.4375
                startAngle: 135
                sweepAngle: gauge.valueSweep  // Use shared property for perfect sync
            }
            
            Behavior on strokeColor {
                ColorAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
    
    // Tick marks
    Repeater {
        model: 9
        
        Rectangle {
            property real tickAngle: 135 + (index * 270 / 8)  // Match new arc position
            property real tickRadius: gauge.width * 0.35  // Align with arc centerline
            property bool isRedline: showRedline && (135 + (index * 270 / 8)) >= redlineAngle
            
            x: gauge.width / 2 + Math.cos((tickAngle - 90) * Math.PI / 180) * tickRadius - width / 2
            y: gauge.height / 2 + Math.sin((tickAngle - 90) * Math.PI / 180) * tickRadius - height / 2
            width: gauge.width * 0.018  // Slightly wider for better visibility
            height: gauge.width * 0.06  // Slightly taller
            radius: width / 2
            color: isRedline ? theme.accentSecondary : theme.gaugeTick
            
            transform: Rotation {
                origin.x: width / 2
                origin.y: height / 2
                angle: tickAngle
            }
        }
    }
    
    // Needle
    Rectangle {
        id: needle
        x: gauge.width / 2 - width / 2
        y: gauge.height / 2 - height + gauge.width * 0.04
        width: gauge.width * 0.025  // Slightly thicker for visibility
        height: gauge.width * 0.32
        radius: width / 2
        color: gauge.normalizedValue >= redlineValue && showRedline ? theme.accentDanger : theme.gaugeNeedle
        opacity: 0.9  // Subtle transparency
        antialiasing: true
        
        transform: Rotation {
            origin.x: needle.width / 2
            origin.y: needle.height - gauge.width * 0.04
            angle: gauge.valueAngle - 270  // Offset: needle naturally points at 270°, adjust to arc position
            
            Behavior on angle {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }
        }
        
        Behavior on color {
            ColorAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
    }
    
    // Center hub
    Rectangle {
        anchors.centerIn: parent
        width: gauge.width * 0.12
        height: width
        radius: width / 2
        color: theme.surfaceElevated
        border.color: theme.glassBorder
        border.width: 1
    }
    
    // Center dot
    Rectangle {
        anchors.centerIn: parent
        width: gauge.width * 0.05
        height: width
        radius: width / 2
        color: gauge.normalizedValue >= redlineValue && showRedline ? theme.accentDanger : theme.gaugeNeedle
        opacity: 0.9  // Subtle transparency
        
        Behavior on color {
            ColorAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
    }
    
    // Value display
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: gauge.height * 0.18
        spacing: theme.spacingSmall
        
        Text {
            id: valueText
            text: {
                if (maximumValue >= 1000) {
                    return Math.round(gauge.normalizedValue).toLocaleString()
                } else {
                    return gauge.normalizedValue.toFixed(1)
                }
            }
            font.family: theme.fontFamilyMono
            font.pixelSize: gauge.width * 0.16
            font.weight: Font.Light
            color: theme.textPrimary
            anchors.horizontalCenter: parent.horizontalCenter
            
            property real animatedValue: gauge.normalizedValue
            
            Behavior on animatedValue {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }
        }
        
        Text {
            text: gauge.unit
            font.family: theme.fontFamily
            font.pixelSize: gauge.width * 0.08
            font.weight: Font.Normal
            color: theme.textTertiary
            font.letterSpacing: 1
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
    
    // Label at bottom
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: gauge.height * 0.12
        text: gauge.label.toLowerCase()
        font.family: theme.fontFamily
        font.pixelSize: gauge.width * 0.09
        font.weight: Font.Normal
        color: theme.textSecondary
        font.letterSpacing: 2
    }
}
