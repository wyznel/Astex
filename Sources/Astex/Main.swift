import SwiftData
import SwiftUI

struct MainWindow: View {
    @State private var prompt: String = ""
    @State private var chatWindowEmpty: Bool = true
    @State private var isSendButtonHovered: Bool = false
    @State private var isAResponseGenerating: Bool = false
    @State private var generationTask: Task<Void, Never>? = nil
    
    @ObservedObject private var settings = Settings.shared
    
    @Environment(\.modelContext) private var context
    @State private var activeChat: Chat? = nil
    @State private var streamingChunks: [String] = []
    private let chunkCharLimit = 1000
    
    private var scaleFactor = 1.2
    private var animationDelay = 0.25
    
    private let llm = LLM()
    
    var body: some View {
        VStack(spacing: 12) {
            if !chatWindowEmpty {
                Spacer()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(
                            (activeChat?.messages ?? []).sorted(by: { msg, msg1 in msg.createdAt < msg1.createdAt
                            })
                        ) { message in
                            if message.isUser {
                                UserMessageView(message.response)
                                    .transition(.opacity)
                            } else {
                                llmMessageView(message.response)
                            }
                        }
                        // Streaming in-progress chunks, they're grouped so all chunks share the width of the widest one rather than sizing independently.
                        if !streamingChunks.isEmpty {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(streamingChunks.indices, id: \.self) { i in
                                        Text(streamingChunks[i])
                                            .textSelection(.enabled)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, i == 0 ? 10 : 4)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .transition(.opacity.combined(with: .scale))
                                    }
                                }
                                .glassEffect(settings.glassEffect.interactive(), in: .rect(cornerRadius: 6))
                                .frame(maxWidth: 550, alignment: .leading)
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: 810)
                }
                .frame(maxWidth: 810)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Astex")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.ultraThickMaterial)
                    .opacity(chatWindowEmpty ? 1 : 0)
                    .animation(.spring(duration: animationDelay * 2), value: chatWindowEmpty)
                GlassEffectContainer {
                    userInputArea()
                }
                .padding(.bottom, 12)
                .animation(.spring(duration: animationDelay + 0.25), value: prompt.isEmpty)
            }
            .frame(maxWidth: 810)
            .animation(.spring(duration: animationDelay + 0.25), value: prompt.isEmpty)
            
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: 400, minHeight: 200)
        .background(
            LinearGradient(colors: [.indigo, .mint], startPoint: .topLeading, endPoint: .bottom)
        )
        .animation(.spring(duration: animationDelay), value: isSendButtonHovered)
        .overlay(alignment: .leading) {
            Sidebar(
                onNewChat: {
                    generationTask?.cancel()
                    generationTask = nil
                    isAResponseGenerating = false
                    withAnimation(.spring(duration: animationDelay)){
                        activeChat = nil
                    }
                    streamingChunks = []
                    chatWindowEmpty = true
                },
                onSelectChat: { chat in
                    generationTask?.cancel()
                    generationTask = nil
                    isAResponseGenerating = false
                    streamingChunks = []
                    withAnimation(.spring(duration: animationDelay)) {
                        activeChat = chat
                        chatWindowEmpty = chat.messages.isEmpty
                    }
                },
                onDeleteChat: { chat in
                    if chat == activeChat {
                        generationTask?.cancel()
                        generationTask = nil
                        isAResponseGenerating = false
                        streamingChunks = []
                        withAnimation(.spring(duration: animationDelay*2)) {
                            activeChat = nil
                            chatWindowEmpty = true
                        }
                    }
                    context.delete(chat)
                }
                
            )
        }
    }
    
    func handlePromptSending() async {
        let currentPrompt = prompt
        
        if activeChat == nil {
            let chat = Chat(title: currentPrompt)
            context.insert(chat)
            activeChat = chat
        }
        
        let chatAtStart = activeChat
        isAResponseGenerating = true
        
        defer {
            if activeChat == chatAtStart {
                isAResponseGenerating = false
                generationTask = nil
            }
        }
        
        prompt.removeAll()
        chatWindowEmpty = false
        
        withAnimation(.spring(duration: animationDelay)) {
            let userMessage = Message(isUser: true, response: currentPrompt)
            context.insert(userMessage)
            activeChat?.messages.append(userMessage)
            // Start with one empty chunk
            streamingChunks = [""]
        }
        
        do {
            let stream = llm.generateStream(activeChat?.messages ?? [])
            
            for try await chunk in stream {
                guard !Task.isCancelled else { break }
                guard activeChat == chatAtStart else { break }
                guard !streamingChunks.isEmpty else { break }
                
                streamingChunks[streamingChunks.count - 1] += chunk
                // If the current chunk has grown too large, start a new one
                if streamingChunks.last!.count >= chunkCharLimit {
                    streamingChunks.append("")
                }
            }
        } catch {
            if Task.isCancelled {
                // User cancelled. Keep partial response.
            } else {
                guard !streamingChunks.isEmpty else { return }
                streamingChunks[streamingChunks.count - 1] = "LLM failed to respond."
            }
        }
        
        // Only save the response if the chat has not changed
        guard activeChat == chatAtStart else {
            return
        }
        
        // Collapse all chunks into a single completed Message
        let fullResponse = streamingChunks.joined()
        if !fullResponse.isEmpty {
            withAnimation(.spring(duration: animationDelay)) {
                let llmMessage = Message(isUser: false, response: fullResponse)
                context.insert(llmMessage)
                activeChat?.messages.append(llmMessage)
            }
        }
        streamingChunks = []
    }
    
    @ViewBuilder
    func UserMessageView(_ message: String) -> some View {
        HStack {
            Spacer()
            Text(message)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .glassEffect(settings.glassEffect.interactive(), in: .rect(cornerRadius: 6))
                .frame(maxWidth: 550, alignment: .trailing)
        }
    }
    
    @ViewBuilder
    func llmMessageView(_ message: String) -> some View {
        HStack {
            Text(message)
                .textSelection(.enabled)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .glassEffect(settings.glassEffect.interactive(), in: .rect(cornerRadius: 6))
                .frame(maxWidth: 550, alignment: .leading)
            Spacer()
        }
    }
    
    @ViewBuilder
    func userInputArea() -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextEditor(text: $prompt)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 6)
                .padding(.vertical, 15)
                .frame(minHeight: 30, maxHeight: 200)
                .frame(width: prompt.isEmpty ? 400 : 750)
                .fixedSize(horizontal: false, vertical: true)
                .scrollDisabled(prompt.isEmpty)
                .overlay(alignment: .topLeading) {
                    if prompt.isEmpty {
                        Text("Enter prompt")
                            .font(.body)
                            .foregroundColor(Color(nsColor: .placeholderTextColor))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }
                .glassEffect(settings.glassEffect.interactive(), in: .rect(cornerRadius: 6))
                .onKeyPress(keys: [.return], phases: .down) { keyPress in
                    if keyPress.modifiers.contains(.shift) {
                        return .ignored
                    }
                    guard !prompt.isEmpty else { return .handled }
                    generationTask = Task { @MainActor in
                        await handlePromptSending()
                    }
                    return .handled
                }
            Button {
                if isAResponseGenerating {
                    generationTask?.cancel()
                    isAResponseGenerating = false
                }else {
                    generationTask = Task { @MainActor in
                        await handlePromptSending()
                    }
                }
            } label: {
                Image(systemName: isAResponseGenerating ? "stop.fill" : "arrow.up")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .disabled(prompt.isEmpty && !isAResponseGenerating)
            .buttonStyle(.glass)
            .frame(
                width: isSendButtonHovered ? 48 * scaleFactor : 48,
                height: isSendButtonHovered ? 45 * scaleFactor : 45
            )
            .onHover { hover in
                isSendButtonHovered = hover && !prompt.isEmpty
            }
            .animation(.spring(duration: animationDelay), value: isSendButtonHovered)
        }
    }
    
}
