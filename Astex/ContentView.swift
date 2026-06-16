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
    private let chunkCharLimit = 1000
    
    private var scaleFactor: Double = 1.2
    
    private let llm = LLM()

    var body: some View {
        NavigationSplitView {
            List {
                ChatActionHandling(
                 onNewChat: {
                     generationTask?.cancel()
                     generationTask = nil
                     isAResponseGenerating = false
                     withAnimation(.spring(duration: settings.animationDelay)){
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
                     withAnimation(.spring(duration: settings.animationDelay)) {
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
                         withAnimation(.spring(duration: settings.animationDelay*2)) {
                             activeChat = nil
                             chatWindowEmpty = true
                         }
                     }
                     modelContext.delete(chat)
                 }
                )
            }
            .frame(minWidth: 180, maxWidth: 320)
            .navigationSplitViewColumnWidth(min: 180, ideal: 240, max: 320)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        } detail: {
            mainBody()
        }
        .navigationSplitViewStyle(.balanced)
    }
 
    @ViewBuilder
    func mainBody() -> some View {
        VStack(spacing: 12) {
            if !chatWindowEmpty {
                ScrollView {
                    VStack(spacing: 10){
                        ForEach(
                            (activeChat?.messages ?? []).sorted(by: { msg, msg1 in msg.createdAt < msg1.createdAt})
                        ) { message in
                            if message.isUser{
                                MessageView(message: message.response, isUserMessage: true)
                                    .transition(.opacity)
                            }else {
                                MessageView(message: message.response, isUserMessage: false)
                                    .transition(.opacity)
                            }
                        }
                        // For streaming in-process chunks, they're grouped so all chunks share the width of the widest one rather than sizing independently.
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
                    .foregroundStyle(.ultraThickMaterial)
                    .animation(.spring(duration: settings.animationDelay * 2), value: prompt.isEmpty)
                GlassEffectContainer {
                    userInputArea()
                }
                .padding(.bottom, 12)
                .animation(.spring(duration: settings.animationDelay * 2), value: prompt.isEmpty)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(minWidth: 400, minHeight: 200)
            .animation(.spring(duration: settings.animationDelay), value: isSendButtonHovered)
            if chatWindowEmpty { Spacer() }
        }
        .background(
            LinearGradient(colors: [.indigo, .mint], startPoint: .topLeading, endPoint: .bottom)
        )
    }

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
        chatWindowEmpty = false
        
        withAnimation(.spring(duration: settings.animationDelay)) {
            let userMessage = Message(isUser: true, response: currentPrompt)
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

                // Seed the first slot on the very first chunk so the streaming
                // view only appears once real content has arrived.
                if streamingChunks.isEmpty {
                    streamingChunks.append("")
                }

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
                // Seed the array if no chunk arrived before the failure.
                if streamingChunks.isEmpty { streamingChunks.append("") }
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
            withAnimation(.spring(duration: settings.animationDelay)) {
                let llmMessage = Message(isUser: false, response: fullResponse)
                modelContext.insert(llmMessage)
                activeChat?.messages.append(llmMessage)
            }
        }
        streamingChunks = []
        
        //Generate a title for a chat after a few messages have been sent/recieved.
        if activeChat?.messages.count ?? 0 > 2 && !activeChat!.titleHasBeenGenerated {
            let promptForTitleGen = Message(isUser: true, response:
                """
                Generate a short chat title based on the conversation.
                
                Rules:
                - Output only the title
                - Do not include any label such as Title or Chat Title
                - Use only letters numbers and spaces
                - No punctuation
                - Maximum 50 characters
                
                Invalid outputs:
                Chat Title: DNS Help
                "DNS Help"
                DNS Help!
                
                Valid output:
                DNS Help
                Project Astex Debugging
                """)
            
            var something = activeChat?.messages ?? []
            something.append(promptForTitleGen)
            
            let newTitle = await llm.generateTitle(something)
            print("Generated Title: \(newTitle)")
            activeChat?.title = newTitle
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
                    guard !prompt.isEmpty && !isAResponseGenerating else { return .handled }
                    generationTask = Task { @MainActor in
                        await handlePromptSending()
                    }
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
            if !isUserMessage { Spacer() }
        }
    }
    
}
