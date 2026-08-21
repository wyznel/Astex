//
//  AppearanceTabView.swift
//  Astex
//
//  Created by Ben Herbert on 18/07/2026.
//
import SwiftUI
import Textual

struct AppearanceTabView: View {
    
    @State var isOn: Bool = false
    
    @ObservedObject private var settings = Settings.shared
    
    var body: some View {

        HStack(spacing: 12) {
            Text("Use background image")
                .font(.headline.weight(.medium))
                .foregroundStyle(.primary)
                .labelStyle(.titleAndIcon)

            Spacer(minLength: 8)

            Toggle("Use background image", isOn: $settings.isBackgroundImageEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(settings.glassEffect.tint(Color.sepiaBackground.opacity(0.5)), in: .rect(cornerRadius: 10))
        .frame(maxWidth: 600)
        
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
