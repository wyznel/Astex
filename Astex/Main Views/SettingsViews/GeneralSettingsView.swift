//
//  SettingsTabView.swift
//  Astex
//
//  Created by Ben Herbert on 15/07/2026.
//

import SwiftUI

struct SettingsTabView: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.appearsActive) var appearsActive

    var body: some View {
        VStack {
            
            DefaultSettingsRow(title: "Notifications", subtitle: "Show Notifications when a model has finished downloading") {
                Toggle("blank", isOn: $settings.showModelDownloadCompleteNotifications)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            
            DefaultSettingsRow(title: "Test", subtitle: "Send test notification") {
                Button {
                    sendNotification(title: "Test Notification", body: "External test notification")
                }label: {
                    Text("Send")
                }
            }
            
            DefaultSettingsRow(title: "Messages", subtitle: "Show tool calls in chat"){
                Toggle("Show Tool Call Messages", isOn: !$settings.hideToolCallMessage)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            
            DefaultSettingsRow(title: "", subtitle: "Launch at Login") {
                Toggle("", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.setLaunchAtLogin($0) }
                ))
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            .onAppear {
                settings.refreshLaunchAtLogin()
            }
            .onChange(of: appearsActive) { _, newValue in
                guard newValue else { return }
                settings.refreshLaunchAtLogin()
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
