//
//  AstexApp.swift
//  Astex
//
//  Created by Ben Herbert on 15/06/2026.
//

import SwiftUI
import SwiftData

@main
struct AstexApp: App {
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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(Settings.shared.colorScheme)
                .frame(minWidth: 1000, minHeight: 512)
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .tint(.sepiaAccent)
        }
        .commands {
            // Populate here.
        }
        .modelContainer(sharedModelContainer)
    }
}
