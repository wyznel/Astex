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
        VStack(spacing: 10) {
            LightDarkModePickerView()
            Divider()
            ToggleBackgroundImageView()
            ThemePickerView()
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
    
    struct LightDarkModePickerView: View {

        @ObservedObject var settings = Settings.shared

        var body: some View {
            HStack(spacing: 12) {
                ForEach(AppearanceOption.allCases) { option in
                    let isSelected = settings.lightScheme.rawValue == option.rawValue

                    Button {
                        
                        var userAppearanceChoice: AppearanceOption = option
                        
                        /// Certain themes have locked light/dark modes. This locks the selection whilst one of those themes is enabled.
                        let isThemeLockedToAppearance: AppearanceOption = ThemesManager.shared.checkThemePrefferedLightScheme(settings.colourTheme.theme)
                        if isThemeLockedToAppearance != .system {
                            userAppearanceChoice = isThemeLockedToAppearance
                        }
                        
                        withAni {
                            settings.lightScheme = userAppearanceChoice
                        }
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: option.systemImage)
                                .font(.system(size: 15, weight: .regular))
                                .symbolRenderingMode(.monochrome)

                            Text(option.title)
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundStyle(ThemesManager.shared.getTextColour().opacity(0.8))
                        .frame(maxWidth: .infinity, minHeight: 108)
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(ThemesManager.shared.getSurfaceColour().opacity(0.55))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    ThemesManager.shared.getTextColour().opacity(isSelected ? 0.65 : 0.1),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        }
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 11)
                                    .inset(by: 3)
                                    .stroke(ThemesManager.shared.getTextColour().opacity(0.12), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(option.title) appearance")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .frame(maxWidth: 600)
            .animation(.spring(duration: settings.animationDelay), value: settings.lightScheme)
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
                        settings.colourTheme = .sepia
                        isResetIconRotated = false
                    } label: {
                        Image(systemName: "arrow.trianglehead.counterclockwise")
                            .foregroundStyle(ThemesManager.shared.getAccentColour())
                            .rotationEffect(.degrees(isResetIconRotated ? -360 : 0))
                    }
                    .buttonStyle(.plain)
                    .tooltip(delay: 1.0, offsetX: 75) {
                        Text("Reset to default theme (Sage)")
                            .fixedSize()
                    }

                    Picker("Colour Theme", selection: $settings.colourTheme) {
                        ForEach(ColourThemes.allCases, id: \.self) { theme in
                            Text(theme.theme.raw)
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
