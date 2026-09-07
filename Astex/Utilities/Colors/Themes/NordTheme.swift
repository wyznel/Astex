//
//  NordTheme.swift
//  Astex
//
//  Created by Ben Herbert on 06/09/2026.
//

import SwiftUI

struct NordTheme: CustomTheme {
    let raw = "Nord"
    let background: Color = Color(
        red: 0.180,
        green: 0.204,
        blue: 0.251
    ) // #2E3440
    let surface: Color = Color(
        red: 0.231,
        green: 0.259,
        blue: 0.322
    ) // #3B4252
    let text: Color = Color(
        red: 0.925,
        green: 0.937,
        blue: 0.957
    ) // #ECEFF4
    let accent: Color = Color(
        red: 0.533,
        green: 0.753,
        blue: 0.816
    ) // #88C0D0
    
    let preferredAppearance: AppearanceOption = .dark
}
