//
//  DefaultButton.swift
//  Astex
//
//  Created by Ben Herbert on 31/07/2026.
//
import SwiftUI

struct DefaultButton: View {
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
                ? Settings.shared.glassEffect.tint(Color.sepiaAccent.opacity(0.3))
                : Settings.shared.glassEffect.tint(Color.sepiaAccent.opacity(0.125)),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .animation(.spring(duration: Settings.shared.animationDelay), value: hovered)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .buttonStyle(.plain)
        .onHover { isHovered in
            hovered = isHovered
        }
    }
}
