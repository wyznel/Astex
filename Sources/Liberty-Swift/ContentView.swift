import SwiftUI

struct ContentView: View {
  @State private var tracker = 0

  var body: some View {
    MainWindow().preferredColorScheme(.light)
  }
}
