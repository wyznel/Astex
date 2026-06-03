import SwiftUI

@main
struct Liberty_Swift: App {

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
      ContentView()
    }
  }
}
