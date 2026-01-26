import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ui 1.0

ApplicationWindow {
    id: window
    width: 1920
    height: 1080
    visible: true
    title: "Go-Kart Telemetry Dashboard"
    
    // Fullscreen on Raspberry Pi
    property bool fullscreen: false
    
    Component.onCompleted: {
        if (fullscreen) {
            showFullScreen()
        }
    }
    
    // Store telemetry reference to pass to views
    property var telemetryBridge: typeof telemetry !== 'undefined' ? telemetry : null
    
    // Main view stack
    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: Dashboard {
            telemetry: window.telemetryBridge
            onDiagnosticsRequested: {
                stackView.push(diagnosticsViewComponent, { telemetry: window.telemetryBridge })
            }
        }
        
        Component {
            id: diagnosticsViewComponent
            Diagnostics {
                onBackRequested: {
                    stackView.pop()
                }
            }
        }
    }
}
