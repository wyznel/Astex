import SwiftUI

struct ContentView: View {
  @State private var tracker = 0  //0 for framedemo1, 1 for framedemo2

  var body: some View {
    FrameDemo().preferredColorScheme(.light)
  }
}
