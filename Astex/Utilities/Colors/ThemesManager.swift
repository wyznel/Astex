//
//  ColorManager.swift
//  Astex
//
//  Created by Ben Herbert on 06/09/2026.
//
import SwiftUI

class ThemesManager {
    
    static let shared = ThemesManager()
    
    @ObservedObject var settings = Settings.shared
    
    func getBackgroundColour() -> Color {
        switch settings.colourTheme {
        case .sepia:
            return .sepiaBackground
        case .forest:
            return .forestBackground
        }
    }
    
    func getTextColour() -> Color {
        switch settings.colourTheme {
        case .sepia:
            return .sepiaText
        case .forest:
            return .forestText
        }
    }
    
    func getSurfaceColour() -> Color {
        switch settings.colourTheme {
        case .sepia:
            return .sepiaSurface
        case .forest:
            return .forestSurface
        }
    }
    
    func getAccentColour() -> Color {
        switch settings.colourTheme {
        case .sepia:
            return .sepiaAccent
        case .forest:
            return .forestAccent
        }
    }
}
