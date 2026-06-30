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
                withAnimation(.spring(duration: settings.animationDelay*2)) {
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
    
            DefaultButton(text: "Settings", imageShape: "gearshape"){
                withAnimation(.spring(duration: settings.animationDelay * 2)){
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
                    }.contentShape(Rectangle())
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.25)
                        .onEnded { _ in
                            Task {
                                withAnimation(.spring(duration: Settings.shared.animationDelay)){
                                    showDeleteChatButton = true
                                }
                                
                                try? await Task.sleep(for: .seconds(5))
                                
                                withAnimation(.spring(duration: Settings.shared.animationDelay)){
                                    showDeleteChatButton = false
                                }
                            }
                        }
                )
                .highPriorityGesture(
                    TapGesture()
                        .onEnded{_ in
                            onSelectChat(chat)
                        }
                )
                .contextMenu(menuItems: {
                    Button("Delete", systemImage: "delete.backward") {
                        onDeleteChat(chat)
                    }
                    Button("Edit Title", systemImage: "pencil") {
                        editTitle()
    //                    newChatTitleName = chat.title
    //                    editingChatTitleID = chat.id
                    }
                    Button("Generate Title", systemImage: ""){
                        getNewTitle(chat)
                    }
                })
                .buttonStyle(ChatRowButtonStyle())
                
                if showDeleteChatButton {
                    Button {
                        onDeleteChat(chat)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.red)
                    }
                    .contentShape(Rectangle())
                }
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
    
    struct DefaultButton: View {
        let text: String
        let imageShape: String
        let action: () -> Void
        
        @State private var hovered: Bool = false
        
        var body: some View {
            Button {
                action()
            } label: {
                HStack {
                    Image(systemName: imageShape)
                        .padding(6)
                    Text(text)
                    Spacer()
                }
                .contentShape(Capsule())
                .frame(height: 30)
            }
            .glassEffect(hovered
                         ? .regular.tint(Color.sepiaAccent.opacity(0.3))
                         : .regular.tint(Color.sepiaAccent.opacity(0.125)))
            .animation(.spring(duration: Settings.shared.animationDelay), value: hovered)
            .clipShape(Capsule())
            .buttonStyle(.plain)
            .onHover { isHovered in
                hovered = isHovered
            }
        }
    }
    
}
