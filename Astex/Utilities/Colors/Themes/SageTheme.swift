//
//  ForestTheme.swift
//  Astex
//
//  Created by Ben Herbert on 06/09/2026.
//

import SwiftUI

struct SageTheme: CustomTheme {
    let raw = "Sage"
    
    let background: Color = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ?
            NSColor(red: 0.071, green: 0.125, blue: 0.094, alpha: 1.0) : // #122018
            NSColor(red: 0.957, green: 0.953, blue: 0.925, alpha: 1.0)   // #F4F3EC
    })
    
    let surface: Color = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ?
            NSColor(red: 0.114, green: 0.188, blue: 0.141, alpha: 1.0) : // #1D3024
            NSColor(red: 0.906, green: 0.914, blue: 0.867, alpha: 1.0)   // #E7E9DD
    })
    
    let text: Color = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ?
            NSColor(red: 0.910, green: 0.941, blue: 0.906, alpha: 1.0) : // #E8F0E7
            NSColor(red: 0.133, green: 0.188, blue: 0.153, alpha: 1.0)   // #223027
    })
    
    let accent: Color = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ?
            NSColor(red: 0.471, green: 0.725, blue: 0.537, alpha: 1.0) : // #78B989
            NSColor(red: 0.278, green: 0.447, blue: 0.333, alpha: 1.0)   // #477255
    })
}
