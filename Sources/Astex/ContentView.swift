import SwiftUI

struct ContentView: View {
  var body: some View {
    MainWindow()
      .preferredColorScheme(Settings.shared.colorScheme)
      .toolbar(removing: .title)
      .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
      .frame(minWidth: 1000, minHeight: 512)
  }
}
