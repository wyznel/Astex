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
      ContentView()
    }
  }
}
