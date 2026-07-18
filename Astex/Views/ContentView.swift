//
//  ContentView.swift
//  Astex
//
//  Created by Ben Herbert on 15/06/2026.
//

import SwiftUI
import SwiftData
import Textual
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var prompt: String = ""
    @State private var chatWindowEmpty: Bool = true
    @State private var isSendButtonHovered: Bool = false
    @State private var isUploadFileButtonHovered: Bool = false
    @State private var isAResponseGenerating: Bool = false
    @State private var generationTask: Task<Void, Never>? = nil
    @State private var showDeleteChatButton: Bool = false
    
    
    @ObservedObject private var settings = Settings.shared
    
    private var utilities = Utilities()
    
    @State private var activeChat: Chat? = nil
    @State private var streamingChunks: [String] = []
    @State private var thinkingStreamingChunks: [String] = []
    @State private var toolCallingChunks: [String] = []
    @State private var availableModels: [String] = []
    
    @State private var showFileImporter: Bool = false
    
    @State private var uploadedFiles: [UploadedFile] = []
    
    private let chunkCharLimit = 1000
    
    
    private let llm = LLM()

    /// Centralised registry of all tools the LLM can invoke.
    /// To add a new tool: create its implementation in Tools/ and add it
    /// to the array below. No other files need to change.
    private let toolRegistry = ToolRegistry(tools: [
        DocumentCreation.makeTool()
    ])

    var body: some View {
        if !settings.isFirstOpen {
            NavigationSplitView {
                ChatActionHandling(
                 onNewChat: {
                     generationTask?.cancel()
                     generationTask = nil
                     isAResponseGenerating = false
                     withAni {
                         settings.settingsOpened = false
                         activeChat = nil
                         
                         prompt = ""
                         uploadedFiles = []
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
                         
                         prompt = ""
                         uploadedFiles = []
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
                             
                             prompt = ""
                             uploadedFiles = []
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
        } else {
            OnboardingView()
                .windowResizeBehavior(.disabled)
        }
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
                            } else if message.isAToolCall {
                                MessageView(message: message.response, isUserMessage: false)
                                    .transition(.opacity)
                            }
                            else{
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

            if chatWindowEmpty { Spacer() }
        }
        .background(Color.sepiaBackground)
    }
    
// MARK: - Prompt Sending
    func handlePromptSending() async {
        let currentPrompt = prompt
        let currentFiles = uploadedFiles
        
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
        uploadedFiles.removeAll()
        messageHistoryIndex = -1
        chatWindowEmpty = false
        
        // Read file contents while security-scoped access is still active
        let fileContext = FileHandling.buildContext(from: currentFiles)
        
        // Now release security-scoped access
        for file in currentFiles {
            file.url.stopAccessingSecurityScopedResource()
        }

        withAni {
            let userMessage = Message(isUser: true, response: currentPrompt, isThinking: false, isAToolCall: false)
            modelContext.insert(userMessage)
            activeChat?.messages.append(userMessage)
        }

        // Keep streamingChunks empty until the first chunk arrives so the
        // streaming view container is not rendered at all beforehand -- avoids
        // showing the previous response's bubble while waiting for the new stream.
        streamingChunks = []
        
        do {
            let stream = llm.generateStream(
                activeChat?.messages ?? [],
                fileContext: fileContext,
                toolRegistry: toolRegistry
            )
            
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
                case .toolCall(let text):
                    if toolCallingChunks.isEmpty {
                        toolCallingChunks.append("")
                    }
                    
                    toolCallingChunks[toolCallingChunks.count - 1] += text
                }
            
            }
        } catch {
            if Task.isCancelled {
                // User cancelled. Keep partial response.
            } else {
                // Seed the array if no chunk arrived before the failure.
                if thinkingStreamingChunks.isEmpty {
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
        
        // Collapse all chunks into a single completed Message.
        // If thinking chunks were collected, the model supported thinking --
        // no need to re-query the API.
        let fullThinkingResp = thinkingStreamingChunks.joined()
        if !fullThinkingResp.isEmpty {
            withAni {
                let llmThinking = Message(isUser: false, response: fullThinkingResp, isThinking: true, isAToolCall: false)
                modelContext.insert(llmThinking)
                activeChat?.messages.append(llmThinking)
            }
        }
        let allToolsCalled = toolCallingChunks.joined()
        print(allToolsCalled)
        
        if !allToolsCalled.isEmpty {
            withAni {
                let toolCalledDisplay = Message(isUser: false, response: allToolsCalled, isThinking: false, isAToolCall: true)
                modelContext.insert(toolCalledDisplay)
                activeChat?.messages.append(toolCalledDisplay)
            }
        }
        
        
        let fullResponse = streamingChunks.joined()
        if !fullResponse.isEmpty {
            withAni {
                let llmMessage = Message(isUser: false, response: fullResponse, isThinking: false, isAToolCall: false)
                modelContext.insert(llmMessage)
                activeChat?.messages.append(llmMessage)
            }
        }
        streamingChunks = []
        toolCallingChunks = []
        thinkingStreamingChunks = []
        
    }
    
    @State private var messageHistoryIndex: Int = -1
    
    @ViewBuilder
    func userInputArea() -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                GlassEffectContainer {
                    HStack(spacing: 12){
                        ForEach(uploadedFiles, id: \.id) { file in
                            UploadedFileView(
                                file: file,
                                uploadedFiles: $uploadedFiles
                            )
                        }
                    }
                }
                
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
                
                HStack(alignment: .bottom, spacing: 12) {
                    Button {
                        showFileImporter = true
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 8, height: 12)
                    }
                    .buttonStyle(.glass)
                    .offset(x: 4, y: -4)
                    .onHover { hover in
                        withAni {
                            isUploadFileButtonHovered = hover
                        }
                    }
                    
                    Spacer()

                    Menu {
                        ForEach(availableModels, id: \.self) { model in
                            Button {
                                settings.selectedModel = model
                            } label: {
                                Text(model)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(settings.selectedModel)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .task {
                        // Load available models once when the menu appears
                        availableModels = await utilities.getAvailableModelsNAME_ONLY_OLLAMA()
                    }
                    .fixedSize()
                    .offset(y: -4)

                    Button {
                        if isAResponseGenerating {
                            generationTask?.cancel()
                            isAResponseGenerating = false
                            streamingChunks = []
                        } else {
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
                    .offset(x: -4, y: -4)
                    .frame(width: 24, height: 20)
                    .onHover { hover in
                        withAni {
                            isSendButtonHovered = hover && !prompt.isEmpty
                        }
                    }
                }
            }
            .padding(.leading, 5)
            .padding(.bottom, 3)
            .frame(maxWidth: prompt.isEmpty ? 400 : 750)
            .glassEffect(settings.glassEffect.interactive(), in: .rect(cornerRadius: 8))
        }
        .offset(y: chatWindowEmpty ? 0 : -20)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.text, .pdf],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    guard url.startAccessingSecurityScopedResource() else { continue }
                    let uploadedFile: UploadedFile = UploadedFile(url: url)
                    uploadedFiles.append(uploadedFile)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
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
        .opacity(0.4)
    }
    
}
