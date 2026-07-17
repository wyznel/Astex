//
//  SettingsTabView.swift
//  Astex
//
//  Created by Ben Herbert on 15/07/2026.
//

import SwiftUI

struct SettingsTabView: View {
    
    private var settings = Settings.shared
    
    var body: some View {
        VStack {
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
                
            }label: {
                Label("Reset to all app defaults.", systemImage: "arrow.up.trash")
            }
        }
    }
}
