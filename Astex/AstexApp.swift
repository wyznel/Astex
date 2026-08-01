//
//  AstexApp.swift
//  Astex
//
//  Created by Ben Herbert on 15/06/2026.
//

import SwiftUI
import SwiftData
import Sparkle
import UserNotifications

@main
struct AstexApp: App {
    
    @AppStorage("IsFirstOpen") private var isFirstOpen: Bool = true
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Chat.self,
            Message.self
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    
    init() {
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            
            if !isFirstOpen {
                ContentView()
                    .frame(minWidth: 1000, minHeight: 512)
                    .toolbar(removing: .title)
                    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                    .tint(.sepiaAccent)
            }else {
                OnboardingView()
                    .frame(minWidth: 750, minHeight: 512)
                    .toolbar(removing: .title)
                    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                    .tint(.sepiaAccent)
                    .windowResizeBehavior(.disabled)
                    .preferredColorScheme(.dark)
            }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates..."){
                    updaterController.updater.checkForUpdates()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
