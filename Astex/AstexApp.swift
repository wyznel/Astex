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
    private static let isTesting = ProcessInfo.processInfo.environment["ASTEX_TESTING"] == "1"
    
    @ObservedObject private var settings = Settings.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Chat.self,
            Message.self
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: Self.isTesting)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: !Self.isTesting,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    
    init() {
        if !Self.isTesting { NotificationManager.shared.requestAuthorization() }
    }
    
    private var preferredScheme: ColorScheme? {
        switch settings.lightScheme {
        case .light:
            return .light
        case .dark:
            return .dark
        default:
            return nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            
            Group {
                if Self.isTesting {
                    EmptyView()
                } else if !settings.isFirstOpen {
                    ContentView()
                        .frame(minWidth: 1000, minHeight: 512)
                        .toolbar(removing: .title)
                        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                        .tint(ThemesManager.shared.getAccentColour())
                } else {
                    OnboardingView()
                        .frame(minWidth: 750, minHeight: 512)
                        .toolbar(removing: .title)
                        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                        .tint(ThemesManager.shared.getAccentColour())
                        .windowResizeBehavior(.disabled)
                }
            }
            .preferredColorScheme(preferredScheme)
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
