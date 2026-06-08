import SwiftData
import SwiftUI

struct Sidebar: View {
  @ObservedObject private var settings = Settings.shared

  /// Called when the user clicks on "New Chat".
  var onNewChat: () -> Void

  //Called when user clicks on delete in context menu of a chat
  var onDeleteChat: (Chat) -> Void

  @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]
  // Called when user clicks on a savec chat.
  var onSelectChat: (Chat) -> Void

  static let animationDelay = 0.25

  @State private var isHovered: Bool = false
  @State private var isNewChatButtonHovered: Bool = false

  init(
    onNewChat: @escaping () -> Void, onSelectChat: @escaping (Chat) -> Void,
    onDeleteChat: @escaping (Chat) -> Void
  ) {
    self.onNewChat = onNewChat
    self.onSelectChat = onSelectChat
    self.onDeleteChat = onDeleteChat
  }

  var body: some View {
    VStack {
      // Pin / unpin toggle
      Button {
        settings.holdSideBarMenuOpen.toggle()
        if !settings.holdSideBarMenuOpen {
          withAnimation(.spring(duration: Sidebar.animationDelay)) {
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
      .animation(.spring(duration: Sidebar.animationDelay), value: settings.holdSideBarMenuOpen)

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
      .buttonStyle(ChatRowButtonStyle())

      // saved chats section.

      SavedChats()

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
    .animation(.spring(duration: Sidebar.animationDelay), value: isHovered)
  }

  @ViewBuilder
  func SavedChats() -> some View {
    ForEach(chats) { chat in
      Button {
        onSelectChat(chat)
      } label: {
        HStack {
          Image(systemName: "bubble.left")
          if isHovered || settings.holdSideBarMenuOpen {
            Text(chat.title)
              .lineLimit(1)
              .truncationMode(.tail)
            Spacer()
          }
        }
      }
      .contextMenu(menuItems: {
        Button("Delete", systemImage: "delete.backward") {
          //Delete chat
          onDeleteChat(chat)
        }
      })
      .buttonStyle(ChatRowButtonStyle())
    }
  }

  struct ChatRowButtonStyle: ButtonStyle {
    @State private var isHovered: Bool = false
    func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .padding(2)
        .buttonStyle(.plain)
        .background(
          isHovered ? Color.gray.opacity(0.2) : Color.clear,
          in: RoundedRectangle(cornerRadius: 6)
        )
        .onHover { isHovered = $0 }
        .animation(.spring(duration: Sidebar.animationDelay), value: isHovered)

    }
  }
}
