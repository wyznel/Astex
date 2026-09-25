//
//  RapidMLX.swift
//  Astex
//
//  Created by Ben Herbert on 19/07/2026.
//

import Foundation
import RapidMLX

class RapidMLXEngine {
    let client = Utilities.shared.rapidmlx_client
    
    func generateStream(
        _ previousMessages: [Message],
        model: String,
        fileContext: String? = nil,
        toolRegistry: ToolRegistry? = nil
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        return AsyncThrowingStream<StreamChunk, Error> { continuation in
            
            let task = Task {
                defer {
                    continuation.yield(.loading(false))
                }
                do {
                    continuation.yield(.loading(true))
                    
                    try await client.serve(model: model)
                    
                    let sorted = previousMessages.sorted {
                        $0.createdAt < $1.createdAt
                    }
                    var messageHistory = sorted.compactMap { message -> RapidMLX.ChatMessage? in
                        guard let text = message.contextText else { return nil }
                        return message.type == .user ? .user(text) : .assistant(text)
                    }
                    messageHistory.insert(.system(
                        """
                        Do not call any tools unless necessary.
                        When making a tool call, explain what you did and why it was necessary
                        """),
                        at: 0)

                    // Inject uploaded file contents into the last user message
                    if let fileContext {
                        if let lastIndex = messageHistory.lastIndex(
                            where: { $0.role == .user
                            }) {
                            let original = messageHistory[lastIndex].content
                            messageHistory[lastIndex] = .user(
                                """
                                The user has attached the following files:
                                
                                \(fileContext)
                                
                                User message:
                                \(original!)
                                """
                            )
                        }
                    }
                    
                    let activeTools: [any RapidMLX.ToolProtocol] = (toolRegistry != nil && !toolRegistry!.isEmpty)
                        ? toolRegistry!.allRapidMLXTools : []
                    
                    let schemas = try activeTools.toChatCompletionTools()
                    for _ in 0..<10 {
                        var assistantMessage: RapidMLX.ChatMessage?
                        for try await chunk in client.chatStreamEvents(
                            messageHistory, tools: schemas, toolChoice: .auto
                        ) {
                            try Task.checkCancellation()
                            switch chunk {
                            case .content(let token):
                                continuation.yield(.content(token))
                            case .toolCallsReady:
                                break
                            case .finished(let message):
                                assistantMessage = message
                            }
                        }
                        guard let message = assistantMessage,
                              let calls = message.toolCalls, !calls.isEmpty else { break }
                        messageHistory.append(message)
                        for call in calls {
                            guard let registry = toolRegistry else { break }
                            let result = await registry.execute(
                                name: call.function.name, jsonString: call.function.arguments
                            )
                            messageHistory.append(.toolResult(callId: call.id, content: result.json))
                            continuation.yield(.toolCall(result))
                            try Task.checkCancellation()
                        }
                    }
                    continuation.finish()
                }
                catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { termination in
                if case .cancelled = termination {
                    task.cancel()
                }
            }
        }
    }
    
//  MARK: - Generate a Title.
    func generateTitle(_ previousMessages: [Message]) async -> String {
        do {
            let promptForTitleGen = Message(type: .user, response:
                """
                Generate a short chat title based on the conversation.
                
                Rules:
                - Output only the title
                - Do not include any label such as Title or Chat Title
                - Use only letters numbers and spaces
                - No punctuation
                - Maximum 50 characters
                
                Invalid output examples:
                Chat Title: DNS Help
                "DNS Help"
                DNS Help!
                
                Example Valid output examples:
                DNS Help
                Project Astex Debugging
                """)
            
            var sorted = previousMessages.sorted { $0.createdAt < $1.createdAt }
            sorted.append(promptForTitleGen)
            
            let messageHistory = sorted.compactMap { message -> RapidMLX.ChatMessage? in
                guard let text = message.contextText else { return nil }
                return message.type == .user ? .user(text) : .assistant(text)
            }
            
            let response = try await client.chat(messageHistory)
            return response.firstText ?? "Error generating title"
            
        } catch {
            print("Error generating chat title: \(error)")
        }
        return ""
    }
}
