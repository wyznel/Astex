//
//  DefaultButton.swift
//  Astex
//
//  Created by Ben Herbert on 31/07/2026.
//
import SwiftUI

struct DefaultButton: View {
    @ObservedObject private var settings = Settings.shared
    let text: String
    let imageShape: String
    let action: () -> Void
    
    @State private var hovered: Bool = false
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: imageShape)
                    .padding(6)
                Text(text)
                Spacer()
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .frame(height: 30)
        }
        .glassEffect(
            hovered
            ? settings.glassEffect.tint(ThemesManager.shared.getAccentColour().opacity(0.3))
            : settings.glassEffect.tint(ThemesManager.shared.getAccentColour().opacity(0.125)),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .animation(.spring(duration: settings.animationDelay), value: hovered)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .buttonStyle(.plain)
        .onHover { isHovered in
            hovered = isHovered
        }
    }
}
