//
//  Sidebar.swift
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
    var getNewTitle: (Chat) -> Void
    
    @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]
    
    @State private var editingChatTitleID: Chat.ID? = nil
    @FocusState private var editTitleFocused: Bool
    
    init (
        onNewChat: @escaping () -> Void,
        onSelectChat: @escaping (Chat) -> Void,
        onDeleteChat: @escaping (Chat) -> Void,
        getNewTitle: @escaping (Chat) -> Void
    ) {
        self.onNewChat = onNewChat
        self.onSelectChat = onSelectChat
        self.onDeleteChat = onDeleteChat
        self.getNewTitle = getNewTitle
    }
    
    
    var body: some View {
        VStack {
            
            DefaultButton(text: "New Chat", imageShape: "square.and.pencil") {
                withAni {
                    onNewChat()
                }
            }
    
            Divider()
            
            ScrollView {
                VStack(spacing: 8) {
                    SavedChats()
                }
            }
            
            Spacer()
            Divider()
            DefaultButton(text: "Settings", imageShape: "gearshape"){
                withAni {
                    settings.settingsOpened.toggle()
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
                    
                    ChatButton(
                        chat: chat,
                        onSelectChat: onSelectChat,
                        onDeleteChat: onDeleteChat,
                        getNewTitle: getNewTitle,
                        editTitle: {
                            newChatTitleName = chat.title
                            editingChatTitleID = chat.id
                        }
                    )
                }
            }
        }
        .animation(.spring(duration: Settings.shared.animationDelay), value: chats)
    }
    
    struct ChatButton: View {
        
        var chat: Chat
        
        @State private var showDeleteChatButton: Bool = false
        @State private var showThreeDots: Bool = false
        
        var onSelectChat: (Chat) -> Void
        var onDeleteChat: (Chat) -> Void
        var getNewTitle: (Chat) -> Void
        var editTitle: () -> Void
        
        var body: some View {
            HStack {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "bubble.left")
                        InlineText(markdown: chat.title)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .allowsHitTesting(false)
                        Spacer()
                        
                        if showThreeDots {
                            Menu {
                                Button("Edit title", systemImage: "pencil") {
                                    editTitle()
                                }
                                .labelStyle(.titleAndIcon)
                                Button("Generate title", systemImage: "bolt.horizontal") {
                                    getNewTitle(chat)
                                }
                                .labelStyle(.titleAndIcon)
                                Divider()
                                Button("Delete...", systemImage: "delete.backward") {
                                    onDeleteChat(chat)
                                }
                                .labelStyle(.titleAndIcon)
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.title3)
                            }
                            .menuStyle(.borderlessButton)
                            .labelStyle(.titleAndIcon)
                        }
                    }.contentShape(Rectangle())
                }
                .onHover { hovered in
                    showThreeDots = hovered && !showDeleteChatButton
                }
                .highPriorityGesture(
                    TapGesture()
                        .onEnded{_ in
                            withAni(doubled: true){
                                onSelectChat(chat)
                            }
                        }
                )
                .contextMenu(menuItems: {
                    Button("Edit title", systemImage: "pencil") {
                        editTitle()
                    }
                    .labelStyle(.titleAndIcon)
                    Button("Generate title", systemImage: "bolt.horizontal") {
                        getNewTitle(chat)
                    }
                    .labelStyle(.titleAndIcon)
                    Divider()
                    Button("Delete", systemImage: "delete.backward") {
                        onDeleteChat(chat)
                    }
                    .labelStyle(.titleAndIcon)
                })
                .buttonStyle(ChatRowButtonStyle())
            }
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
                .animation(.spring(duration: Settings.shared.animationDelay), value: isHovered)
            
        }
    }
    
    @State private var hovered: Bool = false
    
    
    
}
