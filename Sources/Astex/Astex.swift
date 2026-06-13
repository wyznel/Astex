import SwiftData
import SwiftUI

@main
struct Astex: App {
    
    init() {
#if os(macOS)
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
#endif
    }
    var body: some Scene {
        WindowGroup {
            MainWindow()
                .preferredColorScheme(Settings.shared.colorScheme)
                .frame(minWidth: 1000, minHeight: 512)
        }
        .modelContainer(for: [Chat.self, Message.self])
        .windowStyle(.hiddenTitleBar)
        .windowBackgroundDragBehavior(.enabled)
    
    }
}

