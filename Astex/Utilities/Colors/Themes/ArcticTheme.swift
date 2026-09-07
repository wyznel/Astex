//
//  ArcticTheme.swift
//  Astex
//
//  Created by Ben Herbert on 07/09/2026.
//
import SwiftUI

struct ArcticTheme: CustomTheme {
    let raw = "Arctic"
    let background = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0.043, green: 0.086, blue: 0.137, alpha: 1.0) // #0B1623
            : NSColor(red: 0.93, green: 0.97, blue: 1.0, alpha: 1.0)
    })
    let surface = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0.086, green: 0.196, blue: 0.290, alpha: 1.0) // #16324A
            : NSColor(red: 0.84, green: 0.92, blue: 0.98, alpha: 1.0)
    })
    let accent = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0.431, green: 0.788, blue: 0.925, alpha: 1.0) // #6EC9EC
            : NSColor.systemBlue
    })
    let text = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0.914, green: 0.965, blue: 1.0, alpha: 1.0) // #E9F6FF
            : NSColor.black
    })
}
