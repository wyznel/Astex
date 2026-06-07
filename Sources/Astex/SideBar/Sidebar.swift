import SwiftUI

struct Sidebar: View {
  @ObservedObject private var settings = Settings.shared

  /// Called when the user taps "New Chat".
  var onNewChat: () -> Void

  private let animationDelay = 0.25

  @State private var isHovered: Bool = false
  @State private var isNewChatButtonHovered: Bool = false

  var body: some View {
    VStack {
      // Pin / unpin toggle
      Button {
        settings.holdSideBarMenuOpen.toggle()
        if !settings.holdSideBarMenuOpen {
          withAnimation(.spring(duration: animationDelay)) {
            isHovered = false
          }
        }
      } label: {
        Image(
          systemName: settings.holdSideBarMenuOpen
            ? "inset.filled.square" : "inset.filled.leftthird.square"
        )
        .contentShape(RoundedRectangle(cornerRadius: 6))
      }
      .padding(2)
      .buttonStyle(.plain)
      .animation(.spring(duration: animationDelay), value: settings.holdSideBarMenuOpen)

      Divider()

      // New Chat
      Button {
        withAnimation(.spring(duration: 0.5)) {
          onNewChat()
        }
      } label: {
        HStack {
          Image(systemName: "square.and.pencil")
            .contentShape(RoundedRectangle(cornerRadius: 6))
          if isHovered || settings.holdSideBarMenuOpen {
            Text("New Chat")
            Spacer()
          }
        }
      }
      .padding(2)
      .buttonStyle(.plain)
      .background(
        isNewChatButtonHovered ? Color.gray.opacity(0.2) : Color.clear,
        in: RoundedRectangle(cornerRadius: 6)
      )
      .onHover { isNewChatButtonHovered = $0 }
      .animation(.spring(duration: animationDelay), value: isNewChatButtonHovered)

      Spacer()

      // Settings (placeholder)
      HStack {
        Image(systemName: "gearshape")
        if isHovered || settings.holdSideBarMenuOpen {
          Text("Settings")
          Spacer()
        }
      }
      .frame(width: 100)
    }
    .frame(width: (isHovered || settings.holdSideBarMenuOpen) ? 115 : 25)
    .contentShape(Rectangle())
    .onHover { isHovered = $0 }
    .selectionDisabled()
    .padding()
    .glassEffect(settings.glassEffect, in: .rect(cornerRadius: 6))
    .padding(.vertical, 50)
    .animation(.spring(duration: animationDelay), value: isHovered)
  }
}
