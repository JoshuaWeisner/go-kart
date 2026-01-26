import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ui 1.0

Pane {
    id: telemetryCard
    
    property string title: ""
    property string value: ""
    property string unit: ""
    property color accentColor: Theme.accentPrimary
    
    Layout.fillWidth: true
    Layout.preferredHeight: theme.gridUnit * 18
    padding: theme.cardPadding
    
    background: Rectangle {
        color: theme.surface
        radius: theme.cardRadius
        border.color: theme.borderSubtle
        border.width: theme.borderWidth
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.spacingSmall
        spacing: theme.spacingSmall
        
        Text {
            text: telemetryCard.title.toLowerCase()
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeXSmall
            font.weight: Font.Normal
            color: theme.textSecondary
            font.letterSpacing: 1.2
        }
        
        Item { Layout.fillHeight: true }
        
        RowLayout {
            spacing: theme.spacingSmall
            Layout.alignment: Qt.AlignLeft
            
            Text {
                id: cardValue
                text: telemetryCard.value
                font.family: theme.fontFamilyMono
                font.pixelSize: theme.fontSizeMedium
                font.weight: Font.Light
                color: telemetryCard.accentColor
                
                Behavior on color {
                    ColorAnimation {
                        duration: theme.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
            
            Text {
                text: telemetryCard.unit.toLowerCase()
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeXSmall
                color: theme.textTertiary
                Layout.alignment: Qt.AlignBaseline
            }
        }
        
        Item { Layout.fillHeight: true }
    }
    
    // Theme reference
    readonly property var theme: Theme
}
