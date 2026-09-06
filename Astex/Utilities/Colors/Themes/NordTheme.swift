//
//  NordTheme.swift
//  Astex
//
//  Created by Ben Herbert on 06/09/2026.
//

import SwiftUI

/// Nord theme
extension Color {

    /// The Polar Night background stays dark in all appearance modes.
    static let nordBackground = Color(
        red: 0.180,
        green: 0.204,
        blue: 0.251
    ) // #2E3440

    /// The lighter Polar Night surface separates cards from the background.
    static let nordSurface = Color(
        red: 0.231,
        green: 0.259,
        blue: 0.322
    ) // #3B4252

    /// The Frost blue accent adds an icy highlight.
    static let nordAccent = Color(
        red: 0.533,
        green: 0.753,
        blue: 0.816
    ) // #88C0D0

    /// The bright Snow Storm color keeps text clear on dark surfaces.
    static let nordText = Color(
        red: 0.925,
        green: 0.937,
        blue: 0.957
    ) // #ECEFF4
}
