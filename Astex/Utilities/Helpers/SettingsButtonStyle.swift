import SwiftUI

enum SettingsButtonRole {
    case normal
    case destructive
}

private struct SettingsGlassButtonModifier: ViewModifier {
    @ObservedObject private var settings = Settings.shared

    let role: SettingsButtonRole
    let isIconOnly: Bool

    private var foregroundColor: Color {
        switch role {
        case .normal:
            ThemesManager.shared.getTextColour()
        case .destructive:
            .red
        }
    }

    private var glassTint: Color {
        ThemesManager.shared.getSurfaceColour()
            .opacity(settings.isBackgroundImageEnabled ? 0.55 : 0.2)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if isIconOnly {
            content
                .buttonStyle(.plain)
                .foregroundStyle(foregroundColor)
                .frame(width: 32, height: 32)
                .contentShape(Circle())
                .glassEffect(
                    settings.glassEffect.tint(glassTint),
                    in: .circle
                )
        } else {
            content
                .buttonStyle(.plain)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 12)
                .frame(minHeight: 32)
                .contentShape(Capsule())
                .glassEffect(
                    settings.glassEffect.tint(glassTint),
                    in: .capsule
                )
        }
    }
}

extension View {
    func settingsIconButtonStyle(
        role: SettingsButtonRole = .normal
    ) -> some View {
        modifier(SettingsGlassButtonModifier(role: role, isIconOnly: true))
    }

    func settingsButtonStyle(
        role: SettingsButtonRole = .normal
    ) -> some View {
        modifier(SettingsGlassButtonModifier(role: role, isIconOnly: false))
    }
}
