//
//  SettingsParentView.swift
//  Astex
//
//  Created by Ben Herbert on 22/06/2026.
//

import SwiftData
import SwiftUI
import Textual

struct SettingsSidebarView: View {
    @Binding var selectedTab: Int
    @ObservedObject private var settings = Settings.shared

    
    var body: some View {
        VStack(spacing: 8) {
            DefaultButton(text: "Back to Chats", imageShape: "arrowshape.turn.up.backward") {
                withAni(doubled: true) {
                    settings.settingsOpened = false
                }
            }

            Divider()

            SettingsSidebarTabButton(
                title: "Models",
                icon: "server.rack",
                tabID: 1,
                selectedTab: $selectedTab
            )

            SettingsSidebarTabButton(
                title: "Settings",
                icon: "gearshape",
                tabID: 2,
                selectedTab: $selectedTab
            )

            SettingsSidebarTabButton(
                title: "Appearance",
                icon: "pencil",
                tabID: 3,
                selectedTab: $selectedTab
            )

            Spacer()
            
            SettingsSidebarTabButton(
                title: "Settings",
                icon: "gearshape",
                tabID: -1,
                selectedTab: $selectedTab
                
            )
        }
        .padding()
        .selectionDisabled()
    }
}

struct SettingsSidebarTabButton: View {
    let title: String
    let icon: String
    let tabID: Int
    @Binding var selectedTab: Int
    @ObservedObject private var settings = Settings.shared

    @State private var hovered: Bool = false

    var body: some View {
        Button {
            withAni {
                if tabID == -1 {
                    settings.settingsOpened = false
                }else {
                    selectedTab = tabID
                }
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .padding(6)
                Text(title)
                Spacer()
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .frame(height: 30)
        }
        .glassEffect(
            hovered || selectedTab == tabID
            ? settings.glassEffect.tint(ThemesManager.shared.getAccentColour().opacity(0.3))
            : settings.glassEffect.tint(ThemesManager.shared.getAccentColour().opacity(0.125)),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .animation(.spring(duration: settings.animationDelay), value: hovered)
        .animation(.spring(duration: settings.animationDelay), value: selectedTab)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .buttonStyle(.plain)
        .onHover { isHovered in
            hovered = isHovered
        }
    }
}

struct SettingsDetailView: View {
    let selectedTab: Int
    @ObservedObject private var settings = Settings.shared

    private let themesManager = ThemesManager.shared
    
    var body: some View {
        VStack {
            switch selectedTab {
            case 1:
                ModelManagementView()
            case 2:
                SettingsTabView()
            case 3:
                AppearanceTabView()
            default:
                Text("Invalid")
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if settings.isBackgroundImageEnabled {
                Image(settings.background.bg.fileName)
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
                    .blur(radius: 30, opaque: true)
                    .opacity(0.6)
            } else{
                themesManager.getBackgroundColour()
                    .ignoresSafeArea()
            }
        }
    }
}

struct SettingsView: View {
    var selectedTab: Int = 1

    var body: some View {
        SettingsDetailView(selectedTab: selectedTab)
    }
}
