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
    
    func checkThemePrefferedLightScheme(_ theme: ColourThemes) -> AppearanceOption {
        switch theme {
        case .sepia, .forest:
            return .system
        case .nord:
            return .dark
        }
    }
    
    func getBackgroundColour() -> Color {
        switch settings.colourTheme {
        case .sepia:
            return .sepiaBackground
        case .forest:
            return .forestBackground
        case .nord:
            return .nordBackground
        }
    }
    
    func getTextColour() -> Color {
        switch settings.colourTheme {
        case .sepia:
            return .sepiaText
        case .forest:
            return .forestText
        case .nord:
            return .nordText
        }
    }
    
    func getSurfaceColour() -> Color {
        switch settings.colourTheme {
        case .sepia:
            return .sepiaSurface
        case .forest:
            return .forestSurface
        case .nord:
            return .nordSurface
        }
    }
    
    func getAccentColour() -> Color {
        switch settings.colourTheme {
        case .sepia:
            return .sepiaAccent
        case .forest:
            return .forestAccent
        case .nord:
            return .nordAccent
        }
    }
}
