//
//  ContentView.swift
//  Astex
//
//  Created by Ben Herbert on 15/06/2026.
//

import SwiftUI
import SwiftData
import Textual

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var prompt: String = ""
    @State private var chatWindowEmpty: Bool = true
    @State private var isSendButtonHovered: Bool = false
    @State private var isAResponseGenerating: Bool = false
    @State private var generationTask: Task<Void, Never>? = nil
    
    @ObservedObject private var settings = Settings.shared
    
    @State private var activeChat: Chat? = nil
    @State private var streamingChunks: [String] = []
    @State private var thinkingStreamingChunks: [String] = []
    
    private let chunkCharLimit = 1000
    
    private var scaleFactor: Double = 1.2
    
    private let llm = LLM()
    
    var body: some View {
        NavigationSplitView {
            ChatActionHandling(
             onNewChat: {
                 generationTask?.cancel()
                 generationTask = nil
                 isAResponseGenerating = false
                 withAni {
                     settings.settingsOpened = false
                     activeChat = nil
                 }
                 streamingChunks = []
                 thinkingStreamingChunks = []
                 chatWindowEmpty = true
             },
             onSelectChat: { chat in
                 settings.settingsOpened = false
                 generationTask?.cancel()
                 generationTask = nil
                 isAResponseGenerating = false
                 streamingChunks = []
                 thinkingStreamingChunks = []
                 withAni {
                     activeChat = chat
                     chatWindowEmpty = false
                 }
             },
             onDeleteChat: { chat in
                 if chat == activeChat {
                     generationTask?.cancel()
                     generationTask = nil
                     isAResponseGenerating = false
                     streamingChunks = []
                     thinkingStreamingChunks = []
                     withAni(doubled: true) {
                         activeChat = nil
                         chatWindowEmpty = true
                     }
                 }
                 modelContext.delete(chat)
             },
             getNewTitle: { chat in
                 Task {
                     let newTitle = await llm.generateTitle(chat.messages)
                     chat.title = newTitle
                     chat.titleHasBeenGenerated = true
                 }
            }
            )
            .frame(minWidth: 180, maxWidth: 320)
            .navigationSplitViewColumnWidth(min: 180, ideal: 240, max: 320)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        } detail: {
            if(!settings.settingsOpened) {
                mainBody()
            }else{
                SettingsView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
 
    @ViewBuilder
    func mainBody() -> some View {
        VStack(spacing: 12) {
            if !chatWindowEmpty {
//              MARK: - Chat Area
                ScrollView {
                    VStack(spacing: 10){
                        ForEach(
                            (activeChat?.messages ?? []).sorted(by: { msg, msg1 in msg.createdAt < msg1.createdAt})
                        ) { message in
                            if message.isUser{
                                MessageView(message: message.response, isUserMessage: true)
                                    .transition(.opacity)
                            }else if !message.isThinking {
                                MessageView(message: message.response, isUserMessage: false)
                                    .transition(.opacity)
                            }else{
                                ThinkingView(message: message.response)
                                    .transition(.opacity)
                            }
                        }
                        // For streaming in-process chunks, they're grouped so all chunks share the width of the widest one rather than sizing independently.
                        if !thinkingStreamingChunks.isEmpty {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(thinkingStreamingChunks.indices, id: \.self){ i in
                                        Text(thinkingStreamingChunks[i])
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
                    .frame(maxWidth: 810, maxHeight: .infinity)
                    .padding(.top, 8)
                }
                .frame(maxWidth: 810)
                .layoutPriority(1)
            }
            if chatWindowEmpty { Spacer() }
            VStack(alignment: .leading, spacing: 10) {
                Text("Astex")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .opacity(chatWindowEmpty ? 1 : 0)
                    .foregroundStyle(Color.sepiaText)
                    .animation(.spring(duration: settings.animationDelay * 2), value: prompt.isEmpty)
                GlassEffectContainer {
                    userInputArea()
                }
                .padding(.bottom, 12)
                .animation(.spring(duration: settings.animationDelay * 2), value: prompt.isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .frame(minWidth: 400, minHeight: 100)
            .animation(.spring(duration: settings.animationDelay), value: isSendButtonHovered)
            if chatWindowEmpty { Spacer() }
        }
        .background(Color.sepiaBackground)
    }
    
// MARK: - Prompt Sending
    func handlePromptSending() async {
        let currentPrompt = prompt
        
        if activeChat == nil {
            let chat = Chat(title: currentPrompt)
            modelContext.insert(chat)
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
        messageHistoryIndex = -1
        chatWindowEmpty = false
        
        withAni {
            let userMessage = Message(isUser: true, response: currentPrompt, isThinking: false)
            modelContext.insert(userMessage)
            activeChat?.messages.append(userMessage)
        }
        // Keep streamingChunks empty until the first chunk arrives so the
        // streaming view container is not rendered at all beforehand — avoids
        // showing the previous response's bubble while waiting for the new stream.
        streamingChunks = []
        
        do {
            let stream = llm.generateStream(activeChat?.messages ?? [])
            
            for try await chunk in stream {
                guard !Task.isCancelled else { break }
                guard activeChat == chatAtStart else { break }

                switch chunk {
                case .thinking(let text):
                    if thinkingStreamingChunks.isEmpty {
                        thinkingStreamingChunks.append("")
                    }
                    
                    thinkingStreamingChunks[thinkingStreamingChunks.count - 1] += text
                    
                    if thinkingStreamingChunks.last!.count >= chunkCharLimit {
                        thinkingStreamingChunks.append("")
                    }
                    
                case .content(let text):
                    if streamingChunks.isEmpty {
                        streamingChunks.append("")
                    }

                    streamingChunks[streamingChunks.count - 1] += text
                    // If the current chunk has grown too large, start a new one
                    if streamingChunks.last!.count >= chunkCharLimit {
                        streamingChunks.append("")
                    }
                }

            }
        } catch {
            if Task.isCancelled {
                // User cancelled. Keep partial response.
            } else {
                // Seed the array if no chunk arrived before the failure.
                if await llm.client.supportsThinking(model: Settings.shared.selectedModel) && thinkingStreamingChunks.isEmpty {
                    thinkingStreamingChunks.append("")
                    thinkingStreamingChunks[thinkingStreamingChunks.count - 1] = "LLM Failed to respond"
                }
                
                if streamingChunks.isEmpty { streamingChunks.append("") }
                streamingChunks[streamingChunks.count - 1] = "LLM failed to respond."
            }
        }
        
        // Only save the response if the chat has not changed
        guard activeChat == chatAtStart else {
            return
        }
        
        // Collapse all chunks into a single completed Message
        if await llm.client.supportsThinking(model: Settings.shared.selectedModel) {
            let fullThinkingResp = thinkingStreamingChunks.joined()
            if !fullThinkingResp.isEmpty {
                withAni {
                    let llmThinking = Message(isUser: false, response: fullThinkingResp, isThinking: true)
                    modelContext.insert(llmThinking)
                    activeChat?.messages.append(llmThinking)
                }
            }
        }
        
        let fullResponse = streamingChunks.joined()
        if !fullResponse.isEmpty {
            withAni {
                let llmMessage = Message(isUser: false, response: fullResponse, isThinking: false)
                modelContext.insert(llmMessage)
                activeChat?.messages.append(llmMessage)
            }
        }
        streamingChunks = []
        thinkingStreamingChunks = []
        //Generate a title for a chat after a few messages have been sent/recieved.
        if activeChat?.messages.count ?? 0 > 2 && !activeChat!.titleHasBeenGenerated {
            let newTitle = await llm.generateTitle(activeChat?.messages ?? [])
            print("Generated Title: \(newTitle)")
            activeChat?.title = newTitle
            activeChat?.titleHasBeenGenerated = true
        }
    }
    
    @State private var messageHistoryIndex: Int = -1
    
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
                    guard !prompt.isEmpty && !isAResponseGenerating else { return .handled }
                    generationTask = Task { @MainActor in
                        await handlePromptSending()
                    }
                    return .handled
                }
                .onKeyPress(keys: [.upArrow], phases: .down) { keyPress in
                    let sorted = (activeChat?.messages ?? [])
                        .filter { $0.isUser }
                        .sorted { $0.createdAt < $1.createdAt }
                    
                    guard !sorted.isEmpty else { return .ignored }
                    
                    let nextIndex = messageHistoryIndex + 1
                    
                    guard nextIndex < sorted.count else { return .handled }
                    
                    messageHistoryIndex = nextIndex
                    prompt = sorted[sorted.count - 1 - messageHistoryIndex].response
                    
                    return .handled
                }
            Button {
                if isAResponseGenerating {
                    generationTask?.cancel()
                    isAResponseGenerating = false
                    streamingChunks = []
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
            .animation(.spring(duration: settings.animationDelay), value: isSendButtonHovered)
        }
    }
    
    
    @ViewBuilder
    func MessageView(message: String, isUserMessage: Bool) -> some View {
        HStack {
            if isUserMessage { Spacer() }
            StructuredText(markdown: message)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .glassEffect(settings.glassEffect.interactive(), in: .rect(cornerRadius: 6))
                .frame(maxWidth: 550, alignment: isUserMessage ? .trailing : .leading)
                .textual.textSelection(.enabled)
            if !isUserMessage { Spacer() }
        }
    }
    
    @ViewBuilder
    func ThinkingView(message: String) -> some View {
        HStack {
            CollapsibleText(text: message, lineLimit: 1)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .glassEffect(settings.glassEffect.interactive(), in: .rect(cornerRadius: 10))
                .frame(maxWidth: 500, alignment: .leading)
            Spacer()
        }
    }
    
}

#Preview {
    ContentView()
}
