//
//  AppearanceTabView.swift
//  Astex
//
//  Created by Ben Herbert on 18/07/2026.
//
import SwiftUI
import Textual

struct AppearanceTabView: View {
    
    var body: some View {
        StructuredText(markdown:
            """
            ```
            \n
            This page is currently under construction.
            Check ROADMAP.md to view future updates.
            \n
            ```
            """)
        .frame(maxWidth: 600)
    }
}
