//
//  ColorSkeleton.swift
//  Astex
//
//  Created by Ben Herbert on 07/09/2026.
//
import SwiftUI

protocol CustomTheme {
    var raw: String { get }
    var background: Color { get }
    var surface: Color { get }
    var accent: Color { get }
    var text: Color { get }
    
    var preferredAppearance: AppearanceOption { get }
}

extension CustomTheme {
    var preferredAppearance: AppearanceOption {
        .system
    }
}
