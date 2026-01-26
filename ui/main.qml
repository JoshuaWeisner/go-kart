import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

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
    
    // Main view stack
    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: dashboardView
        
        Component {
            id: dashboardView
            Dashboard {
                onDiagnosticsRequested: {
                    stackView.push(diagnosticsView)
                }
            }
        }
        
        Component {
            id: diagnosticsView
            Diagnostics {
                onBackRequested: {
                    stackView.pop()
                }
            }
        }
    }
}
