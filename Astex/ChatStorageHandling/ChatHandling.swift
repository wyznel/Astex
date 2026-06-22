//
//  ChatHandling.swift
//  Astex
//
//  Created by Ben Herbert on 16/06/2026.
//
import SwiftData
import SwiftUI
import Textual

struct ChatActionHandling: View {
    @ObservedObject private var settings = Settings.shared
    
    var onDeleteChat: (Chat) -> Void
    var onSelectChat: (Chat) -> Void
    var onNewChat: () -> Void
    
    @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]
    
    @State private var editingChatTitleID: Chat.ID? = nil
    @FocusState private var editTitleFocused: Bool
    
    init (
        onNewChat: @escaping () -> Void, onSelectChat: @escaping (Chat) -> Void, onDeleteChat: @escaping (Chat) -> Void
    ) {
        self.onNewChat = onNewChat
        self.onSelectChat = onSelectChat
        self.onDeleteChat = onDeleteChat
    }
    
    
    var body: some View {
        VStack {
            Button {
                withAnimation(.spring(duration: settings.animationDelay*2)){
                    onNewChat()
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("New Chat")
                    Spacer()
                }
            }
            Divider()
            
            ScrollView {
                VStack(spacing: 8) {
                    SavedChats()
                }
            }
            
            Spacer()
            Button {
                print("Opened Settings Menu")
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings")
                    Spacer()
                }
            }
        }
        .padding()
        .selectionDisabled()
        
    }
    
    @State private var newChatTitleName: String = ""
    
    @ViewBuilder
    func SavedChats() -> some View {
        ForEach(chats) { chat in
            VStack {
                if editingChatTitleID == chat.id {
                    TextEditor(text: $newChatTitleName)
                        .padding(2)
                        .background(.clear)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .scrollDisabled(true)
                        .fixedSize(horizontal: false, vertical: false)
                        .frame(maxWidth: .infinity, maxHeight: 20)
                        .onKeyPress(keys: [.return], phases: .down) { keyPress in
                            if keyPress.modifiers.contains(.shift) {
                                return .ignored
                            }
                            guard !newChatTitleName.isEmpty else {return .handled}
                            chat.title = newChatTitleName
                            editingChatTitleID = nil
                            return .handled
                        }
                        .onKeyPress(keys: [.escape], phases: .down) { keyPress in
                            editingChatTitleID = nil
                            return .handled
                        }
                        .overlay(alignment: .leading) {
                            if newChatTitleName.isEmpty {
                                InlineText(markdown: chat.title)
                                    .font(.body)
                                    .foregroundColor(Color(nsColor: .placeholderTextColor))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 14)
                                    .allowsHitTesting(false)
                            }
                        }
                        .focused($editTitleFocused)
                        .onAppear {
                            DispatchQueue.main.async {
                                self.editTitleFocused = true
                            }
                        }
                } else {
                    Button {
                        onSelectChat(chat)
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left")
                            InlineText(markdown: chat.title)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .allowsHitTesting(false)
                            Spacer()
                        }.contentShape(Rectangle())
                    }
                    .contextMenu(menuItems: {
                        Button("Delete", systemImage: "delete.backward") {
                            onDeleteChat(chat)
                        }
                        Button("Edit Title", systemImage: "pencil") {
                            newChatTitleName = chat.title
                            editingChatTitleID = chat.id
                        }
                    })
                    .buttonStyle(ChatRowButtonStyle())
                }
            }
        }
        .animation(.spring(duration: Settings.shared.animationDelay), value: chats)
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
                .animation(.spring(duration: Settings.shared.animationDelay), value: isHovered)
            
        }
    }
    
}
