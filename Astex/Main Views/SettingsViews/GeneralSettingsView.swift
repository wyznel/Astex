//
//  SettingsTabView.swift
//  Astex
//
//  Created by Ben Herbert on 15/07/2026.
//

import SwiftUI

struct SettingsTabView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        VStack {
            
            DefaultSettingsRow(title: "Messages", subtitle: "Show tool calls in chat"){
                Toggle("Show Tool Call Messages", isOn: !$settings.hideToolCallMessage)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            
            Divider()
            
            Button {
                if let bundleID = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundleID)
                }
                settings.settingsOpened = false
                settings.suppressModelDeletionConfirmation = false
                settings.showSizeOnDisk = true
                settings.showFormat = true
                settings.showParameterSize = true
                settings.isFirstOpen = true
                settings.selectedEngine = .ollama
            } label: {
                Label("Reset all settings", systemImage: "arrow.up.trash")
            }
            .settingsButtonStyle(role: .destructive)
            
            
        }
    }
}
