pragma Singleton
import QtQuick 2.15

QtObject {
    id: theme
    
    // Spacing System (8px base unit) - Strict Golden Ratio
    readonly property int gridUnit: 8
    readonly property int spacing: gridUnit * 2           // Internal spacing: 16px
    readonly property int spacingSmall: gridUnit          // 8px
    readonly property int spacingMedium: gridUnit * 2     // 16px
    readonly property int spacingLarge: gridUnit * 3      // 24px
    readonly property int spacingXLarge: gridUnit * 4     // 32px
    
    // Margins - Strict 24px rule
    readonly property int margin: gridUnit * 3            // All margins: 24px
    readonly property int marginSmall: gridUnit
    readonly property int marginLarge: gridUnit * 3
    
    // Border Radius - Softer curves
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 16
    
    // Automotive-Grade Dark Theme Palette
    readonly property color background: "#0A0A0B"         // Deep automotive black
    readonly property color surface: "#15FFFFFF"          // Glassmorphism surface (8% white)
    readonly property color surfaceElevated: "#20FFFFFF"  // Higher elevation glass
    
    // Subtle Gauge Colors - Darker for sophistication
    readonly property color accentPrimary: "#0099AA"      // Muted cyan (primary needle)
    readonly property color accentSecondary: "#CC3300"    // Deep red (redline)
    readonly property color accentWarning: "#CC8800"      // Amber warning
    readonly property color accentDanger: "#CC1133"       // Critical red
    readonly property color accentSuccess: "#00AA55"      // Deep green efficiency
    
    // Text Colors - High-contrast automotive
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#B0B0B0"      // 70% opacity
    readonly property color textTertiary: "#808080"       // 50% opacity
    
    // Glassmorphism & Spatial Cues
    readonly property color glassBackground: "#15FFFFFF"  // Frosted glass
    readonly property color glassBorder: "#30FFFFFF"      // Glass border (18% white)
    readonly property color borderSubtle: "#20FFFFFF"     // Subtle borders
    readonly property int borderWidth: 1
    
    // Gauge Colors
    readonly property color gaugeTick: "#50FFFFFF"        // Tick marks (31% white - more visible)
    readonly property color gaugeTrack: "#10FFFFFF"       // Gauge background track (darker)
    readonly property color gaugeSweep: "#20FFFFFF"       // Active sweep area (more subtle)
    readonly property color gaugeNeedle: accentPrimary    // Needle color
    
    // Typography - Human-centric hierarchy
    readonly property int fontSizeHero: 108               // Primary numbers
    readonly property int fontSizeXLarge: 72              // Secondary numbers
    readonly property int fontSizeLarge: 48
    readonly property int fontSizeMedium: 28
    readonly property int fontSizeSmall: 16
    readonly property int fontSizeXSmall: 12
    
    readonly property string fontFamily: "Helvetica"
    readonly property string fontFamilyMono: "Monaco"
    
    // Component Styles
    readonly property int cardPadding: gridUnit * 3       // 24px padding
    readonly property int cardRadius: radiusMedium
    
    // Animation Timings
    readonly property int animationDuration: 250
    readonly property int animationDurationSlow: 500
    
    // Temperature thresholds
    readonly property real tempNormal: 60.0
    readonly property real tempWarning: 80.0
    
    function getTempColor(temp) {
        if (temp < tempNormal) return accentPrimary
        if (temp < tempWarning) return accentWarning
        return accentDanger
    }
}
