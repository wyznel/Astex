//
//  SettingsView.swift
//  Astex
//
//  Created by Ben Herbert on 22/06/2026.
//

import SwiftData
import SwiftUI
import Textual

struct SettingsView: View {
    private var settings = Settings.shared
    @State private var selectedTab = 1
    var body: some View {
        VStack {
            HStack(spacing: 20) {
                TabButton(icon: "arrowshape.turn.up.backward", opacity: 0.125, pageID: 0, selectedTab: $selectedTab) {
                    withAni(doubled: true) {
                        settings.settingsOpened = false
                    }
                }
                
                HStack(spacing: 0) {
                    TabButton(
                        icon: "server.rack",
                        opacity: 0.0625,
                        shape: Rectangle(),
                        pageID: 1,
                        selectedTab: $selectedTab
                    )
                    {
                        withAni {
                            selectedTab = 1
                        }
                    }
                    TabButton(
                        icon: "gearshape",
                        opacity: 0.0625,
                        shape: Rectangle(),
                        pageID: 2,
                        selectedTab: $selectedTab
                    )
                    {
                        withAni {
                            selectedTab = 2
                        }
                    }
                    TabButton(
                        icon: "pencil",
                        opacity: 0.0625,
                        shape: Rectangle(),
                        pageID: 3,
                        selectedTab: $selectedTab
                    ) {
                        withAni {
                            selectedTab = 3
                        }
                    }
                }
                .glassEffect(.regular.tint(Color.sepiaAccent.opacity(0.0625)))
                .clipShape(Capsule())
            }
            .padding(12)

            Divider()
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

        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sepiaBackground)

    }

    @ViewBuilder
    func appearance() -> some View {
        Text("Appearance Tab")
    }

    struct TabButton: View {
        let icon: String
        let opacity: Double
        var shape: AnyShape
        let action: () -> Void
        let pageID: Int
        
        @Binding var selectedTab: Int
        
        init(
            icon: String,
            opacity: Double,
            shape: some Shape = Capsule(),
            pageID: Int,
            selectedTab: Binding<Int>,
            action: @escaping () -> Void
        ) {
            self.icon = icon
            self.shape = AnyShape(shape)
            self.action = action
            self.opacity = opacity
            self.pageID = pageID
            self._selectedTab = selectedTab
        }

        @State private var hovered: Bool = false

        var body: some View {
            Button {
                action()
            } label: {
                Image(systemName: icon)
                    .padding(6)
                    .frame(width: 50, height: 30)
                    .contentShape(shape)
            }
            .glassEffect(
                hovered || selectedTab == pageID ? .
                    regular.tint(Color.sepiaAccent.opacity(0.3)) :
                    .regular.tint(Color.sepiaAccent.opacity(opacity)),
                in: shape
            )
            .animation(.spring(duration: 0.25), value: hovered)
            .clipShape(shape)
            .contentShape(shape)
            .buttonStyle(.plain)
            .onHover { isHovered in
                hovered = isHovered
            }
        }
    }

}
