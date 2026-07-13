import SwiftUI

extension Color {
    // Earth & Sepia Theme
    
    /// The main background color, warm off-white in light mode, deep muted brown in dark mode.
    static let sepiaBackground = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.name == .darkAqua ?
            NSColor(red: 0.17, green: 0.16, blue: 0.15, alpha: 1.0) : // #2C2825
            NSColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)   // #F5EFE6
    })
    
    /// The surface color for bubbles/cards, slightly contrasted against the background.
    static let sepiaSurface = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.name == .darkAqua ?
            NSColor(red: 0.24, green: 0.22, blue: 0.20, alpha: 1.0) : // #3C3733
            NSColor(red: 0.92, green: 0.88, blue: 0.84, alpha: 1.0)   // #EBE0D5
    })
    
    /// The accent color, terracotta.
    static let sepiaAccent = Color(red: 0.80, green: 0.35, blue: 0.27) // #CC5A44
    
    /// Primary text color, ensures high contrast against the background.
    static let sepiaText = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.name == .darkAqua ?
            NSColor(red: 0.95, green: 0.93, blue: 0.90, alpha: 1.0) : // #F2EDE6
            NSColor(red: 0.20, green: 0.18, blue: 0.16, alpha: 1.0)   // #332E29
    })
}
