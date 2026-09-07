//
//  Sepia-Theme.swift
//  Astex
//
//  Created by Ben Herbert on 07/09/2026.
//
import SwiftUI

struct SepiaTheme: CustomTheme {
    let raw = "Sepia"
    let background: Color = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ?
            NSColor(red: 0.17, green: 0.16, blue: 0.15, alpha: 1.0) : // #2C2825
            NSColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)   // #F5EFE6
    })
    
    /// The surface color for bubbles/cards, slightly contrasted against the background.
    let surface: Color = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ?
            NSColor(red: 0.24, green: 0.22, blue: 0.20, alpha: 1.0) : // #3C3733
            NSColor(red: 0.92, green: 0.88, blue: 0.84, alpha: 1.0)   // #EBE0D5
    })
    
    /// The accent color, terracotta.
    let accent = Color(red: 0.80, green: 0.35, blue: 0.27) // #CC5A44
    
    /// Primary text color, ensures high contrast against the background.
    let text = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ?
            NSColor(red: 0.95, green: 0.93, blue: 0.90, alpha: 1.0) : // #F2EDE6
            NSColor(red: 0.20, green: 0.18, blue: 0.16, alpha: 1.0)   // #332E29
    })
}
