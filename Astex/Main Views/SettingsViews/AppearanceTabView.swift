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
        VStack(spacing: 10 ) {
            ToggleBackgroundImageView()
            ThemePickerView()
            
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
    
    struct ToggleBackgroundImageView: View {
        
        @ObservedObject var settings = Settings.shared
        
        var body: some View {
            
            VStack(alignment: .leading) {
                Text("Toggle Background Image in Main Area")
                    .font(.headline)

                HStack(spacing: 12) {
                    Text("Enable / Disable")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)
                    
                    Toggle("Use background image", isOn: $settings.isBackgroundImageEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
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
    
    struct ThemePickerView: View {
        
        @ObservedObject private var settings = Settings.shared
        @State private var isResetIconRotated = false
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("Choose Colour Theme")
                    .font(.headline)

                HStack(spacing: 12) {
                    Text("Theme")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    Button {
                        withAni {
                            isResetIconRotated = true
                        }
                        settings.colourTheme = .forest
                        isResetIconRotated = false
                    } label: {
                        Image(systemName: "arrow.trianglehead.counterclockwise")
                            .foregroundStyle(ThemesManager.shared.getAccentColour())
                            .rotationEffect(.degrees(isResetIconRotated ? -360 : 0))
                    }
                    .buttonStyle(.plain)
                    .tooltip(delay: 1.0, offsetX: 75) {
                        Text("Reset to default theme (forest)")
                            .fixedSize()
                    }

                    Picker("Engine", selection: $settings.colourTheme) {
                        ForEach(ColourThemes.allCases, id: \.self) { theme in
                            Text(theme.rawValue)
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(.primary)
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
    
}
