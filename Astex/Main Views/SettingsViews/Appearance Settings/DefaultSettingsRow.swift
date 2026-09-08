//
//  DefaultSettingsRwo.swift
//  Astex
//
//  Created by Ben Herbert on 08/09/2026.
//

import SwiftUI

struct DefaultSettingsRow<Content: View>: View {
    
    @ObservedObject private var settings =  Settings.shared
    
    let title: String
    let subtitle: String
    let content: () -> Content
    
    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title)")
                .font(.headline)

            HStack(spacing: 12) {
                Text("\(subtitle)")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)
                
                content()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassEffect(
                settings.glassEffect.tint(ThemesManager.shared.getBackgroundColour().opacity(0.5)),
                in: .rect(cornerRadius: 10)
            )
            .frame(maxWidth: 600)
        }
    }
}
