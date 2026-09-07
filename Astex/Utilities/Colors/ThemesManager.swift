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
    
    func checkThemePrefferedLightScheme(_ theme: CustomTheme) -> AppearanceOption {
        return theme.preferredAppearance
    }
    
    func getBackgroundColour() -> Color {
        return settings.colourTheme.theme.background
    }
    func getTextColour() -> Color {
        return settings.colourTheme.theme.text
    }
    func getSurfaceColour() -> Color {
        return settings.colourTheme.theme.surface
    }
    
    func getAccentColour() -> Color {
        return settings.colourTheme.theme.accent
    }
    
//    func getBackgroundColour() -> Color {
//        switch settings.colourTheme {
//        case .sepia:
//            return .sepiaBackground
//        case .sage:
//            return .sageBackground
//        case .nord:
//            return .nordBackground
//        }
//    }
//    
//    func getTextColour() -> Color {
//        switch settings.colourTheme {
//        case .sepia:
//            return .sepiaText
//        case .sage:
//            return .sageText
//        case .nord:
//            return .nordText
//        }
//    }
//    
//    func getSurfaceColour() -> Color {
//        switch settings.colourTheme {
//        case .sepia:
//            return .sepiaSurface
//        case .sage:
//            return .sageSurface
//        case .nord:
//            return .nordSurface
//        }
//    }
//    
//    func getAccentColour() -> Color {
//        switch settings.colourTheme {
//        case .sepia:
//            return .sepiaAccent
//        case .sage:
//            return .sageAccent
//        case .nord:
//            return .nordAccent
//        }
//    }
    
    
    func setTheme(_ newTheme: ColourThemes) {
        settings.colourTheme = newTheme
    }
}
